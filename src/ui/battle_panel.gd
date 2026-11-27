class_name BattlePanel
extends PanelContainer
## Mode Bataille (1.4) : choisir son camp (alliés / ennemis), le type de combattant et le nombre (1, 5, 10), puis
## toucher la carte pour les poser. Les forces en présence s'affichent ; « Retirer les ennemis » nettoie le terrain.
## Unités : « Former une unité » regroupe les soldats posés sans unité (type selon leurs armes) ; chaque unité
## se commande (barre d'ordres), se gère (armes, chevaux, rôles, sous-unités) ou se dissout ici même.

const COUNTS := [1, 5, 10]

var game: Node
var side: String = "ally"
var kind: String = "fusilier"
var count: int = 5
var _body: VBoxContainer
var _info: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	add_child(v)
	var t := UiStyle.title_label("Bataille", 22)
	v.add_child(t)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	v.add_child(_body)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 16)
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	v.add_child(_info)
	refresh()


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var r1 := _flow()
	_btn(r1, "Alliés", func() -> void: _pick("side", "ally"), 130, side == "ally")
	_btn(r1, "Ennemis", func() -> void: _pick("side", "enemy"), 130, side == "enemy")
	for n: int in COUNTS:
		_btn(r1, "×%d" % n, func() -> void: _pick("count", n), 60, count == n)
	var r2 := _flow()
	if side == "ally":
		for k: String in Battle.ALLIES:
			_btn(r2, str(Battle.ALLIES[k]["name"]), func() -> void: _pick("kind", k), 130, kind == k)
	else:
		for k: String in Battle.enemies():
			var nm := str(game.sim.fauna.def(k).get("name", k))
			_btn(r2, nm, func() -> void: _pick("kind", k), 130, kind == k)
	var r3 := _flow()
	_btn(r3, "Retirer les ennemis", func() -> void: Battle.clear_enemies(game.sim), 220)
	_btn(r3, "⚑ Former une unité", _form_unit, 220)
	_btn(r3, "Militaire…", func() -> void: game.hud.menu_button("Militaire").button_pressed = true, 150)
	for u: Dictionary in game.sim.units.units.values():
		var uid: int = u["id"]
		var r4 := _flow()
		var l := Label.new()
		l.text = "%s · %s · %d" % [u["name"], UnitSetup.type_name(u), u["members"].size()]
		l.custom_minimum_size = Vector2(220, 0)
		r4.add_child(l)
		_btn(r4, "⚑", func() -> void: game.hud.unit_bar.open(uid), 54)
		_btn(r4, "⚙", func() -> void: game.hud.unit_editor.open(uid), 54)
		_btn(
			r4,
			"✕",
			func() -> void:
				game.sim.units.disband(uid)
				refresh(),
			54
		)
	var f := Battle.forces(game.sim)
	_info.text = "Touchez la carte pour poser. Vos soldats : %d · Ennemis : %d" % [f[0], f[1]]


func _pick(key: String, v: Variant) -> void:
	match key:
		"side":
			side = str(v)
			kind = "fusilier" if side == "ally" else str(Battle.enemies()[0])
		"kind":
			kind = str(v)
		"count":
			count = int(v)
	refresh()


## Regroupe en une unité tous les soldats sans unité ; le type suit le dernier type posé.
func _form_unit() -> void:
	var free: Array = game.colony.lutins.filter(func(l: Lutin) -> bool: return l.unit_id < 0 and l.can_work())
	if free.is_empty():
		EventBus.alert.emit("info", "Tous les soldats sont déjà en unité.")
		return
	var ids: Array = free.map(func(l: Lutin) -> int: return l.id)
	var uid: int = game.sim.units.create("Unité %d" % game.sim.units.next_id, ids[0], ids.slice(1))
	var t := {"fusilier": "fusiliers", "lancer": "lancers", "swordsman": "swords", "rider": "cavalry"}
	var u: Dictionary = game.sim.units.units[uid]
	u["type"] = str(t.get(kind, "mixed"))
	refresh()
	game.hud.unit_bar.open(uid)


## Toucher la carte : pose les combattants choisis.
func on_tap(screen: Vector2) -> void:
	var cell: Vector3i = game.hud.windows.ground_cell(screen)
	if cell.y < 0:
		return
	if side == "ally":
		Battle.place_allies(game.sim, kind, cell, count)
	else:
		Battle.place_enemies(game.sim, kind, cell, count)
	game.click_marker.show_at(Vector3(cell) + Vector3(0.5, 0, 0.5), "60a0ff" if side == "ally" else "e04030")
	refresh()


func _flow() -> HFlowContainer:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 4)
	h.custom_minimum_size = Vector2(540, 0)
	_body.add_child(h)
	return h


func _btn(row: Control, t: String, cb: Callable, w: int, on: bool = false) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 44)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	if on:
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
	row.add_child(b)
	return b
