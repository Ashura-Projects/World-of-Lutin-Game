extends GutTest

var w: VoxelWorld
var c: Colony
var fauna: Fauna
var ground: GroundItems
var combat: Combat


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(8)
	w = VoxelWorld.new(Vector3i(48, 32, 48))
	for x in 48:
		for z in 48:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	c = Colony.new(w)
	fauna = Fauna.new(w)
	ground = GroundItems.new()
	combat = Combat.new(c, fauna, ground)
	c.spawn_start(Vector3i(24, 2, 24), 4)


func _night() -> void:
	GameClock.tick_index = GameClock.ticks_per_day() + int(GameClock.ticks_per_day() * 0.9)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		c.tick()
		combat.tick()
		var cells := []
		for l in c.lutins:
			cells.append(l.cell)
		fauna.tick(cells)


func test_stats_fixes_et_realistes() -> void:
	var wolf := fauna.def("wolf")
	var bear := fauna.def("bear")
	assert_eq(int(wolf["hp"]), 40)
	assert_eq(int(bear["hp"]), 150)
	assert_gt(float(bear["damage"]), float(wolf["damage"]), "l'ours frappe plus fort")
	assert_gt(float(bear["reach"]), float(wolf["reach"]), "et plus loin")


func test_le_loup_attaque_la_nuit() -> void:
	_night()
	var total := 0.0
	for l in c.lutins:
		total += l.hp
	fauna.spawn("wolf", c.lutins[0].cell + Vector3i(4, 0, 0))
	_run(15)
	var after := 0.0
	for l in c.lutins:
		after += l.hp
	assert_lt(after, total, "le loup a mordu un lutin")


func test_mobilisation_abat_le_loup() -> void:
	_night()
	c.stock.add("flintlock", 3)
	var wolf := fauna.spawn("wolf", c.lutins[0].cell + Vector3i(9, 0, 0))
	combat.ring("mobilize")
	for l in c.lutins:
		assert_true(l.mobilized)
		assert_ne(l.weapon, "", "%s a pris une arme" % l.name)
	_run(20)
	assert_true(fauna.find(wolf["id"]).is_empty(), "loup abattu")
	var kills := 0
	var xp := 0.0
	for l in c.lutins:
		kills += int(l.kills.get("wolf", 0))
		xp += l.combat_xp
	assert_eq(kills, 1)
	assert_gt(xp, 0.0, "XP de combat")
	combat.ring("none")
	assert_eq(c.stock.count("flintlock"), 3 + 1, "les armes reviennent à la réserve (+ le fusil du chariot)")


func test_se_cacher() -> void:
	combat.ring("hide")
	_run(20)
	for l in c.lutins:
		assert_true(Colony._near(l.cell, c.stock.pos, 1), "%s est à l'abri" % l.name)


func test_potion_de_soin() -> void:
	var l := c.lutins[0]
	l.hp = 10.0
	l.place_at(c.stock.pos)
	c.stock.add("healing_potion", 1)
	combat.tick()
	assert_gt(l.hp, 30.0, "la potion soigne")


func test_mort_d_un_lutin() -> void:
	var l := c.lutins[1]
	l.hp = 0.0
	watch_signals(combat)
	combat.tick()
	assert_eq(c.lutins.size(), 3)
	assert_signal_emitted(combat, "lutin_died")
