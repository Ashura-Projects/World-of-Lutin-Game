class_name RealmPanel
extends PanelContainer
## Menu Royaume : Faction (emblème, seigneur, garnison, prison), Membres (promouvoir, soldat, cage),
## Diplomatie (voisins), Lois et taxes. Les règles sont dans Realm (src/sim/realm) et data/realm.json.

const TABS := [
	["faction", "Faction"],
	["members", "Membres"],
	["diplomacy", "Diplomatie"],
	["laws", "Lois et taxes"],
	["religion", "Religion"]
]

var game: Node
var tab: String = "faction"
var _tabs: Dictionary = {}
var _body: VBoxContainer
var _msg: Label
var _lord_pick: OptionButton


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(1060, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var t := UiStyle.title_label("Royaume", 30)
	t.custom_minimum_size = Vector2(170, 0)
	head.add_child(t)
	for e: Array in TABS:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(168, 50)
		b.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(b)
		_tabs[e[0]] = b
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 6)
	scroll.add_child(_body)
	_msg = Label.new()
	_msg.add_theme_color_override("font_color", Color("ffd27a"))
	v.add_child(_msg)
	show_tab("faction")


func show_tab(t: String) -> void:
	tab = t
	_msg.text = ""
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	_rebuild()


## Rafraîchi régulièrement : seulement les onglets d'information (pas pendant un choix).
func refresh() -> void:
	if tab in ["members", "diplomacy"] and not get_viewport().gui_get_focus_owner() is LineEdit:
		_rebuild()


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	match tab:
		"faction":
			_faction_tab()
		"members":
			_members_tab()
		"diplomacy":
			_diplomacy_tab()
		"laws":
			_laws_tab()
		"religion":
			ReligionTab.fill(self)


func _realm() -> Realm:
	return game.sim.realm


func _label(text: String, size: int = 20, color: Color = UiStyle.TXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1000, 0)
	_body.add_child(l)
	return l


func _button(row: Control, text: String, cb: Callable, w: float = 160) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 46)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	_body.add_child(h)
	return h


# --- Faction -------------------------------------------------------------------------------------
func _faction_tab() -> void:
	var f: Faction = game.sim.faction
	var r := _realm()
	_label("%s — « %s »" % [f.name, f.motto], 26, UiStyle.GOLD)
	var row := _row()
	_button(row, "Nom, couleurs et emblème", func() -> void: game.hud.open_faction(), 320)
	var lord := game.colony.find_lutin(r.lord_id) as Lutin
	_label("")
	_label(
		(
			"Seigneur : %s. Salle du trône : %s (un trône et un fanion dans une pièce fermée)."
			% [lord.name if lord != null else "aucun", "oui" if r.throne_room_ok() else "non"]
		)
	)
	var row2 := _row()
	_lord_pick = OptionButton.new()
	_lord_pick.custom_minimum_size = Vector2(320, 46)
	for l: Lutin in game.colony.lutins:
		if l.can_work() and l.jailed.y < 0:
			_lord_pick.add_item(l.name, l.id)
	row2.add_child(_lord_pick)
	_button(row2, "Nommer seigneur", _name_lord, 230)
	_label("")
	_label(
		(
			(
				"Soldats : %d / %d places. Garnison : pièce fermée avec au moins 3 lits, un coffre et un râtelier d'armes "
				+ "(1 place par lit). Les soldats libres s'entraînent sur le « Sol d'entraînement » (%d case(s) posée(s))."
			)
			% [r.soldiers().size(), r.garrison_capacity(), r.training_cells.size()]
		)
	)
	_label(
		(
			"Prison : %d cage(s) libre(s), %d prisonnier(s). Cages en bois (on peut s'en évader) ou en fer : menu Meubles."
			% [r.free_cages().size(), r.prisoners().size()]
		)
	)


func _name_lord() -> void:
	if _lord_pick.item_count == 0:
		return
	var l := game.colony.find_lutin(_lord_pick.get_selected_id()) as Lutin
	_msg.text = "" if _realm().set_lord(l) else "Il faut d'abord une salle du trône (trône + fanion, pièce fermée)."
	_rebuild()


# --- Membres -------------------------------------------------------------------------------------
func _members_tab() -> void:
	var r := _realm()
	_label(
		"Promouvoir donne un titre (meilleur moral). Les soldats s'entraînent et défendent le village.",
		18,
		UiStyle.TXT_D
	)
	for l: Lutin in game.colony.lutins:
		var row := _row()
		var lab := Label.new()
		lab.text = "%s — %s — %s" % [l.name, r.title_name(l), LutinSheet.job_name(l.job)]
		lab.custom_minimum_size = Vector2(420, 0)
		lab.add_theme_font_size_override("font_size", 18)
		row.add_child(lab)
		if not l.can_work():
			continue
		_button(row, "▲", func() -> void: _do(r.promote(l, 1) != "", ""), 56)
		_button(row, "▼", func() -> void: _do(r.promote(l, -1) != "", ""), 56)
		if l.job == "soldier":
			_button(row, "Rendre civil", func() -> void: _do(_discharge(l), ""), 170)
		else:
			_button(row, "Soldat", func() -> void: _do(r.enroll(l), "Plus de place : construisez une garnison."), 170)
		if l.jailed.y >= 0:
			_button(row, "Libérer", func() -> void: _do(_free(l), ""), 140)
		else:
			_button(row, "En cage", func() -> void: _do(r.imprison(l), "Il faut une cage libre (menu Meubles)."), 140)


func _discharge(l: Lutin) -> bool:
	_realm().discharge(l)
	return true


func _free(l: Lutin) -> bool:
	_realm().release_prisoner(l)
	return true


func _do(ok: bool, fail_msg: String) -> void:
	_msg.text = "" if ok else fail_msg
	_rebuild()


# --- Diplomatie ----------------------------------------------------------------------------------
func _diplomacy_tab() -> void:
	DiplomacyTab.fill(self)


func _diplo(id: String, act: String) -> void:
	var m := _realm().diplomacy(id, act)
	_rebuild()
	_msg.text = m


func _set_tax(id: String) -> void:
	_realm().tax = id
	_rebuild()


# --- Lois et taxes -------------------------------------------------------------------------------
func _laws_tab() -> void:
	var r := _realm()
	var cfg := DataRegistry.get_table("realm")
	_label("Impôt", 24, UiStyle.GOLD)
	var row := _row()
	for t: Dictionary in cfg.get("tax", {}).get("levels", []):
		var id: String = t["id"]
		var label := "%s (%s or/adulte/j, moral %+d)" % [t["name"], str(t["gold_per_adult_day"]), int(t["mood"])]
		var b := _button(row, label, _set_tax.bind(id), 250)
		if id == r.tax:
			b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
	_label("")
	_label("Lois", 24, UiStyle.GOLD)
	for law: Dictionary in cfg.get("laws", []):
		var c := CheckButton.new()
		c.text = "%s (moral %+d) — %s" % [law["name"], int(law.get("mood", 0)), law["desc"]]
		c.button_pressed = r.law_on(law["id"])
		c.add_theme_font_size_override("font_size", 18)
		var lid: String = law["id"]
		c.toggled.connect(func(_on: bool) -> void: r.toggle_law(lid))
		_body.add_child(c)
	_label("Le moral change au prochain bilan du village.", 17, UiStyle.TXT_D)
