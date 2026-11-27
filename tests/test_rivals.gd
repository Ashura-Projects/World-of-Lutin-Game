extends GutTest
## Phase 2-3 : villages voisins (IA), territoires, guerre, raids, conquête, paix, victoire.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(5)
	GameSetup.reset_defaults()
	GameSetup.set_mode("royal")
	GameSetup.orcs = false
	w = VoxelWorld.new(Vector3i(256, 24, 256))
	for x in 256:
		for z in 256:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(128, 2, 128), 4)
	sim.rivals.setup_new(Vector3i(128, 2, 128), 3)


func test_villages_et_territoires() -> void:
	assert_gte(sim.rivals.states.size(), 2, "au moins deux villages voisins posés")
	var st: Dictionary = sim.rivals.states.values()[0]
	assert_gt(st["houses"].size(), 2, "des maisons")
	var h: Vector3i = st["houses"][0]
	assert_eq(w.get_block(h + Vector3i(0, 3, 0)), w.types.num("thatch_block"), "toit de chaume")
	assert_eq(sim.territory.owner_at(Vector3i(128, 2, 128)), "player")
	assert_eq(sim.territory.owner_at(st["center"]), st["id"])
	assert_gt(sim.rivals.units_of(st["id"], "villager_").size(), 0, "des villageois se promènent")
	assert_eq(sim.realm.neighbours().size(), sim.rivals.states.size())


func test_ia_grandit_et_s_etend() -> void:
	var st: Dictionary = sim.rivals.states.values()[0]
	st["wealth"] = 500.0
	var before := sim.territory.count(st["id"])
	for d in 30:
		sim.rivals.daily(d)
	assert_gt(sim.territory.count(st["id"]), before, "le territoire s'agrandit")


func test_guerre_raid_et_conquete() -> void:
	var st: Dictionary = sim.rivals.states.values()[0]
	var id: String = st["id"]
	sim.realm.diplomacy(id, "war")
	assert_eq(sim.realm.status(id), "war")
	assert_gt(sim.rivals.units_of(id, "soldier_").size(), 0, "des soldats défendent le village")
	st["last_raid"] = -100
	sim.rivals.daily(1)
	var raiders := sim.fauna.animals.filter(func(a: Dictionary) -> bool: return a.get("raid", false))
	assert_gt(raiders.size(), 0, "raid de soldats ennemis")
	for a in sim.rivals.units_of(id, "soldier_"):
		sim.fauna.damage(a["id"], 9999.0)
	var l := sim.colony.lutins[0]
	sim.colony.stock.add("spear", 1)
	sim.combat.arm(l)
	l.place_at(st["center"])
	var n0 := sim.colony.lutins.size()
	sim.rivals.check_conquest()
	assert_true(st["conquered"])
	assert_eq(sim.realm.status(id), "conquered")
	assert_eq(sim.territory.owner_at(st["center"]), "player", "le territoire passe au joueur")
	assert_gt(sim.colony.lutins.size(), n0, "des villageois rejoignent le village")


func test_paix_proposee_et_victoire() -> void:
	for st: Dictionary in sim.rivals.states.values():
		sim.realm.relations[st["id"]]["relation"] = -60.0
		sim.realm.diplomacy(st["id"], "war")
		st["war_days"] = 100
		st["last_raid"] = 1
	sim.rivals.daily(2)
	var first: Dictionary = sim.rivals.states.values()[0]
	assert_true(first["peace_offer"], "l'IA propose la paix")
	assert_string_contains(sim.realm.diplomacy(first["id"], "peace"), "paix est signée")
	assert_eq(sim.rivals.units_of(first["id"], "soldier_").size(), 0)
	for st: Dictionary in sim.rivals.states.values():
		sim.rivals.conquer(st["id"])
	sim.rivals.daily(3)
	assert_true(sim.rivals.won, "victoire : tout est conquis et pas d'orcs")


func test_sauvegarde_territoire_et_voisins() -> void:
	sim.territory.add_marker(Vector2i(10, 20), "★", "Mine d'or")
	var t2 := Territory.new(w)
	t2.from_dict(sim.territory.to_dict())
	assert_eq(t2.owners, sim.territory.owners)
	assert_eq(t2.markers.size(), 1)
	var r2 := Rivals.new(w, sim.fauna, sim.colony, sim.flora, t2)
	r2.from_dict(sim.rivals.to_dict())
	assert_eq(r2.states.size(), sim.rivals.states.size())
	var id: String = sim.rivals.states.keys()[0]
	assert_eq(r2.states[id]["center"], sim.rivals.states[id]["center"])
