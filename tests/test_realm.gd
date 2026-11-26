extends GutTest
## 1.1 : ordres directs, charrette, royaume (titres, seigneur, prison, lois, taxes, diplomatie, garnison), unités.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(11)
	w = VoxelWorld.new(Vector3i(48, 32, 48))
	for x in 48:
		for z in 48:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(24, 2, 24), 6)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		sim.tick()


## Pièce fermée 5×5 (murs + toit) autour de (x0..x0+4, z0..z0+4), intérieur 3×3.
func _room(x0: int, z0: int) -> void:
	var st := w.types.num("stone")
	for x in range(x0, x0 + 5):
		for z in range(z0, z0 + 5):
			w.set_block(Vector3i(x, 5, z), st)
			if x in [x0, x0 + 4] or z in [z0, z0 + 4]:
				for y in range(2, 5):
					w.set_block(Vector3i(x, y, z), st)


func test_ordre_aller_ici() -> void:
	var l := sim.colony.lutins[0]
	assert_true(LutinOrders.give(sim.colony, sim.board, l, "move", Vector3i(34, 2, 24)))
	_run(20)
	assert_lt((l.cell - Vector3i(34, 2, 24)).length(), 2.0, "il est allé à l'endroit voulu")
	assert_eq(l.order["stage"], 1, "il attend sur place")


func test_ordre_couper_un_arbre_est_prioritaire_et_reserve() -> void:
	var l := sim.colony.lutins[0]
	sim.flora.trees[Vector3i(30, 2, 30)] = "pin"
	assert_true(LutinOrders.give(sim.colony, sim.board, l, "cut", Vector3i(30, 2, 30)))
	var t: Dictionary = sim.board.tasks.values()[0]
	assert_eq(t["assigned"], [l.id])
	assert_true(t["order"])
	_run(60)
	assert_false(sim.flora.trees.has(Vector3i(30, 2, 30)), "l'arbre est coupé par ce lutin")


func test_deplacer_la_charrette() -> void:
	var l := sim.colony.lutins[1]
	assert_true(LutinOrders.give(sim.colony, sim.board, l, "cart", Vector3i(14, 2, 24)))
	_run(40)
	assert_eq(sim.colony.stock.pos, Vector3i(14, 2, 24), "la réserve suit la charrette")


func test_taxes_lois_et_moral() -> void:
	var r := sim.realm
	var gold := sim.colony.stock.count("gold")
	r.tax = "high"
	r.daily()
	assert_eq(sim.colony.stock.count("gold"), gold + 6, "6 adultes × 1 or")
	var l := sim.colony.lutins[0]
	var m0 := r.mood_for(l)
	r.toggle_law("feast_day")
	assert_gt(r.mood_for(l), m0)
	assert_almost_eq(r.work_mult(), 0.9, 0.001)
	r.toggle_law("feast_day")
	r.toggle_law("rations")
	assert_almost_eq(r.food_mult(), 0.75, 0.001)


func test_titres_seigneur_et_salle_du_trone() -> void:
	var r := sim.realm
	var l := sim.colony.lutins[2]
	assert_eq(r.promote(l), "notable")
	assert_false(r.set_lord(l), "pas de salle du trône")
	_room(4, 4)
	sim.structures.add("throne", Vector3i(5, 2, 5), true)
	sim.structures.add("banner_wall", Vector3i(7, 2, 7), true)
	assert_true(r.throne_room_ok())
	assert_true(r.set_lord(l))
	assert_eq(r.lord_id, l.id)


func test_prison_avec_une_cage() -> void:
	var r := sim.realm
	var l := sim.colony.lutins[3]
	assert_false(r.imprison(l), "pas de cage")
	sim.structures.add("iron_cage", Vector3i(20, 2, 20), true)
	assert_true(r.imprison(l))
	_run(5)
	assert_eq(l.cell, Vector3i(20, 2, 20), "le prisonnier est dans la cage")
	assert_false(LutinOrders.give(sim.colony, sim.board, l, "move", Vector3i(30, 2, 30)), "pas d'ordre en cage")
	r.release_prisoner(l)
	assert_eq(l.jailed.y, -1)


