class_name OrcModel
extends RefCounted
## Orc « Bedaine à crête » (STYLE-VALIDE §4, variante B validée) : rouge, ventre clair, museau, crête noire,
## épaulière de récupération, couperet. Variantes : archer (arc) et brute (plus gros, casque).
## Repère : avant = -Z (comme les lutins).

const SKIN := "d65442"
const DARK := "a02c28"
const LEATHER := "603e28"


static func _p(
	root: Node3D,
	mesh: Mesh,
	color: String,
	pos: Vector3,
	sc: Vector3 = Vector3.ONE,
	rot: Vector3 = Vector3.ZERO,
	metal: float = 0.0
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = LutinModel.mat(color, 0.7, metal)
	mi.position = pos
	mi.scale = sc
	mi.rotation = rot
	root.add_child(mi)
	return mi


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


static func _cyl(rt: float, rb: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 8
	return c


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.scale = Vector3.ONE * (1.25 if kind == "orc_brute" else 0.9)
	root.add_child(body)
	for s: float in [-1.0, 1.0]:
		_p(body, _sph(1.0), DARK, Vector3(s * 0.18, 0.08, -0.04), Vector3(0.14, 0.09, 0.18))
		_p(body, _cyl(0.09, 0.09, 0.2), SKIN, Vector3(s * 0.18, 0.2, 0))
	_p(body, _sph(1.0), SKIN, Vector3(0, 0.6, 0), Vector3(0.44, 0.5, 0.4))
	_p(body, _cyl(0.4, 0.43, 0.24), LEATHER, Vector3(0, 0.4, 0))
	_p(body, _sph(1.0), "e87864", Vector3(0, 0.66, -0.12), Vector3(0.3, 0.32, 0.3))
	_p(body, _sph(1.0), "965632", Vector3(-0.42, 0.92, 0), Vector3(0.2, 0.12, 0.2), Vector3.ZERO, 0.5)
	for s: float in [-1.0, 1.0]:
		_p(body, _cyl(0.09, 0.09, 0.36), SKIN, Vector3(s * 0.48, 0.66, -0.03), Vector3.ONE, Vector3(0, 0, s * 0.25))
		_p(body, _sph(0.1), SKIN, Vector3(s * 0.53, 0.46, -0.06))
	var hz := 1.12
	_p(body, _sph(1.0), SKIN, Vector3(0, hz, -0.06), Vector3(0.25, 0.24, 0.23))
	_p(body, _sph(1.0), "b43832", Vector3(0, hz - 0.03, -0.27), Vector3(0.09, 0.06, 0.06))
	for s: float in [-1.0, 1.0]:
		_p(body, _cyl(0.0, 0.03, 0.1), "f6ecce", Vector3(s * 0.1, hz - 0.12, -0.24), Vector3.ONE, Vector3(-0.3, 0, 0))
		_p(body, _cyl(0.0, 0.05, 0.2), SKIN, Vector3(s * 0.27, hz + 0.08, -0.02), Vector3.ONE, Vector3(0, 0, -s * 1.0))
		_p(body, _sph(0.05), "ffd63c", Vector3(s * 0.1, hz + 0.06, -0.23))
	if kind == "orc_brute":
		_p(body, _sph(1.0), "6e7078", Vector3(0, hz + 0.12, -0.04), Vector3(0.28, 0.16, 0.27), Vector3.ZERO, 0.6)
	else:
		for i in 6:
			_p(
				body,
				_cyl(0.0, 0.04, 0.16),
				"281e22",
				Vector3(0, hz + 0.24 - absf(i - 2.5) * 0.015, -0.14 + i * 0.06),
				Vector3.ONE,
				Vector3(0.3 - i * 0.12, 0, 0)
			)
	if kind == "orc_archer":
		_p(body, _cyl(0.015, 0.015, 0.9), "785030", Vector3(0.56, 0.7, -0.15), Vector3.ONE, Vector3(0.1, 0, 0))
		_p(body, _cyl(0.004, 0.004, 0.85), "e0d8c0", Vector3(0.52, 0.7, -0.12))
	else:
		_p(body, _cyl(0.03, 0.03, 0.26), "5a3c28", Vector3(0.56, 0.5, -0.12), Vector3.ONE, Vector3(-0.5, 0, 0))
		_p(
			body,
			_box(Vector3(0.03, 0.2, 0.3)),
			"aaacb0",
			Vector3(0.56, 0.68, -0.3),
			Vector3.ONE,
			Vector3(-0.5, 0, 0),
			0.7
		)
	return root


## Camp : tentes de peaux, totem à crânes, feu.
static func camp() -> Node3D:
	var r := Node3D.new()
	for i in 3:
		var a := i * TAU / 3.0 + 0.4
		var tent := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(2.0, 1.6, 2.2)
		tent.mesh = pm
		tent.material_override = LutinModel.mat("6a4a36", 0.95)
		tent.position = Vector3(cos(a) * 3.5, 0.8, sin(a) * 3.5)
		tent.rotation.y = -a
		r.add_child(tent)
	_p(r, _cyl(0.12, 0.14, 2.6), "4a3426", Vector3(0, 1.3, 0))
	for y: float in [1.9, 2.3]:
		_p(r, _sph(0.16), "e8e0c8", Vector3(0, y, -0.12))
	_p(r, _box(Vector3(1.0, 0.5, 0.06)), "8c2420", Vector3(0, 2.55, 0))
	_p(r, _sph(0.3), "ff8a30", Vector3(1.6, 0.25, 1.6))
	var light := OmniLight3D.new()
	light.light_color = Color("ff9040")
	light.omni_range = 8.0
	light.position = Vector3(1.6, 1.0, 1.6)
	r.add_child(light)
	return r
