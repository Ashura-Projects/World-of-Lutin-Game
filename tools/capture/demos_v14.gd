extends RefCounted
## Captures de vérification de la 1.4 : menus par catégories, unités (armes en main, commandant), panneaux.


static func run(game: Node, action: String) -> void:
	var hud: Hud = game.hud
	match action:
		"v14_menu":
			hud.categories._toggle("Peuple", MenuCategories.CATS[2][1], hud.categories._cat_btns["Peuple"])
		"v14_units":
			_units(game)
		"v14_editor":
			_units(game)
			hud.unit_editor.open(game.sim.units.units.keys()[0])
		"v14_stats":
			hud.stats_panel.visible = true
			hud.stats_panel.refresh()
		"v14_villages":
			hud.settlements_panel.visible = true
			hud.settlements_panel.show_tab("villages")
		"v14_people":
			hud.settlements_panel.open_people()
		"v14_diplo":
			hud.menu_button("Royaume").button_pressed = true
			hud.realm_panel.show_tab("diplomacy")
		"v14_battle":
			var sim: GameSim = game.sim
			var c: Vector3i = game.colony.stock.pos
			Battle.place_allies(sim, "lancer", c + Vector3i(-3, 0, 2), 5)
			Battle.place_enemies(sim, "bandit_club", c + Vector3i(0, 0, -14), 5)
			hud.battle_panel.visible = true
			hud.battle_panel.refresh()
			game.camera.distance = 18.0
			game.camera.focus(Vector3(c) + Vector3(0, 0, -5))


static func _units(game: Node) -> void:
	var col: Colony = game.colony
	col.stock.add("flintlock", 3)
	col.stock.add("spear", 3)
	var ids := []
	for l: Lutin in col.lutins:
		ids.append(l.id)
	var uid: int = game.sim.units.create("Garde royale", ids[0], ids.slice(1, 6))
	var u: Dictionary = game.sim.units.units[uid]
	UnitSetup.set_type(game.sim.units, u, "fusiliers")
	UnitSetup.set_gear(game.sim.units, u, ids[1], "weapon", "spear")
	UnitSetup.set_gear(game.sim.units, u, ids[2], "weapon", "spear")
	var c: Vector3i = col.find_lutin(ids[0]).cell
	for p: Vector3i in game.flora.trees.keys():
		if Vector3(p).distance_to(Vector3(c)) < 16.0:
			game.flora.trees.erase(p)
	game.flora.changed.emit("trees")
	game.sim.units.set_formation(uid, "line")
	game.sim.units.command(uid, "move", c + Vector3i(0, 0, -3))
	game.camera.distance = 8.0
	game.camera.pitch = deg_to_rad(28.0)
	game.camera.focus(Vector3(c) + Vector3(0, 0, -3))
