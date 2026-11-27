class_name CraftModels
extends RefCounted
## Ateliers « bois et tissu » en low poly texturé : établi de menuisier, rouet, métier à tisser, herboristerie,
## tannerie, école (tableau et pupitres), bibliothèque, atelier de maître, ébéniste, tailleur, cuve de teinture,
## ancien cimetière. Origine = centre de la case du coin ; avant = -Z.

const K = preload("res://src/view/model_kit.gd")


static func build(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"sawbench":
			_sawbench(r)
		"spinning_wheel":
			_spinning_wheel(r)
		"loom":
			_loom(r)
		"herbalist":
			_herbalist(r)
		"leatherworks":
			_leatherworks(r)
		"school":
			_school(r)
		"library":
			_library(r)
		"master_workshop":
			_master(r)
		"cabinetmaker":
			_cabinetmaker(r)
		"tailor":
			_tailor(r)
		"dye_vat":
			_dye_vat(r)
		"graveyard":
			for i in 3:
				K.box(r, Vector3(0.4, 0.6, 0.12), K.tex("cut_stone"), Vector3(i, 0.3, 1.0))
				K.box(r, Vector3(0.5, 0.05, 0.9), K.tex("dirt"), Vector3(i, 0.02, 1.5))
		_:
			return null
	return r


## Râtelier d'armes : cadre de bois ; fusils et / ou lances rangés debout selon ce qu'il accepte.
static func weapon_rack(r: Node3D, filter: String) -> void:
	var wood := K.tex("wood_side")
	for sx: float in [-0.42, 0.42]:
		K.box(r, Vector3(0.09, 1.5, 0.09), wood, Vector3(sx, 0.75, 0.3))
	K.box(r, Vector3(0.95, 0.1, 0.3), K.tex("plank"), Vector3(0, 0.12, 0.2))
	K.box(r, Vector3(0.95, 0.08, 0.12), wood, Vector3(0, 1.25, 0.32))
	for i in 5:
		K.box(r, Vector3(0.05, 0.05, 0.14), wood, Vector3(-0.32 + i * 0.16, 1.18, 0.24))
	var metal := K.col("6a6a72", 0.35, 0.8)
	for i in 5:
		var x := -0.32 + i * 0.16
		var gun := filter == "flintlock" or (filter == "all" and i % 2 == 0)
		if gun:
			K.box(r, Vector3(0.06, 0.45, 0.07), K.col("5a3a24"), Vector3(x, 0.4, 0.2))
			K.box(r, Vector3(0.03, 0.75, 0.03), metal, Vector3(x, 0.95, 0.22))
		else:
			K.box(r, Vector3(0.03, 1.45, 0.03), wood, Vector3(x, 0.85, 0.22))
			K.cyl(r, 0.0, 0.04, 0.16, metal, Vector3(x, 1.65, 0.22), Vector3.ZERO, 4)


## Établi de menuisier : chevalets, planche en cours de sciage, scie, rabot, copeaux.
static func _sawbench(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0)
	for sx: float in [-0.7, 0.7]:
		K.box(r, Vector3(0.1, 0.6, 0.08), K.tex("wood_side"), c + Vector3(sx, 0.3, -0.18), Vector3(0.3, 0, 0))
		K.box(r, Vector3(0.1, 0.6, 0.08), K.tex("wood_side"), c + Vector3(sx, 0.3, 0.18), Vector3(-0.3, 0, 0))
		K.box(r, Vector3(0.12, 0.1, 0.5), K.tex("wood_side"), c + Vector3(sx, 0.6, 0))
	K.cyl(r, 0.16, 0.16, 1.9, K.tex("wood_side"), c + Vector3(0, 0.8, 0), Vector3(0, 0, PI / 2.0), 8)
	K.box(r, Vector3(0.02, 0.22, 0.5), K.col("9a9aa2", 0.3, 0.8), c + Vector3(0.2, 0.95, 0))
	K.box(r, Vector3(0.05, 0.08, 0.14), K.tex("wood_side"), c + Vector3(0.2, 1.08, 0.3))
	K.box(r, Vector3(1.2, 0.05, 0.25), K.tex("plank"), c + Vector3(-0.1, 0.03, 0.45))
	K.box(r, Vector3(0.6, 0.02, 0.4), K.col("d8c090"), c + Vector3(0.2, 0.01, -0.3))


## Rouet : roue à rayons, pédale, fuseau et quenouille de lin.
static func _spinning_wheel(r: Node3D) -> void:
	K.box(r, Vector3(0.7, 0.08, 0.2), K.tex("plank"), Vector3(0, 0.3, 0))
	for p: Vector3 in [Vector3(-0.3, 0.15, -0.08), Vector3(-0.3, 0.15, 0.08), Vector3(0.3, 0.15, 0)]:
		K.box(r, Vector3(0.05, 0.3, 0.05), K.tex("wood_side"), p)
	K.box(r, Vector3(0.05, 0.5, 0.05), K.tex("wood_side"), Vector3(-0.15, 0.55, 0))
	K.cyl(r, 0.3, 0.3, 0.04, K.tex("wood_side"), Vector3(-0.15, 0.75, 0), Vector3(PI / 2.0, 0, 0), 12)
	K.cyl(r, 0.24, 0.24, 0.05, K.col("3a2a1e"), Vector3(-0.15, 0.75, 0), Vector3(PI / 2.0, 0, 0), 12)
	for i in 4:
		K.box(r, Vector3(0.02, 0.5, 0.02), K.tex("wood_side"), Vector3(-0.15, 0.75, 0), Vector3(0, 0, i * PI / 4.0))
	K.box(r, Vector3(0.05, 0.35, 0.05), K.tex("wood_side"), Vector3(0.25, 0.48, 0))
	K.ball(r, 0.08, K.col("d8cca8"), Vector3(0.25, 0.7, 0), Vector3(1, 1.6, 1))
	K.box(r, Vector3(0.25, 0.03, 0.15), K.tex("plank"), Vector3(0.05, 0.03, -0.2))


## Métier à tisser : cadre de poutres, ensouples, fils et toile, banc du tisserand.
static func _loom(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0)
	for sx: float in [-0.85, 0.85]:
		for sz: float in [-0.3, 0.3]:
			K.box(r, Vector3(0.1, 1.5, 0.1), K.tex("beam"), c + Vector3(sx, 0.75, sz))
		K.box(r, Vector3(0.1, 0.1, 0.7), K.tex("beam"), c + Vector3(sx, 1.5, 0))
	K.box(r, Vector3(1.8, 0.1, 0.1), K.tex("beam"), c + Vector3(0, 1.5, 0.3))
	K.cyl(r, 0.06, 0.06, 1.7, K.tex("wood_side"), c + Vector3(0, 0.8, -0.3), Vector3(0, 0, PI / 2.0))
	K.cyl(r, 0.08, 0.08, 1.7, K.tex("wood_side"), c + Vector3(0, 0.6, 0.3), Vector3(0, 0, PI / 2.0))
	K.box(r, Vector3(1.5, 0.02, 0.6), K.col("d8ccb0"), c + Vector3(0, 0.72, 0), Vector3(-0.35, 0, 0))
	K.box(r, Vector3(1.2, 0.03, 0.35), K.col("b04a3a"), c + Vector3(0, 0.79, -0.18), Vector3(-0.35, 0, 0))
	K.box(r, Vector3(1.5, 0.05, 0.05), K.tex("wood_side"), c + Vector3(0, 1.1, 0))
	K.box(r, Vector3(1.0, 0.08, 0.3), K.tex("plank"), c + Vector3(0, 0.45, -0.75))
	K.legs(r, 1.0, 0.3, 0.45, K.tex("wood_side"), c + Vector3(0, 0, -0.75), 0.06)


## Herboristerie : table de préparation, alambic, fioles, herbes séchées pendues, mortier.
static func _herbalist(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(1.8, 0.1, 0.7), K.tex("plank"), c + Vector3(0, 0.75, 0.4))
	K.legs(r, 1.8, 0.7, 0.75, K.tex("wood_side"), c + Vector3(0, 0, 0.4), 0.08)
	K.ball(r, 0.2, K.col("b8743a", 0.35, 0.8), c + Vector3(-0.5, 1.0, 0.45))
	K.cyl(r, 0.03, 0.03, 0.5, K.col("b8743a", 0.35, 0.8), c + Vector3(-0.3, 1.2, 0.45), Vector3(0, 0, -1.0))
	for i in 4:
		var g := K.col(["58a060", "a05878", "5878b0", "c8a040"][i], 0.15, 0.2)
		K.cyl(r, 0.05, 0.06, 0.18, g, c + Vector3(0.1 + i * 0.15, 0.89, 0.3))
	K.cyl(r, 0.1, 0.07, 0.12, K.tex("stone"), c + Vector3(0.65, 0.86, 0.55))
	for sx: float in [-0.85, 0.85]:
		K.box(r, Vector3(0.08, 1.9, 0.08), K.tex("beam"), c + Vector3(sx, 0.95, 0.9))
	K.box(r, Vector3(1.8, 0.06, 0.06), K.tex("beam"), c + Vector3(0, 1.85, 0.9))
	for i in 6:
		K.cyl(
			r,
			0.08,
			0.0,
			0.35,
			K.col(["5a8a40", "7a9a50", "8a6a3a"][i % 3]),
			c + Vector3(-0.7 + i * 0.28, 1.6, 0.9),
			Vector3.ZERO,
			5
		)
	K.cyl(r, 0.25, 0.25, 0.35, K.tex("plank"), c + Vector3(0.6, 0.18, -0.5), Vector3.ZERO, 8)


## Tannerie : cadres de peaux tendues, cuve de tan, racloir, cuirs empilés.
static func _leatherworks(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	for i in 2:
		var p := c + Vector3(-0.45 + i * 0.9, 0, 0.6)
		for sx: float in [-0.35, 0.35]:
			K.box(r, Vector3(0.07, 1.4, 0.07), K.tex("wood_side"), p + Vector3(sx, 0.7, 0))
		K.box(r, Vector3(0.8, 0.07, 0.07), K.tex("wood_side"), p + Vector3(0, 1.35, 0))
		K.box(r, Vector3(0.8, 0.07, 0.07), K.tex("wood_side"), p + Vector3(0, 0.3, 0))
		K.box(r, Vector3(0.6, 0.9, 0.03), K.col("b08a60" if i == 0 else "8a6440"), p + Vector3(0, 0.82, 0))
	K.cyl(r, 0.4, 0.36, 0.5, K.tex("plank"), c + Vector3(-0.4, 0.25, -0.45), Vector3.ZERO, 10)
	K.cyl(r, 0.37, 0.37, 0.02, K.col("6a4a2a", 0.3), c + Vector3(-0.4, 0.48, -0.45), Vector3.ZERO, 10)
	for i in 3:
		K.box(
			r,
			Vector3(0.6, 0.05, 0.45),
			K.col("7a4a2a"),
			c + Vector3(0.5, 0.03 + i * 0.05, -0.45),
			Vector3(0, i * 0.2, 0)
		)


## École : tableau noir, pupitre du maître, deux petits bancs.
static func _school(r: Node3D) -> void:
	K.box(r, Vector3(0.9, 0.6, 0.05), K.col("2a3a30"), Vector3(0, 1.2, 0.42))
	K.box(r, Vector3(0.96, 0.66, 0.04), K.tex("wood_side"), Vector3(0, 1.2, 0.45))
	K.box(r, Vector3(0.5, 0.02, 0.01), K.col("e8e8e0", 0.9, 0.0, 0.3), Vector3(-0.1, 1.3, 0.39))
	K.box(r, Vector3(0.3, 0.02, 0.01), K.col("e8e8e0", 0.9, 0.0, 0.3), Vector3(0.05, 1.18, 0.39))
	for sx: float in [-0.4, 0.4]:
		K.box(r, Vector3(0.06, 0.95, 0.06), K.tex("wood_side"), Vector3(sx, 0.48, 0.42))
	K.box(r, Vector3(0.45, 0.06, 0.3), K.tex("plank"), Vector3(0, 0.65, 0.1), Vector3(0.2, 0, 0))
	K.box(r, Vector3(0.4, 0.6, 0.25), K.tex("plank"), Vector3(0, 0.3, 0.1))
	K.box(r, Vector3(0.8, 0.05, 0.22), K.tex("plank"), Vector3(0, 0.3, -0.35))
	K.legs(r, 0.8, 0.22, 0.3, K.tex("wood_side"), Vector3(0, 0, -0.35), 0.05)


## Bibliothèque : haute étagère pleine de livres colorés, échelle, lutrin avec un livre ouvert.
static func _library(r: Node3D) -> void:
	K.box(r, Vector3(0.95, 1.9, 0.35), K.tex("plank"), Vector3(0, 0.95, 0.3))
	for i in 4:
		var y := 0.2 + i * 0.45
		K.box(r, Vector3(0.9, 0.04, 0.32), K.tex("wood_side"), Vector3(0, y, 0.22))
		for j in 7:
			var h := 0.26 + float((i * 7 + j) % 3) * 0.04
			var cols := ["8c2420", "2c4a96", "3e6a3a", "6a4a2e", "c49e54", "5a3a6a"]
			K.box(
				r,
				Vector3(0.1, h, 0.24),
				K.col(cols[(i + j) % cols.size()]),
				Vector3(-0.36 + j * 0.12, y + h / 2.0 + 0.02, 0.2)
			)
	K.box(r, Vector3(0.05, 1.6, 0.05), K.tex("wood_side"), Vector3(0.4, 0.8, -0.05), Vector3(0.2, 0, 0))


## Atelier de maître : grand établi, étau, outils au mur, chef-d'œuvre sous cloche.
static func _master(r: Node3D) -> void:
	K.box(r, Vector3(0.95, 0.1, 0.6), K.tex("plank"), Vector3(0, 0.8, 0.1))
	K.legs(r, 0.95, 0.6, 0.8, K.tex("beam"), Vector3(0, 0, 0.1), 0.09)
	K.box(r, Vector3(0.2, 0.15, 0.15), K.col("4a4a52", 0.4, 0.8), Vector3(-0.35, 0.92, -0.1))
	K.box(r, Vector3(0.95, 0.9, 0.04), K.tex("plank"), Vector3(0, 1.4, 0.42))
	for i in 4:
		K.box(
			r,
			Vector3(0.04, 0.35, 0.04),
			K.col("6a6a72", 0.4, 0.7),
			Vector3(-0.3 + i * 0.2, 1.45, 0.38),
			Vector3(0, 0, 0.3 * (i % 2))
		)
	K.cyl(r, 0.12, 0.12, 0.02, K.tex("wood_side"), Vector3(0.25, 0.86, 0.1), Vector3.ZERO, 10)
	K.ball(r, 0.12, K.col("c8e0f0", 0.05, 0.1), Vector3(0.25, 0.98, 0.1))
	K.ball(r, 0.05, K.col("c49e54", 0.3, 0.8), Vector3(0.25, 0.93, 0.1))


## Ébéniste : établi à étau, chaise en cours, planches, armoire à outils.
static func _cabinetmaker(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(1.8, 0.12, 0.7), K.tex("plank"), c + Vector3(0, 0.8, 0.5))
	K.legs(r, 1.8, 0.7, 0.8, K.tex("beam"), c + Vector3(0, 0, 0.5), 0.1)
	K.box(r, Vector3(0.25, 0.2, 0.2), K.tex("wood_side"), c + Vector3(-0.7, 0.95, 0.2))
	K.box(r, Vector3(0.45, 0.05, 0.45), K.tex("plank"), c + Vector3(0.1, 0.4, -0.4))
	K.legs(r, 0.45, 0.45, 0.4, K.tex("wood_side"), c + Vector3(0.1, 0, -0.4), 0.05)
	K.box(r, Vector3(0.45, 0.5, 0.05), K.tex("plank"), c + Vector3(0.1, 0.67, -0.2))
	for i in 4:
		K.box(r, Vector3(0.25, 1.4, 0.06), K.tex("plank"), c + Vector3(0.85, 0.7, -0.6 + i * 0.08), Vector3(0.15, 0, 0))
	K.box(r, Vector3(0.6, 0.02, 0.3), K.col("d8c090"), c + Vector3(-0.3, 0.87, 0.5))


## Tailleur : mannequin habillé, table de coupe avec rouleaux de tissu, ciseaux.
static func _tailor(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0.5)
	K.box(r, Vector3(1.6, 0.1, 0.7), K.tex("plank"), c + Vector3(0, 0.78, 0.45))
	K.legs(r, 1.6, 0.7, 0.78, K.tex("wood_side"), c + Vector3(0, 0, 0.45), 0.07)
	for i in 3:
		K.cyl(
			r,
			0.09,
			0.09,
			0.6,
			K.col(["8c2420", "2c4a96", "e8dcc4"][i]),
			c + Vector3(-0.5 + i * 0.35, 0.92, 0.6),
			Vector3(PI / 2.0, 0, 0),
			8
		)
	K.box(r, Vector3(0.12, 0.02, 0.04), K.col("9a9aa2", 0.3, 0.8), c + Vector3(0.6, 0.84, 0.3), Vector3(0, 0.5, 0))
	var m := c + Vector3(-0.4, 0, -0.5)
	K.box(r, Vector3(0.05, 0.8, 0.05), K.tex("wood_side"), m + Vector3(0, 0.4, 0))
	K.box(r, Vector3(0.4, 0.04, 0.4), K.tex("wood_side"), m + Vector3(0, 0.02, 0))
	K.box(r, Vector3(0.4, 0.55, 0.25), K.col("3e6a3a"), m + Vector3(0, 1.05, 0))
	K.box(r, Vector3(0.44, 0.08, 0.27), K.col("c49e54"), m + Vector3(0, 0.84, 0))
	K.box(r, Vector3(0.48, 0.12, 0.22), K.col("3e6a3a"), m + Vector3(0, 1.3, 0))


## Cuve de teinture : grande cuve de bois cerclée, eau colorée, bâton, écheveaux qui sèchent.
static func _dye_vat(r: Node3D) -> void:
	K.cyl(r, 0.42, 0.38, 0.6, K.tex("plank"), Vector3(0, 0.3, 0), Vector3.ZERO, 12)
	for y: float in [0.12, 0.48]:
		K.cyl(r, 0.43, 0.43, 0.04, K.col("3a3a40", 0.5, 0.6), Vector3(0, y, 0), Vector3.ZERO, 12)
	K.cyl(r, 0.39, 0.39, 0.02, K.col("2c4a96", 0.2), Vector3(0, 0.58, 0), Vector3.ZERO, 12)
	K.box(r, Vector3(0.04, 0.9, 0.04), K.tex("wood_side"), Vector3(0.12, 0.8, 0), Vector3(0, 0, 0.4))
	K.box(r, Vector3(0.9, 0.04, 0.04), K.tex("wood_side"), Vector3(0, 1.3, 0.42))
	for i in 3:
		K.box(
			r, Vector3(0.12, 0.35, 0.04), K.col(["8c2420", "c8a040", "2c4a96"][i]), Vector3(-0.3 + i * 0.3, 1.1, 0.42)
		)
