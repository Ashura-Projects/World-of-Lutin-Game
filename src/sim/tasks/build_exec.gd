class_name BuildExec
extends RefCounted
## Chantiers : le bâtisseur va chercher les matériaux à la réserve, les apporte, puis pose le bloc ou monte l'objet.

var board: TaskBoard


func _init(b: TaskBoard) -> void:
	board = b


static func cost_of(t: Dictionary) -> Dictionary:
	match t["kind"]:
		"build":
			return DataRegistry.block(int(t["block"])).get("cost", {})
		"sow":
			return Fields.crop(t["crop"]).get("seed", {})
		"craft":
			return Production.recipe(t["recipe"]).get("in", {})
		"heal":
			return {"healing_potion": 1}
	return Structures.def(t["struct_kind"]).get("cost", {})


func has_materials(t: Dictionary) -> bool:
	var cost := cost_of(t)
	for id: String in cost:
		if board.colony.stock.count(id) < int(cost[id]):
			t["missing"] = id
			return false
	t.erase("missing")
	return true


## Règle de solidité Phase 1 : un bloc doit toucher un bloc solide ; personne ne doit être dans la case.
func can_place(t: Dictionary) -> bool:
	if t["kind"] in ["build", "build_struct"] and board.tree_at(t["cell"]).y >= 0:
		return false  # attendre que le bûcheron ait coupé l'arbre
	if t["kind"] != "build":
		return true
	var cell: Vector3i = t["cell"]
	for l in board.colony.lutins:
		if l.cell == cell or l.cell == cell + Vector3i.DOWN:
			return false
	for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
		if board.world.is_solid(cell + d):
			return true
	return false


func start(l: Lutin, t: Dictionary) -> bool:
	if not has_materials(t) or not can_place(t):
		t["blocked"] = GameClock.tick_index + 5 * GameClock.ticks_per_second()
		return false
	if not board.colony.send(l, board.colony.stock.pos, true):
		t["blocked"] = GameClock.tick_index + 30 * GameClock.ticks_per_second()
		return false
	t["reserved"] = l.id
	t["phase"] = "fetch"
	l.task_id = t["id"]
	return true


func arrived(l: Lutin, t: Dictionary) -> void:
	if t.get("phase", "") == "fetch":
		var cost := cost_of(t)
		if not has_materials(t):
			board.release(l)
			return
		for id: String in cost:
			board.colony.stock.take(id, int(cost[id]))
		l.carrying = {"build": t["id"]}
		t["phase"] = "go"
		if not board.colony.send(l, t["cell"], true, _reach()):
			_refund(l, t)
			t["blocked"] = GameClock.tick_index + 30 * GameClock.ticks_per_second()
			board.release(l)
		return
	l.state = Lutin.State.WORK


func resume(l: Lutin) -> bool:
	var t: Dictionary = board.tasks.get(int(l.carrying["build"]), {})
	if t.is_empty() or (t["reserved"] != -1 and t["reserved"] != l.id):
		_refund(l, t)
		return false
	t["reserved"] = l.id
	l.task_id = t["id"]
	t["phase"] = "go"
	return board.colony.send(l, t["cell"], true, _reach())


func _reach() -> int:
	return int(DataRegistry.get_table("jobs").get("work", {}).get("build_reach_up", 3))


func _refund(l: Lutin, t: Dictionary) -> void:
	if not t.is_empty():
		var cost := cost_of(t)
		for id: String in cost:
			board.colony.stock.add(id, int(cost[id]))
	l.carrying = {}


func complete(l: Lutin, t: Dictionary) -> void:
	if t["kind"] == "heal":
		var patient := board.colony.find_lutin(int(t["target"]))
		if patient != null:
			var max_hp := float(DataRegistry.get_table("population").get("combat", {}).get("hp", 50))
			patient.hp = minf(max_hp, patient.hp + float(Stockpile._resource("healing_potion").get("heal", 30)))
			EventBus.alert.emit("soin", "%s soigne %s." % [l.name, patient.name])
	elif t["kind"] == "sow":
		if board.fields != null:
			board.fields.set_state(t["cell"], "sown")
	elif t["kind"] == "craft":
		var r := Production.recipe(t["recipe"])
		for k: String in r.get("out", {}):
			board.colony.stock.add(k, int(r["out"][k]))
		if t.has("order"):
			t["order"]["done"] = int(t["order"]["done"]) + 1
	elif t["kind"] == "build":
		if not can_place(t):
			t["progress"] = 0.0
			return
		board.world.set_block(t["cell"], int(t["block"]))
	elif board.structures != null:
		board.structures.set_built(int(t["struct_id"]))
		board.structures.assign_homes(board.colony)
	l.carrying = {}
