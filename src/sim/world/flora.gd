class_name Flora
extends RefCounted
## Végétation récoltable : arbres (bûches), buissons à baies, plantes sauvages (lin, plantes médicinales).

signal changed(kind: String)

var trees: Dictionary = {}  # Vector3i -> espèce
var bushes: Dictionary = {}  # Vector3i -> jour de repousse (0 = prêt)
var herbs: Dictionary = {}  # Vector3i -> id (wild_flax, medicinal_herb)


func load_from_generator(g: WorldGenerator) -> void:
	for t: Dictionary in g.trees:
		trees[t["pos"]] = t["kind"]
	for b: Dictionary in g.bushes:
		bushes[b["pos"]] = 0
	for h: Dictionary in g.herbs:
		herbs[h["pos"]] = h["kind"]


func bush_ready(p: Vector3i, day: int) -> bool:
	return bushes.has(p) and int(bushes[p]) <= day


func remove_tree(p: Vector3i) -> String:
	var k: String = trees.get(p, "")
	trees.erase(p)
	changed.emit("trees")
	return k


func harvest_bush(p: Vector3i, day: int) -> void:
	bushes[p] = day + int(DataRegistry.get_table("flora").get("bush", {}).get("regrow_days", 6))
	changed.emit("bushes")


func remove_bush(p: Vector3i) -> void:
	bushes.erase(p)
	changed.emit("bushes")


## Plante un arbre / un buisson (terraformation).
func add_tree(p: Vector3i, kind: String) -> void:
	trees[p] = kind
	changed.emit("trees")


func add_bush(p: Vector3i) -> void:
	bushes[p] = 0
	changed.emit("bushes")


func remove_herb(p: Vector3i) -> String:
	var k: String = herbs.get(p, "")
	herbs.erase(p)
	changed.emit("herbs")
	return k


## Ressources récoltables dans un cercle (rayon en cases) : pour le menu Récolter.
func in_circle(kind: String, center: Vector3i, radius: int, day: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var src: Dictionary = trees if kind == "tree" else (bushes if kind in ["bush", "bush_any"] else herbs)
	for p: Vector3i in src:
		if Vector2(p.x - center.x, p.z - center.z).length() <= radius + 0.5:
			if kind != "bush" or bush_ready(p, day):  # « bush_any » : tous les buissons
				out.append(p)
	return out


func _pack(d: Dictionary) -> Array:
	var out := []
	for p: Vector3i in d:
		out.append([p.x, p.y, p.z, d[p]])
	return out


func _unpack(a: Array) -> Dictionary:
	var out := {}
	for e: Array in a:
		out[Vector3i(int(e[0]), int(e[1]), int(e[2]))] = e[3]
	return out


func to_dict() -> Dictionary:
	return {"trees": _pack(trees), "bushes": _pack(bushes), "herbs": _pack(herbs)}


func from_dict(d: Dictionary) -> void:
	trees = _unpack(d.get("trees", []))
	bushes = _unpack(d.get("bushes", []))
	for p: Vector3i in bushes:
		bushes[p] = int(bushes[p])
	herbs = _unpack(d.get("herbs", []))
	changed.emit("all")
