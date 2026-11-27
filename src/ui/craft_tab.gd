class_name CraftTab
extends RefCounted
## Fiche « Fabrication » d'un atelier touché (forge, métier à tisser, four…) : artisans affectés, nouvelle commande
## (recette, quantité, « faire N » / « garder N en stock » / « en continu ») et file d'attente (▲ ▼ ✕).
## L'atelier fait les commandes dans l'ordre de la file, dès que les matières sont en réserve.

const MODES := [["make", "Faire"], ["keep", "Garder en stock"], ["forever", "En continu"]]

static var _qty: int = 5
static var _mode: int = 0
static var _recipe: Dictionary = {}  # id structure -> recette choisie


static func fill(dlg: ObjectDialog, s: Dictionary) -> void:
	var game: Node = dlg.game
	var prod: Production = game.production
	var d := Structures.def(s["kind"])
	var sid: int = s["id"]
	var recipes := Production.recipes_for(str(d.get("station", "")))
	if recipes.is_empty():
		return
	_staff(dlg, prod, s, d)
	dlg._label("Nouvelle commande", 21, UiStyle.GOLD)
	var row := dlg._row()
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(580, 48)
	pick.add_theme_font_size_override("font_size", 16)
	for i in recipes.size():
		pick.add_item(_recipe_text(recipes[i], game.colony.stock), i)
	pick.selected = clampi(int(_recipe.get(sid, 0)), 0, recipes.size() - 1)
	pick.item_selected.connect(func(i: int) -> void: _recipe[sid] = i)
	row.add_child(pick)
	var row2 := dlg._row()
	dlg._button(row2, MODES[_mode][1], func() -> void: _cycle_mode(dlg), 200)
	dlg._button(row2, "−", func() -> void: _set_qty(dlg, -1), 56)
	var q := Label.new()
	q.text = "∞" if MODES[_mode][0] == "forever" else str(_qty)
	q.custom_minimum_size = Vector2(56, 0)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 22)
	row2.add_child(q)
	dlg._button(row2, "+", func() -> void: _set_qty(dlg, 1), 56)
	var add := dlg._button(
		row2,
		"Ajouter à la file",
		func() -> void:
			var r: Dictionary = recipes[clampi(pick.selected, 0, recipes.size() - 1)]
			prod.add_order(sid, r["id"], MODES[_mode][0], _qty)
			dlg._say(""),
		220
	)
	UiStyle.make_primary(add)
	_queue(dlg, prod, sid)


static func _staff(dlg: ObjectDialog, prod: Production, s: Dictionary, d: Dictionary) -> void:
	var game: Node = dlg.game
	var sid: int = s["id"]
	var staff: Array = prod.staff.get(sid, [])
	var names := staff.map(
		func(id: int) -> String: return game.colony.find_lutin(id).name if game.colony.find_lutin(id) != null else "?"
	)
	dlg._label(
		(
			"Artisans %d/%d : %s"
			% [staff.size(), int(d.get("staff", 1)), ", ".join(names) if not names.is_empty() else "aucun"]
		),
		19,
		UiStyle.GOLD
	)
	var row := dlg._row()
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(250, 48)
	pick.add_theme_font_size_override("font_size", 16)
	for l: Lutin in game.colony.lutins:
		if l.can_work() and not staff.has(l.id):
			pick.add_item("%s (%s)" % [l.name, LutinSheet.job_name(l.job)], l.id)
	row.add_child(pick)
	dlg._button(
		row,
		"Affecter",
		func() -> void:
			if pick.item_count > 0:
				var l := game.colony.find_lutin(pick.get_selected_id()) as Lutin
				var ok := prod.assign_staff(sid, l)
				dlg._say("" if ok else "Poste plein ou pas d'outil en réserve."),
		140
	)
	for id: int in staff:
		var l := game.colony.find_lutin(id) as Lutin
		if l != null:
			dlg._button(
				row,
				"✕ " + l.name,
				func() -> void:
					prod.staff[sid].erase(id)
					dlg._say(""),
				0
			)
	var auto := dlg._button(
		row,
		"Auto : %s" % ("oui" if prod.auto.get(sid, false) else "non"),
		func() -> void:
			prod.auto[sid] = not prod.auto.get(sid, false)
			dlg._say(""),
		140
	)
	auto.tooltip_text = "Auto : un lutin libre prend le poste tout seul"


static func _queue(dlg: ObjectDialog, prod: Production, sid: int) -> void:
	var q: Array = prod.orders.get(sid, [])
	dlg._label("File d'attente (%d)" % q.size(), 21, UiStyle.GOLD)
	if q.is_empty():
		dlg._label("Rien à faire : ajoutez une commande.", 17, UiStyle.TXT_D)
		return
	var st: Stockpile = dlg.game.colony.stock
	for i in q.size():
		var o: Dictionary = q[i]
		var r := Production.recipe(o["recipe"])
		var what := str(r.get("name", o["recipe"]))
		var how := ""
		match str(o["mode"]):
			"make":
				how = "faire %d (%d faits)" % [int(o["n"]), int(o["done"])]
			"keep":
				how = "garder %d en stock" % int(o["n"])
			_:
				how = "en continu"
		var miss := []
		for k: String in r.get("in", {}):
			if st.count(k) < int(r["in"][k]):
				miss.append(str(Stockpile._resource(k).get("name", k)).to_lower())
		var row := dlg._row()
		var lab := Label.new()
		lab.text = (
			"%d. %s — %s%s" % [i + 1, what, how, "  (manque : %s)" % ", ".join(miss) if not miss.is_empty() else ""]
		)
		lab.custom_minimum_size = Vector2(400, 0)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.add_theme_font_size_override("font_size", 16)
		if not miss.is_empty():
			lab.add_theme_color_override("font_color", UiStyle.TXT_D)
		row.add_child(lab)
		dlg._button(row, "▲", func() -> void: _act(dlg, func() -> void: prod.move_order(sid, i, -1)), 50)
		dlg._button(row, "▼", func() -> void: _act(dlg, func() -> void: prod.move_order(sid, i, 1)), 50)
		dlg._button(row, "✕", func() -> void: _act(dlg, func() -> void: prod.remove_order(sid, i)), 50)


static func _act(dlg: ObjectDialog, cb: Callable) -> void:
	cb.call()
	dlg._say("")


static func _recipe_text(r: Dictionary, st: Stockpile) -> String:
	var ins := []
	for k: String in r.get("in", {}):
		ins.append("%d %s" % [int(r["in"][k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
	var outs := []
	for k: String in r.get("out", {}):
		outs.append("%d %s" % [int(r["out"][k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
	var have := ""
	if not r.get("out", {}).is_empty():
		have = "  [%d en réserve]" % st.count(str(r["out"].keys()[0]))
	return (
		"%s : %s → %s%s"
		% [r.get("name", r["id"]), ", ".join(ins) if not ins.is_empty() else "rien", ", ".join(outs), have]
	)


static func _cycle_mode(dlg: ObjectDialog) -> void:
	_mode = (_mode + 1) % MODES.size()
	dlg._say("")


static func _set_qty(dlg: ObjectDialog, d: int) -> void:
	var steps := [1, 2, 5, 10, 20, 50, 100]
	var i := steps.find(_qty)
	_qty = steps[clampi((i if i >= 0 else 2) + d, 0, steps.size() - 1)]
	dlg._say("")
