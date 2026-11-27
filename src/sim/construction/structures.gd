class_name Structures
extends RefCounted
## Bâtiments et objets posés (tente, feu de camp, établi, lit, foyer, porte…) : plan → construit par les bâtisseurs.

signal changed

var items: Dictionary = {}  # id -> {"id", "kind", "cell", "built", "owner"}
var next_id: int = 1


static func def(kind: String) -> Dictionary:
	return DataRegistry.find("buildings", "buildings", kind)


func add(kind: String, cell: Vector3i, built: bool = false) -> int:
	var s := {"id": next_id, "kind": kind, "cell": cell, "built": built, "owner": -1}
	items[next_id] = s
	next_id += 1
	changed.emit()
	return s["id"]


func set_built(id: int) -> void:
	if items.has(id):
		items[id]["built"] = true
		changed.emit()


func remove(id: int) -> void:
	items.erase(id)
	changed.emit()


func at(cell: Vector3i) -> Dictionary:
	for s: Dictionary in items.values():
		if s["cell"] == cell:
			return s
	return {}


func built_with_tag(tag: String) -> Array:
	var out := []
	for s: Dictionary in items.values():
		if s["built"] and def(s["kind"]).get("tags", []).has(tag):
			out.append(s)
	return out


## Donne un lit (tente ou lit) libre à chaque lutin qui n'en a pas.
func assign_homes(colony: Colony) -> void:
	for l in colony.lutins:
		if l.home.y >= 0:
			continue
		for s: Dictionary in items.values():
			if s["built"] and int(def(s["kind"]).get("sleeps", 0)) > 0 and s["owner"] == -1:
				s["owner"] = l.id
				l.home = s["cell"]
				break


## Sources de chaleur construites (feu de camp, foyer…).
func warmth_near(cell: Vector3i, radius: float = 4.0) -> float:
	var w := 0.0
	for s: Dictionary in items.values():
		if s["built"] and def(s["kind"]).has("warmth"):
			if Vector3(s["cell"]).distance_to(Vector3(cell)) <= radius:
				w = maxf(w, float(def(s["kind"])["warmth"]))
	return w


func to_dict() -> Dictionary:
	var out := []
	for s: Dictionary in items.values():
		var c: Vector3i = s["cell"]
		out.append(
			{
				"id": s["id"],
				"kind": s["kind"],
				"cell": [c.x, c.y, c.z],
				"built": s["built"],
				"owner": s["owner"],
				"claimed": s.get("claimed", false)
			}
		)
	return {"items": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	items.clear()
	for e: Dictionary in d.get("items", []):
		var c: Array = e["cell"]
		items[int(e["id"])] = {
			"id": int(e["id"]),
			"kind": e["kind"],
			"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])),
			"built": bool(e["built"]),
			"owner": int(e["owner"]),
			"claimed": bool(e.get("claimed", false))
		}
	next_id = int(d.get("next_id", items.size() + 1))
	changed.emit()
