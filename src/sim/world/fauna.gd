class_name Fauna
extends RefCounted
## Animaux : gibier (cerf, sanglier) et, au J7, prédateurs (loup, ours). Déplacements simples sur la grille.

signal animal_added(a: Dictionary)
signal animal_removed(id: int)

var world: VoxelWorld
var animals: Array[Dictionary] = []
var next_id: int = 1
var _defs: Dictionary = {}


func _init(w: VoxelWorld) -> void:
	world = w
	for a: Dictionary in DataRegistry.get_table("animals").get("animals", []):
		_defs[a["id"]] = a


func def(kind: String) -> Dictionary:
	return _defs.get(kind, {})


## Peuple la carte selon data/animals.json (densité pour 1000 cases), loin du point de départ.
func populate(kinds: Array, avoid: Vector3i, avoid_radius: float = 20.0) -> void:
	var area := world.size.x * world.size.z
	for kind: String in kinds:
		var d := def(kind)
		var groups := maxi(1, int(area / 1000.0 * float(d.get("per_1000", 1)) / 3.0))
		for _g in groups:
			var c := Vector3i(Rng.randi_range(4, world.size.x - 5), 0, Rng.randi_range(4, world.size.z - 5))
			if Vector2(c.x - avoid.x, c.z - avoid.z).length() < avoid_radius:
				continue
			var herd: Array = d.get("herd", d.get("pack", [1, 1]))
			for _i in Rng.randi_range(int(herd[0]), int(herd[1])):
				var p := Pathfinder.snap(
					world,
					Vector3i(c.x + Rng.randi_range(-2, 2), world.surface_y(c.x, c.z), c.z + Rng.randi_range(-2, 2))
				)
				if p.y >= 0:
					spawn(kind, p)


func spawn(kind: String, p: Vector3i) -> Dictionary:
	var d := def(kind)
	var a := {
		"id": next_id,
		"kind": kind,
		"cell": p,
		"pos": Vector3(p) + Vector3(0.5, 0, 0.5),
		"hp": float(d.get("hp", 30)),
		"path": [],
		"path_i": 0,
		"wait": 0,
		"target": -1
	}
	next_id += 1
	animals.append(a)
	animal_added.emit(a)
	return a


func find(id: int) -> Dictionary:
	for a in animals:
		if a["id"] == id:
			return a
	return {}


## Dégâts ; renvoie true si l'animal meurt (il est alors retiré).
func damage(id: int, amount: float) -> bool:
	var a := find(id)
	if a.is_empty():
		return false
	a["hp"] = float(a["hp"]) - amount
	if float(a["hp"]) <= 0.0:
		animals.erase(a)
		animal_removed.emit(id)
		return true
	return false


func tick(colony_cells: Array) -> void:
	var tps := float(GameClock.ticks_per_second())
	for a in animals:
		var d := def(a["kind"])
		if a["wait"] > 0:
			a["wait"] -= 1
		var path: Array = a["path"]
		if a["path_i"] < path.size():
			var target := Vector3(path[a["path_i"]]) + Vector3(0.5, 0, 0.5)
			var step := float(d.get("speed", 1.2)) / tps
			var to: Vector3 = target - a["pos"]
			if to.length() <= step:
				a["pos"] = target
				a["cell"] = path[a["path_i"]]
				a["path_i"] += 1
			else:
				a["pos"] += to.normalized() * step
			continue
		if a["wait"] > 0 or int(a.get("prey", -1)) != -1:
			continue  # un prédateur en chasse suit sa proie (Combat)
		# fuite si un lutin approche (cerf), sinon errance
		var flee := float(d.get("flee_radius", 0))
		var dest: Vector3i = a["cell"] + Vector3i(Rng.randi_range(-6, 6), 0, Rng.randi_range(-6, 6))
		for c: Vector3i in colony_cells:
			if flee > 0 and Vector3(c).distance_to(Vector3(a["cell"])) < flee:
				var away: Vector3i = a["cell"] - c
				dest = a["cell"] + Vector3i(signi(away.x) * 8, 0, signi(away.z) * 8)
				break
		dest = Pathfinder.snap(world, Vector3i(dest.x, world.surface_y(dest.x, dest.z), dest.z))
		if dest.y >= 0:
			a["path"] = Pathfinder.find(world, a["cell"], dest, 600)
			a["path_i"] = 1
		a["wait"] = Rng.randi_range(2, 8) * GameClock.ticks_per_second()


func to_dict() -> Dictionary:
	var out := []
	for a in animals:
		var c: Vector3i = a["cell"]
		out.append({"id": a["id"], "kind": a["kind"], "cell": [c.x, c.y, c.z], "hp": a["hp"]})
	return {"animals": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	for a in animals:
		animal_removed.emit(a["id"])
	animals.clear()
	for e: Dictionary in d.get("animals", []):
		var c: Array = e["cell"]
		var a := spawn(e["kind"], Vector3i(int(c[0]), int(c[1]), int(c[2])))
		a["id"] = int(e["id"])
		a["hp"] = float(e["hp"])
	next_id = int(d.get("next_id", next_id))
