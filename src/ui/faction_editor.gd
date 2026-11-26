class_name FactionEditor
extends PanelContainer
## Éditeur de faction : nom, devise, couleurs, forme et partition de l'écu, symbole — aperçu en direct.

signal done(f: Faction)

var faction: Faction
var _preview: Emblem
var _labels: Dictionary = {}
var _name: LineEdit
var _motto: LineEdit


func setup(f: Faction) -> void:
	faction = f
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	h.add_child(left)
	left.add_child(UiStyle.title_label("Faction", 30))
	_name = _line(left, "Nom", f.name, int(DataRegistry.get_table("faction").get("name_max", 28)))
	_motto = _line(left, "Devise", f.motto, int(DataRegistry.get_table("faction").get("motto_max", 40)))
	for row: Array in [
		["color1", "Couleur principale"],
		["color2", "Seconde couleur"],
		["symbol_color", "Couleur du symbole"],
		["shape", "Forme"],
		["division", "Partition"],
		["symbol", "Symbole"]
	]:
		_cycler(left, row[0], row[1])
	var ok := Button.new()
	ok.text = "Valider"
	ok.custom_minimum_size = Vector2(260, 58)
	UiStyle.make_primary(ok)
	ok.pressed.connect(_validate)
	left.add_child(ok)
	var right := VBoxContainer.new()
	h.add_child(right)
	_preview = Emblem.new()
	_preview.custom_minimum_size = Vector2(240, 290)
	right.add_child(_preview)
	_refresh()


func _line(parent: Control, label: String, value: String, max_len: int) -> LineEdit:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	var e := LineEdit.new()
	e.text = value
	e.max_length = max_len
	e.custom_minimum_size = Vector2(380, 50)
	e.text_changed.connect(func(_t: String) -> void: _refresh())
	row.add_child(e)
	return e


func _cycler(parent: Control, field: String, label: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	for step: int in [-1, 1]:
		var b := Button.new()
		b.text = "◀" if step < 0 else "▶"
		b.custom_minimum_size = Vector2(56, 48)
		b.pressed.connect(_cycle.bind(field, step))
		row.add_child(b)
		if step < 0:
			var v := Label.new()
			v.custom_minimum_size = Vector2(170, 0)
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(v)
			_labels[field] = v


func _cycle(field: String, step: int) -> void:
	faction.cycle(field, step)
	_refresh()


static func _entry_name(list_key: String, id: String) -> String:
	for e: Dictionary in DataRegistry.get_table("faction").get(list_key, []):
		if e["id"] == id:
			return e["name"]
	return id


func _refresh() -> void:
	faction.set_name_text(_name.text)
	faction.set_motto_text(_motto.text)
	for field: String in _labels:
		var v: String = faction.get(field)
		var lab: Label = _labels[field]
		if field in ["color1", "color2", "symbol_color"]:
			lab.text = "■■■■"
			lab.add_theme_color_override("font_color", Color(v))
		else:
			lab.text = _entry_name({"shape": "shapes", "division": "divisions", "symbol": "symbols"}[field], v)
	_preview.show_faction(faction)


func _validate() -> void:
	_refresh()
	done.emit(faction)
	visible = false
