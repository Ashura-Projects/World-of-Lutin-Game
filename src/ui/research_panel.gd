class_name ResearchPanel
extends PanelContainer
## Recherche et éducation : technologie en cours, choix de la suivante, cours de l'école, inscription aux formations.

var game: Node
var _body: VBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(880, 0)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiStyle.title_label("Recherche et éducation", 30))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(860, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.custom_minimum_size = Vector2(840, 0)
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)


func _label(t: String, size: int = 19) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	_body.add_child(l)
	return l


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var r: Research = game.sim.research
	var ed: Education = game.sim.education
	var cur := Research.tech(r.current)
	_label("En cours : %s (%d / %d points)" % [cur.get("name", "—"), int(r.points), int(cur.get("cost", 0))])
	var techs := HFlowContainer.new()
	_body.add_child(techs)
	for t: Dictionary in r.available():
		var b := Button.new()
		b.text = "%s (%d)" % [t["name"], int(t["cost"])]
		b.add_theme_font_size_override("font_size", 17)
		if t["id"] == r.current:
			b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
		b.pressed.connect(_choose.bind(str(t["id"])))
		techs.add_child(b)
	var known := []
	for id: String in r.unlocked:
		known.append(Research.tech(id).get("name", id))
	_label("Découvertes : " + (", ".join(known) if not known.is_empty() else "aucune"))
	var fb := Button.new()
	fb.text = "Cours de l'école : %s" % _focus_name(ed.focus)
	fb.pressed.connect(_next_focus)
	_body.add_child(fb)
	_body.add_child(UiStyle.title_label("Formations", 22))
	var centers := []
	for s: Dictionary in game.structures.items.values():
		if s["built"] and Structures.def(s["kind"]).has("training"):
			centers.append(s)
	if centers.is_empty():
		_label("Construisez une bibliothèque, un atelier de maître ou une herboristerie.")
	for l: Lutin in game.colony.lutins:
		if not l.can_work():
			continue
		var row := HBoxContainer.new()
		_body.add_child(row)
		var n := Label.new()
		n.text = (
			"%s (savoir %d, adresse %d)"
			% [l.name, int(l.aptitudes.get("knowledge", 0)), int(l.aptitudes.get("dexterity", 0))]
		)
		n.custom_minimum_size = Vector2(380, 0)
		row.add_child(n)
		if ed.trainees.has(l.id):
			var tl := Label.new()
			tl.text = "en formation (%d j)" % int(ed.trainees[l.id]["days"])
			row.add_child(tl)
			continue
		for s: Dictionary in centers:
			var b := Button.new()
			b.text = "→ %s" % Structures.def(s["kind"]).get("name", s["kind"])
			b.add_theme_font_size_override("font_size", 16)
			b.pressed.connect(_enroll.bind(l, int(s["id"])))
			row.add_child(b)


func _focus_name(id: String) -> String:
	if id == "balanced":
		return "équilibré"
	for c: Dictionary in DataRegistry.get_table("education").get("school", {}).get("courses", []):
		if c["id"] == id:
			return c["name"]
	return id


func _next_focus() -> void:
	var ids := ["balanced"]
	for c: Dictionary in DataRegistry.get_table("education").get("school", {}).get("courses", []):
		ids.append(c["id"])
	var ed: Education = game.sim.education
	ed.focus = ids[(ids.find(ed.focus) + 1) % ids.size()]
	refresh()


func _choose(id: String) -> void:
	game.sim.research.choose(id)
	refresh()


func _enroll(l: Lutin, center_id: int) -> void:
	game.sim.education.enroll(l, center_id)
	refresh()
