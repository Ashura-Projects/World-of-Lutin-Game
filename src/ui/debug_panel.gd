class_name DebugPanel
extends PanelContainer
## Menu débug (activé par 5 touchers dans le coin droit de l'accueil) : ressources, apparitions à l'endroit
## regardé, temps, mode dieu, construction libre, monde. En bas : « Désactiver le menu débug ».

var game: Node
var _body: VBoxContainer
var _msg: Label
var extra_sections: Array = []  # [[titre, [[texte, Callable], …]], …] ajoutées par d'autres systèmes


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.1, 0.05, 0.05, 0.96), Color("e05050"), 3, 10))
	custom_minimum_size = Vector2(1100, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	v.add_child(UiStyle.title_label("Menu débug", 30, Color("ff8a7a")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1080, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_msg = Label.new()
	_msg.add_theme_color_override("font_color", Color("ffd27a"))
	v.add_child(_msg)
	refresh()


func _sim() -> GameSim:
	return game.sim


func _here() -> Vector3i:
	var t: Vector3 = game.camera.target
	return Vector3i(int(t.x), game.world.surface_y(int(t.x), int(t.z)), int(t.z))


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var r: GameRules = _sim().rules
	_section(
		"Ressources",
		[
			["+100 de base", func() -> void: DebugTools.add_resources(_sim(), 100)],
			["+500 or", func() -> void: _sim().colony.stock.add("gold", 500)],
			["+50 de tout", func() -> void: DebugTools.add_everything(_sim(), 50)],
			["+10 fusils et lances", func() -> void: DebugTools.add_resources(_sim(), 10, ["flintlock", "spear"])],
		]
	)
	_section(
		"Apparitions (à l'endroit regardé)",
		[
			["Lutin adulte", func() -> void: DebugTools.spawn_lutin(_sim(), _here())],
			["Enfant", func() -> void: DebugTools.spawn_lutin(_sim(), _here(), true)],
			["Loup", func() -> void: DebugTools.spawn_animal(_sim(), "wolf", _here())],
			["Ours", func() -> void: DebugTools.spawn_animal(_sim(), "bear", _here())],
			["Cerf", func() -> void: DebugTools.spawn_animal(_sim(), "deer", _here())],
			["Sanglier", func() -> void: DebugTools.spawn_animal(_sim(), "boar", _here())],
			["Marchand", func() -> void: DebugTools.merchant_now(_sim())],
		]
	)
	_section(
		"Triches",
		[
			["Mode dieu : %s" % ("OUI" if r.god_mode else "non"), _toggle_god],
			["Construction libre : %s" % ("OUI" if r.free_build else "non"), _toggle_free],
			["Creuser instantané : %s" % ("OUI" if r.free_dig else "non"), _toggle_dig],
			[
				"Finir les constructions",
				func() -> void: _say("%d plan(s) terminé(s)." % DebugTools.finish_builds(_sim()))
			],
			["Tout rechercher", func() -> void: DebugTools.unlock_all_research(_sim())],
			["Soigner et rassasier", func() -> void: DebugTools.heal_all(_sim())],
			["Tuer les ennemis", func() -> void: _say("%d ennemi(s) éliminé(s)." % DebugTools.kill_enemies(_sim()))],
		]
	)
	_section(
		"Temps",
		[
			["+1 jour", func() -> void: DebugTools.skip_days(1)],
			["+10 jours", func() -> void: DebugTools.skip_days(10)],
			["Midi", func() -> void: DebugTools.set_hour(0.5)],
			["Minuit", func() -> void: DebugTools.set_hour(0.0)],
			["Vitesse ×8", func() -> void: GameClock.set_speed(8)],
			["Vitesse ×16", func() -> void: GameClock.set_speed(16)],
		]
	)
	_section(
		"Monde et factions",
		[
			["Révéler la carte", func() -> void: _sim().territory.reveal_all()],
			["Raid d'orcs maintenant", func() -> void: _say("%d orcs en route." % _sim().orcs.raid())],
			["Orc ici", func() -> void: DebugTools.spawn_animal(_sim(), "orc", _here())],
			["Orc brute ici", func() -> void: DebugTools.spawn_animal(_sim(), "orc_brute", _here())],
			["Camp d'orcs ici", func() -> void: _sim().orcs.add_camp(Pathfinder.snap(game.world, _here()))],
			["Rencontrer tout le monde", _meet_all],
			["Victoire", func() -> void: EventBus.alert.emit("victoire", "VICTOIRE (débug) !")],
		]
	)
	var fac := []
	for st: Dictionary in _sim().rivals.present():
		var id: String = st["id"]
		var nm: String = str(Rivals.def(id).get("name", id))
		fac.append(["Guerre : " + nm, func() -> void: _say(_sim().realm.diplomacy(id, "war"))])
		fac.append(["Conquérir : " + nm, func() -> void: _sim().rivals.conquer(id)])
	if not fac.is_empty():
		_section("Diplomatie", fac)
	for s: Array in extra_sections:
		_section(s[0], s[1].call() if s[1] is Callable else s[1])
	var off := Button.new()
	off.text = "Désactiver le menu débug"
	off.custom_minimum_size = Vector2(500, 56)
	UiStyle.make_primary(off)
	off.pressed.connect(
		func() -> void:
			Settings.set_value("debug", false)
			visible = false
			EventBus.alert.emit("info", "Menu débug désactivé (5 touchers dans le coin de l'accueil pour le remettre).")
	)
	_body.add_child(off)


func _meet_all() -> void:
	for st: Dictionary in _sim().rivals.states.values():
		_sim().territory.explore(st["center"], 1)
	_sim().rivals.check_meetings()


func _toggle_god() -> void:
	_sim().rules.god_mode = not _sim().rules.god_mode
	refresh.call_deferred()


func _toggle_dig() -> void:
	_sim().rules.free_dig = not _sim().rules.free_dig
	refresh.call_deferred()


func _toggle_free() -> void:
	_sim().rules.free_build = not _sim().rules.free_build
	refresh.call_deferred()


func _section(title: String, buttons: Array) -> void:
	_body.add_child(UiStyle.title_label(title, 22, UiStyle.GOLD))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	flow.custom_minimum_size = Vector2(1060, 0)
	_body.add_child(flow)
	for b: Array in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 18)
		var cb: Callable = b[1]
		btn.pressed.connect(
			func() -> void:
				cb.call()
				if _msg.text == "" or not _msg.text.ends_with("."):
					_say("Fait : %s" % btn.text)
		)
		flow.add_child(btn)


func _say(t: String) -> void:
	_msg.text = t
