class_name SettlementsPanel
extends PanelContainer
## Villages et villes (1.4). Onglet Villages : chaque établissement avec ses foyers (qui habite où), ses maisons,
## ses ateliers (qui travaille où, ce qu'ils produisent), ses soldats et unités, ses bâtiments et les règles pour
## devenir une ville. Onglet Habitants : tous les lutins, filtrés par village / ville, métier, soldats et âge.

const AGES := [["", "Tous âges"], ["baby", "Bébés"], ["child", "Enfants"], ["adult", "Adultes"], ["elder", "Anciens"]]

var game: Node
var tab: String = "villages"
var selected: int = -1
var f_place: int = -1
var f_job: String = ""
var f_age: String = ""
var f_soldiers: bool = false
var _body: VBoxContainer
var _tabs: Dictionary = {}


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1100, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var t := UiStyle.title_label("Villages et villes", 28)
	t.custom_minimum_size = Vector2(300, 0)
	head.add_child(t)
	for e: Array in [["villages", "Villages"], ["people", "Habitants"]]:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(170, 48)
		b.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(b)
		_tabs[e[0]] = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1080, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 5)
	scroll.add_child(_body)


func refresh() -> void:
	show_tab(tab)


func open_people() -> void:
	visible = not visible or tab != "people"
	if visible:
		show_tab("people")


func show_tab(t: String) -> void:
	tab = t
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	for c in _body.get_children():
		c.queue_free()
	if t == "villages":
		_villages()
	else:
		_people()


func _st() -> Settlements:
	return game.sim.settlements


func _label(text: String, size: int = 17, c: Color = UiStyle.TXT) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1060, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	_body.add_child(l)


func _row() -> HFlowContainer:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 6)
	_body.add_child(h)
	return h


func _btn(row: Control, t: String, cb: Callable, w: int = 180, on: bool = false) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 44)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	if on:
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
	row.add_child(b)
	return b


# --- villages ------------------------------------------------------------------------------------
func _villages() -> void:
	var st := _st()
	var row := _row()
	for e: Dictionary in st.items:
		var id: int = e["id"]
		var kind := "Ville" if e["kind"] == "city" else "Village"
		_btn(
			row,
			"%s : %s (%d)" % [kind, e["name"], st.residents(e).size()],
			func() -> void:
				selected = id
				refresh(),
			300,
			id == selected
		)
	_label("Fondez un autre village avec une « Balise de village » (Construire › Défense).", 15, UiStyle.TXT_D)
	var e: Dictionary = st.find(selected)
	if e.is_empty() and not st.items.is_empty():
		e = st.items[0]
		selected = e["id"]
	if not e.is_empty():
		_detail(e)


func _detail(e: Dictionary) -> void:
	var st := _st()
	var col: Colony = game.colony
	var name := LineEdit.new()
	name.text = e["name"]
	name.custom_minimum_size = Vector2(380, 44)
	name.text_submitted.connect(func(t: String) -> void: e["name"] = t)
	var r0 := _row()
	r0.add_child(name)
	_btn(r0, "Voir", func() -> void: game.camera.focus(Vector3(e["cell"])), 120)
	var check: Array = st.city_check(e)
	_label("%s — %s" % ["Ville" if e["kind"] == "city" else "Village", "  ".join(check[1])], 16, UiStyle.GOLD)
	_label("Foyers", 20, UiStyle.GOLD)
	for h: Array in st.households(e):
		var names := h.map(func(l: Lutin) -> String: return l.name)
		var home := _home_text(h[0])
		_label("• %s — %s" % [", ".join(names), home], 16)
	_label("Maisons et pièces", 20, UiStyle.GOLD)
	for r: Dictionary in st.rooms(e):
		var rname := str(DataRegistry.find("rooms", "room_types", r["type"]).get("name", r["type"]))
		var who := []
		for b: Dictionary in r["beds"]:
			for l: Lutin in col.lutins:
				if l.home == b["cell"]:
					who.append(l.name)
		_label("• %s%s" % [rname, " — " + ", ".join(who) if not who.is_empty() else ""], 16)
	_label("Ateliers (qui y travaille, ce qui est commandé)", 20, UiStyle.GOLD)
	var prod: Production = game.production
	for s: Dictionary in st.structures_in(e):
		if not s["built"] or not Structures.def(s["kind"]).has("station"):
			continue
		var workers := Array(prod.staff.get(s["id"], [])).map(
			func(id: int) -> String: return col.find_lutin(id).name if col.find_lutin(id) != null else "?"
		)
		var orders := Array(prod.orders.get(s["id"], [])).map(
			func(o: Dictionary) -> String: return str(Production.recipe(o["recipe"]).get("name", o["recipe"]))
		)
		_label(
			(
				"• %s — %s — %s"
				% [
					Structures.def(s["kind"]).get("name", s["kind"]),
					", ".join(workers) if not workers.is_empty() else "personne",
					", ".join(orders) if not orders.is_empty() else "rien de commandé"
				]
			),
			16
		)
	_label("Soldats et unités", 20, UiStyle.GOLD)
	var soldiers := st.residents(e).filter(func(l: Lutin) -> bool: return l.job == "soldier" or l.unit_id >= 0)
	_label(
		"%d soldat(s) : %s" % [soldiers.size(), ", ".join(soldiers.map(func(l: Lutin) -> String: return l.name))], 16
	)
	for u: Dictionary in game.sim.units.units.values():
		var cap := col.find_lutin(int(u["captain"]))
		if cap != null and int(st.of_lutin(cap).get("id", -1)) == int(e["id"]):
			_label("• %s — %s, %d soldats" % [u["name"], UnitSetup.type_name(u), u["members"].size()], 16)
	_label("Bâtiments et objets", 20, UiStyle.GOLD)
	var counts := {}
	for s: Dictionary in st.structures_in(e):
		var n := str(Structures.def(s["kind"]).get("name", s["kind"]))
		counts[n] = int(counts.get(n, 0)) + 1
	_label(", ".join(counts.keys().map(func(k: String) -> String: return "%s ×%d" % [k, counts[k]])), 16)


