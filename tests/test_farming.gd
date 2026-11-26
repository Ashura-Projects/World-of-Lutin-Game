extends GutTest

var w: VoxelWorld
var c: Colony
var board: TaskBoard
var st: Structures
var fields: Fields
var prod: Production


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(4)
	w = VoxelWorld.new(Vector3i(40, 32, 40))
	for x in 40:
		for z in 40:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("fertile_soil" if x < 10 else "grass"))
	c = Colony.new(w)
	board = TaskBoard.new(w, c, Flora.new(), Fauna.new(w), GroundItems.new())
	st = Structures.new()
	board.structures = st
	c.structures = st
	fields = Fields.new()
	board.fields = fields
	prod = Production.new(board, fields)
	c.spawn_start(Vector3i(20, 2, 20), 6)
	c.stock.add("hoe", 2)
	c.change_job(c.lutins[0], "farmer")
	c.change_job(c.lutins[1], "farmer")


func _run(seconds: float) -> void:
	var tps := GameClock.ticks_per_second()
	for i in int(seconds * tps):
		GameClock.step()
		c.tick()
		if i % tps == 0:
			prod.plan()


func test_rendements_realistes() -> void:
	var y := Fields.harvest_yield("wheat", false, 1)
	assert_eq(y["wheat"], 3, "1 grain semé → 3 récoltés")
	assert_eq(y["straw"], 2, "les tiges donnent la paille")
	assert_eq(Fields.harvest_yield("potato", false, 1)["potato"], 5)
	assert_gt(Fields.harvest_yield("wheat", true, 5)["wheat"], 3, "terre fertile + fermier expérimenté")


func test_cycle_d_un_champ_case_par_case() -> void:
	for i in 4:
		fields.plan(Vector3i(5 + i, 1, 5), "wheat" if i < 2 else "flax")
	_run(160)  # trajets réels : réserve ↔ champ
	assert_eq(w.get_block(Vector3i(6, 1, 5)), w.types.num("field_plot"), "case labourée")
	assert_eq(fields.plots[Vector3i(5, 1, 5)]["state"], "sown", "semé au printemps")
	var seeds_left := c.stock.count("wheat")
	for d in 10:
		prod.daily()
	assert_eq(fields.plots[Vector3i(5, 1, 5)]["state"], "ripe", "blé mûr après 9 jours")
	GameClock.tick_index = GameClock.ticks_per_day() * 10 + int(GameClock.ticks_per_day() * 0.3)  # un matin
	for l in c.lutins:
		l.needs["sleep"] = 100.0
		l.state = Lutin.State.IDLE
	_run(120)
	assert_gt(c.stock.count("wheat"), seeds_left, "blé récolté et rentré")
	assert_gt(c.stock.count("straw"), 0, "paille récoltée")
	assert_gt(c.stock.count("flax"), 0, "lin récolté")


func test_rien_ne_pousse_l_hiver() -> void:
	fields.plots[Vector3i(1, 1, 1)] = {"crop": "wheat", "state": "sown", "growth": 0.0}
	GameClock.tick_index = GameClock.ticks_per_day() * 15 + 100  # hiver (saison 4)
	prod.daily()
	assert_eq(fields.plots[Vector3i(1, 1, 1)]["growth"], 0.0)


func _built(kind: String, cell: Vector3i) -> int:
	var id := st.add(kind, cell, true)
	return id


func test_chaine_ble_farine_pain() -> void:
	var mill := _built("mill", Vector3i(15, 2, 15))
	var oven := _built("oven", Vector3i(15, 2, 19))
	var well := _built("well", Vector3i(19, 2, 15))
	c.stock.add("flail", 1)
	c.stock.add("bread_peel", 1)
	assert_true(prod.assign_staff(mill, c.lutins[2]), "meunier affecté (prend le fléau)")
	assert_eq(c.lutins[2].job, "miller")
	assert_true(prod.assign_staff(oven, c.lutins[3]))
	assert_true(prod.assign_staff(well, c.lutins[4]))
	c.stock.add("wheat", 8)
	prod.add_order(mill, "grind_flour", "make", 2)
	prod.add_order(well, "draw_water", "keep", 2)
	prod.add_order(oven, "bake_bread", "make", 1)
	var bread := c.stock.count("bread")
	_run(240)
	assert_gt(c.stock.count("bread"), bread, "du pain sorti du four")


func test_pas_d_outil_pas_d_affectation() -> void:
	var mill := _built("mill", Vector3i(15, 2, 15))
	assert_false(prod.assign_staff(mill, c.lutins[5]), "aucun fléau en réserve")


func test_froid_l_hiver_sans_feu() -> void:
	GameClock.tick_index = GameClock.ticks_per_day() * 15 + 1000
	var l := c.lutins[5]
	c.tick()
	for i in GameClock.ticks_per_day() / 2:
		c._update_needs(l, float(GameClock.ticks_per_day()))
	assert_lt(l.needs["warmth"], 90.0, "il a froid loin d'un feu")
	_built("campfire", l.cell)
	for i in 700:
		c._update_needs(l, float(GameClock.ticks_per_day()))
	assert_gt(l.needs["warmth"], 90.0, "le feu de camp réchauffe")


func test_production_aller_retour() -> void:
	var mill := _built("mill", Vector3i(15, 2, 15))
	prod.add_order(mill, "grind_flour", "keep", 10)
	fields.plan(Vector3i(2, 1, 2), "potato")
	var p2 := Production.new(board, Fields.new())
	p2.from_dict(JSON.parse_string(JSON.stringify(prod.to_dict())))
	assert_eq(p2.orders[mill][0]["recipe"], "grind_flour")
	assert_eq(p2.fields.plots[Vector3i(2, 1, 2)]["crop"], "potato")


## Critère J6 : le village passe un hiver complet (5 jours) en autonomie : personne n'a faim ni froid à mourir.
func test_un_hiver_en_autonomie() -> void:
	_built("campfire", c.stock.pos + Vector3i(1, 0, 0))
	for i in 4:
		_built("tent", c.stock.pos + Vector3i(-3 + i * 2, 0, 3))
	st.assign_homes(c)
	c.stock.add("log", 20)
	c.stock.add("bread", 40)
	var logs := c.stock.count("log")
	var tpd := GameClock.ticks_per_day()
	GameClock.tick_index = tpd * 15 + int(tpd * 0.3)  # premier matin d'hiver
	var min_hunger := 100.0
	var min_warmth := 100.0
	for i in tpd * 5:
		GameClock.step()
		c.tick()
		if i % tpd == 0:
			prod.daily()
			c.heating_ok = not prod.fire_out
		for l in c.lutins:
			min_hunger = minf(min_hunger, l.needs["hunger"])
			min_warmth = minf(min_warmth, l.needs["warmth"])
	assert_gt(min_hunger, 5.0, "personne n'a eu faim au point de mourir")
	assert_gt(min_warmth, 5.0, "personne n'a gelé")
	assert_lt(c.stock.count("log"), logs, "le feu a consommé du bois")
