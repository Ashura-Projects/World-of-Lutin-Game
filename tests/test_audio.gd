extends GutTest


func test_tous_les_sons_existent() -> void:
	var cfg := DataRegistry.get_table("audio")
	for t: String in cfg["music_day"] + cfg["music_night"]:
		assert_true(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % t), "musique " + t)
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
