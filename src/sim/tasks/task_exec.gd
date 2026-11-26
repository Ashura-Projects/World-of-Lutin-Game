class_name TaskExec
extends RefCounted
## Exécution des tâches : aller sur place, travailler (temps × niveau du métier), effets (bûches, blocs creusés,
## baies, poissons, gibier), transport des objets au sol vers la réserve.

var board: TaskBoard
var _work: Dictionary


func _init(b: TaskBoard) -> void:
	board = b
	_work = DataRegistry.get_table("jobs").get("work", {})


func _task(l: Lutin) -> Dictionary:
	return board.tasks.get(l.task_id, {})


func start(l: Lutin, t: Dictionary) -> bool:
	var target: Vector3i = t["cell"]
	if t["kind"] == "hunt":
		var a := board.fauna.find(t["target"])
		if a.is_empty():
			board.finish(t)
			return false
		target = a["cell"]
	if not board.colony.send(l, target, true):
		t["blocked"] = GameClock.tick_index + 30 * GameClock.ticks_per_second()  # inaccessible : quarantaine
		return false
	t["reserved"] = l.id
	l.task_id = t["id"]
	if not l.has_path():
		arrived(l)
	return true


func start_haul(l: Lutin) -> bool:
	var best := Vector3i(-1, -1, -1)
	var best_d := INF
	for c: Vector3i in board.ground.piles:
		if board.is_pile_reserved(c):
			continue
		var d := Vector3(c).distance_squared_to(Vector3(l.cell))
		if d < best_d:
			best_d = d
			best = c
	if best.y < 0 or not board.reserve_pile(best, l):
		return false
	if not board.colony.send(l, best, true):
		board.free_pile(best)
		return false
	l.carrying = {"pickup": [best.x, best.y, best.z]}
	if not l.has_path():
		arrived(l)
	return true


func start_delivery(l: Lutin) -> bool:
	if l.carrying.has("pickup"):
		l.carrying = {}
		return false
	return board.colony.send(l, board.colony.stock.pos, true)


func arrived(l: Lutin) -> void:
	if l.carrying.has("pickup"):
		var c: Array = l.carrying["pickup"]
		var cell := Vector3i(int(c[0]), int(c[1]), int(c[2]))
		board.free_pile(cell)
		var got := board.ground.pick(cell, int(_work.get("carry_capacity", 4)))
		l.carrying = got
		if not got.is_empty():
			board.colony.send(l, board.colony.stock.pos, true)
		return
	if not l.carrying.is_empty():
		if Colony._near(l.cell, board.colony.stock.pos, 2):
			board.colony.stock.add(l.carrying["id"], int(l.carrying["n"]))
			l.carrying = {}
		return
	var t := _task(l)
	if t.is_empty():
		return
	l.state = Lutin.State.WORK


func while_walking(l: Lutin) -> void:
	var t := _task(l)
	if t.is_empty() or t["kind"] != "hunt":
		return
	var a := board.fauna.find(t["target"])
	if a.is_empty():
		board.finish(t)
		l.task_id = -1
		l.path = []
		return
	var w := DataRegistry.find("equipment", "weapons", "flintlock")
	if l.pos.distance_to(a["pos"]) <= float(w.get("range", 12)) * 0.8:
		l.path = []
		l.path_i = 0
		l.state = Lutin.State.WORK


func work(l: Lutin) -> void:
	var t := _task(l)
	if t.is_empty():
		l.state = Lutin.State.IDLE
		l.task_id = -1
		return
	var tps := float(GameClock.ticks_per_second())
	var speed := 1.0 + float(_work.get("speed_per_level", 0.1)) * (l.job_level(t["job"]) - 1)
	l.add_xp(float(_work.get("xp_per_second", 1.0)) / tps, float(_work.get("xp_per_level", 100)))
	if t["kind"] == "hunt":
		_hunt(l, t, tps)
		return
	t["progress"] = float(t["progress"]) + speed / tps
	if float(t["progress"]) < float(t["work"]):
		return
	_complete(l, t)


func _complete(l: Lutin, t: Dictionary) -> void:
	var cell: Vector3i = t["cell"]
	match t["kind"]:
		"cut":
			var kind := board.flora.remove_tree(cell)
			board.ground.drop(cell, DataRegistry.get_table("flora")["trees"].get(kind, {}).get("drop", {"log": 3}))
		"dig":
			var b := DataRegistry.block(board.world.get_block(cell))
			board.world.set_block(cell, 0)
			var drop: Dictionary = b.get("drop", b.get("cost", {}))
			if not drop.is_empty():
				board.ground.drop(l.cell, drop)
		"gather":
			var f := DataRegistry.get_table("flora")
			if t.get("what") == "bush":
				board.flora.harvest_bush(cell, GameClock.day())
				board.ground.drop(l.cell, f["bush"].get("drop", {"berries": 3}))
			else:
				var kind := board.flora.remove_herb(cell)
				for w: Dictionary in DataRegistry.get_table("crops").get("wild", []):
					if w["id"] == kind:
						board.ground.drop(l.cell, w.get("gather", {}))
		"fish":
			board.ground.drop(l.cell, DataRegistry.get_table("flora").get("fishing", {}).get("drop", {"fish": 1}))
			t["progress"] = 0.0
			return  # tâche répétée : le pêcheur reste à son poste
	l.task_id = -1
	l.state = Lutin.State.IDLE
	board.finish(t)


func _hunt(l: Lutin, t: Dictionary, tps: float) -> void:
	var a := board.fauna.find(t["target"])
	if a.is_empty():
		board.finish(t)
		l.task_id = -1
		l.state = Lutin.State.IDLE
		return
	var w := DataRegistry.find("equipment", "weapons", "flintlock")
	if l.pos.distance_to(a["pos"]) > float(w.get("range", 12)):
		t["reserved"] = -1
		l.task_id = -1
		l.state = Lutin.State.IDLE  # trop loin : il reprendra la poursuite
		return
	t["progress"] = float(t["progress"]) + 1.0 / tps
	if float(t["progress"]) >= float(w.get("reload_s", 6)) * 0.5:
		t["progress"] = 0.0
		t["shots"] = int(t.get("shots", 0)) + 1
		var cell: Vector3i = a["cell"]
		var drop: Dictionary = board.fauna.def(a["kind"]).get("drop", {})
		if board.fauna.damage(a["id"], float(w.get("attack", 18))):
			board.ground.drop(cell, drop)
			board.finish(t)
			l.task_id = -1
			l.state = Lutin.State.IDLE
