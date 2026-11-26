class_name CameraController
extends Node3D
## Caméra « stratégie » : cible au sol, lacet, tangage, distance. Gestes tactiles + souris (tests sur PC).

signal tapped(screen_pos: Vector2)

var target := Vector3.ZERO
var yaw: float = 0.6
var pitch: float = deg_to_rad(50.0)
var distance: float = 40.0
var bounds := AABB(Vector3.ZERO, Vector3(256, 64, 256))
var pan_enabled: bool = true  # en mode construction, 1 doigt = construire
var cam: Camera3D
var _cfg: Dictionary
var _touches: Dictionary = {}
var _last_two: Array = []
var _drag_moved: float = 0.0


func _ready() -> void:
	_cfg = DataRegistry.get_table("camera")
	cam = Camera3D.new()
	cam.fov = float(_cfg.get("fov", 45))
	cam.far = 600.0
	add_child(cam)
	distance = float(_cfg.get("default_distance", 40))
	pitch = deg_to_rad(float(_cfg.get("default_pitch_deg", 50)))
	_apply()


func focus(p: Vector3) -> void:
	target = p
	_apply()


func _apply() -> void:
	var d: Array = _cfg.get("distance", [6, 140])
	var pr: Array = _cfg.get("pitch_deg", [25, 85])
	distance = clampf(distance, float(d[0]), float(d[1]))
	pitch = clampf(pitch, deg_to_rad(float(pr[0])), deg_to_rad(float(pr[1])))
	target.x = clampf(target.x, bounds.position.x, bounds.end.x)
	target.z = clampf(target.z, bounds.position.z, bounds.end.z)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	cam.global_position = target + offset
	cam.look_at(target, Vector3.UP)


func pan_screen(delta: Vector2) -> void:
	var k := distance * 0.0022 * float(_cfg.get("pan_speed", 1.0))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	target -= (right * delta.x + fwd * delta.y) * k
	_apply()


func zoom(factor: float) -> void:
	distance *= factor
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			_drag_moved = 0.0
		else:
			if _touches.size() == 1 and _drag_moved < 12.0:
				tapped.emit(event.position)
			_touches.erase(event.index)
			_last_two = []
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		_drag_moved += event.relative.length()
		if _touches.size() == 1 and pan_enabled:
			pan_screen(event.relative)
		elif _touches.size() >= 2:
			_two_finger()
	elif event is InputEventMouseButton and event.pressed:
		var f := float(_cfg.get("zoom_wheel_factor", 1.12))
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom(1.0 / f)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom(f)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw -= event.relative.x * 0.006
		pitch += event.relative.y * 0.004
		_apply()


func _two_finger() -> void:
	var pts: Array = _touches.values().slice(0, 2)
	if _last_two.size() == 2:
		var a0: Vector2 = _last_two[0]
		var b0: Vector2 = _last_two[1]
		var a1: Vector2 = pts[0]
		var b1: Vector2 = pts[1]
		var d0 := a0.distance_to(b0)
		var d1 := a1.distance_to(b1)
		if d0 > 1.0 and d1 > 1.0:
			distance *= d0 / d1  # pincer
		var ang0 := (b0 - a0).angle()
		var ang1 := (b1 - a1).angle()
		yaw -= wrapf(ang1 - ang0, -PI, PI) * float(_cfg.get("rotate_speed", 1.0))
		# glisser à 2 doigts : déplacer la caméra (même en mode construction) ; l'inclinaison passe par les boutons
		var mid := ((a1 + b1) - (a0 + b0)) * 0.5
		pan_screen(mid)
		_apply()
	_last_two = pts
