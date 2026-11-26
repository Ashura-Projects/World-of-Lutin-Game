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
