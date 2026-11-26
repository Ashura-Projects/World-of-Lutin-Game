extends GutTest

var w: VoxelWorld
var c: Colony
var flora: Flora
var fauna: Fauna
var ground: GroundItems
var board: TaskBoard


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(9)
	w = VoxelWorld.new(Vector3i(48, 32, 48))
	for x in 48:
		for z in 48:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("dirt"))
			w.set_raw(Vector3i(x, 2, z), w.types.num("grass"))
	c = Colony.new(w)
	flora = Flora.new()
	fauna = Fauna.new(w)
	ground = GroundItems.new()
	board = TaskBoard.new(w, c, flora, fauna, ground)
	c.spawn_start(Vector3i(24, 3, 24), 6)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		c.tick()
		var cells := []
		for l in c.lutins:
			cells.append(l.cell)
		fauna.tick(cells)


func test_metiers_auto_avec_outils() -> void:
	var axes := c.stock.count("axe")
	c.auto_assign_jobs()
	var jobs := []
	for l in c.lutins:
		jobs.append(l.job)
	assert_true(jobs.has("woodcutter"))
	assert_eq(c.stock.count("axe"), axes - 1, "la hache a quitté la réserve")
	var l := c.lutins[5]
	assert_false(c.change_job(l, "woodcutter"), "plus de hache en réserve")


func test_couper_un_arbre_et_ramener_les_buches() -> void:
	c.auto_assign_jobs()
	flora.trees[Vector3i(30, 3, 24)] = "pin"
	assert_gt(board.add_cut(Vector3i(30, 3, 24)), 0)
	var logs_before := c.stock.count("log")
	_run(90)
	assert_false(flora.trees.has(Vector3i(30, 3, 24)), "arbre coupé")
	assert_eq(c.stock.count("log"), logs_before + 4, "4 bûches ramenées par les porteurs")
	var wc: Lutin = null
	for l in c.lutins:
		if l.job == "woodcutter":
			wc = l
	assert_gt(float(wc.jobs_known["woodcutter"]["xp"]), 0.0, "XP de bûcheron gagnée")


func test_creuser_un_trou_reglable() -> void:
	c.auto_assign_jobs()
	var cells := Shapes.dig_box(Vector3i(20, 2, 20), 2, 2, 2)
	assert_eq(board.order_dig(cells), 8)
	_run(150)
	for p in cells:
		assert_eq(w.get_block(p), 0, "bloc %s creusé" % p)
	assert_gt(c.stock.count("dirt") + ground.total(), 0, "la terre est récupérée")


func test_cueillette_en_cercle() -> void:
	c.auto_assign_jobs()
	for i in 4:
		flora.bushes[Vector3i(18 + i, 3, 28)] = 0
	flora.bushes[Vector3i(2, 3, 2)] = 0
	assert_eq(board.order_circle("gather", Vector3i(20, 3, 28), 3), 4, "le cercle ne prend que ce qui est dedans")
	_run(60)
	assert_gt(c.stock.count("berries") + ground.total(), 0)


func test_chasse_au_fusil() -> void:
	c.auto_assign_jobs()
	var deer := fauna.spawn("deer", Vector3i(34, 3, 24))
	deer["wait"] = 99999  # immobile pour le test
	assert_gt(board.add_hunt(deer["id"]), 0)
	_run(60)
	assert_true(fauna.find(deer["id"]).is_empty(), "cerf abattu")
	assert_gt(c.stock.count("hide") + ground.total(), 0, "peaux et viande récupérées")


func test_taches_assignees_a_un_lutin() -> void:
	c.auto_assign_jobs()
	flora.trees[Vector3i(26, 3, 30)] = "chene"
	var id := board.add_cut(Vector3i(26, 3, 30))
	var hauler: Lutin = c.lutins[5]
	board.assign_lutins(id, [hauler.id])
	_run(60)
	assert_false(flora.trees.has(Vector3i(26, 3, 30)), "le lutin assigné a coupé l'arbre")


func test_route_accelere() -> void:
	var road := DataRegistry.block(w.types.num("road_stone"))
	assert_gt(float(road.get("speed_mult", 1.0)), 1.0)
	w.set_raw(Vector3i(10, 2, 10), w.types.num("road_stone"))
	assert_lt(Pathfinder.step_cost(w, Vector3i(10, 3, 10)), Pathfinder.step_cost(w, Vector3i(11, 3, 10)))


func test_tableau_aller_retour() -> void:
	flora.trees[Vector3i(30, 3, 24)] = "pin"
	board.add_cut(Vector3i(30, 3, 24))
	var d: Dictionary = JSON.parse_string(JSON.stringify(board.to_dict()))
	var b2 := TaskBoard.new(w, c, flora, fauna, ground)
	b2.from_dict(d)
	assert_eq(b2.tasks.size(), 1)
	assert_eq(b2.tasks.values()[0]["cell"], Vector3i(30, 3, 24))
