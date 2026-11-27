class_name ObjectDialog
extends PanelContainer
## Dialogue d'un objet touché dans le monde : animal (PV, infos, Chasser / Capturer / Monter), herse ou
## pont-levis (ouvrir, fermer, cadenas), lit et chambre (attribuer à des lutins), autres objets (démonter).

var game: Node
var _title: Label
var _body: VBoxContainer
var _kind: String = ""
var _ref: Variant = null
var _scroll: ScrollContainer


## La fiche grandit avec son contenu, puis défile (jamais plus haute que l'écran).
func _fit() -> void:
	_scroll.custom_minimum_size = Vector2(600, minf(_body.get_combined_minimum_size().y, 520.0))


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(620, 0)
	position = Vector2(20, 130)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_title = UiStyle.title_label("", 28)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	head.add_child(UiStyle.close_button(func() -> void: visible = false))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_scroll.add_child(_body)
	_body.resized.connect(_fit)
	visible = false


func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()


func _label(t: String, size: int = 20, col: Color = UiStyle.TXT) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(580, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	_body.add_child(l)


func _row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	_body.add_child(h)
	return h


func _button(row: Control, t: String, cb: Callable, w: float = 200) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 52)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _reopen() -> void:
	match _kind:
		"animal":
			show_animal(_ref)
		"gate":
			show_gate(_ref)
		"structure":
			show_structure(_ref)
		"flora":
			show_flora(_ref[0], _ref[1])


## Arbre, buisson ou plante : ressources et ordres (couper, cueillir, enlever).
func show_flora(what: String, cell: Vector3i) -> void:
	_kind = "flora"
	_ref = [what, cell]
	_clear()
	var f: Flora = game.flora
	if not {"tree": f.trees, "bush": f.bushes, "herb": f.herbs}[what].has(cell):
		visible = false  # déjà enlevé
		return
	FloraDialog.fill(self, what, cell)
	visible = true


