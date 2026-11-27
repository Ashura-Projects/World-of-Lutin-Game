class_name StoreZones
extends RefCounted
## Zones de réserve (1.1) : groupes de cases au sol où les lutins déposent et prennent les ressources.
## Chaque zone a un filtre : tout, ou des catégories, ou des objets précis (au choix du joueur).
## Le stock reste commun ; une zone décide seulement OÙ chaque ressource est apportée et prise.

var world: VoxelWorld
var zones: Array = []  # [{"id", "cells": Array[Vector3i], "filter": {"all": bool, "cats": [], "items": []}}]
var next_id: int = 1
var version: int = 0  # change à chaque modification (pour la vue)


func _init(w: VoxelWorld) -> void:
	world = w


func cells() -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for z: Dictionary in zones:
		out.append_array(z["cells"])
	return out


func zone_at(cell: Vector3i) -> Dictionary:
	for z: Dictionary in zones:
		if z["cells"].has(cell):
			return z
	return {}


## Nouvelle zone avec les cases praticables pas encore prises. Renvoie l'id (ou -1 si aucune case).
func add_zone(new_cells: Array) -> int:
	var ok: Array[Vector3i] = []
	for c: Vector3i in new_cells:
		if not ok.has(c) and zone_at(c).is_empty() and Pathfinder.walkable(world, c):
			ok.append(c)
	if ok.is_empty():
		return -1
	var id := next_id
	next_id += 1
	zones.append({"id": id, "cells": ok, "filter": {"all": true, "cats": [], "items": []}})
	version += 1
	return id


func remove_cells(del: Array) -> void:
	for z: Dictionary in zones:
		for c: Vector3i in del:
			z["cells"].erase(c)
	zones = zones.filter(func(z: Dictionary) -> bool: return not z["cells"].is_empty())
	version += 1


func find(id: int) -> Dictionary:
	for z: Dictionary in zones:
		if z["id"] == id:
			return z
	return {}


func set_filter(id: int, all: bool, cats: Array, items: Array) -> void:
	var z := find(id)
	if not z.is_empty():
		z["filter"] = {"all": all, "cats": cats.duplicate(), "items": items.duplicate()}
		version += 1


## La zone accepte-t-elle cet objet ? "" = n'importe quoi ; "food" = n'importe quel aliment.
static func accepts(z: Dictionary, item: String) -> bool:
	var f: Dictionary = z["filter"]
	if f.get("all", true) or item == "":
		return true
	if item == "food":
		if f["cats"].has("food"):
			return true
		return f["items"].any(func(i: String) -> bool: return Stockpile._resource(i).get("category", "") == "food")
	return f["items"].has(item) or f["cats"].has(str(Stockpile._resource(item).get("category", "")))


## Tas visibles (1.3.2) : la réserve répartie dans les cases des zones, un tas d'une seule matière par case,
## au plus `pile_size` unités par tas (ex. zone 2×2 de paille = 4 tas de 50). Les zones qui filtrent une matière
## passent en premier, puis les zones « tout ». Renvoie case -> [matière, quantité].
func layout(items: Dictionary, pile_size: int) -> Dictionary:
	var out := {}
	var left := {}
	for k: String in items:
		if int(items[k]) > 0 and k != "gold":
			left[k] = int(items[k])
	var keys := left.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(left[a]) > int(left[b]))
	for pass_all: bool in [false, true]:
		for z: Dictionary in zones:
			if bool(z["filter"].get("all", true)) != pass_all:
				continue
			var free: Array = z["cells"].filter(func(c: Vector3i) -> bool: return not out.has(c))
			for k: String in keys:
				if free.is_empty():
					break
				if int(left[k]) <= 0 or not accepts(z, k):
					continue
				while int(left[k]) > 0 and not free.is_empty():
					var n := mini(pile_size, int(left[k]))
					out[free.pop_front()] = [k, n]
					left[k] = int(left[k]) - n
	return out


## Case de zone la plus proche qui accepte l'objet ; sinon `fallback` (la charrette, qui accepte tout).
func nearest(cell: Vector3i, item: String, fallback: Vector3i) -> Vector3i:
	var best := fallback
	var bd := Vector3(cell).distance_squared_to(Vector3(fallback))
	for z: Dictionary in zones:
		if not accepts(z, item):
			continue
		for c: Vector3i in z["cells"]:
			var d := Vector3(cell).distance_squared_to(Vector3(c))
			if d < bd:
				bd = d
				best = c
	return best


func to_dict() -> Array:
	var out := []
	for z: Dictionary in zones:
		var cs := []
		for c: Vector3i in z["cells"]:
			cs.append([c.x, c.y, c.z])
		out.append({"id": z["id"], "cells": cs, "filter": z["filter"]})
	return out


func from_dict(arr: Array) -> void:
	zones.clear()
	next_id = 1
	for e: Dictionary in arr:
		var cs: Array[Vector3i] = []
		for c: Array in e["cells"]:
			cs.append(Vector3i(int(c[0]), int(c[1]), int(c[2])))
		var f: Dictionary = e.get("filter", {})
		var filt := {
			"all": bool(f.get("all", true)), "cats": Array(f.get("cats", [])), "items": Array(f.get("items", []))
		}
		zones.append({"id": int(e["id"]), "cells": cs, "filter": filt})
		next_id = maxi(next_id, int(e["id"]) + 1)
	version += 1
