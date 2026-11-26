extends GutTest


func test_meme_graine_meme_suite() -> void:
	Rng.set_seed(42)
	var a := [Rng.randf(), Rng.randf(), Rng.randi_range(0, 1000)]
	Rng.set_seed(42)
	var b := [Rng.randf(), Rng.randf(), Rng.randi_range(0, 1000)]
	assert_eq(a, b)


func test_aller_retour_sauvegarde() -> void:
	Rng.set_seed(7)
	Rng.randf()
	var d := Rng.to_dict()
	var expected := Rng.randf()
	Rng.from_dict(d)
	assert_almost_eq(Rng.randf(), expected, 0.0000001)
