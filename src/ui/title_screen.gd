extends Control
## Menu principal (STYLE-VALIDE §7) : Continuer, Nouvelle partie (configuration), Charger, Paramètres, Crédits, Quitter.

const GAME_SCENE := "res://src/game/game.tscn"

var _setup_panel: NewGamePanel
var _debug_btn: Button
var _main: VBoxContainer
var _play: VBoxContainer
var _slots: SlotsPanel
var _taps: Array = []  # 5 touchers rapides dans le coin droit = menu débug


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

	# menu principal : Jouer, Paramètres, Crédits, (Débug), Quitter
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 12)
	col.add_child(_main)
	UiStyle.make_primary(_menu_button(_main, "Jouer", func() -> void: _show_play(true)))
	_menu_button(_main, "Guide", func() -> void: _popup(GuidePanel.new(), Vector2(200, 60)))
	_menu_button(_main, "Paramètres", func() -> void: _popup(SettingsPanel.new()))
	_menu_button(_main, "Crédits", func() -> void: _popup(CreditsPanel.new()))
	_debug_btn = _menu_button(_main, "Débug", _debug_menu)
	_debug_btn.add_theme_color_override("font_color", Color("ff8a7a"))
	_debug_btn.visible = bool(Settings.get_value("debug"))
	_menu_button(_main, "Quitter", func() -> void: get_tree().quit())
	# sous-menu Jouer : Continuer, Nouvelle partie, Charger, Tutoriel, Retour
	_play = VBoxContainer.new()
	_play.add_theme_constant_override("separation", 12)
	_play.visible = false
	col.add_child(_play)
	var cont := _menu_button(_play, "Continuer", _on_continue)
	cont.disabled = SaveManager.last_slot() == ""
	if not cont.disabled:
		UiStyle.make_primary(cont)
	_menu_button(_play, "Nouvelle partie", _on_new_game)
	_menu_button(_play, "Charger", _open_slots)
	_menu_button(_play, "Tutoriel", _start_tutorial)
	_menu_button(_play, "← Retour", func() -> void: _show_play(false))
	_build_corner_buttons()

	var ver := Label.new()
	ver.text = "v%s · by Ashura" % ProjectSettings.get_setting("application/config/version", "1.0.0")
	ver.add_theme_color_override("font_color", UiStyle.TXT_D)
	ver.add_theme_font_size_override("font_size", 16)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(16, -30)
	add_child(ver)
	_build_setup_panel()
	var corner := Button.new()
	corner.flat = true
	corner.position = Vector2(1480, 0)
	corner.custom_minimum_size = Vector2(120, 120)
	corner.set_meta("silent", true)
	corner.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	corner.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	corner.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	corner.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	corner.pressed.connect(_corner_tap)
	add_child(corner)


func _menu_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 62)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_setup_panel() -> void:
	_setup_panel = NewGamePanel.new()
	_setup_panel.position = Vector2(560, 60)
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
	if _slots != null:
		_slots.visible = false
	_setup_panel.visible = not _setup_panel.visible
	_setup_panel.refresh()


func _on_continue() -> void:
	load_slot(SaveManager.last_slot())


func load_slot(slot: String) -> void:
	if slot == "" or not SaveManager.has_save(slot):
		return
	GameSetup.load_slot = slot
	get_tree().change_scene_to_file(GAME_SCENE)


func _start_game() -> void:
	GameSetup.load_slot = ""
	get_tree().change_scene_to_file(GAME_SCENE)


## Tutoriel : petite carte paisible, 4 lutins, missions pas à pas (construire, cultiver, se défendre…).
func _start_tutorial() -> void:
	GameSetup.reset_defaults()
	GameSetup.set_mode("tutorial")
	GameSetup.map_size = "small"
	GameSetup.lutin_count = 4
	GameSetup.save_slot = "tutoriel"
	_start_game()


func _show_play(on: bool) -> void:
	_main.visible = not on
	_play.visible = on
	_setup_panel.visible = false
	if _slots != null:
		_slots.visible = false


func _open_slots() -> void:
	if _slots == null:
		_slots = SlotsPanel.new()
		_slots.position = Vector2(560, 120)
		add_child(_slots)
		_slots.load_requested.connect(load_slot)
	_setup_panel.visible = false
	_slots.visible = true
	_slots.refresh()


## Coin bas-droit : Info (aide) et Retour (revenir en arrière facilement).
func _build_corner_buttons() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(1270, 640)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var info := Button.new()
	info.text = "ℹ Info"
	info.custom_minimum_size = Vector2(130, 60)
	info.pressed.connect(func() -> void: _dialog("Info", InfoTexts.title_help()))
	box.add_child(info)
	var back := Button.new()
	back.text = "↩ Retour"
	back.custom_minimum_size = Vector2(150, 60)
	back.pressed.connect(_back)
	box.add_child(back)


func _back() -> void:
	for c in get_children():
		if c is PanelContainer and c.visible and c != _setup_panel and c != _slots and c.get_index() > 2:
			if c is SettingsPanel or c is CreditsPanel or c is FactionEditor or c is GuidePanel:
				c.queue_free()
				return
	if _slots != null and _slots.visible:
		_slots.visible = false
	elif _setup_panel.visible:
		_setup_panel.visible = false
	else:
		_show_play(false)


func _popup(p: Control, at: Vector2 = Vector2(560, 120)) -> void:
	p.position = at
	add_child(p)


func _toast(text: String) -> void:
	EventBus.alert.emit("info", text)
	var l := Label.new()
	l.text = text
	l.position = Vector2(600, 640)
	add_child(l)
	get_tree().create_timer(2.0).timeout.connect(l.queue_free)


## Menu débug caché : 5 touchers en moins de 3 secondes dans le coin en haut à droite.
func _corner_tap() -> void:
	var now := Time.get_ticks_msec()
	_taps = _taps.filter(func(t: int) -> bool: return now - t < 3000)
	_taps.append(now)
	if _taps.size() < 5:
		return
	_taps.clear()
	Settings.set_value("debug", true)
	_debug_btn.visible = true
	_dialog("Mode débug activé", "Le menu débug est maintenant dans le menu (accueil et ⚙ en partie).")


func _dialog(title: String, text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, Color("e05050"), 3, 10))
	p.position = Vector2(500, 260)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiStyle.title_label(title, 30, Color("ff8a7a")))
	var l := Label.new()
	l.text = text
	v.add_child(l)
	var ok := Button.new()
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(200, 56)
	UiStyle.make_primary(ok)
	ok.pressed.connect(p.queue_free)
	v.add_child(ok)
	add_child(p)


## Menu débug de l'accueil : rappel et désactivation (les commandes sont dans ⚙ en partie).
func _debug_menu() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, Color("e05050"), 3, 10))
	p.position = Vector2(520, 200)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiStyle.header("Menu débug", 30, p.queue_free))
	var l := Label.new()
	l.text = (
		"En partie : ⚙ › Débug (apparitions, ressources, mode dieu,\n"
		+ "construction libre, temps, orcs, factions, carte)."
	)
	v.add_child(l)
	var off := Button.new()
	off.text = "Désactiver le menu débug"
	off.custom_minimum_size = Vector2(460, 56)
	UiStyle.make_primary(off)
	off.pressed.connect(
		func() -> void:
			Settings.set_value("debug", false)
			_debug_btn.visible = false
			p.queue_free()
	)
	v.add_child(off)
	add_child(p)
