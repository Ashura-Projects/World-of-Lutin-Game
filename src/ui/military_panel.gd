class_name MilitaryPanel
extends PanelContainer
## Menu Militaire : onglet Alerte (cloche Mobiliser / Se cacher / Fin, armes en réserve, combattants)
## et onglet Unités (capitaine, formation, ordres).

var game: Node
var _list: VBoxContainer
var _state: Label
var _alert_box: VBoxContainer
var units_box: UnitsBox
var _tab_btns: Dictionary = {}


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1020, 0)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	outer.add_child(head)
	var t := UiStyle.title_label("Militaire", 30)
	t.custom_minimum_size = Vector2(200, 0)
	head.add_child(t)
	for e: Array in [["alert", "Alerte"], ["units", "Unités"]]:
		var tb := Button.new()
		tb.text = e[1]
		tb.custom_minimum_size = Vector2(180, 50)
		tb.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(tb)
		_tab_btns[e[0]] = tb
	_alert_box = VBoxContainer.new()
	_alert_box.add_theme_constant_override("separation", 8)
	outer.add_child(_alert_box)
	units_box = UnitsBox.new()
	units_box.setup(g)
	outer.add_child(units_box)
	var v := _alert_box
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for b: Array in [["Mobiliser", "mobilize"], ["Se cacher", "hide"], ["Fin de l'alerte", "none"]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(220, 58)
		btn.pressed.connect(_ring.bind(b[1]))
		if b[1] == "mobilize":
			UiStyle.make_primary(btn)
		row.add_child(btn)
	_state = Label.new()
	v.add_child(_state)
	_list = VBoxContainer.new()
	v.add_child(_list)
	show_tab("alert")


func show_tab(tab: String) -> void:
	_alert_box.visible = tab == "alert"
	units_box.visible = tab == "units"
	for k: String in _tab_btns:
		_tab_btns[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == tab else UiStyle.IRON_L))
	if units_box.visible:
		units_box.refresh()
	refresh()


func _ring(mode: String) -> void:
	game.sim.combat.ring(mode)
	refresh()


func refresh() -> void:
	if units_box.visible:
		return  # l'onglet Unités se rafraîchit à la demande (pas pendant un choix)
	var c: Combat = game.sim.combat
	var st: Stockpile = game.colony.stock
	_state.text = (
		"Alerte : %s   ·   En réserve : %d fusil(s), %d lance(s), %d potion(s)"
		% [
			{"none": "aucune", "mobilize": "MOBILISATION", "hide": "à l'abri"}[c.alert],
			st.count("flintlock"),
			st.count("spear"),
			st.count("healing_potion")
		]
	)
	for ch in _list.get_children():
		ch.queue_free()
	for l: Lutin in game.colony.lutins:
		var lab := Label.new()
		var k := 0
		for n: int in l.kills.values():
			k += n
		var weapon := "—"
		if l.weapon != "":
			weapon = str(Combat.weapon_def(l.weapon).get("name", l.weapon))
		var unit: String = str(game.sim.units.unit_of(l).get("name", "—"))
		lab.text = (
			"%s · %s · PV %d · arme : %s · prises : %d · XP combat %d · unité : %s"
			% [l.name, LutinSheet.job_name(l.job), int(l.hp), weapon, k, int(l.combat_xp), unit]
		)
		_list.add_child(lab)
