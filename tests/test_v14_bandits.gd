extends GutTest
## 1.4 : bandits des forêts (camps, pillage, butin) et combats entre personnages non joueurs.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(7)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(128, 24, 128))
	for x in 128:
		for z in 128:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 4)
	for x in range(90, 110, 2):  # une grande forêt loin du village
		for z in range(90, 110, 2):
			sim.flora.trees[Vector3i(x, 2, z)] = "pin"


func test_camp_en_foret() -> void:
	sim.bandits.setup_new(Vector3i(20, 2, 20))
	assert_gt(sim.bandits.camps.size(), 0)
	var c: Dictionary = sim.bandits.camps[0]
	assert_gt(Vector3(c["cell"]).distance_to(Vector3(20, 2, 20)), 50.0, "loin du village")
	assert_gt(sim.bandits.members(c["id"]).size(), 0, "des bandits gardent le camp")


func test_pillage_vole_la_reserve() -> void:
	var c := sim.bandits.add_camp(Vector3i(100, 2, 100))
	var b: Dictionary = sim.bandits.members(c["id"])[0]
	sim.colony.stock.items.clear()
	sim.colony.stock.add("bread", 20)
	b["raid"] = true
	b["goal"] = sim.colony.stock.pos
	b["target_faction"] = "player"
	b["cell"] = sim.colony.stock.pos
	b["pos"] = Vector3(sim.colony.stock.pos)
	sim.bandits.tick_second()
	assert_lt(sim.colony.stock.count("bread"), 20, "ils ont volé")
	assert_false(b["raid"], "ils rentrent au camp")


func test_camp_vide_disparait() -> void:
	var c := sim.bandits.add_camp(Vector3i(100, 2, 100))
	for a: Dictionary in sim.bandits.members(c["id"]):
		sim.fauna.damage(a["id"], 9999.0)
	var gold := sim.colony.stock.count("gold")
	sim.bandits.daily()
	assert_true(c["destroyed"])
	assert_gt(sim.colony.stock.count("gold"), gold, "butin récupéré")


func test_bandits_contre_villageois() -> void:
	assert_true(NpcCombat.enemies("bandits", "jaune"))
	assert_false(NpcCombat.enemies("jaune", "jaune"))
	var c := sim.bandits.add_camp(Vector3i(100, 2, 100))
	var b: Dictionary = sim.bandits.members(c["id"])[0]
	var orc := sim.fauna.spawn("orc", b["cell"])
	orc["faction"] = "orcs"
	var hp := float(orc["hp"])
	NpcCombat.tick(sim.fauna, 0.5)
	NpcCombat.tick(sim.fauna, 0.5)
	assert_lt(float(orc["hp"]), hp, "les bandits frappent aussi les orcs")


func test_sauvegarde_bandits() -> void:
	sim.bandits.add_camp(Vector3i(100, 2, 100))
	var b2 := Bandits.new(sim)
	b2.from_dict(sim.bandits.to_dict())
	assert_eq(b2.camps.size(), 1)
	Bandits.active = sim.bandits
