class_name LutinModel
extends Node3D
## Modèle du lutin (variante A « Bouille », peau bleu sombre) construit à partir de primitives, comme les planches validées.

var body: Node3D
var arm_r: MeshInstance3D
var arm_l: MeshInstance3D
var leg_r: MeshInstance3D
var leg_l: MeshInstance3D
var tool_slot: Node3D
var _job: String = ""
static var _mats: Dictionary = {}


static func mat(hex: String, rough: float = 0.8, metal: float = 0.0, emit: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%s_%s_%s" % [hex, rough, metal, emit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


static func _sphere(r: float, segs: int = 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = segs / 2
	return s


static func _cyl(r_top: float, r_bot: float, h: float, segs: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


func _part(
	parent: Node3D, mesh: Mesh, m: Material, p: Vector3, s: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = p
	mi.scale = s
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Construit le lutin (le modèle regarde vers -Z, hauteur ≈ 1 bloc avec le bonnet). age_scale : bébé 0.5 … adulte 1.
func build(job: String, age_scale: float = 1.0) -> void:
	_job = job
	for c in get_children():
		c.queue_free()
	var cfg := DataRegistry.get_table("outfits")
	var o: Dictionary = cfg.get("outfits", {}).get(job, cfg.get("outfits", {}).get("none", {}))
	var skin := mat(str(cfg.get("skin", "466ca0")), 0.55)
	var nose := mat(str(cfg.get("skin_shade", "365684")), 0.5)
	var tunic := mat(str(o.get("tunic", "5a6a48")), 0.85)
	var s := 0.82 * age_scale
	body = Node3D.new()
	body.scale = Vector3.ONE * s
	add_child(body)
	var boot := mat("5c3a24", 0.7)
	leg_r = _part(body, _cyl(0.05, 0.05, 0.14), mat("464052", 0.9), Vector3(-0.08, 0.11, 0))
	leg_l = _part(body, _cyl(0.05, 0.05, 0.14), mat("464052", 0.9), Vector3(0.08, 0.11, 0))
	_part(leg_r, _sphere(0.07, 8), boot, Vector3(0, -0.07, -0.025), Vector3(1, 0.7, 1.35))
	_part(leg_l, _sphere(0.07, 8), boot, Vector3(0, -0.07, -0.025), Vector3(1, 0.7, 1.35))
	_part(body, _sphere(0.2, 12), tunic, Vector3(0, 0.32, 0), Vector3(1, 1.2, 0.9))
	_part(body, _cyl(0.19, 0.19, 0.03, 14), mat("784c2c", 0.7), Vector3(0, 0.27, 0))
	arm_r = _part(body, _cyl(0.045, 0.045, 0.18), tunic, Vector3(-0.21, 0.36, 0), Vector3.ONE, Vector3(0, 0, -0.35))
	arm_l = _part(body, _cyl(0.045, 0.045, 0.18), tunic, Vector3(0.21, 0.36, 0), Vector3.ONE, Vector3(0, 0, 0.35))
	_part(arm_r, _sphere(0.055, 8), skin, Vector3(0, -0.11, 0))
	_part(arm_l, _sphere(0.055, 8), skin, Vector3(0, -0.11, 0))
	tool_slot = Node3D.new()
	tool_slot.position = Vector3(0, -0.11, 0)
	arm_r.add_child(tool_slot)
	var head := Vector3(0, 0.66, 0)
	_part(body, _sphere(0.28, 14), skin, head)
	_part(body, _sphere(0.073, 8), nose, head + Vector3(0, -0.02, -0.275))
	for sx: float in [-1.0, 1.0]:
		_part(
			body,
			_cyl(0.0, 0.056, 0.2, 6),
			skin,
			head + Vector3(sx * 0.29, 0.02, 0.02),
			Vector3.ONE,
			Vector3(0, 0, -sx * 1.25)
		)
		_part(
			body, _sphere(0.042, 8), mat("181622", 0.2), head + Vector3(sx * 0.1, 0.035, -0.25), Vector3(1, 1.38, 0.6)
		)
		_part(body, _sphere(0.013, 6), mat("fafaf6", 0.2, 0.0, 0.6), head + Vector3(sx * 0.1 + 0.012, 0.06, -0.272))
		_part(
			body, _sphere(0.04, 6), mat("c47890", 0.8), head + Vector3(sx * 0.16, -0.04, -0.2), Vector3(1.25, 0.75, 0.5)
		)
	_hat(str(o.get("hat", "pointu")), mat(str(o.get("hat_color", "8c4030")), 0.8), head)


func _hat(kind: String, m: Material, head: Vector3) -> void:
	var top := head.y + 0.17
	match kind:
		"pointu", "pointu_haut":
			var h := 0.38 if kind == "pointu" else 0.48
			_part(
				body,
				_cyl(0.0, 0.27, h, 12),
				m,
				Vector3(0, top + h / 2.0 - 0.05, 0.04),
				Vector3.ONE,
				Vector3(0.22, 0, 0)
			)
			_part(body, _cyl(0.27, 0.27, 0.06, 14), m, Vector3(0, top - 0.04, 0))
			_part(body, _sphere(0.05, 6), mat("e6dcc8", 0.9), Vector3(0, top + h - 0.09, 0.12))
		"capuche":
			_part(body, _sphere(0.31, 12), m, head + Vector3(0, 0.05, 0.08))
		"casque", "chapeau_fer", "heaume":
			_part(body, _sphere(0.28, 12), m, Vector3(0, top - 0.04, 0), Vector3(1, 0.62, 1))
			if kind == "chapeau_fer":
				_part(body, _cyl(0.38, 0.38, 0.025, 16), m, Vector3(0, top - 0.06, 0))
			if kind == "casque":
				_part(
					body,
					_cyl(0.05, 0.05, 0.05, 8),
					mat("ffd278", 0.3, 0.0, 3.0),
					Vector3(0, top, -0.27),
					Vector3.ONE,
					Vector3(PI / 2, 0, 0)
				)
		"large":
			_part(body, _cyl(0.47, 0.47, 0.03, 16), m, Vector3(0, top, 0))
			_part(body, _cyl(0.17, 0.21, 0.16, 12), m, Vector3(0, top + 0.08, 0))
		"beret", "calotte":
			_part(body, _sphere(0.3, 12), m, Vector3(0.03, top, 0), Vector3(1, 0.32, 1))
		"toque":
			_part(body, _cyl(0.2, 0.2, 0.22, 12), m, Vector3(0, top + 0.1, 0))
			_part(body, _sphere(0.25, 12), m, Vector3(0, top + 0.24, 0), Vector3(1, 0.4, 1))
		"bandeau":
			_part(body, _cyl(0.27, 0.27, 0.05, 16), m, Vector3(0, head.y + 0.12, 0))


## Animation simple : marche (jambes et bras qui balancent), sommeil (couché), travail (bras qui frappe).
func animate(t: float, walking: bool, sleeping: bool, working: bool) -> void:
	if body == null:
		return
	var sw := sin(t * 10.0) * 0.5 if walking else 0.0
	leg_r.rotation.x = sw
	leg_l.rotation.x = -sw
	arm_l.rotation.x = -sw * 0.6
	arm_r.rotation.x = sw * 0.6
	if working:
		arm_r.rotation.x = -1.2 + sin(t * 7.0) * 0.9
	body.rotation.z = PI / 2.0 if sleeping else 0.0
	body.position.y = 0.15 if sleeping else absf(sin(t * 10.0)) * 0.03 * float(walking)
