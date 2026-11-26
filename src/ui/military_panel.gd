class_name MilitaryPanel
extends PanelContainer
## Menu Militaire : cloche (Mobiliser / Se cacher / Fin de l'alerte), armes en réserve,
## combattants (tableau de chasse, XP).

var game: Node
var _list: VBoxContainer
var _state: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(760, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiStyle.title_label("Militaire", 30))
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


func _ring(mode: String) -> void:
	game.sim.combat.ring(mode)
	refresh()


func refresh() -> void:
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
		lab.text = (
			"%s · PV %d · arme : %s · prises : %d · XP combat %d" % [l.name, int(l.hp), weapon, k, int(l.combat_xp)]
		)
		_list.add_child(lab)
