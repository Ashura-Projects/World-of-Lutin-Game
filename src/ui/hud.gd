class_name Hud
extends CanvasLayer
## Interface en jeu (STYLE-VALIDE §7) : barre du haut, 7 menus en bas, engrenage.

var root: Control
var _time_label: Label
var _fps_label: Label
var _speed_buttons: Array[Button] = []
var _menu_panel: PanelContainer
var _game: Node


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.make_theme()
	add_child(root)
	_build_top()
	_build_bottom()
	_build_menu()
	EventBus.speed_changed.connect(func(_s: int) -> void: _refresh_speed())


var sheet: LutinSheet
var harvest_panel: HarvestPanel
var jobs_panel: JobsPanel
var _res_labels: Dictionary = {}
var _food_drop: PanelContainer


func show_lutin(l: Lutin) -> void:
	sheet.show_lutin(l)


func bind_game(game: Node) -> void:
	_game = game
	sheet = LutinSheet.new()
	sheet.position = Vector2(20, 80)
	root.add_child(sheet)
	harvest_panel = HarvestPanel.new()
	harvest_panel.setup(game)
	harvest_panel.position = Vector2(170, 400)
	harvest_panel.visible = false
	root.add_child(harvest_panel)
	jobs_panel = JobsPanel.new()
	jobs_panel.setup(game)
	jobs_panel.position = Vector2(420, 80)
	jobs_panel.visible = false
	root.add_child(jobs_panel)
	_panel_toggle("Récolter", harvest_panel)
	_panel_toggle("Lutins", jobs_panel)
	_build_resources()
	_setup_build(game.build_tool, game.world_view)


func _panel_toggle(button_name: String, panel: Control) -> void:
	var b := menu_button(button_name)
	b.toggle_mode = true
	b.toggled.connect(
		func(on: bool) -> void:
			panel.visible = on
			if on and panel is JobsPanel:
				panel.refresh()
			if not on and panel is HarvestPanel:
				panel.hide_preview()
			if on:
				_close_others(button_name)
	)


## Un seul menu du bas ouvert à la fois.
func _close_others(keep: String) -> void:
	for n in ["Construire", "Récolter", "Zones", "Lutins", "Militaire", "Commerce", "Gestion"]:
		var b := menu_button(n)
		if n != keep and b.toggle_mode and b.button_pressed:
			b.button_pressed = false


## Ressources en haut : Nourriture (total des aliments, détail déroulant), bûches, pierre, fer, or.
func _build_resources() -> void:
	var x := 690
	for r: Array in [
		["food", "Nourriture"], ["log", "Bûches"], ["stone", "Pierre"], ["iron_ore", "Fer"], ["gold", "Or"]
	]:
		var b := Button.new()
		b.position = Vector2(x, 6)
		var wide := 200 if r[0] == "food" else 140
		b.custom_minimum_size = Vector2(wide, 50)
		b.add_theme_font_size_override("font_size", 17)
		root.add_child(b)
		_res_labels[r[0]] = [b, r[1]]
		x += wide + 8
	_food_drop = PanelContainer.new()
	_food_drop.position = Vector2(690, 62)
	_food_drop.visible = false
	root.add_child(_food_drop)
	_res_labels["food"][0].pressed.connect(func() -> void: _food_drop.visible = not _food_drop.visible)


func _refresh_resources() -> void:
	if _game == null or _game.colony == null:
		return
	var st: Stockpile = _game.colony.stock
	for k: String in _res_labels:
		var n := st.food_total() if k == "food" else st.count(k)
		_res_labels[k][0].text = "%s %d%s" % [_res_labels[k][1], n, " ▾" if k == "food" else ""]
	if _food_drop.visible:
		for c in _food_drop.get_children():
			c.queue_free()
		var l := Label.new()
		var lines := []
		for id: String in st.items:
			if Stockpile._resource(id).get("category", "") == "food":
				lines.append("%s : %d" % [Stockpile._resource(id).get("name", id), st.count(id)])
		l.text = "\n".join(lines) if not lines.is_empty() else "Aucune nourriture"
		_food_drop.add_child(l)


