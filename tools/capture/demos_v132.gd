extends RefCounted
## Captures de vérification de la 1.3.2 : ateliers en vrais modèles, ferme et élevage, unité en formation.


static func run(game: Node, action: String) -> void:
	match action:
		"v132_ateliers":
			_ateliers(game, 0)
		"v132_ateliers2":
			_ateliers(game, 1)
		"v132_ferme":
			_ferme(game)
		"v132_unite":
			_unite(game)
		"v132_tas":
			_tas(game)
		"v132_craft":
			_ateliers(game, 0)
			var st: Structures = game.sim.structures
			for s: Dictionary in st.items.values():
				if s["kind"] == "furnace":
					game.hud.object_dialog.show_structure(s)
		"v132_bulle":
			game.hud.menu_button("Construire").button_pressed = true
			game.hud.build_panel.show_category("blocks")
			game.hud.build_panel._choose_block(game.world.types.num("stone_block"), "Pierre", false)


static func _flat(w: VoxelWorld, p: Vector3i, sx: int, sz: int) -> void:
	var grass := w.types.num("grass")
	for x in range(-1, sx + 1):
		for z in range(-1, sz + 1):
			var c := Vector3i(p.x + x, p.y - 1, p.z + z)
			w.set_block(c, grass)
			for y in range(0, 6):
				w.set_block(Vector3i(c.x, p.y + y, c.z), 0)


static func _ateliers(game: Node, page: int) -> void:
	var w: VoxelWorld = game.world
	var st: Structures = game.sim.structures
	var p: Vector3i = game.colony.stock.pos + Vector3i(-8, 0, -10)
	_flat(w, p, 16, 8)
	var sets := [
		["furnace", "glassworks", "oven", "kiln", "cooking_hearth", "anvil", "well", "mill"],
		["brewery", "wine_press", "loom", "spinning_wheel", "herbalist", "leatherworks", "tailor", "library"]
	]
	var i := 0
	for k: String in sets[page]:
		var c := p + Vector3i((i % 4) * 4, 0, (i / 4) * 4)
		game.sim.flora.trees.erase(c)
		st.add(k, c, true)
		i += 1
	game.camera.distance = 16.0
	game.camera.yaw = 0.5
	game.camera.pitch = deg_to_rad(38.0)
	game.camera.focus(Vector3(p) + Vector3(7, 0.5, 4))


static func _ferme(game: Node) -> void:
	var w: VoxelWorld = game.world
	var st: Structures = game.sim.structures
	var p: Vector3i = game.colony.stock.pos + Vector3i(-6, 0, -10)
	_flat(w, p, 14, 8)
	for x in 7:
		st.add("fence", p + Vector3i(x, 0, 0), true)
		st.add("fence", p + Vector3i(x, 0, 6), true)
	for z in range(1, 6):
		st.add("fence", p + Vector3i(0, 0, z), true)
		if z != 3:
			st.add("fence", p + Vector3i(6, 0, z), true)
	st.add("fence_gate", p + Vector3i(6, 0, 3), true, {"rot": 1})
	st.add("water_trough", p + Vector3i(2, 0, 1), true)
	st.add("hay_rack", p + Vector3i(4, 0, 1), true)
	for k: String in ["cow", "cow", "pig", "pig"]:
		var a: Dictionary = game.fauna.spawn(k, p + Vector3i(2 + game.fauna.animals.size() % 3, 0, 3))
		a["owned"] = true
		a["home"] = p + Vector3i(3, 0, 3)
		a["roam"] = 2
	st.add("tent_cloth_double", p + Vector3i(9, 0, 0), true, {"rot": 2})
	st.add("tent_double", p + Vector3i(12, 0, 0), true, {"rot": 2})
	st.add("dairy", p + Vector3i(9, 0, 5), true, {"rot": 2})
	st.add("butcher_block", p + Vector3i(12, 0, 5), true, {"rot": 2})
	game.camera.distance = 15.0
	game.camera.yaw = 0.4
	game.camera.pitch = deg_to_rad(40.0)
	game.camera.focus(Vector3(p) + Vector3(7, 0.5, 3))


static func _unite(game: Node) -> void:
	var col: Colony = game.colony
	var ids := []
	for l: Lutin in col.lutins:
		ids.append(l.id)
	var uid: int = game.sim.units.create("Garde", ids[0], ids.slice(1, 8))
	game.sim.units.set_formation(uid, "square")
	var dest: Vector3i = Pathfinder.snap(game.world, col.stock.pos + Vector3i(0, 0, -6))
	game.sim.units.command(uid, "move", dest)
	game.hud.unit_bar.open(uid)
	game.click_marker.show_at(Vector3(dest) + Vector3(0.5, 0, 0.5))
	game.camera.distance = 12.0
	game.camera.focus(Vector3(dest))


static func _tas(game: Node) -> void:
	var w: VoxelWorld = game.world
	var col: Colony = game.colony
	var p: Vector3i = col.stock.pos + Vector3i(-4, 0, -8)
	_flat(w, p, 8, 4)
	var items := [
		"straw",
		"log",
		"plank",
		"stone",
		"brick",
		"glass",
		"hide",
		"cloth",
		"rope",
		"iron_ingot",
		"bread",
		"fish",
		"cheese",
		"pottery",
		"flintlock",
		"spear",
		"axe",
		"flour",
		"carrot",
		"beer",
		"bottle",
		"meat",
		"pumpkin",
		"chest_item"
	]
	var cells := []
	for i in items.size():
		cells.append(p + Vector3i(i % 8, 0, i / 8))
		col.stock.add(items[i], 30 + (i * 7) % 25)
	col.add_store_cells(cells)
	game.camera.distance = 11.0
	game.camera.yaw = 0.35
	game.camera.pitch = deg_to_rad(42.0)
	game.camera.focus(Vector3(p) + Vector3(4, 0.5, 1.5))
