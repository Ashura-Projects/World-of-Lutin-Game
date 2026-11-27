class_name Structures
extends RefCounted
## Bâtiments et objets posés (tente, feu de camp, établi, lit, foyer, porte…) : plan → construit par les bâtisseurs.

signal changed

var items: Dictionary = {}  # id -> {"id", "kind", "cell", "built", "owner"}
var next_id: int = 1


static func def(kind: String) -> Dictionary:
	return DataRegistry.find("buildings", "buildings", kind)


func add(kind: String, cell: Vector3i, built: bool = false, extra: Dictionary = {}) -> int:
	var s := {"id": next_id, "kind": kind, "cell": cell, "built": built, "owner": -1}
	s.merge(extra, true)  # sens, taille de pont-levis… (avant le signal : les herses en ont besoin)
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


## Lits : par défaut libres pour tous ; un lit (ou une chambre) peut être attribué à des lutins précis.
## Les lutins attribués y dorment ; les autres prennent un lit libre (non attribué) qui a encore de la place.
func assign_homes(colony: Colony) -> void:
	var beds := items.values().filter(
		func(s: Dictionary) -> bool: return s["built"] and int(def(s["kind"]).get("sleeps", 0)) > 0
	)
	var by_cell := {}
	for s: Dictionary in beds:
		by_cell[s["cell"]] = s
	var count := {}
	for l in colony.lutins:
		var b: Dictionary = by_cell.get(l.home, {})
		var assigned: Array = b.get("assigned", [])
		if b.is_empty() or (not assigned.is_empty() and not assigned.has(l.id)):
			l.home = Vector3i(-1, -1, -1)  # lit disparu ou attribué à quelqu'un d'autre
		else:
			count[l.home] = int(count.get(l.home, 0)) + 1
	for l in colony.lutins:  # 1) lits attribués
		for s: Dictionary in beds:
			if Array(s.get("assigned", [])).has(l.id) and l.home != s["cell"]:
				if int(count.get(s["cell"], 0)) < int(def(s["kind"]).get("sleeps", 1)):
					if l.home.y >= 0:
						count[l.home] = int(count[l.home]) - 1
					l.home = s["cell"]
					count[s["cell"]] = int(count.get(s["cell"], 0)) + 1
				break
	for l in colony.lutins:  # 2) lits libres pour tous
		if l.home.y >= 0:
			continue
		for s: Dictionary in beds:
			var cap := int(def(s["kind"]).get("sleeps", 1))
			if Array(s.get("assigned", [])).is_empty() and int(count.get(s["cell"], 0)) < cap:
				l.home = s["cell"]
				count[s["cell"]] = int(count.get(s["cell"], 0)) + 1
				break
	for s: Dictionary in beds:
		s["owner"] = -1
		for l in colony.lutins:
			if l.home == s["cell"]:
				s["owner"] = l.id
				break


## Attribue un lit à des lutins (liste vide = libre pour tous).
func assign_bed(id: int, lutin_ids: Array, colony: Colony) -> void:
	if items.has(id):
		items[id]["assigned"] = lutin_ids.duplicate()
		assign_homes(colony)


## Attribue tous les lits d'une pièce (chambre) à des lutins.
func assign_room(room_cells: Dictionary, lutin_ids: Array, colony: Colony) -> int:
	var n := 0
	for s: Dictionary in items.values():
		if s["built"] and int(def(s["kind"]).get("sleeps", 0)) > 0 and room_cells.has(s["cell"]):
			s["assigned"] = lutin_ids.duplicate()
			n += 1
	assign_homes(colony)
	return n


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
				"claimed": s.get("claimed", false),
				"rot": s.get("rot", 0),
				"gate_w": s.get("gate_w", 2),
				"gate_l": s.get("gate_l", 2),
				"assigned": s.get("assigned", [])
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
			"claimed": bool(e.get("claimed", false)),
			"rot": int(e.get("rot", 0)),
			"gate_w": int(e.get("gate_w", 2)),
			"gate_l": int(e.get("gate_l", 2)),
			"assigned": Array(e.get("assigned", [])).map(func(x: Variant) -> int: return int(x))
		}
	next_id = int(d.get("next_id", items.size() + 1))
	changed.emit()
