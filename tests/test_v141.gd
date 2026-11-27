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
