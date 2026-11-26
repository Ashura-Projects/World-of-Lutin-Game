class_name ResourcesPanel
extends PanelContainer
## Menu Ressources : tout ce qui est en réserve, rangé par catégories (onglets), avec la variation de la veille.

const CATEGORIES := [
	["all", "Tout"],
	["food", "Nourriture"],
	["raw", "Matières"],
	["processed", "Transformé"],
	["tool", "Outils"],
	["weapon", "Armes"],
	["furniture", "Meubles"],
	["medicine", "Remèdes"],
	["currency", "Monnaie"]
]

var game: Node
var category: String = "all"
var _tabs: Dictionary = {}
var _grid: GridContainer
var _total: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1000, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiStyle.title_label("Ressources", 30))
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	v.add_child(tabs)
	for c: Array in CATEGORIES:
		var b := Button.new()
		b.text = c[1]
		b.custom_minimum_size = Vector2(0, 48)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(open.bind(str(c[0])))
		tabs.add_child(b)
		_tabs[c[0]] = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(980, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_grid)
	_total = Label.new()
	_total.add_theme_color_override("font_color", UiStyle.TXT_D)
	v.add_child(_total)


func open(cat: String = "") -> void:
	if cat != "":
		category = cat
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == category else UiStyle.IRON_L))
	refresh()


func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var st: Stockpile = game.colony.stock
	var delta: Dictionary = game.sim.village.daily_delta
	var ids: Array = st.items.keys()
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			return str(Stockpile._resource(a).get("name", a)) < str(Stockpile._resource(b).get("name", b))
	)
	var n := 0
	for id: String in ids:
		var r := Stockpile._resource(id)
		if st.count(id) <= 0 or (category != "all" and str(r.get("category", "")) != category):
			continue
		var l := Label.new()
		var d := int(delta.get(id, 0))
		l.text = "%s : %d%s" % [r.get("name", id), st.count(id), "  (%+d)" % d if d != 0 else ""]
		l.custom_minimum_size = Vector2(310, 0)
		l.add_theme_font_size_override("font_size", 19)
		_grid.add_child(l)
		n += 1
	_total.text = (
		"%d sorte(s) d'objets · nourriture totale : %d" % [n, st.food_total()] if n > 0 else "Rien en réserve ici."
	)


func _process(_d: float) -> void:
	if visible and Engine.get_process_frames() % 30 == 0:
		refresh()
