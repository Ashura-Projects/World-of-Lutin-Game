class_name Orcs
extends RefCounted
## Orcs (Phase 2) : camps dans les grandes forêts, garnisons, raids réguliers vers le village (tous les N jours,
## réglable), sièges (ils cassent les blocs qui bloquent le passage, ce qui n'est plus soutenu s'effondre).
## On peut attaquer un camp : sans défenseurs et avec un lutin armé à côté, il est détruit (butin).

signal camp_destroyed(id: int)
signal raid_started(size: int)

static var active: Orcs = null

var world: VoxelWorld
var fauna: Fauna
var colony: Colony
var flora: Flora
var camps: Array = []  # {"id", "cell": Vector3i, "destroyed": bool, "discovered": bool}
var next_raid_day: int = -1
var raid_count: int = 0
var _cfg: Dictionary


func _init(w: VoxelWorld, f: Fauna, c: Colony, fl: Flora) -> void:
	world = w
	fauna = f
	colony = c
	flora = fl
	_cfg = DataRegistry.get_table("military").get("orcs", {})
	active = self


func enabled() -> bool:
	return GameRules.active != null and GameRules.active.orcs


func interval() -> int:
	var days := GameRules.active.raid_days if GameRules.active != null else 100
	return maxi(5, roundi(days * GameRules.get_mult("raid_interval")))


## Nouvelle partie : camps dans les forêts denses, loin du départ.
func setup_new(start: Vector3i) -> void:
	if not enabled():
		return
	var n := int(_cfg.get("camps_per_size", {}).get(GameSetup.map_size, 2))
	for cell: Vector3i in pick_camp_spots(start, n):
		add_camp(cell)
	next_raid_day = GameClock.day() + interval()


func pick_camp_spots(start: Vector3i, n: int) -> Array:
	var trees: Array = flora.trees.keys()
	var min_d := minf(
		float(_cfg.get("camp_min_distance_ratio", 0.3)) * float(mini(world.size.x, world.size.z)),
		float(_cfg.get("camp_min_distance_streamed", 150)) if GameSetup.size_def().get("streamed", false) else INF
	)
	var spacing := float(_cfg.get("camp_spacing", 60))
	var cands := []
	for _i in mini(500, trees.size()):
		var t: Vector3i = trees[Rng.randi_range(0, trees.size() - 1)]
		if Vector2(t.x - start.x, t.z - start.z).length() < min_d:
			continue
		var dens := 0
		for dx in range(-8, 9, 2):
			for dz in range(-8, 9, 2):
				for dy in range(-2, 3):
					if flora.trees.has(t + Vector3i(dx, dy, dz)):
						dens += 1
		cands.append([dens, t])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var out := []
	for c: Array in cands:
		var t: Vector3i = c[1]
		if out.any(func(o: Vector3i) -> bool: return Vector2(o.x - t.x, o.z - t.z).length() < spacing):
			continue
		var p := Pathfinder.snap(world, t)
		if p.y >= 0:
			out.append(p)
		if out.size() >= n:
			break
	return out


func add_camp(cell: Vector3i) -> Dictionary:
	var r := int(_cfg.get("camp_clearing", 5))
	for p: Vector3i in flora.trees.keys():
		if absi(p.x - cell.x) <= r and absi(p.z - cell.z) <= r:
			flora.trees.erase(p)
	flora.changed.emit("trees")
	var camp := {"id": camps.size() + 1, "cell": cell, "destroyed": false, "discovered": false}
	camps.append(camp)
	_garrison(camp)
	return camp


func orcs_of(camp_id: int, raiders: bool = false) -> Array:
	return fauna.animals.filter(
		func(a: Dictionary) -> bool: return int(a.get("camp", -1)) == camp_id and bool(a.get("raid", false)) == raiders
	)


