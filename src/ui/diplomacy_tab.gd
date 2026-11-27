class_name DiplomacyTab
extends RefCounted
## Onglet « Diplomatie » du menu Royaume (1.4) : diplomate du royaume (charisme, Diplomatie, puissance), puis pour
## chaque voisin rencontré une jauge de relation en 7 niveaux et les actions que le diplomate maîtrise
## (cadeaux, banquet, commerce, pacte, tribut, alliance, intrigues…), plus paix et guerre.


static func fill(p: RealmPanel) -> void:
	var r: Realm = p._realm()
	var d := Diplomacy.diplomat(r)
	var row := p._row()
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(380, 46)
	pick.add_item("— pas de diplomate —", 0)
	for l: Lutin in r.colony.lutins:
		if l.can_work() and l.jailed.y < 0:
			pick.add_item(
				(
					"%s%s · charisme %d · Diplomatie %d"
					% [
						l.name,
						" (diplomate)" if l.job == "diplomat" else "",
						int(l.aptitudes.get("charisma", 0)),
						Soldiering.skill_level(l, "diplomacy")
					]
				),
				l.id + 1
			)
			if l.id == r.diplomat_id:
				pick.select(pick.item_count - 1)
	pick.item_selected.connect(
		func(i: int) -> void:
			r.diplomat_id = pick.get_item_id(i) - 1
			p._rebuild.call_deferred()
	)
	var lab := Label.new()
	lab.text = "Diplomate : "
	row.add_child(lab)
	row.add_child(pick)
	p._label(
		(
			"Puissance diplomatique ×%.2f — %s"
			% [
				Diplomacy.power(r),
				"chaque niveau de Diplomatie débloque des actions" if d != null else "sans diplomate, effets réduits"
			]
		),
		17,
		UiStyle.TXT_D
	)
	if r.neighbours().is_empty():
		p._label("Aucun voisin rencontré : explorez la carte (éclaireurs) pour les trouver.", 20)
	var acts := Diplomacy.actions(r)
	for f: Dictionary in r.neighbours():
		_faction(p, r, f, acts)


static func _faction(p: RealmPanel, r: Realm, f: Dictionary, acts: Array) -> void:
	var id: String = f["id"]
	var lv := Diplomacy.level(r, id)
	p._label("%s — %s" % [f["name"], f.get("desc", "")], 21, UiStyle.GOLD)
	var row := p._row()
	var bar := ProgressBar.new()
	bar.min_value = -100
	bar.max_value = 100
	bar.value = r.relation(id)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(300, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(str(lv.get("color", "a0a0a0")))
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var info := Label.new()
	info.text = "  %s (%d) · %s" % [lv.get("name", "?"), int(r.relation(id)), r.status_name(id)]
	if bool(r.relations.get(id, {}).get("pact", false)):
		info.text += " · pacte"
	if Rivals.active != null and Rivals.active.states.has(id):
		var st: Dictionary = Rivals.active.states[id]
		info.text += " · %d habitants, %d soldats" % [int(st["population"]), int(st["soldiers"])]
		if st.get("peace_offer", false):
			info.text += " · PROPOSE LA PAIX"
	info.add_theme_color_override("font_color", Color(str(lv.get("color", "a0a0a0"))))
	row.add_child(info)
	if r.status(id) == "conquered":
		return
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(1000, 0)
	p._body.add_child(flow)
	for a: Dictionary in acts:
		var aid: String = a["id"]
		p._button(flow, str(a["name"]), func() -> void: _act(p, r, id, aid), 220)
	for e: Array in [["peace", "Paix"], ["war", "Guerre"]]:
		var act: String = e[0]
		p._button(flow, e[1], func() -> void: p._diplo(id, act), 120)


static func _act(p: RealmPanel, r: Realm, id: String, aid: String) -> void:
	var other := ""
	if aid == "incite":
		for f: Dictionary in r.neighbours():
			if f["id"] != id:
				other = f["id"]
				break
	var m := Diplomacy.act(r, id, aid, other)
	p._rebuild()
	p._msg.text = m
