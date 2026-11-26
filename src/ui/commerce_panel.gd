class_name CommercePanel
extends PanelContainer
## Menu Commerce : quand le marchand est au village, acheter ses marchandises et vendre nos surplus contre de l'or.

var game: Node
var _body: VBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiStyle.title_label("Commerce", 30))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.custom_minimum_size = Vector2(860, 0)
	scroll.add_child(_body)


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var tr: Trade = game.sim.trade
	var st: Stockpile = game.colony.stock
	var head := Label.new()
	_body.add_child(head)
	if not tr.present:
		head.text = (
			"Pas de marchand au village. Prochain passage : jour %d.   Or : %d" % [tr.next_day + 1, st.count("gold")]
		)
		return
	head.text = "Le marchand est là jusqu'au jour %d.   Or du village : %d" % [tr.leaves_day + 1, st.count("gold")]
	_body.add_child(UiStyle.title_label("Acheter", 22))
	for id: String in tr.offers:
		if int(tr.offers[id]) > 0:
			_row(id, "%d dispo · %d or" % [int(tr.offers[id]), tr.buy_price(id)], true)
	_body.add_child(UiStyle.title_label("Vendre", 22))
	for id: String in st.items:
		if tr.sell_price(id) > 0 and id != "gold":
			_row(id, "%d en réserve · %d or" % [st.count(id), tr.sell_price(id)], false)


func _row(id: String, info: String, buying: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_body.add_child(row)
	var l := Label.new()
	l.text = "%s — %s" % [Stockpile._resource(id).get("name", id), info]
	l.custom_minimum_size = Vector2(560, 0)
	row.add_child(l)
	for n: int in [1, 10]:
		var b := Button.new()
		b.text = ("Acheter " if buying else "Vendre ") + str(n)
		b.add_theme_font_size_override("font_size", 16)
		b.custom_minimum_size = Vector2(130, 46)
		b.pressed.connect(_trade.bind(id, n, buying))
		row.add_child(b)


func _trade(id: String, n: int, buying: bool) -> void:
	var tr: Trade = game.sim.trade
	if buying:
		tr.buy(id, n)
	else:
		tr.sell(id, n)
	refresh()
