class_name CampaignGoals
extends RefCounted
## Objectifs propres à la Campagne (1.4.1), en plus de ceux du tutoriel : population, tentes, diplomate,
## relations et pactes, unités, ennemis abattus par sorte, camps vidés, caserne, soldats, clans unis,
## villages, seigneur, villes. Renvoie la valeur atteinte, ou -1 si la sorte d'objectif n'est pas d'ici.


static func value(sim: GameSim, m: Dictionary, base: Dictionary) -> int:
	match str(m["kind"]):
		"population":
			return sim.colony.lutins.size()
		"built_tag":
			return sim.structures.built_with_tag(str(m["what"])).size()
		"diplomat":
			return int(sim.realm.diplomat_id >= 0)
		"relation_any":
			var best := -100
			for id: String in sim.realm.relations:
				best = maxi(best, int(sim.realm.relation(id)))
			return best
		"pact_any":
			return (
				sim
				. realm
				. relations
				. keys()
				. filter(func(id: String) -> bool: return sim.realm.status(id) in ["trade", "alliance"])
				. size()
			)
		"unit_size":
			var best := 0
			for u: Dictionary in sim.units.units.values():
				best = maxi(best, u["members"].size())
			return best
		"kills_prefix":
			return _kills(sim, str(m["what"])) - int(base.get("kills_prefix", 0))
		"bandit_camps":
			return sim.bandits.camps.filter(func(c: Dictionary) -> bool: return c["destroyed"]).size()
		"orc_camps":
			return sim.orcs.camps.filter(func(c: Dictionary) -> bool: return c["destroyed"]).size()
		"barracks":
			return int(sim.realm.barracks_ok())
		"soldiers":
			return sim.realm.soldiers().size()
		"united":
			return _united(sim)
		"united_all":
			var n := sim.realm.neighbours().size()
			return int(n > 0 and _united(sim) >= n)
		"settlements":
			return sim.settlements.items.size()
		"lord":
			return int(sim.realm.lord_id >= 0)
		"cities":
			return sim.settlements.items.filter(func(e: Dictionary) -> bool: return e["kind"] == "city").size()
	return -1


## Valeurs de départ d'un objectif (compteurs qui partent de zéro au début de la mission).
static func base_for(sim: GameSim, m: Dictionary) -> Dictionary:
	if str(m.get("kind", "")) == "kills_prefix":
		return {"kills_prefix": _kills(sim, str(m["what"]))}
	return {}


static func _kills(sim: GameSim, prefix: String) -> int:
	var k := 0
	for l: Lutin in sim.colony.lutins:
		for kind: String in l.kills:
			if kind.begins_with(prefix):
				k += int(l.kills[kind])
	return k


static func _united(sim: GameSim) -> int:
	return (
		sim
		. realm
		. relations
		. keys()
		. filter(func(id: String) -> bool: return sim.realm.status(id) in ["alliance", "conquered"])
		. size()
	)
