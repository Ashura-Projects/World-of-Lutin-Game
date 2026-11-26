class_name Colony
extends RefCounted
## Les lutins du village : apparition, besoins, décisions (manger, dormir, flâner, travailler), déplacements.
## Logique pure (sans nœud) : un appel à tick() = un tick de simulation.

signal lutin_added(l: Lutin)

var world: VoxelWorld
var lutins: Array[Lutin] = []
var stock := Stockpile.new()
var next_id: int = 1
var task_board: RefCounted = null  # TaskBoard (J4) : fournit des tâches aux lutins libres
var _pop: Dictionary
var _move: Dictionary
var _needs: Dictionary
var _path_budget: int = 0
var _goals: Dictionary = {}  # id lutin -> [case visée, raison]


func _init(w: VoxelWorld) -> void:
	world = w
	_pop = DataRegistry.get_table("population")
	_move = _pop.get("movement", {})
	_needs = _pop.get("needs", {})


## Nouvelle partie : n lutins adultes autour du chariot, chariot rempli selon data/start.json.
func spawn_start(center: Vector3i, n: int) -> void:
	stock.pos = Pathfinder.snap(world, center)
	var cart: Dictionary = DataRegistry.get_table("start").get("cart", {})
	for k: String in cart.get("fixed", {}):
		stock.add(k, int(cart["fixed"][k]))
	for k: String in cart.get("per_lutin", {}):
		stock.add(k, int(cart["per_lutin"][k]) * n)
	var names: Array = DataRegistry.get_table("names").get("names", ["Lutin"])
	var ages: Array = _pop.get("ages", [])
	var adult_from := 60
	for a: Dictionary in ages:
		if a["id"] == "adult":
			adult_from = int(a["from_day"])
	for i in n:
		var l := Lutin.new()
		l.id = next_id
		next_id += 1
		l.name = names[Rng.randi_range(0, names.size() - 1)]
		l.sex = "f" if i % 2 == 0 else "m"
		l.age_days = adult_from + Rng.randi_range(0, 120)
		l.hp = float(_pop.get("combat", {}).get("hp", 50))
		for apt: String in l.aptitudes:
			l.aptitudes[apt] = Rng.randi_range(10, 40)
		l.set_job("hauler")
		var spot := Pathfinder.snap(world, stock.pos + Vector3i(i % 3 - 1, 0, i / 3 - 1))
		l.place_at(spot if spot.y >= 0 else stock.pos)
		lutins.append(l)
		lutin_added.emit(l)


func tick() -> void:
	_path_budget = int(_move.get("paths_per_tick", 3))
	var tpd := float(GameClock.ticks_per_day())
	var night := GameClock.is_night()
	for l in lutins:
		_update_needs(l, tpd)
		_decide(l, night)
		_act(l)


func _update_needs(l: Lutin, tpd: float) -> void:
	l.needs["hunger"] = maxf(0.0, l.needs["hunger"] - float(_needs["hunger"]["loss_per_day"]) / tpd)
	if l.state == Lutin.State.SLEEP:
		l.needs["sleep"] = minf(100.0, l.needs["sleep"] + float(_needs["sleep"]["recover_per_day"]) / tpd)
	else:
		l.needs["sleep"] = maxf(0.0, l.needs["sleep"] - float(_needs["sleep"]["loss_per_day"]) / tpd)


func _decide(l: Lutin, night: bool) -> void:
	if l.state == Lutin.State.WORK:
		var urgent: bool = l.needs["hunger"] < float(_needs["hunger"]["critical"]) * 2.0 or l.needs["sleep"] < 15.0
		if not urgent:
			return
		if task_board != null:
			task_board.call("release", l)
	if l.state == Lutin.State.SLEEP:
		if l.needs["sleep"] >= float(_needs["sleep"]["wake_above"]) and not night:
			l.state = Lutin.State.IDLE
		return
	if l.state == Lutin.State.EAT or l.wait_ticks > 0:
		return
	if l.state == Lutin.State.WALK and l.has_path():
		return
	if l.needs["hunger"] < float(_needs["hunger"]["eat_below"]) and stock.food_total() > 0:
		if _near(l.cell, stock.pos, 2):
			l.needs["hunger"] = minf(100.0, l.needs["hunger"] + stock.take_best_food())
			l.state = Lutin.State.EAT
			l.wait_ticks = int(float(_needs.get("eat_duration_s", 3)) * GameClock.ticks_per_second())
		else:
			_go(l, stock.pos, "manger")
		return
	if l.needs["sleep"] < float(_needs["sleep"]["go_to_bed_below"]) or (night and l.needs["sleep"] < 90.0):
		if l.home.y >= 0 and not _near(l.cell, l.home, 1):
			_go(l, l.home, "dormir", true)
		else:
			l.state = Lutin.State.SLEEP
		return
	if task_board != null and task_board.call("assign", l):
		return
	# flâner autour du camp
	l.state = Lutin.State.IDLE
	var r := int(_move.get("wander_radius", 10))
	var target := Pathfinder.snap(world, stock.pos + Vector3i(Rng.randi_range(-r, r), 0, Rng.randi_range(-r, r)))
	if target.y >= 0:
		_go(l, target, "flâner")
	var w: Array = _move.get("idle_wait_s", [2, 6])
	l.wait_ticks = Rng.randi_range(int(w[0]), int(w[1])) * GameClock.ticks_per_second()


