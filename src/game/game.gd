extends Node3D
## Scène de jeu : génère (ou charge) le monde, puis l'affiche. Le monde est construit hors du thread principal.

var world: VoxelWorld
var generator: WorldGenerator
var world_view: WorldView
var flora_view: FloraView
var camera: CameraController
var sky: SkyLight
var hud: Hud
var build_tool: BuildTool
var colony: Colony
var lutins_view: LutinsView
var props_view: PropsView
var flora: Flora
var fauna: Fauna
var ground: GroundItems
var board: TaskBoard
var items_view: ItemsView
var fauna_view: FaunaView
var structures: Structures
var structures_view: StructuresView
var plans_view: PlansView
var _gen_task: int = -1
var _loading: Label


func _ready() -> void:
	Rng.set_seed(GameSetup.seed_value)
	GameClock.configure()
	GameClock.reset(true)
	sky = SkyLight.new()
	add_child(sky)
	camera = CameraController.new()
	add_child(camera)
	hud = Hud.new()
	add_child(hud)
	_loading = UiStyle.title_label("Le monde se forme…", 40)
	_loading.position = Vector2(560, 320)
	hud.add_child(_loading)
	world = VoxelWorld.new(GameSetup.map_dims())
	generator = WorldGenerator.new(world, GameSetup.seed_value)
	_gen_task = WorkerThreadPool.add_task(generator.generate)


func _process(_delta: float) -> void:
	if _gen_task >= 0 and WorkerThreadPool.is_task_completed(_gen_task):
		WorkerThreadPool.wait_for_task_completion(_gen_task)
		_gen_task = -1
		_on_world_ready()
	if sky and world_view:
		sky.update(GameClock.time_of_day())


func _on_world_ready() -> void:
	colony = Colony.new(world)
	flora = Flora.new()
	fauna = Fauna.new(world)
	ground = GroundItems.new()
	board = TaskBoard.new(world, colony, flora, fauna, ground)
	structures = Structures.new()
	board.structures = structures
	for pair: Array in [
		["world", world], ["colony", colony], ["flora", flora], ["fauna", fauna], ["ground", ground], ["tasks", board]
	]:
		SaveManager.register(pair[0], pair[1])
	var loaded := GameSetup.load_slot != "" and SaveManager.load_game(GameSetup.load_slot)
	if not loaded:
		var c := _start_spot()
		flora.load_from_generator(generator)
		colony.spawn_start(c, GameSetup.lutin_count)
		colony.auto_assign_jobs()
		fauna.populate(["deer", "boar"], c)
	EventBus.tick.connect(_on_tick)
	world_view = WorldView.new()
	add_child(world_view)
	world_view.setup(world)
	flora_view = FloraView.new()
	add_child(flora_view)
	flora_view.bind(flora)
	props_view = PropsView.new()
	add_child(props_view)
	props_view.place(PropsView.cart(), colony.stock.pos + Vector3i(2, 0, 0))
	items_view = ItemsView.new()
	add_child(items_view)
	items_view.bind(ground)
	fauna_view = FaunaView.new()
	add_child(fauna_view)
	fauna_view.bind(fauna)
	structures_view = StructuresView.new()
	add_child(structures_view)
	structures_view.bind(structures)
	plans_view = PlansView.new()
	add_child(plans_view)
	plans_view.bind(board)
	lutins_view = LutinsView.new()
	add_child(lutins_view)
	lutins_view.setup(colony)
	camera.bounds = AABB(Vector3.ZERO, Vector3(world.size))
	camera.distance = 22.0
	camera.focus(Vector3(colony.stock.pos))
	camera.tapped.connect(_on_tap)
	build_tool = BuildTool.new()
	add_child(build_tool)
	build_tool.setup(world, camera)
	build_tool.place_handler = board.place_blueprints  # en partie : poser = plans pour les bâtisseurs
	build_tool.structure_handler = func(kind: String, cell: Vector3i) -> bool:
		return board.add_structure(kind, cell) >= 0
	_loading.queue_free()
	hud.bind_game(self)
	GameClock.running = true


func _on_tick(_i: int) -> void:
	colony.tick()
	if GameClock.tick_index % 2 == 0:
		var cells := []
		for l in colony.lutins:
			cells.append(l.cell)
		fauna.tick(cells)


## Point de départ : case de plaine sèche la plus proche du centre de la carte.
func _start_spot() -> Vector3i:
	var center := Vector2i(world.size.x / 2, world.size.z / 2)
	for r in range(0, world.size.x / 2, 3):
		for a in 16:
			var x := center.x + int(cos(a * TAU / 16.0) * r)
			var z := center.y + int(sin(a * TAU / 16.0) * r)
			var y := world.surface_y(x, z)
			var top := world.get_block(Vector3i(x, y - 1, z))
			if y > 0 and (top == world.types.num("grass") or top == world.types.num("fertile_soil")):
				var ok := true
				for d: Vector3i in [Vector3i(3, 0, 0), Vector3i(-3, 0, 0), Vector3i(0, 0, 3), Vector3i(0, 0, -3)]:
					if absi(world.surface_y(x + d.x, z + d.z) - y) > 1:
						ok = false
				if ok:
					return Vector3i(x, y, z)
	return Vector3i(center.x, world.surface_y(center.x, center.y), center.y)


func _on_tap(screen: Vector2) -> void:
	if build_tool.active:
		return
	if hud.harvest_panel != null and hud.harvest_panel.visible:
		hud.harvest_panel.on_tap(screen)
		return
	hud.show_lutin(lutins_view.pick(camera.cam, screen))


func _exit_tree() -> void:
	for k in ["world", "colony", "flora", "fauna", "ground", "structures", "tasks"]:
		SaveManager.unregister(k)
