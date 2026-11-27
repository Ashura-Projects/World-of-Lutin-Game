class_name FarmModels
extends RefCounted
## Ferme et camp (1.3.2), low poly texturé : vache, cochon, clôture fine (se relie aux voisines), portillon,
## tentes en peau ou en tissu (1 place ou couple), laiterie, billot de boucher, râtelier à foin, auge.

const K = preload("res://src/view/model_kit.gd")


## Animaux d'élevage. Avant = -Z.
static func animal(kind: String) -> Node3D:
	var r := Node3D.new()
	if kind == "cow":
		var hide := K.col("f0ece4", 0.95)
		var spot := K.col("2e2a28", 0.95)
		K.box(r, Vector3(0.62, 0.55, 1.15), hide, Vector3(0, 0.85, 0.05))
		K.box(r, Vector3(0.3, 0.3, 0.35), spot, Vector3(0.2, 0.95, 0.25))
		K.box(r, Vector3(0.25, 0.25, 0.3), spot, Vector3(-0.22, 0.85, -0.2))
		K.box(r, Vector3(0.36, 0.36, 0.4), hide, Vector3(0, 1.08, -0.68))
		K.box(r, Vector3(0.3, 0.18, 0.12), K.col("e8a8a0"), Vector3(0, 0.98, -0.9))
		for sx: float in [-1.0, 1.0]:
			K.cyl(r, 0.0, 0.035, 0.18, K.col("e8dcc0"), Vector3(sx * 0.18, 1.3, -0.66), Vector3(0, 0, -sx * 0.9), 5)
			K.box(r, Vector3(0.12, 0.06, 0.08), hide, Vector3(sx * 0.24, 1.16, -0.6))
			for sz: float in [-0.38, 0.45]:
				K.box(r, Vector3(0.13, 0.6, 0.13), hide, Vector3(sx * 0.2, 0.3, sz))
				K.box(r, Vector3(0.14, 0.08, 0.14), K.col("3a3030"), Vector3(sx * 0.2, 0.04, sz))
		K.box(r, Vector3(0.2, 0.1, 0.16), K.col("f0b0b0"), Vector3(0, 0.55, 0.3))
		K.box(r, Vector3(0.04, 0.5, 0.04), hide, Vector3(0, 0.85, 0.65), Vector3(0.2, 0, 0))
	else:
		var pink := K.col("e8a0a0", 0.9)
		K.box(r, Vector3(0.48, 0.42, 0.8), pink, Vector3(0, 0.45, 0))
		K.box(r, Vector3(0.36, 0.34, 0.24), pink, Vector3(0, 0.5, -0.48))
		K.cyl(r, 0.09, 0.09, 0.08, K.col("d07878"), Vector3(0, 0.46, -0.62), Vector3(PI / 2.0, 0, 0), 8)
		for sx: float in [-1.0, 1.0]:
			K.box(r, Vector3(0.1, 0.1, 0.04), K.col("d88a8a"), Vector3(sx * 0.13, 0.7, -0.5), Vector3(0.4, 0, 0))
			K.box(r, Vector3(0.04, 0.04, 0.02), K.col("202020"), Vector3(sx * 0.09, 0.58, -0.61))
			for sz: float in [-0.25, 0.25]:
				K.box(r, Vector3(0.1, 0.25, 0.1), pink, Vector3(sx * 0.15, 0.12, sz))
		K.ball(r, 0.05, pink, Vector3(0, 0.55, 0.42), Vector3(1, 1, 1.5))
	return r


