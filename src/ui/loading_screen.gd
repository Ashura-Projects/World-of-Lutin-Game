class_name LoadingScreen
extends CanvasLayer
## Écran de chargement d'une partie : fond d'accueil, barre de progression, phrases drôles (data/loading.json),
## puis bouton « Jouer » quand le monde est prêt.

signal play_pressed

var _bar: ProgressBar
var _msg: Label
var _play: Button
var _msgs: Array = []
var _t: float = 0.0
var _every: float = 2.6
var _i: int = 0
var progress: float = 0.0


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiStyle.make_theme()
	add_child(root)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/title_bg.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	# pleine largeur, calé en haut : le titre de l'image reste visible (le bas est rogné)
	bg.size = Vector2(1600, 1600.0 * bg.texture.get_height() / bg.texture.get_width())
	root.add_child(bg)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.85), UiStyle.GOLD, 2, 12))
	box.position = Vector2(400, 520)
	box.custom_minimum_size = Vector2(800, 0)
	root.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	_msg = UiStyle.title_label("", 24, UiStyle.PARCH)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_msg)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(760, 30)
	_bar.max_value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiStyle.GOLD
	fill.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", UiStyle.box(Color("141212"), UiStyle.GOLD_D, 1, 6))
	v.add_child(_bar)
	_play = Button.new()
	_play.text = "Jouer"
	_play.custom_minimum_size = Vector2(300, 64)
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.make_primary(_play)
	_play.visible = false
	_play.pressed.connect(
		func() -> void:
			play_pressed.emit()
			queue_free()
	)
	v.add_child(_play)
	var cfg := DataRegistry.get_table("loading")
	_msgs = cfg.get("messages", ["Chargement…"])
	_every = float(cfg.get("every_s", 2.6))
	_i = randi() % _msgs.size()
	_msg.text = _msgs[_i]


func set_progress(p: float) -> void:
	progress = maxf(progress, clampf(p, 0.0, 1.0))


func ready_to_play() -> void:
	progress = 1.0
	_play.visible = true
	_msg.text = "Le village vous attend !"


func is_ready() -> bool:
	return _play.visible


func _process(delta: float) -> void:
	_bar.value = lerpf(_bar.value, progress * 100.0, minf(1.0, delta * 6.0))
	if _play.visible:
		return
	_t += delta
	if _t >= _every:
		_t = 0.0
		_i = (_i + 1) % _msgs.size()
		_msg.text = _msgs[_i]