func _home_text(l: Lutin) -> String:
	if l.home.y < 0:
		return "sans logement"
	var s: Dictionary = game.structures.at(l.home)
	var r := RoomDetector.room_at(game.world, game.structures, l.home)
	var where := str(DataRegistry.find("rooms", "room_types", r["type"]).get("name", "")) if not r.is_empty() else ""
	return "%s%s" % [Structures.def(s.get("kind", "")).get("name", "lit"), " (%s)" % where if where != "" else ""]


# --- habitants -----------------------------------------------------------------------------------
func _people() -> void:
	var st := _st()
	var col: Colony = game.colony
	var r1 := _row()
	_btn(r1, "Partout", func() -> void: _filter("place", -1), 140, f_place < 0)
	for e: Dictionary in st.items:
		var id: int = e["id"]
		_btn(r1, e["name"], func() -> void: _filter("place", id), 200, f_place == id)
	var r2 := _row()
	for a: Array in AGES:
		var aid: String = a[0]
		_btn(r2, a[1], func() -> void: _filter("age", aid), 120, f_age == aid)
	_btn(r2, "Soldats seulement", func() -> void: _filter("soldiers", not f_soldiers), 200, f_soldiers)
	var r3 := _row()
	var jobs := {}
	for l: Lutin in col.lutins:
		jobs[l.job] = true
	_btn(r3, "Tous métiers", func() -> void: _filter("job", ""), 150, f_job == "")
	for j: String in jobs:
		_btn(r3, LutinSheet.job_name(j), func() -> void: _filter("job", j), 140, f_job == j)
	var work := {}
	for sid: int in game.production.staff:
		for lid: int in game.production.staff[sid]:
			work[lid] = Structures.def(game.structures.items.get(sid, {}).get("kind", "")).get("name", "")
	var n := 0
	for l: Lutin in col.lutins:
		var place := st.of_lutin(l)
		if f_place >= 0 and int(place.get("id", -1)) != f_place:
			continue
		if f_age != "" and l.age_stage() != f_age:
			continue
		if f_job != "" and l.job != f_job:
			continue
		if f_soldiers and not (l.job == "soldier" or l.unit_id >= 0):
			continue
		n += 1
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = (
			"%s · %d a. · %s · %s · %s%s"
			% [
				l.name,
				l.age_days / 20,
				LutinSheet.job_name(l.job),
				place.get("name", "hors village"),
				_home_text(l),
				" · travaille : %s" % work[l.id] if work.has(l.id) else ""
			]
		)
		b.add_theme_font_size_override("font_size", 15)
		b.custom_minimum_size = Vector2(1050, 40)
		b.pressed.connect(
			func() -> void:
				visible = false
				game.hud.show_lutin(l)
				game.camera.focus(l.pos)
		)
		_body.add_child(b)
	_label("%d lutin(s)" % n, 16, UiStyle.TXT_D)


func _filter(key: String, v: Variant) -> void:
	match key:
		"place":
			f_place = int(v)
		"age":
			f_age = str(v)
		"job":
			f_job = str(v)
		"soldiers":
			f_soldiers = bool(v)
	refresh()
