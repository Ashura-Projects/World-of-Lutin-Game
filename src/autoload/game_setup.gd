extends Node
## Réglages de la nouvelle partie, choisis sur l'écran de configuration avant le lancement.

var mode: String = "sandbox"
var lutin_count: int = 6
var map_size: String = "small"
var seed_value: int = 0
var load_slot: String = ""
var faction: Dictionary = {}  # faction choisie avant la partie (éditeur)
var difficulty: String = "normal"
var ai_factions: int = 0  # villages voisins (0 à 3)
var orcs: bool = false
var raid_days: int = 100  # un raid d'orcs tous les N jours


func reset_defaults() -> void:
	var start := DataRegistry.get_table("start")
	lutin_count = int(start.get("lutins", {}).get("default", 6))
	map_size = str(start.get("map_size", "small"))
	seed_value = randi() % 100000
	load_slot = ""
	set_mode("sandbox")
	var dcfg := DataRegistry.get_table("difficulty")
	difficulty = str(dcfg.get("default", "normal"))
	raid_days = int(dcfg.get("raid_days_default", 100))
	faction = DataRegistry.get_table("faction").get("default", {}).duplicate()


func clamp_lutins(n: int) -> int:
	var l: Dictionary = DataRegistry.get_table("start").get("lutins", {})
	return clampi(n, int(l.get("min", 2)), int(l.get("max", 10)))


func map_dims() -> Vector3i:
	for s: Dictionary in DataRegistry.get_table("world").get("sizes", []):
		if s["id"] == map_size:
			return Vector3i(int(s["x"]), int(s["height"]), int(s["z"]))
	return Vector3i(256, 64, 256)


func size_def() -> Dictionary:
	for s: Dictionary in DataRegistry.get_table("world").get("sizes", []):
		if s["id"] == map_size:
			return s
	return {}


## Change de mode et met les options par défaut de ce mode (data/difficulty.json › modes).
func set_mode(m: String) -> void:
	mode = m
	for e: Dictionary in DataRegistry.get_table("difficulty").get("modes", []):
		if e["id"] == m:
			ai_factions = int(e.get("ai_factions", 0))
			orcs = bool(e.get("orcs", false))


## Règles de la partie à créer (copiées dans la simulation et sauvegardées).
func rules() -> Dictionary:
	return {"mode": mode, "difficulty": difficulty, "ai_factions": ai_factions, "orcs": orcs, "raid_days": raid_days}
