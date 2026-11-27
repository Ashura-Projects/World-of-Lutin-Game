class_name DecorModels
extends RefCounted
## Modèles des objets de la 1.3 : cheminée, torches, braseros, lit double, meubles, tapis, tapisseries,
## jeux, bar, abreuvoir, mangeoire. Origine au centre de la case, au sol ; les objets muraux sont contre +Z.


static func _b(
	r: Node3D, size: Vector3, color: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, emit: float = 0.0
) -> void:
	StructuresView._box(r, size, color, pos, rot, emit)


static func _light(r: Node3D, pos: Vector3, energy: float = 1.2, rng: float = 6.0) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color("ffa050")
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	r.add_child(l)


static func _flame(r: Node3D, pos: Vector3, s: float = 1.0) -> void:
	_b(r, Vector3(0.18, 0.26, 0.18) * s, "ffb050", pos, Vector3(0, 0.7, 0), 7.0)
	_b(r, Vector3(0.1, 0.18, 0.1) * s, "fff0b0", pos + Vector3(0, 0.05, 0), Vector3(0, 0.3, 0), 9.0)


const CARPETS := {
	"carpet_red": ["8c2420", "c49e54"],
	"carpet_blue": ["2c4a96", "c8c0a8"],
	"carpet_green": ["3e6a3a", "c49e54"],
	"carpet_fur": ["9a8a70", "6a5a48"]
}
const TAPESTRIES := {
	"tapestry_red": ["8c2420", "c49e54"],
	"tapestry_blue": ["2c4a96", "e8dcc4"],
	"tapestry_gold": ["c49e54", "6a3a20"],
	"tapestry_hunt": ["4a6a3a", "c8b890"]
}


## Encadrement d'une porte (le battant est animé par GatesView).
static func door_frame(kind: String) -> Node3D:
	var r := Node3D.new()
	var w := 2.0 if kind == "double_door" else 1.0
	var col := "4a4a52" if kind == "iron_door" else "5a3e28"
	_b(r, Vector3(0.1, 2.1, 0.16), col, Vector3(-0.5, 1.05, 0))
	_b(r, Vector3(0.1, 2.1, 0.16), col, Vector3(w - 0.5, 1.05, 0))
	_b(r, Vector3(w + 0.1, 0.12, 0.16), col, Vector3(w / 2.0 - 0.5, 2.06, 0))
	return r


## Battant de porte (charnière à gauche) : bois, fer ou grande porte.
static func door_leaf(kind: String) -> Node3D:
	var r := Node3D.new()
	var w := 1.9 if kind == "double_door" else 0.9
	var col := "4a4a52" if kind == "iron_door" else "6e4e30"
	_b(r, Vector3(w, 1.95, 0.08), col, Vector3(w / 2.0, 0.98, 0))
	for y: float in [0.4, 1.5]:
		_b(r, Vector3(w, 0.06, 0.1), "2a2a30" if kind == "iron_door" else "4a3420", Vector3(w / 2.0, y, 0))
	_b(r, Vector3(0.08, 0.08, 0.14), "c49e54", Vector3(w - 0.15, 1.0, 0))
	return r