func _spawn(kind: String, near: Vector3i, camp_id: int) -> Dictionary:
	var p := Pathfinder.snap(world, near + Vector3i(Rng.randi_range(-3, 3), 0, Rng.randi_range(-3, 3)))
	if p.y < 0:
		p = Pathfinder.snap(world, near)
	if p.y < 0:
		return {}
	var a := fauna.spawn(kind, p)
	a["hp"] = float(a["hp"]) * GameRules.get_mult("enemy_hp")
	a["camp"] = camp_id
	a["home"] = near
	a["roam"] = int(_cfg.get("wander_radius", 8))
	return a


## Défenseurs du camp (complétés s'il en manque).
func _garrison(camp: Dictionary) -> void:
	var have := orcs_of(camp["id"])
	var groups: Array = _cfg.get("camp_garrison", [])
	for g: Dictionary in groups:
		var missing := int(g["n"]) - have.filter(func(a: Dictionary) -> bool: return a["kind"] == g["kind"]).size()
		for _i in missing:
			_spawn(str(g["kind"]), camp["cell"], camp["id"])
	if GameClock.day() >= int(_cfg.get("camp_garrison_brute_from_day", 120)):
		if not have.any(func(a: Dictionary) -> bool: return a["kind"] == "orc_brute"):
			_spawn("orc_brute", camp["cell"], camp["id"])


func alive_camps() -> Array:
	return camps.filter(func(c: Dictionary) -> bool: return not c["destroyed"])


func daily(day: int) -> void:
	if not enabled():
		return
	if day % int(_cfg.get("respawn_every_days", 12)) == 0:
		for c: Dictionary in alive_camps():
			_garrison(c)
	if next_raid_day < 0:
		next_raid_day = day + interval()
	if day == next_raid_day - int(_cfg.get("warning_days", 2)):
		EventBus.alert.emit("alerte", "Les tambours des orcs résonnent dans la forêt… un raid approche.")
	if day >= next_raid_day:
		raid()
		next_raid_day = day + interval()


## Lance un raid depuis le camp vivant le plus proche du village. Renvoie le nombre d'orcs.
func raid() -> int:
	var live := alive_camps()
	if live.is_empty():
		return 0
	var home := colony.stock.pos
	live.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return Vector3(a["cell"]).distance_to(Vector3(home)) < Vector3(b["cell"]).distance_to(Vector3(home))
	)
	var camp: Dictionary = live[0]
	var size := int(_cfg.get("raid_base", 3)) + int(_cfg.get("raid_growth_per_100_days", 2)) * GameClock.day() / 100
	size = clampi(roundi(size * GameRules.get_mult("raid_size")), 1, int(_cfg.get("raid_max", 24)))
	var n := 0
	for i in size:
		var kind := "orc"
		if i > 0 and i % int(_cfg.get("raid_brute_every", 6)) == 0:
			kind = "orc_brute"
		elif float(i % 10) / 10.0 < float(_cfg.get("raid_archer_ratio", 0.3)):
			kind = "orc_archer"
		var a := _spawn(kind, camp["cell"], camp["id"])
		if a.is_empty():
			continue
		a["raid"] = true
		a["goal"] = home
		a.erase("home")
		n += 1
	raid_count += 1
	camp["discovered"] = true
	EventBus.alert.emit("alerte", "RAID D'ORCS ! %d orcs marchent sur le village (%s)." % [n, direction(camp["cell"])])
	EventBus.sfx.emit("cloche", Vector3(home))
	raid_started.emit(n)
	return n


func direction(cell: Vector3i) -> String:
	var d := Vector2(cell.x - colony.stock.pos.x, cell.z - colony.stock.pos.z)
	if absf(d.x) > absf(d.y):
		return "par l'est" if d.x > 0 else "par l'ouest"
	return "par le sud" if d.y > 0 else "par le nord"


