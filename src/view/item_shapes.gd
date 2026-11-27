class_name ItemShapes
extends RefCounted
## Formes 3D des objets rangés en tas (1.3.2) : chaque objet a sa vraie forme (vitre, peau pliée, rouleau de tissu,
## corde enroulée, lingot, outil, arme, pain, poisson, fromage, fiole, seau, sac, caisse…), empilée en rangées et en
## couches. Le tas est ensuite fusionné en un seul maillage (rapide sur téléphone).

const K = preload("res://src/view/model_kit.gd")

## objet -> [forme, couleur]. Ce qui manque est déduit de la catégorie (voir kind_of).
const SHAPES := {
	"glass": ["pane", "a8d8e8"],
	"hide": ["hide", "9a7656"],
	"leather": ["hide", "6a4228"],
	"cloth": ["bolt", "d8ccb0"],
	"linen": ["bolt", "e8e0c8"],
	"clothes": ["folded", "5a6a8a"],
	"rope": ["coil", "b8a070"],
	"iron_ingot": ["ingot", "6a6a72"],
	"iron_bar": ["bar", "5a5a62"],
	"gold": ["ingot", "e0b840"],
	"nails": ["box", "7a7a80"],
	"pottery": ["pot", "b0623a"],
	"vial": ["vial", "b8e0e8"],
	"bottle": ["bottle", "6aa8a0"],
	"healing_potion": ["vial", "d04060"],
	"candle": ["candle", "f0e8c8"],
	"tallow": ["block", "e8e0c0"],
	"bread": ["loaf", "c8904a"],
	"barley_bread": ["loaf", "a87a40"],
	"fish": ["fish", "8aa0b0"],
	"smoked_fish": ["fish", "8a6a40"],
	"grilled_fish": ["fish", "a07848"],
	"meat": ["meat", "a8443a"],
	"roast": ["meat", "8a4a2a"],
	"ham": ["meat", "c06a5a"],
	"sausage": ["sausage", "a0503a"],
	"cheese": ["wheel", "f0d070"],
	"butter": ["block", "f0e090"],
	"milk": ["jug", "f4f0e8"],
	"water": ["bucket", "4a7ab8"],
	"water_bucket": ["bucket", "4a7ab8"],
	"bucket": ["bucket", ""],
	"beer": ["barrel", "c89a40"],
	"wine": ["barrel", "6a2448"],
	"flour": ["sack", "e8e0d0"],
	"salt": ["sack", "f0f0f0"],
	"berries": ["small", "8a2448"],
	"grapes": ["small", "5a2a6a"],
	"potato": ["veg", "b8945a"],
	"carrot": ["carrot", "e07a2a"],
	"onion": ["veg", "d8b070"],
	"turnip": ["veg", "e8d8e0"],
	"pumpkin": ["pumpkin", "e08030"],
	"vegetables": ["veg", "6a9a40"],
	"mushroom": ["mushroom", "b88a60"],
	"medicinal_herb": ["herb", "5a8a40"],
	"flax_seed": ["sack", "c8b080"],
	"stew": ["bowl", "8a5a30"],
	"veg_soup": ["bowl", "7a9a40"],
	"mushroom_soup": ["bowl", "a08060"],
	"onion_soup": ["bowl", "c8a060"],
	"pumpkin_soup": ["bowl", "e08a30"],
	"carrot_stew": ["bowl", "b06a30"],
	"compote": ["bowl", "8a2448"],
	"berry_pie": ["pie", "8a2448"],
	"cheese_pie": ["pie", "f0d070"],
	"potato_cake": ["pie", "c8a060"],
	"spear": ["spear", ""],
	"flintlock": ["gun", ""],
	"short_sword": ["sword", ""],
	"shot": ["sack", "5a5a5a"],
	"dye_red": ["pot", "b02a2a"],
	"dye_blue": ["pot", "2a4ab0"],
	"dye_yellow": ["pot", "d0b020"]
}

