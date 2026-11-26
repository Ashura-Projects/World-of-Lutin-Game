extends GutTest

var c: Colony
var tr: Trade


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(6)
	var w := VoxelWorld.new(Vector3i(16, 16, 16))
	for x in 16:
		for z in 16:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
	c = Colony.new(w)
	c.spawn_start(Vector3i(8, 1, 8), 2)
	tr = Trade.new(c)


func test_le_marchand_passe_et_repart() -> void:
	tr.daily(1)
	assert_false(tr.present)
	tr.daily(4)
	assert_true(tr.present, "arrive au jour 4")
	assert_true(tr.offers.has("salt"))
	tr.daily(5)
	assert_false(tr.present, "repart le lendemain")


func test_vendre_puis_acheter() -> void:
	tr.daily(4)
	c.stock.add("log", 20)
	var sold := tr.sell("log", 10)
	assert_eq(sold, 10)
	assert_eq(c.stock.count("gold"), 10 * tr.sell_price("log"))
	var gold := c.stock.count("gold")
	var bought := tr.buy("salt", 2)
	assert_gt(bought, 0)
	assert_eq(c.stock.count("gold"), gold - bought * tr.buy_price("salt"))
	assert_gt(tr.buy_price("salt"), tr.sell_price("salt"), "le marchand gagne sa vie")


func test_pas_d_or_pas_d_achat() -> void:
	tr.daily(4)
	c.stock.items.erase("gold")
	assert_eq(tr.buy("iron_ingot", 5), 0)
