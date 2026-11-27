class_name WorkshopModels
extends RefCounted
## Ateliers « feu et pierre » en low poly texturé (pierre, brique, planche de l'atlas) : four à pain, four de potier,
## forge, verrerie (gros four à verre), enclume, foyer de cuisine (cheminée en pierre et marmite), puits, meule,
## brasserie, pressoir, établi de tailleur de pierre. Origine = centre de la case du coin ; avant = -Z.

const K = preload("res://src/view/model_kit.gd")


static func build(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"oven":
			_oven(r)
		"kiln":
			_kiln(r)
		"furnace":
			_furnace(r)
		"glassworks":
			_glassworks(r)
		"anvil":
			_anvil(r, Vector3.ZERO)
		"cooking_hearth":
			_cooking_hearth(r)
		"well":
			_well(r)
		"mill":
			_mill(r)
		"brewery":
			_brewery(r)
		"wine_press":
			_wine_press(r)
		"mason_bench":
			_mason_bench(r)
		_:
			return null
	return r


## Four à pain : dôme de briques sur un socle de pierre, bouche rougeoyante, pelle à pain et pains.
static func _oven(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(1.8, 0.7, 1.8), K.tex("cobble"), c + Vector3(0, 0.35, 0))
	K.ball(r, 0.8, K.tex("brick"), c + Vector3(0, 0.75, 0.1), Vector3(1.0, 0.85, 1.0))
	K.box(r, Vector3(0.6, 0.45, 0.2), K.tex("cut_stone"), c + Vector3(0, 0.95, -0.72))
	K.box(r, Vector3(0.4, 0.3, 0.05), K.col("ff7a30", 0.8, 0.0, 4.0), c + Vector3(0, 0.92, -0.83))
	K.cyl(r, 0.14, 0.16, 0.7, K.tex("brick"), c + Vector3(0.35, 1.6, 0.4))
	K.box(r, Vector3(0.08, 0.04, 1.2), K.tex("wood_side"), c + Vector3(0.75, 0.72, -0.3), Vector3(0, 0.3, 0))
	for i in 3:
		K.ball(r, 0.1, K.col("c8904a"), c + Vector3(-0.55 + i * 0.22, 0.75, -0.75), Vector3(1.4, 0.7, 1.0))
	K.light(r, c + Vector3(0, 0.9, -1.0), 0.8, 4.0)


## Four de potier : four en ruche de briques, bouche à bois, pots et cruches qui sèchent.
static func _kiln(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.cyl(r, 0.65, 0.85, 1.4, K.tex("brick"), c + Vector3(0, 0.7, 0.15), Vector3.ZERO, 10)
	K.cyl(r, 0.25, 0.6, 0.45, K.tex("brick"), c + Vector3(0, 1.62, 0.15), Vector3.ZERO, 10)
	K.cyl(r, 0.18, 0.2, 0.4, K.tex("cut_stone"), c + Vector3(0, 2.0, 0.15))
	K.box(r, Vector3(0.45, 0.35, 0.3), K.tex("cobble"), c + Vector3(0, 0.25, -0.75))
	K.box(r, Vector3(0.3, 0.22, 0.05), K.col("ff6a20", 0.8, 0.0, 5.0), c + Vector3(0, 0.24, -0.91))
	for i in 4:
		var p := c + Vector3(-0.75 + (i % 2) * 0.25, 0, -0.7 + (i / 2) * 0.3)
		K.cyl(r, 0.08, 0.1, 0.24, K.col("b0623a"), p + Vector3(0, 0.12, 0), Vector3.ZERO, 8)
		K.cyl(r, 0.05, 0.08, 0.06, K.col("b0623a"), p + Vector3(0, 0.27, 0), Vector3.ZERO, 8)
	K.logs(r, c + Vector3(0.75, 0, -0.65), 3)
	K.light(r, c + Vector3(0, 0.3, -1.0), 0.8, 4.0)


## Forge (fonderie) : foyer de pierre, hotte et cheminée, braises, soufflet en cuir, seau et pinces.
static func _furnace(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(1.4, 0.8, 1.1), K.tex("cobble"), c + Vector3(0, 0.4, 0.3))
	K.box(r, Vector3(1.0, 0.1, 0.7), K.col("2a2220"), c + Vector3(0, 0.82, 0.25))
	for i in 6:
		K.box(
			r,
			Vector3(0.18, 0.1, 0.16),
			K.col("ff6a20", 0.8, 0.0, 4.0),
			c + Vector3(-0.35 + (i % 3) * 0.3, 0.88, 0.1 + (i / 3) * 0.3)
		)
	K.prism(r, Vector3(1.4, 0.8, 1.1), K.tex("cut_stone"), c + Vector3(0, 1.75, 0.3))
	K.box(r, Vector3(1.4, 0.35, 0.15), K.tex("cut_stone"), c + Vector3(0, 1.2, 0.8))
	K.box(r, Vector3(0.5, 1.4, 0.5), K.tex("brick"), c + Vector3(0, 2.6, 0.45))
	# soufflet : planches et cuir, sur le côté
	K.box(r, Vector3(0.5, 0.08, 0.7), K.tex("plank"), c + Vector3(0.95, 0.55, 0.2), Vector3(0, 0, 0.15))
	K.box(r, Vector3(0.45, 0.16, 0.6), K.col("6a4630"), c + Vector3(0.95, 0.45, 0.2))
	K.box(r, Vector3(0.5, 0.08, 0.7), K.tex("plank"), c + Vector3(0.95, 0.35, 0.2))
	K.cyl(r, 0.03, 0.05, 0.4, K.col("3a3a40", 0.5, 0.7), c + Vector3(0.75, 0.45, -0.15), Vector3(PI / 2.0, 0, 0))
	# seau d'eau pour la trempe
	K.cyl(r, 0.2, 0.17, 0.3, K.tex("plank"), c + Vector3(-0.85, 0.15, -0.6))
	K.cyl(r, 0.17, 0.17, 0.02, K.tex("water"), c + Vector3(-0.85, 0.28, -0.6))
	_anvil(r, c + Vector3(0.1, 0, -0.85))
	K.light(r, c + Vector3(0, 1.1, 0), 1.4, 6.0)


## Enclume de fer sur une souche, marteau posé.
static func _anvil(r: Node3D, at: Vector3) -> void:
	var iron := K.col("3c3c44", 0.45, 0.8)
	K.cyl(r, 0.24, 0.27, 0.45, K.tex("wood_side"), at + Vector3(0, 0.225, 0), Vector3.ZERO, 9)
	K.box(r, Vector3(0.22, 0.12, 0.2), iron, at + Vector3(0, 0.51, 0))
	K.box(r, Vector3(0.14, 0.12, 0.14), iron, at + Vector3(0, 0.6, 0))
	K.box(r, Vector3(0.46, 0.12, 0.2), iron, at + Vector3(-0.04, 0.72, 0))
	K.cyl(r, 0.0, 0.07, 0.24, iron, at + Vector3(0.3, 0.72, 0), Vector3(0, 0, -PI / 2.0), 6)
	K.box(r, Vector3(0.05, 0.04, 0.3), K.tex("wood_side"), at + Vector3(-0.1, 0.8, -0.05), Vector3(0, 0.4, 0))
	K.box(r, Vector3(0.12, 0.07, 0.07), iron, at + Vector3(-0.15, 0.81, -0.18), Vector3(0, 0.4, 0))


## Verrerie : gros four à verre en dôme de briques, trois gueules incandescentes, cannes de souffleur, bouteilles.
static func _glassworks(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.cyl(r, 0.95, 0.95, 0.5, K.tex("cobble"), c + Vector3(0, 0.25, 0.1), Vector3.ZERO, 12)
	K.ball(r, 0.9, K.tex("brick"), c + Vector3(0, 0.6, 0.1), Vector3(1.0, 1.0, 1.0))
	for a: float in [-0.7, 0.0, 0.7]:
		var d := Vector3(sin(a), 0, -cos(a)) * 0.82
		K.box(
			r,
			Vector3(0.28, 0.24, 0.1),
			K.col("ffb040", 0.8, 0.0, 6.0),
			c + Vector3(0, 0.85, 0.1) + d,
			Vector3(0, -a, 0)
		)
	K.cyl(r, 0.2, 0.24, 0.9, K.tex("brick"), c + Vector3(0, 1.85, 0.3))
	K.box(r, Vector3(0.5, 0.06, 0.25), K.tex("plank"), c + Vector3(-0.85, 0.75, -0.7))
	K.legs(r, 0.5, 0.25, 0.72, K.tex("wood_side"), c + Vector3(-0.85, 0, -0.7), 0.05)
	for i in 3:
		var p := c + Vector3(-1.0 + i * 0.14, 0.78, -0.7)
		var g := K.col(["6aa8a0", "88b860", "a0c8d8"][i], 0.1, 0.2)
		K.cyl(r, 0.05, 0.05, 0.16, g, p + Vector3(0, 0.08, 0))
		K.cyl(r, 0.02, 0.04, 0.08, g, p + Vector3(0, 0.2, 0))
	for i in 2:
		K.cyl(
			r,
			0.015,
			0.015,
			1.3,
			K.col("3a3a40", 0.5, 0.7),
			c + Vector3(0.95, 0.6, -0.4 + i * 0.12),
			Vector3(0.3, 0, 0.1)
		)
	K.light(r, c + Vector3(0, 0.9, -0.9), 1.3, 6.0, "ffb050")


## Foyer de cuisine : cheminée en pierre avec hotte, feu, marmite suspendue à une crémaillère.
static func _cooking_hearth(r: Node3D) -> void:
	K.box(r, Vector3(1.0, 0.18, 0.8), K.tex("cobble"), Vector3(0, 0.09, 0.05))
	for sx: float in [-0.42, 0.42]:
		K.box(r, Vector3(0.16, 1.1, 0.7), K.tex("cobble"), Vector3(sx, 0.55, 0.1))
	K.box(r, Vector3(1.0, 0.16, 0.16), K.tex("beam"), Vector3(0, 1.12, -0.18))
	K.box(r, Vector3(1.0, 0.7, 0.7), K.tex("cobble"), Vector3(0, 1.5, 0.12))
	K.box(r, Vector3(0.45, 1.0, 0.45), K.tex("cobble"), Vector3(0, 2.3, 0.2))
	K.box(r, Vector3(0.68, 0.06, 0.6), K.col("2a2220"), Vector3(0, 0.2, 0.1))
	K.logs(r, Vector3(0, 0.18, 0.1), 2)
	K.flame(r, Vector3(0, 0.42, 0.1), 1.3)
	var iron := K.col("2e2e34", 0.5, 0.7)
	K.box(r, Vector3(0.03, 0.4, 0.03), iron, Vector3(0, 0.88, 0.1))
	K.cyl(r, 0.2, 0.15, 0.24, iron, Vector3(0, 0.6, 0.1), Vector3.ZERO, 10)
	K.cyl(r, 0.17, 0.17, 0.02, K.col("8a6a3a", 0.6, 0.0, 0.3), Vector3(0, 0.71, 0.1), Vector3.ZERO, 10)
	K.light(r, Vector3(0, 0.6, -0.2), 1.3, 6.0)


## Puits : margelle ronde en pierre, deux poteaux, toit, treuil et seau.
static func _well(r: Node3D) -> void:
	K.cyl(r, 0.5, 0.52, 0.7, K.tex("cobble"), Vector3(0, 0.35, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.38, 0.38, 0.02, K.tex("water"), Vector3(0, 0.55, 0), Vector3.ZERO, 12)
	for sx: float in [-0.45, 0.45]:
		K.box(r, Vector3(0.1, 1.3, 0.1), K.tex("wood_side"), Vector3(sx, 1.15, 0))
	K.cyl(r, 0.06, 0.06, 0.9, K.tex("wood_side"), Vector3(0, 1.4, 0), Vector3(0, 0, PI / 2.0))
	K.prism(r, Vector3(1.2, 0.45, 0.9), K.tex("thatch_side"), Vector3(0, 2.0, 0), Vector3(0, PI / 2.0, 0))
	K.box(r, Vector3(0.02, 0.5, 0.02), K.col("8a7a5a"), Vector3(0, 1.15, 0))
	K.cyl(r, 0.1, 0.08, 0.16, K.tex("plank"), Vector3(0, 0.86, 0))


## Meule : deux meules de pierre sous un bâti de poutres, trémie à grain, sacs de farine.
static func _mill(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.cyl(r, 0.8, 0.85, 0.45, K.tex("cobble"), c + Vector3(0, 0.22, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.65, 0.65, 0.22, K.tex("cut_stone"), c + Vector3(0, 0.56, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.62, 0.62, 0.2, K.tex("stone"), c + Vector3(0, 0.77, 0), Vector3.ZERO, 12)
	for sx: float in [-0.85, 0.85]:
		K.box(r, Vector3(0.14, 1.8, 0.14), K.tex("beam"), c + Vector3(sx, 0.9, 0))
	K.box(r, Vector3(1.9, 0.14, 0.14), K.tex("beam"), c + Vector3(0, 1.8, 0))
	K.cyl(r, 0.05, 0.05, 1.0, K.tex("wood_side"), c + Vector3(0, 1.3, 0))
	K.cyl(r, 0.3, 0.08, 0.4, K.tex("plank"), c + Vector3(0, 1.45, 0), Vector3.ZERO, 6)
	K.box(r, Vector3(1.2, 0.08, 0.08), K.tex("wood_side"), c + Vector3(0.5, 0.95, 0), Vector3(0, 0.4, 0))
	for i in 2:
		K.ball(r, 0.2, K.col("d8ccb0"), c + Vector3(-0.7 + i * 0.35, 0.2, -0.75), Vector3(1.0, 1.2, 0.9))


## Brasserie : cuve de cuivre sur un foyer, deux tonneaux couchés, cuve de bois.
static func _brewery(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(0.9, 0.5, 0.9), K.tex("brick"), c + Vector3(-0.45, 0.25, 0.4))
	K.cyl(r, 0.42, 0.36, 0.6, K.col("b8743a", 0.35, 0.8), c + Vector3(-0.45, 0.8, 0.4), Vector3.ZERO, 12)
	K.cyl(r, 0.1, 0.36, 0.25, K.col("b8743a", 0.35, 0.8), c + Vector3(-0.45, 1.22, 0.4), Vector3.ZERO, 12)
	K.box(r, Vector3(0.3, 0.16, 0.05), K.col("ff7a30", 0.8, 0.0, 4.0), c + Vector3(-0.45, 0.2, -0.06))
	for i in 2:
		var p := c + Vector3(0.55, 0.32 + i * 0.6, 0.4 - i * 0.05)
		K.cyl(r, 0.3, 0.3, 0.8, K.tex("plank"), p, Vector3(PI / 2.0, 0, 0), 10)
		for z: float in [-0.25, 0.25]:
			K.cyl(r, 0.31, 0.31, 0.05, K.col("3a3a40", 0.5, 0.6), p + Vector3(0, 0, z), Vector3(PI / 2.0, 0, 0), 10)
	K.box(r, Vector3(0.9, 0.3, 0.08), K.tex("beam"), c + Vector3(0.55, 0.15, 0.4))
	K.cyl(r, 0.35, 0.3, 0.5, K.tex("plank"), c + Vector3(-0.3, 0.25, -0.6), Vector3.ZERO, 10)
	K.cyl(r, 0.32, 0.32, 0.02, K.col("c89a40", 0.3), c + Vector3(-0.3, 0.49, -0.6), Vector3.ZERO, 10)


## Pressoir : bâti de poutres, grande vis de bois, plateau sur la cuve de raisin.
static func _wine_press(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.cyl(r, 0.7, 0.7, 0.5, K.tex("plank"), c + Vector3(0, 0.25, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.62, 0.62, 0.02, K.col("6a2448", 0.4), c + Vector3(0, 0.48, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.55, 0.55, 0.12, K.tex("plank"), c + Vector3(0, 0.62, 0), Vector3.ZERO, 12)
	for sx: float in [-0.8, 0.8]:
		K.box(r, Vector3(0.16, 2.0, 0.16), K.tex("beam"), c + Vector3(sx, 1.0, 0))
	K.box(r, Vector3(1.8, 0.22, 0.22), K.tex("beam"), c + Vector3(0, 1.9, 0))
	K.cyl(r, 0.08, 0.08, 1.25, K.tex("wood_side"), c + Vector3(0, 1.25, 0), Vector3.ZERO, 8)
	K.box(r, Vector3(1.0, 0.07, 0.07), K.tex("wood_side"), c + Vector3(0, 1.45, 0), Vector3(0, 0.6, 0))
	K.box(r, Vector3(0.2, 0.06, 0.4), K.tex("plank"), c + Vector3(0.65, 0.4, -0.55))
	for i in 5:
		K.ball(r, 0.06, K.col("5a2a6a"), c + Vector3(-0.8 + i * 0.08, 0.06, -0.8 + (i % 2) * 0.1))


## Établi de tailleur de pierre : grosse table, bloc taillé, ciseau et maillet, pierres en attente.
static func _mason_bench(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0)
	K.box(r, Vector3(1.7, 0.14, 0.75), K.tex("plank"), c + Vector3(0, 0.72, 0))
	K.legs(r, 1.7, 0.75, 0.72, K.tex("beam"), c, 0.12)
	K.box(r, Vector3(0.45, 0.35, 0.4), K.tex("cut_stone"), c + Vector3(-0.3, 0.97, 0))
	K.box(r, Vector3(0.04, 0.04, 0.25), K.col("6a6a70", 0.4, 0.7), c + Vector3(0.15, 0.81, -0.1), Vector3(0, 0.5, 0))
	K.cyl(r, 0.07, 0.07, 0.16, K.tex("wood_side"), c + Vector3(0.4, 0.86, 0.1), Vector3(0, 0, PI / 2.0))
	for i in 3:
		K.box(
			r,
			Vector3(0.32, 0.25, 0.3),
			K.tex("stone"),
			c + Vector3(-0.6 + i * 0.35, 0.13, 0.55),
			Vector3(0, i * 0.4, 0)
		)
