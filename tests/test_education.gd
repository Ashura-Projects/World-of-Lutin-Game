extends GutTest

var sim: GameSim


func before_each() -> void:
	GameClock.configure()
	GameClock.reset(true)
	Rng.set_seed(21)
	var w := VoxelWorld.new(Vector3i(40, 32, 40))
	for x in 40:
		for z in 40:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	sim = GameSim.new(w)
	sim.colony.spawn_start(Vector3i(20, 2, 20), 2)  # une femme et un homme
	# maison fermée 5×5 avec 3 lits
	var plank := w.types.num("plank_block")
	for x in range(5, 10):
		for z in range(5, 10):
			for y in range(2, 5):
				if x in [5, 9] or z in [5, 9]:
					w.set_raw(Vector3i(x, y, z), plank)
			w.set_raw(Vector3i(x, 5, z), plank)
	for i in 3:
		sim.structures.add("bed", Vector3i(6 + i, 2, 7), true)
	sim.structures.assign_homes(sim.colony)
	sim.colony.stock.add("bread", 200)


func _days(n: int) -> void:
	for i in n:
		GameClock.tick_index += GameClock.ticks_per_day()
		sim.daily()


func test_metier_forme_seulement_apres_formation() -> void:
	var l := sim.colony.lutins[0]
	assert_false(sim.colony.change_job(l, "researcher"), "pas de chercheur sans formation")


func test_bebe_ne_pas_de_travail() -> void:
	var babies := []
	for i in 120:
		_days(1)
		babies = sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.parents.size() == 2)
		if not babies.is_empty():
			break
	assert_gt(babies.size(), 0, "un bébé est né")
	var b: Lutin = babies[0]
	assert_false(b.can_work(), "un enfant ne travaille pas")
	assert_false(sim.colony.change_job(b, "woodcutter"))


## Critère J8 : un enfant né au village va à l'école, devient chercheur et débloque une technologie.
func test_enfant_ecole_chercheur_technologie() -> void:
	var lib := sim.structures.add("library", Vector3i(15, 2, 15), true)
	var school := sim.structures.add("school", Vector3i(15, 2, 25), true)
	# un adulte suit la formation courte de chercheur, puis devient maître d'école
	var mother: Lutin = sim.colony.lutins[0]
	assert_true(sim.education.enroll(mother, lib))
	assert_eq(sim.education.trainees[mother.id]["eff"], 0.5, "formation courte d'adulte")
	_days(10)
	assert_eq(mother.job, "researcher")
	assert_true(sim.production.assign_staff(school, mother), "le chercheur devient maître d'école")
	assert_eq(mother.job, "teacher")
	sim.education.focus = "letters"
	# naissance
	var child: Lutin = null
	for i in 120:
		_days(1)
		var kids := sim.colony.lutins.filter(func(l: Lutin) -> bool: return l.parents.size() == 2)
		if not kids.is_empty():
			child = kids[0]
			break
	assert_not_null(child, "un enfant est né")
	# il grandit et va à l'école
	while child.age_stage() != "adult":
		_days(1)
	assert_gte(int(child.aptitudes["knowledge"]), 50, "l'école lui a donné du savoir")
	assert_true(sim.education.enroll(child, lib))
	assert_eq(sim.education.trainees[child.id]["eff"], 1.0, "enfant bien éduqué : formation complète")
	_days(10)
	assert_eq(child.job, "researcher")
	assert_true(sim.production.assign_staff(lib, child))
	var before := sim.research.unlocked.size()
	sim.research.choose("writing")
	_days(4)
	assert_gt(sim.research.unlocked.size(), before, "une technologie est découverte")
	assert_true(sim.research.unlocked.has("writing"))


func test_bonus_de_technologie() -> void:
	sim.research.unlocked["plough"] = true
	assert_almost_eq(Research.get_bonus("crop_yield"), 0.3, 0.001)
	assert_false(Research.is_locked("loom") and sim.research.unlocked.has("weaving"))
	assert_true(Research.is_locked("kiln"))


func test_mort_de_vieillesse() -> void:
	var old := sim.colony.lutins[1]
	old.age_days = 2000
	_days(400)
	assert_false(sim.colony.lutins.has(old), "l'ancien finit par mourir de vieillesse")


func test_education_aller_retour() -> void:
	sim.research.unlocked["writing"] = true
	sim.education.focus = "crafts"
	var e2 := Education.new(sim.colony, sim.structures, sim.production, Research.new())
	e2.from_dict(JSON.parse_string(JSON.stringify(sim.education.to_dict())))
	assert_eq(e2.focus, "crafts")
	assert_true(e2.research.unlocked.has("writing"))
