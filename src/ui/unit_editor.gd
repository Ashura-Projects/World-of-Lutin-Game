class_name UnitEditor
extends PanelContainer
## Gérer une unité (1.4) : type (mixte, cavalerie, fusiliers, lanciers, épéistes, catapulte), arme et monture de
## toute l'unité, entraînement, cuisinier, lieutenants des sous-unités (une de plus tous les 5 niveaux de
## Commandement), puis chaque soldat : arme, cheval, sous-unité, et ses qualités (force, agilité, robustesse).

var game: Node
var uid: int = -1
var _body: VBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1060, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UiStyle.title_label("Gérer l'unité", 26)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)  # la croix ✕ est ajoutée par HudWindows
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	visible = false


func open(id: int) -> void:
	uid = id
	visible = true
	refresh()


func _units() -> Units:
	return game.sim.units


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var u: Dictionary = _units().units.get(uid, {})
	if u.is_empty():
		visible = false
		return
	var col: Colony = game.colony
	var cap := col.find_lutin(int(u["captain"]))
	_label(
		(
			"%s — %s — commandant %s (Commandement %d) — %d soldats"
			% [
				u["name"],
				UnitSetup.type_name(u),
				cap.name if cap != null else "?",
				Soldiering.skill_level(cap, "command") if cap != null else 0,
				u["members"].size()
			]
		),
		21,
		UiStyle.GOLD
	)
	var row := _row("Type :")
	for t: String in UnitSetup.TYPES:
		var b := _btn(
			row, str(UnitSetup.TYPES[t]["name"]), _do.bind(func() -> void: UnitSetup.set_type(_units(), u, t)), 150
		)
		_mark(b, u["type"] == t)
	row = _row("Arme :")
	for w: Array in UnitSetup.WEAPONS:
		var b := _btn(
			row,
			"%s (%d)" % [w[1], col.stock.count(w[0])] if w[0] != "" else w[1],
			_set_all.bind(u, "weapon", w[0]),
			150
		)
		_mark(b, u["weapon"] == w[0])
	var b1 := _btn(row, "À pied", _set_all.bind(u, "mount", "foot"), 120)
	_mark(b1, u["mount"] == "foot")
	var b2 := _btn(row, "À cheval", _set_all.bind(u, "mount", "horse"), 130)
	_mark(b2, u["mount"] == "horse")
	row = _row("Entraîner :")
	for s: String in Soldiering.STATS:
		var b := _btn(row, str(Soldiering.STAT_NAMES[s]), _do.bind(func() -> void: u["train"] = s), 150)
		_mark(b, u["train"] == s)
	_btn(row, "▶ Aller s'entraîner", _do.bind(func() -> void: _units().command(uid, "train")), 230)
	row = _row("Catapulte :")
	var cat_txt := "aucune"
	if int(u["catapult_id"]) >= 0:
		cat_txt = "servie (n° %d)" % int(u["catapult_id"])
	var lab := Label.new()
	lab.text = cat_txt
	row.add_child(lab)
	_btn(
		row,
		"Prendre la plus proche" if int(u["catapult_id"]) < 0 else "La laisser",
		_do.bind(_toggle_catapult.bind(u)),
		240
	)
	_roles(u)
	_soldiers(u)


func _roles(u: Dictionary) -> void:
	var col: Colony = game.colony
	var n := UnitSetup.max_squads(_units(), u)
	_label("Rôles et sous-unités (%d possibles ; +1 tous les 5 niveaux de Commandement)" % n, 19, UiStyle.GOLD)
	var row := _row("Cuisinier :")
	_pick(row, u, int(u["cook"]), func(lid: int) -> void: UnitSetup.set_cook(u, lid))
	for sq in range(1, n):
		var r := _row("Lieutenant %d :" % sq)
		_pick(
			r, u, UnitSetup.lieutenant_of(u, sq), func(lid: int) -> void: UnitSetup.set_lieutenant(_units(), u, sq, lid)
		)
		var cnt := Array(u["members"]).filter(func(m: int) -> bool: return UnitSetup.squad_of(u, m) == sq).size()
		var l := Label.new()
		l.text = "  %d soldat(s)" % cnt
		r.add_child(l)
	if col == null:
		return