## Chaque tick : les raiders avancent vers le village et cassent ce qui bloque ; camps détruits / découverts.
func tick() -> void:
	var tps := GameClock.ticks_per_second()
	var searches := 1  # une recherche de chemin de raid par tick (performance)
	for a in fauna.animals:
		if not a.get("raid", false) or int(a.get("prey", -1)) != -1:
			continue
		if a["path_i"] < a["path"].size():
			continue
		if a.has("blocked_at"):
			_siege(a, tps)
			continue
		if searches <= 0 or int(a["wait"]) > 0:
			continue
		searches -= 1
		_advance(a)
	if GameClock.tick_index % tps == 0 and not camps.is_empty():
		_check_camps()


## Étape suivante vers la cible (par bonds de raid_step blocs) ; chemin impossible → siège.
func _advance(a: Dictionary) -> void:
	var target: Vector3i = a.get("goal", colony.stock.pos)
	var cell: Vector3i = a["cell"]
	var d := Vector2(target.x - cell.x, target.z - cell.z)
	if d.length() < 3.0:
		if str(a["kind"]).begins_with("bandit"):
			a["wait"] = tps_wait(2)
			return  # bandits : Bandits.tick_second les fait piller puis rentrer
		a["goal"] = colony.stock.pos  # arrivé : il cherche des lutins (Combat) autour du village
		a["wait"] = tps_wait(2)
		return
	var step := minf(d.length(), float(_cfg.get("raid_step", 22)))
	var wp2 := Vector2(cell.x, cell.z) + d.normalized() * step
	var wp := Vector3i(int(wp2.x), 0, int(wp2.y))
	wp.y = world.surface_y(wp.x, wp.z)
	if int(a.get("fails", 0)) > 0:  # détour : on contourne par le côté
		var side := (
			Vector2(-d.y, d.x).normalized() * float(_cfg.get("raid_step", 22)) * (1 if int(a["fails"]) % 2 == 1 else -1)
		)
		wp = Vector3i(
			clampi(wp.x + int(side.x), 1, world.size.x - 2), 0, clampi(wp.z + int(side.y), 1, world.size.z - 2)
		)
		wp.y = world.surface_y(wp.x, wp.z)
	var path := Pathfinder.find(world, cell, wp, int(_cfg.get("raid_path_budget", 450)), true)
	if path.size() > 1:
		a["path"] = path
		a["path_i"] = 1
		a["fails"] = 0
		return
	a["fails"] = int(a.get("fails", 0)) + 1
	a["wait"] = tps_wait(1)
	if int(a["fails"]) > int(_cfg.get("detour_after_fails", 2)) and _built_obstacle(a, target).y >= 0:
		a["blocked_at"] = GameClock.tick_index  # un mur bâti bloque : siège
		a["break"] = 0.0
		a["fails"] = 0


## Bloc construit (pas du terrain naturel) qui gêne dans la direction de la cible, ou (-1,-1,-1).
func _built_obstacle(a: Dictionary, target: Vector3i) -> Vector3i:
	var cell: Vector3i = a["cell"]
	var dx := target.x - cell.x
	var dz := target.z - cell.z
	var dir := Vector3i(signi(dx), 0, 0) if absi(dx) >= absi(dz) else Vector3i(0, 0, signi(dz))
	var natural: Array = _cfg.get("natural_blocks", [])
	for q: Vector3i in [cell + dir + Vector3i.UP, cell + dir, cell + dir + Vector3i.UP * 2]:
		var id := world.get_block(q)
		if world.types.solid[id] == 1 and not natural.has(str(DataRegistry.block(id).get("id", ""))):
			return q
	return Vector3i(-1, -1, -1)


static func tps_wait(s: float) -> int:
	return int(s * GameClock.ticks_per_second())


