class_name NpcCombat
extends RefCounted
## Combats entre personnages non joueurs (1.4) : les bandits s'en prennent à tout le monde, les orcs aux villages
## voisins, les voisins défendent leurs gens et se battent entre eux s'ils ont été montés l'un contre l'autre.
## Chaque combattant frappe à sa cadence (data/animals.json : damage, reach, attack_every_s).


static func faction_of(a: Dictionary, fauna: Fauna) -> String:
	if a.has("faction"):
		return str(a["faction"])
	return str(fauna.def(a["kind"]).get("faction", ""))


static func enemies(fa: String, fb: String) -> bool:
	if fa == "" or fb == "" or fa == fb:
		return false
	if fa == "bandits" or fb == "bandits":
		return true
	if fa == "orcs" or fb == "orcs":
		return true
	if Rivals.active != null:
		var sa: Dictionary = Rivals.active.states.get(fa, {})
		var sb: Dictionary = Rivals.active.states.get(fb, {})
		return str(sa.get("rival_of", "")) == fb or str(sb.get("rival_of", "")) == fa
	return false


## Appelé deux fois par seconde.
static func tick(fauna: Fauna, dt: float) -> void:
	var fighters := fauna.animals.filter(func(a: Dictionary) -> bool: return faction_of(a, fauna) != "")
	for a: Dictionary in fighters:
		var d := fauna.def(a["kind"])
		var dmg := float(d.get("damage", 0))
		if dmg <= 0.0:
			continue
		a["npc_cool"] = float(a.get("npc_cool", 0.0)) - dt
		if float(a["npc_cool"]) > 0.0:
			continue
		var fa := faction_of(a, fauna)
		var reach := float(d.get("reach", 1.3)) + 0.3
		for b: Dictionary in fighters:
			if b == a or not enemies(fa, faction_of(b, fauna)):
				continue
			if (a["pos"] as Vector3).distance_to(b["pos"]) > reach:
				continue
			a["npc_cool"] = float(d.get("attack_every_s", 1.6))
			var kind: String = b["kind"]
			if fauna.damage(b["id"], dmg):
				_on_death(kind)
			break


## Un villageois ou soldat voisin tué : leur village perd un habitant ou un soldat.
static func _on_death(kind: String) -> void:
	if Rivals.active == null:
		return
	var parts := kind.split("_")
	if parts.size() < 2 or not Rivals.active.states.has(parts[1]):
		return
	var st: Dictionary = Rivals.active.states[parts[1]]
	var key := "soldiers" if parts[0] == "soldier" else "population"
	st[key] = maxi(0, int(st.get(key, 0)) - 1)
