extends GutTest
## Critère J7 : sauvegarde → réouverture = identique (toute la simulation).


func test_sauvegarde_complete_identique() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(77)
	var w := VoxelWorld.new(Vector3i(64, 48, 64))
	var gen := WorldGenerator.new(w, 77)
	gen.generate()
	var sim := GameSim.new(w)
	sim.register_saves()
	var start := Pathfinder.snap(w, Vector3i(32, w.surface_y(32, 32), 32))
	sim.new_game(gen, start, 6)
	sim.structures.add("campfire", start + Vector3i(2, 0, 0), true)
	sim.board.order_circle("cut", start, 10)
	sim.fields.plan(Vector3i(start.x + 3, start.y - 1, start.z + 3), "wheat")
	for i in 600:
		GameClock.step()
		sim.tick()
	assert_true(SaveManager.save_game("test_complet"))
	var before := JSON.stringify(SaveManager.build_snapshot())
	sim.unregister_saves()
	# nouvelle simulation vierge, puis chargement
	var w2 := VoxelWorld.new(Vector3i(8, 8, 8))
	var sim2 := GameSim.new(w2)
	sim2.register_saves()
	GameClock.reset()
	assert_true(SaveManager.load_game("test_complet"))
	var after := JSON.stringify(SaveManager.build_snapshot())
	if after != before:
		for pair: Array in [["/tmp/claude-0/avant.json", before], ["/tmp/claude-0/apres.json", after]]:
			var f := FileAccess.open(pair[0], FileAccess.WRITE)
			f.store_string(pair[1])
			f.close()
	assert_eq(after.length(), before.length())
	assert_eq(after, before, "état identique après rechargement")
	assert_eq(sim2.colony.lutins.size(), 6)
	assert_eq(sim2.world.size, Vector3i(64, 48, 64))
	sim2.unregister_saves()
