class_name Rivals
extends RefCounted
## Factions voisines gérées par l'IA (Phase 2-3) : villages de lutins jaunes, rouges et vert clair.
## Chaque village a une population, des soldats, de l'or et un territoire ; l'IA s'étend, commerce,
## peut déclarer la guerre (raids de soldats) et proposer la paix. On peut conquérir un village.
## Relations et statuts : Realm (diplomatie) ; territoires : Territory.

signal conquered(id: String)
signal victory

static var active: Rivals = null

var world: VoxelWorld
var fauna: Fauna
var colony: Colony
var flora: Flora
var territory: Territory
var states: Dictionary = {}  # id -> état du village
var won: bool = false
var _cfg: Dictionary


func _init(w: VoxelWorld, f: Fauna, c: Colony, fl: Flora, t: Territory) -> void:
	world = w
	fauna = f
	colony = c
	flora = fl
	territory = t
	_cfg = DataRegistry.get_table("factions")
	for fd: Dictionary in defs():
		_register(fd)
	active = self


static func defs() -> Array:
	return DataRegistry.get_table("factions").get("factions", [])


static func def(id: String) -> Dictionary:
	for f: Dictionary in defs():
		if f["id"] == id:
			return f
	return {}


## Sortes d'animaux pour les villageois (paisibles) et les soldats (ennemis en guerre) de chaque faction.
func _register(fd: Dictionary) -> void:
	var npc: Dictionary = _cfg.get("npc", {})
	var v: Dictionary = npc.get("villager", {}).duplicate()
	v.merge({"name": "Villageois (%s)" % fd["name"], "npc": true, "faction": fd["id"], "per_1000": 0}, true)
	fauna.register_def("villager_" + str(fd["id"]), v)
	var s: Dictionary = npc.get("soldier", {}).duplicate()
	s.merge(
		{"name": "Soldat (%s)" % fd["name"], "hostile": true, "enemy": true, "faction": fd["id"], "per_1000": 0}, true
	)
	fauna.register_def("soldier_" + str(fd["id"]), s)


func present() -> Array:
	return states.values().filter(func(s: Dictionary) -> bool: return not s["conquered"])


## Nouvelle partie : n villages loin du départ, en plaine, avec leur territoire.
func setup_new(start: Vector3i, n: int) -> void:
	territory.claim(start, int(_cfg.get("territory", {}).get("player_start_radius", 2)), "player")
	territory.explore(start, 3)
	var vcfg: Dictionary = _cfg.get("village", {})
	var spots := _spots(start, mini(n, defs().size()))
	for i in spots.size():
		var fd: Dictionary = defs()[i]
		var center: Vector3i = spots[i]
		var hr: Array = vcfg.get("houses", [4, 7])
		var houses := VillageStamp.village(
			world, flora, center, Rng.randi_range(int(hr[0]), int(hr[1])), int(vcfg.get("spread", 10))
		)
		var pr: Array = vcfg.get("start_population", [12, 20])
		var sr: Array = vcfg.get("start_soldiers", [3, 6])
		var wr: Array = vcfg.get("start_wealth", [50, 120])
		states[fd["id"]] = {
			"id": fd["id"],
			"center": Pathfinder.snap(world, center),
			"houses": houses,
			"population": Rng.randi_range(int(pr[0]), int(pr[1])),
			"soldiers": Rng.randi_range(int(sr[0]), int(sr[1])),
			"wealth": float(Rng.randi_range(int(wr[0]), int(wr[1]))),
			"conquered": false,
			"war_days": 0,
			"last_raid": 0,
			"peace_offer": false
		}
		territory.claim(center, int(_cfg.get("territory", {}).get("village_radius", 2)), fd["id"])
		_spawn_villagers(states[fd["id"]])


func _spots(start: Vector3i, n: int) -> Array:
	var vcfg: Dictionary = _cfg.get("village", {})
	var min_d := float(vcfg.get("min_distance_ratio", 0.25)) * float(mini(world.size.x, world.size.z))
	var spacing := float(vcfg.get("spacing", 70))
	var out := []
	for _i in 400:
		if out.size() >= n:
			break
		var x := Rng.randi_range(16, world.size.x - 17)
		var z := Rng.randi_range(16, world.size.z - 17)
		var y := world.surface_y(x, z)
		if y <= 0 or world.get_block(Vector3i(x, y - 1, z)) != world.types.num("grass"):
			continue
		if Vector2(x - start.x, z - start.z).length() < min_d:
			continue
		if out.any(func(o: Vector3i) -> bool: return Vector2(o.x - x, o.z - z).length() < spacing):
			continue
		if (
			Orcs.active != null
			and Orcs.active.camps.any(
				func(c: Dictionary) -> bool: return Vector3(c["cell"]).distance_to(Vector3(x, y, z)) < spacing * 0.6
			)
		):
			continue
		var flat := true
		for d: Vector2i in [Vector2i(6, 0), Vector2i(-6, 0), Vector2i(0, 6), Vector2i(0, -6)]:
			if absi(world.surface_y(x + d.x, z + d.y) - y) > 2:
				flat = false
		if flat:
			out.append(Vector3i(x, y, z))
	return out


