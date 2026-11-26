class_name LutinsView
extends Node3D
## Affiche les lutins de la colonie (un LutinModel chacun), lisse leurs déplacements, permet de les sélectionner.

var colony: Colony
var _models: Dictionary = {}  # id -> LutinModel
var _jobs: Dictionary = {}
var _time: float = 0.0
var _marker: MeshInstance3D
var selected_id: int = -1


func setup(c: Colony) -> void:
	colony = c
	colony.lutin_added.connect(_add)
	for l in colony.lutins:
		_add(l)
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
	_jobs[l.id] = l.job


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
		var job_view := "militia" if l.mobilized else l.job
		if _jobs[l.id] != job_view:
			m.build(job_view, _age_scale(l))
			_jobs[l.id] = job_view
		var target := l.pos
		var dir := target - m.position
		dir.y = 0.0
		if dir.length() > 0.01:
			m.rotation.y = lerp_angle(m.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 10.0))
		m.position = m.position.lerp(target, minf(1.0, delta * 12.0))
		var walking := l.state == Lutin.State.WALK
		m.animate(_time + l.id, walking, l.state == Lutin.State.SLEEP, l.state == Lutin.State.WORK)
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
