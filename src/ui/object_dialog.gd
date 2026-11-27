class_name ObjectDialog
extends PanelContainer
## Dialogue d'un objet touché dans le monde : animal (PV, infos, Chasser / Capturer / Monter), herse ou
## pont-levis (ouvrir, fermer, cadenas), lit et chambre (attribuer à des lutins), autres objets (démonter).

var game: Node
var _title: Label
var _body: VBoxContainer
var _kind: String = ""
var _ref: Variant = null


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
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	v.add_child(_body)
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
	if d.get("npc", false) and float(a.get("faith", 0)) >= 100.0:
		_button(row, "Recruter", func() -> void: _say("Recruté !" if game.sim.religion.recruit(a) != null else ""))
	visible = true


func _hunt(a: Dictionary) -> void:
	var id: int = game.board.add_hunt(a["id"])
	_say("Ordre de chasse donné aux chasseurs." if id >= 0 else "Déjà chassé.")


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
	if g["kind"] == "portcullis":
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
	if g["locked"]:
		_label("Verrouillé : impossible de le manœuvrer tant que le cadenas est mis.", 17, UiStyle.TXT_D)
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


func _remove(s: Dictionary) -> void:
	TaskCancel.remove_structure_at(game.board, s["cell"])
	visible = false
