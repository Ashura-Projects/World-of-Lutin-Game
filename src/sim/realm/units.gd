class_name Units
extends RefCounted
## Unités militaires (1.1) : un capitaine et des lutins, une formation (ligne, colonne, carré, coin)
## et des ordres : aller à, attaquer (armes prises, combat autour du point), tenir, rentrer.

static var active: Units = null

var colony: Colony
var combat: Combat
var units: Dictionary = {}  # id -> {"id","name","captain","members","formation","order","cell","dir"}
var next_id: int = 1
var _cfg: Dictionary


func _init(c: Colony, cb: Combat) -> void:
	colony = c
	combat = cb
	_cfg = DataRegistry.get_table("realm").get("units", {})
	active = self


func formations() -> Array:
	return _cfg.get("formations", [])


## Crée une unité. Le capitaine en fait partie ; un lutin ne peut être que dans une unité.
func create(name: String, captain_id: int, member_ids: Array) -> int:
	var cap := colony.find_lutin(captain_id)
	if cap == null:
		return -1
	var ids: Array = [captain_id]
	for m: int in member_ids:
		if not ids.has(m) and colony.find_lutin(m) != null and ids.size() < int(_cfg.get("max_members", 12)):
			ids.append(m)
	for m: int in ids:
		_leave(colony.find_lutin(m))
	var id := next_id
	next_id += 1
	var u := {
		"id": id,
		"name": name,
		"captain": captain_id,
		"members": ids,
		"formation": "line",
		"order": "none",
		"cell": cap.cell,
		"dir": Vector2(0, -1)
	}
	UnitSetup.defaults(u)
	units[id] = u
	for m: int in ids:
		colony.find_lutin(m).unit_id = id
	return id


func _leave(l: Lutin) -> void:
	if l == null or not units.has(l.unit_id):
		if l != null:
			l.unit_id = -1
		return
	var u: Dictionary = units[l.unit_id]
	u["members"].erase(l.id)
	if int(u.get("cook", -1)) == l.id:
		u["cook"] = -1
	for s: Variant in u.get("lieutenants", {}).keys():
		if int(u["lieutenants"][s]) == l.id:
			u["lieutenants"].erase(s)
	if u.has("squads"):
		u["squads"].erase(l.id)
	l.unit_id = -1
	if u["members"].is_empty():
		units.erase(u["id"])
	elif u["captain"] == l.id:
		u["captain"] = u["members"][0]


func disband(id: int) -> void:
	if not units.has(id):
		return
	command(id, "return")
	for m: int in units[id]["members"].duplicate():
		var l := colony.find_lutin(m)
		if l != null:
			l.unit_id = -1
	units.erase(id)


func set_formation(id: int, f: String) -> void:
	if units.has(id):
		units[id]["formation"] = f
		if units[id]["order"] in ["move", "attack"]:
			command(id, units[id]["order"], units[id]["cell"])


## Ordre à l'unité : move (aller en formation), attack (armes + combat), hold (rester), return (vie normale),
## rest (camp de tentes, le cuisinier fait à manger), train (sol d'entraînement). squad : -1 = toute l'unité,
## 0 = la sous-unité du commandant, 1 = celle du lieutenant (commandées séparément).
func command(id: int, kind: String, cell: Vector3i = Vector3i(-1, -1, -1), squad: int = -1) -> void:
	if not units.has(id):
		return
	var u: Dictionary = units[id]
	var view := u if squad < 0 else squad_view(u, squad)
	if cell.y >= 0:
		var lead := colony.find_lutin(int(view["captain"]))
		var from: Vector3i = lead.cell if lead != null else view["cell"]
		var d := Vector2(cell.x - from.x, cell.z - from.z)
		if d.length() > 0.5:
			view["dir"] = d.normalized()
		view["cell"] = cell
	view["order"] = kind
	if squad >= 0:
		u["sq%d" % squad] = {"cell": view["cell"], "dir": view["dir"], "order": kind}
	else:
		for k: String in u.keys().filter(
			func(x: Variant) -> bool: return str(x).begins_with("sq") and str(x) != "squads"
		):
			u.erase(k)
	if kind != "rest":
		UnitCamp.break_camp(self, u)
	if kind == "rest":
		UnitCamp.make_camp(self, u)
		return
	if kind == "train":
		UnitCamp.go_train(self, u)
		return
	var members: Array = view["members"]
	var places := slots(view)
	if kind in ["move", "attack"] and int(u.get("catapult_id", -1)) >= 0 and cell.y >= 0:
		UnitCamp.serve_catapult(self, u, kind, cell)
	for i in members.size():
		var l := colony.find_lutin(members[i])
		if l == null or l.jailed.y >= 0:
			continue
		match kind:
			"move":
				if l.mobilized and combat.alert != "mobilize":
					combat.disarm(l)
				LutinOrders.give(colony, colony.task_board, l, "move", places[i], {"hold_s": 600.0})
			"attack":
				combat.arm(l)
			"hold":
				if not l.mobilized:
					LutinOrders.give(colony, colony.task_board, l, "move", l.cell, {"hold_s": 600.0})
			"explore":
				LutinOrders.give(colony, colony.task_board, l, "explore", l.cell)
			"return":
				l.order = {}
				if combat.alert != "mobilize":
					combat.disarm(l)


