extends GutTest
## 1.3 : formes de blocs, herses et ponts-levis, lits attribuables, chevaux, loisirs, voisins qui grandissent,
## tutoriel à missions, emplacements de sauvegarde.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(13)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 4)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		sim.tick()


func test_formes_maillage_et_sauvegarde() -> void:
	var p := Vector3i(10, 2, 10)
	w.set_block(p, w.types.num("plank_block"))
	w.set_shape(p, ShapeMesh.Shape.STAIRS * 4 + 1)
	assert_eq(w.get_shape(p), 13)
	for s in range(1, ShapeMesh.NAMES.size()):
		assert_gt(ShapeMesh.triangles(s).size(), 0, "forme %d" % s)
	var res := ChunkMesher.build(w, VoxelWorld.chunk_key(p), 9999, w.shapes_near(VoxelWorld.chunk_key(p) * 16))
	assert_gt(int(res["faces"]), 0)
	var w2 := VoxelWorld.new(w.size)
	w2.from_dict(w.to_dict())
	assert_eq(w2.get_shape(p), 13, "la forme est sauvegardée")
	w.set_block(p, 0)
	assert_eq(w.get_shape(p), 0, "bloc retiré : forme oubliée")


func test_plan_avec_forme_pose_la_forme() -> void:
	var p := Vector3i(12, 2, 12)
	var id := sim.board.add_build_block(p, w.types.num("plank_block"), ShapeMesh.Shape.SLOPE * 4)
	assert_eq(int(sim.board.tasks[id]["shape"]), 16)
	DebugTools.finish_builds(sim)
	assert_eq(w.get_block(p), w.types.num("plank_block"))


func test_herse_et_pont_levis() -> void:
	sim.structures.add("portcullis", Vector3i(30, 2, 30), true, {"rot": 0})
	var g: Dictionary = sim.gates.gates.values()[0]
	assert_true(g["open"], "herse levée au départ")
	assert_eq(w.get_block(Vector3i(31, 3, 30)), 0)
	assert_true(sim.gates.toggle(g["id"]))
	assert_eq(w.get_block(Vector3i(31, 3, 30)), w.types.num("gate_solid"), "fermée : l'ouverture est bouchée")
	sim.gates.set_locked(g["id"], true)
	assert_false(sim.gates.toggle(g["id"]), "verrouillée : on ne peut pas la manœuvrer")
	assert_eq(sim.gates.at(Vector3i(30, 4, 30))["id"], g["id"])
	# pont-levis 3 × 2 au-dessus d'un trou
	for x in range(40, 44):
		for z in range(28, 33):
			w.set_block(Vector3i(x, 1, z), 0)
	sim.structures.add("drawbridge", Vector3i(40, 2, 33), true, {"rot": 0, "gate_w": 3, "gate_l": 2})
	var b: Dictionary = sim.gates.gates.values()[1]
	assert_eq(sim.gates.cells(b).size(), 6)
	assert_eq(w.get_block(Vector3i(41, 1, 32)), w.types.num("gate_solid"), "pont baissé : on peut passer")
	sim.gates.toggle(b["id"])
	assert_eq(w.get_block(Vector3i(41, 1, 32)), 0, "pont levé : passage coupé")
	var g2 := Gates.new(w, sim.structures)
	g2.from_dict(sim.gates.to_dict())
	assert_eq(g2.gates.size(), 2)


func test_lits_libres_et_chambre_attribuee() -> void:
	var a := sim.structures.add("bed", Vector3i(5, 2, 5), true)
	var b := sim.structures.add("double_bed", Vector3i(8, 2, 5), true)
	var l0 := sim.colony.lutins[0]
	var l1 := sim.colony.lutins[1]
	for l in sim.colony.lutins:
		l.home = Vector3i(-1, -1, -1)
	sim.structures.assign_homes(sim.colony)
	var housed := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.home.y >= 0).size()
	assert_eq(housed, 3, "1 lit simple + 1 lit double, libres pour tous")
	sim.structures.assign_bed(b, [l0.id, l1.id], sim.colony)
	assert_eq(l0.home, Vector3i(8, 2, 5))
	assert_eq(l1.home, Vector3i(8, 2, 5))
	sim.structures.assign_bed(a, [l0.id], sim.colony)
	assert_eq(l0.home, Vector3i(5, 2, 5), "son lit attribué")


func test_cheval_capture_monte_plus_vite() -> void:
	var h := sim.fauna.spawn("horse", Vector3i(30, 2, 20))
	assert_string_contains(Horses.capture(sim, h), "mangeoire")
	sim.structures.add("feeder", Vector3i(25, 2, 25), true)
	sim.structures.add("water_trough", Vector3i(26, 2, 25), true)
	Horses.capture(sim, h)
	assert_true(h["owned"])
	var l := sim.colony.lutins[0]
	assert_true(LutinOrders.give(sim.colony, sim.board, l, "mount", h["cell"], {"horse": h["id"]}))
	_run(15)
	assert_eq(l.horse, h["id"], "il est en selle")
	assert_gt(Horses.speed_mult(l), 2.0)
	sim.colony.stock.items.erase("straw")
	for i in 3:
		Horses.daily(sim)
	assert_false(h["owned"], "sans paille, le cheval s'enfuit")


func test_loisirs_et_bar() -> void:
	sim.structures.add("bar_counter", Vector3i(24, 2, 20), true)
	sim.colony.stock.add("beer", 3)
	var l := sim.colony.lutins[0]
	l.order = {"kind": "leisure", "cell": Vector3i(24, 2, 20), "stage": 0, "until": 0, "tries": 0, "hold_s": 25.0}
	Leisure.enjoy(sim.colony, l)
	assert_gt(l.fun, 8.0, "jeu + bière")
	assert_eq(sim.colony.stock.count("beer"), 2)
	Leisure.daily(sim.colony)
	assert_lt(l.fun, 14.0 + 0.01)


func test_tutoriel_missions() -> void:
	sim.rules.mode = "tutorial"
	var ms := sim.missions
	ms.start_current()
	assert_eq(ms.current()["id"], "wood")
	sim.colony.stock.add("log", 6)
	ms.check()
	assert_eq(ms.current()["id"], "tents", "mission suivante")
	sim.structures.add("tent", Vector3i(5, 2, 5), true)
	sim.structures.add("tent", Vector3i(7, 2, 5), true)
	ms.check()
	assert_eq(ms.current()["id"], "fire")
	ms.index = ms.missions().size() - 1
	ms.start_current()
	sim.territory.reveal_all()
	ms.check()
	assert_true(ms.finished, "tutoriel terminé")


func test_emplacements_de_sauvegarde() -> void:
	SaveManager.meta_provider = func() -> Dictionary:
		return {"name": "Test", "mode": "Bac à sable", "day": 3, "lutins": 4}
	assert_true(SaveManager.save_game("slot5"))
	var info := SaveManager.slot_info("slot5")
	assert_eq(info["name"], "Test")
	SaveManager.delete_slot("slot5")
	assert_false(SaveManager.has_save("slot5"))
	assert_true(SaveManager.slot_info("slot5").is_empty())
	SaveManager.meta_provider = Callable()
