class_name Territory
extends RefCounted
## Territoires (Phase 3) : la carte est découpée en colonnes de 16 × 16 blocs ; chacune appartient à une faction
## (« player », « jaune », « rouge », « vert », « orcs ») ou à personne. On revendique avec une borne de territoire.

signal changed

var world: VoxelWorld
var owners: Dictionary = {}  # Vector2i (colonne) -> id faction
var explored: Dictionary = {}  # Vector2i -> true (brouillard de la carte)
var markers: Array = []  # marqueurs du joueur : {"cell": Vector2i (blocs), "icon": String, "label": String}
var version: int = 0
var size: int = 16


func _init(w: VoxelWorld) -> void:
	world = w
	size = int(DataRegistry.get_table("factions").get("territory", {}).get("chunk", 16))


func col_of(cell: Vector3i) -> Vector2i:
	return Vector2i(cell.x / size, cell.z / size)


func cols() -> Vector2i:
	return Vector2i(ceili(float(world.size.x) / size), ceili(float(world.size.z) / size))


func in_map(c: Vector2i) -> bool:
	var n := cols()
	return c.x >= 0 and c.y >= 0 and c.x < n.x and c.y < n.y


func owner_at(cell: Vector3i) -> String:
	return str(owners.get(col_of(cell), ""))


## Revendique les colonnes autour d'une case (rayon en colonnes). force = prendre aussi celles des autres.
func claim(cell: Vector3i, radius: int, faction: String, force: bool = false) -> int:
	var c0 := col_of(cell)
	var n := 0
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var c := c0 + Vector2i(dx, dz)
			if not in_map(c) or Vector2(dx, dz).length() > radius + 0.5:
				continue
			var cur := str(owners.get(c, ""))
			if cur == faction or (cur != "" and not force):
				continue
			owners[c] = faction
			n += 1
	if n > 0:
		version += 1
		changed.emit()
	return n


## Toutes les colonnes d'une faction passent à une autre (conquête).
func transfer(from: String, to: String) -> int:
	var n := 0
	for c: Vector2i in owners:
		if owners[c] == from:
			owners[c] = to
			n += 1
	version += 1
	changed.emit()
	return n


func count(faction: String) -> int:
	return owners.values().count(faction)


## Colonne libre voisine du territoire d'une faction (pour l'expansion de l'IA), ou (-1, -1).
func free_neighbour(faction: String) -> Vector2i:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var cands: Array = []
	for c: Vector2i in owners:
		if owners[c] != faction:
			continue
		for d: Vector2i in dirs:
			var q: Vector2i = c + d
			if in_map(q) and not owners.has(q):
				cands.append(q)
	if cands.is_empty():
		return Vector2i(-1, -1)
	return cands[Rng.randi_range(0, cands.size() - 1)]


## Les lutins découvrent la carte autour d'eux (rayon en colonnes).
func explore(cell: Vector3i, radius: int = 2) -> void:
	var c0 := col_of(cell)
	var added := false
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var c := c0 + Vector2i(dx, dz)
			if in_map(c) and not explored.has(c):
				explored[c] = true
				added = true
	if added:
		version += 1


func reveal_all() -> void:
	var n := cols()
	for x in n.x:
		for z in n.y:
			explored[Vector2i(x, z)] = true
	version += 1


func add_marker(cell: Vector2i, icon: String, label: String) -> void:
	markers.append({"cell": cell, "icon": icon, "label": label})
	version += 1


func remove_marker_near(cell: Vector2i, radius: float = 10.0) -> bool:
	for m: Dictionary in markers:
		if Vector2(m["cell"]).distance_to(Vector2(cell)) <= radius:
			markers.erase(m)
			version += 1
			return true
	return false


func to_dict() -> Dictionary:
	var o := []
	for c: Vector2i in owners:
		o.append([c.x, c.y, owners[c]])
	var e := []
	for c: Vector2i in explored:
		e.append([c.x, c.y])
	var m := []
	for k: Dictionary in markers:
		m.append([k["cell"].x, k["cell"].y, k["icon"], k["label"]])
	return {"owners": o, "explored": e, "markers": m}


func from_dict(d: Dictionary) -> void:
	owners.clear()
	for e: Array in d.get("owners", []):
		owners[Vector2i(int(e[0]), int(e[1]))] = str(e[2])
	explored.clear()
	for e: Array in d.get("explored", []):
		explored[Vector2i(int(e[0]), int(e[1]))] = true
	markers.clear()
	for e: Array in d.get("markers", []):
		markers.append({"cell": Vector2i(int(e[0]), int(e[1])), "icon": str(e[2]), "label": str(e[3])})
	version += 1
