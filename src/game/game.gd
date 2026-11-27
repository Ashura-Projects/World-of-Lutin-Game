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
var _loading: LoadingScreen
var _load_t: float = 0.0
var _mesh_total: int = 0
var _cart: Node3D
var fog_view: FogView
var realm_view: RealmView
var fauna_fog: Territory


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
	_loading = LoadingScreen.new()
	add_child(_loading)
	_loading.play_pressed.connect(_on_play)
	world = VoxelWorld.new(GameSetup.map_dims())
	generator = WorldGenerator.new(world, GameSetup.seed_value)
	_gen_task = WorkerThreadPool.add_task(generator.generate)


func _process(delta: float) -> void:
	if _gen_task >= 0:
		_load_t += delta
		_loading.set_progress(0.6 * (1.0 - exp(-_load_t / 2.5)))  # génération : progression estimée
		if WorkerThreadPool.is_task_completed(_gen_task):
			WorkerThreadPool.wait_for_task_completion(_gen_task)
			_gen_task = -1
			_on_world_ready()
	elif is_instance_valid(_loading) and not _loading.is_ready() and world_view != null:
		var left := world_view.pending_count()
		_mesh_total = maxi(_mesh_total, left)
		_loading.set_progress(0.65 + 0.35 * (1.0 - float(left) / maxf(1.0, float(_mesh_total))))
		if left == 0 and world_view.has_scanned():
			_loading.ready_to_play()
	if sky and world_view:
		sky.update(GameClock.time_of_day())
		world_view.focus = camera.target
		flora_view.focus = camera.target
		fauna_view.focus = camera.target
		if fog_view != null:
			fog_view.focus = camera.target
	if _cart != null and colony != null:
		for l: Lutin in colony.lutins:
			if l.order.get("kind", "") == "cart" and int(l.order["stage"]) == 1:
				_cart.position = _cart.position.lerp(l.pos + Vector3(0.9, 0, 0), minf(1.0, delta * 6.0))


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
	world_view.focus = Vector3(colony.stock.pos)
	if bool(DataRegistry.get_table("realm").get("fog", {}).get("enabled", true)):
		world_view.fog = sim.territory
		fog_view = FogView.new()
		add_child(fog_view)
		fog_view.bind(sim.territory, world.size.y)
		fauna_fog = sim.territory
	flora_view = FloraView.new()
	add_child(flora_view)
	flora_view.bind(flora)
	props_view = PropsView.new()
	add_child(props_view)
	_cart = PropsView.cart()
	props_view.place(_cart, colony.stock.pos + Vector3i(2, 0, 0))
	colony.cart_moved.connect(
		func(p: Vector3i) -> void: _cart.position = Vector3(p + Vector3i(2, 0, 0)) + Vector3(0.5, 0, 0.5)
	)
	items_view = ItemsView.new()
	add_child(items_view)
	items_view.bind(ground)
	fauna_view = FaunaView.new()
	add_child(fauna_view)
	fauna_view.bind(fauna)
	fauna_view.fog = fauna_fog
	structures_view = StructuresView.new()
	add_child(structures_view)
	structures.set_meta("world", world)
	structures_view.bind(structures)
	fields_view = FieldsView.new()
	add_child(fields_view)
	fields_view.bind(fields)
	realm_view = RealmView.new()
	add_child(realm_view)
	realm_view.bind(sim.orcs, sim.territory, world)
	var stores := StoreZonesView.new()
	add_child(stores)
	stores.bind(colony)
	var markers := TaskMarkersView.new()
	add_child(markers)
	markers.bind(board)
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
	build_tool.place_handler = _place  # en partie : poser = plans pour les bâtisseurs
	build_tool.structure_handler = _place_structure
	sound = SoundDirector.new()
	add_child(sound)
	sound.setup(self)
	hud.bind_game(self)
	_loading.set_progress(0.65)
	GameClock.running = false  # la partie démarre au bouton « Jouer »


## Poser des blocs : plans pour les bâtisseurs, ou pose immédiate en « construction libre » (débug).
func _place(cells: Array, block_id: int, erase: bool) -> int:
	if sim.rules.free_build:
		var into_air: bool = not erase and build_tool.mode != BuildTool.Mode.ROAD
		return build_tool.history.apply(cells, 0 if erase else block_id, into_air)
	return board.place_blueprints(cells, block_id, erase)


func _place_structure(kind: String, cell: Vector3i) -> bool:
	if sim.rules.free_build:
		if not structures.at(cell).is_empty():
			return false
		structures.add(kind, cell, true)
		structures.assign_homes(colony)
		return true
	return board.add_structure(kind, cell) >= 0


func _on_play() -> void:
	GameClock.running = true
	if bool(Settings.get_value("tutorial")) and GameSetup.load_slot == "":
		hud.root.add_child(TutorialPanel.new())


func _on_tick(_i: int) -> void:
	sim.tick()
	_autosave_ticks += 1
	if _autosave_ticks >= int(Settings.get_value("autosave_min")) * 60 * GameClock.ticks_per_second():
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
	if hud.windows.on_tap(screen):
		return
	if build_tool.active:
		return
	if hud.zones_panel != null and hud.zones_panel.visible:
		hud.zones_panel.on_tap(screen)
		return
	if hud.harvest_panel != null and hud.harvest_panel.visible:
		hud.harvest_panel.on_tap(screen)
		return
	if hud.orders.active() and hud.orders.on_tap(screen):
		return  # mode ordres : chaque toucher donne un ordre au lutin choisi
	var l := lutins_view.pick(camera.cam, screen)
	if l != null:
		hud.show_lutin(l)


func _exit_tree() -> void:
	Audio.stop_all()
	Audio.world_root = null
	if sim != null:
		sim.unregister_saves()
