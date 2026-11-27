extends GutTest
## 1.4.1 : économie des villages IA (métiers, production, famine, améliorations).


func _st() -> Dictionary:
	return {
		"id": "jaune", "center": Vector3i(60, 2, 60), "houses": [], "population": 20, "soldiers": 3, "wealth": 100.0
	}


func test_metiers_repartis() -> void:
	var st := _st()
	RivalEconomy.assign_jobs(st)
	var n := 0
	for k: String in st["jobs"]:
		if k != "soldier":
			n += int(st["jobs"][k])
	assert_eq(n, 17, "tous les habitants hors soldats ont un métier")
	assert_gt(int(st["jobs"]["miner"]), 1, "les jaunes sont mineurs")


func test_production_et_ventes() -> void:
	var st := _st()
	RivalEconomy.daily(st)
	assert_gt(float(st["stock"]["wood"]), 10.0, "les bûcherons produisent")
	assert_gt(float(st["stock"]["stone"]), 5.0, "les mineurs produisent")
	assert_gt(float(st["wealth"]), 100.0, "les marchandises se vendent")


func test_famine() -> void:
	Rng.set_seed(1)
	var st := _st()
	st["population"] = 60
	st["soldiers"] = 55
	st["stock"] = {"food": 0.0}
	var pop := 60
	for i in 20:
		RivalEconomy.daily(st)
	assert_lt(int(st["population"]), pop, "sans vivres, la population baisse")


func test_amelioration() -> void:
	var st := _st()
	st["buildings"] = [{"id": "workshop", "cell": [0, 0, 0], "level": 1}]
	st["stock"] = {"wood": 100.0, "stone": 100.0}
	var before := RivalBuilder.effect(st, "wealth")
	assert_eq(RivalEconomy.upgrade(st), "workshop")
	assert_eq(int(st["buildings"][0]["level"]), 2)
	assert_almost_eq(RivalBuilder.effect(st, "wealth"), before * 2.0, 0.001, "effets × niveau")


func _sim() -> GameSim:
	GameClock.configure()
	GameClock.reset(true)
	GameSetup.reset_defaults()
	var w := VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	var sim := GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 6)
	sim.missions.campaign = true
	sim.missions.start_current()
	return sim


func test_campagne_chapitre_1_puis_2() -> void:
	var sim := _sim()
	var ms := sim.missions
	assert_eq(ms.chapter_def()["id"], 1)
	assert_eq(ms.current()["title"], "Du bois pour l'hiver")
	var got := []
	ms.chapter_done.connect(func(c: int) -> void: got.append(c))
	sim.colony.stock.add("log", 10)
	ms.check()
	sim.structures.add("tent", Vector3i(30, 2, 30), true)
	sim.structures.add("tent_cloth", Vector3i(34, 2, 30), true)
	ms.check()
	sim.structures.add("campfire", Vector3i(38, 2, 30), true)
	ms.check()
	var bread := sim.colony.stock.count("bread")
	sim.colony.add_store_cells([Vector3i(40, 2, 40)])
	ms.check()
	assert_eq(got, [0], "chapitre 1 terminé")
	assert_eq(ms.chapter, 1)
	assert_eq(ms.chapter_def()["title"], "Le premier village")
	assert_gt(sim.colony.stock.count("bread"), bread, "récompense donnée")


func test_objectifs_campagne() -> void:
	var sim := _sim()
	assert_eq(CampaignGoals.value(sim, {"kind": "population"}, {}), 6)
	assert_eq(CampaignGoals.value(sim, {"kind": "diplomat"}, {}), 0)
	sim.realm.diplomat_id = sim.colony.lutins[0].id
	assert_eq(CampaignGoals.value(sim, {"kind": "diplomat"}, {}), 1)
	assert_eq(CampaignGoals.value(sim, {"kind": "stock_gain"}, {}), -1, "objectif du tutoriel : pas d'ici")


func test_sauvegarde_campagne() -> void:
	var sim := _sim()
	sim.missions.chapter = 3
	var t2 := TutorialMissions.new(sim)
	t2.from_dict(sim.missions.to_dict())
	assert_true(t2.campaign)
	assert_eq(t2.chapter, 3)
	assert_eq(t2.chapter_def()["id"], 4)
