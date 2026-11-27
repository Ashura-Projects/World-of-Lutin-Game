extends GutTest
## 1.4 : Campagne Impériale (carte générée par zones, déterministe, sauvegarde des seules zones modifiées),
## villages IA qui bâtissent selon leurs schémas.


func _world() -> VoxelWorld:
	return VoxelWorld.new(Vector3i(512, 64, 512))


func test_zone_deterministe_quel_que_soit_l_ordre() -> void:
	var w1 := _world()
	var g1 := WorldGenerator.new(w1, 99)
	g1.generate_region(128, 128, 192, 192)
	var w2 := _world()
	var g2 := WorldGenerator.new(w2, 99)
	g2.generate_region(0, 0, 64, 64)  # une autre zone d'abord
	g2.generate_region(128, 128, 192, 192)
	for p: Vector3i in [Vector3i(130, 20, 140), Vector3i(150, 26, 170), Vector3i(191, 10, 128)]:
		assert_eq(w1.get_block(p), w2.get_block(p), "même terrain en %s" % p)
	assert_eq(g1.height_at(160, 160), w1.surface_y(160, 160), "hauteur calculée sans générer = vraie hauteur")


func test_streamer_genere_et_sauvegarde_les_zones_modifiees() -> void:
	var w := _world()
	var f := Flora.new()
	var g := WorldGenerator.new(w, 7)
	var st := WorldStreamer.new(w, f)
	st.start(g)
	var t0 := Time.get_ticks_msec()
	st.generate_now(Vector2i(2, 2))
	var ms := Time.get_ticks_msec() - t0
	gut.p("Génération d'une zone 64 × 64 : %d ms" % ms)
	assert_true(st.is_loaded(Vector3i(150, 0, 150)))
	assert_gt(w.chunks.size(), 0)
	w.set_block(Vector3i(140, 40, 140), w.types.num("plank_block"))
	st.generate_now(Vector2i(5, 5))
	var d := w.to_dict()
	assert_gt(d["chunks"].size(), 0)
	for key: String in d["chunks"]:
		var parts := key.split(",")
		assert_eq(
			WorldStreamer.region_of(Vector3i(int(parts[0]) * 16, 0, int(parts[2]) * 16)),
			Vector2i(2, 2),
			"seule la zone modifiée"
		)
	assert_eq(st.unload_far([Vector3(150, 0, 150)], 100.0), 1, "la zone lointaine non modifiée est oubliée")
	var st2 := WorldStreamer.new(_world(), Flora.new())
	st2.from_dict(st.to_dict())
	assert_true(st2.enabled and st2.modified.has(Vector2i(2, 2)))
	WorldStreamer.active = null


func test_zone_sur_fil_de_travail() -> void:
	var w := _world()
	var st := WorldStreamer.new(w, Flora.new())
	st.start(WorldGenerator.new(w, 3))
	st.request(Vector3(100, 0, 100), 10.0)
	for i in 200:
		st.process()
		OS.delay_msec(10)
		if st.is_loaded(Vector3i(100, 0, 100)):
			break
	assert_true(st.is_loaded(Vector3i(100, 0, 100)), "zone fusionnée après génération en arrière-plan")
	WorldStreamer.active = null


func test_village_ia_batit_un_schema() -> void:
	GameSetup.reset_defaults()
	var w := VoxelWorld.new(Vector3i(96, 32, 96))
	for x in 96:
		for z in 96:
			w.set_raw(Vector3i(x, 0, z), w.types.num("stone"))
			w.set_raw(Vector3i(x, 1, z), w.types.num("grass"))
	var sim := GameSim.new(w)
	sim.colony.spawn_start(Vector3i(10, 2, 10), 2)
	var st := {
		"id": "jaune", "center": Vector3i(60, 2, 60), "houses": [], "population": 8, "soldiers": 0, "wealth": 200.0
	}
	sim.rivals.states["jaune"] = st
	RivalBuilder.daily(sim.rivals, st)
	assert_eq(st["buildings"].size(), 1, "premier bâtiment du plan")
	assert_eq(st["buildings"][0]["id"], "field")
	var fields := 0
	for x in range(35, 85):
		for z in range(35, 85):
			fields += int(w.get_block(Vector3i(x, 1, z)) == w.types.num("field_plot"))
	assert_gt(fields, 20, "le champ est posé dans le monde")
	assert_gt(RivalBuilder.growth_bonus(st), 0.0, "un champ fait grandir le village")
