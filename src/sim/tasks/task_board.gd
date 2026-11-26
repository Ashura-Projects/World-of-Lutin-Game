class_name TaskBoard
extends RefCounted
## Tableau des tâches : ordres du joueur (couper, creuser, cueillir, pêcher, chasser) + transport automatique.
## Un lutin libre prend la meilleure tâche de son métier (ou une tâche où il est assigné). Une cible = un lutin.

signal tasks_changed

## Tâches où l'on va d'abord chercher des matériaux à la réserve.
const FETCH_KINDS := ["build", "build_struct", "sow", "craft", "heal"]

var world: VoxelWorld
var colony: Colony
var flora: Flora
var fauna: Fauna
var ground: GroundItems
var tasks: Dictionary = {}  # id -> tâche (Dictionary)
var next_id: int = 1
var _by_cell: Dictionary = {}  # Vector3i -> id (évite les doublons)
var _haul_reserved: Dictionary = {}  # case de pile -> id lutin
var _work: Dictionary
var exec: TaskExec
var builds: BuildExec
var structures: Structures = null
var fields: Fields = null
var batches: Array = []  # groupes de plans (pour ↶)


func _init(w: VoxelWorld, c: Colony, f: Flora, fa: Fauna, g: GroundItems) -> void:
	world = w
	colony = c
	flora = f
	fauna = fa
	ground = g
	_work = DataRegistry.get_table("jobs").get("work", {})
	exec = TaskExec.new(self)
	builds = BuildExec.new(self)
	c.task_board = self


func _new_task(kind: String, cell: Vector3i, job: String, work_s: float, extra: Dictionary = {}) -> int:
	if _by_cell.has(cell) and kind != "hunt":
		return -1
	var t := {
		"id": next_id,
		"kind": kind,
		"cell": cell,
		"job": job,
		"work": work_s,
		"progress": 0.0,
		"reserved": -1,
		"assigned": [],
		"blocked": 0,
		"target": -1,
		"repeat": false
	}
	t.merge(extra, true)
	tasks[next_id] = t
	if kind != "hunt":
		_by_cell[cell] = next_id
	next_id += 1
	tasks_changed.emit()
	return t["id"]


func add_cut(cell: Vector3i) -> int:
	var kind: String = flora.trees.get(cell, "")
	if kind == "":
		return -1
	var def: Dictionary = DataRegistry.get_table("flora")["trees"].get(kind, {})
	return _new_task("cut", cell, "woodcutter", float(def.get("work", 8)))


func add_dig(cell: Vector3i) -> int:
	var b := DataRegistry.block(world.get_block(cell))
	if b.is_empty() or not b.get("solid", false) or b.get("diggable", true) == false:
		return -1
	var job := "builder" if b.has("cost") else ("miner" if b.get("tool", "shovel") == "pickaxe" else "digger")
	return _new_task("dig", cell, job, float(b.get("hardness", b.get("build_time", 2))))


## Plan de bloc : un bâtisseur apportera le matériau (coût du bloc) puis le posera.
func add_build_block(cell: Vector3i, block_id: int) -> int:
	var b := DataRegistry.block(block_id)
	if not b.has("cost") or world.types.solid[world.get_block(cell)] == 1:
		return -1
	_clear_tree(cell)
	return _new_task("build", cell, "builder", float(b.get("build_time", 2)), {"block": block_id})


## Objet ou bâtiment à monter (tente, feu de camp, lit…).
func add_structure(kind: String, cell: Vector3i) -> int:
	if structures == null or not structures.at(cell).is_empty():
		return -1
	var on_wall: bool = Structures.def(kind).get("on_wall", false)
	if on_wall:
		var wall := false
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			wall = wall or world.is_solid(cell + d)
		if not wall or world.is_solid(cell):
			return -1  # un fanion mural se pose contre un mur
	elif not Pathfinder.walkable(world, cell):
		return -1  # il faut un sol solide et sec
	_clear_tree(cell)
	var d := Structures.def(kind)
	var sid := structures.add(kind, cell)
	var tid := _new_task(
		"build_struct", cell, "builder", float(d.get("build_time", 10)), {"struct_kind": kind, "struct_id": sid}
	)
	if tid >= 0:
		batches.append([tid])
	return tid


