class_name GuidePanel
extends PanelContainer
## Guide (menu pause et accueil) : pièces et leurs règles, bâtiments, fenêtres, portes, défense, religion,
## chevaux, conseils. Sommaire à gauche, texte à droite.

var _text: RichTextLabel
var _sections: Array = []


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1200, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiStyle.header("Guide", 30, queue_free))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 4)
	h.add_child(menu)
	_text = RichTextLabel.new()
	_text.custom_minimum_size = Vector2(860, 470)
	_text.bbcode_enabled = true
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.add_theme_color_override("default_color", UiStyle.TXT)
	h.add_child(_text)
	_sections = DataRegistry.get_table("guide").get("sections", [])
	for i in _sections.size():
		var b := Button.new()
		b.text = _sections[i]["title"]
		b.custom_minimum_size = Vector2(300, 44)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(show_section.bind(i))
		menu.add_child(b)
	show_section(0)


func show_section(i: int) -> void:
	var s: Dictionary = _sections[i]
	var t := "[font_size=26][color=#c49e54]%s[/color][/font_size]\n\n%s" % [s["title"], s["text"]]
	if s["id"] == "rooms":
		t += "\n" + room_rules()
	_text.text = t


## Règles des pièces, lues dans data/rooms.json (ce qu'il faut dans une pièce fermée pour chaque type).
static func room_rules() -> String:
	var names := {
		"pew": "banc d'église",
		"seat": "siège ou banc",
		"stained_glass": "vitrail",
		"bed": "lit",
		"storage": "coffre",
		"weapons": "râtelier d'armes",
		"lectern": "pupitre",
		"altar": "autel",
		"bell": "cloche",
		"hearth": "foyer",
		"table": "table",
		"throne": "trône",
		"banner": "fanion",
		"school": "tableau du maître",
		"shelf": "étagère",
		"workstation": "atelier"
	}
	var lines := []
	var types: Array = DataRegistry.get_table("rooms").get("room_types", []).duplicate()
	types.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["priority"]) > int(b["priority"]))
	for r: Dictionary in types:
		if r["id"] == "empty":
			continue
		var need := []
		for tg: String in r.get("requires", []):
			need.append(names.get(tg, tg))
		if r.has("requires_any_tag"):
			need.append(names.get(r["requires_any_tag"], r["requires_any_tag"]))
		var mc: Dictionary = r.get("min_counts", {})
		for tg: String in mc:
			need.append("%d %s" % [int(mc[tg]), names.get(tg, tg)])
		if r.has("min_beds"):
			need.append("au moins %d lits" % int(r["min_beds"]))
		if r.has("max_beds"):
			need.append("au plus %d lits" % int(r["max_beds"]))
		lines.append("• [b]%s[/b] : %s" % [r["name"], ", ".join(need) if not need.is_empty() else "—"])
	return "\n".join(lines)
