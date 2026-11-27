class_name UnitsBox
extends VBoxContainer
## Onglet « Unités » du menu Militaire : créer une unité (capitaine + lutins), formation, ordres
## (Aller à…, Attaquer…, Tenir, Rentrer, Dissoudre). « Aller à » et « Attaquer » : toucher la carte ensuite.

var game: Node
var _list: VBoxContainer
var _new_box: VBoxContainer
var _captain: OptionButton
var _checks: Dictionary = {}


func setup(g: Node) -> void:
	game = g
	add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	add_child(row)
	var nb := Button.new()
	nb.text = "+ Nouvelle unité"
	nb.custom_minimum_size = Vector2(240, 50)
	nb.pressed.connect(_toggle_new)
	row.add_child(nb)
	_new_box = VBoxContainer.new()
	_new_box.visible = false
	add_child(_new_box)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1000, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _units() -> Units:
	return game.sim.units


func _toggle_new() -> void:
	_new_box.visible = not _new_box.visible
	for c in _new_box.get_children():
		c.queue_free()
	_checks.clear()
	if not _new_box.visible:
		return
	var row := HBoxContainer.new()
	_new_box.add_child(row)
	var l := Label.new()
	l.text = "Capitaine : "
	row.add_child(l)
	_captain = OptionButton.new()
	_captain.custom_minimum_size = Vector2(300, 46)
	row.add_child(_captain)
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(1000, 0)
	_new_box.add_child(flow)
	for lu: Lutin in game.colony.lutins:
		if not lu.can_work() or lu.jailed.y >= 0:
			continue
		_captain.add_item(lu.name, lu.id)
		var c := CheckBox.new()
		c.text = lu.name
		c.add_theme_font_size_override("font_size", 18)
		flow.add_child(c)
		_checks[lu.id] = c
	var ok := Button.new()
	ok.text = "Créer l'unité"
	ok.custom_minimum_size = Vector2(240, 50)
	UiStyle.make_primary(ok)
	ok.pressed.connect(_create)
	_new_box.add_child(ok)


func _create() -> void:
	if _captain.item_count == 0:
		return
	var members := []
	for id: int in _checks:
		if _checks[id].button_pressed:
			members.append(id)
	var name := "Unité %d" % _units().next_id
	_units().create(name, _captain.get_selected_id(), members)
	_new_box.visible = false
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	if _units().units.is_empty():
		var l := Label.new()
		l.text = "Aucune unité. Une unité = un capitaine et des lutins qui se déplacent et combattent en formation."
		l.add_theme_color_override("font_color", UiStyle.TXT_D)
		_list.add_child(l)
		return
	var orders := {
		"none": "libre",
		"move": "en marche",
		"attack": "à l'attaque",
		"hold": "tient la position",
		"explore": "en exploration"
	}
	for u: Dictionary in _units().units.values():
		var cap := game.colony.find_lutin(u["captain"]) as Lutin
		var head := Label.new()
		head.text = (
			"%s — capitaine %s — %d membre(s) — %s"
			% [u["name"], cap.name if cap != null else "?", u["members"].size(), orders.get(u["order"], u["order"])]
		)
		head.add_theme_color_override("font_color", UiStyle.GOLD)
		_list.add_child(head)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_list.add_child(row)
		var f := OptionButton.new()
		f.custom_minimum_size = Vector2(170, 46)
		var fs := _units().formations()
		for i in fs.size():
			f.add_item(fs[i]["name"], i)
			if fs[i]["id"] == u["formation"]:
				f.select(i)
		var uid: int = u["id"]
		f.item_selected.connect(func(i: int) -> void: _units().set_formation(uid, fs[i]["id"]))
		row.add_child(f)
		for a: Array in [
			["move", "Aller à…"],
			["attack", "Attaquer…"],
			["hold", "Tenir"],
			["explore", "Explorer"],
			["return", "Rentrer"]
		]:
			var b := Button.new()
			b.text = a[1]
			b.custom_minimum_size = Vector2(128, 46)
			b.add_theme_font_size_override("font_size", 17)
			b.pressed.connect(_order.bind(uid, str(a[0])))
			row.add_child(b)
		var d := Button.new()
		d.text = "Dissoudre"
		d.custom_minimum_size = Vector2(140, 46)
		d.add_theme_font_size_override("font_size", 17)
		d.pressed.connect(
			func() -> void:
				_units().disband(uid)
				refresh()
		)
		row.add_child(d)


func _order(uid: int, kind: String) -> void:
	if kind in ["move", "attack"]:
		game.hud.menu_button("Militaire").button_pressed = false
		var prompt := "Touchez où l'unité doit aller" if kind == "move" else "Touchez le lieu à attaquer"
		game.hud.windows.pick_cell(prompt, func(cell: Vector3i) -> void: _units().command(uid, kind, cell))
		return
	_units().command(uid, kind)
	refresh()
