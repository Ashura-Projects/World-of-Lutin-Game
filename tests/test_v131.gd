extends GutTest
## 1.3.1 : portes, cimetière, caserne en deux pièces, créneaux en demi-bloc, fenêtres, catapulte, charrette orientée,
## lanciers à cheval.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(31)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 4)


func _run(seconds: float) -> void:
	for i in int(seconds * GameClock.ticks_per_second()):
		GameClock.step()
		sim.tick()


func _room(x0: int, z0: int, n: int = 6) -> void:
	var st := w.types.num("stone")
	for x in range(x0, x0 + n):
		for z in range(z0, z0 + n):
			w.set_block(Vector3i(x, 5, z), st)
			if x in [x0, x0 + n - 1] or z in [z0, z0 + n - 1]:
				for y in range(2, 5):
					w.set_block(Vector3i(x, y, z), st)


func test_porte_verrouillee_et_demontee() -> void:
	sim.structures.add("door", Vector3i(30, 2, 30), true, {"rot": 0})
	var g: Dictionary = sim.gates.gates.values()[0]
	assert_eq(g["kind"], "door")
	assert_eq(w.get_block(Vector3i(30, 2, 30)), 0, "non verrouillée : les lutins passent")
	sim.gates.set_locked(g["id"], true)
	assert_eq(w.get_block(Vector3i(30, 3, 30)), w.types.num("gate_solid"), "verrouillée : bloquée")
	assert_true(TaskCancel.remove_structure_at(sim.board, Vector3i(30, 2, 30)))
	sim.gates.sync_with_structures()
	assert_eq(sim.gates.gates.size(), 0)
	assert_eq(w.get_block(Vector3i(30, 3, 30)), 0, "porte démontée : passage libre")


func test_cimetiere_et_pierre_tombale() -> void:
	sim.colony.cemetery.append(Vector3i(40, 2, 40))
	var l := sim.colony.lutins[0]
	var name := l.name
	sim.colony.remove_lutin(l)
	var s := sim.structures.at(Vector3i(40, 2, 40))
	assert_eq(s["kind"], "tombstone")
	assert_eq(s["epitaph"], name)


func test_caserne_en_deux_pieces() -> void:
	var r := sim.realm
	var cap := r.garrison_capacity()
	_room(2, 2)
	for i in 3:
		sim.structures.add("wood_bed", Vector3i(3 + i, 2, 3), true)
	sim.structures.add("chest", Vector3i(3, 2, 5), true)
	sim.structures.add("weapon_rack", Vector3i(5, 2, 5), true)
	_room(12, 2)
	sim.structures.add("cooking_hearth", Vector3i(13, 2, 3), true)
	sim.structures.add("table", Vector3i(14, 2, 4), true)
	sim.structures.add("bench", Vector3i(13, 2, 5), true)
	sim.structures.add("bench", Vector3i(15, 2, 5), true)
	assert_true(r.barracks_ok(), "garnison + réfectoire")
	assert_gt(r.garrison_capacity(), cap + 3)


func test_creneau_demi_bloc() -> void:
	var p := Vector3i(10, 2, 10)
	w.set_block(p, w.types.num("crenel"))
	assert_eq(w.types.default_shape[w.types.num("crenel")], 1)
	var res := ChunkMesher.build(w, VoxelWorld.chunk_key(p), 9999, {})
	var top := -1.0
	for v: Vector3 in res["opaque"][Mesh.ARRAY_VERTEX]:
		if absf(v.x - 10.5) < 0.6 and absf(v.z - 10.5) < 0.6:
			top = maxf(top, v.y)
	assert_almost_eq(top, 2.5, 0.01, "le créneau ne monte qu'à mi-hauteur")


func test_fenetre_percee_dans_un_mur() -> void:
	var p := Vector3i(12, 2, 12)
	w.set_block(p, w.types.num("plank_block"))
	sim.colony.stock.add("glass", 1)
	sim.colony.stock.add("plank", 1)
	var code := ShapeMesh.Shape.WINDOW_GLASS * 4
	assert_eq(sim.board.place_blueprints([p], w.types.num("plank_block"), false, code), 1)
	assert_eq(w.get_shape(p), code)
	assert_eq(sim.colony.stock.count("glass"), 0, "une vitre coûte un verre")


func test_catapulte_charger_tirer_casser() -> void:
	sim.structures.add("catapult", Vector3i(20, 2, 40), true, {"yaw": 0.0})
	var s := sim.structures.at(Vector3i(20, 2, 40))
	var cat := sim.catapults
	assert_string_contains(cat.fire(s, Vector3i(20, 2, 20)), "Chargez")
	sim.colony.stock.add("stone", 2)
	cat.load(s)
	assert_true(s["loaded"])
	assert_string_contains(cat.fire(s, Vector3i(40, 2, 40)), "Tournez", "cible sur le côté")
	w.set_block(Vector3i(20, 2, 20), w.types.num("plank_block"))
	assert_eq(cat.fire(s, Vector3i(20, 2, 20)), "Tir !")
	_run(3)
	assert_eq(w.get_block(Vector3i(20, 2, 20)), 0, "le rocher casse le bloc construit")
	assert_eq(w.get_block(Vector3i(20, 1, 20)), w.types.num("grass"), "pas le terrain naturel")
	cat.rotate(s, 2)
	assert_almost_eq(float(s["yaw"]), deg_to_rad(30.0), 0.001)


func test_charrette_et_catapulte_orientees() -> void:
	var l := sim.colony.lutins[0]
	LutinOrders.give(sim.colony, sim.board, l, "cart", Vector3i(20, 2, 8))
	_run(25)
	assert_almost_eq(absf(wrapf(sim.colony.cart_yaw, -PI, PI)), 0.0, 0.5, "tirée vers le nord : orientée nord")
	sim.structures.add("catapult", Vector3i(30, 2, 20), true)
	var s := sim.structures.at(Vector3i(30, 2, 20))
	assert_string_contains(sim.catapults.move(s, Vector3i(44, 2, 20)), "poussent")
	_run(40)
	assert_eq(s["cell"].x, 44, "poussée jusqu'à l'endroit choisi")
	assert_almost_eq(float(s["yaw"]), -PI / 2.0, 0.6, "orientée vers l'est")


func test_lancier_a_cheval() -> void:
	var l := sim.colony.lutins[0]
	l.weapon = "spear"
	var base: float = sim.combat._weapon_stats(l)["attack"]
	l.horse = 99
	assert_gt(float(sim.combat._weapon_stats(l)["attack"]), base * 1.5, "charge à cheval")
