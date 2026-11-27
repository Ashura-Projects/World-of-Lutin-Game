class_name SettingsPanel
extends PanelContainer
## Paramètres en onglets : Son, Musique (playlist), Graphismes (préréglages + réglages libres), Jeu.
## Croix ✕ en haut à droite pour fermer. Tout est appliqué tout de suite et gardé (Settings).

signal closed

const TABS := [["sound", "Son"], ["music", "Musique"], ["graphics", "Graphismes"], ["game", "Jeu"]]
const MODES := [["all", "Toutes en boucle"], ["shuffle", "Aléatoire"], ["one", "Un seul morceau"]]

var tab: String = "sound"
var _tabs: Dictionary = {}
var _body: VBoxContainer
var _checks: Dictionary = {}
var _now: Label
var _mode_btn: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1000, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	v.add_child(UiStyle.header("Paramètres", 30, _close))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for e: Array in TABS:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(200, 52)
		b.pressed.connect(show_tab.bind(str(e[0])))
		row.add_child(b)
		_tabs[e[0]] = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(980, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)
	show_tab("sound")


func show_tab(t: String) -> void:
	tab = t
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	for c in _body.get_children():
		c.queue_free()
	_checks.clear()
	match t:
		"sound":
			_slider("music", "Volume de la musique")
			_slider("effects", "Volume des effets et des ambiances")
		"music":
			_music_tab()
		"graphics":
			_graphics_tab()
		"game":
			_game_tab()


func _close() -> void:
	closed.emit()
	queue_free()


