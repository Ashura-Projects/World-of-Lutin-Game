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
var smoke_view: SmokeView
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
		if smoke_view != null:
			smoke_view.focus = camera.target
	if _cart != null and colony != null:
		# la charrette suit le lutin (derrière lui) et s'oriente dans le sens de la marche
		var yaw := colony.cart_yaw
		_cart.rotation.y = lerp_angle(_cart.rotation.y, yaw + PI / 2.0, minf(1.0, delta * 5.0))
		for l: Lutin in colony.lutins:
			if l.order.get("kind", "") == "cart" and int(l.order["stage"]) == 1:
				var behind := Vector3(sin(yaw), 0, cos(yaw)) * 1.3
				_cart.position = _cart.position.lerp(l.pos + behind, minf(1.0, delta * 6.0))


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
	SaveManager.current_slot = GameSetup.load_slot if GameSetup.load_slot != "" else GameSetup.save_slot
	SaveManager.meta_provider = _save_meta
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
	_cart.rotation.y = colony.cart_yaw + PI / 2.0
	colony.cart_moved.connect(func(p: Vector3i) -> void: _cart.position = Vector3(p) + Vector3(0.5, 0, 0.5))
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
	smoke_view = SmokeView.new()
	add_child(smoke_view)
	smoke_view.bind(sim.realm, world)
	var gates_view := GatesView.new()
	add_child(gates_view)
	gates_view.bind(sim.gates)
	gates_view.colony = colony
	var shots := ShotsView.new()
	shots.catapults = sim.catapults
	add_child(shots)
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
	if erase:
		cells = cells.filter(func(c: Vector3i) -> bool: return not _erase_object(c))  # portes, objets, herses d'abord
		if cells.is_empty():
			return 1
	var shape: int = build_tool.shape_code if build_tool.mode != BuildTool.Mode.ROAD else 0
	if sim.rules.free_build or (erase and sim.rules.free_dig):
		var into_air: bool = not erase and build_tool.mode != BuildTool.Mode.ROAD
		var n := build_tool.history.apply(cells, 0 if erase else block_id, into_air)
		if not erase and shape > 0:
			for c: Vector3i in cells:
				if world.get_block(c) == block_id:
					world.set_shape(c, shape)
		return n
	return board.place_blueprints(cells, block_id, erase, shape)


func _place_structure(kind: String, cell: Vector3i) -> bool:
	var rot := posmod(roundi(-camera.yaw / (PI / 2.0)), 4)  # l'objet fait face à la caméra
	var extra := {"rot": rot, "gate_w": build_tool.gate_size.x, "gate_l": build_tool.gate_size.y}
	if sim.rules.free_build:
		if not structures.at(cell).is_empty():
			return false
		structures.add(kind, cell, true, extra)
		structures.assign_homes(colony)
		return true
	return board.add_structure(kind, cell, extra) >= 0


## Résumé affiché dans l'écran « Charger ».
func _save_meta() -> Dictionary:
	var modes := {"sandbox": "Bac à sable", "royal": "Aventure Royale", "tutorial": "Tutoriel"}
	return {
		"name": sim.faction.name,
		"mode": modes.get(sim.rules.mode, sim.rules.mode),
		"day": GameClock.day() + 1,
		"lutins": colony.lutins.size(),
		"size": str(GameSetup.size_def().get("name", "")),
		"version": str(ProjectSettings.get_setting("application/config/version", ""))
	}


func _on_play() -> void:
	GameClock.running = true
	if sim.rules.mode == "tutorial":
		var mp := MissionPanel.new()
		mp.setup(self)
		hud.root.add_child(mp)
	elif bool(Settings.get_value("tutorial")) and GameSetup.load_slot == "":
		hud.root.add_child(TutorialPanel.new())


func _on_tick(_i: int) -> void:
	sim.tick()
	_autosave_ticks += 1
	if _autosave_ticks >= int(Settings.get_value("autosave_min")) * 60 * GameClock.ticks_per_second():
		_autosave_ticks = 0
		SaveManager.save_game()


## Sauvegarde quand l'appli passe en arrière-plan ou se ferme (téléphone).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and hud != null and hud.windows != null:
		hud.back()  # bouton retour du téléphone = « ↩ Retour »
		return
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		if sim != null:
			SaveManager.save_game()


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
		return
	_pick_object(screen)


## Gomme sur un objet (porte, meuble, herse, pont-levis) : il est démonté (matériaux rendus). true si fait.
func _erase_object(c: Vector3i) -> bool:
	for q: Vector3i in [c + build_tool.last_normal, c + Vector3i.UP, c]:
		var g := sim.gates.at(q)
		if not g.is_empty() and structures.items.has(int(g["struct_id"])):
			return TaskCancel.remove_structure_at(board, structures.items[int(g["struct_id"])]["cell"])
		var s := structures.at(q)
		if not s.is_empty():
			return TaskCancel.remove_structure_at(board, s["cell"])
	return false


## Toucher un animal, une herse / un pont-levis ou un objet : son dialogue s'ouvre.
func _pick_object(screen: Vector2) -> void:
	var best: Dictionary = {}
	var bd := 45.0
	for a: Dictionary in fauna.animals:
		var p: Vector3 = a["pos"] + Vector3(0, 0.5, 0)
		if camera.cam.is_position_behind(p) or not fauna_view.visible_animal(a):
			continue
		var d := camera.cam.unproject_position(p).distance_to(screen)
		if d < bd:
			bd = d
			best = a
	if not best.is_empty():
		hud.object_dialog.show_animal(best)
		return
	var r := VoxelRaycast.cast(world, camera.cam.project_ray_origin(screen), camera.cam.project_ray_normal(screen))
	if not r["hit"]:
		return
	var cell: Vector3i = r["pos"]
	for c: Vector3i in [cell, cell + Vector3i.UP]:
		var g := sim.gates.at(c)
		if not g.is_empty():
			hud.object_dialog.show_gate(g)
			return
	for c: Vector3i in [cell + r["normal"], cell + Vector3i.UP, cell]:
		var s := structures.at(c)
		if not s.is_empty():
			hud.object_dialog.show_structure(s)
			return


func _exit_tree() -> void:
	Audio.stop_all()
	Audio.world_root = null
	if sim != null:
		sim.unregister_saves()