## Taille d'un objet (largeur x, hauteur y, profondeur z) pour la disposition en rangées.
const SIZES := {
	"pane": Vector3(0.38, 0.04, 0.38),
	"hide": Vector3(0.42, 0.06, 0.4),
	"bolt": Vector3(0.8, 0.16, 0.16),
	"folded": Vector3(0.36, 0.07, 0.3),
	"coil": Vector3(0.3, 0.08, 0.3),
	"ingot": Vector3(0.26, 0.08, 0.12),
	"bar": Vector3(0.8, 0.05, 0.06),
	"pot": Vector3(0.22, 0.24, 0.22),
	"vial": Vector3(0.12, 0.18, 0.12),
	"bottle": Vector3(0.14, 0.3, 0.14),
	"candle": Vector3(0.08, 0.2, 0.08),
	"block": Vector3(0.2, 0.12, 0.14),
	"loaf": Vector3(0.28, 0.12, 0.16),
	"fish": Vector3(0.36, 0.07, 0.12),
	"meat": Vector3(0.26, 0.14, 0.2),
	"sausage": Vector3(0.3, 0.06, 0.06),
	"wheel": Vector3(0.28, 0.12, 0.28),
	"jug": Vector3(0.2, 0.3, 0.2),
	"bucket": Vector3(0.26, 0.26, 0.26),
	"barrel": Vector3(0.4, 0.5, 0.4),
	"sack": Vector3(0.36, 0.34, 0.28),
	"small": Vector3(0.12, 0.08, 0.12),
	"veg": Vector3(0.14, 0.12, 0.14),
	"carrot": Vector3(0.28, 0.06, 0.06),
	"pumpkin": Vector3(0.34, 0.24, 0.34),
	"mushroom": Vector3(0.14, 0.12, 0.14),
	"herb": Vector3(0.36, 0.06, 0.12),
	"bowl": Vector3(0.24, 0.1, 0.24),
	"pie": Vector3(0.28, 0.07, 0.28),
	"spear": Vector3(0.9, 0.05, 0.08),
	"gun": Vector3(0.8, 0.08, 0.12),
	"sword": Vector3(0.6, 0.04, 0.12),
	"tool": Vector3(0.6, 0.08, 0.2),
	"crate": Vector3(0.4, 0.34, 0.4)
}


## Forme et couleur d'un objet ; outils, meubles en kit et le reste : outil ou caisse.
static func kind_of(item: String) -> Array:
	if SHAPES.has(item):
		return SHAPES[item]
	var cat := str(Stockpile._resource(item).get("category", ""))
	if cat == "tool":
		return ["tool", ""]
	if cat == "food":
		return ["veg", Color.from_hsv(float(hash(item) % 360) / 360.0, 0.5, 0.7).to_html(false)]
	return ["crate", ""]


## Tas d'objets : rangées et couches de la vraie forme, nombre selon le remplissage (0..1).
static func stack(item: String, fill: float) -> Node3D:
	var r := Node3D.new()
	var k := kind_of(item)
	var shape: String = k[0]
	var sz: Vector3 = SIZES.get(shape, Vector3(0.3, 0.2, 0.3))
	var cols := maxi(1, floori(0.9 / (sz.x + 0.03)))
	var rows := maxi(1, floori(0.9 / (sz.z + 0.03)))
	var layers := maxi(1, mini(6, floori(0.9 / (sz.y + 0.01))))
	var total := cols * rows * layers
	var n := clampi(ceili(fill * total), 1, total)
	var i := 0
	for y in layers:
		for row in rows:
			for col in cols:
				if i >= n:
					return r
				var j := float((i * 37) % 11) / 11.0 - 0.5  # petit désordre, toujours le même
				var p := Vector3(
					(col - (cols - 1) / 2.0) * (sz.x + 0.03),
					y * (sz.y + 0.01),
					(row - (rows - 1) / 2.0) * (sz.z + 0.03)
				)
				one(r, shape, str(k[1]), p, j * 0.25)
				i += 1
	return r


