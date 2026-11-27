class_name CinematicPlayer
extends Control
## Lecteur de cinématique dessinée (1.4.1) : plein écran, fond noir, vidéo Ogg Theora (assets/cinematics).
## Un double toucher (ou double clic) la passe ; à la fin (ou passée), « finished » est émis et le lecteur disparaît.
## La musique du jeu est coupée pendant la cinématique (la vidéo a sa propre musique).

signal finished

const DOUBLE_TAP_MS := 400

var _video: VideoStreamPlayer
var _hint: Label
var _last_tap: int = -10000
var _done: bool = false


## Joue une cinématique ; false si le fichier n'existe pas (rien n'est affiché).
func play(path: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	top_level = true  # plein écran, quelle que soit la taille du parent
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_video = VideoStreamPlayer.new()
	_video.stream = load(path)
	_video.expand = true
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.volume_db = linear_to_db(maxf(0.05, float(Settings.get_value("music"))))
	add_child(_video)
	_video.finished.connect(_end)
	_hint = Label.new()
	_hint.text = "Toucher deux fois pour passer"
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	_hint.position = Vector2(1300, 680)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	Audio.pause_music(true)
	_video.play()
	return true


func _gui_input(event: InputEvent) -> void:
	var tap: bool = (
		(event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	)
	if not tap:
		return
	var now := Time.get_ticks_msec()
	if now - _last_tap < DOUBLE_TAP_MS:
		_end()
	_last_tap = now
	accept_event()


func _process(_d: float) -> void:
	if _hint != null and _video != null:
		_hint.modulate.a = clampf(1.0 - _video.stream_position / 6.0, 0.0, 1.0)  # l'astuce s'efface après 6 s


func _end() -> void:
	if _done:
		return
	_done = true
	if _video != null:
		_video.stop()
	Audio.pause_music(false)
	finished.emit()
	queue_free()