func _label(text: String, size: int = 20, color: Color = UiStyle.TXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_body.add_child(l)
	return l


func _slider(key: String, text: String) -> void:
	_label(text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(900, 44)
	s.value_changed.connect(
		func(v: float) -> void:
			Settings.set_value(key, v)
			Audio.apply_volumes()
	)
	_body.add_child(s)


## Bouton « Nom : valeur » qui passe à la valeur suivante à chaque toucher.
func _cycle(key: String, text: String, options: Array, names: Array, custom: bool = true) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(900, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var show := func() -> void:
		var i := _index(options, Settings.get_value(key))
		b.text = "%s : %s" % [text, names[i] if i >= 0 else str(Settings.get_value(key))]
	show.call()
	b.pressed.connect(
		func() -> void:
			var i := _index(options, Settings.get_value(key))
			Settings.values["quality"] = "custom" if custom else Settings.values["quality"]
			Settings.set_value(key, options[(i + 1) % options.size()])
			show.call()
			if custom:
				_refresh_presets()
	)
	_body.add_child(b)


## Position d'une valeur dans la liste (les nombres lus dans le JSON sont des flottants).
static func _index(options: Array, v: Variant) -> int:
	for i in options.size():
		var o: Variant = options[i]
		if (o is float or o is int) and (v is float or v is int):
			if is_equal_approx(float(o), float(v)):
				return i
		elif o == v:
			return i
	return -1


# --- Musique -------------------------------------------------------------------------------------
func _music_tab() -> void:
	_mode_btn = Button.new()
	_mode_btn.custom_minimum_size = Vector2(440, 50)
	_mode_btn.pressed.connect(_cycle_mode)
	_body.add_child(_mode_btn)
	var chosen: Array = Settings.get_value("playlist") if Settings.get_value("playlist") != null else []
	for t: Dictionary in Audio.tracks():
		var row := HBoxContainer.new()
		var c := CheckBox.new()
		c.text = "%s — %s" % [t["title"], t["author"]]
		c.button_pressed = (chosen.is_empty() and bool(t.get("playlist", true))) or chosen.has(t["id"])
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.toggled.connect(func(_on: bool) -> void: _save_playlist())
		row.add_child(c)
		_checks[t["id"]] = c
		var play := Button.new()
		play.text = "▶"
		play.custom_minimum_size = Vector2(56, 44)
		var id: String = t["id"]
		play.pressed.connect(
			func() -> void:
				Settings.set_value("music_track", id)
				Audio.play_track(id)
				_refresh_music()
		)
		row.add_child(play)
		_body.add_child(row)
	_now = _label("", 17, UiStyle.TXT_D)
	_refresh_music()


func _cycle_mode() -> void:
	var keys := MODES.map(func(m: Array) -> String: return m[0])
	var i := keys.find(str(Settings.get_value("music_mode")))
	Settings.set_value("music_mode", keys[(i + 1) % keys.size()])
	if str(Settings.get_value("music_track")) == "":
		Settings.set_value("music_track", Audio.current_track)
	_refresh_music()


func _save_playlist() -> void:
	var on := []
	for id: String in _checks:
		if _checks[id].button_pressed:
			on.append(id)
	Settings.set_value("playlist", [] if on.size() == _checks.size() else on)


func _refresh_music() -> void:
	var m := str(Settings.get_value("music_mode"))
	for e: Array in MODES:
		if e[0] == m:
			_mode_btn.text = "Mode : %s" % e[1]
	var title := Audio.current_track
	for t: Dictionary in Audio.tracks():
		if t["id"] == title:
			title = t["title"]
	_now.text = "En cours : %s  ·  Licence CC BY 4.0 (incompetech.com)" % title


# --- Graphismes ----------------------------------------------------------------------------------
var _preset_btns: Dictionary = {}


func _graphics_tab() -> void:
	var cfg := DataRegistry.get_table("graphics")
	_label("Préréglage", 22, UiStyle.GOLD)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_body.add_child(row)
	_preset_btns.clear()
	for p: Array in [
		["low", "Basse"], ["medium", "Moyenne"], ["high", "Haute"], ["ultra", "Ultra"], ["custom", "Perso."]
	]:
		var b := Button.new()
		b.text = p[1]
		b.custom_minimum_size = Vector2(170, 52)
		var id: String = p[0]
		b.pressed.connect(
			func() -> void:
				if id != "custom":
					Settings.apply_preset(id)
				else:
					Settings.set_value("quality", "custom")
				show_tab("graphics")
		)
		row.add_child(b)
		_preset_btns[id] = b
	_refresh_presets()
	_label("Réglages détaillés (passent en « Personnalisée »)", 22, UiStyle.GOLD)
	_cycle("shadows", "Ombres", ["off", "low", "high"], ["aucune", "légères", "fines"])
	var vd: Array = cfg.get("view_distances", [80, 128, 192])
	_cycle("view_distance", "Distance de vue", vd, vd.map(func(d: int) -> String: return "%d blocs" % d))
	var rs: Array = cfg.get("render_scales", [0.7, 1.0])
	_cycle("render_scale", "Résolution 3D", rs, rs.map(func(r: float) -> String: return "%d %%" % roundi(r * 100)))
	_cycle("aa", "Anticrénelage", ["off", "fxaa", "msaa2"], ["aucun", "FXAA (léger)", "MSAA ×2 (net)"])
	_cycle("fog", "Brume au loin", [true, false], ["oui", "non"])
	var caps: Array = cfg.get("fps_caps", [30, 60, 0])
	_cycle(
		"fps_cap",
		"Images par seconde max",
		caps,
		caps.map(func(c: int) -> String: return "illimité" if c == 0 else str(c))
	)
	var veg: Array = cfg.get("vegetation_levels", [0.5, 1.0])
	_cycle("vegetation", "Herbes et plantes", veg, veg.map(func(v: float) -> String: return "%d %%" % roundi(v * 100)))
	_cycle("show_fps", "Afficher les images par seconde", [false, true], ["non", "oui"], false)


func _refresh_presets() -> void:
	var q := str(Settings.get_value("quality"))
	for k: String in _preset_btns:
		_preset_btns[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == q else UiStyle.IRON_L))


# --- Jeu -----------------------------------------------------------------------------------------
func _game_tab() -> void:
	_cycle("tutorial", "Conseils du tutoriel", [true, false], ["oui", "non"], false)
	_cycle(
		"autosave_min",
		"Sauvegarde automatique",
		[2, 5, 10],
		["toutes les 2 min", "toutes les 5 min", "toutes les 10 min"],
		false
	)
	_cycle(
		"camera_speed",
		"Vitesse de la caméra",
		[0.6, 1.0, 1.5, 2.0],
		["lente", "normale", "rapide", "très rapide"],
		false
	)
	if bool(Settings.get_value("debug")):
		_label("Menu débug : activé (désactivable dans le menu Débug).", 18, UiStyle.TXT_D)
