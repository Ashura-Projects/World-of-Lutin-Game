extends Node
## Mesure du tick de simulation : grande carte, 50 lutins actifs (récolte, construction, faune).
## Usage : godot --headless res://tools/bench/bench_tick.tscn

var _done := false


func _process(_d: float) -> void:
	if _done:
		return
	_done = true
	GameSetup.map_size = "large"
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(1234)
	var w := VoxelWorld.new(GameSetup.map_dims())
	var gen := WorldGenerator.new(w, 1234)
	gen.generate()
	var sim := GameSim.new(w)
	var start := Pathfinder.snap(w, Vector3i(128, w.surface_y(128, 128), 128))
	sim.new_game(gen, start, 10)
	for i in 40:  # porter la population à 50
		sim.colony.spawn_start(start, 1)
	sim.colony.stock.add("axe", 10)
	sim.colony.auto_assign_jobs()
	sim.board.order_circle("cut", start, 20)
	sim.board.order_circle("gather", start, 20)
	var worst := 0
	var total := 0
	var n := 600
	var parts := {"colony": 0, "combat": 0, "fauna": 0, "prod": 0}
	for i in n:
		GameClock.step()
		var t0 := Time.get_ticks_usec()
		sim.colony.tick()
		var t1 := Time.get_ticks_usec()
		sim.combat.tick()
		var t2 := Time.get_ticks_usec()
		if GameClock.tick_index % 2 == 0:
			var cells := []
			for l in sim.colony.lutins:
				cells.append(l.cell)
			sim.fauna.tick(cells)
		var t3 := Time.get_ticks_usec()
		if GameClock.tick_index % 10 == 0:
			sim.production.plan()
		var t4 := Time.get_ticks_usec()
		parts["colony"] += t1 - t0
		parts["combat"] += t2 - t1
		parts["fauna"] += t3 - t2
		parts["prod"] += t4 - t3
		var dt := t4 - t0
		if dt > 15000:
			print("PIC tick=%d colony=%d combat=%d fauna=%d prod=%d" % [i, t1 - t0, t2 - t1, t3 - t2, t4 - t3])
		total += dt
		worst = maxi(worst, dt)
	print("PART dont_recherches %.2fms" % [sim.colony.prof_search / 1000.0 / n])
	for k: String in parts:
		print("PART %s %.2fms" % [k, parts[k] / 1000.0 / n])
	print(
		(
			"BENCHTICK lutins=%d animaux=%d taches=%d tick_moyen=%.2fms tick_pire=%.2fms"
			% [
				sim.colony.lutins.size(),
				sim.fauna.animals.size(),
				sim.board.tasks.size(),
				total / 1000.0 / n,
				worst / 1000.0
			]
		)
	)
	get_tree().quit()
