extends GutTest


func before_each() -> void:
	GameClock.configure()
	GameClock.reset()


func test_jour_et_saison() -> void:
	var t := DataRegistry.get_table("time")
	var per_day := GameClock.ticks_per_day()
	assert_eq(per_day, int(t["day_seconds"]) * int(t["ticks_per_second"]))
	for i in per_day * int(t["days_per_season"]):
		GameClock.step()
	assert_eq(GameClock.day(), int(t["days_per_season"]))
	assert_eq(GameClock.season_index(), 1)


func test_signal_jour() -> void:
	watch_signals(EventBus)
	for i in GameClock.ticks_per_day():
		GameClock.step()
	assert_signal_emit_count(EventBus, "day_changed", 1)


func test_aller_retour() -> void:
	for i in 123:
		GameClock.step()
	var d := GameClock.to_dict()
	GameClock.reset()
	GameClock.from_dict(d)
	assert_eq(GameClock.tick_index, 123)
