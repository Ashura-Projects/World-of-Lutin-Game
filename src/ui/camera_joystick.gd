class_name CameraJoystick
extends Control
## Petit joystick à l'écran : glisser le pouce déplace la caméra (pratique pendant la construction ou la récolte).

const RADIUS := 62.0
const KNOB := 30.0

var camera: CameraController
var speed: float = 900.0  # pixels d'écran « glissés » par seconde à fond
var _vec := Vector2.ZERO
var _active: bool = false
var _index: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == _index:
			_release()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _index:
		_update(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_update(event.position)
		else:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _active and _index == -1:
		_update(event.position)


func _update(p: Vector2) -> void:
	var c := size * 0.5
	_vec = (p - c).limit_length(RADIUS) / RADIUS
	queue_redraw()


func _release() -> void:
	_active = false
	_index = -1
	_vec = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	if camera != null and _vec.length() > 0.08:
		# pousser vers le haut = avancer dans la direction regardée
		camera.pan_screen(-_vec * speed * delta)


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, RADIUS, Color(0.08, 0.06, 0.06, 0.6))
	draw_arc(c, RADIUS, 0, TAU, 48, UiStyle.GOLD_D, 2.0, true)
	draw_circle(c + _vec * (RADIUS - KNOB * 0.6), KNOB, UiStyle.BLOOD if _active else UiStyle.IRON_L)
	draw_arc(c + _vec * (RADIUS - KNOB * 0.6), KNOB, 0, TAU, 32, UiStyle.GOLD, 2.0, true)
