extends GutTest

var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(3)
	w = VoxelWorld.new(Vector3i(40, 32, 40))
	for x in 40:
		for z in 40:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))


func test_marche_d_un_bloc_mais_pas_deux() -> void:
	var stone := w.types.num("stone")
	w.set_raw(Vector3i(5, 1, 5), stone)  # marche d'1
	assert_true(Pathfinder.neighbors(w, Vector3i(4, 1, 5)).has(Vector3i(5, 2, 5)))
	w.set_raw(Vector3i(5, 2, 8), stone)
	w.set_raw(Vector3i(5, 1, 8), stone)  # mur de 2
	assert_false(Pathfinder.neighbors(w, Vector3i(4, 1, 8)).has(Vector3i(5, 3, 8)))


func test_pas_de_marche_sur_l_eau() -> void:
	w.set_raw(Vector3i(3, 1, 3), w.types.num("water"))
	assert_false(Pathfinder.walkable(w, Vector3i(3, 1, 3)))
	assert_false(Pathfinder.walkable(w, Vector3i(3, 2, 3)), "l'eau ne porte pas")


## Critère J3 : un lutin rejoint le sommet d'une tour par l'escalier intérieur.
func test_sommet_de_la_tour_par_l_escalier() -> void:
	var h := EditHistory.new(w)
	var st := w.types.num("cut_stone_block")
	for side: Array in [
		[Vector3i(10, 1, 10), Vector3i(14, 1, 10)],
		[Vector3i(14, 1, 10), Vector3i(14, 1, 14)],
		[Vector3i(14, 1, 14), Vector3i(10, 1, 14)],
		[Vector3i(10, 1, 14), Vector3i(10, 1, 11)]
	]:
		h.apply(Shapes.wall(side[0], side[1], 10), st)
	# porte au rez-de-chaussée (côté x=10, z=12) et escalier en colimaçon contre les murs
	w.set_raw(Vector3i(10, 1, 12), 0)
	w.set_raw(Vector3i(10, 2, 12), 0)
	var ring := [
		Vector3i(11, 0, 13),
		Vector3i(12, 0, 13),
		Vector3i(13, 0, 13),
		Vector3i(13, 0, 12),
		Vector3i(13, 0, 11),
		Vector3i(12, 0, 11),
		Vector3i(11, 0, 11),
		Vector3i(11, 0, 12)
	]
	for i in 10:
		var p: Vector3i = ring[i % 8] + Vector3i(0, i + 1, 0)
		w.set_raw(p, st)
		for k in range(1, 3):  # dégager la tête au-dessus des marches
			if w.get_block(p + Vector3i(0, k, 0)) != 0 and (p + Vector3i(0, k, 0)).y > i + 1:
				pass
	var top: Vector3i = ring[9 % 8] + Vector3i(0, 11, 0)
	assert_true(Pathfinder.walkable(w, top), "case du sommet marchable")
	var path := Pathfinder.find(w, Vector3i(5, 1, 12), top, 50000)
	assert_false(path.is_empty(), "chemin jusqu'au sommet")
	for i in range(1, path.size()):
		assert_lte(absi(path[i].y - path[i - 1].y), 1, "jamais plus d'1 bloc de dénivelé")


func test_trois_jours_sans_blocage() -> void:
	var c := Colony.new(w)
	c.spawn_start(Vector3i(20, 1, 20), 6)
	assert_eq(c.lutins.size(), 6)
	var food_before := c.stock.food_total()
	var slept := {}
	for i in GameClock.ticks_per_day() * 3:
		GameClock.step()
		c.tick()
		for l in c.lutins:
			if l.state == Lutin.State.SLEEP:
				slept[l.id] = true
	for l in c.lutins:
		assert_true(Pathfinder.walkable(w, l.cell), "%s sur une case valide" % l.name)
		assert_gt(l.needs["hunger"], 0.0, "%s n'est pas affamé" % l.name)
		assert_gt(l.needs["sleep"], 0.0)
	assert_eq(slept.size(), 6, "tous ont dormi")
	assert_lt(c.stock.food_total(), food_before, "ils ont mangé")


func test_metiers_connus_gardent_leur_niveau() -> void:
	var l := Lutin.new()
	l.set_job("woodcutter")
	l.add_xp(350.0, 100.0)  # niv 1→2 (100), 2→3 (200), reste 50
	assert_eq(l.job_level(), 3)
	l.set_job("miner")
	assert_eq(l.job_level(), 1, "nouveau métier : niveau 1")
	l.set_job("woodcutter")
	assert_eq(l.job_level(), 3, "ancien métier : niveau gardé")


func test_colonie_aller_retour() -> void:
	var c := Colony.new(w)
	c.spawn_start(Vector3i(20, 1, 20), 4)
	for i in 300:
		GameClock.step()
		c.tick()
	var d: Dictionary = JSON.parse_string(JSON.stringify(c.to_dict()))
	var c2 := Colony.new(w)
	c2.from_dict(d)
	assert_eq(c2.lutins.size(), 4)
	assert_eq(c2.lutins[2].name, c.lutins[2].name)
	assert_eq(c2.lutins[2].cell, c.lutins[2].cell)
	assert_eq(c2.stock.food_total(), c.stock.food_total())
