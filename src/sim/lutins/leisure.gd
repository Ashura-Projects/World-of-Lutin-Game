class_name Leisure
extends RefCounted
## Loisirs (1.3) : un lutin libre va parfois jouer (dés, échecs, cartes) ou boire au bar (bière, vin) ;
## il en tire un bonus de moral (Lutin.fun) qui baisse chaque jour.

const FUN_MAX := 20.0


## Appelé quand un lutin n'a rien à faire. Renvoie true s'il part se divertir.
static func try(colony: Colony, l: Lutin) -> bool:
	if colony.structures == null or l.fun >= FUN_MAX * 0.5 or not Rng.chance(0.25):
		return false
	var best: Dictionary = {}
	var bd := 40.0
	for s: Dictionary in colony.structures.built_with_tag("leisure"):
		var d := Vector3(s["cell"]).distance_to(Vector3(l.cell))
		if d < bd:
			bd = d
			best = s
	if best.is_empty():
		return false
	l.order = {"kind": "leisure", "cell": best["cell"], "stage": 0, "until": 0, "tries": 0, "hold_s": 25.0}
	return true


## Arrivé au jeu ou au bar : bonus de moral ; au bar, il boit une bière ou un vin s'il y en a.
static func enjoy(colony: Colony, l: Lutin) -> void:
	l.fun = minf(FUN_MAX, l.fun + 8.0)
	var s := colony.structures.at(l.order.get("cell", l.cell))
	if not s.is_empty() and Structures.def(s["kind"]).get("tags", []).has("bar"):
		for drink: String in ["wine", "beer"]:
			if colony.stock.take(drink, 1) == 1:
				l.fun = minf(FUN_MAX, l.fun + float(Stockpile._resource(drink).get("fun", 6)))
				break


static func daily(colony: Colony) -> void:
	for l in colony.lutins:
		l.fun = maxf(0.0, l.fun - 5.0)
