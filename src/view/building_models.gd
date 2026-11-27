class_name BuildingModels
extends RefCounted
## Modèles des bâtiments de la 1.2 : chapelle, église, autel, cloche, caserne, tour de guet, borne de territoire.
## L'origine est la case du coin (comme les autres objets) ; avant = -Z.


static func _b(
	r: Node3D, size: Vector3, color: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, emit: float = 0.0
) -> void:
	StructuresView._box(r, size, color, pos, rot, emit)


static func _roof(r: Node3D, size: Vector3, color: String, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = LutinModel.mat(color, 0.9)
	mi.position = pos
	r.add_child(mi)


## Symbole de la religion (disque doré à rayons) au sommet.
static func _symbol(r: Node3D, pos: Vector3) -> void:
	var col := Religion.active.color if Religion.active != null else "e8c440"
	_b(r, Vector3(0.5, 0.5, 0.08), col, pos, Vector3(0, 0, PI / 4), 1.5)
	_b(r, Vector3(0.5, 0.5, 0.08), col, pos)


static func build(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"chapel":
			var c := Vector3(1.0, 0, 1.0)
			_b(r, Vector3(3.0, 2.2, 3.0), "8a8278", c + Vector3(0, 1.1, 0))
			_roof(r, Vector3(3.4, 1.4, 3.2), "5a3e2c", c + Vector3(0, 2.9, 0))
			_b(r, Vector3(0.8, 1.5, 0.1), "4a3020", c + Vector3(0, 0.75, -1.52))
			_b(r, Vector3(0.6, 1.4, 0.6), "8a8278", c + Vector3(0, 3.6, 1.0))
			_symbol(r, c + Vector3(0, 4.6, 1.0))
		"church":
			var c := Vector3(2.0, 0, 2.0)
			_b(r, Vector3(5.0, 3.4, 5.0), "a49c90", c + Vector3(0, 1.7, 0))
			_roof(r, Vector3(5.4, 2.2, 5.2), "4a3a30", c + Vector3(0, 4.5, 0))
			_b(r, Vector3(1.6, 6.5, 1.6), "a49c90", c + Vector3(0, 3.25, 1.7))
			_roof(r, Vector3(1.8, 1.6, 1.8), "4a3a30", c + Vector3(0, 7.3, 1.7))
			_b(r, Vector3(1.2, 2.2, 0.1), "4a3020", c + Vector3(0, 1.1, -2.52))
			for x: float in [-1.6, 1.6]:
				_b(r, Vector3(0.6, 1.2, 0.08), "4a6ea8", c + Vector3(x, 2.0, -2.52), Vector3.ZERO, 0.6)
			_symbol(r, c + Vector3(0, 8.4, 1.7))
		"altar":
			_b(r, Vector3(0.9, 0.7, 0.5), "c8c0b0", Vector3(0, 0.35, 0))
			_b(r, Vector3(0.95, 0.06, 0.55), "8c2420", Vector3(0, 0.72, 0))
			_b(r, Vector3(0.08, 0.3, 0.08), "f0e0a0", Vector3(-0.3, 0.9, 0), Vector3.ZERO, 2.0)
			_b(r, Vector3(0.08, 0.3, 0.08), "f0e0a0", Vector3(0.3, 0.9, 0), Vector3.ZERO, 2.0)
		"church_bell":
			_b(r, Vector3(0.1, 2.0, 0.1), "5a3e28", Vector3(-0.4, 1.0, 0))
			_b(r, Vector3(0.1, 2.0, 0.1), "5a3e28", Vector3(0.4, 1.0, 0))
			_b(r, Vector3(0.9, 0.1, 0.1), "5a3e28", Vector3(0, 2.0, 0))
			var bell := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.15
			cm.bottom_radius = 0.32
			cm.height = 0.5
			bell.mesh = cm
			bell.material_override = LutinModel.mat("b8902e", 0.35, 0.8)
			bell.position = Vector3(0, 1.65, 0)
			r.add_child(bell)
		"barracks":
			var c := Vector3(1.5, 0, 1.5)
			_b(r, Vector3(4.0, 2.4, 4.0), "6a5a48", c + Vector3(0, 1.2, 0))
			_roof(r, Vector3(4.4, 1.2, 4.2), "3a3a40", c + Vector3(0, 3.0, 0))
			_b(r, Vector3(1.0, 1.6, 0.1), "3a2a1e", c + Vector3(0, 0.8, -2.02))
			var col := Faction.current.color1 if Faction.current != null else "2c4a96"
			_b(r, Vector3(0.06, 2.4, 0.06), "5a3e28", c + Vector3(2.2, 1.2, -2.2))
			_b(r, Vector3(0.8, 0.5, 0.04), col, c + Vector3(2.6, 2.1, -2.2))
		"watchtower":
			var c := Vector3(0.5, 0, 0.5)
			for sx: float in [-0.8, 0.8]:
				for sz: float in [-0.8, 0.8]:
					_b(r, Vector3(0.18, 5.0, 0.18), "5a3e28", c + Vector3(sx, 2.5, sz))
			_b(r, Vector3(2.2, 0.15, 2.2), "7a5836", c + Vector3(0, 5.0, 0))
			for e: Vector3 in [Vector3(0, 5.4, -1.05), Vector3(0, 5.4, 1.05)]:
				_b(r, Vector3(2.2, 0.7, 0.1), "6a4a2e", c + e)
			_roof(r, Vector3(2.6, 1.2, 2.6), "5a3e2c", c + Vector3(0, 6.6, 0))
		"catapult":
			var c := Vector3(0.5, 0, 0.5)
			for sx: float in [-0.7, 0.7]:
				_b(r, Vector3(0.14, 0.14, 2.0), "5a3e28", c + Vector3(sx, 0.35, 0))
				for sz: float in [-0.7, 0.7]:
					var wheel := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.3
					cm.bottom_radius = 0.3
					cm.height = 0.1
					wheel.mesh = cm
					wheel.material_override = LutinModel.mat("4a3420", 0.8)
					wheel.position = c + Vector3(sx * 1.1, 0.3, sz)
					wheel.rotation.z = PI / 2.0
					r.add_child(wheel)
			for sz: float in [-0.7, 0.7]:
				_b(r, Vector3(1.5, 0.14, 0.14), "5a3e28", c + Vector3(0, 0.35, sz))
			for sx: float in [-0.5, 0.5]:
				_b(r, Vector3(0.12, 1.2, 0.12), "6a4a2e", c + Vector3(sx, 0.95, 0.2))
			_b(r, Vector3(1.1, 0.1, 0.1), "6a4a2e", c + Vector3(0, 1.5, 0.2))
			_b(r, Vector3(0.12, 0.12, 2.2), "7a5836", c + Vector3(0, 1.1, -0.1), Vector3(0.55, 0, 0))
			_b(r, Vector3(0.4, 0.2, 0.4), "5a3e28", c + Vector3(0, 1.85, -0.75))
			_b(r, Vector3(0.6, 0.6, 0.6), "6a6a6a", c + Vector3(0, 0.75, 0.75))
		"claim_post":
			var col := Faction.current.color1 if Faction.current != null else "2c4a96"
			_b(r, Vector3(0.3, 0.3, 0.3), "8a8278", Vector3(0, 0.15, 0))
			_b(r, Vector3(0.1, 2.2, 0.1), "5a3e28", Vector3(0, 1.1, 0))
			_b(r, Vector3(0.7, 0.45, 0.04), col, Vector3(0.38, 1.9, 0))
		_:
			return null
	return r
