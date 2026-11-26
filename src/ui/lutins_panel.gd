class_name LutinsPanel
extends PanelContainer
## Menu Lutins : liste des lutins (toucher = choisir et donner des ordres ; double toucher = centrer la caméra),
## familles (liens de parenté), métiers.

const TABS := [["list", "Liste"], ["family", "Familles"], ["jobs", "Métiers"]]

var game: Node
var tab: String = "list"
var _tabs: Dictionary = {}
var _list: VBoxContainer
var _scroll: ScrollContainer
var _jobs: JobsPanel
var _last_tap: Dictionary = {"id": -1, "t": 0}


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var t := UiStyle.title_label("Lutins", 30)
	t.custom_minimum_size = Vector2(180, 0)
	head.add_child(t)
	for e: Array in TABS:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(170, 50)
		b.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(b)
		_tabs[e[0]] = b
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(880, 420)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)
	_jobs = JobsPanel.new()
	_jobs.setup(g)
	_jobs.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_jobs.visible = false
	v.add_child(_jobs)
	show_tab("list")


func show_tab(t: String) -> void:
	tab = t
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	_scroll.visible = t != "jobs"
	_jobs.visible = t == "jobs"
	refresh()


func refresh() -> void:
	if tab == "jobs":
		_jobs.refresh()
		return
	for c in _list.get_children():
		c.queue_free()
	if tab == "family":
		_fill_family()
		return
	var states := ["Libre", "Marche", "Dort", "Mange", "Travaille"]
	for l: Lutin in game.colony.lutins:
		var b := Button.new()
		var extra := "  · en cage" if l.jailed.y >= 0 else ("  · ordre" if not l.order.is_empty() else "")
		b.text = (
			"%s · %d ans · %s · %s · %s%s"
			% [
				l.name,
				l.age_days / 20,
				LutinSheet.job_name(l.job),
				game.sim.realm.title_name(l),
				states[l.state],
				extra
			]
		)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(860, 50)
		b.add_theme_font_size_override("font_size", 18)
		b.tooltip_text = "Toucher : choisir · Double toucher : centrer la caméra"
		b.pressed.connect(_on_lutin.bind(l))
		if game.lutins_view.selected_id == l.id:
			b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
		_list.add_child(b)


func _fill_family() -> void:
	var any := false
	for l: Lutin in game.colony.lutins:
		var s := Kinship.summary(game.colony, l)
		if s == "Pas de famille au village.":
			continue
		any = true
		var lab := Label.new()
		lab.text = "%s (%d ans) — %s" % [l.name, l.age_days / 20, s]
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(850, 0)
		lab.add_theme_font_size_override("font_size", 18)
		_list.add_child(lab)
	if not any:
		var lab := Label.new()
		lab.text = "Pas encore de famille : les couples ont des enfants quand ils ont un foyer (Population)."
		_list.add_child(lab)


## Toucher : choisir le lutin (barre d'ordres). Double toucher : centrer la caméra sur lui et fermer le menu.
func _on_lutin(l: Lutin) -> void:
	var now := Time.get_ticks_msec()
	var double: bool = _last_tap["id"] == l.id and now - int(_last_tap["t"]) < 450
	_last_tap = {"id": l.id, "t": now}
	game.hud.show_lutin(l)
	if double:
		game.camera.distance = 12.0
		game.camera.focus(l.pos)
		game.hud.menu_button("Lutins").button_pressed = false
	else:
		refresh()
