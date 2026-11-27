class_name SmokeView
extends Node3D
## Fumée qui sort du conduit de cheminée le plus haut (seulement près de la caméra).

var realm: Realm
var world: VoxelWorld
var focus := Vector3.ZERO
var _fx: Dictionary = {}  # case -> CPUParticles3D


func bind(r: Realm, w: VoxelWorld) -> void:
	realm = r
	world = w


func _process(_d: float) -> void:
	if realm == null or Engine.get_process_frames() % 30 != 0:
		return
	var want := {}
	var r := Graphics.view_distance()
	for c: Vector3i in realm.flue_cells:
		if world.get_block(c + Vector3i.UP) == 0 and Vector2(c.x - focus.x, c.z - focus.z).length() < r:
			want[c] = true
	for c: Vector3i in _fx.keys():
		if not want.has(c):
			_fx[c].queue_free()
			_fx.erase(c)
	for c: Vector3i in want:
		if not _fx.has(c):
			_fx[c] = _smoke(Vector3(c) + Vector3(0.5, 1.1, 0.5))


func _smoke(at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 3.5
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0.15, 0.1, 0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.9
	var m := SphereMesh.new()
	m.radius = 0.25
	m.height = 0.5
	m.radial_segments = 6
	m.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.55, 0.58, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	p.mesh = m
	p.position = at
	add_child(p)
	return p