func test_diplomatie_cadeau_et_accord_commercial() -> void:
	var r := sim.realm
	sim.colony.stock.add("gold", 100)
	var before := sim.trade.sell_price("log")
	assert_string_contains(r.diplomacy("pierrefeu", "treaty"), "refusent")
	r.diplomacy("pierrefeu", "gift")
	assert_eq(r.relation("pierrefeu"), 30.0)
	r.diplomacy("pierrefeu", "treaty")
	assert_eq(r.status("pierrefeu"), "trade")
	assert_gt(r.trade_bonus(), 0.0)
	assert_gte(sim.trade.sell_price("log"), before)


func test_garnison_soldats_et_entrainement() -> void:
	var r := sim.realm
	assert_eq(r.garrison_capacity(), 2)
	assert_true(r.enroll(sim.colony.lutins[0]))
	assert_true(r.enroll(sim.colony.lutins[1]))
	assert_false(r.enroll(sim.colony.lutins[2]), "plus de place sans garnison")
	_room(30, 30)
	for i in 3:
		sim.structures.add("wood_bed", Vector3i(31 + i, 2, 31), true)
	sim.structures.add("chest", Vector3i(31, 2, 33), true)
	sim.structures.add("weapon_rack", Vector3i(33, 2, 33), true)
	assert_eq(r.garrison_capacity(), 5, "3 lits de garnison en plus")
	w.set_block(Vector3i(24, 1, 28), w.types.num("training_ground"))
	assert_true(r.training_cells.has(Vector3i(24, 2, 28)))
	var s := sim.colony.lutins[0]
	sim.colony.lutins[0].needs["sleep"] = 100.0
	_run(30)
	assert_gt(s.combat_xp, 0.0, "le soldat s'entraîne")


func test_unite_en_formation_et_attaque() -> void:
	var u := sim.units
	var ids := []
	for l in sim.colony.lutins:
		ids.append(l.id)
	var id := u.create("Première lance", ids[0], ids.slice(1, 5))
	assert_eq(u.units[id]["members"].size(), 5)
	u.set_formation(id, "square")
	u.command(id, "move", Vector3i(30, 2, 24))
	var slots := {}
	for i in 5:
		slots[u.slot(u.units[id], i)] = true
	assert_eq(slots.size(), 5, "une place différente par membre")
	_run(25)
	assert_lt((sim.colony.find_lutin(ids[0]).cell - Vector3i(30, 2, 24)).length(), 3.0, "l'unité est arrivée")
	sim.colony.stock.add("spear", 5)
	u.command(id, "attack", Vector3i(30, 2, 30))
	assert_true(sim.colony.find_lutin(ids[1]).mobilized)
	assert_ne(sim.colony.find_lutin(ids[1]).weapon, "")
	u.disband(id)
	assert_false(sim.colony.find_lutin(ids[1]).mobilized)


func test_sauvegarde_royaume_unites_et_lutins() -> void:
	var r := sim.realm
	r.tax = "normal"
	r.toggle_law("curfew")
	r.diplomacy("clan_crocs", "insult")
	var l := sim.colony.lutins[0]
	l.combat_xp = 42.0
	l.title = "knight"
	LutinOrders.give(sim.colony, sim.board, l, "move", Vector3i(30, 2, 24))
	var id := sim.units.create("Garde", l.id, [sim.colony.lutins[1].id])
	var sim2 := GameSim.new(w)
	sim2.colony.from_dict(sim.colony.to_dict())
	sim2.realm.from_dict(sim.realm.to_dict())
	sim2.units.from_dict(sim.units.to_dict())
	var l2 := sim2.colony.find_lutin(l.id)
	assert_eq(l2.combat_xp, 42.0)
	assert_eq(l2.title, "knight")
	assert_eq(l2.order["cell"], Vector3i(30, 2, 24))
	assert_eq(sim2.realm.tax, "normal")
	assert_true(sim2.realm.law_on("curfew"))
	assert_eq(sim2.realm.relation("clan_crocs"), r.relation("clan_crocs"))
	assert_eq(sim2.units.units[id]["members"], sim.units.units[id]["members"])
