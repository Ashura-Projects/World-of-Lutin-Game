extends RefCounted
## Démonstrations scriptées pour les captures de vérification (pas utilisées par le jeu).


static func run(game: Node, action: String) -> void:
	if action == "nouvelle":
		game._show_play(true)
		game._on_new_game()
		game._setup_panel.advanced = true
		game._setup_panel.refresh()
		return
	if action == "jouer":
		game._show_play(true)
		return
	if action == "charger":
		game._show_play(true)
		game._open_slots()
		return
	if "_loading" in game and is_instance_valid(game._loading):  # passer l'écran de chargement
		game._loading.play_pressed.emit()
		game._loading.queue_free()
	if action.begins_with("v132"):
		load("res://tools/capture/demos_v132.gd").run(game, action)
		return
	match action:
		"tour":
			_tour(game)
		"fiche":
			var l: Lutin = game.colony.lutins[0]
			game.camera.distance = 7.0
			game.camera.focus(l.pos)
			game.lutins_view.selected_id = l.id
			game.hud.show_lutin(l)
		"marchand":
			marchand(game)
		"deco":
			deco(game)
		"faction":
			faction(game)
		"nature":
			nature(game)
		"vue_large":
			vue_large(game)
		"recherche":
			recherche(game)
		"loups":
			loups(game)
		"ferme":
			ferme(game)
		"village":
			village(game)
		"recolte":
			recolte(game)
		"travail":
			recolte(game)
			game.hud.menu_button("Récolter").button_pressed = false
		"construire":
			_tour(game)
			game.hud.menu_button("Construire").button_pressed = true
		"menu_meubles":
			_tour(game)
			game.hud.menu_button("Construire").button_pressed = true
			game.hud.build_panel.show_category("furniture")
			game.hud.tools.set_floor(6)
			game.hud.tools._floor_panel.visible = true
		"chargement":
			pass
		"formes":
			formes(game)
		"v131":
			v131(game)
		"guide":
			game.hud._guide()
		"objets13":
			objets13(game)
		"animal":
			var h: Dictionary = game.fauna.spawn(
				"horse", Pathfinder.snap(game.world, game.colony.stock.pos + Vector3i(4, 0, 3))
			)
			game.camera.distance = 10.0
			game.camera.focus(h["pos"])
			game.hud.object_dialog.show_animal(h)
		"herse":
			var g: Dictionary = objets13(game)
			game.hud.object_dialog.show_gate(g)
		"apercu_champs":
			game.hud.menu_button("Zones").button_pressed = true
			var p0: Vector3i = game.colony.stock.pos + Vector3i(3, -1, 3)
			var cells: Array = []
			for x in 4:
				for z in 3:
					cells.append(Vector3i(p0.x + x, game.world.surface_y(p0.x + x, p0.z + z) - 1, p0.z + z))
			game.hud.zones_panel._set_preview(cells)
			game.camera.distance = 14.0
			game.camera.focus(Vector3(p0))
		"construire13":
			game.hud.menu_button("Construire").button_pressed = true
			game.hud.build_panel.show_category("light")
		"tutoriel":
			game.hud.root.add_child(TutorialPanel.new())
		"carte":
			game.sim.territory.reveal_all()
			game.sim.rivals.check_meetings()
			game.sim.orcs.check_discovery(game.sim.territory)
			game.hud.top.map_panel.visible = true
		"camp_orc":
			var c: Dictionary = game.sim.orcs.camps[0]
			game.sim.territory.explore(c["cell"], 2)
			game.camera.distance = 16.0
			game.camera.focus(Vector3(c["cell"]))
		"village_voisin":
			var st: Dictionary = game.sim.rivals.states.values()[0]
			game.sim.territory.explore(st["center"], 2)
			game.camera.distance = 22.0
			game.camera.focus(Vector3(st["center"]))
		"brouillard":
			game.camera.distance = 70.0
			game.camera.focus(Vector3(game.colony.stock.pos))
		"religion":
			game.sim.structures.add("chapel", game.colony.stock.pos + Vector3i(5, 0, 0), true)
			game.sim.religion.ordain(game.colony.lutins[0])
			game.hud.open_realm()
			game.hud.realm_panel.show_tab("religion")
		"debug":
			game.hud.debug_panel.visible = true
			game.hud.debug_panel.refresh()
		"batiments":
			var p: Vector3i = game.colony.stock.pos
			for e: Array in [
				["chapel", Vector3i(6, 0, -6)],
				["church", Vector3i(-12, 0, -8)],
				["barracks", Vector3i(6, 0, 4)],
				["watchtower", Vector3i(-6, 0, 6)],
				["claim_post", Vector3i(2, 0, 8)],
				["altar", Vector3i(0, 0, -4)],
				["church_bell", Vector3i(-3, 0, -4)],
				["throne", Vector3i(3, 0, -4)],
				["iron_cage", Vector3i(-1, 0, 4)]
			]:
				var c := Pathfinder.snap(game.world, p + e[1])
				game.sim.structures.add(e[0], c, true)
			game.camera.distance = 30.0
			game.camera.focus(Vector3(p))
		"parametres":
			game.hud._settings()
			for c in game.hud.root.get_children():
				if c is SettingsPanel:
					c.show_tab("graphics")
		"dodo":
			GameClock.set_speed(0)
			for l: Lutin in game.colony.lutins:
				l.state = Lutin.State.SLEEP
			game.camera.distance = 9.0
			game.camera.focus(game.colony.lutins[0].pos)
		"soldats":
			for i in 3:
				game.sim.realm.enroll(game.colony.lutins[i])
			var l: Lutin = game.colony.lutins[0]
			game.camera.distance = 7.0
			game.camera.focus(l.pos)
		"recolte_menu":
			game.hud.menu_button("Récolter").button_pressed = true
		"fiche_ordres":
			var l: Lutin = game.colony.lutins[0]
			game.camera.distance = 16.0
			game.camera.focus(l.pos)
			game.hud.show_lutin(l)
		"ordres":
			var l: Lutin = game.colony.lutins[0]
			game.camera.distance = 16.0
			game.camera.focus(l.pos)
			game.hud.show_lutin(l)
			game.hud.sheet.visible = false
		"royaume":
			game.hud.open_realm()
			game.hud.realm_panel.show_tab("laws")
		"diplomatie":
			game.hud.open_realm()
			game.hud.realm_panel.show_tab("diplomacy")
		"lutins":
			game.hud.menu_button("Lutins").button_pressed = true
		"unites":
			var ids := []
			for l: Lutin in game.colony.lutins:
				ids.append(l.id)
			game.sim.units.create("Première lance", ids[0], ids.slice(1, 4))
			game.hud.menu_button("Militaire").button_pressed = true
			game.hud.military_panel.show_tab("units")
		"ressources":
			game.hud.top.toggle_resources("")
		"reserve":
			game.hud.menu_button("Zones").button_pressed = true
			game.hud.zones_panel.show_tab("stores")
			var id: int = game.colony.stores.add_zone(
				Shapes.rect(game.colony.stock.pos + Vector3i(3, 0, -3), game.colony.stock.pos + Vector3i(6, 0, -1))
			)
			game.hud.zones_panel.filter_panel.open(id)
		"bulle":
			recolte(game)
			game.hud.menu_button("Récolter").button_pressed = false
			game.hud.menu_button("Construire").button_pressed = true
			game.hud.build_panel._choose_object("table", "Table")
			game.colony.add_store_cells(
				Shapes.rect(game.colony.stock.pos + Vector3i(3, 0, -3), game.colony.stock.pos + Vector3i(6, 0, -1))
			)


