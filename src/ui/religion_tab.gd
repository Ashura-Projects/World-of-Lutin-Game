class_name ReligionTab
extends RefCounted
## Onglet « Religion » du menu Royaume : lieux de culte, foi, clergé (ordonner, promouvoir, envoyer prêcher),
## religion personnalisée (avec un cardinal et un chef de culte), convertis à recruter, couples mariés.


static func fill(p: RealmPanel) -> void:
	var game: Node = p.game
	var rel: Religion = game.sim.religion
	var cfg := DataRegistry.get_table("religion")
	p._label("%s — symbole : %s" % [rel.name, rel.symbol], 26, UiStyle.GOLD)
	var dn := []
	for d: Dictionary in cfg.get("dogmas", []):
		if rel.dogmas.has(d["id"]):
			dn.append("%s (%s)" % [d["name"], d["desc"]])
	p._label(
		(
			"Dogmes : "
			+ (
				", ".join(dn)
				if not dn.is_empty()
				else "aucun (religion personnalisable avec un cardinal et un chef de culte)"
			)
		),
		18
	)
	var faith := 0.0
	for l: Lutin in game.colony.lutins:
		faith += l.faith
	faith /= maxf(1.0, game.colony.lutins.size())
	var couples: int = game.colony.lutins.filter(func(l: Lutin) -> bool: return l.sex == "f" and l.spouse >= 0).size()
	p._label(
		(
			"Chapelles %d · Églises %d · Cathédrales %d — %d fidèles par office · Foi moyenne %d %% · Couples mariés %d"
			% [
				rel.temples().count("chapel_room"),
				rel.temples().count("church_room"),
				rel.temples().count("cathedral_room"),
				rel.capacity(),
				int(faith),
				couples
			]
		),
		19
	)
	if not rel.has_temple():
		(
			p
			. _label(
				(
					"Lieu de culte = pièce fermée : chapelle (2 bancs d'église, 1 pupitre, 1 autel) ; église (6 bancs, "
					+ "pupitre, autel, 1 vitrail) ; cathédrale (12 bancs, pupitre, autel, cloche, 4 vitraux). Voir ⚙ › Guide."
				),
				18,
				UiStyle.TXT_D
			)
		)
	_clergy(p, game, rel)
	if rel.can_customize():
		_customize(p, rel, cfg)
	_converts(p, rel)


static func _clergy(p: RealmPanel, game: Node, rel: Religion) -> void:
	p._label("Clergé", 22, UiStyle.GOLD)
	for id: int in rel.clergy:
		var l := game.colony.find_lutin(id) as Lutin
		if l == null:
			continue
		var row := p._row()
		var lab := Label.new()
		var where := ""
		if rel.preachers.has(id):
			where = " — prêche chez %s" % Rivals.def(rel.preachers[id]).get("name", rel.preachers[id])
		lab.text = "%s — %s%s" % [l.name, rel.rank_name(rel.clergy[id]), where]
		lab.custom_minimum_size = Vector2(430, 0)
		row.add_child(lab)
		p._button(
			row,
			"Promouvoir",
			func() -> void: p._do(rel.promote(l), "Déjà au plus haut rang (un seul chef de culte)."),
			170
		)
		if rel.preachers.has(id):
			p._button(row, "Rappeler", func() -> void: _act(p, func() -> void: rel.recall(l)), 140)
		elif Realm.active != null:
			for f: Dictionary in Realm.active.neighbours():
				var fid: String = f["id"]
				if Realm.active.status(fid) in ["war", "conquered"]:
					continue
				p._button(
					row,
					"Prêcher : " + str(f["name"]).split(" ")[-1],
					func() -> void: p._do(rel.send_preacher(l, fid), ""),
					200
				)
	if rel.has_temple():
		var row2 := p._row()
		var pick := OptionButton.new()
		pick.custom_minimum_size = Vector2(320, 46)
		for l: Lutin in game.colony.lutins:
			if l.can_work() and not rel.clergy.has(l.id) and l.jailed.y < 0:
				pick.add_item(l.name, l.id)
		row2.add_child(pick)
		p._button(
			row2,
			"Ordonner prêtre",
			func() -> void:
				if pick.item_count > 0:
					p._do(
						rel.ordain(game.colony.find_lutin(pick.get_selected_id())), "Impossible (formation ou métier)."
					),
			240
		)


static func _act(p: RealmPanel, cb: Callable) -> void:
	cb.call()
	p._rebuild()


static func _customize(p: RealmPanel, rel: Religion, cfg: Dictionary) -> void:
	p._label("Personnaliser la religion", 22, UiStyle.GOLD)
	var row := p._row()
	var name := LineEdit.new()
	name.text = rel.name
	name.custom_minimum_size = Vector2(380, 46)
	row.add_child(name)
	var syms: Array = cfg.get("symbols", ["soleil"])
	var sym := Button.new()
	sym.text = "Symbole : %s" % rel.symbol
	sym.custom_minimum_size = Vector2(260, 46)
	sym.pressed.connect(
		func() -> void:
			var i := syms.find(sym.text.trim_prefix("Symbole : "))
			sym.text = "Symbole : %s" % syms[(i + 1) % syms.size()]
	)
	row.add_child(sym)
	var checks := {}
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(1000, 0)
	p._body.add_child(flow)
	for d: Dictionary in cfg.get("dogmas", []):
		var c := CheckBox.new()
		c.text = "%s — %s" % [d["name"], d["desc"]]
		c.button_pressed = rel.dogmas.has(d["id"])
		c.add_theme_font_size_override("font_size", 17)
		flow.add_child(c)
		checks[d["id"]] = c
	var row2 := p._row()
	p._button(
		row2,
		"Valider la religion",
		func() -> void:
			var chosen := []
			for k: String in checks:
				if checks[k].button_pressed:
					chosen.append(k)
			p._do(rel.customize(name.text, sym.text.trim_prefix("Symbole : "), chosen), ""),
		300
	)


static func _converts(p: RealmPanel, rel: Religion) -> void:
	var list := rel.converts()
	if list.is_empty():
		p._label("Pas encore de converti à 100 % : envoyez des prêtres prêcher chez les voisins.", 18, UiStyle.TXT_D)
		return
	p._label("Convertis prêts à vous rejoindre", 22, UiStyle.GOLD)
	for a: Dictionary in list:
		var row := p._row()
		var lab := Label.new()
		lab.text = "%s (%s) — foi 100 %%" % [a.get("name", "?"), Rivals.def(str(a.get("faction", ""))).get("name", "?")]
		lab.custom_minimum_size = Vector2(500, 0)
		row.add_child(lab)
		p._button(row, "Recruter", func() -> void: p._do(rel.recruit(a) != null, ""), 180)
