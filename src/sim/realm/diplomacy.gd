class_name Diplomacy
extends RefCounted
## Diplomatie poussée (1.4) : jauge de relation (-100 à 100) en 7 niveaux — ennemi mortel, ennemi, suspicieux,
## neutre, favorable, soutien, alliance —, cadeaux (or ou marchandises) et actions débloquées par le niveau de
## Diplomatie du diplomate du royaume ; son charisme et sa Diplomatie renforcent chaque effet.
## Données : data/realm.json › diplomacy (levels, actions). Les relations sont dans Realm.relations.


static func cfg() -> Dictionary:
	return DataRegistry.get_table("realm").get("diplomacy", {})


## Niveau de relation affiché (id, nom, couleur).
static func level(realm: Realm, id: String) -> Dictionary:
	if realm.status(id) == "alliance":
		return {"id": "alliance", "name": "Alliance", "color": "4a90d8"}
	var rel := realm.relation(id)
	var best: Dictionary = {}
	for lv: Dictionary in cfg().get("levels", []):
		if rel >= float(lv["min"]):
			best = lv
	return best if not best.is_empty() else {"id": "neutral", "name": "Neutre", "color": "a0a0a0"}


static func diplomat(realm: Realm) -> Lutin:
	return realm.colony.find_lutin(realm.diplomat_id) if realm.diplomat_id >= 0 else null


## Multiplicateur des effets : 1 + charisme et Diplomatie du diplomate (sans diplomate : effets réduits).
static func power(realm: Realm) -> float:
	var d := diplomat(realm)
	if d == null:
		return float(cfg().get("no_diplomat_mult", 0.6))
	return (
		1.0
		+ float(cfg().get("charisma_mult", 0.01)) * int(d.aptitudes.get("charisma", 0))
		+ float(cfg().get("skill_mult", 0.06)) * Soldiering.skill_level(d, "diplomacy")
	)


## Actions disponibles avec le diplomate actuel (niveau de Diplomatie requis).
static func actions(realm: Realm) -> Array:
	var d := diplomat(realm)
	var lvl := Soldiering.skill_level(d, "diplomacy") if d != null else -1
	return cfg().get("actions", []).filter(
		func(a: Dictionary) -> bool: return int(a.get("min_skill", 0)) <= lvl or int(a.get("min_skill", 0)) < 0
	)


## Fait une action (gift_gold, gift_goods, praise, trade, non_aggression, tribute, alliance, incite, insult, …).
## Renvoie un message. Les actions classiques (paix, guerre…) passent par Realm.diplomacy.
static func act(realm: Realm, id: String, action: String, other: String = "") -> String:
	if not realm.relations.has(id):
		return ""
	var a: Dictionary = {}
	for e: Dictionary in actions(realm):
		if e["id"] == action:
			a = e
	if a.is_empty():
		return "Votre diplomate n'a pas encore le niveau pour cela."
	var r: Dictionary = realm.relations[id]
	var day := GameClock.day()
	if a.get("daily", false) and int(r.get("last_%s" % action, -99)) == day:
		return "Déjà fait aujourd'hui avec eux."
	var cost: Dictionary = a.get("cost", {})
	for k: String in cost:
		if realm.colony.stock.count(k) < int(cost[k]):
			return "Il faut %d %s." % [int(cost[k]), str(Stockpile._resource(k).get("name", k)).to_lower()]
	if realm.relation(id) < float(a.get("min_relation", -999)):
		return "Ils refusent : relation trop basse."
	for k: String in cost:
		realm.colony.stock.take(k, int(cost[k]))
	r["last_%s" % action] = day
	var gain := float(a.get("relation", 0)) * (power(realm) if float(a.get("relation", 0)) > 0 else 1.0)
	r["relation"] = clampf(float(r["relation"]) + gain, -100.0, 100.0)
	var msg := str(a.get("done", "C'est fait."))
	match action:
		"trade":
			r["status"] = "trade"
		"non_aggression":
			r["pact"] = true
		"alliance":
			r["status"] = "alliance"
		"tribute":
			var g := int(float(a.get("gold", 20)) * power(realm))
			realm.colony.stock.add("gold", g)
			msg = "Ils paient un tribut de %d or." % g
		"incite":
			if other != "" and realm.relations.has(other):
				realm.relations[other]["relation"] = clampf(float(realm.relations[other]["relation"]) - 5.0, -100, 100)
				var rv := Rivals.active
				if rv != null:
					rv.states.get(id, {})["rival_of"] = other
				msg = "Votre diplomate les monte contre leurs voisins."
	var d := diplomat(realm)
	if d != null:
		Soldiering.add_skill_xp(d, "diplomacy", float(a.get("xp", 10)))
	return "%s (relation %+d)" % [msg, int(gain)]
