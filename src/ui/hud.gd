class_name Hud
extends CanvasLayer
## Interface en jeu (STYLE-VALIDE §7) : barre du haut, 8 menus en bas, engrenage.
## Chaque fenêtre a une croix ✕ et reste entre les deux barres (HudWindows).

const MENUS := ["Construire", "Récolter", "Terrain", "Zones", "Lutins", "Militaire", "Royaume", "Commerce", "Gestion"]

var root: Control
var windows: HudWindows
var top: HudTop
var orders: OrderBar
var unit_bar: UnitBar
var unit_editor: UnitEditor
var stats_panel: StatsPanel
var settlements_panel: SettlementsPanel
var sheet: LutinSheet
var tools: HudTools
var build_panel: BuildPanel
var harvest_panel: HarvestPanel
var terraform_panel: TerraformPanel
var lutins_panel: LutinsPanel
var zones_panel: ZonesPanel
var workshops_panel: WorkshopsPanel
var military_panel: MilitaryPanel
var realm_panel: RealmPanel
var dashboard: DashboardPanel
var research_panel: ResearchPanel
var commerce_panel: CommercePanel
var debug_panel: DebugPanel
var object_dialog: ObjectDialog
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
	_build_corner()
	EventBus.speed_changed.connect(func(_s: int) -> void: _refresh_speed())


func show_lutin(l: Lutin) -> void:
	sheet.show_lutin(l)
	if l != null and l.unit_id >= 0 and unit_bar != null:
		orders.clear()
		unit_bar.open(l.unit_id)  # lutin d'une unité : on commande toute l'unité
	elif l != null:
		orders.select(l)
	else:
		orders.clear()


func bind_game(game: Node) -> void:
	_game = game
	windows = HudWindows.new()
	add_child(windows)
	windows.setup(root, game)
	sheet = LutinSheet.new()
	sheet.position = Vector2(20, 130)
	root.add_child(sheet)
	sheet.setup(game)
	windows.add(sheet, func() -> void: show_lutin(null), true)
	harvest_panel = _menu_panel_add(HarvestPanel.new(), "Récolter", Vector2(170, 380))
	terraform_panel = _menu_panel_add(TerraformPanel.new(), "Terrain", Vector2(170, 420))
	lutins_panel = _menu_panel_add(LutinsPanel.new(), "Lutins", Vector2(300, 70))
	zones_panel = _menu_panel_add(ZonesPanel.new(), "Zones", Vector2(170, 420))
	root.add_child(zones_panel.filter_panel)
	windows.add(zones_panel.filter_panel, func() -> void: zones_panel.filter_panel.visible = false)
	workshops_panel = _menu_panel_add(WorkshopsPanel.new(), "Gestion", Vector2(350, 70))
	military_panel = _menu_panel_add(MilitaryPanel.new(), "Militaire", Vector2(300, 70))
	realm_panel = _menu_panel_add(RealmPanel.new(), "Royaume", Vector2(250, 70))
	commerce_panel = _menu_panel_add(CommercePanel.new(), "Commerce", Vector2(350, 80))
	dashboard = _free_panel_add(DashboardPanel.new(), Vector2(390, 80))
	research_panel = _free_panel_add(ResearchPanel.new(), Vector2(360, 80))
	debug_panel = _free_panel_add(DebugPanel.new(), Vector2(200, 70))
	unit_editor = _free_panel_add(UnitEditor.new(), Vector2(240, 70))
	stats_panel = _free_panel_add(StatsPanel.new(), Vector2(220, 70))
	settlements_panel = _free_panel_add(SettlementsPanel.new(), Vector2(220, 70))
	object_dialog = ObjectDialog.new()
	object_dialog.setup(game)
	root.add_child(object_dialog)
	windows.add(object_dialog, func() -> void: object_dialog.visible = false, true)
	top = HudTop.new()
	add_child(top)
	top.setup(self, game)
	orders = OrderBar.new()
	add_child(orders)
	orders.setup(self, game)
	unit_bar = UnitBar.new()
	add_child(unit_bar)
	unit_bar.setup(self, game)
	_setup_build(game.build_tool, game.world_view)


## Fenêtre liée à un bouton du bas : la croix ✕ relâche le bouton.
func _menu_panel_add(panel: Control, menu: String, pos: Vector2) -> Control:
	panel.call("setup", _game)
	panel.position = pos
	panel.visible = false
	root.add_child(panel)
	_panel_toggle(menu, panel)
	windows.add(panel, func() -> void: menu_button(menu).button_pressed = false)
	return panel


func _free_panel_add(panel: Control, pos: Vector2) -> Control:
	panel.call("setup", _game)
	panel.position = pos
	panel.visible = false
	root.add_child(panel)
	windows.add(panel, func() -> void: panel.visible = false)
	return panel


