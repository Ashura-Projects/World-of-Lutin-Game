extends GutTest


func test_tous_les_sons_existent() -> void:
	var cfg := DataRegistry.get_table("audio")
	assert_between(cfg["music"].size(), 6, 8, "playlist de 6-7 morceaux")
	for t: Dictionary in cfg["music"]:
		assert_true(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % t["id"]), "musique " + t["id"])
		assert_true(t.has("author") and t.has("license"), "crédit de " + t["id"])
	for a: String in Audio.AMBIENCES:
		assert_true(ResourceLoader.exists("res://assets/audio/ambience/%s.ogg" % a), "ambiance " + a)
	for s: String in cfg["work_sounds"].values() + ["fusil", "loup", "ours", "cloche", "clic", "fanfare", "naissance"]:
		assert_true(ResourceLoader.exists("res://assets/audio/sfx/%s.ogg" % s), "bruitage " + s)


func test_le_zoom_rapproche_monte_l_ambiance() -> void:
	Audio.zoom_distance = 10.0
	Audio.set_ambience({"eau": 1.0})
	var near: float = Audio._amb_target["eau"]
	Audio.zoom_distance = 80.0
	Audio.set_ambience({"eau": 1.0})
	assert_gt(near, Audio._amb_target["eau"])
	Audio.set_ambience({})


func test_playlist_respecte_les_morceaux_coches_et_le_mode() -> void:
	var saved: Dictionary = Settings.values.duplicate(true)
	Settings.values["playlist"] = ["conteur", "ronde"]
	assert_eq(Audio.playlist(), ["conteur", "ronde"])
	Settings.values["music_mode"] = "one"
	Settings.values["music_track"] = "ronde"
	Audio._next_track()
	assert_eq(Audio.current_track, "ronde")
	Settings.values["music_mode"] = "all"
	Audio._next_track()
	assert_eq(Audio.current_track, "conteur", "en boucle : morceau suivant de la liste")
	Settings.values["playlist"] = []
	assert_eq(Audio.playlist().size(), Audio.tracks().size(), "rien de coché = tous")
	Settings.values = saved
	Audio.stop_all()
