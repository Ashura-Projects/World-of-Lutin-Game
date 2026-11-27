extends Control
## Menu principal (STYLE-VALIDE §7) : Continuer, Nouvelle partie (configuration), Charger, Paramètres, Crédits, Quitter.

const GAME_SCENE := "res://src/game/game.tscn"

var _setup_panel: NewGamePanel


func _ready() -> void:
	theme = UiStyle.make_theme()
	GameSetup.reset_defaults()
	_build()
	Audio.start_music()


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/title_bg.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	# pleine largeur, calé en haut : le titre de l'image reste visible (le bas est rogné)
	bg.size = Vector2(1600, 1600.0 * bg.texture.get_height() / bg.texture.get_width())
	add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(0.05, 0.04, 0.04, 0.12)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	# le titre est dans l'image de fond (fournie par Ashura) : menu dans un cadre sombre à gauche
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.78), UiStyle.GOLD, 2, 12))
	frame.position = Vector2(60, 190)
	add_child(frame)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(420, 0)
	col.add_theme_constant_override("separation", 12)
	frame.add_child(col)

	var cont := _menu_button(col, "Continuer", _on_continue)
	cont.disabled = not SaveManager.has_save("auto")
	if not cont.disabled:
		UiStyle.make_primary(cont)
	var newb := _menu_button(col, "Nouvelle partie", _on_new_game)
	if cont.disabled:
		UiStyle.make_primary(newb)
	_menu_button(col, "Paramètres", func() -> void: _popup(SettingsPanel.new()))
	_menu_button(col, "Crédits", func() -> void: _popup(CreditsPanel.new()))
	_menu_button(col, "Quitter", func() -> void: get_tree().quit())

	var ver := Label.new()
	ver.text = "v%s · projet d'Ashura" % ProjectSettings.get_setting("application/config/version", "1.0.0")
	ver.add_theme_color_override("font_color", UiStyle.TXT_D)
	ver.add_theme_font_size_override("font_size", 16)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(16, -30)
	add_child(ver)
	_build_setup_panel()


func _menu_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 62)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_setup_panel() -> void:
	_setup_panel = NewGamePanel.new()
	_setup_panel.position = Vector2(560, 80)
	_setup_panel.visible = false
	add_child(_setup_panel)
	_setup_panel.start_requested.connect(_start_game)
	_setup_panel.faction_requested.connect(_open_faction)


func _open_faction() -> void:
	var ed := FactionEditor.new()
	ed.setup(Faction.new(GameSetup.faction))
	ed.position = Vector2(300, 60)
	add_child(ed)
	ed.done.connect(
		func(f: Faction) -> void:
			GameSetup.faction = f.to_dict()
			ed.queue_free()
	)


func _small_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(64, 56)
	b.pressed.connect(cb)
	return b


func _on_new_game() -> void:
	_setup_panel.visible = not _setup_panel.visible


func _on_continue() -> void:
	GameSetup.load_slot = "auto"
	get_tree().change_scene_to_file(GAME_SCENE)


func _start_game() -> void:
	GameSetup.load_slot = ""
	get_tree().change_scene_to_file(GAME_SCENE)


func _popup(p: Control) -> void:
	p.position = Vector2(560, 120)
	add_child(p)


func _toast(text: String) -> void:
	EventBus.alert.emit("info", text)
	var l := Label.new()
	l.text = text
	l.position = Vector2(600, 640)
	add_child(l)
	get_tree().create_timer(2.0).timeout.connect(l.queue_free)
