extends GutTest
## 1.4 : mode Bataille (cartes plaine / forêt / collines, poser alliés et ennemis, combat).

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(5)
	GameSetup.reset_defaults()
	GameSetup.set_mode("battle")


func after_each() -> void:
	GameSetup.reset_defaults()


func test_carte_de_bataille_sans_riviere() -> void:
	for t: String in ["plain", "forest", "hills"]:
		w = VoxelWorld.new(Vector3i(64, 64, 64))
		var g := WorldGenerator.new(w, 5)
		g.preset = t
		g.generate()
		var water := 0
		for x in range(0, 64, 4):
			for z in range(0, 64, 4):
				for y in 40:
					water += int(w.get_block(Vector3i(x, y, z)) == w.types.num("water"))
		assert_eq(water, 0, "%s : pas de rivière ni de lac" % t)
		if t == "forest":
			assert_gt(g.trees.size(), 60, "forêt dense")


func test_poser_et_combattre() -> void:
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 2)
	Battle.setup(sim)
	assert_true(sim.rules.free_build)
	assert_eq(Battle.place_allies(sim, "rider", Vector3i(22, 2, 22), 3), 3)
	assert_eq(Battle.place_enemies(sim, "orc", Vector3i(27, 2, 27), 4), 4)
	var f := Battle.forces(sim)
	assert_eq(f[0], 5)
	assert_eq(f[1], 4)
	var riders := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.horse >= 0).size()
	assert_eq(riders, 3, "cavaliers à cheval")
	for i in 30 * GameClock.ticks_per_second():
		GameClock.step()
		sim.tick()
	var f2 := Battle.forces(sim)
	assert_true(f2[0] < 5 or f2[1] < 4, "le combat a eu lieu")
	assert_eq(Battle.clear_enemies(sim), f2[1])
