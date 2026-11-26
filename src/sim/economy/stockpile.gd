class_name Stockpile
extends RefCounted
## Réserve de ressources (le chariot de départ est la première réserve). Quantités entières par id de ressource.

var items: Dictionary = {}
var pos := Vector3i.ZERO


func add(id: String, n: int) -> void:
	if n <= 0:
		return
	items[id] = int(items.get(id, 0)) + n


func count(id: String) -> int:
	return int(items.get(id, 0))


func take(id: String, n: int) -> int:
	var got := mini(n, count(id))
	if got > 0:
		items[id] = count(id) - got
		if items[id] == 0:
			items.erase(id)
	return got


## Somme de toute la nourriture (catégorie food) : c'est la « Nourriture » affichée en haut.
func food_total() -> int:
	var total := 0
	for id: String in items:
		if _resource(id).get("category", "") == "food":
			total += count(id)
	return total


## Prend l'aliment le plus nourrissant disponible ; renvoie sa valeur nutritive (0 si rien).
func take_best_food() -> int:
	var best := ""
	var best_n := 0
	for id: String in items:
		var r := _resource(id)
		if r.get("category", "") == "food" and int(r.get("nutrition", 0)) > best_n:
			best = id
			best_n = int(r["nutrition"])
	if best == "":
		return 0
	take(best, 1)
	return best_n


static func _resource(id: String) -> Dictionary:
	return DataRegistry.find("resources", "resources", id)


func to_dict() -> Dictionary:
	return {"items": items.duplicate(), "pos": [pos.x, pos.y, pos.z]}


func from_dict(d: Dictionary) -> void:
	items = {}
	var src: Dictionary = d.get("items", {})
	for k: String in src:
		items[k] = int(src[k])
	var p: Array = d.get("pos", [0, 0, 0])
	pos = Vector3i(int(p[0]), int(p[1]), int(p[2]))
