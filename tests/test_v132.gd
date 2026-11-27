extends GutTest
## 1.3.2 : enlever la végétation, gros objets touchables partout, clôtures, tentes et familles, élevage,
## file d'attente des ateliers, formations sans chevauchement, eau qui coule, terraformation.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(32)
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


func test_enlever_buisson_et_debug_instantane() -> void:
	sim.flora.bushes[Vector3i(25, 2, 25)] = 0
	sim.flora.trees[Vector3i(27, 2, 25)] = "pin"
	var id := Clearing.uproot(sim.board, Vector3i(25, 2, 25))
	assert_gt(id, 0, "un cueilleur va déraciner le buisson")
	assert_eq(sim.board.tasks[id]["kind"], "uproot")
	Clearing.complete(sim.board, sim.colony.lutins[0], sim.board.tasks[id])
	assert_false(sim.flora.bushes.has(Vector3i(25, 2, 25)), "buisson enlevé")
	sim.rules.free_clear = true
	assert_eq(Clearing.order_circle(sim.board, Vector3i(27, 2, 25), 3), 1)
	assert_false(sim.flora.trees.has(Vector3i(27, 2, 25)), "débug : arbre enlevé tout de suite")


func test_gros_atelier_touchable_partout() -> void:
	var sid := sim.structures.add("glassworks", Vector3i(30, 2, 30), true)
	assert_eq(int(sim.structures.at(Vector3i(31, 3, 31)).get("id", -1)), sid, "toute la case 2×2×2 compte")
	assert_true(sim.structures.at(Vector3i(32, 2, 30)).is_empty())
	assert_false(sim.structures.footprint_free("anvil", Vector3i(31, 2, 30), 0), "pas d'objet par-dessus")
	var hit := sim.structures.pick_ray(Vector3(31, 10, 31), Vector3(0, -1, 0))
	assert_eq(int(hit.get("id", -1)), sid, "un toucher au-dessus de n'importe quelle case le sélectionne")
	assert_true(TaskCancel.remove_structure_at(sim.board, Vector3i(31, 2, 31)), "gomme sur une autre case")
	assert_false(sim.structures.items.has(sid))


func test_cloture_bloque_et_se_demonte() -> void:
	sim.structures.add("fence", Vector3i(10, 2, 10), true)
	var gs := w.types.num("gate_solid")
	assert_eq(w.get_block(Vector3i(10, 2, 10)), gs)
	assert_eq(w.get_block(Vector3i(10, 3, 10)), gs, "2 de haut : on ne saute pas par-dessus")
	TaskCancel.remove_structure_at(sim.board, Vector3i(10, 2, 10))
	assert_eq(w.get_block(Vector3i(10, 2, 10)), 0)
	assert_eq(w.get_block(Vector3i(10, 3, 10)), 0)


func test_portillon_ferme_garde_les_betes() -> void:
	sim.structures.add("fence_gate", Vector3i(12, 2, 10), true, {"rot": 0})
	var g: Dictionary = sim.gates.gates.values()[0]
	assert_eq(w.get_block(Vector3i(12, 2, 10)), 0, "ouvert : on passe")
	sim.gates.toggle(g["id"])
	assert_eq(w.get_block(Vector3i(12, 2, 10)), w.types.num("gate_solid"), "fermé : personne ne passe")


func test_tente_couple_plus_un_enfant() -> void:
	var col := sim.colony
	var a := col.lutins[0]
	var b := col.lutins[1]
	a.spouse = b.id
	b.spouse = a.id
	var kid := col.lutins[2]
	kid.age_days = 0
	kid.parents = [a.id, b.id]
	var other := col.lutins[3]
	other.age_days = 200
	sim.structures.add("tent_double", Vector3i(40, 2, 40), true)
	sim.structures.assign_homes(col)
	var tent := Vector3i(40, 2, 40)
	var inside := col.lutins.filter(func(l: Lutin) -> bool: return l.home == tent)
	assert_eq(inside.size(), 3, "2 adultes + 1 enfant dans la tente de couple")
	assert_ne(other.home, tent, "pas de 3e adulte")
	assert_eq(kid.home, tent, "l'enfant dort près de ses parents")


func test_tente_simple_un_seul_adulte() -> void:
	sim.structures.add("tent", Vector3i(40, 2, 40), true)
	sim.structures.assign_homes(sim.colony)
	var n := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.home == Vector3i(40, 2, 40)).size()
	assert_eq(n, 1)


func test_elevage_achat_lait_abattage_vente() -> void:
	sim.colony.stock.add("gold", 500)
	assert_eq(Livestock.buy(sim, "cow"), "Le marchand n'est pas là.")
	sim.trade._arrive(1)
	sim.trade.animal_offers["cow"] = 2
	Livestock.buy(sim, "cow")
	Livestock.buy(sim, "cow")
	assert_eq(Livestock.owned(sim, "cow").size(), 2)
	sim.colony.stock.add("straw", 10)
	var milk := sim.colony.stock.count("milk")
	Livestock.daily(sim)
	assert_eq(sim.colony.stock.count("milk"), milk + 4, "2 vaches nourries = 4 laits")
	var cow: Dictionary = Livestock.owned(sim, "cow")[0]
	var cell: Vector3i = cow["cell"]
	Livestock.slaughter(sim, cow)
	assert_eq(Livestock.owned(sim, "cow").size(), 1 + int(GameClock.day() % 12 == 0), "abattue")
	assert_gt(sim.ground.piles.size(), 0, "viande et peaux au sol près de %s" % cell)
	var gold := sim.colony.stock.count("gold")
	Livestock.sell(sim, Livestock.owned(sim, "cow")[0])
	assert_gt(sim.colony.stock.count("gold"), gold, "vendue au marchand")


