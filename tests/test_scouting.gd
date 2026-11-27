extends GutTest
## Brouillard de guerre et éclaireurs : exploration autonome, camp la nuit, retour à la base.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(8)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(160, 24, 160))
	for x in 160:
		for z in 160:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(30, 2, 30), 2)
	sim.territory.explore(Vector3i(30, 2, 30), 2)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		sim.tick()


func test_l_eclaireur_explore_seul() -> void:
	var l := sim.colony.lutins[0]
	l.set_job("scout")
	var before := sim.territory.explored.size()
	assert_true(LutinOrders.give(sim.colony, sim.board, l, "explore", l.cell))
	_run(60)
	assert_gt(sim.territory.explored.size(), before + 6, "de nouvelles zones découvertes")
	assert_gt(Vector3(l.cell).distance_to(Vector3(30, 2, 30)), 20.0, "il est parti loin")


func test_camp_la_nuit_et_retour() -> void:
	var l := sim.colony.lutins[0]
	LutinOrders.give(sim.colony, sim.board, l, "explore", l.cell)
	DebugTools.set_hour(0.02)
	_run(2)
	assert_eq(l.state, Lutin.State.SLEEP, "il dort la nuit")
	assert_true(l.order.has("camp"), "petit camp monté")
	DebugTools.set_hour(0.45)
	_run(3)
	assert_false(l.order.has("camp"), "il repart au matin")
	LutinOrders.give(sim.colony, sim.board, l, "move", sim.colony.stock.pos)
	assert_eq(l.order["kind"], "move", "ordre retour à la base")


func test_brouillard_cache_les_factions_et_les_camps() -> void:
	var c := sim.orcs.add_camp(Vector3i(140, 2, 140))
	sim.orcs.check_discovery(sim.territory)
	assert_false(c["discovered"])
	sim.territory.explore(Vector3i(140, 2, 140), 1)
	sim.orcs.check_discovery(sim.territory)
	assert_true(c["discovered"], "repéré une fois la zone explorée")
	assert_eq(Scouting.next_goal(w, sim.territory, Vector3i(30, 2, 30), 40).y, 2, "il reste des zones à explorer")
	sim.territory.reveal_all()
	assert_eq(Scouting.next_goal(w, sim.territory, Vector3i(30, 2, 30), 40).y, -1, "tout est exploré")
