class_name GroundItems
extends RefCounted
## Ressources posées au sol (elles tombent là où on récolte) ; les porteurs les ramènent à la réserve.

signal changed(cell: Vector3i)

var piles: Dictionary = {}  # Vector3i -> {id: n}


func drop(cell: Vector3i, items: Dictionary) -> void:
	var pile: Dictionary = piles.get_or_add(cell, {})
	for id: String in items:
		pile[id] = int(pile.get(id, 0)) + int(items[id])
	changed.emit(cell)


## Prend jusqu'à `n` objets d'une pile (un seul type à la fois). Renvoie {"id", "n"}.
func pick(cell: Vector3i, n: int) -> Dictionary:
	var pile: Dictionary = piles.get(cell, {})
	if pile.is_empty():
		return {}
	var id: String = pile.keys()[0]
	var got := mini(n, int(pile[id]))
	pile[id] = int(pile[id]) - got
	if pile[id] <= 0:
		pile.erase(id)
	if pile.is_empty():
		piles.erase(cell)
	changed.emit(cell)
	return {"id": id, "n": got}


func total() -> int:
	var t := 0
	for c: Vector3i in piles:
		for id: String in piles[c]:
			t += int(piles[c][id])
	return t


func to_dict() -> Dictionary:
	var out := []
	for c: Vector3i in piles:
		out.append([c.x, c.y, c.z, piles[c]])
	return {"piles": out}


func from_dict(d: Dictionary) -> void:
	piles.clear()
	for e: Array in d.get("piles", []):
		var pile := {}
		for id: String in e[3]:
			pile[id] = int(e[3][id])
		piles[Vector3i(int(e[0]), int(e[1]), int(e[2]))] = pile
