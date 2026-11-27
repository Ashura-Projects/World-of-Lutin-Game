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


## Objet sur cette case : sa case d'origine, ou n'importe quelle case de son volume (gros ateliers).
func at(cell: Vector3i) -> Dictionary:
	for s: Dictionary in items.values():
		if s["cell"] == cell:
			return s
	for s: Dictionary in items.values():
		var dm := dims(s)
		if dm != Vector3i.ONE and AABB(Vector3(s["cell"]), Vector3(dm)).has_point(Vector3(cell) + Vector3.ONE * 0.5):
			return s
	return {}


## Toutes les cases au sol du futur objet sont libres (aucun autre objet).
func footprint_free(kind: String, cell: Vector3i, rot: int) -> bool:
	var dm := dims({"kind": kind, "rot": rot})
	for x in dm.x:
		for z in dm.z:
			if not at(cell + Vector3i(x, 0, z)).is_empty():
				return false
	return true


## Taille occupée en cases (largeur x, hauteur y, profondeur z), tournée selon le sens de pose.
static func dims(s: Dictionary) -> Vector3i:
	var d := def(s["kind"])
	var sz: Array = d.get("size", [1, 1, 1])
	var x := maxi(1, int(sz[0]))
	var z := maxi(1, int(sz[1])) if sz.size() > 1 else 1
	var h := 1
	if sz.size() > 2 and (sz[2] is int or sz[2] is float):
		h = maxi(1, int(sz[2]))
	if d.get("tags", []).has("door"):
		return Vector3i(1, 2, 1)
	if int(s.get("rot", 0)) % 2 == 1:
		return Vector3i(z, h, x)
	return Vector3i(x, h, z)


## Objet traversé par un rayon (toucher à l'écran), le plus proche avant `max_t`. {} si aucun.
func pick_ray(origin: Vector3, dir: Vector3, max_t: float = 400.0) -> Dictionary:
	var best := {}
	var bt := max_t
	for s: Dictionary in items.values():
		var box := AABB(Vector3(s["cell"]), Vector3(dims(s)))
		var hit: Variant = box.intersects_ray(origin, dir)
		if hit == null:
			continue
		var t := (Vector3(hit) - origin).length()
		if t < bt:
			bt = t
			best = s
	return best


func built_with_tag(tag: String) -> Array:
	var out := []
	for s: Dictionary in items.values():
		if s["built"] and def(s["kind"]).get("tags", []).has(tag):
			out.append(s)
	return out


## Lits : par défaut libres pour tous ; un lit (ou une chambre, une maison) peut être attribué à des lutins précis.
## Les lutins attribués y dorment ; les autres prennent un lit libre (non attribué) qui a encore de la place.
## Places : « sleeps » adultes, plus « child_slots » enfants (tente : 1 ou 2 adultes + 1 enfant).
## Les couples dorment ensemble et les enfants près de leurs parents quand il y a de la place.
func assign_homes(colony: Colony) -> void:
	var beds := items.values().filter(
		func(s: Dictionary) -> bool: return s["built"] and int(def(s["kind"]).get("sleeps", 0)) > 0
	)
	var by_cell := {}
	for s: Dictionary in beds:
		by_cell[s["cell"]] = s
	var occ := {}  # case -> [adultes, enfants]
	var fits := func(s: Dictionary, l: Lutin) -> bool:
		var o: Array = occ.get(s["cell"], [0, 0])
		var d := def(s["kind"])
		if l.can_work():
			return o[0] < int(d.get("sleeps", 1))
		return o[0] + o[1] < int(d.get("sleeps", 1)) + int(d.get("child_slots", 0))
	var take := func(cell: Vector3i, l: Lutin, add: int) -> void:
		var o: Array = occ.get_or_add(cell, [0, 0])
		o[0 if l.can_work() else 1] += add
	for l in colony.lutins:
		var b: Dictionary = by_cell.get(l.home, {})
		var assigned: Array = b.get("assigned", [])
		if b.is_empty() or (not assigned.is_empty() and not assigned.has(l.id)) or not fits.call(b, l):
			l.home = Vector3i(-1, -1, -1)  # lit disparu, plein, ou attribué à quelqu'un d'autre
		else:
			take.call(l.home, l, 1)
	for l in colony.lutins:  # 1) lits attribués
		for s: Dictionary in beds:
			if Array(s.get("assigned", [])).has(l.id) and l.home != s["cell"]:
				if fits.call(s, l):
					if l.home.y >= 0:
						take.call(l.home, l, -1)
					l.home = s["cell"]
					take.call(s["cell"], l, 1)
				break
	for l in colony.lutins:  # 2) lits libres pour tous : d'abord celui du conjoint ou des parents
		if l.home.y >= 0:
			continue
		var near: Array = []
		var partner := Kinship.partner_of(colony, l)
		if partner != null and partner.home.y >= 0:
			near.append(partner.home)
		for p: Lutin in Kinship.parents_of(colony, l):
			if p.home.y >= 0:
				near.append(p.home)
		var choice: Dictionary = {}
		for c: Vector3i in near:
			var s0: Dictionary = by_cell.get(c, {})
			if not s0.is_empty() and Array(s0.get("assigned", [])).is_empty() and fits.call(s0, l):
				choice = s0
				break
		if choice.is_empty():
			for s: Dictionary in beds:
				if Array(s.get("assigned", [])).is_empty() and fits.call(s, l):
					choice = s
					break
		if not choice.is_empty():
			l.home = choice["cell"]
			take.call(choice["cell"], l, 1)
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
				"assigned": s.get("assigned", []),
				"epitaph": s.get("epitaph", ""),
				"yaw": s.get("yaw", 0.0),
				"loaded": s.get("loaded", false),
				"rack": s.get("rack", "all")
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
			"assigned": Array(e.get("assigned", [])).map(func(x: Variant) -> int: return int(x)),
			"epitaph": str(e.get("epitaph", "")),
			"yaw": float(e.get("yaw", 0.0)),
			"loaded": bool(e.get("loaded", false)),
			"rack": str(e.get("rack", "all"))
		}
	next_id = int(d.get("next_id", items.size() + 1))
	changed.emit()