func test_file_atelier_monter_retirer_finir() -> void:
	var sid := sim.structures.add("dairy", Vector3i(30, 2, 30), true)
	var p := sim.production
	p.add_order(sid, "make_cheese_plain", "make", 2)
	p.add_order(sid, "churn_butter", "forever", 1)
	p.move_order(sid, 1, -1)
	assert_eq(p.orders[sid][0]["recipe"], "churn_butter", "monté en tête de file")
	p.orders[sid][1]["done"] = 2
	p._plan_station(sim.structures.items[sid])
	assert_eq(p.orders[sid].size(), 1, "commande « faire 2 » finie : retirée de la file")
	p.remove_order(sid, 0)
	assert_true(p.orders[sid].is_empty())


func test_formations_sans_chevauchement() -> void:
	for i in 8:
		sim.colony.spawn_start(Vector3i(22 + i % 4, 2, 22 + i / 4), 1)
	var ids := []
	for l: Lutin in sim.colony.lutins:
		ids.append(l.id)
	var uid := sim.units.create("Test", ids[0], ids.slice(1, 12))
	var u: Dictionary = sim.units.units[uid]
	for f: Dictionary in sim.units.formations():
		u["formation"] = f["id"]
		for dir: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0.7, 0.7)]:
			u["dir"] = dir
			u["cell"] = Vector3i(32, 2, 32)
			var seen := {}
			for c: Vector3i in sim.units.slots(u):
				assert_false(seen.has(c), "%s : deux soldats sur %s" % [f["id"], c])
				seen[c] = true


func test_eau_remplit_le_trou() -> void:
	var water := w.types.num("water")
	w.set_block(Vector3i(50, 1, 50), water)
	w.set_block(Vector3i(51, 1, 50), 0)  # on creuse juste à côté
	w.set_block(Vector3i(52, 1, 50), 0)
	_run(2.0)
	assert_eq(w.get_block(Vector3i(51, 1, 50)), water, "l'eau a coulé dans le trou")
	assert_eq(w.get_block(Vector3i(52, 1, 50)), water, "puis plus loin")


func test_terraformation_cout_annulation_debug() -> void:
	var st := sim.colony.stock
	st.add("dirt", 5)
	var before := st.count("dirt")
	var res: Array = Terraform.order(sim, "dirt", [Vector3i(45, 2, 45), Vector3i(46, 2, 45)])
	assert_eq(int(res[0]), 2)
	assert_eq(st.count("dirt"), before - 2, "coût pris à la réserve")
	var tid: int = sim.board._by_cell[Vector3i(45, 2, 45)]
	sim.board.cancel(tid)
	assert_eq(st.count("dirt"), before - 1, "annulé : remboursé")
	sim.rules.free_terra = true
	Terraform.order(sim, "tree", [Vector3i(47, 2, 45)])
	assert_true(sim.flora.trees.has(Vector3i(47, 2, 45)), "débug : arbre planté tout de suite")
	st.add("water_bucket", 1)
	Terraform.order(sim, "water", [Vector3i(48, 2, 45)])
	assert_eq(w.get_block(Vector3i(48, 2, 45)), w.types.num("water"))


func test_sauvegarde_aller_retour_v132() -> void:
	sim.rules.free_clear = true
	sim.rules.free_terra = true
	sim.trade.animal_offers = {"cow": 2, "pig": 1}
	var r2 := GameRules.new(sim.rules.to_dict())
	assert_true(r2.free_clear and r2.free_terra)
	var t2 := Trade.new(sim.colony)
	t2.from_dict(sim.trade.to_dict())
	assert_eq(int(t2.animal_offers["cow"]), 2)
	sim.rules = r2
	GameRules.active = r2


func test_ratelier_armes_filtre() -> void:
	var guns := Vector3i(10, 2, 30)
	var spears := Vector3i(30, 2, 30)
	sim.structures.add("weapon_rack", guns, true, {"rack": "flintlock"})
	sim.structures.add("weapon_rack", spears, true, {"rack": "spear"})
	var from := Vector3i(20, 2, 30)
	assert_eq(sim.colony.store_near(from, "flintlock"), guns, "les fusils vont au râtelier à fusils")
	assert_eq(sim.colony.store_near(from, "spear"), spears, "les lances au râtelier à lances")
	assert_ne(sim.colony.store_near(from, "log"), guns, "pas de bûches au râtelier")
	var d := sim.structures.to_dict()
	var s2 := Structures.new()
	s2.from_dict(d)
	assert_eq(str(s2.at(guns)["rack"]), "flintlock", "filtre sauvegardé")


func test_tas_dans_les_zones() -> void:
	var cells := []
	for x in 2:
		for z in 2:
			cells.append(Vector3i(40 + x, 2, 40 + z))
	sim.colony.add_store_cells(cells)
	var items := {"straw": 200, "log": 30}
	var z: Dictionary = sim.colony.stores.zones[0]
	sim.colony.stores.set_filter(z["id"], false, [], ["straw"])
	var lay := sim.colony.stores.layout(items, 50)
	assert_eq(lay.size(), 4, "zone 2×2 de paille : 4 tas")
	for c: Vector3i in lay:
		assert_eq(lay[c][0], "straw")
		assert_eq(int(lay[c][1]), 50, "50 par tas")