## Siège : l'orc frappe le bloc qui le gêne dans la direction du village ; un bloc tombe au bout d'un moment.
func _siege(a: Dictionary, tps: int) -> void:
	var target: Vector3i = a.get("goal", colony.stock.pos)
	var p := _built_obstacle(a, target)
	if p.y < 0 or not DataRegistry.block(world.get_block(p)).get("diggable", true):
		a.erase("blocked_at")  # plus rien ne bloque : il repart
		return
	var bid := DataRegistry.block(world.get_block(p))
	var resist := float(_cfg.get("break_resist", {}).get(str(bid.get("id", "")), 1.0))
	var mult := float(fauna.def(a["kind"]).get("break_mult", 1.0))
	if not fauna.def(a["kind"]).get("breaks_blocks", false):
		mult = 0.3  # les archers cassent lentement
	a["break"] = float(a.get("break", 0.0)) + mult / (resist * tps)
	if float(a["break"]) >= float(_cfg.get("break_seconds", 3.0)):
		a["break"] = 0.0
		world.set_block(p, 0)
		EventBus.sfx.emit("pioche", Vector3(p))
		collapse_above(p)
		a.erase("blocked_at")


## Effondrement : les blocs au-dessus d'un trou, sans appui en dessous ni sur les côtés, tombent.
func collapse_above(p: Vector3i) -> int:
	var n := 0
	for k in range(1, int(_cfg.get("collapse_max", 12)) + 1):
		var q := p + Vector3i.UP * k
		if world.types.solid[world.get_block(q)] == 0:
			break
		if world.types.solid[world.get_block(q + Vector3i.DOWN)] == 1:
			break
		var side := false
		for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
			if world.types.solid[world.get_block(q + d)] == 1:
				side = true
		if side:
			break
		world.set_block(q, 0)
		n += 1
	return n


func _check_camps() -> void:
	var r := float(_cfg.get("destroy_camp_radius", 6))
	for c: Dictionary in alive_camps():
		var near := colony.lutins.filter(
			func(l: Lutin) -> bool: return Vector3(l.cell).distance_to(Vector3(c["cell"])) < 24.0
		)
		if not near.is_empty():
			c["discovered"] = true
		if not orcs_of(c["id"]).is_empty():
			continue
		if near.any(
			func(l: Lutin) -> bool:
				return (l.mobilized or l.weapon != "") and Vector3(l.cell).distance_to(Vector3(c["cell"])) <= r
		):
			destroy_camp(c)


## Un camp est découvert quand sa zone a été explorée.
func check_discovery(t: Territory) -> void:
	for c: Dictionary in camps:
		if not c["discovered"] and t.explored.has(t.col_of(c["cell"])):
			c["discovered"] = true
			EventBus.alert.emit("alerte", "Un camp d'orcs a été repéré %s !" % direction(c["cell"]))


func destroy_camp(c: Dictionary) -> void:
	c["destroyed"] = true
	var loot: Dictionary = _cfg.get("camp_loot", {})
	for k: String in loot:
		colony.stock.add(k, int(loot[k]))
	EventBus.alert.emit(
		"victoire",
		(
			"Camp d'orcs détruit ! Butin : %s."
			% ", ".join(
				loot.keys().map(
					func(k: String) -> String: return "%d %s" % [int(loot[k]), Stockpile._resource(k).get("name", k)]
				)
			)
		)
	)
	camp_destroyed.emit(c["id"])


func to_dict() -> Dictionary:
	var out := []
	for c: Dictionary in camps:
		var p: Vector3i = c["cell"]
		out.append({"id": c["id"], "cell": [p.x, p.y, p.z], "destroyed": c["destroyed"], "discovered": c["discovered"]})
	return {"camps": out, "next_raid": next_raid_day, "raids": raid_count}


func from_dict(d: Dictionary) -> void:
	camps.clear()
	for e: Dictionary in d.get("camps", []):
		var p: Array = e["cell"]
		camps.append(
			{
				"id": int(e["id"]),
				"cell": Vector3i(int(p[0]), int(p[1]), int(p[2])),
				"destroyed": bool(e["destroyed"]),
				"discovered": bool(e["discovered"])
			}
		)
	next_raid_day = int(d.get("next_raid", -1))
	raid_count = int(d.get("raids", 0))
	active = self