## Vue d'une sous-unité (0 : commandant et les siens ; 1, 2… : un lieutenant et les siens), formation et ordre.
func squad_view(u: Dictionary, squad: int) -> Dictionary:
	var ids := Array(u["members"]).filter(func(m: int) -> bool: return UnitSetup.squad_of(u, m) == squad)
	var lead: int = int(u["captain"]) if squad == 0 else UnitSetup.lieutenant_of(u, squad)
	if lead < 0 and not ids.is_empty():
		lead = ids[0]
	var st: Dictionary = u.get("sq%d" % squad, {})
	return {
		"captain": lead,
		"members": ids,
		"formation": u["formation"],
		"cell": st.get("cell", u["cell"]),
		"dir": st.get("dir", u["dir"]),
		"order": st.get("order", u["order"])
	}


## Décalage du i-ème membre (x = sur le côté, y = vers l'arrière), en cases entières : rangs bien alignés.
func offset(formation: String, i: int, n: int) -> Vector2i:
	var sp := maxi(1, int(_cfg.get("spacing", 1)))
	match formation:
		"line":
			return Vector2i((i - n / 2) * sp, 0)
		"column":
			return Vector2i(0, i * sp)
		"double_line":
			var half := (n + 1) / 2
			return Vector2i(((i % half) - half / 2) * sp, (i / half) * sp)
		"square":
			var side := ceili(sqrt(n))
			return Vector2i((i % side - side / 2) * sp, (i / side) * sp)
		"wedge":
			var row := ceili((sqrt(8.0 * i + 1.0) - 1.0) / 2.0) if i > 0 else 0
			var first := row * (row - 1) / 2 + 1 if row > 0 else 0
			return Vector2i(((i - first) * 2 - row + 1) * sp if row > 0 else 0, row * sp)
	return Vector2i.ZERO


## Places de tous les membres : une case différente par lutin (jamais deux au même endroit), rangs alignés
## sur la grille dans la direction de marche (arrondie aux 4 directions).
func slots(u: Dictionary) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var used := {}
	var n: int = u["members"].size()
	var dv: Vector2 = u["dir"]
	var fwd := Vector2i(0, signi(roundi(dv.y))) if absf(dv.y) >= absf(dv.x) else Vector2i(signi(roundi(dv.x)), 0)
	if fwd == Vector2i.ZERO:
		fwd = Vector2i(0, -1)
	var side_v := Vector2i(-fwd.y, fwd.x)
	var c: Vector3i = u["cell"]
	for i in n:
		var off := offset(str(u["formation"]), i, n)
		var w := side_v * off.x - fwd * off.y
		var p := Pathfinder.snap(colony.world, Vector3i(c.x + w.x, c.y, c.z + w.y))
		if p.y < 0 or used.has(Vector2i(p.x, p.z)):
			p = _free_near(Vector3i(c.x + w.x, c.y, c.z + w.y), used)
		used[Vector2i(p.x, p.z)] = true
		out.append(p)
	return out


## Case libre et marchable la plus proche (spirale), pour ne jamais empiler deux soldats.
func _free_near(p: Vector3i, used: Dictionary) -> Vector3i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q := Pathfinder.snap(colony.world, p + Vector3i(dx, 0, dz))
				if q.y >= 0 and not used.has(Vector2i(q.x, q.z)):
					return q
	return p


## Place du i-ème membre dans la formation (le capitaine, i = 0, est devant au centre).
func slot(u: Dictionary, i: int) -> Vector3i:
	var all := slots(u)
	return all[i] if i >= 0 and i < all.size() else u["cell"]


## Point de ralliement d'un membre mobilisé (sa place dans la formation autour du point d'attaque).
func rally_for(l: Lutin, fallback: Vector3i) -> Vector3i:
	if not units.has(l.unit_id):
		return fallback
	var u: Dictionary = units[l.unit_id]
	var sq := UnitSetup.squad_of(u, l.id)
	var view := squad_view(u, sq) if u.has("sq%d" % sq) else u
	if view["order"] != "attack":
		return fallback
	return slot(view, Array(view["members"]).find(l.id))


func unit_of(l: Lutin) -> Dictionary:
	return units.get(l.unit_id, {})


func to_dict() -> Dictionary:
	var out := []
	for u: Dictionary in units.values():
		var c: Vector3i = u["cell"]
		var dv: Vector2 = u["dir"]
		out.append(
			{
				"id": u["id"],
				"name": u["name"],
				"captain": u["captain"],
				"members": u["members"],
				"formation": u["formation"],
				"order": u["order"],
				"cell": [c.x, c.y, c.z],
				"dir": [dv.x, dv.y],
				"setup": UnitSetup.gear_to_dict(u)
			}
		)
	return {"units": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	units.clear()
	for e: Dictionary in d.get("units", []):
		var c: Array = e["cell"]
		var dv: Array = e.get("dir", [0, -1])
		var members: Array = []
		for m in e["members"]:
			members.append(int(m))
		units[int(e["id"])] = {
			"id": int(e["id"]),
			"name": str(e["name"]),
			"captain": int(e["captain"]),
			"members": members,
			"formation": str(e["formation"]),
			"order": str(e["order"]),
			"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])),
			"dir": Vector2(float(dv[0]), float(dv[1]))
		}
		UnitSetup.gear_from_dict(units[int(e["id"])], e.get("setup", {}))
	next_id = int(d.get("next_id", units.size() + 1))
	active = self
