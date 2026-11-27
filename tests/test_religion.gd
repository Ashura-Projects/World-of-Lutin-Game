extends GutTest
## Religion et mariages : offices, clergé, religion personnalisée, dogmes, prédication, recrutement, naissances.

var sim: GameSim
var w: VoxelWorld


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(4)
	GameSetup.reset_defaults()
	w = VoxelWorld.new(Vector3i(64, 24, 64))
	for x in 64:
		for z in 64:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 6)


## Chapelle = pièce fermée avec 2 bancs d'église, un pupitre et un autel.
func _chapel() -> void:
	var st := w.types.num("stone")
	for x in range(28, 34):
		for z in range(28, 34):
			w.set_block(Vector3i(x, 5, z), st)
			if x in [28, 33] or z in [28, 33]:
				for y in range(2, 5):
					w.set_block(Vector3i(x, y, z), st)
	sim.structures.add("pew", Vector3i(29, 2, 29), true)
	sim.structures.add("pew", Vector3i(30, 2, 29), true)
	sim.structures.add("lectern", Vector3i(31, 2, 31), true)
	sim.structures.add("small_altar", Vector3i(30, 2, 32), true)


func test_pretre_et_offices() -> void:
	var rel := sim.religion
	var p := sim.colony.lutins[0]
	assert_false(rel.ordain(p), "il faut une chapelle")
	_chapel()
	assert_true(rel.ordain(p))
	assert_eq(p.job, "priest")
	var f0 := sim.colony.lutins[3].faith
	rel.daily()
	assert_gt(sim.colony.lutins[3].faith, f0, "la foi monte avec les offices")


func test_clerge_et_religion_personnalisee() -> void:
	var rel := sim.religion
	_chapel()
	var a := sim.colony.lutins[0]
	var b := sim.colony.lutins[1]
	rel.ordain(a)
	rel.ordain(b)
	assert_false(rel.can_customize())
	assert_true(rel.promote(a))
	assert_true(rel.promote(a), "cardinal puis chef de culte")
	assert_true(rel.promote(b))
	assert_false(rel.promote(b), "un seul chef de culte")
	assert_true(rel.can_customize())
	assert_true(rel.customize("Voie du Chêne", "arbre", ["sacred_work", "fertility", "charity"]))
	assert_eq(rel.dogmas.size(), 2, "2 dogmes au plus")
	assert_almost_eq(rel.work_mult(), 1.05, 0.001)
	assert_almost_eq(rel.birth_mult(), 1.5, 0.001)


func test_mariage_et_naissance() -> void:
	var rel := sim.religion
	for l in sim.colony.lutins:
		l.needs["mood"] = 80.0
	for _i in 200:
		rel._marriages()
	var wives := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.sex == "f" and l.spouse >= 0)
	assert_gt(wives.size(), 0, "des couples se marient")
	var wife: Lutin = wives[0]
	assert_eq(sim.colony.find_lutin(wife.spouse).spouse, wife.id)
	assert_eq(Kinship.partner_of(sim.colony, wife).id, wife.spouse)


func test_predication_conversion_et_recrutement() -> void:
	var rel := sim.religion
	_chapel()
	var p := sim.colony.lutins[0]
	rel.ordain(p)
	rel.preachers[p.id] = "jaune"
	p.place_at(Vector3i(50, 2, 50))
	var v := sim.fauna.spawn("villager_jaune", Vector3i(52, 2, 50))
	for _i in 2000:
		rel.tick_second()
	assert_eq(float(v["faith"]), 100.0)
	assert_eq(rel.converts().size(), 1)
	var n := sim.colony.lutins.size()
	var l := rel.recruit(v)
	assert_not_null(l)
	assert_eq(sim.colony.lutins.size(), n + 1, "le fidèle rejoint le village")
	assert_false(sim.fauna.animals.has(v))


func test_sauvegarde_religion() -> void:
	var rel := sim.religion
	_chapel()
	rel.ordain(sim.colony.lutins[0])
	rel.custom = true
	rel.name = "Voie du Chêne"
	sim.colony.lutins[1].spouse = sim.colony.lutins[2].id
	var r2 := Religion.new(sim.colony, sim.structures, sim.fauna)
	r2.from_dict(rel.to_dict())
	assert_eq(r2.name, "Voie du Chêne")
	assert_eq(r2.clergy, rel.clergy)
	var c2 := Colony.new(w)
	c2.from_dict(sim.colony.to_dict())
	assert_eq(c2.lutins[1].spouse, sim.colony.lutins[2].id)


func test_eglise_demande_un_vitrail() -> void:
	_chapel()
	assert_eq(sim.religion.temples(), ["chapel_room"])
	for i in 4:
		sim.structures.add("pew", Vector3i(29 + i, 2, 30), true)
	assert_eq(sim.religion.temples(), ["chapel_room"], "6 bancs mais pas de vitrail")
	w.set_block(Vector3i(28, 3, 30), w.types.num("plank_block"))
	w.set_shape(Vector3i(28, 3, 30), ShapeMesh.Shape.WINDOW_STAINED * 4 + 1)
	assert_eq(sim.religion.temples(), ["church_room"], "avec un vitrail : église")
	assert_gt(sim.religion.capacity(), 10)
