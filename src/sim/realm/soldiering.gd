class_name Soldiering
extends RefCounted
## Soldats (1.4) : entraînement en trois qualités — force (dégâts), agilité (vitesse de marche et d'attaque),
## robustesse (PV) —, compétences Commandement et Diplomatie (niveau + XP), bonus du commandant (+20 % PV, chapeau)
## et boost des soldats sous ses ordres selon son Commandement. Valeurs : data/military.json › soldiers.

const STATS := ["force", "agility", "robust"]
const STAT_NAMES := {"force": "Force", "agility": "Agilité", "robust": "Robustesse"}
const SKILL_NAMES := {"command": "Commandement", "diplomacy": "Diplomatie"}


static func cfg() -> Dictionary:
	return DataRegistry.get_table("military").get("soldiers", {})


## Niveau d'entraînement d'une qualité (0 à max_level).
static func drill_level(l: Lutin, stat: String) -> int:
	var per := float(cfg().get("drill_points_per_level", 100))
	return mini(int(cfg().get("max_level", 10)), int(float(l.drill.get(stat, 0.0)) / per))


static func add_drill(l: Lutin, stat: String, points: float) -> void:
	var cap := float(cfg().get("drill_points_per_level", 100)) * float(cfg().get("max_level", 10))
	l.drill[stat] = minf(cap, float(l.drill.get(stat, 0.0)) + points)


static func skill_level(l: Lutin, skill: String) -> int:
	return int(l.skills.get(skill, {}).get("level", 0))


## XP de compétence (Commandement, Diplomatie) : niveau suivant tous les xp_per_level × (niveau + 1).
static func add_skill_xp(l: Lutin, skill: String, xp: float) -> void:
	var k: Dictionary = l.skills.get_or_add(skill, {"level": 0, "xp": 0.0})
	k["xp"] = float(k["xp"]) + xp
	var per := float(cfg().get("skill_xp_per_level", 60))
	while float(k["xp"]) >= per * (int(k["level"]) + 1) and int(k["level"]) < int(cfg().get("skill_max_level", 20)):
		k["xp"] = float(k["xp"]) - per * (int(k["level"]) + 1)
		k["level"] = int(k["level"]) + 1


## Chef de ce lutin dans son unité (le lieutenant pour sa sous-unité, sinon le commandant). null s'il n'en a pas.
static func leader_of(l: Lutin) -> Lutin:
	if Units.active == null or l.unit_id < 0:
		return null
	var u: Dictionary = Units.active.units.get(l.unit_id, {})
	if u.is_empty():
		return null
	var col := Units.active.colony
	var sq := int(u.get("squads", {}).get(l.id, 0))
	var lt := int(u.get("lieutenants", {}).get(sq, -1)) if sq > 0 else -1
	if lt >= 0 and lt != l.id:
		return col.find_lutin(lt)
	return col.find_lutin(int(u["captain"])) if int(u["captain"]) != l.id else null


static func is_commander(l: Lutin) -> bool:
	if Units.active == null or l.unit_id < 0:
		return false
	return int(Units.active.units.get(l.unit_id, {}).get("captain", -1)) == l.id


## Bonus des soldats sous les ordres d'un bon chef (multiplicateur, ex. 1,1 = +10 %).
static func command_boost(l: Lutin) -> float:
	var chief := leader_of(l)
	if chief == null:
		return 1.0
	return 1.0 + float(cfg().get("command_boost_per_level", 0.02)) * skill_level(chief, "command")


static func max_hp(l: Lutin) -> float:
	var base := float(DataRegistry.get_table("population").get("combat", {}).get("hp", 50))
	var m := 1.0 + float(cfg().get("robust_hp_per_level", 0.08)) * drill_level(l, "robust")
	if is_commander(l):
		m *= 1.0 + float(cfg().get("commander_hp_bonus", 0.2))
	return base * m * command_boost(l)


static func damage_mult(l: Lutin) -> float:
	return (1.0 + float(cfg().get("force_damage_per_level", 0.06)) * drill_level(l, "force")) * command_boost(l)


static func move_mult(l: Lutin) -> float:
	return 1.0 + float(cfg().get("agility_move_per_level", 0.04)) * drill_level(l, "agility")


## Délai entre deux coups (plus petit = plus rapide).
static func attack_delay_mult(l: Lutin) -> float:
	return (
		1.0
		/ ((1.0 + float(cfg().get("agility_attack_per_level", 0.05)) * drill_level(l, "agility")) * command_boost(l))
	)


## Un coup porté par un soldat : un peu d'XP de Commandement pour son chef (et plus s'il tue).
static func on_strike(l: Lutin, killed: bool) -> void:
	var chief := leader_of(l)
	var xp := (
		float(cfg().get("command_xp_per_strike", 1.0))
		+ (float(cfg().get("command_xp_per_kill", 8.0)) if killed else 0.0)
	)
	if chief != null:
		add_skill_xp(chief, "command", xp)
	if is_commander(l) or (chief == null and l.unit_id >= 0):
		add_skill_xp(l, "command", xp * 0.5)  # le chef qui se bat apprend aussi
