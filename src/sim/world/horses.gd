class_name Horses
extends RefCounted
## Chevaux (1.3) : sauvages dans les plaines ; on les capture si une mangeoire et un abreuvoir sont bâtis.
## Un lutin monté va bien plus vite (data/animals.json › horse.mount_speed). Ils mangent de la paille chaque jour.


static func _cfg() -> Dictionary:
	return DataRegistry.find("animals", "animals", "horse")


static func capture(sim: GameSim, a: Dictionary) -> String:
	var feeder := sim.structures.built_with_tag("feeder")
	var trough := sim.structures.built_with_tag("trough")
	if feeder.is_empty() or trough.is_empty():
		return "Il faut d'abord une mangeoire et un abreuvoir (Construire › Meubles ou Défense)."
	a["owned"] = true
	a["home"] = trough[0]["cell"]
	a["roam"] = 4
	a["rider"] = -1
	return "Cheval capturé : il reste près de l'abreuvoir."


static func release(sim: GameSim, a: Dictionary) -> String:
	var rider := sim.colony.find_lutin(int(a.get("rider", -1)))
	if rider != null:
		dismount(sim, rider)
	a["owned"] = false
	a.erase("home")
	return "Cheval relâché."


static func owned(sim: GameSim) -> Array:
	return sim.fauna.animals.filter(func(a: Dictionary) -> bool: return a["kind"] == "horse" and a.get("owned", false))


static func free_horse_near(sim: GameSim, cell: Vector3i) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for a: Dictionary in owned(sim):
		if int(a.get("rider", -1)) >= 0:
			continue
		var d := Vector3(a["cell"]).distance_to(Vector3(cell))
		if d < bd:
			bd = d
			best = a
	return best


static func mount(_sim: GameSim, l: Lutin, a: Dictionary) -> void:
	l.horse = a["id"]
	a["rider"] = l.id


static func dismount(sim: GameSim, l: Lutin) -> void:
	var a := sim.fauna.find(l.horse)
	if not a.is_empty():
		a["rider"] = -1
		a["home"] = a.get("home", l.cell)
	l.horse = -1


static func speed_mult(l: Lutin) -> float:
	return float(_cfg().get("mount_speed", 2.2)) if l.horse >= 0 else 1.0


## Chaque tick : un cheval monté suit son cavalier.
static func tick(sim: GameSim) -> void:
	for l in sim.colony.lutins:
		if l.horse < 0:
			continue
		var a := sim.fauna.find(l.horse)
		if a.is_empty():
			l.horse = -1
			continue
		a["pos"] = l.pos
		a["cell"] = l.cell
		a["path"] = []
		a["path_i"] = 0
		a["wait"] = 10


## Chaque jour : les chevaux mangent ; sans paille 3 jours, ils s'enfuient.
static func daily(sim: GameSim) -> void:
	var eats: Dictionary = _cfg().get("eats_per_day", {"straw": 1})
	for a: Dictionary in owned(sim):
		var ok := true
		for k: String in eats:
			if sim.colony.stock.take(k, int(eats[k])) < int(eats[k]):
				ok = false
		a["hungry"] = 0 if ok else int(a.get("hungry", 0)) + 1
		if int(a["hungry"]) >= 3:
			release(sim, a)
			EventBus.alert.emit("alerte", "Un cheval affamé s'est enfui (il faut de la paille).")
