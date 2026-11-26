extends Node
## Générateur aléatoire unique et seedé de la partie (déterminisme).

var seed_value: int = 0
var _rng := RandomNumberGenerator.new()


func set_seed(value: int) -> void:
	seed_value = value
	_rng.seed = value
	_rng.state = 0


func randf() -> float:
	return _rng.randf()


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func chance(p: float) -> bool:
	return _rng.randf() < p


func to_dict() -> Dictionary:
	return {"seed": seed_value, "state": str(_rng.state)}


func from_dict(d: Dictionary) -> void:
	seed_value = int(d.get("seed", 0))
	_rng.seed = seed_value
	_rng.state = int(str(d.get("state", "0")))
