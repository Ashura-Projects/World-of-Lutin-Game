class_name LutinsView
extends Node3D
## Affiche les lutins de la colonie (un LutinModel chacun), lisse leurs déplacements, permet de les sélectionner.

var colony: Colony
var _models: Dictionary = {}  # id -> LutinModel
var _jobs: Dictionary = {}
var _time: float = 0.0
var _marker: MeshInstance3D
var _zzz: Dictionary = {}  # id lutin -> Label3D « zZz » au-dessus des dormeurs
var selected_id: int = -1


func setup(c: Colony) -> void:
	colony = c
	colony.lutin_added.connect(_add)
	colony.lutin_removed.connect(
		func(id: int) -> void:
			if _models.has(id):
				_models[id].queue_free()
				_models.erase(id)
			if _zzz.has(id):
				_zzz[id].queue_free()
				_zzz.erase(id)
	)
	for l in colony.lutins:
		_add(l)
	# nouvelles couleurs de faction : on rhabille les soldats (le modèle est reconstruit au prochain cadre)
	EventBus.faction_changed.connect(
		func() -> void:
			for id: int in _jobs:
				_jobs[id] = ""
	)
	_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.38
	ring.outer_radius = 0.46
	_marker.mesh = ring
	_marker.material_override = LutinModel.mat("c49e54", 0.4, 0.0, 1.5)
	_marker.visible = false
	add_child(_marker)


func _add(l: Lutin) -> void:
	var m := LutinModel.new()
	add_child(m)
	m.build(l.job, _age_scale(l))
	m.position = l.pos
	_models[l.id] = m
	_jobs[l.id] = l.job + ":" + l.age_stage()


func _age_scale(l: Lutin) -> float:
	var scale := 1.0
	for a: Dictionary in DataRegistry.get_table("population").get("ages", []):
		if l.age_days >= int(a["from_day"]):
			scale = {"baby": 0.5, "child": 0.72, "adult": 1.0, "elder": 0.95}.get(a["id"], 1.0)
	return scale


func _process(delta: float) -> void:
	_time += delta
	for l in colony.lutins:
		var m: LutinModel = _models.get(l.id)
		if m == null:
			continue
		var job_view := ("militia" if l.mobilized or l.job == "soldier" else l.job) + ":" + l.age_stage()
		if _jobs[l.id] != job_view:
			m.build(job_view.split(":")[0], _age_scale(l))
			_jobs[l.id] = job_view
		var target := l.pos
		var dir := target - m.position
		dir.y = 0.0
		if dir.length() > 0.01:
			m.rotation.y = lerp_angle(m.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 10.0))
		m.position = m.position.lerp(target, minf(1.0, delta * 12.0))
		var walking := l.state == Lutin.State.WALK
		var working := l.state == Lutin.State.WORK
		m.show_tool(working)
		m.animate(_time + l.id, walking, l.state == Lutin.State.SLEEP, working)
		_sleep_label(l, m)
		_scout_tent(l)
		if l.id == selected_id:
			_marker.visible = true
			_marker.position = m.position + Vector3(0, 0.05, 0)


## Lutin le plus proche du point touché à l'écran (dans un rayon de 60 px).
func pick(cam: Camera3D, screen: Vector2) -> Lutin:
	var best: Lutin = null
	var best_d := 60.0
	for l in colony.lutins:
		var p := l.pos + Vector3(0, 0.5, 0)
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(screen)
		if d < best_d:
			best_d = d
			best = l
	selected_id = best.id if best else -1
	_marker.visible = best != null
	return best


## Petits « zZz » qui montent au-dessus d'un lutin endormi.
func _sleep_label(l: Lutin, m: LutinModel) -> void:
	var asleep := l.state == Lutin.State.SLEEP
	var z: Label3D = _zzz.get(l.id)
	if not asleep:
		if z != null:
			z.visible = false
		return
	if z == null:
		z = Label3D.new()
		z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		z.no_depth_test = false
		z.font_size = 48
		z.pixel_size = 0.006
		z.outline_size = 10
		z.modulate = Color("dfe8ff")
		z.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)
		add_child(z)
		_zzz[l.id] = z
	z.visible = true
	var t := fmod(_time * 0.8 + l.id * 0.37, 1.0)
	z.text = ["z", "zZ", "zZz", "zZzZ"][int(t * 4.0) % 4]
	z.position = m.position + Vector3(0.15, 1.05 + t * 0.35, 0)
	z.modulate.a = 1.0 - t * 0.6


var _tents: Dictionary = {}  # id lutin -> petite tente d'éclaireur (la nuit)


func _scout_tent(l: Lutin) -> void:
	var camp: bool = l.order.has("camp")
	var t: Node3D = _tents.get(l.id)
	if not camp:
		if t != null:
			t.queue_free()
			_tents.erase(l.id)
		return
	if t == null:
		t = MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(1.0, 0.8, 1.2)
		t.mesh = pm
		t.material_override = LutinModel.mat("7a6a4a", 0.95)
		t.position = Vector3(l.order["camp"]) + Vector3(1.2, 0.4, 0.5)
		add_child(t)
		_tents[l.id] = t