static func build(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"fence":
			fence(r, 0)
		"fence_gate":
			K.box(r, Vector3(0.14, 1.0, 0.14), K.tex("wood_side"), Vector3(-0.45, 0.5, 0))
			K.box(r, Vector3(0.14, 1.0, 0.14), K.tex("wood_side"), Vector3(0.45, 0.5, 0))
		"tent", "tent_double", "tent_cloth", "tent_cloth_double":
			_tent(r, kind)
		"camp_tent":  # petite tente militaire aux couleurs de la faction
			var fac := Faction.current.color1 if Faction.current != null else "2c4a96"
			K.prism(r, Vector3(0.95, 0.8, 1.0), K.col("d8d0b8", 0.95), Vector3(0, 0.4, 0))
			K.prism(r, Vector3(0.36, 0.3, 1.02), K.col(fac, 0.9), Vector3(0, 0.66, 0))
			K.box(r, Vector3(0.04, 1.1, 0.04), K.tex("wood_side"), Vector3(0, 0.55, -0.5))
			K.box(r, Vector3(0.3, 0.18, 0.02), K.col(fac, 0.9), Vector3(0.15, 1.0, -0.5))
		"dairy":
			_dairy(r)
		"butcher_block":
			_butcher(r)
		"hay_rack":
			K.box(r, Vector3(0.9, 0.08, 0.5), K.tex("plank"), Vector3(0, 0.4, 0))
			K.legs(r, 0.9, 0.5, 0.4, K.tex("wood_side"), Vector3.ZERO, 0.08)
			for i in 6:
				K.box(
					r,
					Vector3(0.04, 0.55, 0.04),
					K.tex("wood_side"),
					Vector3(-0.38 + i * 0.15, 0.7, 0.2),
					Vector3(-0.35, 0, 0)
				)
			K.box(r, Vector3(0.8, 0.35, 0.4), K.tex("straw"), Vector3(0, 0.62, 0.05))
		"pig_trough":
			K.box(r, Vector3(0.9, 0.08, 0.45), K.tex("plank"), Vector3(0, 0.05, 0))
			for sz: float in [-0.2, 0.2]:
				K.box(r, Vector3(0.9, 0.28, 0.06), K.tex("plank"), Vector3(0, 0.18, sz), Vector3(sz * 1.5, 0, 0))
			K.box(r, Vector3(0.82, 0.04, 0.32), K.col("8a7040"), Vector3(0, 0.2, 0))
		_:
			return null
	return r


## Clôture : poteau central et deux lisses vers chaque voisine (masque : 1 = -Z, 2 = +X, 4 = +Z, 8 = -X).
static func fence(r: Node3D, mask: int) -> void:
	var wood := K.tex("wood_side")
	K.box(r, Vector3(0.16, 1.05, 0.16), wood, Vector3(0, 0.52, 0))
	K.box(r, Vector3(0.2, 0.06, 0.2), wood, Vector3(0, 1.06, 0))
	var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
	for i in 4:
		if mask & (1 << i) == 0:
			continue
		var d: Vector3 = dirs[i]
		for y: float in [0.4, 0.82]:
			var size := Vector3(0.06, 0.1, 0.5) if d.x == 0.0 else Vector3(0.5, 0.1, 0.06)
			K.box(r, size, K.tex("plank"), d * 0.25 + Vector3(0, y, 0))


## Battant du portillon (charnière à gauche) : deux lisses, montant en diagonale.
static func gate_leaf() -> Node3D:
	var r := Node3D.new()
	for y: float in [0.35, 0.8]:
		K.box(r, Vector3(0.76, 0.1, 0.06), K.tex("plank"), Vector3(0.38, y, 0))
	K.box(r, Vector3(0.06, 0.6, 0.06), K.tex("plank"), Vector3(0.38, 0.57, 0), Vector3(0, 0, 0.9))
	K.box(r, Vector3(0.06, 0.6, 0.08), K.tex("wood_side"), Vector3(0.05, 0.57, 0))
	return r


## Tente : peau (brune, coutures) ou tissu (rayée, couleur de faction) ; la double est plus large.
static func _tent(r: Node3D, kind: String) -> void:
	var cloth := kind.begins_with("tent_cloth")
	var wide := kind.ends_with("double")
	var c := Vector3(0.5, 0, 0.5)
	var w := 1.9 if wide else 1.5
	var fac := Faction.current.color1 if Faction.current != null else "2c4a96"
	var m: Material = K.col("e4dcc8", 0.95) if cloth else K.col("9a7656", 0.95)
	K.prism(r, Vector3(w, 1.35, 1.9), m, c + Vector3(0, 0.68, 0))
	if cloth:
		K.prism(r, Vector3(w * 0.35, 0.48, 1.92), K.col(fac, 0.9), c + Vector3(0, 1.12, 0))
	else:
		for i in 3:
			K.box(
				r,
				Vector3(0.03, 0.9, 0.02),
				K.col("6a4a30"),
				c + Vector3(-0.32 + i * 0.32, 0.55, -0.96),
				Vector3(0, 0, 0.5 - i * 0.5)
			)
	K.box(r, Vector3(w * 0.42, 1.0, 0.04), K.col("2a2018"), c + Vector3(0, 0.45, -0.96))
	for sz: float in [-1.0, 1.0]:
		K.box(r, Vector3(0.07, 1.6, 0.07), K.tex("wood_side"), c + Vector3(0, 0.8, sz))
	for sx: float in [-1.0, 1.0]:
		K.box(
			r,
			Vector3(0.05, 0.05, 0.6),
			K.col("c8b890"),
			c + Vector3(sx * (w / 2.0 + 0.15), 0.15, -0.95),
			Vector3(0.5, 0, 0)
		)
	K.box(r, Vector3(w * 0.8, 0.06, 1.6), K.col("7a6a50"), c + Vector3(0, 0.03, 0.05))
	if wide:
		K.box(r, Vector3(w * 0.5, 0.1, 0.25), K.col("c8b48a"), c + Vector3(0, 0.08, 0.6))


## Laiterie : baratte, presse à fromage, meules de fromage sur l'étagère, bidons de lait.
static func _dairy(r: Node3D) -> void:
	var c := Vector3(0.5, 0, 0)
	K.box(r, Vector3(1.8, 0.1, 0.6), K.tex("plank"), c + Vector3(0, 0.7, 0.1))
	K.legs(r, 1.8, 0.6, 0.7, K.tex("wood_side"), c + Vector3(0, 0, 0.1), 0.08)
	K.cyl(r, 0.18, 0.22, 0.7, K.tex("plank"), c + Vector3(-0.55, 0.35, -0.4), Vector3.ZERO, 10)
	K.cyl(r, 0.02, 0.02, 0.6, K.tex("wood_side"), c + Vector3(-0.55, 0.9, -0.4))
	for i in 2:
		K.box(r, Vector3(0.08, 0.5, 0.08), K.tex("beam"), c + Vector3(0.25 + i * 0.5, 1.0, 0.1))
	K.box(r, Vector3(0.6, 0.1, 0.12), K.tex("beam"), c + Vector3(0.5, 1.25, 0.1))
	K.cyl(r, 0.18, 0.18, 0.12, K.col("e8c860", 0.6), c + Vector3(0.5, 0.82, 0.1), Vector3.ZERO, 10)
	K.cyl(r, 0.2, 0.2, 0.06, K.tex("plank"), c + Vector3(0.5, 0.93, 0.1), Vector3.ZERO, 10)
	K.cyl(r, 0.025, 0.025, 0.3, K.col("4a4a50", 0.4, 0.7), c + Vector3(0.5, 1.08, 0.1))
	for i in 3:
		K.cyl(
			r,
			0.13,
			0.13,
			0.09,
			K.col("f0d070", 0.5),
			c + Vector3(-0.15 + i * 0.0, 0.8 + i * 0.1, 0.15),
			Vector3.ZERO,
			10
		)
	for i in 2:
		K.cyl(
			r, 0.12, 0.13, 0.4, K.col("a8a8b0", 0.35, 0.7), c + Vector3(0.65 + i * 0.28, 0.2, -0.38), Vector3.ZERO, 10
		)


## Billot de boucher : grosse souche, couperet planté, crochets et jambons suspendus.
static func _butcher(r: Node3D) -> void:
	K.cyl(r, 0.36, 0.4, 0.75, K.tex("wood_side"), Vector3(0, 0.375, 0.1), Vector3.ZERO, 10)
	K.cyl(r, 0.36, 0.36, 0.02, K.tex("wood_top"), Vector3(0, 0.76, 0.1), Vector3.ZERO, 10)
	K.box(r, Vector3(0.04, 0.18, 0.26), K.col("8a8a92", 0.3, 0.8), Vector3(0.1, 0.86, 0.05))
	K.box(r, Vector3(0.05, 0.05, 0.22), K.tex("wood_side"), Vector3(0.1, 0.97, 0.22))
	for sx: float in [-0.42, 0.42]:
		K.box(r, Vector3(0.08, 1.8, 0.08), K.tex("beam"), Vector3(sx, 0.9, 0.42))
	K.box(r, Vector3(0.95, 0.08, 0.08), K.tex("beam"), Vector3(0, 1.8, 0.42))
	for i in 2:
		K.box(r, Vector3(0.02, 0.2, 0.02), K.col("5a5a60", 0.4, 0.7), Vector3(-0.2 + i * 0.4, 1.66, 0.42))
		K.ball(r, 0.13, K.col("a0503a"), Vector3(-0.2 + i * 0.4, 1.42, 0.42), Vector3(0.9, 1.4, 0.9))
