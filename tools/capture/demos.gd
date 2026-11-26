extends RefCounted
## Démonstrations scriptées pour les captures de vérification (pas utilisées par le jeu).


static func run(game: Node, action: String) -> void:
	match action:
		"tour":
			_tour(game)
		"fiche":
			var l: Lutin = game.colony.lutins[0]
			game.camera.distance = 7.0
			game.camera.focus(l.pos)
			game.lutins_view.selected_id = l.id
			game.hud.show_lutin(l)
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
