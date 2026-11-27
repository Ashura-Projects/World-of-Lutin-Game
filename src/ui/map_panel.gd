class_name MapPanel
extends PanelContainer
## Grande carte : vue d'ensemble des factions, territoires, ressources découvertes et marqueurs personnels.
## Filtres à droite ; toucher la carte = y envoyer la caméra, ou poser / effacer un marqueur.

var game: Node
var map: Minimap
var mode: String = "look"  # look, add, remove
var _icon: int = 0
var _label: int = 0
var _mode_btns: Dictionary = {}
var _icon_btn: Button
var _label_btn: Button
var _info: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	add_child(h)
	map = Minimap.new()
	map.setup(g, Vector2(520, 520))
	map.picked.connect(_on_pick)
	h.add_child(map)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.custom_minimum_size = Vector2(420, 0)
	h.add_child(v)
	v.add_child(UiStyle.title_label("Carte du royaume", 26))
	for f: Array in [
		["territory", "Territoires"],
		["factions", "Villages et camps d'orcs"],
		["resources", "Ressources découvertes"],
		["markers", "Mes marqueurs"],
		["lutins", "Mes lutins"]
	]:
		var c := CheckButton.new()
		c.text = f[1]
		c.button_pressed = true
		var key: String = f[0]
		c.toggled.connect(func(on: bool) -> void: map.filters[key] = on)
		v.add_child(c)
	var t3 := CheckButton.new()
	t3.text = "Territoires sur le terrain (3D)"
	t3.toggled.connect(func(on: bool) -> void: game.realm_view.show_territory = on)
	v.add_child(t3)
	var row := HBoxContainer.new()
	v.add_child(row)
	for m: Array in [["look", "Regarder"], ["add", "+ Marqueur"], ["remove", "− Marqueur"]]:
		var b := Button.new()
		b.text = m[1]
		b.custom_minimum_size = Vector2(134, 48)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_set_mode.bind(str(m[0])))
		row.add_child(b)
		_mode_btns[m[0]] = b
	var row2 := HBoxContainer.new()
	v.add_child(row2)
	_icon_btn = Button.new()
	_icon_btn.custom_minimum_size = Vector2(70, 46)
	_icon_btn.pressed.connect(func() -> void: _cycle(1, 0))
	row2.add_child(_icon_btn)
	_label_btn = Button.new()
	_label_btn.custom_minimum_size = Vector2(330, 46)
	_label_btn.add_theme_font_size_override("font_size", 16)
	_label_btn.pressed.connect(func() -> void: _cycle(0, 1))
	row2.add_child(_label_btn)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(410, 0)
	_info.add_theme_font_size_override("font_size", 16)
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	v.add_child(_info)
	_cycle(0, 0)
	_set_mode("look")
	visibility_changed.connect(
		func() -> void:
			if visible:
				map.rebuild()
				_set_mode(mode)
	)


func _cycle(di: int, dl: int) -> void:
	var cfg := DataRegistry.get_table("map")
	var icons: Array = cfg.get("marker_icons", ["★"])
	var labels: Array = cfg.get("marker_labels", ["Repère"])
	_icon = (_icon + di) % icons.size()
	_label = (_label + dl) % labels.size()
	_icon_btn.text = icons[_icon]
	_label_btn.text = labels[_label]


func _set_mode(m: String) -> void:
	mode = m
	for k: String in _mode_btns:
		_mode_btns[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == m else UiStyle.IRON_L))
	_info.text = {
		"look": "Touchez la carte pour y aller. Noir : pas encore exploré (envoyez des éclaireurs).",
		"add": "Touchez la carte pour poser le marqueur choisi.",
		"remove": "Touchez un marqueur pour l'effacer."
	}[m]
	_info.text += "\n" + _summary()


func _summary() -> String:
	var t: Territory = game.sim.territory
	var parts := ["Votre territoire : %d zones" % t.count("player")]
	for st: Dictionary in game.sim.rivals.states.values():
		if game.sim.rivals.is_met(st["id"]):
			parts.append("%s : %d" % [Rivals.def(st["id"]).get("name", st["id"]), t.count(st["id"])])
	var camps: Array = game.sim.orcs.camps.filter(
		func(c: Dictionary) -> bool: return c["discovered"] and not c["destroyed"]
	)
	parts.append("Camps d'orcs repérés : %d" % camps.size())
	return " · ".join(parts)


func _on_pick(cell: Vector3i) -> void:
	var t: Territory = game.sim.territory
	var cfg := DataRegistry.get_table("map")
	match mode:
		"add":
			t.add_marker(Vector2i(cell.x, cell.z), cfg["marker_icons"][_icon], cfg["marker_labels"][_label])
		"remove":
			t.remove_marker_near(Vector2i(cell.x, cell.z), 12.0)
		_:
			game.camera.focus(Vector3(cell))
			visible = false