func _spawn_villagers(st: Dictionary) -> void:
	var vcfg: Dictionary = _cfg.get("village", {})
	for _i in mini(int(vcfg.get("villagers_shown", 6)), int(st["population"])):
		_spawn("villager_" + str(st["id"]), st["center"], int(vcfg.get("roam", 12)))


func _spawn(kind: String, near: Vector3i, roam: int) -> Dictionary:
	var p := Pathfinder.snap(world, near + Vector3i(Rng.randi_range(-4, 4), 0, Rng.randi_range(-4, 4)))
	if p.y < 0:
		p = Pathfinder.snap(world, near)
	if p.y < 0:
		return {}
	var a := fauna.spawn(kind, p)
	a["home"] = near
	a["roam"] = roam
	a["faction"] = kind.split("_")[1]
	a["name"] = colony.unique_name(DataRegistry.get_table("names").get("names", ["Lutin"]))
	if kind.begins_with("soldier_"):
		a["hp"] = float(a["hp"]) * GameRules.get_mult("enemy_hp")
	return a


## Brouillard de guerre : on « rencontre » une faction en explorant son village.
func check_meetings() -> void:
	for st: Dictionary in states.values():
		if not st.get("met", false) and territory.explored.has(territory.col_of(st["center"])):
			st["met"] = true
			var fd := def(st["id"])
			EventBus.alert.emit(
				"faction", "Vous avez rencontré %s : %s" % [fd.get("name", st["id"]), fd.get("desc", "")]
			)


func is_met(id: String) -> bool:
	return bool(states.get(id, {}).get("met", false))


func units_of(id: String, prefix: String) -> Array:
	return fauna.animals.filter(func(a: Dictionary) -> bool: return a["kind"] == prefix + id)


func _realm() -> Realm:
	return Realm.active


# --- guerre et paix ------------------------------------------------------------------------------
## Guerre : des soldats gardent le village (on peut le conquérir) ; l'IA lancera des raids.
func on_war(id: String) -> void:
	var st: Dictionary = states.get(id, {})
	if st.is_empty() or st["conquered"]:
		return
	st["war_days"] = 0
	st["peace_offer"] = false
	var n := mini(int(st["soldiers"]), int(_cfg.get("village", {}).get("soldiers_shown", 3)))
	for _i in maxi(n, 1):
		_spawn("soldier_" + id, st["center"], 6)


## Paix : les soldats rentrent (retirés de la carte).
func on_peace(id: String) -> void:
	for a in units_of(id, "soldier_"):
		fauna.animals.erase(a)
		fauna.animal_removed.emit(a["id"])
	var st: Dictionary = states.get(id, {})
	if not st.is_empty():
		st["war_days"] = 0
		st["peace_offer"] = false


func _war_raid(st: Dictionary) -> int:
	var ai: Dictionary = _cfg.get("ai", {})
	var n := clampi(int(st["soldiers"] * 0.5 * GameRules.get_mult("raid_size")), 1, int(ai.get("war_raid_max", 10)))
	var made := 0
	for _i in n:
		var a := _spawn("soldier_" + str(st["id"]), st["center"], 6)
		if a.is_empty():
			continue
		a["raid"] = true
		a["goal"] = colony.stock.pos
		a.erase("home")
		made += 1
	st["soldiers"] = maxi(0, int(st["soldiers"]) - made)
	EventBus.alert.emit(
		"alerte", "%s attaque le village avec %d soldats !" % [def(st["id"]).get("name", st["id"]), made]
	)
	return made


## Conquête : en guerre, des lutins armés au centre du village et plus aucun défenseur autour.
func check_conquest() -> void:
	var ai: Dictionary = _cfg.get("ai", {})
	for st: Dictionary in present():
		if _realm() == null or _realm().status(st["id"]) != "war":
			continue
		var c: Vector3i = st["center"]
		var attackers := colony.lutins.filter(
			func(l: Lutin) -> bool:
				return (
					(l.mobilized or l.weapon != "")
					and Vector3(l.cell).distance_to(Vector3(c)) <= float(ai.get("conquest_radius", 8))
				)
		)
		if attackers.is_empty():
			continue
		var r := float(ai.get("defense_radius", 20))
		if units_of(st["id"], "soldier_").any(
			func(a: Dictionary) -> bool: return Vector3(a["cell"]).distance_to(Vector3(c)) <= r
		):
			continue
		conquer(st["id"])


func conquer(id: String) -> void:
	var st: Dictionary = states[id]
	var ai: Dictionary = _cfg.get("ai", {})
	st["conquered"] = true
	_realm().relations[id]["status"] = "conquered"
	on_peace(id)
	territory.transfer(id, "player")
	colony.stock.add("gold", int(ai.get("conquest_loot_gold", 80)))
	var joined := 0
	for a in units_of(id, "villager_"):
		if joined < int(ai.get("conquest_join", 3)):
			recruit(a)
			joined += 1
	EventBus.alert.emit(
		"victoire", "%s est conquis ! %d villageois vous rejoignent." % [def(id).get("name", id), joined]
	)
	conquered.emit(id)


