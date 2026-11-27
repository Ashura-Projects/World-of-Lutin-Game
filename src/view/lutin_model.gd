class_name LutinModel
extends Node3D
## Modèle du lutin (variante A « Bouille », peau bleu sombre),
## construit à partir de primitives comme les planches validées.

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
var skin_override: String = ""  # lutins des autres factions (jaunes, rouges, vert clair)
var tunic_override: String = ""
var commander: bool = false  # commandant d'unité : bicorne à plume (1.4)
var _weapon_id: String = ""
var _weapon_pivot: Node3D


func build(job: String, age_scale: float = 1.0) -> void:
	_job = job
	for c in get_children():
		c.queue_free()
	var cfg := DataRegistry.get_table("outfits")
	var o: Dictionary = cfg.get("outfits", {}).get(job, cfg.get("outfits", {}).get("none", {}))
	var skin_hex := skin_override if skin_override != "" else str(cfg.get("skin", "466ca0"))
	var skin := mat(skin_hex, 0.55)
	var nose := mat(
		Color(skin_hex).darkened(0.2).to_html(false) if skin_override != "" else str(cfg.get("skin_shade", "365684")),
		0.5
	)
	var tunic_hex := str(o.get("tunic", "5a6a48"))
	var soldier := job in ["militia", "soldier"]
	if soldier and Faction.current != null:
		tunic_hex = Color(Faction.current.color1).darkened(0.25).to_html(false)  # uniforme aux couleurs de la faction
	if tunic_override != "":
		tunic_hex = tunic_override
	var tunic := mat(tunic_hex, 0.85)
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
	var belt := "784c2c"
	if soldier and Faction.current != null:
		belt = Color(Faction.current.color2).darkened(0.15).to_html(false)  # ceinture et écharpe : 2e couleur
		_part(
			body,
			_cyl(0.205, 0.205, 0.05, 14),
			mat(belt, 0.6, 0.2),
			Vector3(0, 0.36, 0),
			Vector3.ONE,
			Vector3(0, 0, 0.6)
		)
	_part(body, _cyl(0.19, 0.19, 0.03, 14), mat(belt, 0.7), Vector3(0, 0.27, 0))
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
	if commander:
		_commander_hat(head)
	else:
		_hat(str(o.get("hat", "pointu")), mat(str(o.get("hat_color", "8c4030")), 0.8), head)
	_weapon_id = ""
	_weapon_pivot = null


## Bicorne du commandant : feutre sombre, galon doré, cocarde et grande plume aux couleurs de la faction.
func _commander_hat(head: Vector3) -> void:
	var top := head.y + 0.17
	var felt := mat("1e1a24", 0.7)
	var gold := mat("d8b048", 0.35, 0.7)
	var plume := Faction.current.color1 if Faction.current != null else "c02a2a"
	_part(body, _sphere(0.27, 12), felt, Vector3(0, top - 0.02, 0), Vector3(1, 0.5, 1))
	_part(body, _cyl(0.0, 0.3, 0.22, 3), felt, Vector3(0, top + 0.06, 0), Vector3(1.9, 1, 0.55), Vector3(0, PI / 2, 0))
	_part(
		body, _cyl(0.31, 0.31, 0.03, 3), gold, Vector3(0, top - 0.04, 0), Vector3(1.9, 1, 0.58), Vector3(0, PI / 2, 0)
	)
	_part(body, _cyl(0.05, 0.05, 0.02, 10), gold, Vector3(0.12, top + 0.08, -0.15), Vector3.ONE, Vector3(PI / 2, 0, 0))
	_part(body, _sphere(0.09, 8), mat(plume, 0.8), Vector3(-0.05, top + 0.25, 0.02), Vector3(0.6, 1.8, 0.6))
	_part(body, _sphere(0.06, 8), mat("f0ece0", 0.8), Vector3(-0.05, top + 0.38, 0.03), Vector3(0.6, 1.4, 0.6))