## Mode Construire : barre des matériaux + curseur d'étage (bord droit).
func _setup_build(tool: BuildTool, view: WorldView) -> void:
	var panel := BuildPanel.new()
	panel.setup(tool)
	panel.position = Vector2(170, 380)
	panel.visible = false
	root.add_child(panel)
	var btn := menu_button("Construire")
	btn.toggle_mode = true
	btn.toggled.connect(
		func(on: bool) -> void:
			panel.visible = on
			tool.set_active(on)
	)
	var slider := VSlider.new()
	slider.min_value = 1
	slider.max_value = tool.world.size.y
	slider.value = tool.world.size.y
	slider.step = 1
	slider.position = Vector2(1540, 90)
	slider.size = Vector2(50, 500)
	slider.custom_minimum_size = Vector2(50, 500)
	slider.value_changed.connect(
		func(v: float) -> void:
			var y := int(v) if v < tool.world.size.y else 9999
			view.set_max_y(y)
			tool.max_y = y
	)
	root.add_child(slider)


func _bar(rect: Rect2) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.9), UiStyle.GOLD_D, 2, 0))
	p.position = rect.position
	p.size = rect.size
	root.add_child(p)
	return p


func _build_top() -> void:
	var bar := _bar(Rect2(0, 0, 1600, 62))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_time_label = UiStyle.title_label("", 26)
	_time_label.position = Vector2(18, 12)
	bar.add_child(_time_label)
	var speeds: Array = DataRegistry.get_table("time").get("speeds", [0, 1, 2, 4])
	for i in speeds.size():
		var s := int(speeds[i])
		var b := Button.new()
		b.text = "II" if s == 0 else "x%d" % s
		b.position = Vector2(300 + i * 66, 6)
		b.custom_minimum_size = Vector2(58, 50)
		b.pressed.connect(func() -> void: GameClock.set_speed(s))
		bar.add_child(b)
		_speed_buttons.append(b)
	_fps_label = Label.new()
	_fps_label.position = Vector2(590, 18)
	_fps_label.add_theme_color_override("font_color", UiStyle.TXT_D)
	bar.add_child(_fps_label)
	var gear := Button.new()
	gear.text = "⚙"
	gear.custom_minimum_size = Vector2(56, 50)
	gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear.position = Vector2(-66, 6)
	gear.pressed.connect(func() -> void: _menu_panel.visible = not _menu_panel.visible)
	bar.add_child(gear)
	_refresh_speed()


func _build_bottom() -> void:
	var bar := _bar(Rect2(0, 628, 1600, 92))
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -92
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	for n in ["Construire", "Récolter", "Zones", "Lutins", "Militaire", "Commerce", "Gestion"]:
		var b := Button.new()
		b.text = n
		b.custom_minimum_size = Vector2(170, 76)
		b.add_theme_font_size_override("font_size", 20)
		b.name = n
		row.add_child(b)


func menu_button(name: String) -> Button:
	return root.find_child(name, true, false) as Button


func _build_menu() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.position = Vector2(560, 110)
	_menu_panel.custom_minimum_size = Vector2(480, 0)
	_menu_panel.visible = false
	root.add_child(_menu_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_menu_panel.add_child(v)
	v.add_child(UiStyle.title_label("Menu", 34))
	for item: Array in [
		["Reprendre", _close_menu], ["Sauvegarder", _save], ["Menu principal", _to_title], ["Quitter", _quit]
	]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(440, 58)
		b.pressed.connect(item[1])
		v.add_child(b)


func _close_menu() -> void:
	_menu_panel.visible = false


func _save() -> void:
	SaveManager.save_game("auto")
	_menu_panel.visible = false


func _to_title() -> void:
	SaveManager.save_game("auto")
	GameClock.running = false
	get_tree().change_scene_to_file("res://src/ui/title_screen.tscn")


func _quit() -> void:
	SaveManager.save_game("auto")
	get_tree().quit()


func _refresh_speed() -> void:
	var speeds: Array = DataRegistry.get_table("time").get("speeds", [0, 1, 2, 4])
	for i in _speed_buttons.size():
		var active := int(speeds[i]) == GameClock.speed
		_speed_buttons[i].add_theme_stylebox_override(
			"normal", UiStyle.box(UiStyle.BLOOD if active else UiStyle.IRON_L)
		)


func _process(_delta: float) -> void:
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	var sname: String = seasons[GameClock.season_index()]["name"] if not seasons.is_empty() else ""
	var dps := int(DataRegistry.get_table("time").get("days_per_season", 5))
	_time_label.text = "%s · jour %d" % [sname, GameClock.day() % dps + 1]
	_fps_label.text = "%d img/s" % Engine.get_frames_per_second()
	if Engine.get_process_frames() % 15 == 0:
		_refresh_resources()
