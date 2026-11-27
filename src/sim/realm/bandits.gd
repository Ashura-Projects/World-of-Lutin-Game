class_name Bandits
extends RefCounted
## Bandits (1.4) : lutins gris cachés dans les grandes forêts. Ils attaquent les lutins qui passent près de leur
## camp et, de temps en temps, une bande part piller le village le plus proche (le nôtre ou un voisin) : elle vole
## des ressources puis rentre au camp. Détruire tous les bandits d'un camp le fait disparaître.
## Données : data/military.json › bandits ; sortes bandit_club / bandit_archer (data/animals.json).

static var active: Bandits = null

var sim: GameSim
var camps: Array = []  # {"id", "cell": Vector3i, "destroyed": bool, "next_raid": int}
var next_id: int = 1


func _init(s: GameSim) -> void:
	sim = s
	active = self


static func cfg() -> Dictionary:
	return DataRegistry.get_table("military").get("bandits", {})


func enabled() -> bool:
	return bool(cfg().get("enabled", true)) and sim.rules.mode != "battle"


## Camps dans les forêts denses, loin du départ.
func setup_new(start: Vector3i) -> void:
	if not enabled():
		return
	var area := sim.world.size.x * sim.world.size.z
	var n := clampi(int(area / float(cfg().get("area_per_camp", 40000))), 1, int(cfg().get("max_camps", 12)))
	var spots := _forest_spots(start, n)
	for c: Vector3i in spots:
		add_camp(c)


func _forest_spots(start: Vector3i, n: int) -> Array:
	var out := []
	var min_d := float(cfg().get("min_distance", 50))
	var trees: Array = sim.flora.trees.keys()
	if trees.is_empty():
		return out
	for _try in n * 40:
		if out.size() >= n:
			break
		var t: Vector3i = trees[Rng.randi_range(0, trees.size() - 1)]
		if Vector2(t.x - start.x, t.z - start.z).length() < min_d:
			continue
		if out.any(func(o: Vector3i) -> bool: return Vector3(o).distance_to(Vector3(t)) < min_d):
			continue
		if sim.flora.in_circle("tree", t, 8, 0).size() < int(cfg().get("min_trees", 12)):
			continue  # seulement dans une grande forêt
		var p := Pathfinder.snap(sim.world, t + Vector3i(1, 0, 1))
		if p.y >= 0:
			out.append(p)
	return out


func add_camp(cell: Vector3i) -> Dictionary:
	var c := {
		"id": next_id,
		"cell": cell,
		"destroyed": false,
		"next_raid": GameClock.day() + int(cfg().get("raid_every_days", 9))
	}
	next_id += 1
	camps.append(c)
	for g: Dictionary in cfg().get("camp_band", []):
		for _i in int(g["n"]):
			_spawn(str(g["kind"]), cell, int(c["id"]))
	return c


func _spawn(kind: String, near: Vector3i, camp_id: int) -> Dictionary:
	var p := Pathfinder.snap(sim.world, near + Vector3i(Rng.randi_range(-3, 3), 0, Rng.randi_range(-3, 3)))
	if p.y < 0:
		return {}
	var a := sim.fauna.spawn(kind, p)
	a["hp"] = float(a["hp"]) * GameRules.get_mult("enemy_hp")
	a["camp"] = camp_id
	a["home"] = near
	a["roam"] = int(cfg().get("roam", 7))
	a["faction"] = "bandits"
	return a


func members(camp_id: int) -> Array:
	return sim.fauna.animals.filter(
		func(a: Dictionary) -> bool: return str(a["kind"]).begins_with("bandit") and int(a.get("camp", -1)) == camp_id
	)


## Village le plus proche à piller : le nôtre ou un village voisin. [case, id faction ("player" ou voisin)].
func _target(c: Dictionary) -> Array:
	var best := [sim.colony.stock.pos, "player"]
	var bd := Vector3(c["cell"]).distance_to(Vector3(sim.colony.stock.pos))
	if Rivals.active != null:
		for st: Dictionary in Rivals.active.present():
			var d := Vector3(c["cell"]).distance_to(Vector3(st["cell"]))
			if d < bd:
				bd = d
				best = [st["cell"], st["id"]]
	return best


func daily() -> void:
	if not enabled():
		return
	for c: Dictionary in camps:
		if c["destroyed"]:
			continue
		var band := members(c["id"])
		if band.is_empty():
			c["destroyed"] = true
			sim.colony.stock.add("gold", int(cfg().get("camp_gold", 15)))
			EventBus.alert.emit("victoire", "Un camp de bandits est vidé : vous récupérez leur butin.")
			continue
		if GameClock.day() >= int(c["next_raid"]):
			c["next_raid"] = GameClock.day() + int(cfg().get("raid_every_days", 9))
			var t := _target(c)
			var n := mini(band.size(), int(cfg().get("raid_size", 4)))
			for i in n:
				band[i]["raid"] = true
				band[i]["goal"] = t[0]
				band[i]["target_faction"] = t[1]
			if t[1] == "player":
				EventBus.alert.emit("alerte", "Des bandits approchent du village pour piller !")


## Chaque seconde : les pillards arrivés volent et rentrent ; les pillards en fuite reviennent au camp.
func tick_second() -> void:
	for a: Dictionary in sim.fauna.animals:
		if not str(a["kind"]).begins_with("bandit") or not a.get("raid", false):
			continue
		var goal: Vector3i = a.get("goal", a["cell"])
		if Vector3(a["cell"]).distance_to(Vector3(goal)) > 4.0:
			continue
		_pillage(a)
		a["raid"] = false
		a["goal"] = a.get("home", a["cell"])
		a["path"] = Pathfinder.find(sim.world, a["cell"], Pathfinder.snap(sim.world, a["goal"]), 600, true)
		a["path_i"] = 1


func _pillage(a: Dictionary) -> void:
	var fid := str(a.get("target_faction", "player"))
	var n := int(cfg().get("steal_per_bandit", 6))
	if fid == "player":
		var st := sim.colony.stock
		var keys := st.items.keys().filter(func(k: String) -> bool: return st.count(k) > 0)
		if keys.is_empty():
			return
		var k: String = keys[Rng.randi_range(0, keys.size() - 1)]
		var got := st.take(k, n)
		EventBus.alert.emit(
			"alerte", "Des bandits ont volé %d %s !" % [got, str(Stockpile._resource(k).get("name", k)).to_lower()]
		)
	elif Rivals.active != null and Rivals.active.states.has(fid):
		var rs: Dictionary = Rivals.active.states[fid]
		rs["wealth"] = maxf(0.0, float(rs.get("wealth", 0)) - n)


func to_dict() -> Dictionary:
	var out := []
	for c: Dictionary in camps:
		var p: Vector3i = c["cell"]
		out.append({"id": c["id"], "cell": [p.x, p.y, p.z], "destroyed": c["destroyed"], "next_raid": c["next_raid"]})
	return {"camps": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	camps.clear()
	for e: Dictionary in d.get("camps", []):
		var p: Array = e["cell"]
		camps.append(
			{
				"id": int(e["id"]),
				"cell": Vector3i(int(p[0]), int(p[1]), int(p[2])),
				"destroyed": bool(e["destroyed"]),
				"next_raid": int(e.get("next_raid", 0))
			}
		)
	next_id = int(d.get("next_id", camps.size() + 1))
	active = self
