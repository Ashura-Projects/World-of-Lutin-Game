class_name StoreFilterPanel
extends PanelContainer
## Ce que garde une réserve : tout, ou des catégories entières, ou des objets précis (au choix, simple).

var game: Node
var zone_id: int = -1
var _all: CheckButton
var _cats: Dictionary = {}
var _items: Dictionary = {}
var _box: VBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	position = Vector2(340, 80)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	v.add_child(UiStyle.title_label("Ce que garde cette réserve", 26))
	_all = CheckButton.new()
	_all.text = "Tout accepter"
	_all.toggled.connect(func(on: bool) -> void: _box.modulate.a = 0.4 if on else 1.0)
	v.add_child(_all)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_box)
	var by_cat := {}
	for r: Dictionary in DataRegistry.get_table("resources").get("resources", []):
		by_cat.get_or_add(str(r.get("category", "raw")), []).append(r)
	for c: Array in ResourcesPanel.CATEGORIES:
		if c[0] == "all" or not by_cat.has(c[0]):
			continue
		var cb := CheckBox.new()
		cb.text = "%s (toute la catégorie)" % c[1]
		cb.add_theme_color_override("font_color", UiStyle.GOLD)
		_box.add_child(cb)
		_cats[c[0]] = cb
		var flow := HFlowContainer.new()
		flow.custom_minimum_size = Vector2(860, 0)
		_box.add_child(flow)
		for r: Dictionary in by_cat[c[0]]:
			var ib := CheckBox.new()
			ib.text = str(r.get("name", r["id"]))
			ib.add_theme_font_size_override("font_size", 16)
			flow.add_child(ib)
			_items[r["id"]] = ib
	var ok := Button.new()
	ok.text = "Valider"
	ok.custom_minimum_size = Vector2(260, 52)
	UiStyle.make_primary(ok)
	ok.pressed.connect(_validate)
	v.add_child(ok)


func open(id: int) -> void:
	var z: Dictionary = game.colony.stores.find(id)
	if z.is_empty():
		return
	zone_id = id
	var f: Dictionary = z["filter"]
	_all.button_pressed = bool(f.get("all", true))
	for k: String in _cats:
		_cats[k].button_pressed = f["cats"].has(k)
	for k: String in _items:
		_items[k].button_pressed = f["items"].has(k)
	_box.modulate.a = 0.4 if _all.button_pressed else 1.0
	visible = true


func _validate() -> void:
	var cats := []
	for k: String in _cats:
		if _cats[k].button_pressed:
			cats.append(k)
	var items := []
	for k: String in _items:
		if _items[k].button_pressed:
			items.append(k)
	var all := _all.button_pressed or (cats.is_empty() and items.is_empty())
	game.colony.stores.set_filter(zone_id, all, cats, items)
	visible = false
	EventBus.alert.emit(
		"info",
		"Réserve réglée : %s." % ("tout" if all else "%d catégorie(s), %d objet(s)" % [cats.size(), items.size()])
	)