## Arme tenue (fusil, lance, épée) : posée sur l'épaule en marche, en joue / en pique à l'arrêt (transition douce).
func set_weapon(id: String) -> void:
	if id == _weapon_id and (_weapon_pivot != null or id == ""):
		return
	_weapon_id = id
	if _weapon_pivot != null:
		_weapon_pivot.queue_free()
		_weapon_pivot = null
	if id == "" or body == null:
		return
	_weapon_pivot = Node3D.new()
	_weapon_pivot.position = Vector3(0.22, 0.42, 0.0)
	body.add_child(_weapon_pivot)
	var wood := mat("6a4428", 0.8)
	var iron := mat("8a8e96", 0.3, 0.8)
	match id:
		"flintlock":
			_part(_weapon_pivot, _cyl(0.035, 0.045, 0.32, 6), wood, Vector3(0, -0.1, 0))
			_part(_weapon_pivot, _cyl(0.018, 0.018, 0.5, 6), iron, Vector3(0, 0.3, 0))
			_part(_weapon_pivot, _cyl(0.01, 0.01, 0.06, 4), iron, Vector3(0, 0.57, 0))
		"spear":
			_part(_weapon_pivot, _cyl(0.018, 0.018, 1.4, 6), wood, Vector3(0, 0.35, 0))
			_part(_weapon_pivot, _cyl(0.0, 0.045, 0.16, 4), iron, Vector3(0, 1.12, 0))
		_:
			_part(_weapon_pivot, _cyl(0.012, 0.03, 0.42, 4), iron, Vector3(0, 0.24, 0))
			_part(_weapon_pivot, _cyl(0.06, 0.06, 0.02, 6), mat("c49e54", 0.4, 0.6), Vector3(0, 0.02, 0))
			_part(_weapon_pivot, _cyl(0.02, 0.02, 0.1, 6), wood, Vector3(0, -0.05, 0))


## Posture de l'arme : "march" (fusil à l'épaule, lance haute), "ready" (fusil en joue, lance en pique), "rest".
func pose_weapon(stance: String, delta: float) -> void:
	if _weapon_pivot == null:
		return
	var rot := Vector3(0.12, 0, 0.18)
	var pos := Vector3(0.22, 0.42, 0.04)
	var arm := -0.4
	if stance == "ready":
		match _weapon_id:
			"flintlock":
				rot = Vector3(-PI / 2.0, 0, 0)
				pos = Vector3(0.12, 0.55, -0.05)
				arm = -1.45
			"spear":
				rot = Vector3(-PI / 2.0 + 0.22, 0, 0)
				pos = Vector3(0.2, 0.42, 0.2)
				arm = -1.1
			_:
				rot = Vector3(-0.9, 0, 0)
				arm = -1.0
	elif _weapon_id == "spear":
		rot = Vector3(0.05, 0, 0.05)
		pos = Vector3(0.24, 0.3, -0.02)
	var k := minf(1.0, delta * 6.0)
	_weapon_pivot.rotation = _weapon_pivot.rotation.lerp(rot, k)
	_weapon_pivot.position = _weapon_pivot.position.lerp(pos, k)
	if stance == "ready":
		arm_r.rotation.x = lerpf(arm_r.rotation.x, arm, k)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, arm * 0.9, k)
		arm_l.rotation.z = lerpf(arm_l.rotation.z, -0.3, k)
	else:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, arm, k)


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


## L'outil n'apparaît que pendant l'action (validé) : manche + tête, à l'échelle exagérée du style.
func show_tool(on: bool) -> void:
	if tool_slot == null:
		return
	if not on:
		for c in tool_slot.get_children():
			c.queue_free()
		return
	if tool_slot.get_child_count() > 0:
		return
	var tool_id = DataRegistry.find("jobs", "jobs", _job).get("tool")
	if tool_id == null:
		return
	var wood := mat("80583a", 0.8)
	var iron := mat("a0a4ac", 0.35, 0.7)
	var long := ["flintlock", "fishing_rod", "shovel", "hoe"].has(tool_id)
	_part(
		tool_slot,
		_cyl(0.02, 0.02, 0.75 if long else 0.5),
		wood,
		Vector3(0, -0.05, -0.1),
		Vector3.ONE,
		Vector3(PI / 2.4, 0, 0)
	)
	var head := BoxMesh.new()
	match str(tool_id):
		"axe":
			head.size = Vector3(0.04, 0.12, 0.16)
		"pickaxe":
			head.size = Vector3(0.04, 0.05, 0.4)
		"hammer", "tongs":
			head.size = Vector3(0.08, 0.08, 0.16)
		"basket":
			head.size = Vector3(0.2, 0.14, 0.2)
		_:
			head.size = Vector3(0.05, 0.05, 0.1)
	_part(tool_slot, head, iron if tool_id != "basket" else mat("b08448", 0.9), Vector3(0, 0.12, -0.32))


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
