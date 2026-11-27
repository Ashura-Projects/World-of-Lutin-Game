extends GutTest
## 1.4 : diplomatie à 7 niveaux et diplomate, cours du soir, villages et villes.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(41)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 6)
	sim.settlements.found("Premier village", Vector3i(20, 2, 20))


func test_niveaux_de_relation() -> void:
	var r := sim.realm
	var id: String = r.relations.keys()[0]
	r.relations[id]["relation"] = -90.0
	assert_eq(Diplomacy.level(r, id)["id"], "mortal")
	r.relations[id]["relation"] = 0.0
	assert_eq(Diplomacy.level(r, id)["id"], "neutral")
	r.relations[id]["relation"] = 50.0
	assert_eq(Diplomacy.level(r, id)["id"], "support")
	r.relations[id]["status"] = "alliance"
	assert_eq(Diplomacy.level(r, id)["id"], "alliance")


func test_diplomate_charisme_et_actions() -> void:
	var r := sim.realm
	var id: String = r.relations.keys()[0]
	assert_eq(Diplomacy.actions(r).filter(func(a: Dictionary) -> bool: return a["id"] == "alliance").size(), 0)
	var d := sim.colony.lutins[0]
	d.aptitudes["charisma"] = 80
	d.skills["diplomacy"] = {"level": 5, "xp": 0.0}
	r.diplomat_id = d.id
	assert_gt(Diplomacy.power(r), 1.0, "charisme et Diplomatie renforcent les effets")
	assert_eq(Diplomacy.actions(r).filter(func(a: Dictionary) -> bool: return a["id"] == "alliance").size(), 1)
	sim.colony.stock.add("gold", 100)
	var before := r.relation(id)
	Diplomacy.act(r, id, "gift_gold")
	assert_gt(r.relation(id) - before, 8.0, "cadeau plus efficace avec un bon diplomate")
	assert_gt(float(d.skills["diplomacy"]["xp"]), 0.0, "le diplomate apprend")


func test_cours_du_soir() -> void:
	var a := sim.colony.lutins[0]
	a.age_days = 200
	var t := sim.colony.lutins[1]
	t.set_job("teacher")
	var sid := sim.structures.add("school", Vector3i(30, 2, 30), true)
	sim.production.staff[sid] = [t.id]
	var c0 := int(a.aptitudes.get("charisma", 0))
	assert_true(sim.education.study(a, "charisma"))
	sim.education.daily()
	assert_gt(int(a.aptitudes["charisma"]), c0)


func test_village_habitants_et_balise() -> void:
	var st := sim.settlements
	assert_eq(st.items.size(), 1)
	assert_eq(st.residents(st.items[0]).size(), 6)
	sim.structures.add("village_post", Vector3i(60, 2, 60), true)
	assert_eq(st.items.size(), 2, "balise de village : nouveau village")
	var far := sim.colony.lutins[0]
	far.place_at(Vector3i(58, 2, 58))
	assert_eq(st.of_lutin(far)["id"], st.items[1]["id"])
	assert_false(st.city_check(st.items[0])[0], "pas encore une ville")


func test_sauvegarde_villages_et_diplomate() -> void:
	sim.realm.diplomat_id = sim.colony.lutins[0].id
	var r2 := Realm.new(sim.colony, sim.structures, w)
	r2.from_dict(sim.realm.to_dict())
	assert_eq(r2.diplomat_id, sim.realm.diplomat_id)
	var s2 := Settlements.new(sim.colony, sim.structures, w)
	s2.from_dict(sim.settlements.to_dict())
	assert_eq(s2.items.size(), sim.settlements.items.size())
	assert_eq(s2.items[0]["name"], "Premier village")
	Realm.active = sim.realm