## Un objet posé en p (bas de l'objet), légèrement tourné de yaw.
static func one(r: Node3D, shape: String, hex: String, p: Vector3, yaw: float) -> void:
	var c := K.col(hex if hex != "" else "8a7a6a", 0.8)
	var rot := Vector3(0, yaw, 0)
	match shape:
		"pane":
			var g := K.col(hex, 0.05, 0.1)
			K.box(r, Vector3(0.38, 0.03, 0.38), g, p + Vector3(0, 0.015, 0), rot)
		"hide":
			K.box(r, Vector3(0.42, 0.05, 0.38), c, p + Vector3(0, 0.025, 0), rot)
			K.box(r, Vector3(0.2, 0.02, 0.1), c, p + Vector3(0.15, 0.055, 0.15), rot)
		"bolt":
			K.cyl(r, 0.075, 0.075, 0.8, c, p + Vector3(0, 0.075, 0), Vector3(0, yaw * 0.2, PI / 2.0), 8)
		"folded":
			K.box(r, Vector3(0.36, 0.06, 0.3), c, p + Vector3(0, 0.03, 0), rot)
		"coil":
			var t := TorusMesh.new()
			t.inner_radius = 0.07
			t.outer_radius = 0.14
			t.rings = 10
			t.ring_segments = 5
			var mi := MeshInstance3D.new()
			mi.mesh = t
			mi.material_override = c
			mi.position = p + Vector3(0, 0.035, 0)
			mi.scale = Vector3(1, 0.8, 1)
			r.add_child(mi)
		"ingot":
			K.box(r, Vector3(0.24, 0.07, 0.11), K.col(hex, 0.35, 0.8), p + Vector3(0, 0.035, 0), rot)
		"bar":
			K.box(r, Vector3(0.8, 0.04, 0.05), K.col(hex, 0.4, 0.8), p + Vector3(0, 0.02, 0), rot)
		"pot", "jug":
			K.cyl(r, 0.08, 0.1, 0.2, c, p + Vector3(0, 0.1, 0), Vector3.ZERO, 8)
			K.cyl(r, 0.05, 0.07, 0.06, c, p + Vector3(0, 0.23, 0), Vector3.ZERO, 8)
		"vial", "bottle":
			var tall := 1.6 if shape == "bottle" else 1.0
			var g := K.col(hex, 0.1, 0.2)
			K.cyl(r, 0.05, 0.05, 0.12 * tall, g, p + Vector3(0, 0.06 * tall, 0), Vector3.ZERO, 7)
			K.cyl(r, 0.02, 0.03, 0.06 * tall, g, p + Vector3(0, 0.15 * tall, 0), Vector3.ZERO, 6)
		"candle":
			K.cyl(r, 0.03, 0.03, 0.18, c, p + Vector3(0, 0.09, 0), Vector3.ZERO, 6)
		"block":
			K.box(r, Vector3(0.18, 0.11, 0.13), c, p + Vector3(0, 0.055, 0), rot)
		"loaf":
			K.ball(r, 0.12, c, p + Vector3(0, 0.06, 0), Vector3(1.1, 0.55, 0.65))
		"fish":
			K.ball(r, 0.12, c, p + Vector3(0, 0.035, 0), Vector3(1.4, 0.3, 0.5))
			K.box(r, Vector3(0.06, 0.03, 0.1), c, p + Vector3(0.18, 0.035, 0), Vector3(0, PI / 4.0, 0))
		"meat":
			K.ball(r, 0.12, c, p + Vector3(0, 0.07, 0), Vector3(1.1, 0.6, 0.85))
			K.cyl(r, 0.02, 0.02, 0.12, K.col("e8e0d0"), p + Vector3(0.12, 0.07, 0), Vector3(0, 0, PI / 2.0), 5)
		"sausage":
			K.cyl(r, 0.028, 0.028, 0.28, c, p + Vector3(0, 0.03, 0), Vector3(0, yaw, PI / 2.0), 6)
		"wheel":
			K.cyl(r, 0.13, 0.13, 0.11, c, p + Vector3(0, 0.055, 0), Vector3.ZERO, 10)
		"bucket":
			K.cyl(r, 0.13, 0.1, 0.24, K.tex("plank"), p + Vector3(0, 0.12, 0), Vector3.ZERO, 8)
			K.cyl(r, 0.135, 0.135, 0.03, K.col("4a4a50", 0.5, 0.6), p + Vector3(0, 0.2, 0), Vector3.ZERO, 8)
			if hex != "":
				K.cyl(r, 0.12, 0.12, 0.02, K.col(hex, 0.1), p + Vector3(0, 0.22, 0), Vector3.ZERO, 8)
		"barrel":
			K.cyl(r, 0.18, 0.18, 0.48, K.tex("plank"), p + Vector3(0, 0.24, 0), Vector3.ZERO, 9)
			for yy: float in [0.08, 0.4]:
				K.cyl(r, 0.185, 0.185, 0.03, K.col("3a3a40", 0.5, 0.6), p + Vector3(0, yy, 0), Vector3.ZERO, 9)
		"sack":
			K.ball(r, 0.17, c, p + Vector3(0, 0.15, 0), Vector3(1.0, 1.0, 0.8))
			K.cyl(r, 0.04, 0.07, 0.08, c, p + Vector3(0, 0.31, 0), Vector3.ZERO, 6)
		"small":
			for q in 3:
				K.ball(r, 0.04, c, p + Vector3(-0.03 + q * 0.03, 0.04, (q % 2) * 0.04))
		"veg":
			K.ball(r, 0.065, c, p + Vector3(0, 0.06, 0), Vector3(1.0, 0.9, 1.0))
		"carrot":
			K.cyl(r, 0.03, 0.0, 0.24, c, p + Vector3(0, 0.03, 0), Vector3(0, yaw, -PI / 2.0), 6)
			K.box(r, Vector3(0.06, 0.03, 0.05), K.col("4a8a30"), p + Vector3(-0.14, 0.03, 0))
		"pumpkin":
			K.ball(r, 0.16, c, p + Vector3(0, 0.12, 0), Vector3(1.0, 0.75, 1.0))
			K.cyl(r, 0.02, 0.025, 0.06, K.col("4a6a30"), p + Vector3(0, 0.25, 0))
		"mushroom":
			K.cyl(r, 0.025, 0.03, 0.07, K.col("e8e0d0"), p + Vector3(0, 0.035, 0))
			K.ball(r, 0.06, c, p + Vector3(0, 0.08, 0), Vector3(1.0, 0.5, 1.0))
		"herb":
			K.box(r, Vector3(0.34, 0.04, 0.1), c, p + Vector3(0, 0.02, 0), rot)
		"bowl":
			K.cyl(r, 0.11, 0.07, 0.08, K.tex("wood_side"), p + Vector3(0, 0.04, 0), Vector3.ZERO, 8)
			K.cyl(r, 0.1, 0.1, 0.01, c, p + Vector3(0, 0.08, 0), Vector3.ZERO, 8)
		"pie":
			K.cyl(r, 0.13, 0.12, 0.06, K.col("c8904a"), p + Vector3(0, 0.03, 0), Vector3.ZERO, 10)
			K.cyl(r, 0.1, 0.1, 0.01, c, p + Vector3(0, 0.065, 0), Vector3.ZERO, 10)
		"spear":
			K.cyl(r, 0.018, 0.018, 0.8, K.tex("wood_side"), p + Vector3(0, 0.02, 0), Vector3(0, yaw * 0.3, PI / 2.0), 5)
			K.cyl(
				r, 0.0, 0.035, 0.12, K.col("8a8a92", 0.3, 0.8), p + Vector3(0.45, 0.02, 0), Vector3(0, 0, -PI / 2.0), 4
			)
		"gun":
			K.box(r, Vector3(0.3, 0.06, 0.08), K.col("5a3a24"), p + Vector3(-0.22, 0.03, 0), rot)
			K.cyl(
				r, 0.018, 0.018, 0.5, K.col("4a4a52", 0.4, 0.8), p + Vector3(0.17, 0.04, 0), Vector3(0, 0, PI / 2.0), 5
			)
		"sword":
			K.box(r, Vector3(0.42, 0.02, 0.05), K.col("a0a0a8", 0.25, 0.9), p + Vector3(0.08, 0.02, 0), rot)
			K.box(r, Vector3(0.03, 0.03, 0.14), K.col("c49e54", 0.4, 0.7), p + Vector3(-0.14, 0.02, 0), rot)
			K.box(r, Vector3(0.12, 0.03, 0.03), K.col("4a3020"), p + Vector3(-0.22, 0.02, 0), rot)
		"tool":
			K.cyl(r, 0.02, 0.02, 0.5, K.tex("wood_side"), p + Vector3(0, 0.03, 0), Vector3(0, yaw * 0.3, PI / 2.0), 5)
			K.box(r, Vector3(0.06, 0.05, 0.16), K.col("6a6a72", 0.4, 0.8), p + Vector3(0.24, 0.03, 0), rot)
		_:
			K.box(r, Vector3(0.38, 0.32, 0.38), K.tex("plank"), p + Vector3(0, 0.16, 0), rot)
			K.box(r, Vector3(0.4, 0.04, 0.06), K.tex("wood_side"), p + Vector3(0, 0.3, 0), rot)
