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
var fields: Fields
var production: Production
var fields_view: FieldsView
var sim: GameSim
var _autosave_ticks: int = 0
var sound: SoundDirector
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
	sim = GameSim.new(world)
	colony = sim.colony
	flora = sim.flora
	fauna = sim.fauna
	ground = sim.ground
	board = sim.board
	structures = sim.structures
	fields = sim.fields
	production = sim.production
	sim.register_saves()
	var loaded := GameSetup.load_slot != "" and SaveManager.load_game(GameSetup.load_slot)
	if not loaded:
		sim.new_game(generator, _start_spot(), GameSetup.lutin_count)
	EventBus.tick.connect(_on_tick)
	EventBus.day_changed.connect(func(_d: int) -> void: sim.daily())
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
	structures.set_meta("world", world)
	structures_view.bind(structures)
	fields_view = FieldsView.new()
	add_child(fields_view)
	fields_view.bind(fields)
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
	sound = SoundDirector.new()
	add_child(sound)
	sound.setup(self)
	_loading.queue_free()
	hud.bind_game(self)
	GameClock.running = true


func _on_tick(_i: int) -> void:
	sim.tick()
	_autosave_ticks += 1
	if _autosave_ticks >= int(DataRegistry.get_table("time").get("autosave_s", 300)) * GameClock.ticks_per_second():
		_autosave_ticks = 0
		SaveManager.save_game("auto")


## Sauvegarde quand l'appli passe en arrière-plan ou se ferme (téléphone).
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		if sim != null:
			SaveManager.save_game("auto")


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
	if hud.zones_panel != null and hud.zones_panel.visible:
		hud.zones_panel.on_tap(screen)
		return
	if hud.harvest_panel != null and hud.harvest_panel.visible:
		hud.harvest_panel.on_tap(screen)
		return
	hud.show_lutin(lutins_view.pick(camera.cam, screen))


func _exit_tree() -> void:
	Audio.stop_all()
	Audio.world_root = null
	if sim != null:
		sim.unregister_saves()
