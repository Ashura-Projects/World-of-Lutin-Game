class_name Livestock
extends RefCounted
## Élevage (1.3.2) : vaches (lait, viande, peaux) et cochons (viande, peau). On les achète au marchand ambulant,
## on peut les revendre ou les abattre. Ils vivent autour de leur abreuvoir / auge (enclos de clôtures conseillé),
## mangent chaque jour à la réserve, donnent leur produit (lait) et font des petits s'ils sont bien nourris.


static func cfg() -> Dictionary:
	return DataRegistry.get_table("animals").get("livestock", {})


static func is_livestock(kind: String) -> bool:
	return bool(DataRegistry.find("animals", "animals", kind).get("livestock", false))


static func owned(sim: GameSim, kind: String = "") -> Array:
	return sim.fauna.animals.filter(
		func(a: Dictionary) -> bool:
			return a.get("owned", false) and is_livestock(a["kind"]) and (kind == "" or a["kind"] == kind)
	)


## Case d'attache : abreuvoir / auge / mangeoire le plus proche de la réserve, sinon la réserve.
static func home_cell(sim: GameSim) -> Vector3i:
	for tag: String in ["trough", "feeder"]:
		var list := sim.structures.built_with_tag(tag)
		if not list.is_empty():
			return list[0]["cell"]
	return sim.colony.stock.pos


static func add_owned(sim: GameSim, kind: String, near: Vector3i) -> Dictionary:
	var p := Pathfinder.snap(sim.world, near + Vector3i(Rng.randi_range(-1, 1), 0, Rng.randi_range(-1, 1)))
	if p.y < 0:
		p = Pathfinder.snap(sim.world, sim.colony.stock.pos)
	var a := sim.fauna.spawn(kind, p)
	a["owned"] = true
	a["home"] = near
	a["roam"] = int(cfg().get("roam", 5))
	a["hungry"] = 0
	return a


## Prix d'achat au marchand (comme une ressource : majoré, et l'accord commercial aide).
static func buy_price(_sim: GameSim, kind: String) -> int:
	var base := int(DataRegistry.find("animals", "animals", kind).get("price", 40))
	var b: float = Realm.active.trade_bonus() if Realm.active != null else 0.0
	return maxi(1, ceili(base * (1.0 - b)))


static func sell_price(kind: String) -> int:
	var base := int(DataRegistry.find("animals", "animals", kind).get("price", 40))
	return maxi(1, floori(base * float(cfg().get("sell_ratio", 0.7))))


## Acheter une bête au marchand (s'il est là et en propose). Renvoie un message.
static func buy(sim: GameSim, kind: String) -> String:
	var tr := sim.trade
	if not tr.present:
		return "Le marchand n'est pas là."
	if int(tr.animal_offers.get(kind, 0)) <= 0:
		return "Le marchand n'en a plus."
	var p := buy_price(sim, kind)
	if sim.colony.stock.count("gold") < p:
		return "Pas assez d'or (%d)." % p
	sim.colony.stock.take("gold", p)
	tr.animal_offers[kind] = int(tr.animal_offers[kind]) - 1
	add_owned(sim, kind, home_cell(sim))
	return "%s achetée pour %d or." % [DataRegistry.find("animals", "animals", kind).get("name", kind), p]


## Vendre une bête au marchand.
static func sell(sim: GameSim, a: Dictionary) -> String:
	if not sim.trade.present:
		return "Le marchand n'est pas là : il passe régulièrement."
	var p := sell_price(a["kind"])
	sim.colony.stock.add("gold", p)
	sim.fauna.damage(a["id"], 99999.0)
	return "Vendue %d or." % p


## Abattre : viande et peaux déposées au sol (les porteurs les rangent).
static func slaughter(sim: GameSim, a: Dictionary) -> String:
	var drop: Dictionary = sim.fauna.def(a["kind"]).get("drop", {})
	var cell: Vector3i = a["cell"]
	sim.fauna.damage(a["id"], 99999.0)
	sim.ground.drop(cell, drop)
	return "Abattue : la viande et les peaux sont au sol, les porteurs les rangent."


## Chaque matin : repas, produit (lait), petits.
static func daily(sim: GameSim) -> void:
	var fed := {}
	for a: Dictionary in owned(sim):
		var d := sim.fauna.def(a["kind"])
		var ate := false
		for food: String in d.get("eats_any", ["straw"]):
			if sim.colony.stock.take(food, 1) == 1:
				ate = true
				break
		if ate:
			a["hungry"] = 0
			fed[a["kind"]] = int(fed.get(a["kind"], 0)) + 1
			var prod: Dictionary = d.get("product", {})
			for k: String in prod:
				sim.colony.stock.add(k, int(prod[k]))
		else:
			a["hungry"] = int(a.get("hungry", 0)) + 1
			if int(a["hungry"]) >= 3:
				a["hp"] = float(a["hp"]) - float(cfg().get("hungry_hp_loss", 10))
				if float(a["hp"]) <= 0.0:
					sim.fauna.damage(a["id"], 1.0)
					EventBus.alert.emit("alerte", "Une bête de l'élevage est morte de faim.")
	for kind: String in fed:
		var d := sim.fauna.def(kind)
		var every := maxi(1, int(d.get("breed_days", 10)))
		if int(fed[kind]) >= 2 and GameClock.day() % every == 0:
			if owned(sim, kind).size() < int(cfg().get("max_per_kind", 20)):
				add_owned(sim, kind, home_cell(sim))
				EventBus.alert.emit("info", "Un petit est né à l'élevage (%s)." % d.get("name", kind))
