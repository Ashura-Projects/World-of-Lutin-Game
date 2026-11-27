class_name MissionPanel
extends PanelContainer
## Tutoriel : la mission en cours (objectif, avancement, aide) ; à la fin, continuer ou revenir au menu.

var game: Node
var _title: Label
var _goal: Label
var _hint: Label
var _bar: ProgressBar
var _hint_btn: Button


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.1, 0.08, 0.06, 0.92), UiStyle.GOLD, 2, 10))
	custom_minimum_size = Vector2(520, 0)
	position = Vector2(12, 70)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	_title = UiStyle.title_label("", 22)
	v.add_child(_title)
	_goal = Label.new()
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.custom_minimum_size = Vector2(490, 0)
	_goal.add_theme_font_size_override("font_size", 18)
	v.add_child(_goal)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(490, 16)
	_bar.show_percentage = false
	v.add_child(_bar)
	_hint_btn = Button.new()
	_hint_btn.text = "Aide ▾"
	_hint_btn.custom_minimum_size = Vector2(120, 40)
	_hint_btn.add_theme_font_size_override("font_size", 16)
	_hint_btn.pressed.connect(func() -> void: _hint.visible = not _hint.visible)
	v.add_child(_hint_btn)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(490, 0)
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", UiStyle.PARCH)
	_hint.visible = true
	v.add_child(_hint)
	game.sim.missions.all_done.connect(_on_done)
	game.sim.missions.mission_done.connect(func(_t: String) -> void: _hint.visible = true)


func _process(_d: float) -> void:
	if Engine.get_process_frames() % 20 != 0:
		return
	var ms: TutorialMissions = game.sim.missions
	var m := ms.current()
	if m.is_empty():
		visible = false
		return
	var p := ms.progress()
	_title.text = "Mission %d/%d — %s" % [ms.index + 1, ms.missions().size(), m["title"]]
	_goal.text = "%s  (%d / %d)" % [m["goal"], p[0], p[1]]
	_bar.max_value = p[1]
	_bar.value = p[0]
	_hint.text = str(m.get("hint", ""))


func _on_done() -> void:
	var cfg := DataRegistry.get_table("missions")
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	p.position = Vector2(480, 220)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiStyle.title_label(str(cfg.get("done_title", "Tutoriel terminé !")), 32))
	var l := Label.new()
	l.text = str(cfg.get("done_text", ""))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var cont := Button.new()
	cont.text = "Continuer à jouer"
	cont.custom_minimum_size = Vector2(280, 58)
	UiStyle.make_primary(cont)
	cont.pressed.connect(p.queue_free)
	row.add_child(cont)
	var menu := Button.new()
	menu.text = "Menu principal"
	menu.custom_minimum_size = Vector2(260, 58)
	menu.pressed.connect(
		func() -> void:
			SaveManager.save_game()
			GameClock.running = false
			get_tree().change_scene_to_file("res://src/ui/title_screen.tscn")
	)
	row.add_child(menu)
	get_parent().add_child(p)
