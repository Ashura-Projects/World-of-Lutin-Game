class_name HorseModel
extends RefCounted
## Cheval low-poly (1.3.1, plus beau) : corps galbé, poitrail, croupe, encolure dressée, tête fine et museau,
## oreilles, crinière et queue, jambes avec genoux et sabots ; selle et bride s'il est à nous. Avant = -Z.

const COAT := ["7a4e30", "5a3a24", "a07850", "3a2a22", "c8c0b0"]


static func _p(
	r: Node3D, mesh: Mesh, col: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = LutinModel.mat(col, 0.75)
	mi.position = pos
	mi.scale = sc
	mi.rotation = rot
	r.add_child(mi)
	return mi


static func _sph() -> SphereMesh:
	var s := SphereMesh.new()
	s.radial_segments = 12
	s.rings = 6
	return s


static func _cyl(top: float, bot: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bot
	c.height = h
	c.radial_segments = 8
	return c


static func build(seed_id: int = 0, saddled: bool = false) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * 0.72  # à l'échelle des lutins (petits chevaux)
	var coat: String = COAT[seed_id % COAT.size()]
	var dark := Color(coat).darkened(0.45).to_html(false)
	var s := _sph()
	_p(root, s, coat, Vector3(0, 1.05, 0), Vector3(0.42, 0.44, 0.78))  # ventre
	_p(root, s, coat, Vector3(0, 1.12, -0.42), Vector3(0.4, 0.46, 0.42))  # poitrail
	_p(root, s, coat, Vector3(0, 1.14, 0.42), Vector3(0.42, 0.44, 0.44))  # croupe
	_p(root, _cyl(0.16, 0.24, 0.72), coat, Vector3(0, 1.5, -0.62), Vector3.ONE, Vector3(-0.55, 0, 0))  # encolure
	_p(root, s, coat, Vector3(0, 1.82, -0.86), Vector3(0.17, 0.2, 0.3), Vector3(0.5, 0, 0))  # tête
	_p(root, s, Color(coat).darkened(0.25).to_html(false), Vector3(0, 1.68, -1.06), Vector3(0.13, 0.13, 0.16))  # museau
	for sx: float in [-1.0, 1.0]:
		_p(root, _cyl(0.0, 0.05, 0.16), coat, Vector3(sx * 0.08, 2.03, -0.8), Vector3.ONE, Vector3(-0.2, 0, sx * 0.25))
		_p(root, s, "181414", Vector3(sx * 0.12, 1.86, -0.95), Vector3(0.035, 0.035, 0.035))
	for i in 6:  # crinière
		_p(
			root,
			_cyl(0.0, 0.06, 0.18),
			dark,
			Vector3(0, 1.95 - i * 0.1, -0.78 + i * 0.07),
			Vector3.ONE,
			Vector3(-0.3, 0, 0)
		)
	_p(root, _cyl(0.03, 0.1, 0.7), dark, Vector3(0, 0.98, 0.84), Vector3.ONE, Vector3(0.45, 0, 0))  # queue
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-0.42, 0.4]:
			_p(root, _cyl(0.07, 0.09, 0.42), coat, Vector3(sx * 0.2, 0.68, sz))  # haut de jambe
			_p(root, _cyl(0.05, 0.055, 0.42), coat, Vector3(sx * 0.2, 0.3, sz))  # bas de jambe
			_p(root, _cyl(0.07, 0.075, 0.1), "2a2220", Vector3(sx * 0.2, 0.05, sz))  # sabot
	if saddled:
		_p(root, s, "6a3a24", Vector3(0, 1.46, -0.02), Vector3(0.36, 0.1, 0.34))
		_p(root, _cyl(0.2, 0.2, 0.04), "8c2420", Vector3(0, 1.36, -0.02), Vector3(1.0, 1, 1.4))
		_p(root, _cyl(0.012, 0.012, 0.5), "3a2a1e", Vector3(0, 1.75, -0.9), Vector3.ONE, Vector3(1.2, 0, 0))
	return root
