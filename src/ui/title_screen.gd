extends Control
## Menu principal (STYLE-VALIDE §7) : Continuer, Nouvelle partie (configuration), Charger, Paramètres, Crédits, Quitter.

const GAME_SCENE := "res://src/game/game.tscn"

var _setup_panel: PanelContainer
var _lutin_label: Label
var _seed_label: Label


func _ready() -> void:
	theme = UiStyle.make_theme()
	GameSetup.reset_defaults()
	_build()
	Audio.start_music()


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/title_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(0.05, 0.04, 0.04, 0.55)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var col := VBoxContainer.new()
	col.position = Vector2(80, 60)
	col.custom_minimum_size = Vector2(460, 0)
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	col.add_child(UiStyle.title_label("World of Lutin", 64))
	var tag := UiStyle.title_label("Bâtis. Règne. Deviens légende.", 22, UiStyle.TXT_D)
	col.add_child(tag)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	col.add_child(spacer)

	var cont := _menu_button(col, "Continuer", _on_continue)
	cont.disabled = not SaveManager.has_save("auto")
	if not cont.disabled:
		UiStyle.make_primary(cont)
	var newb := _menu_button(col, "Nouvelle partie", _on_new_game)
	if cont.disabled:
		UiStyle.make_primary(newb)
	_menu_button(col, "Paramètres", func() -> void: _toast("Paramètres : bientôt"))
	_menu_button(col, "Crédits", func() -> void: _toast("Projet d'Ashura — voir assets/CREDITS.md"))
	_menu_button(col, "Quitter", func() -> void: get_tree().quit())

	var ver := Label.new()
	ver.text = "v0.1 · projet d'Ashura"
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
	_setup_panel = PanelContainer.new()
	_setup_panel.position = Vector2(600, 150)
	_setup_panel.custom_minimum_size = Vector2(520, 0)
	_setup_panel.visible = false
	add_child(_setup_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_setup_panel.add_child(v)
	v.add_child(UiStyle.title_label("Nouvelle partie", 34))
	var sandbox := Button.new()
	sandbox.text = "Bac à sable"
	sandbox.custom_minimum_size = Vector2(460, 64)
	UiStyle.make_primary(sandbox)
	v.add_child(sandbox)
	var royal := Button.new()
	royal.text = "Aventure Royale (Phase 2)"
	royal.disabled = true
	royal.custom_minimum_size = Vector2(460, 56)
	v.add_child(royal)
	# nombre de lutins de départ (2 à 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var lab := Label.new()
	lab.text = "Lutins de départ"
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	row.add_child(_small_button("−", func() -> void: _change_lutins(-1)))
	_lutin_label = UiStyle.title_label(str(GameSetup.lutin_count), 30)
	_lutin_label.custom_minimum_size = Vector2(56, 0)
	_lutin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_lutin_label)
	row.add_child(_small_button("+", func() -> void: _change_lutins(1)))
	var row2 := HBoxContainer.new()
	v.add_child(row2)
	_seed_label = Label.new()
	_seed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(_seed_label)
	row2.add_child(_small_button("⟲", _new_seed))
	_refresh_seed()
	var fb := Button.new()
	fb.text = "Faction et emblème…"
	fb.custom_minimum_size = Vector2(460, 56)
	fb.pressed.connect(_open_faction)
	v.add_child(fb)
	var go := Button.new()
	go.text = "Lancer"
	go.custom_minimum_size = Vector2(460, 64)
	UiStyle.make_primary(go)
	go.pressed.connect(_start_game)
	sandbox.pressed.connect(_start_game)
	v.add_child(go)


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


func _change_lutins(d: int) -> void:
	GameSetup.lutin_count = GameSetup.clamp_lutins(GameSetup.lutin_count + d)
	_lutin_label.text = str(GameSetup.lutin_count)


func _new_seed() -> void:
	GameSetup.seed_value = randi() % 100000
	_refresh_seed()


func _refresh_seed() -> void:
	_seed_label.text = "Graine de carte : %d" % GameSetup.seed_value


func _on_new_game() -> void:
	_setup_panel.visible = not _setup_panel.visible


func _on_continue() -> void:
	GameSetup.load_slot = "auto"
	get_tree().change_scene_to_file(GAME_SCENE)


func _start_game() -> void:
	GameSetup.load_slot = ""
	get_tree().change_scene_to_file(GAME_SCENE)


func _toast(text: String) -> void:
	EventBus.alert.emit("info", text)
	var l := Label.new()
	l.text = text
	l.position = Vector2(600, 640)
	add_child(l)
	get_tree().create_timer(2.0).timeout.connect(l.queue_free)