## Un villageois d'une autre faction rejoint le village (conquête ou foi à 100 %).
func recruit(a: Dictionary) -> Lutin:
	var l := DebugTools.spawn_lutin_at(colony, a["cell"], str(a.get("name", "")))
	fauna.animals.erase(a)
	fauna.animal_removed.emit(a["id"])
	return l


# --- IA quotidienne ------------------------------------------------------------------------------
func daily(day: int) -> void:
	var ai: Dictionary = _cfg.get("ai", {})
	for st: Dictionary in present():
		var fd := def(st["id"])
		st["wealth"] = float(st["wealth"]) + int(st["population"]) * float(ai.get("income_per_pop", 0.4))
		if Rng.chance(float(ai.get("growth_per_day", 0.05))):
			st["population"] = int(st["population"]) + 1
		var max_s := int(int(st["population"]) * float(ai.get("max_soldiers_ratio", 0.4)))
		if int(st["soldiers"]) < max_s and float(st["wealth"]) >= float(ai.get("soldier_cost", 15)):
			st["wealth"] = float(st["wealth"]) - float(ai.get("soldier_cost", 15))
			st["soldiers"] = int(st["soldiers"]) + 1
		_expand(st, ai)
		if _realm() == null:
			continue
		var status := _realm().status(st["id"])
		var aggr := float(fd.get("aggression", 0.5)) * GameRules.get_mult("ai_aggression")
		if status == "war":
			st["war_days"] = int(st["war_days"]) + 1
			if day - int(st["last_raid"]) >= int(ai.get("war_raid_every_days", 15)) and int(st["soldiers"]) > 0:
				st["last_raid"] = day
				_war_raid(st)
			if int(st["war_days"]) >= int(ai.get("peace_after_days", 40)) and not st["peace_offer"]:
				st["peace_offer"] = true
				EventBus.alert.emit("faction", "%s propose la paix (Royaume › Diplomatie)." % fd.get("name", st["id"]))
		elif status not in ["alliance", "conquered"]:
			if (
				_realm().relation(st["id"]) <= float(ai.get("war_relation", -50))
				and Rng.chance(float(ai.get("war_chance_per_day", 0.04)) * aggr)
			):
				_realm().relations[st["id"]]["status"] = "war"
				on_war(st["id"])
				EventBus.alert.emit("alerte", "%s vous déclare la guerre !" % fd.get("name", st["id"]))
	_check_victory()


## L'IA achète une colonne libre au bord de son territoire ; empiéter sur le joueur crée des tensions.
func _expand(st: Dictionary, ai: Dictionary) -> void:
	var cost := float(ai.get("claim_cost", 25))
	if float(st["wealth"]) < cost or not Rng.chance(float(ai.get("claim_chance_per_day", 0.25))):
		return
	var c := territory.free_neighbour(st["id"])
	if c.x < 0:
		return
	st["wealth"] = float(st["wealth"]) - cost
	territory.owners[c] = st["id"]
	territory.version += 1
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if territory.owners.get(c + d, "") == "player" and _realm() != null:
			var r: Dictionary = _realm().relations[st["id"]]
			r["relation"] = float(r["relation"]) - float(ai.get("border_tension", 1.0))


## Aventure Royale : victoire quand plus aucun camp d'orcs et chaque voisin conquis ou allié.
func _check_victory() -> void:
	if won or GameRules.active == null or not GameRules.active.victory_enabled():
		return
	if Orcs.active != null and not Orcs.active.alive_camps().is_empty():
		return
	for st: Dictionary in present():
		if _realm().status(st["id"]) != "alliance":
			return
	won = true
	EventBus.alert.emit("victoire", "VICTOIRE ! Les lutins vous proclament roi. La partie continue.")
	victory.emit()


func to_dict() -> Dictionary:
	var out := []
	for st: Dictionary in states.values():
		var e := st.duplicate()
		var c: Vector3i = st["center"]
		e["center"] = [c.x, c.y, c.z]
		e["houses"] = st["houses"].map(func(h: Vector3i) -> Array: return [h.x, h.y, h.z])
		out.append(e)
	return {"states": out, "won": won}


func from_dict(d: Dictionary) -> void:
	states.clear()
	for e: Dictionary in d.get("states", []):
		var st := e.duplicate()
		var c: Array = e["center"]
		st["center"] = Vector3i(int(c[0]), int(c[1]), int(c[2]))
		st["houses"] = e.get("houses", []).map(
			func(h: Array) -> Vector3i: return Vector3i(int(h[0]), int(h[1]), int(h[2]))
		)
		for k: String in ["population", "soldiers", "war_days", "last_raid"]:
			st[k] = int(e.get(k, 0))
		st["wealth"] = float(e.get("wealth", 0))
		states[st["id"]] = st
	won = bool(d.get("won", false))
	active = self
