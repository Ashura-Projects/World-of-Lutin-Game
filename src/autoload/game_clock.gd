extends Node
## Horloge de la simulation : tick fixe (10/s) × vitesse (pause, x1, x2, x4), indépendante des FPS.

var tick_index: int = 0
var speed: int = 1
var running: bool = false
var _accumulator: float = 0.0
var _tps: int = 10
var _ticks_per_day: int = 3600
var _days_per_season: int = 5
var _season_count: int = 4
var _max_ticks_per_frame: int = 8


func _ready() -> void:
	configure()


func configure() -> void:
	var t := DataRegistry.get_table("time")
	_tps = int(t.get("ticks_per_second", 10))
	_ticks_per_day = int(t.get("day_seconds", 360)) * _tps
	_days_per_season = int(t.get("days_per_season", 5))
	_season_count = t.get("seasons", [1, 2, 3, 4]).size()
	_max_ticks_per_frame = int(t.get("max_ticks_per_frame", 8))


## Nouvelle partie : l'horloge démarre au matin (data/time.json › start_time_of_day).
func reset(at_start_time: bool = false) -> void:
	tick_index = 0
	if at_start_time:
		tick_index = int(float(DataRegistry.get_table("time").get("start_time_of_day", 0.0)) * _ticks_per_day)
	_accumulator = 0.0


func set_speed(value: int) -> void:
	speed = value
	EventBus.speed_changed.emit(value)


func _process(delta: float) -> void:
	if not running or speed <= 0:
		return
	_accumulator += delta * speed * _tps
	var steps := 0
	while _accumulator >= 1.0 and steps < _max_ticks_per_frame:
		_accumulator -= 1.0
		step()
		steps += 1


## Avance la simulation d'un tick (appelé aussi par les tests).
func step() -> void:
	var old_day := day()
	var old_season := season_index()
	tick_index += 1
	EventBus.tick.emit(tick_index)
	if day() != old_day:
		EventBus.day_changed.emit(day())
	if season_index() != old_season:
		EventBus.season_changed.emit(season_index())


func ticks_per_day() -> int:
	return _ticks_per_day


func ticks_per_second() -> int:
	return _tps


func day() -> int:
	return tick_index / _ticks_per_day


func time_of_day() -> float:
	return float(tick_index % _ticks_per_day) / _ticks_per_day


func season_index() -> int:
	return (day() / _days_per_season) % _season_count


func year() -> int:
	return day() / (_days_per_season * _season_count)


func is_night() -> bool:
	var t := DataRegistry.get_table("time")
	var tod := time_of_day()
	return tod < float(t.get("dawn", 0.25)) or tod > float(t.get("dusk", 0.8))


func to_dict() -> Dictionary:
	return {"tick": tick_index, "speed": speed}


func from_dict(d: Dictionary) -> void:
	tick_index = int(d.get("tick", 0))
	speed = int(d.get("speed", 1))
	_accumulator = 0.0
