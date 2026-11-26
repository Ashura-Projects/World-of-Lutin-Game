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
var tools: HudTools
var build_panel: BuildPanel
var harvest_panel: HarvestPanel
var jobs_panel: JobsPanel
var zones_panel: ZonesPanel
var workshops_panel: WorkshopsPanel
var military_panel: MilitaryPanel
var dashboard: DashboardPanel
var research_panel: ResearchPanel
var commerce_panel: CommercePanel
var _toasts: VBoxContainer
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
	zones_panel = ZonesPanel.new()
	zones_panel.setup(game)
	zones_panel.position = Vector2(170, 470)
	zones_panel.visible = false
	root.add_child(zones_panel)
	workshops_panel = WorkshopsPanel.new()
	workshops_panel.setup(game)
	workshops_panel.position = Vector2(350, 70)
	workshops_panel.visible = false
	root.add_child(workshops_panel)
	military_panel = MilitaryPanel.new()
	military_panel.setup(game)
	military_panel.position = Vector2(420, 80)
	military_panel.visible = false
	root.add_child(military_panel)
	_panel_toggle("Militaire", military_panel)
	commerce_panel = CommercePanel.new()
	commerce_panel.setup(game)
	commerce_panel.position = Vector2(350, 80)
	commerce_panel.visible = false
	root.add_child(commerce_panel)
	_panel_toggle("Commerce", commerce_panel)
	game.sim.trade.merchant_arrived.connect(_merchant_dialog)
	dashboard = DashboardPanel.new()
	dashboard.setup(game)
	dashboard.position = Vector2(390, 80)
	dashboard.visible = false
	root.add_child(dashboard)
	research_panel = ResearchPanel.new()
	research_panel.setup(game)
	research_panel.position = Vector2(360, 80)
	research_panel.visible = false
	root.add_child(research_panel)
	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(1150, 120)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)
	EventBus.alert.connect(_toast)
	_panel_toggle("Zones", zones_panel)
	_panel_toggle("Gestion", workshops_panel)
	_panel_toggle("Récolter", harvest_panel)
	_panel_toggle("Lutins", jobs_panel)
	_build_resources()
	_setup_build(game.build_tool, game.world_view)


## Alertes en bulles (en haut à droite), quelques secondes.
func _toast(kind: String, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override(
		"font_color", Color("ffd27a") if kind in ["mort", "alerte", "froid", "cloche"] else UiStyle.TXT
	)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.9), UiStyle.GOLD_D, 1, 6))
	p.add_child(l)
	_toasts.add_child(p)
	if _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
	get_tree().create_timer(6.0).timeout.connect(p.queue_free)


## Dialogue d'événement (maquette validée) : un marchand arrive.
func _merchant_dialog() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	p.position = Vector2(500, 380)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiStyle.title_label("Un marchand au village", 28))
	var txt := Label.new()
	txt.text = "« Le bonjour ! J'ai du fer, du sel et des remèdes.\n  Contre de l'or, ou je rachète vos surplus. »"
	txt.add_theme_color_override("font_color", UiStyle.PARCH)
	v.add_child(txt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for b: Array in [["Commercer", true], ["Plus tard", false]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(220, 56)
		if b[1]:
			UiStyle.make_primary(btn)
		var open: bool = b[1]
		btn.pressed.connect(
			func() -> void:
				p.queue_free()
				if open:
					menu_button("Commerce").button_pressed = true
		)
		row.add_child(btn)
	root.add_child(p)


func open_faction() -> void:
	workshops_panel.visible = false
	var ed := FactionEditor.new()
	ed.setup(_game.sim.faction)
	ed.position = Vector2(300, 70)
	root.add_child(ed)
	ed.done.connect(
		func(_f: Faction) -> void:
			EventBus.alert.emit("faction", "Faction : %s" % _f.name)
			EventBus.faction_changed.emit()
			ed.queue_free()
	)


func toggle_research() -> void:
	research_panel.visible = not research_panel.visible
	workshops_panel.visible = false
	if research_panel.visible:
		research_panel.refresh()


func toggle_dashboard() -> void:
	dashboard.visible = not dashboard.visible
	if dashboard.visible:
		dashboard.refresh()


func _panel_toggle(button_name: String, panel: Control) -> void:
	var b := menu_button(button_name)
	b.toggle_mode = true
	b.toggled.connect(
		func(on: bool) -> void:
			panel.visible = on
			if on and panel.has_method("refresh"):
				panel.call("refresh")
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
	var x := 668
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
	_food_drop.position = Vector2(668, 62)
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
	tools = HudTools.new()
	add_child(tools)
	tools.setup(self, _game.camera, view, tool)
	var panel := BuildPanel.new()
	panel.setup(tool, _game.board)
	panel.position = Vector2(80, 300)
	panel.visible = false
	root.add_child(panel)
	build_panel = panel
	panel.collapsed.connect(func(label: String) -> void: tools.show_bubble(panel, label))
	var btn := menu_button("Construire")
	btn.toggle_mode = true
	btn.toggled.connect(
		func(on: bool) -> void:
			panel.visible = on
			tool.set_active(on)
			if not on:
				tools.hide_bubble()
			if on:
				_close_others("Construire")
	)


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
	_time_label = UiStyle.title_label("", 22)
	_time_label.position = Vector2(18, 12)
	bar.add_child(_time_label)
	var speeds: Array = DataRegistry.get_table("time").get("speeds", [0, 1, 2, 4])
	for i in speeds.size():
		var s := int(speeds[i])
		var b := Button.new()
		b.text = "II" if s == 0 else "x%d" % s
		b.position = Vector2(400 + i * 64, 6)
		b.custom_minimum_size = Vector2(58, 50)
		b.pressed.connect(func() -> void: GameClock.set_speed(s))
		bar.add_child(b)
		_speed_buttons.append(b)
	_fps_label = Label.new()
	_fps_label.position = Vector2(18, 64)
	_fps_label.add_theme_color_override("font_color", UiStyle.TXT_D)
	_fps_label.visible = false  # mesure : visible seulement en débogage
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


func _settings() -> void:
	_menu_panel.visible = false
	var sp := SettingsPanel.new()
	sp.position = Vector2(520, 100)
	root.add_child(sp)


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
	if _game != null and _game.sim != null:
		_time_label.text += " · " + _game.sim.village.rank_name()
	_fps_label.text = "%d img/s" % Engine.get_frames_per_second()
	if Engine.get_process_frames() % 15 == 0:
		_refresh_resources()
	if Engine.get_process_frames() % 30 == 0:
		for p: Control in [military_panel, dashboard, commerce_panel]:
			if p != null and p.visible:
				p.call("refresh")
