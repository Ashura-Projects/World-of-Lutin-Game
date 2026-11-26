extends GutTest


class FakeSystem:
	extends RefCounted
	var value := 0

	func to_dict() -> Dictionary:
		return {"value": value}

	func from_dict(d: Dictionary) -> void:
		value = int(d["value"])


func test_aller_retour_fichier() -> void:
	var sys := FakeSystem.new()
	sys.value = 99
	SaveManager.register("fake", sys)
	Rng.set_seed(5)
	GameClock.reset()
	for i in 10:
		GameClock.step()
	assert_true(SaveManager.save_game("test_gut"))
	sys.value = 0
	GameClock.reset()
	assert_true(SaveManager.load_game("test_gut"))
	assert_eq(sys.value, 99)
	assert_eq(GameClock.tick_index, 10)
	SaveManager.unregister("fake")