## Branché sur l'outil de construction : en partie, poser = plans ; gomme = annuler un plan ou démolir.
func place_blueprints(cells: Array, block_id: int, erase: bool) -> int:
	var n := 0
	var batch := []
	for p: Vector3i in cells:
		if erase:
			if _by_cell.has(p) and tasks[_by_cell[p]]["kind"] in ["build", "build_struct", "dig"]:
				cancel(_by_cell[p])  # annuler un plan (bloc, objet) ou un ordre de démolition
				n += 1
			elif TaskCancel.remove_structure_at(self, p) or TaskCancel.remove_structure_at(self, p + Vector3i.UP):
				n += 1
			else:
				var id := add_dig(p)
				if id >= 0:
					batch.append(id)
					n += 1
		else:
			var id := add_build_block(p, block_id)
			if id >= 0:
				batch.append(id)
				n += 1
	if not batch.is_empty():
		batches.append(batch)
	return n


## Un arbre occupe la case (son tronc monte sur 3 blocs) : on ordonne de le couper d'abord.
func tree_at(cell: Vector3i) -> Vector3i:
	for dy in range(0, 4):
		var p := cell - Vector3i(0, dy, 0)
		if flora.trees.has(p):
			return p
	return Vector3i(-1, -1, -1)


func _clear_tree(cell: Vector3i) -> void:
	var t := tree_at(cell)
	if t.y >= 0:
		add_cut(t)


## Le guérisseur apporte une potion à un blessé.
func add_heal(patient: Lutin) -> int:
	for t: Dictionary in tasks.values():
		if t["kind"] == "heal" and int(t["target"]) == patient.id:
			return -1
	var id := next_id
	var t := {
		"id": id,
		"kind": "heal",
		"cell": patient.cell,
		"job": "healer",
		"work": 3.0,
		"progress": 0.0,
		"reserved": -1,
		"assigned": [],
		"blocked": 0,
		"target": patient.id,
		"repeat": false
	}
	tasks[id] = t
	next_id += 1
	tasks_changed.emit()
	return id


func add_gather(cell: Vector3i) -> int:
	var f := DataRegistry.get_table("flora")
	if flora.bushes.has(cell):
		return _new_task("gather", cell, "gatherer", float(f["bush"].get("work", 3)), {"what": "bush"})
	if flora.herbs.has(cell):
		var w: Dictionary = f.get("wild", {}).get(flora.herbs[cell], {})
		return _new_task("gather", cell, "gatherer", float(w.get("work", 3)), {"what": "herb"})
	return -1


func add_fish(water_cell: Vector3i) -> int:
	var f: Dictionary = DataRegistry.get_table("flora").get("fishing", {})
	return _new_task("fish", water_cell, "fisher", float(f.get("work", 12)), {"repeat": true})


func add_hunt(animal_id: int) -> int:
	var a := fauna.find(animal_id)
	if a.is_empty():
		return -1
	for t: Dictionary in tasks.values():
		if t["kind"] == "hunt" and t["target"] == animal_id:
			return -1
	return _new_task("hunt", a["cell"], "hunter", 0.0, {"target": animal_id})


## Ordre de récolte en cercle (rayon 1 à 20) : toutes les ressources du type dans le cercle.
func order_circle(kind: String, center: Vector3i, radius: int) -> int:
	var n := 0
	match kind:
		"cut":
			for p in flora.in_circle("tree", center, radius, GameClock.day()):
				n += int(add_cut(p) >= 0)
		"gather":
			for p in (
				flora.in_circle("bush", center, radius, GameClock.day()) + flora.in_circle("herb", center, radius, 0)
			):
				n += int(add_gather(p) >= 0)
		"hunt":
			for a: Dictionary in fauna.animals:
				var c: Vector3i = a["cell"]
				if (
					Vector2(c.x - center.x, c.z - center.z).length() <= radius + 0.5
					and not fauna.def(a["kind"]).get("hostile", false)
				):
					n += int(add_hunt(a["id"]) >= 0)
	return n


## Ordre de creusage (boîte largeur × longueur × profondeur) : du haut vers le bas.
func order_dig(cells: Array) -> int:
	var n := 0
	for p: Vector3i in cells:
		n += int(add_dig(p) >= 0)
	return n


func cancel(id: int) -> void:
	var t: Dictionary = tasks.get(id, {})
	if t.is_empty():
		return
	if t["reserved"] >= 0:
		var l := colony.find_lutin(t["reserved"])
		if l:
			release(l)
	_by_cell.erase(t["cell"])
	tasks.erase(id)
	if t["kind"] == "build_struct" and structures != null:
		structures.remove(int(t["struct_id"]))
	tasks_changed.emit()


func finish(t: Dictionary) -> void:
	if t["kind"] != "heal":
		_by_cell.erase(t["cell"])
	tasks.erase(t["id"])
	tasks_changed.emit()