static func build(kind: String) -> Node3D:
	var r := Node3D.new()
	if CARPETS.has(kind):
		var c: Array = CARPETS[kind]
		_b(r, Vector3(0.98, 0.03, 0.98), c[0], Vector3(0, 0.015, 0))
		_b(r, Vector3(0.8, 0.035, 0.8), c[1], Vector3(0, 0.02, 0))
		_b(r, Vector3(0.6, 0.04, 0.6), c[0], Vector3(0, 0.025, 0))
		return r
	if TAPESTRIES.has(kind):
		var c: Array = TAPESTRIES[kind]
		_b(r, Vector3(0.9, 0.06, 0.06), "5a3e28", Vector3(0, 1.85, 0.44))
		_b(r, Vector3(0.8, 1.5, 0.03), c[0], Vector3(0, 1.08, 0.46))
		_b(r, Vector3(0.6, 1.2, 0.035), c[1], Vector3(0, 1.1, 0.455))
		_b(r, Vector3(0.4, 0.9, 0.04), c[0], Vector3(0, 1.1, 0.45))
		return r
	match kind:
		"fireplace":
			_b(r, Vector3(1.0, 1.2, 0.5), "8a5a48", Vector3(0, 0.6, 0.25))
			_b(r, Vector3(0.6, 0.6, 0.3), "1a1414", Vector3(0, 0.35, 0.12))
			_b(r, Vector3(1.1, 0.12, 0.6), "6a6a6a", Vector3(0, 1.22, 0.22))
			_flame(r, Vector3(0, 0.25, 0.1), 1.3)
			_light(r, Vector3(0, 0.6, -0.4), 1.6, 7.0)
		"wall_torch":
			_b(r, Vector3(0.08, 0.4, 0.08), "5a3e28", Vector3(0, 1.25, 0.38), Vector3(-0.4, 0, 0))
			_b(r, Vector3(0.12, 0.08, 0.14), "3a3a3e", Vector3(0, 1.1, 0.46))
			_flame(r, Vector3(0, 1.5, 0.3))
			_light(r, Vector3(0, 1.5, 0.1))
		"standing_torch":
			_b(r, Vector3(0.08, 1.5, 0.08), "3a3a3e", Vector3(0, 0.75, 0))
			for i in 3:
				_b(r, Vector3(0.3, 0.05, 0.05), "3a3a3e", Vector3(0, 0.04, 0), Vector3(0, i * 2.1, 0))
			_flame(r, Vector3(0, 1.6, 0))
			_light(r, Vector3(0, 1.7, 0))
		"brazier_stone", "brazier_iron":
			var col := "8a8278" if kind == "brazier_stone" else "3a3a40"
			_b(r, Vector3(0.7, 0.5, 0.7), col, Vector3(0, 0.25, 0))
			_b(r, Vector3(0.8, 0.1, 0.8), col, Vector3(0, 0.55, 0))
			_b(r, Vector3(0.5, 0.1, 0.5), "ff7a30", Vector3(0, 0.6, 0), Vector3.ZERO, 5.0)
			_flame(r, Vector3(0, 0.78, 0), 1.6)
			_light(r, Vector3(0, 1.1, 0), 1.6, 8.0)
		"double_bed":
			_b(r, Vector3(1.6, 0.3, 0.95), "7a5836", Vector3(0.3, 0.15, 0))
			_b(r, Vector3(1.6, 0.7, 0.08), "5a3e28", Vector3(0.3, 0.45, 0.45))
			_b(r, Vector3(1.5, 0.12, 0.85), "2c4a96", Vector3(0.3, 0.34, -0.03))
			for x: float in [-0.05, 0.65]:
				_b(r, Vector3(0.5, 0.1, 0.2), "e8dcc4", Vector3(x, 0.42, 0.3))
		"nightstand":
			_b(r, Vector3(0.5, 0.5, 0.45), "6e4e30", Vector3(0, 0.25, 0.2))
			_b(r, Vector3(0.1, 0.18, 0.1), "f0e0a0", Vector3(0, 0.6, 0.2), Vector3.ZERO, 2.0)
		"bookshelf":
			_b(r, Vector3(0.95, 1.9, 0.4), "6e4e30", Vector3(0, 0.95, 0.28))
			for y: float in [0.45, 0.95, 1.45]:
				for i in 6:
					_b(
						r,
						Vector3(0.1, 0.32, 0.25),
						["8c2420", "2c4a96", "3e6a3a", "c49e54"][(i + int(y * 10)) % 4],
						Vector3(-0.35 + i * 0.14, y, 0.22)
					)
		"stool":
			_b(r, Vector3(0.4, 0.06, 0.4), "7a5836", Vector3(0, 0.4, 0))
			_b(r, Vector3(0.08, 0.4, 0.08), "5a3e28", Vector3(0, 0.2, 0))
		"armchair":
			_b(r, Vector3(0.7, 0.35, 0.6), "8c2420", Vector3(0, 0.3, 0))
			_b(r, Vector3(0.7, 0.6, 0.12), "8c2420", Vector3(0, 0.7, 0.26))
			for x: float in [-0.33, 0.33]:
				_b(r, Vector3(0.1, 0.3, 0.6), "6e4e30", Vector3(x, 0.55, 0))
		"cupboard":
			_b(r, Vector3(0.95, 1.1, 0.5), "6e4e30", Vector3(0, 0.55, 0.22))
			_b(r, Vector3(0.9, 0.04, 0.46), "4a3420", Vector3(0, 0.6, 0.0))
		"candelabra":
			_b(r, Vector3(0.06, 1.3, 0.06), "b8902e", Vector3(0, 0.65, 0))
			_b(r, Vector3(0.5, 0.05, 0.05), "b8902e", Vector3(0, 1.3, 0))
			for x: float in [-0.25, 0.0, 0.25]:
				_b(r, Vector3(0.05, 0.14, 0.05), "f0e8d0", Vector3(x, 1.4, 0))
				_b(r, Vector3(0.04, 0.06, 0.04), "ffd27a", Vector3(x, 1.5, 0), Vector3.ZERO, 6.0)
			_light(r, Vector3(0, 1.5, 0), 0.9, 5.0)
		"statue":
			_b(r, Vector3(0.8, 0.4, 0.8), "a49c90", Vector3(0, 0.2, 0))
			var head := MeshInstance3D.new()
			head.mesh = SphereMesh.new()
			head.scale = Vector3(0.5, 0.5, 0.5)
			head.position = Vector3(0, 1.35, 0)
			head.material_override = LutinModel.mat("b8b0a4", 0.8)
			r.add_child(head)
			_b(r, Vector3(0.45, 0.8, 0.35), "b8b0a4", Vector3(0, 0.8, 0))
		"iron_door":
			_b(r, Vector3(0.9, 1.9, 0.12), "4a4a52", Vector3(0, 0.95, -0.44))
			for y: float in [0.4, 1.0, 1.6]:
				_b(r, Vector3(0.92, 0.06, 0.14), "2a2a30", Vector3(0, y, -0.44))
		"double_door":
			_b(r, Vector3(1.9, 2.4, 0.14), "6e4e30", Vector3(0.5, 1.2, -0.44))
			_b(r, Vector3(0.04, 2.3, 0.16), "3a2a1e", Vector3(0.5, 1.2, -0.44))
			for x: float in [0.35, 0.65]:
				_b(r, Vector3(0.08, 0.08, 0.06), "c49e54", Vector3(x, 1.2, -0.52))
		"dice_table", "chess_table", "card_table":
			_b(r, Vector3(0.9, 0.08, 0.9), "7a5836", Vector3(0, 0.6, 0))
			_b(r, Vector3(0.12, 0.6, 0.12), "5a3e28", Vector3(0, 0.3, 0))
			if kind == "chess_table":
				for i in 4:
					for j in 4:
						_b(
							r,
							Vector3(0.12, 0.02, 0.12),
							"e8dcc4" if (i + j) % 2 == 0 else "2a2020",
							Vector3(-0.18 + i * 0.12, 0.65, -0.18 + j * 0.12)
						)
			elif kind == "dice_table":
				for i in 3:
					_b(
						r,
						Vector3(0.08, 0.08, 0.08),
						"f0e8d0",
						Vector3(-0.15 + i * 0.15, 0.68, 0.05 * i),
						Vector3(0, i, 0)
					)
			else:
				for i in 4:
					_b(
						r,
						Vector3(0.12, 0.01, 0.17),
						"f0e8d0",
						Vector3(-0.2 + i * 0.13, 0.65, 0),
						Vector3(0, i * 0.3, 0)
					)
		"bar_counter":
			_b(r, Vector3(1.0, 1.0, 0.6), "6e4e30", Vector3(0, 0.5, 0))
			_b(r, Vector3(1.05, 0.08, 0.7), "4a3420", Vector3(0, 1.04, 0))
			for i in 3:
				_b(r, Vector3(0.1, 0.18, 0.1), ["c49e54", "8c2420", "3e6a3a"][i], Vector3(-0.3 + i * 0.3, 1.17, 0.1))
		"portcullis", "drawbridge":
			# objet porteur : la herse / le pont animés sont dessinés par GatesView une fois bâtis
			_b(r, Vector3(0.25, 0.4, 0.25), "3a3a40", Vector3(0, 0.2, 0))
		"pew":
			_b(r, Vector3(0.95, 0.08, 0.4), "6e4e30", Vector3(0, 0.45, 0))
			_b(r, Vector3(0.95, 0.6, 0.06), "5a3e28", Vector3(0, 0.75, 0.2))
			for x: float in [-0.42, 0.42]:
				_b(r, Vector3(0.06, 0.45, 0.38), "5a3e28", Vector3(x, 0.22, 0))
		"lectern":
			_b(r, Vector3(0.12, 1.0, 0.12), "5a3e28", Vector3(0, 0.5, 0))
			_b(r, Vector3(0.5, 0.06, 0.4), "6e4e30", Vector3(0, 1.05, 0), Vector3(-0.4, 0, 0))
			_b(r, Vector3(0.36, 0.04, 0.26), "e8dcc4", Vector3(0, 1.1, 0), Vector3(-0.4, 0, 0))
		"small_altar":
			_b(r, Vector3(0.7, 0.8, 0.45), "c8c0b0", Vector3(0, 0.4, 0))
			_b(r, Vector3(0.75, 0.05, 0.5), "c49e54", Vector3(0, 0.82, 0))
			_b(r, Vector3(0.06, 0.2, 0.06), "f0e0a0", Vector3(0, 0.95, 0), Vector3.ZERO, 3.0)
		"tombstone":
			_b(r, Vector3(0.7, 0.04, 0.9), "4a6a3a", Vector3(0, 0.02, 0))
			_b(r, Vector3(0.5, 0.75, 0.12), "8a8a8a", Vector3(0, 0.38, 0.3))
			_b(r, Vector3(0.36, 0.06, 0.14), "6a6a6a", Vector3(0, 0.6, 0.3))
		"water_trough":
			_b(r, Vector3(1.0, 0.4, 0.5), "6e4e30", Vector3(0, 0.2, 0))
			_b(r, Vector3(0.9, 0.05, 0.4), "3a6aa8", Vector3(0, 0.38, 0))
		"feeder":
			_b(r, Vector3(1.0, 0.5, 0.5), "6e4e30", Vector3(0, 0.25, 0))
			_b(r, Vector3(0.9, 0.12, 0.4), "c8a84a", Vector3(0, 0.52, 0))
		_:
			return null
	return r