# --- animaux -------------------------------------------------------------------------------------
func show_animal(a: Dictionary) -> void:
	_kind = "animal"
	_ref = a
	_clear()
	var d: Dictionary = game.fauna.def(a["kind"])
	var name := str(a.get("name", "")) if a.has("name") else ""
	_title.text = str(d.get("name", a["kind"])) + (" — " + name if name != "" else "")
	var max_hp := float(d.get("hp", 30)) * (GameRules.get_mult("enemy_hp") if d.get("enemy", false) else 1.0)
	_label("PV : %d / %d" % [int(a["hp"]), int(max_hp)], 22, UiStyle.GOLD)
	var info := []
	if d.get("hostile", false):
		info.append("Dangereux : %d dégâts, portée %.1f" % [int(d.get("damage", 0)), float(d.get("reach", 1))])
	elif d.get("npc", false):
		info.append(
			(
				"Villageois de %s · foi %d %%"
				% [Rivals.def(str(d.get("faction", ""))).get("name", "?"), int(a.get("faith", 0))]
			)
		)
	else:
		info.append("Paisible")
	info.append("Vitesse %.1f" % float(d.get("speed", 1.5)))
	var drop: Dictionary = d.get("drop", {})
	if not drop.is_empty():
		var parts := []
		for k: String in drop:
			parts.append("%d %s" % [int(drop[k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
		info.append("Donne : " + ", ".join(parts))
	if a.get("owned", false):
		var rider := game.colony.find_lutin(int(a.get("rider", -1))) as Lutin
		info.append("À vous" + (" · monté par %s" % rider.name if rider != null else ""))
	_label(" · ".join(info), 19)
	var row := _row()
	if not d.get("npc", false) and not a.get("owned", false):
		_button(row, "Chasser" if not d.get("hostile", false) else "Attaquer", func() -> void: _hunt(a))
	if a["kind"] == "horse":
		if not a.get("owned", false):
			_button(row, "Capturer", func() -> void: _say(Horses.capture(game.sim, a)))
		else:
			_button(row, "Relâcher", func() -> void: _say(Horses.release(game.sim, a)))
	if Livestock.is_livestock(a["kind"]) and a.get("owned", false):
		var prod: Dictionary = d.get("product", {})
		var gives := (
			"donne %s chaque jour" % _names(prod.keys()) if not prod.is_empty() else "viande et peau à l'abattage"
		)
		_label("Élevage · %s · mange : %s" % [gives, _names(d.get("eats_any", []))], 18, UiStyle.TXT_D)
		var row2 := _row()
		_button(row2, "Abattre", func() -> void: _gone(Livestock.slaughter(game.sim, a)), 170)
		_button(
			row2,
			"Vendre (%d or)" % Livestock.sell_price(a["kind"]),
			func() -> void: _gone(Livestock.sell(game.sim, a)),
			220
		)
	if d.get("npc", false) and float(a.get("faith", 0)) >= 100.0:
		_button(row, "Recruter", func() -> void: _say("Recruté !" if game.sim.religion.recruit(a) != null else ""))
	visible = true


func _hunt(a: Dictionary) -> void:
	var id: int = game.board.add_hunt(a["id"])
	_say("Ordre de chasse donné aux chasseurs." if id >= 0 else "Déjà chassé.")


static func _names(ids: Array) -> String:
	var out := []
	for k: String in ids:
		out.append(str(Stockpile._resource(k).get("name", k)).to_lower())
	return ", ".join(out)


## L'animal a disparu (abattu, vendu) : on ferme la fiche.
func _gone(t: String) -> void:
	EventBus.alert.emit("info", t)
	if game.fauna.find(_ref["id"]).is_empty():
		visible = false
	else:
		_reopen.call_deferred()


func _say(t: String) -> void:
	if t != "":
		EventBus.alert.emit("info", t)
	_reopen.call_deferred()


# --- herses et ponts-levis ------------------------------------------------------------------------
func show_gate(g: Dictionary) -> void:
	_kind = "gate"
	_ref = g
	_clear()
	var gates: Gates = game.sim.gates
	_title.text = Gates.name_of(g)
	_label("État : " + gates.state_text(g), 21)
	var row := _row()
	var verb := ""
	if g["kind"] == "door":
		verb = "Fermer" if g["open"] else "Ouvrir"
	elif g["kind"] == "portcullis":
		verb = "Baisser (fermer)" if g["open"] else "Lever (ouvrir)"
	else:
		verb = "Lever (couper)" if g["open"] else "Baisser (passer)"
	var t := _button(row, verb, func() -> void: _act(func() -> void: gates.toggle(g["id"])), 260)
	t.disabled = g["locked"]
	_button(
		row,
		"🔓 Déverrouiller" if g["locked"] else "🔒 Verrouiller",
		func() -> void: _act(func() -> void: gates.set_locked(g["id"], not g["locked"])),
		260
	)
	var row2 := _row()
	_button(row2, "Démonter", func() -> void: _remove_gate(g), 200)
	if g["locked"]:
		_label(
			"Verrouillé : personne ne passe et on ne peut pas le manœuvrer tant que le cadenas est mis.",
			17,
			UiStyle.TXT_D
		)
	visible = true


func _act(cb: Callable) -> void:
	cb.call()
	_reopen.call_deferred()


# --- objets, lits et chambres --------------------------------------------------------------------
func show_structure(s: Dictionary) -> void:
	_kind = "structure"
	_ref = s
	_clear()
	var d := Structures.def(s["kind"])
	_title.text = str(d.get("name", s["kind"]))
	_label("Construit" if s["built"] else "En plan (en attente des bâtisseurs)", 19, UiStyle.TXT_D)
	if s["built"] and int(d.get("sleeps", 0)) > 0:
		_bed(s, d)
	if s["built"] and s["kind"] == "catapult":
		_catapult(s)
	if s["built"] and d.has("station"):
		CraftTab.fill(self, s)
	if s["kind"] == "weapon_rack":
		_rack(s)
	if str(s.get("epitaph", "")) != "":
		_label("Ici repose %s." % s["epitaph"], 20, UiStyle.PARCH)
	var row := _row()
	_button(row, "Démonter", func() -> void: _remove(s), 200)
	visible = true


func _bed(s: Dictionary, d: Dictionary) -> void:
	var col: Colony = game.colony
	var assigned: Array = s.get("assigned", [])
	var who := assigned.map(
		func(id: int) -> String: return col.find_lutin(id).name if col.find_lutin(id) != null else "?"
	)
	_label(
		(
			"Lit pour %d — %s"
			% [int(d["sleeps"]), "libre pour tous" if assigned.is_empty() else "attribué à " + ", ".join(who)]
		),
		20
	)
	var room := RoomDetector.room_at(game.world, game.structures, s["cell"])
	if not room.is_empty():
		var rname := str(DataRegistry.find("rooms", "room_types", room["type"]).get("name", room["type"]))
		_label("Pièce : %s (lit + coffre = chambre)" % rname, 18, UiStyle.TXT_D)
	_label("Attribuer à :", 19, UiStyle.GOLD)
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(580, 0)
	_body.add_child(flow)
	var checks := {}
	for l: Lutin in col.lutins:
		var c := CheckBox.new()
		c.text = l.name
		c.button_pressed = assigned.has(l.id)
		flow.add_child(c)
		checks[l.id] = c
	var row := _row()
	var pick := func() -> Array:
		var ids := []
		for id: int in checks:
			if checks[id].button_pressed:
				ids.append(id)
		return ids
	_button(
		row, "Ce lit", func() -> void: _act(func() -> void: game.structures.assign_bed(s["id"], pick.call(), col)), 160
	)
	if not room.is_empty():
		_button(
			row,
			"Toute la chambre",
			func() -> void: _act(func() -> void: game.structures.assign_room(room["cells"], pick.call(), col)),
			230
		)
	_button(
		row, "Libre pour tous", func() -> void: _act(func() -> void: game.structures.assign_bed(s["id"], [], col)), 200
	)


## Râtelier d'armes : il range les fusils, les lances, ou toutes les armes.
func _rack(s: Dictionary) -> void:
	var st: Stockpile = game.colony.stock
	_label(
		(
			"Armes en réserve : %d fusil(s), %d lance(s), %d épée(s)"
			% [st.count("flintlock"), st.count("spear"), st.count("short_sword")]
		),
		19,
		UiStyle.GOLD
	)
	_label("Ce râtelier accepte :", 18, UiStyle.TXT_D)
	var row := _row()
	for e: Array in [["flintlock", "Fusils"], ["spear", "Lances"], ["all", "Toutes les armes"]]:
		var b := _button(
			row,
			e[1],
			func() -> void:
				s["rack"] = e[0]
				game.structures.changed.emit()
				_reopen.call_deferred(),
			190
		)
		if str(s.get("rack", "all")) == e[0]:
			b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))


func _remove_gate(g: Dictionary) -> void:
	var s: Dictionary = game.structures.items.get(int(g["struct_id"]), {})
	if not s.is_empty():
		_remove(s)
	visible = false


## Catapulte : charger, tirer (toucher la cible), tourner, déplacer (2 lutins).
func _catapult(s: Dictionary) -> void:
	var cat: Catapults = game.sim.catapults
	var cc: Dictionary = DataRegistry.get_table("military")["catapult"]
	var rng: Array = cc.get("range", [8, 45])
	_label(
		(
			"PV %d / %d · Dégâts %d (rayon %.1f) · Portée %d à %d blocs · 2 pierres par tir"
			% [
				int(s.get("hp", cc.get("hp", 200))),
				int(cc.get("hp", 200)),
				int(cc.get("damage", 45)),
				float(cc.get("damage_radius", 2.5)),
				int(rng[0]),
				int(rng[1])
			]
		),
		20,
		UiStyle.GOLD
	)
	_label(
		(
			"État : %s · tir à %d° de chaque côté de l'avant"
			% [
				"chargée" if s.get("loaded", false) else "vide",
				int(DataRegistry.get_table("military")["catapult"].get("arc_deg", 40))
			]
		),
		19
	)
	var row := _row()
	_button(row, "Charger", func() -> void: _say(cat.load(s)), 140)
	_button(
		row,
		"Tirer…",
		func() -> void:
			_pick("Touchez la cible", func(c: Vector3i) -> void: EventBus.alert.emit("info", cat.fire(s, c))),
		140
	)
	_button(row, "⟲", func() -> void: _act(func() -> void: cat.rotate(s, 1)), 70)
	_button(row, "⟳", func() -> void: _act(func() -> void: cat.rotate(s, -1)), 70)
	_button(
		row,
		"Déplacer…",
		func() -> void:
			_pick("Touchez où la pousser", func(c: Vector3i) -> void: EventBus.alert.emit("info", cat.move(s, c))),
		170
	)


func _pick(prompt: String, cb: Callable) -> void:
	visible = false
	game.hud.windows.pick_cell(prompt, cb)


func _remove(s: Dictionary) -> void:
	TaskCancel.remove_structure_at(game.board, s["cell"])
	visible = false
