class_name SettingsPanel
extends PanelContainer
## Paramètres : volumes, qualité graphique, et playlist des musiques
## (toutes en boucle, aléatoire ou un seul morceau ; cocher les morceaux voulus ; ▶ pour écouter tout de suite).

signal closed

const MODES := [["all", "Toutes en boucle"], ["shuffle", "Aléatoire"], ["one", "Un seul morceau"]]

var _mode_btn: Button
var _checks: Dictionary = {}
var _now: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(UiStyle.header("Paramètres", 30, _close))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	v.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)
	for k: Array in [["music", "Musique"], ["effects", "Effets et ambiances"]]:
		var l := Label.new()
		l.text = k[1]
		left.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Settings.get_value(k[0]))
		s.custom_minimum_size = Vector2(420, 40)
		s.value_changed.connect(_set_volume.bind(k[0]))
		left.add_child(s)
	var q := Button.new()
	q.text = "Qualité graphique : %s" % _qname(str(Settings.get_value("quality")))
	q.custom_minimum_size = Vector2(420, 54)
	q.pressed.connect(
		func() -> void:
			var order := ["low", "medium", "high"]
			var cur := str(Settings.get_value("quality"))
			Settings.set_value("quality", order[(order.find(cur) + 1) % order.size()])
			q.text = "Qualité graphique : %s" % _qname(str(Settings.get_value("quality")))
	)
	left.add_child(q)
	cols.add_child(_playlist_box())


func _playlist_box() -> VBoxContainer:
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.add_child(UiStyle.title_label("Playlist", 22))
	_mode_btn = Button.new()
	_mode_btn.custom_minimum_size = Vector2(440, 50)
	_mode_btn.pressed.connect(_cycle_mode)
	right.add_child(_mode_btn)
	var chosen: Array = Settings.get_value("playlist") if Settings.get_value("playlist") != null else []
	for t: Dictionary in Audio.tracks():
		var row := HBoxContainer.new()
		var c := CheckBox.new()
		c.text = "%s — %s" % [t["title"], t["author"]]
		c.button_pressed = chosen.is_empty() or chosen.has(t["id"])
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.toggled.connect(func(_on: bool) -> void: _save_playlist())
		row.add_child(c)
		_checks[t["id"]] = c
		var play := Button.new()
		play.text = "▶"
		play.custom_minimum_size = Vector2(52, 44)
		var id: String = t["id"]
		play.pressed.connect(
			func() -> void:
				Settings.set_value("music_track", id)
				Audio.play_track(id)
				_refresh()
		)
		row.add_child(play)
		right.add_child(row)
	_now = Label.new()
	_now.add_theme_color_override("font_color", UiStyle.TXT_D)
	_now.add_theme_font_size_override("font_size", 17)
	right.add_child(_now)
	_refresh()
	return right


func _cycle_mode() -> void:
	var keys := MODES.map(func(m: Array) -> String: return m[0])
	var i := keys.find(str(Settings.get_value("music_mode")))
	Settings.set_value("music_mode", keys[(i + 1) % keys.size()])
	if str(Settings.get_value("music_track")) == "":
		Settings.set_value("music_track", Audio.current_track)
	_refresh()


func _save_playlist() -> void:
	var on := []
	for id: String in _checks:
		if _checks[id].button_pressed:
			on.append(id)
	Settings.set_value("playlist", [] if on.size() == _checks.size() else on)


func _refresh() -> void:
	var m := str(Settings.get_value("music_mode"))
	for e: Array in MODES:
		if e[0] == m:
			_mode_btn.text = "Mode : %s" % e[1]
	var title := Audio.current_track
	for t: Dictionary in Audio.tracks():
		if t["id"] == title:
			title = t["title"]
	_now.text = "En cours : %s  ·  Licence CC BY 4.0 (incompetech.com)" % title


func _close() -> void:
	closed.emit()
	queue_free()


static func _qname(q: String) -> String:
	return {"low": "basse (sans ombres)", "medium": "moyenne", "high": "haute"}.get(q, q)


func _set_volume(v: float, key: String) -> void:
	Settings.set_value(key, v)
	Audio.apply_volumes()