func _act(l: Lutin) -> void:
	if l.wait_ticks > 0:
		l.wait_ticks -= 1
		if l.wait_ticks == 0 and l.state == Lutin.State.EAT:
			l.state = Lutin.State.IDLE
	if l.state == Lutin.State.WORK and task_board != null:
		task_board.call("work", l)
	if l.state == Lutin.State.WALK:
		if task_board != null and l.task_id >= 0:
			task_board.call("while_walking", l)
		var under := DataRegistry.block(world.get_block(l.cell + Vector3i.DOWN))
		var speed := float(_move.get("walk_speed", 2.2)) * float(under.get("speed_mult", 1.0))
		if l.state == Lutin.State.WALK and l.walk(speed / GameClock.ticks_per_second()):
			l.state = Lutin.State.IDLE
			if task_board != null:
				task_board.call("arrived", l)


## Demande un chemin (budget limité par tick). Renvoie false si le chemin est impossible.
func _go(l: Lutin, target: Vector3i, _why: String, near: bool = false, reach_up: int = 1) -> bool:
	if _path_budget <= 0:
		return true  # on réessaiera au prochain tick
	_path_budget -= 1
	var p := Pathfinder.find(world, l.cell, target, int(_move.get("path_max_nodes", 20000)), near, reach_up)
	if p.is_empty():
		return false
	l.set_path(p)
	return true


## Pour les tâches (J4) : envoyer un lutin vers une case ; near = s'arrêter à côté.
func send(l: Lutin, target: Vector3i, near: bool = false, reach_up: int = 1) -> bool:
	return _go(l, target, "tâche", near, reach_up)


static func _near(a: Vector3i, b: Vector3i, r: int) -> bool:
	var d := (a - b).abs()
	return d.x <= r and d.z <= r and d.y <= 1


## Changer de métier : l'outil du nouveau métier est pris dans la réserve, l'ancien y retourne.
## Renvoie false s'il n'y a pas l'outil en réserve.
func change_job(l: Lutin, job: String) -> bool:
	if job == l.job:
		return true
	var new_tool = DataRegistry.find("jobs", "jobs", job).get("tool")
	if new_tool != null and stock.count(str(new_tool)) <= 0:
		return false
	var old_tool = DataRegistry.find("jobs", "jobs", l.job).get("tool")
	if old_tool != null:
		stock.add(str(old_tool), 1)
	if new_tool != null:
		stock.take(str(new_tool), 1)
	if task_board != null:
		task_board.call("release", l)
	l.set_job(job)
	return true


## Mode auto du départ : les outils du chariot vont aux premiers lutins (data/start.json › auto_jobs).
func auto_assign_jobs() -> void:
	var order: Array = DataRegistry.get_table("start").get("auto_jobs", [])
	var i := 0
	for job: String in order:
		if i >= lutins.size():
			break
		if change_job(lutins[i], job):
			i += 1


func find_lutin(id: int) -> Lutin:
	for l in lutins:
		if l.id == id:
			return l
	return null


func to_dict() -> Dictionary:
	var ls := []
	for l in lutins:
		ls.append(l.to_dict())
	return {"lutins": ls, "stock": stock.to_dict(), "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	lutins.clear()
	for ld: Dictionary in d.get("lutins", []):
		var l := Lutin.new()
		l.from_dict(ld)
		lutins.append(l)
		lutin_added.emit(l)
	stock.from_dict(d.get("stock", {}))
	next_id = int(d.get("next_id", lutins.size() + 1))
