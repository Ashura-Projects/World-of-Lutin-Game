extends GutTest
## 1.0.1 : annuler des plans et des ordres, démonter un objet, zones de réserve.

var w: VoxelWorld
var c: Colony
var flora: Flora
var board: TaskBoard
var st: Structures


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(3)
	w = VoxelWorld.new(Vector3i(40, 32, 40))
	for x in 40:
		for z in 40:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	c = Colony.new(w)
	flora = Flora.new()
	board = TaskBoard.new(w, c, flora, Fauna.new(w), GroundItems.new())
	st = Structures.new()
	board.structures = st
	c.spawn_start(Vector3i(20, 2, 20), 2)


func test_annuler_le_dernier_groupe_de_plans() -> void:
	var plank := w.types.num("plank_block")
	assert_eq(board.place_blueprints([Vector3i(5, 2, 5), Vector3i(6, 2, 5)], plank, false), 2)
	assert_eq(board.place_blueprints([Vector3i(9, 2, 9)], plank, false), 1)
	assert_eq(TaskCancel.undo_last_plans(board), 1, "seul le dernier groupe est annulé")
	assert_eq(board.tasks.size(), 2)
	assert_eq(TaskCancel.undo_last_plans(board), 2)
	assert_eq(board.tasks.size(), 0)


func test_gomme_annule_un_plan_d_objet() -> void:
	var id := board.add_structure("tent", Vector3i(8, 2, 8))
	assert_gt(id, 0)
	assert_eq(board.place_blueprints([Vector3i(8, 1, 8)], 0, true), 1, "toucher le sol sous l'objet suffit")
	assert_false(board.tasks.has(id))
	assert_true(st.at(Vector3i(8, 2, 8)).is_empty(), "le plan a disparu")
	assert_eq(w.get_block(Vector3i(8, 1, 8)), w.types.num("grass"), "le sol n'est pas creusé")


func test_demonter_un_objet_rend_les_materiaux() -> void:
	var sid := st.add("tent", Vector3i(8, 2, 8), true)
	var cost: Dictionary = Structures.def("tent").get("cost", {})
	var k: String = cost.keys()[0]
	var before := c.stock.count(k)
	c.lutins[0].home = Vector3i(8, 2, 8)
	assert_true(TaskCancel.remove_structure_at(board, Vector3i(8, 2, 8)))
	assert_false(st.items.has(sid))
	assert_eq(c.stock.count(k), before + int(cost[k]))
	assert_eq(c.lutins[0].home.y, -1, "le lutin n'a plus de foyer")


func test_annuler_les_ordres_dans_un_cercle() -> void:
	for x in [4, 6, 30]:
		flora.trees[Vector3i(x, 2, 4)] = "pin"
		board.add_cut(Vector3i(x, 2, 4))
	assert_eq(TaskCancel.cancel_in_circle(board, Vector3i(5, 2, 4), 2), 2)
	assert_eq(board.tasks.size(), 1, "l'arbre hors du cercle reste ciblé")


func test_zone_de_reserve_la_plus_proche_et_sauvegarde() -> void:
	var far := Vector3i(35, 2, 35)
	assert_eq(c.store_near(Vector3i(36, 2, 36)), c.stock.pos, "sans zone : le chariot")
	assert_eq(c.add_store_cells([far, Vector3i(35, 5, 35)]), 1, "seules les cases praticables comptent")
	assert_eq(c.store_near(Vector3i(36, 2, 36)), far)
	assert_true(c.at_store(Vector3i(34, 2, 35)))
	var c2 := Colony.new(w)
	c2.from_dict(c.to_dict())
	assert_eq(c2.stores.cells(), c.stores.cells())
	c.remove_store_cells([far])
	assert_eq(c.store_near(Vector3i(36, 2, 36)), c.stock.pos)


func test_filtre_de_reserve_par_categorie_et_objet() -> void:
	var near := Vector3i(30, 2, 30)
	var id := c.stores.add_zone([near])
	c.stores.set_filter(id, false, ["food"], ["log"])
	var p := Vector3i(31, 2, 31)
	assert_eq(c.store_near(p, "log"), near, "les bûches sont acceptées")
	assert_eq(c.store_near(p, "bread"), near, "catégorie nourriture acceptée")
	assert_eq(c.store_near(p, "food"), near)
	assert_eq(c.store_near(p, "stone"), c.stock.pos, "la pierre va à la charrette")
