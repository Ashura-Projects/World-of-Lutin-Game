class_name GameRules
extends RefCounted
## Règles de la partie (configuration) : mode, difficulté, voisins, orcs, fréquence des raids.
## Sauvegardées avec la partie ; lues par les systèmes (orcs, IA, victoire).

static var active: GameRules = null

var mode: String = "sandbox"
var difficulty: String = "normal"
var ai_factions: int = 0
var orcs: bool = false
var raid_days: int = 100
var ai_start_lutins: int = 6
var god_mode: bool = false  # débug : lutins invincibles
var free_build: bool = false  # débug : construction instantanée et gratuite
var free_dig: bool = false  # débug : creuser (gomme, récolte « creuser ») instantané


func _init(d: Dictionary = {}) -> void:
	from_dict(d)
	active = self


## Multiplicateur de difficulté (raid_size, enemy_hp, enemy_damage, ai_aggression, start_mult, raid_interval).
func mult(key: String) -> float:
	for l: Dictionary in DataRegistry.get_table("difficulty").get("levels", []):
		if l["id"] == difficulty:
			return float(l.get(key, 1.0))
	return 1.0


static func get_mult(key: String) -> float:
	return active.mult(key) if active != null else 1.0


func victory_enabled() -> bool:
	return mode == "royal"


func to_dict() -> Dictionary:
	return {
		"mode": mode,
		"difficulty": difficulty,
		"ai_factions": ai_factions,
		"orcs": orcs,
		"raid_days": raid_days,
		"ai_start_lutins": ai_start_lutins,
		"god_mode": god_mode,
		"free_build": free_build,
		"free_dig": free_dig
	}


func from_dict(d: Dictionary) -> void:
	mode = str(d.get("mode", "sandbox"))
	difficulty = str(d.get("difficulty", "normal"))
	ai_factions = int(d.get("ai_factions", 0))
	orcs = bool(d.get("orcs", false))
	raid_days = int(d.get("raid_days", 100))
	ai_start_lutins = int(d.get("ai_start_lutins", 6))
	god_mode = bool(d.get("god_mode", false))
	free_build = bool(d.get("free_build", false))
	free_dig = bool(d.get("free_dig", false))
	active = self
