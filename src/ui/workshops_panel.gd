class_name WorkshopsPanel
extends PanelContainer
## Menu Gestion : ateliers construits, leurs commandes (« faire N » / « garder N ») et le panneau d'affectation
## lutin → bâtiment (l'outil est pris automatiquement), mode auto par bâtiment.

var game: Node
var _list: VBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiStyle.title_label("Ateliers et affectation", 30))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 420)
	v.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(860, 0)
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var prod: Production = game.production
	var stations := prod.stations()
	if stations.is_empty():
		var l := Label.new()
		l.text = "Aucun atelier construit (Construire → établi, moulin, four, puits…)."
		_list.add_child(l)
	for s: Dictionary in stations:
		var d := Structures.def(s["kind"])
		var box := VBoxContainer.new()
		_list.add_child(box)
		var head := HBoxContainer.new()
		box.add_child(head)
		var staff: Array = prod.staff.get(s["id"], [])
		var t := UiStyle.title_label(
			"%s  (%d/%d postes)" % [d.get("name", s["kind"]), staff.size(), int(d.get("staff", 1))], 22
		)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		var auto := Button.new()
		auto.text = "Auto : %s" % ("oui" if prod.auto.get(s["id"], false) else "non")
		auto.custom_minimum_size = Vector2(130, 46)
		var sid: int = s["id"]
		auto.pressed.connect(_toggle_auto.bind(sid))
		head.add_child(auto)
		var people := HFlowContainer.new()
		box.add_child(people)
		for l: Lutin in game.colony.lutins:
			var b := Button.new()
			var on := staff.has(l.id)
			b.text = "%s%s" % [l.name, " ✓" if on else ""]
			b.add_theme_font_size_override("font_size", 16)
			if on:
				b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
			b.pressed.connect(_toggle_staff.bind(sid, l, on))
			people.add_child(b)
		var recs := HFlowContainer.new()
		box.add_child(recs)
		for r: Dictionary in Production.recipes_for(d.get("station", "")):
			var cur := _order_of(prod, sid, r["id"])
			var rb := Button.new()
			var state := "—"
			if not cur.is_empty():
				state = "garder %d" % int(cur["n"])
			rb.text = "%s : %s" % [str(r.get("name", r["id"])), state]
			rb.add_theme_font_size_override("font_size", 16)
			rb.pressed.connect(_on_recipe.bind(sid, str(r["id"])))
			recs.add_child(rb)


func _toggle_auto(sid: int) -> void:
	game.production.auto[sid] = not game.production.auto.get(sid, false)
	refresh()


func _toggle_staff(sid: int, l: Lutin, on: bool) -> void:
	if on:
		game.production.staff[sid].erase(l.id)
	else:
		game.production.assign_staff(sid, l)
	refresh()


func _on_recipe(sid: int, rid: String) -> void:
	_bump(game.production, sid, rid)
	refresh()


static func _order_of(prod: Production, sid: int, rid: String) -> Dictionary:
	for o: Dictionary in prod.orders.get(sid, []):
		if o["recipe"] == rid:
			return o
	return {}


## Chaque tap : garder 5 → 10 → 20 → 50 en stock → arrêt.
func _bump(prod: Production, sid: int, rid: String) -> void:
	var o := _order_of(prod, sid, rid)
	var steps := [5, 10, 20, 50]
	if o.is_empty():
		prod.add_order(sid, rid, "keep", 5)
		return
	var i := steps.find(int(o["n"]))
	if i < 0 or i >= steps.size() - 1:
		prod.orders[sid].erase(o)
	else:
		o["n"] = steps[i + 1]