static func _tour(game: Node) -> void:
	var w: VoxelWorld = game.world
	var c := Vector3i(w.size.x / 2, 0, w.size.z / 2)
	c.y = w.surface_y(c.x, c.z)
	var tool: BuildTool = game.build_tool
	tool.set_active(true)
	tool.material_id = w.types.num("cut_stone_block")
	tool.mode = BuildTool.Mode.WALL
	tool.wall_height = 10
	var a := c
	for d: Vector3i in [Vector3i(4, 0, 0), Vector3i(0, 0, 4), Vector3i(-4, 0, 0), Vector3i(0, 0, -4)]:
		tool.stroke(a, a + d)
		a += d
	tool.material_id = w.types.num("plank_block")
	tool.mode = BuildTool.Mode.FILL
	tool.stroke(c + Vector3i(0, 10, 0), c + Vector3i(4, 10, 4))
	tool.material_id = w.types.num("thatch_block")
	tool.mode = BuildTool.Mode.WALL
	tool.wall_height = 4
	tool.stroke(c + Vector3i(7, 0, 0), c + Vector3i(14, 0, 0))
	game.camera.distance = 26
	game.camera.focus(Vector3(c) + Vector3(5, 3, 2))


static func recolte(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	game.board.order_circle("cut", c, 12)
	game.board.order_circle("gather", c, 12)
	game.board.order_dig(Shapes.dig_box(c + Vector3i(4, -1, 4), 3, 3, 2))
	GameClock.set_speed(4)
	game.camera.distance = 18.0
	game.camera.focus(Vector3(c))
	game.hud.menu_button("Récolter").button_pressed = true


static func village(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	var st: Stockpile = game.colony.stock
	st.add("hide", 12)
	st.add("log", 20)
	st.add("plank", 120)
	st.add("stone", 20)
	st.add("hammer", 2)
	for l: Lutin in game.colony.lutins.slice(0, 3):
		game.colony.change_job(l, "builder")
	var b: TaskBoard = game.board
	for i in 3:
		b.add_structure("tent", c + Vector3i(-4 + i * 3, 0, 4))
	b.add_structure("campfire", c + Vector3i(0, 0, 2))
	var x0 := c + Vector3i(4, 0, -3)
	var walls: Array[Vector3i] = []
	for side: Array in [
		[x0, x0 + Vector3i(4, 0, 0)],
		[x0 + Vector3i(4, 0, 0), x0 + Vector3i(4, 0, 4)],
		[x0 + Vector3i(4, 0, 4), x0 + Vector3i(0, 0, 4)],
		[x0 + Vector3i(0, 0, 4), x0]
	]:
		for p in Shapes.wall(side[0], side[1], 3):
			if not walls.has(p) and not (p.x == x0.x + 2 and p.z == x0.z and p.y < x0.y + 2):
				walls.append(p)
	b.place_blueprints(walls, game.world.types.num("plank_block"), false)
	GameClock.set_speed(4)
	game.camera.distance = 16.0
	game.camera.focus(Vector3(c) + Vector3(2, 0, 0))


static func ferme(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	var st: Structures = game.structures
	st.add("mill", c + Vector3i(-5, 0, -3), true)
	st.add("well", c + Vector3i(-2, 0, -4), true)
	st.add("sawbench", c + Vector3i(3, 0, -4), true)
	game.colony.stock.add("hoe", 2)
	for l: Lutin in game.colony.lutins.slice(0, 2):
		game.colony.change_job(l, "farmer")
	for x in 6:
		for z in 4:
			var p := c + Vector3i(2 + x, 0, 3 + z)
			var top := Vector3i(p.x, game.world.surface_y(p.x, p.z) - 1, p.z)
			if ZonesPanel.farmable(game.world, top):
				game.fields.plan(top, "wheat" if z < 2 else "flax")
				if x < 3:
					game.fields.plots[top]["state"] = "ripe"
					game.world.set_block(top, game.world.types.num("field_plot"))
	GameClock.set_speed(4)
	game.camera.distance = 15.0
	game.camera.focus(Vector3(c) + Vector3(3, 0, 2))
	game.hud.menu_button("Gestion").button_pressed = true


static func loups(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	GameClock.tick_index = GameClock.ticks_per_day() + int(GameClock.ticks_per_day() * 0.82)
	game.colony.stock.add("flintlock", 4)
	for i in 3:
		game.fauna.spawn("wolf", c + Vector3i(9, 0, -2 + i * 2))
	game.fauna.spawn("bear", c + Vector3i(-10, 0, 4))
	game.sim.combat.ring("mobilize")
	game.camera.distance = 14.0
	game.camera.focus(Vector3(c) + Vector3(4, 0, 0))
	game.hud.menu_button("Militaire").button_pressed = true


static func recherche(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	var st: Structures = game.structures
	var lib := st.add("library", c + Vector3i(-6, 0, -4), true)
	st.add("school", c + Vector3i(5, 0, -5), true)
	game.sim.education.enroll(game.colony.lutins[0], lib)
	game.sim.research.choose("plough")
	game.sim.research.points = 22.0
	game.camera.distance = 18.0
	game.camera.focus(Vector3(c))
	game.hud.toggle_research()


static func vue_large(game: Node) -> void:
	game.camera.distance = 120.0
	game.camera.pitch = deg_to_rad(55)
	game.camera.focus(Vector3(game.world.size.x / 2.0, 30, game.world.size.z / 2.0))


static func nature(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos
	var best := c
	var bd := 1e9
	for p: Vector3i in game.flora.herbs:
		if game.flora.herbs[p] in ["mushroom", "reed"]:
			var d := Vector3(p).distance_to(Vector3(c))
			if d < bd:
				bd = d
				best = p
	game.camera.distance = 9.0
	game.camera.focus(Vector3(best))


static func deco(game: Node) -> void:
	var c: Vector3i = game.colony.stock.pos + Vector3i(3, 0, -6)
	var w: VoxelWorld = game.world
	var plank := w.types.num("plank_block")
	var stone := w.types.num("cut_stone_block")
	for x in range(0, 7):
		for z in range(0, 5):
			var p := c + Vector3i(x, -1, z)
			w.set_block(p, stone)
			if (x == 0 or x == 6 or z == 4) and not (x == 3 and z == 4):
				for y in 3:
					w.set_block(c + Vector3i(x, y, z), plank)
	for p: Vector3i in game.flora.trees.keys():
		if absi(p.x - c.x - 3) < 9 and absi(p.z - c.z - 2) < 9:
			game.flora.remove_tree(p)
	var st: Structures = game.structures
	for e: Array in [
		["wood_bed", Vector3i(1, 0, 3)],
		["chest", Vector3i(2, 0, 3)],
		["wardrobe", Vector3i(5, 0, 3)],
		["table", Vector3i(3, 0, 2)],
		["chair", Vector3i(2, 0, 2)],
		["carpet", Vector3i(3, 0, 1)],
		["barrel", Vector3i(5, 0, 1)],
		["lantern", Vector3i(1, 0, 0)],
		["flowerpot", Vector3i(4, 0, 0)],
		["weapon_rack", Vector3i(5, 0, 2)],
		["banner_wall", Vector3i(2, 1, 5)],
		["banner_pole", Vector3i(-2, 0, 0)],
		["crate", Vector3i(7, 0, 0)],
		["bench", Vector3i(7, 0, 2)]
	]:
		st.add(e[0], c + e[1], true)
	game.camera.distance = 11.0
	game.camera.yaw = 0.5
	game.camera.focus(Vector3(c) + Vector3(3, 0, 2))


static func faction(game: Node) -> void:
	deco(game)
	game.hud.open_faction()


static func marchand(game: Node) -> void:
	game.colony.stock.add("gold", 40)
	game.colony.stock.add("log", 30)
	game.sim.trade.daily(game.sim.trade.next_day)
	game.hud.menu_button("Commerce").button_pressed = true


static func formes(game: Node) -> void:
	var w: VoxelWorld = game.world
	var p: Vector3i = game.colony.stock.pos + Vector3i(-6, 0, -8)
	var plank := w.types.num("plank_block")
	var stone := w.types.num("cut_stone_block")
	var thatch := w.types.num("thatch_block")
	for i in range(1, ShapeMesh.NAMES.size()):
		var c := p + Vector3i(i * 2 - 2, 0, 0)
		c.y = w.surface_y(c.x, c.z)
		w.set_block(c, plank if i < 7 else stone)
		w.set_shape(c, i * 4)
	# tour ronde 2×2 : 4 angles arrondis sur 3 étages et un toit conique
	var t := p + Vector3i(4, 0, 6)
	t.y = w.surface_y(t.x, t.z)
	var quarters := [[Vector3i(1, 0, 1), 0], [Vector3i(0, 0, 1), 1], [Vector3i(0, 0, 0), 2], [Vector3i(1, 0, 0), 3]]
	for y in 4:
		for q: Array in quarters:
			var c: Vector3i = t + q[0] + Vector3i(0, y, 0)
			var shape := ShapeMesh.Shape.ROUND if y < 3 else ShapeMesh.Shape.CONE
			w.set_block(c, stone if y < 3 else thatch)
			w.set_shape(c, shape * 4 + int(q[1]))
	game.camera.distance = 14.0
	game.camera.focus(Vector3(p) + Vector3(8, 1, 3))


static func objets13(game: Node) -> Dictionary:
	var st: Structures = game.sim.structures
	var p: Vector3i = game.colony.stock.pos + Vector3i(-4, 0, -6)
	var kinds := [
		"fireplace",
		"standing_torch",
		"brazier_stone",
		"brazier_iron",
		"double_bed",
		"bookshelf",
		"armchair",
		"carpet_red",
		"carpet_fur",
		"chess_table",
		"dice_table",
		"bar_counter",
		"water_trough",
		"feeder",
		"statue",
		"candelabra"
	]
	for i in kinds.size():
		var c := Pathfinder.snap(game.world, p + Vector3i(i % 8 * 2, 0, i / 8 * 2))
		st.add(kinds[i], c, true)
	var gc := Pathfinder.snap(game.world, p + Vector3i(4, 0, 6))
	st.add("portcullis", gc, true, {"rot": 0})
	var g: Dictionary = game.sim.gates.gates.values()[0]
	game.sim.gates.toggle(g["id"])
	game.camera.distance = 16.0
	game.camera.focus(Vector3(p) + Vector3(7, 0, 3))
	return g


static func v131(game: Node) -> void:
	var w: VoxelWorld = game.world
	var st: Structures = game.sim.structures
	var p: Vector3i = game.colony.stock.pos + Vector3i(-6, 0, -8)
	var stone := w.types.num("cut_stone_block")
	# un mur avec fenêtres (ouverture, vitre, vitrail 2×2), une porte, des créneaux
	for x in 10:
		for y in 4:
			var c := Vector3i(p.x + x, p.y + y, p.z)
			w.set_block(c, stone)
	for e: Array in [
		[Vector3i(1, 1, 0), ShapeMesh.Shape.WINDOW_OPEN],
		[Vector3i(3, 1, 0), ShapeMesh.Shape.WINDOW_GLASS],
		[Vector3i(6, 1, 0), ShapeMesh.Shape.WINDOW_STAINED],
		[Vector3i(7, 1, 0), ShapeMesh.Shape.WINDOW_STAINED],
		[Vector3i(6, 2, 0), ShapeMesh.Shape.WINDOW_STAINED],
		[Vector3i(7, 2, 0), ShapeMesh.Shape.WINDOW_STAINED]
	]:
		w.set_shape(p + e[0], int(e[1]) * 4)
	w.set_block(p + Vector3i(9, 0, 0), 0)
	w.set_block(p + Vector3i(9, 1, 0), 0)
	st.add("door", p + Vector3i(9, 0, 0), true, {"rot": 0})
	for x in 10:
		w.set_block(Vector3i(p.x + x, p.y + 4, p.z), w.types.num("crenel") if x % 2 == 0 else stone)
	st.add("catapult", Pathfinder.snap(w, p + Vector3i(4, 0, 6)), true, {"yaw": 0.6})
	st.add("pew", Pathfinder.snap(w, p + Vector3i(12, 0, 3)), true)
	st.add("lectern", Pathfinder.snap(w, p + Vector3i(13, 0, 3)), true)
	st.add("small_altar", Pathfinder.snap(w, p + Vector3i(14, 0, 3)), true)
	st.add("tombstone", Pathfinder.snap(w, p + Vector3i(12, 0, 6)), true, {"epitaph": "Silex"})
	var h: Dictionary = game.fauna.spawn("horse", Pathfinder.snap(w, p + Vector3i(9, 0, 7)))
	h["owned"] = true
	game.camera.distance = 17.0
	game.camera.yaw = 0.3
	game.camera.focus(Vector3(p) + Vector3(6, 1, 5))
