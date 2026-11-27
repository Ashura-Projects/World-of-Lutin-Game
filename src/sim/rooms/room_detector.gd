class_name RoomDetector
extends RefCounted
## Détection des pièces : volume d'air fermé (murs + toit) ; typé selon les objets qu'il contient (data/rooms.json).


## Pièce qui contient `cell` : {"cells": Dictionary, "type": String, "tags": Array} ou {} si l'air s'échappe.
static func room_at(world: VoxelWorld, structures: Structures, cell: Vector3i) -> Dictionary:
	var max_cells := int(DataRegistry.get_table("rooms").get("detector", {}).get("max_cells", 600))
	if world.types.solid[world.get_block(cell)] == 1:
		return {}
	var doors := {}
	for s: Dictionary in structures.items.values():
		if s["built"] and s["kind"] == "door":
			doors[s["cell"]] = true
			doors[s["cell"] + Vector3i.UP] = true
	var seen := {cell: true}
	var stack: Array[Vector3i] = [cell]
	while not stack.is_empty():
		var p: Vector3i = stack.pop_back()
		for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
			var q := p + d
			if seen.has(q) or doors.has(q):
				continue
			if not world.in_bounds(q) or q.y >= world.size.y - 1:
				return {}  # ouvert sur l'extérieur
			if world.types.solid[world.get_block(q)] == 1:
				continue
			seen[q] = true
			if seen.size() > max_cells:
				return {}
			stack.append(q)
	var tags := []
	for s: Dictionary in structures.items.values():
		if s["built"] and seen.has(s["cell"]):
			for t: String in Structures.def(s["kind"]).get("tags", []):
				tags.append(t)
	# vitraux : fenêtres « vitrail » dans les murs de la pièce
	if not world.shapes.is_empty():
		var glass := {}
		for p: Vector3i in seen:
			for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
				if world.get_shape(p + d) / 4 == ShapeMesh.Shape.WINDOW_STAINED:
					glass[p + d] = true
		for _g in glass:
			tags.append("stained_glass")
	return {"cells": seen, "type": room_type(tags), "tags": tags}


static func room_type(tags: Array) -> String:
	var best := "empty"
	var best_p := -1
	for r: Dictionary in DataRegistry.get_table("rooms").get("room_types", []):
		var ok := true
		for req: String in r.get("requires", []):
			if not tags.has(req):
				ok = false
		if r.has("requires_any_tag") and not tags.has(r["requires_any_tag"]):
			ok = false
		var counts: Dictionary = r.get("min_counts", {})
		for t: String in counts:
			if tags.count(t) < int(counts[t]):
				ok = false
		var beds := tags.count("bed")
		if r.has("min_beds") and beds < int(r["min_beds"]):
			ok = false
		if r.has("max_beds") and beds > int(r["max_beds"]):
			ok = false
		if ok and int(r["priority"]) > best_p:
			best_p = int(r["priority"])
			best = r["id"]
	return best