## Assigner des lutins précis à une tâche (bouton « Assigner »).
func assign_lutins(id: int, lutin_ids: Array) -> void:
	if tasks.has(id):
		tasks[id]["assigned"] = lutin_ids.duplicate()
		tasks_changed.emit()


func release(l: Lutin) -> void:
	if l.task_id >= 0 and tasks.has(l.task_id):
		tasks[l.task_id]["reserved"] = -1
	for c: Vector3i in _haul_reserved.keys():
		if _haul_reserved[c] == l.id:
			_haul_reserved.erase(c)
	l.task_id = -1
	if l.state == Lutin.State.WORK:
		l.state = Lutin.State.IDLE


func _can_do(l: Lutin, t: Dictionary) -> bool:
	var assigned: Array = t["assigned"]
	if not assigned.is_empty():
		return assigned.has(l.id)
	return l.job == t["job"]


## Appelé par la colonie pour un lutin libre. Renvoie true si une tâche est prise.
func assign(l: Lutin) -> bool:
	if l.carrying.has("build"):
		return builds.resume(l)
	if not l.carrying.is_empty():
		return exec.start_delivery(l)
	var best: Dictionary = {}
	var best_d := INF
	var now := GameClock.tick_index
	for t: Dictionary in tasks.values():
		if t["reserved"] != -1 or int(t["blocked"]) > now or not _can_do(l, t):
			continue
		var d := Vector3(t["cell"]).distance_squared_to(Vector3(l.cell))
		d += (
			float(t["cell"].y) * 16.0
			if t["kind"] == "build"
			else (-float(t["cell"].y) * 4.0 if t["kind"] == "dig" else 0.0)
		)
		if d < best_d:
			best_d = d
			best = t
	if not best.is_empty():
		if best["kind"] in FETCH_KINDS:
			return builds.start(l, best)
		return exec.start(l, best)
	if l.job == "hauler" or bool(_work.get("haul_any_idle", true)):
		return exec.start_haul(l)
	return false


func arrived(l: Lutin) -> void:
	exec.arrived(l)


func work(l: Lutin) -> void:
	exec.work(l)


func while_walking(l: Lutin) -> void:
	exec.while_walking(l)


## Chemin impossible : la tâche est mise de côté 30 s, le lutin est libéré (matériaux rendus).
func path_failed(l: Lutin) -> void:
	if l.carrying.has("pickup"):
		var c: Array = l.carrying["pickup"]
		free_pile(Vector3i(int(c[0]), int(c[1]), int(c[2])))
		l.carrying = {}
	var t: Dictionary = tasks.get(l.task_id, {})
	if not t.is_empty():
		t["blocked"] = GameClock.tick_index + 30 * GameClock.ticks_per_second()
		if l.carrying.has("build"):
			builds._refund(l, t)
	elif l.carrying.has("build"):
		l.carrying = {}
	release(l)


func reserve_pile(cell: Vector3i, l: Lutin) -> bool:
	if _haul_reserved.has(cell):
		return false
	_haul_reserved[cell] = l.id
	return true


func free_pile(cell: Vector3i) -> void:
	_haul_reserved.erase(cell)


func is_pile_reserved(cell: Vector3i) -> bool:
	return _haul_reserved.has(cell)


func to_dict() -> Dictionary:
	var out := []
	for t: Dictionary in tasks.values():
		var e := t.duplicate()
		e.erase("order")
		var c: Vector3i = t["cell"]
		e["cell"] = [c.x, c.y, c.z]
		e["reserved"] = -1
		out.append(e)
	return {"tasks": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	tasks.clear()
	_by_cell.clear()
	_haul_reserved.clear()
	for e: Dictionary in d.get("tasks", []):
		var c: Array = e["cell"]
		e["cell"] = Vector3i(int(c[0]), int(c[1]), int(c[2]))
		e["id"] = int(e["id"])
		e["reserved"] = -1
		e["blocked"] = int(e.get("blocked", 0))
		e["target"] = int(e.get("target", -1))
		e.erase("phase")
		if e.has("block"):
			e["block"] = int(e["block"])
		e.erase("order")
		if e["kind"] == "craft":
			continue  # les commandes recréent leurs tâches
		if e.has("struct_id"):
			e["struct_id"] = int(e["struct_id"])
		tasks[e["id"]] = e
		if e["kind"] != "hunt":
			_by_cell[e["cell"]] = e["id"]
	next_id = int(d.get("next_id", tasks.size() + 1))
	for l in colony.lutins:
		l.task_id = -1
