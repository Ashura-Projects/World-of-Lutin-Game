extends GutTest

var w: VoxelWorld
var c: Colony
var board: TaskBoard
var st: Structures


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(5)
	w = VoxelWorld.new(Vector3i(40, 32, 40))
	for x in 40:
		for z in 40:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	c = Colony.new(w)
	board = TaskBoard.new(w, c, Flora.new(), Fauna.new(w), GroundItems.new())
	st = Structures.new()
	board.structures = st
	c.spawn_start(Vector3i(20, 2, 20), 4)
	c.stock.add("hammer", 3)
	for l in c.lutins:
		c.change_job(l, "builder")


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		c.tick()


func test_plan_sans_materiaux_attend() -> void:
	c.stock.items.erase("plank")
	var id := board.add_build_block(Vector3i(10, 2, 10), w.types.num("plank_block"))
	_run(10)
	assert_eq(w.get_block(Vector3i(10, 2, 10)), 0, "pas de planches : rien n'est posé")
	assert_eq(board.tasks[id].get("missing"), "plank")


func test_tente_montee_et_attribuee() -> void:
	c.stock.add("hide", 3)
	c.stock.add("log", 2)
	board.add_structure("tent", Vector3i(24, 2, 20))
	_run(60)
	var s := st.at(Vector3i(24, 2, 20))
	assert_true(s["built"], "tente montée")
	assert_ne(s["owner"], -1, "un lutin y dort")


## Critère J5 : une maison (murs, toit, porte, lits) bâtie par les lutins, et ils y dorment.
func test_maison_batie_et_habitee() -> void:
	c.stock.add("plank", 200)
	c.stock.add("straw", 20)
	c.stock.add("door_item", 1)
	var plank := w.types.num("plank_block")
	var x0 := 10
	var z0 := 10
	var walls: Array[Vector3i] = []
	for side: Array in [
		[Vector3i(x0, 2, z0), Vector3i(x0 + 4, 2, z0)],
		[Vector3i(x0 + 4, 2, z0), Vector3i(x0 + 4, 2, z0 + 4)],
		[Vector3i(x0 + 4, 2, z0 + 4), Vector3i(x0, 2, z0 + 4)],
		[Vector3i(x0, 2, z0 + 4), Vector3i(x0, 2, z0)]
	]:
		for p in Shapes.wall(side[0], side[1], 3):
			if not walls.has(p) and not (p.x == x0 + 2 and p.z == z0 and p.y < 4):
				walls.append(p)
	board.place_blueprints(walls, plank, false)
	board.place_blueprints(Shapes.rect(Vector3i(x0, 5, z0), Vector3i(x0 + 4, 5, z0 + 4)), plank, false)
	board.add_structure("door", Vector3i(x0 + 2, 2, z0))
	for i in 4:
		board.add_structure("bed", Vector3i(x0 + 1 + (i % 3), 2, z0 + 2 + (i / 3)))
	_run(GameClock.ticks_per_day() / 10.0 * 3.0)  # jusqu'à 3 jours de jeu
	var left := 0
	for t: Dictionary in board.tasks.values():
		left += 1
	assert_eq(left, 0, "tous les plans sont bâtis")
	assert_eq(w.get_block(Vector3i(x0, 4, z0 + 2)), plank)
	var room := RoomDetector.room_at(w, st, Vector3i(x0 + 2, 2, z0 + 2))
	assert_false(room.is_empty(), "la maison est fermée")
	assert_true(room["type"] in ["house", "dormitory"], "type de pièce : %s" % room.get("type"))
	var housed := 0
	for l in c.lutins:
		if l.home.y >= 0 and room["cells"].has(l.home):
			housed += 1
	assert_eq(housed, 4, "chaque lutin a un lit dans la maison")
	# la nuit, ils vont y dormir
	while not GameClock.is_night():
		GameClock.step()
		c.tick()
	_run(GameClock.ticks_per_day() / 10.0 * 0.15)
	var inside := 0
	for l in c.lutins:
		if l.state == Lutin.State.SLEEP and room["cells"].has(l.cell):
			inside += 1
	assert_gt(inside, 2, "ils dorment dans la maison")


func test_pas_de_tente_sur_l_eau() -> void:
	w.set_raw(Vector3i(30, 1, 30), w.types.num("water"))
	assert_eq(board.add_structure("tent", Vector3i(30, 2, 30)), -1)
	assert_eq(board.add_structure("tent", Vector3i(30, 1, 30)), -1)
