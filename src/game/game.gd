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
	if GameSetup.load_slot != "":
		SaveManager.register("world", world)
		SaveManager.load_game(GameSetup.load_slot)
	SaveManager.register("world", world)
	world_view = WorldView.new()
	add_child(world_view)
	world_view.setup(world)
	flora_view = FloraView.new()
	add_child(flora_view)
	flora_view.show_flora(generator.trees, generator.bushes)
	camera.bounds = AABB(Vector3.ZERO, Vector3(world.size))
	var c := Vector3(world.size.x / 2.0, 0, world.size.z / 2.0)
	c.y = world.surface_y(int(c.x), int(c.z))
	camera.focus(c)
	build_tool = BuildTool.new()
	add_child(build_tool)
	build_tool.setup(world, camera)
	_loading.queue_free()
	hud.bind_game(self)
	GameClock.running = true


func _exit_tree() -> void:
	SaveManager.unregister("world")