## Liste déroulante des membres (« aucun » = -1) pour un rôle.
func _pick(row: HBoxContainer, u: Dictionary, current: int, cb: Callable) -> void:
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(300, 46)
	o.add_item("— aucun —", 0)
	var i := 1
	for m: int in u["members"]:
		var l := game.colony.find_lutin(m) as Lutin
		if l == null:
			continue
		o.add_item(l.name, m + 1)
		if m == current:
			o.select(i)
		i += 1
	o.item_selected.connect(
		func(idx: int) -> void:
			cb.call(o.get_item_id(idx) - 1)
			refresh.call_deferred()
	)
	row.add_child(o)


func _soldiers(u: Dictionary) -> void:
	_label("Soldats", 19, UiStyle.GOLD)
	var n := UnitSetup.max_squads(_units(), u)
	for m: int in u["members"]:
		var l := game.colony.find_lutin(m) as Lutin
		if l == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		_body.add_child(row)
		var name := Label.new()
		var role := ""
		if int(u["captain"]) == m:
			role = " ★"
		elif int(u["cook"]) == m:
			role = " (cuisinier)"
		name.text = (
			"%s%s — F%d A%d R%d · PV %d/%d"
			% [
				l.name,
				role,
				Soldiering.drill_level(l, "force"),
				Soldiering.drill_level(l, "agility"),
				Soldiering.drill_level(l, "robust"),
				int(l.hp),
				int(Soldiering.max_hp(l))
			]
		)
		name.custom_minimum_size = Vector2(380, 0)
		name.add_theme_font_size_override("font_size", 16)
		row.add_child(name)
		var w := OptionButton.new()
		w.custom_minimum_size = Vector2(170, 44)
		w.add_item("Arme : unité", 0)
		for i in range(1, UnitSetup.WEAPONS.size()):
			w.add_item(str(UnitSetup.WEAPONS[i][1]), i)
		var g: Dictionary = u["gear"].get(m, {})
		if g.has("weapon"):
			for i in range(1, UnitSetup.WEAPONS.size()):
				if UnitSetup.WEAPONS[i][0] == g["weapon"]:
					w.select(i)
		w.item_selected.connect(
			func(i: int) -> void:
				UnitSetup.set_gear(_units(), u, m, "weapon", "default" if i == 0 else str(UnitSetup.WEAPONS[i][0]))
				refresh.call_deferred()
		)
		row.add_child(w)
		var mt := OptionButton.new()
		mt.custom_minimum_size = Vector2(160, 44)
		for e: Array in [["default", "Monture : unité"], ["foot", "À pied"], ["horse", "À cheval"]]:
			mt.add_item(e[1])
			if str(g.get("mount", "default")) == e[0]:
				mt.select(mt.item_count - 1)
		mt.item_selected.connect(
			func(i: int) -> void:
				UnitSetup.set_gear(_units(), u, m, "mount", ["default", "foot", "horse"][i])
				refresh.call_deferred()
		)
		row.add_child(mt)
		var sq := OptionButton.new()
		sq.custom_minimum_size = Vector2(150, 44)
		for s in n:
			sq.add_item("Commandant" if s == 0 else "Sous-unité %d" % s, s)
		sq.select(mini(UnitSetup.squad_of(u, m), n - 1))
		sq.item_selected.connect(
			func(i: int) -> void:
				UnitSetup.set_squad(_units(), u, m, i)
				refresh.call_deferred()
		)
		row.add_child(sq)


func _set_all(u: Dictionary, key: String, value: String) -> void:
	u[key] = value
	if key == "weapon":
		u["type"] = "mixed" if value == "" else u["type"]
	UnitSetup.apply(_units(), u)
	refresh()


func _toggle_catapult(u: Dictionary) -> void:
	if int(u["catapult_id"]) >= 0:
		u["catapult_id"] = -1
	else:
		u["catapult_id"] = UnitSetup._free_catapult(_units(), u)
		if int(u["catapult_id"]) < 0:
			EventBus.alert.emit("alerte", "Aucune catapulte libre (Construire › Défense).")


func _do(cb: Callable) -> void:
	cb.call()
	refresh()


func _label(t: String, size: int = 18, c: Color = UiStyle.TXT) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	_body.add_child(l)


func _row(title: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	_body.add_child(h)
	return h


func _btn(row: HBoxContainer, t: String, cb: Callable, w: int) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _mark(b: Button, on: bool) -> void:
	if on:
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
