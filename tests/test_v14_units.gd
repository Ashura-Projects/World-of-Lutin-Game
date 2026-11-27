extends GutTest
## 1.4 : unités v2 (types, armes, chevaux, rôles, sous-unités débloquées par le Commandement, repos, entraînement),
## qualités des soldats et bonus du commandant.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(14)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 8)


func _unit() -> Dictionary:
	var ids := []
	for l: Lutin in sim.colony.lutins:
		ids.append(l.id)
	var uid := sim.units.create("Garde", ids[0], ids.slice(1, 8))
	return sim.units.units[uid]


func test_type_fusiliers_prend_les_fusils() -> void:
	sim.colony.stock.add("flintlock", 3)
	var have := sim.colony.stock.count("flintlock")
	var u := _unit()
	UnitSetup.set_type(sim.units, u, "fusiliers")
	var armed := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.weapon == "flintlock").size()
	assert_eq(armed, mini(have, 8), "autant de fusils que la réserve en a")
	assert_eq(UnitSetup.type_name(u), "Fusiliers")


func test_arme_par_soldat_prioritaire() -> void:
	sim.colony.stock.add("spear", 5)
	sim.colony.stock.add("flintlock", 5)
	var u := _unit()
	var lid: int = u["members"][2]
	UnitSetup.set_type(sim.units, u, "lancers")
	UnitSetup.set_gear(sim.units, u, lid, "weapon", "flintlock")
	assert_eq(sim.colony.find_lutin(lid).weapon, "flintlock", "unité mixte : ce soldat a un fusil")
	assert_eq(sim.colony.find_lutin(u["members"][1]).weapon, "spear")


func test_commandant_plus_20_pourcent_pv() -> void:
	var u := _unit()
	var cap := sim.colony.find_lutin(u["captain"])
	var other := sim.colony.find_lutin(u["members"][1])
	assert_almost_eq(Soldiering.max_hp(cap) / Soldiering.max_hp(other), 1.2, 0.001)


func test_entrainement_et_qualites() -> void:
	var l := sim.colony.lutins[0]
	var hp0 := Soldiering.max_hp(l)
	Soldiering.add_drill(l, "robust", 250.0)
	Soldiering.add_drill(l, "agility", 100.0)
	assert_eq(Soldiering.drill_level(l, "robust"), 2)
	assert_gt(Soldiering.max_hp(l), hp0, "robustesse : plus de PV")
	assert_gt(Soldiering.move_mult(l), 1.0, "agilité : plus rapide")
	assert_lt(Soldiering.attack_delay_mult(l), 1.0, "agilité : attaque plus vite")


func test_commandement_boost_et_sous_unites() -> void:
	var u := _unit()
	var cap := sim.colony.find_lutin(u["captain"])
	var soldier := sim.colony.find_lutin(u["members"][1])
	assert_eq(UnitSetup.max_squads(sim.units, u), 2, "commandant + 1 lieutenant au départ")
	var base := Soldiering.damage_mult(soldier)
	cap.skills["command"] = {"level": 5, "xp": 0.0}
	assert_gt(Soldiering.damage_mult(soldier), base, "un bon chef renforce ses soldats")
	assert_eq(UnitSetup.max_squads(sim.units, u), 3, "niveau 5 : une sous-unité de plus")
	assert_true(UnitSetup.set_lieutenant(sim.units, u, 2, u["members"][3]))
	assert_false(UnitSetup.set_lieutenant(sim.units, u, 3, u["members"][4]), "pas encore débloquée")
	for i in 60:
		Soldiering.on_strike(soldier, true)
	assert_gt(Soldiering.skill_level(cap, "command"), 5, "les combats font monter le Commandement")


func test_ordre_a_une_seule_sous_unite() -> void:
	var u := _unit()
	var lt: int = u["members"][1]
	UnitSetup.set_lieutenant(sim.units, u, 1, lt)
	UnitSetup.set_squad(sim.units, u, u["members"][2], 1)
	sim.units.command(u["id"], "move", Vector3i(40, 2, 40), 1)
	var moved := 0
	for m: int in u["members"]:
		if not sim.colony.find_lutin(m).order.is_empty():
			moved += 1
	assert_eq(moved, 2, "seuls le lieutenant et les siens reçoivent l'ordre")


func test_repos_monte_et_leve_le_camp() -> void:
	var u := _unit()
	UnitSetup.set_cook(u, u["members"][1])
	sim.units.command(u["id"], "rest")
	var tents := sim.structures.items.values().filter(func(s: Dictionary) -> bool: return s["kind"] == "camp_tent")
	assert_gt(tents.size(), 0, "des tentes sont montées")
	var l := sim.colony.find_lutin(u["members"][3])
	l.needs["hunger"] = 20.0
	sim.colony.stock.add("bread", 5)
	UnitCamp.tick_second(sim.units)
	assert_gt(float(l.needs["hunger"]), 20.0, "le cuisinier le nourrit")
	sim.units.command(u["id"], "hold")
	tents = sim.structures.items.values().filter(func(s: Dictionary) -> bool: return s["kind"] == "camp_tent")
	assert_eq(tents.size(), 0, "on lève le camp")


func test_entrainement_sur_le_sol() -> void:
	var u := _unit()
	var l := sim.colony.find_lutin(u["captain"])
	Realm.active.training_cells[l.cell] = true
	u["train"] = "force"
	u["order"] = "train"
	UnitCamp.tick_second(sim.units)
	assert_gt(float(l.drill.get("force", 0.0)), 0.0)


func test_sauvegarde_unite_et_soldat() -> void:
	var u := _unit()
	UnitSetup.set_type(sim.units, u, "cavalry")
	UnitSetup.set_lieutenant(sim.units, u, 1, u["members"][1])
	var l := sim.colony.find_lutin(u["members"][1])
	Soldiering.add_drill(l, "force", 120.0)
	Soldiering.add_skill_xp(l, "command", 100.0)
	var u2 := Units.new(sim.colony, sim.combat)
	u2.from_dict(sim.units.to_dict())
	var r: Dictionary = u2.units[u["id"]]
	assert_eq(r["type"], "cavalry")
	assert_eq(UnitSetup.lieutenant_of(r, 1), l.id)
	var l2 := Lutin.new()
	l2.from_dict(l.to_dict())
	assert_eq(Soldiering.drill_level(l2, "force"), 1)
	assert_eq(Soldiering.skill_level(l2, "command"), Soldiering.skill_level(l, "command"))
	Units.active = sim.units
