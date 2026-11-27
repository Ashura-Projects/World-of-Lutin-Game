extends GutTest
## Phase 2 : camps d'orcs, raids, siège (casse et effondrement), défense (créneaux, tir des gardes), camp détruit.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(21)
	GameSetup.reset_defaults()
	GameSetup.orcs = true
	w = VoxelWorld.new(Vector3i(64, 32, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(12, 2, 12), 4)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		sim.tick()


func test_camp_et_garnison() -> void:
	var c := sim.orcs.add_camp(Vector3i(50, 2, 50))
	assert_gte(sim.orcs.orcs_of(c["id"]).size(), 4, "3 orcs et un archer")
	assert_eq(sim.orcs.alive_camps().size(), 1)


func test_raid_marche_sur_le_village() -> void:
	sim.orcs.add_camp(Vector3i(50, 2, 50))
	var n := sim.orcs.raid()
	assert_gt(n, 0)
	var raider: Dictionary = sim.fauna.animals.filter(func(a: Dictionary) -> bool: return a.get("raid", false))[0]
	var d0 := Vector3(raider["cell"]).distance_to(Vector3(sim.colony.stock.pos))
	_run(12)
	if sim.fauna.animals.has(raider):
		assert_lt(Vector3(raider["cell"]).distance_to(Vector3(sim.colony.stock.pos)), d0 - 5.0, "il s'approche")


func test_siege_casse_un_mur_et_effondrement() -> void:
	var st := w.types.num("stone")
	# un orc coincé derrière un mur : il le casse
	var a := sim.fauna.spawn("orc", Vector3i(30, 2, 12))
	a["raid"] = true
	a["goal"] = Vector3i(12, 2, 12)
	a["blocked_at"] = 0
	for y in range(2, 6):
		w.set_block(Vector3i(29, y, 12), st)
	_run(8)
	assert_eq(w.get_block(Vector3i(29, 3, 12)), 0, "le bloc qui gênait est tombé")
	# effondrement : un bloc suspendu sans appui
	w.set_block(Vector3i(40, 6, 40), st)
	w.set_block(Vector3i(40, 5, 40), st)
	w.set_block(Vector3i(40, 5, 40), 0)
	assert_eq(sim.orcs.collapse_above(Vector3i(40, 5, 40)), 1)
	assert_eq(w.get_block(Vector3i(40, 6, 40)), 0)


func test_garde_tire_depuis_les_creneaux() -> void:
	var l := sim.colony.lutins[0]
	sim.colony.stock.add("flintlock", 1)
	assert_true(sim.realm.enroll(l))
	assert_eq(l.weapon, "flintlock")
	l.place_at(Vector3i(20, 2, 20))
	w.set_block(Vector3i(21, 2, 20), w.types.num("crenel"))
	assert_true(Defense.behind_crenel(w, l.cell))
	assert_lt(sim.combat.armor_factor(l), 1.0, "moins de dégâts derrière un créneau")
	var o := sim.fauna.spawn("orc", Vector3i(26, 2, 20))
	var hp0: float = o["hp"]
	for i in 30:
		GameClock.step()
		sim.combat.tick()
	assert_lt(float(o["hp"]) if sim.fauna.animals.has(o) else 0.0, hp0, "le garde a tiré")


func test_camp_detruit_et_butin() -> void:
	var c := sim.orcs.add_camp(Vector3i(50, 2, 50))
	for a in sim.orcs.orcs_of(c["id"]):
		sim.fauna.damage(a["id"], 9999.0)
	var l := sim.colony.lutins[0]
	sim.combat.arm(l)
	l.place_at(Vector3i(51, 2, 50))
	var gold := sim.colony.stock.count("gold")
	sim.orcs._check_camps()
	assert_true(c["destroyed"])
	assert_gt(sim.colony.stock.count("gold"), gold)


func test_raids_reguliers_et_sauvegarde() -> void:
	sim.orcs.add_camp(Vector3i(50, 2, 50))
	sim.orcs.next_raid_day = GameClock.day() + 1
	sim.orcs.daily(GameClock.day() + 1)
	assert_eq(sim.orcs.raid_count, 1)
	assert_eq(sim.orcs.next_raid_day, GameClock.day() + 1 + sim.orcs.interval())
	var f2 := Fauna.new(w)
	f2.from_dict(sim.fauna.to_dict())
	var raiders := f2.animals.filter(func(a: Dictionary) -> bool: return a.get("raid", false))
	assert_gt(raiders.size(), 0, "les raiders restent des raiders après chargement")
	assert_true(raiders[0]["goal"] is Vector3i)
	var o2 := Orcs.new(w, f2, sim.colony, sim.flora)
	o2.from_dict(sim.orcs.to_dict())
	assert_eq(o2.camps.size(), 1)
	assert_eq(o2.raid_count, 1)