func open_faction() -> void:
	workshops_panel.visible = false
	var ed := FactionEditor.new()
	ed.setup(_game.sim.faction)
	ed.position = Vector2(300, 70)
	root.add_child(ed)
	windows.add(ed, ed.queue_free)
	ed.done.connect(
		func(_f: Faction) -> void:
			EventBus.alert.emit("faction", "Faction : %s" % _f.name)
			EventBus.faction_changed.emit()
			ed.queue_free()
	)


func open_realm() -> void:
	menu_button("Royaume").button_pressed = true


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
	for n: String in MENUS:
		var b := menu_button(n)
		if n != keep and b.toggle_mode and b.button_pressed:
			b.button_pressed = false


## Mode Construire : panneau par catégories + bulle quand il est réduit.
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
	windows.add(panel, func() -> void: menu_button("Construire").button_pressed = false)
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
	_fps_label = Label.new()
	_fps_label.position = Vector2(18, 66)
	_fps_label.add_theme_color_override("font_color", Color("ffd27a"))
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fps_label)
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
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	for n: String in MENUS:
		var b := Button.new()
		b.text = n
		b.custom_minimum_size = Vector2(140, 76)
		b.add_theme_font_size_override("font_size", 18)
		b.name = n
		row.add_child(b)


## Coin bas-droit : Info (aide selon ce qu'on fait) et Retour (revenir en arrière).
func _build_corner() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(1474, 646)
	box.add_theme_constant_override("separation", 4)
	root.add_child(box)
	for e: Array in [["ℹ", _info], ["↩", back]]:
		var b := Button.new()
		b.text = e[0]
		b.custom_minimum_size = Vector2(58, 62)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(e[1])
		box.add_child(b)


func _info() -> void:
	var ctx := ""
	if build_panel != null and (build_panel.visible or tools.bubble.visible):
		ctx = "build"
	elif orders != null and orders.active():
		ctx = "orders"
	elif zones_panel != null and zones_panel.visible:
		ctx = "zones"
	EventBus.alert.emit("info", InfoTexts.game_help(ctx))


## Retour : annule le choix d'un endroit, sinon ferme la fenêtre du dessus, sinon quitte le mode en cours.
func back() -> void:
	if windows != null and windows.picking():
		windows.cancel_pick()
	elif _menu_panel.visible:
		_menu_panel.visible = false
	elif windows != null and windows.close_top():
		pass
	elif tools != null and tools.bubble.visible:
		menu_button("Construire").button_pressed = false
	elif unit_bar != null and unit_bar.active():
		unit_bar.close()
	elif orders != null and orders.active():
		show_lutin(null)


func menu_button(name: String) -> Button:
	return root.find_child(name, true, false) as Button


func _build_menu() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.position = Vector2(560, 90)
	_menu_panel.custom_minimum_size = Vector2(480, 0)
	_menu_panel.visible = false
	root.add_child(_menu_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_menu_panel.add_child(v)
	v.add_child(UiStyle.header("Menu", 34, _close_menu))
	var debug := Button.new()
	debug.text = "Débug"
	debug.custom_minimum_size = Vector2(440, 56)
	debug.add_theme_color_override("font_color", Color("ff8a7a"))
	debug.pressed.connect(
		func() -> void:
			_menu_panel.visible = false
			debug_panel.visible = true
			debug_panel.refresh()
	)
	_menu_panel.visibility_changed.connect(func() -> void: debug.visible = bool(Settings.get_value("debug")))
	for item: Array in [
		["Reprendre", _close_menu],
		["Sauvegarder", _save],
		["Paramètres", _settings],
		["Guide", _guide],
		["Menu principal", _to_title],
		["Quitter", _quit]
	]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(440, 56)
		b.pressed.connect(item[1])
		v.add_child(b)
		if item[0] == "Paramètres":
			v.add_child(debug)


func _settings() -> void:
	_menu_panel.visible = false
	var sp := SettingsPanel.new()
	sp.position = Vector2(260, 80)
	root.add_child(sp)


func _guide() -> void:
	_menu_panel.visible = false
	var g := GuidePanel.new()
	g.position = Vector2(200, 70)
	root.add_child(g)
	windows.add(g, g.queue_free, true)


func _close_menu() -> void:
	_menu_panel.visible = false


func _save() -> void:
	SaveManager.save_game()
	_menu_panel.visible = false
	EventBus.alert.emit("info", "Partie sauvegardée.")


func _to_title() -> void:
	SaveManager.save_game()
	GameClock.running = false
	get_tree().change_scene_to_file("res://src/ui/title_screen.tscn")


func _quit() -> void:
	SaveManager.save_game()
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
	_fps_label.visible = bool(Settings.get_value("show_fps"))
	if _fps_label.visible:
		_fps_label.text = "%d img/s" % Engine.get_frames_per_second()
	if top != null and Engine.get_process_frames() % 15 == 0:
		top.refresh()
	if Engine.get_process_frames() % 30 == 0:
		for p: Control in [military_panel, dashboard, commerce_panel, realm_panel, lutins_panel]:
			if p != null and p.visible and p.has_method("refresh"):
				p.call("refresh")
