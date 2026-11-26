extends Node
## Réglages de la nouvelle partie, choisis sur l'écran de configuration avant le lancement.

var mode: String = "sandbox"
var lutin_count: int = 6
var map_size: String = "large"
var seed_value: int = 0
var load_slot: String = ""


func reset_defaults() -> void:
	var start := DataRegistry.get_table("start")
	lutin_count = int(start.get("lutins", {}).get("default", 6))
	map_size = str(start.get("map_size", "large"))
	seed_value = randi() % 100000
	mode = "sandbox"
	load_slot = ""


func clamp_lutins(n: int) -> int:
	var l: Dictionary = DataRegistry.get_table("start").get("lutins", {})
	return clampi(n, int(l.get("min", 2)), int(l.get("max", 10)))


func map_dims() -> Vector3i:
	for s: Dictionary in DataRegistry.get_table("world").get("sizes", []):
		if s["id"] == map_size:
			return Vector3i(int(s["x"]), int(s["height"]), int(s["z"]))
	return Vector3i(128, 64, 128)
