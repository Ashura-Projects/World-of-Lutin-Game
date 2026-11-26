extends GutTest

var w: VoxelWorld
var c: Colony
var st: Structures
var v: Village


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(2)
	w = VoxelWorld.new(Vector3i(32, 32, 32))
	for x in 32:
		for z in 32:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
	c = Colony.new(w)
	st = Structures.new()
	v = Village.new(c, st, w)
	c.spawn_start(Vector3i(16, 1, 16), 6)


func test_rang_hameau() -> void:
	assert_eq(v.compute_rank(), "camp")
	for i in 4:
		st.add("tent", Vector3i(i * 2, 1, 2), true)
	assert_eq(v.compute_rank(), "hamlet")


func test_objectifs() -> void:
	c.stock.add("log", 60)
	c.stock.take("bread", 999)
	st.add("campfire", Vector3i(3, 1, 3), true)
	v.check()
	assert_true(v.done.has("logs50"))
	assert_true(v.done.has("fire"))
	assert_false(v.done.has("bread60"))


func test_tour_de_vingt_blocs() -> void:
	var plank := w.types.num("plank_block")
	for y in range(1, 21):
		w.set_raw(Vector3i(5, y, 5), plank)
		v.on_block(Vector3i(5, y, 5), 0, plank)
	v.check()
	assert_eq(v.tower_height, 20)
	assert_true(v.done.has("tower20"))


func test_bilan_quotidien_et_famine() -> void:
	v.daily()
	c.stock.take("bread", 999)
	c.stock.take("potato", 999)
	watch_signals(EventBus)
	v.daily()
	assert_lt(int(v.daily_delta.get("bread", 0)), 0, "le pain a diminué")
	assert_true(v.alerts.size() > 0 and v.alerts[0].begins_with("Famine"))


func test_aller_retour() -> void:
	v.done["fire"] = true
	v.rank_id = "hamlet"
	var v2 := Village.new(c, st, w)
	v2.from_dict(JSON.parse_string(JSON.stringify(v.to_dict())))
	assert_eq(v2.rank_id, "hamlet")
	assert_true(v2.done.has("fire"))


func test_deco_donne_du_moral() -> void:
	var plank := w.types.num("plank_block")
	for x in range(2, 7):
		for z in range(2, 7):
			for y in range(1, 4):
				if x in [2, 6] or z in [2, 6]:
					w.set_raw(Vector3i(x, y, z), plank)
			w.set_raw(Vector3i(x, 4, z), plank)
	var bed := st.add("bed", Vector3i(3, 1, 3), true)
	var l := c.lutins[0]
	l.home = Vector3i(3, 1, 3)
	v.update_mood()
	var plain := float(l.needs["mood"])
	st.add("carpet", Vector3i(4, 1, 4), true)
	st.add("banner_wall", Vector3i(5, 2, 3), true)
	v.update_mood()
	assert_gt(float(l.needs["mood"]), plain, "tapis et fanion : meilleur moral")
