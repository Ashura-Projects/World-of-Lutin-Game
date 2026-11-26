class_name TaskCancel
extends RefCounted
## Annulations (1.0.1) : plans, objets démontés, ordres de récolte dans un cercle.


## Objet posé ou en plan sur cette case : plan annulé, ou objet démonté (matériaux rendus à la réserve).
static func remove_structure_at(b: TaskBoard, cell: Vector3i) -> bool:
	if b.structures == null:
		return false
	var s := b.structures.at(cell)
	if s.is_empty():
		return false
	if b._by_cell.has(cell) and b.tasks[b._by_cell[cell]]["kind"] == "build_struct":
		b.cancel(b._by_cell[cell])
		return true
	var cost: Dictionary = Structures.def(s["kind"]).get("cost", {})
	for k: String in cost:
		b.colony.stock.add(k, int(cost[k]))
	for l in b.colony.lutins:
		if l.home == cell:
			l.home = Vector3i(-1, -1, -1)
	b.structures.remove(s["id"])
	return true


## Annuler le dernier groupe de plans posés (bouton ↶ en partie).
static func undo_last_plans(b: TaskBoard) -> int:
	var n := 0
	while not b.batches.is_empty() and n == 0:
		for id: int in b.batches.pop_back():
			if b.tasks.has(id) and b.tasks[id]["reserved"] == -1:
				b.cancel(id)
				n += 1
	return n


## Annuler tous les ordres de récolte dans un cercle (menu Récolter).
static func cancel_in_circle(b: TaskBoard, center: Vector3i, radius: int) -> int:
	var n := 0
	for t: Dictionary in b.tasks.values().duplicate():
		if not t["kind"] in ["cut", "gather", "hunt", "fish", "dig"]:
			continue
		var c: Vector3i = t["cell"]
		if t["kind"] == "hunt":
			var a := b.fauna.find(t["target"])
			if not a.is_empty():
				c = a["cell"]
		if Vector2(c.x - center.x, c.z - center.z).length() <= radius + 0.5:
			b.cancel(t["id"])
			n += 1
	return n
