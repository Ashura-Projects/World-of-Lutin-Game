class_name PilesView
extends Node3D
## Tas dans les zones de stockage (1.3.2) : chaque case de zone montre un tas d'une matière (bûches empilées,
## bottes de paille, tas de pierres, planches, caisses de nourriture, sacs…), plus ou moins haut selon la quantité
## (50 par tas) ; les objets (vitres, peaux, outils, pains…) gardent leur forme. Un maillage par tas.
## Recalculé chaque seconde, seules les cases qui changent sont redessinées.

const K = preload("res://src/view/model_kit.gd")
const TILES := {
	"stone": "stone",
	"cut_stone": "cut_stone",
	"brick": "brick",
	"clay": "clay",
	"sand": "sand",
	"dirt": "dirt",
	"coal": "coal_ore",
	"charcoal": "coal_ore",
	"iron_ore": "iron_ore",
	"gold_ore": "gold_ore",
	"roof_tile": "brick"
}
const BALES := ["straw", "wheat", "barley", "flax", "hemp", "reed", "hops"]
const BOARDS := ["plank", "beam"]

var _colony: Colony
var _nodes: Dictionary = {}  # case -> [nœud, "matière:niveau"]
var _t: float = 0.0
var _size: int = 50


func bind(c: Colony) -> void:
	_colony = c
	_size = int(DataRegistry.get_table("resources").get("piles", {}).get("size", 50))


func _process(delta: float) -> void:
	_t += delta
	if _colony == null or _t < 1.0:
		return
	_t = 0.0
	var lay: Dictionary = _colony.stores.layout(_colony.stock.items, _size)
	for c: Vector3i in _nodes.keys():
		if not lay.has(c) or _sig(lay[c]) != _nodes[c][1]:
			_nodes[c][0].queue_free()
			_nodes.erase(c)
	for c: Vector3i in lay:
		if _nodes.has(c):
			continue
		var n := ModelKit.merge(pile(str(lay[c][0]), float(lay[c][1]) / float(_size)))
		n.position = Vector3(c) + Vector3(0.5, 0, 0.5)
		add_child(n)
		_nodes[c] = [n, _sig(lay[c])]


func _sig(e: Array) -> String:
	return "%s:%d" % [e[0], ceili(float(e[1]) / float(_size) * 5.0)]  # 5 niveaux de hauteur


## Modèle d'un tas (fill = 0..1).
static func pile(item: String, fill: float) -> Node3D:
	var r := Node3D.new()
	var layers := clampi(ceili(fill * 5.0), 1, 5)
	if item == "log":
		for y in layers:
			for i in 3:
				K.cyl(
					r,
					0.13,
					0.13,
					0.85,
					K.tex("wood_side"),
					Vector3(-0.27 + i * 0.27, 0.13 + y * 0.22, 0),
					Vector3(PI / 2.0, 0, 0) if y % 2 == 0 else Vector3(0, 0, PI / 2.0),
					7
				)
	elif BALES.has(item):
		var tint := "ffffff" if item == "straw" else ("e8d890" if item in ["wheat", "barley"] else "b8d0a0")
		for y in mini(layers, 3):
			for i in 2:
				K.box(
					r,
					Vector3(0.38, 0.3, 0.8),
					K.tex("straw", tint),
					Vector3(-0.2 + i * 0.4, 0.15 + y * 0.31, 0),
					Vector3(0, (y % 2) * PI / 2.0, 0)
				)
	elif BOARDS.has(item):
		for y in layers * 2:
			K.box(
				r,
				Vector3(0.85, 0.08, 0.22),
				K.tex("plank" if item == "plank" else "beam"),
				Vector3(0, 0.04 + y * 0.09, -0.24 + (y % 3) * 0.24),
				Vector3(0, (y / 3 % 2) * PI / 2.0, 0)
			)
	elif TILES.has(item):
		var m := K.tex(str(TILES[item]))
		var cut := item in ["cut_stone", "brick", "roof_tile"]
		for y in layers:
			var n := 4 - y / 2
			for i in n:
				var a := i * TAU / float(n) + y
				var s := 0.3 if cut else 0.26 + 0.05 * float((i + y) % 2)
				var p := Vector3(cos(a), 0, sin(a)) * (0.25 - y * 0.04) + Vector3(0, s / 2.0 + y * 0.2, 0)
				K.box(
					r,
					Vector3(s, s * (0.6 if cut else 0.8), s),
					m,
					p,
					Vector3(0, a, 0) if cut else Vector3(0.2, a, 0.15)
				)
	else:
		return ItemShapes.stack(item, fill)  # objets : leur vraie forme, empilés
	return r
