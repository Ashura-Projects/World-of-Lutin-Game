class_name HudTools
extends Node
## Outils d'écran : bulle de menu réduit, jauge d'étage déroulante (+ / − couche par couche, numéro affiché),
## boutons de caméra (pivoter, zoomer, incliner) en plus des gestes, et petit joystick pour déplacer la vue.
## Ces boutons sont « silencieux » (pas de clic sonore).

var hud: Hud
var root: Control
var camera: CameraController
var view: WorldView
var tool: BuildTool
var bubble: Button
var _bubble_panel: Control
var shortcuts: BuildShortcuts  # raccourcis sous la bulle de construction
var _floor_panel: PanelContainer
var _floor_slider: VSlider
var _floor_label: Label
var _floor_btn: Button
var _max_y: int = 64


func setup(h: Hud, cam: CameraController, v: WorldView, t: BuildTool) -> void:
	hud = h
	root = h.root
	camera = cam
	view = v
	tool = t
	_max_y = t.world.size.y
	_build_bubble()
	_build_floor()
	_build_camera_buttons()


# --- bulle : un menu réduit laisse une bulle sur le côté pour le rouvrir -------------------------
func _build_bubble() -> void:
	bubble = Button.new()
	bubble.position = Vector2(12, 300)
	bubble.custom_minimum_size = Vector2(0, 64)
	bubble.add_theme_font_size_override("font_size", 20)
	bubble.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD, 2, 30))
	bubble.visible = false
	bubble.pressed.connect(_reopen)
	root.add_child(bubble)


func show_bubble(panel: Control, label: String) -> void:
	_bubble_panel = panel
	bubble.text = "  ▸ %s  " % label
	bubble.visible = true
	if panel is BuildPanel:
		if shortcuts == null:
			shortcuts = BuildShortcuts.new()
			shortcuts.position = Vector2(12, 372)
			root.add_child(shortcuts)
			shortcuts.setup(panel)
		shortcuts.refresh()
		shortcuts.visible = true


func hide_bubble() -> void:
	bubble.visible = false
	_bubble_panel = null
	if shortcuts != null:
		shortcuts.visible = false


func _reopen() -> void:
	if _bubble_panel != null:
		_bubble_panel.visible = true
	bubble.visible = false
	if shortcuts != null:
		shortcuts.visible = false


# --- jauge d'étage dans un menu déroulant -------------------------------------------------------
func _build_floor() -> void:
	_floor_btn = Button.new()
	_floor_btn.text = "▤"
	_floor_btn.tooltip_text = "Étage"
	_floor_btn.position = Vector2(1472, 6)
	_floor_btn.custom_minimum_size = Vector2(56, 50)
	_floor_btn.pressed.connect(func() -> void: _floor_panel.visible = not _floor_panel.visible)
	_floor_btn.set_meta("silent", true)
	root.add_child(_floor_btn)
	_floor_panel = PanelContainer.new()
	_floor_panel.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 2, 8))
	_floor_panel.position = Vector2(1318, 66)
	_floor_panel.visible = false
	root.add_child(_floor_panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	_floor_panel.add_child(v)
	var title := UiStyle.title_label("Étage", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(130, 52)
	plus.pressed.connect(func() -> void: set_floor(_floor_slider.value + 1))
	plus.set_meta("silent", true)
	v.add_child(plus)
	_floor_slider = VSlider.new()
	_floor_slider.min_value = 1
	_floor_slider.max_value = _max_y
	_floor_slider.step = 1
	_floor_slider.value = _max_y
	_floor_slider.custom_minimum_size = Vector2(60, 300)
	_floor_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_floor_slider.value_changed.connect(_apply_floor)
	v.add_child(_floor_slider)
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(130, 52)
	minus.pressed.connect(func() -> void: set_floor(_floor_slider.value - 1))
	minus.set_meta("silent", true)
	v.add_child(minus)
	_floor_label = Label.new()
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_floor_label)
	var all := Button.new()
	all.text = "Tout voir"
	all.custom_minimum_size = Vector2(130, 48)
	all.pressed.connect(func() -> void: set_floor(_max_y))
	v.add_child(all)
	_apply_floor(_max_y)


func set_floor(v: float) -> void:
	_floor_slider.value = clampf(v, 1, _max_y)


func _apply_floor(v: float) -> void:
	var y := int(v) if int(v) < _max_y else 9999
	view.set_max_y(y)
	tool.max_y = y
	_floor_label.text = "Tout" if y == 9999 else "Couche %d / %d" % [int(v), _max_y]
	_floor_btn.text = "▤" if y == 9999 else "▤%d" % int(v)


# --- boutons de caméra ---------------------------------------------------------------------------
func _build_camera_buttons() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(1536, 66)
	col.add_theme_constant_override("separation", 8)
	root.add_child(col)
	for b: Array in [
		["⟲", "Pivoter à gauche", _rotate.bind(-1)],
		["⟳", "Pivoter à droite", _rotate.bind(1)],
		["+", "Zoomer", _zoom.bind(0.8)],
		["−", "Dézoomer", _zoom.bind(1.25)],
		["⤒", "Vue plus à plat", _tilt.bind(-1)],
		["⤓", "Vue plus du dessus", _tilt.bind(1)]
	]:
		var btn := Button.new()
		btn.text = b[0]
		btn.tooltip_text = b[1]
		btn.custom_minimum_size = Vector2(56, 56)
		btn.add_theme_stylebox_override("normal", UiStyle.box(Color(0.08, 0.06, 0.06, 0.75), UiStyle.GOLD_D, 2, 28))
		btn.pressed.connect(b[2])
		btn.set_meta("silent", true)
		col.add_child(btn)
	var joy := CameraJoystick.new()
	joy.camera = camera
	joy.position = Vector2(1468, 494)
	root.add_child(joy)


func _rotate(dir: int) -> void:
	camera.yaw += dir * PI / 8.0
	camera._apply()


func _zoom(f: float) -> void:
	camera.zoom(f)


func _tilt(dir: int) -> void:
	camera.pitch += dir * deg_to_rad(8.0)
	camera._apply()
