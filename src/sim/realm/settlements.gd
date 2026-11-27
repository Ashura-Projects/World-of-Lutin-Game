class_name Settlements
extends RefCounted
## Villages et villes (1.4). La balise de royaume (claim_post) revendique le territoire ; la balise de village
## (village_post) fonde un établissement : un village, qui devient une ville avec au moins 50 habitants et tous les
## bâtiments de base (château du seigneur = salle du trône, geôle d'au moins 5 cages, une maison par foyer, caserne,
## camp d'entraînement). Un lutin, un bâtiment ou un soldat appartient à l'établissement le plus proche (rayon).
## Le premier village est fondé au point de départ. Données : data/realm.json › settlements.

signal changed

var colony: Colony
var structures: Structures
var world: VoxelWorld
var items: Array = []  # [{"id", "name", "cell": Vector3i, "kind": "village"/"city", "post": id balise}]
var next_id: int = 1


func _init(c: Colony, s: Structures, w: VoxelWorld) -> void:
	colony = c
	structures = s
	world = w


static func cfg() -> Dictionary:
	return DataRegistry.get_table("realm").get("settlements", {})


func radius() -> float:
	return float(cfg().get("radius", 40))


func found(name: String, cell: Vector3i, post: int = -1) -> Dictionary:
	var e := {"id": next_id, "name": name, "cell": cell, "kind": "village", "post": post}
	next_id += 1
	items.append(e)
	changed.emit()
	return e


func find(id: int) -> Dictionary:
	for e: Dictionary in items:
		if int(e["id"]) == id:
			return e
	return {}


## Établissement d'une case : le plus proche dans le rayon, sinon {}.
func at(cell: Vector3i) -> Dictionary:
	var best: Dictionary = {}
	var bd := radius()
	for e: Dictionary in items:
		var d := Vector2(cell.x - e["cell"].x, cell.z - e["cell"].z).length()
		if d <= bd:
			bd = d
			best = e
	return best


## Établissement d'un lutin : celui de son foyer, sinon de l'endroit où il est.
func of_lutin(l: Lutin) -> Dictionary:
	return at(l.home if l.home.y >= 0 else l.cell)


## Balises de village bâties → nouveaux villages ; balises démontées → village oublié (sauf le premier).
func sync() -> void:
	var posts := {}
	for s: Dictionary in structures.built_with_tag("village_post"):
		posts[int(s["id"])] = s
		if items.any(func(e: Dictionary) -> bool: return int(e["post"]) == int(s["id"])):
			continue
		var names: Array = cfg().get("names", ["Nouveau village"])
		found(str(names[items.size() % names.size()]), s["cell"], int(s["id"]))
		EventBus.alert.emit("faction", "Nouveau village fondé : %s." % items[-1]["name"])
	for e: Dictionary in items.duplicate():
		if int(e["post"]) >= 0 and not posts.has(int(e["post"])):
			items.erase(e)
			changed.emit()


func residents(e: Dictionary) -> Array:
	return colony.lutins.filter(func(l: Lutin) -> bool: return int(of_lutin(l).get("id", -1)) == int(e["id"]))


## Foyers : couples (et leurs enfants) et célibataires adultes.
func households(e: Dictionary) -> Array:
	var out := []
	var seen := {}
	for l: Lutin in residents(e):
		if seen.has(l.id) or not l.can_work():
			continue
		var h := [l]
		seen[l.id] = true
		var p := Kinship.partner_of(colony, l)
		if p != null and not seen.has(p.id):
			h.append(p)
			seen[p.id] = true
		for c: Lutin in Kinship.children_of(colony, l):
			if not seen.has(c.id) and not c.can_work():
				h.append(c)
				seen[c.id] = true
		out.append(h)
	return out


func structures_in(e: Dictionary) -> Array:
	return structures.items.values().filter(
		func(s: Dictionary) -> bool: return int(at(s["cell"]).get("id", -1)) == int(e["id"])
	)


## Pièces de l'établissement (une fois chacune) : [{"type", "cells", "beds": [structures]}].
func rooms(e: Dictionary) -> Array:
	var out := []
	var done := {}
	for s: Dictionary in structures_in(e):
		if done.has(s["cell"]):
			continue
		var r := RoomDetector.room_at(world, structures, s["cell"])
		if r.is_empty():
			continue
		for c: Vector3i in r["cells"]:
			done[c] = true
		var beds := []
		for s2: Dictionary in structures.items.values():
			if r["cells"].has(s2["cell"]) and int(Structures.def(s2["kind"]).get("sleeps", 0)) > 0:
				beds.append(s2)
		out.append({"type": r["type"], "cells": r["cells"], "beds": beds})
	return out


## Règles de ville : renvoie [ok, liste de « ✓ / ✗ règle »].
func city_check(e: Dictionary) -> Array:
	var c := cfg()
	var rs := rooms(e)
	var types := rs.map(func(r: Dictionary) -> String: return str(r["type"]))
	var houses := rs.filter(func(r: Dictionary) -> bool: return not Array(r["beds"]).is_empty()).size()
	var cages := (
		structures_in(e)
		. filter(
			func(s: Dictionary) -> bool: return s["built"] and Structures.def(s["kind"]).get("tags", []).has("cage")
		)
		. size()
	)
	var training := 0
	if Realm.active != null:
		for cell: Vector3i in Realm.active.training_cells:
			if int(at(cell).get("id", -1)) == int(e["id"]):
				training += 1
	var rules := [
		[
			residents(e).size() >= int(c.get("city_residents", 50)),
			"%d habitants (%d)" % [int(c.get("city_residents", 50)), residents(e).size()]
		],
		[types.has("throne_room"), "Château du seigneur (salle du trône)"],
		[cages >= int(c.get("city_cages", 5)), "Geôle : %d cages (%d)" % [int(c.get("city_cages", 5)), cages]],
		[
			houses >= households(e).size() and houses > 0,
			"Une maison par foyer (%d / %d)" % [houses, households(e).size()]
		],
		[types.has("garrison") and types.has("refectory"), "Caserne (garnison + réfectoire)"],
		[training >= int(c.get("city_training_cells", 4)), "Camp d'entraînement (%d cases)" % training]
	]
	var ok := rules.all(func(r: Array) -> bool: return r[0])
	return [ok, rules.map(func(r: Array) -> String: return ("✓ " if r[0] else "✗ ") + str(r[1]))]


## Chaque jour : villages qui deviennent villes (ou redeviennent villages).
func daily() -> void:
	sync()
	for e: Dictionary in items:
		var ok: bool = city_check(e)[0]
		if ok and e["kind"] != "city":
			e["kind"] = "city"
			EventBus.alert.emit("faction", "%s devient une ville !" % e["name"])
		elif not ok and e["kind"] == "city":
			e["kind"] = "village"
			EventBus.alert.emit("alerte", "%s n'a plus tout ce qu'il faut : redevient un village." % e["name"])


func to_dict() -> Dictionary:
	var out := []
	for e: Dictionary in items:
		var c: Vector3i = e["cell"]
		out.append({"id": e["id"], "name": e["name"], "cell": [c.x, c.y, c.z], "kind": e["kind"], "post": e["post"]})
	return {"items": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	items.clear()
	for e: Dictionary in d.get("items", []):
		var c: Array = e["cell"]
		items.append(
			{
				"id": int(e["id"]),
				"name": str(e["name"]),
				"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])),
				"kind": str(e.get("kind", "village")),
				"post": int(e.get("post", -1))
			}
		)
	next_id = int(d.get("next_id", items.size() + 1))
	changed.emit()
