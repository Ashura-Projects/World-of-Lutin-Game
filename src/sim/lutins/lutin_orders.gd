class_name LutinOrders
extends RefCounted
## Ordres directs du joueur à un lutin (1.1) : aller ici, couper, cueillir, chasser, creuser, construire, déplacer
## la charrette. Les ordres de travail deviennent des tâches réservées à ce lutin et prioritaires.


## Donne un ordre. Renvoie true si l'ordre est accepté.
static func give(
	colony: Colony, board: TaskBoard, l: Lutin, kind: String, cell: Vector3i, extra: Dictionary = {}
) -> bool:
	if l.jailed.y >= 0 or not l.can_work():
		return false
	match kind:
		"move", "cart":
			board.release(l)
			l.order = {"kind": kind, "cell": cell, "stage": 0, "until": 0, "tries": 0}
			if extra.has("hold_s"):
				l.order["hold_s"] = float(extra["hold_s"])
			l.wait_ticks = 0
			l.state = Lutin.State.IDLE
			return true
	var id := -1
	match kind:
		"cut":
			id = _existing(board, cell, "cut")
			if id < 0:
				id = board.add_cut(cell)
		"gather":
			id = _existing(board, cell, "gather")
			if id < 0:
				id = board.add_gather(cell)
		"dig":
			id = _existing(board, cell, "dig")
			if id < 0:
				id = board.add_dig(cell)
		"build":
			id = _existing(board, cell, "build")
			if id < 0:
				id = board.add_build_block(cell, int(extra.get("block", 0)))
		"hunt":
			id = board.add_hunt(int(extra.get("animal", -1)))
		"task":
			id = int(extra.get("task", -1))
	if id < 0 or not board.tasks.has(id):
		return false
	var t: Dictionary = board.tasks[id]
	if t["reserved"] >= 0 and t["reserved"] != l.id:
		var other := colony.find_lutin(t["reserved"])
		if other != null:
			board.release(other)
	t["assigned"] = [l.id]
	t["order"] = true
	t["blocked"] = 0
	l.order = {}
	if l.task_id != id:
		board.release(l)
		l.wait_ticks = 0
		if l.state != Lutin.State.SLEEP:
			l.state = Lutin.State.IDLE
	board.tasks_changed.emit()
	return true


static func _existing(board: TaskBoard, cell: Vector3i, kind: String) -> int:
	for t: Dictionary in board.tasks.values():
		if t["kind"] == kind and t["cell"] == cell:
			return t["id"]
	return -1


## Appelé par la colonie à chaque décision. Renvoie true si l'ordre occupe le lutin.
static func tick(colony: Colony, l: Lutin) -> bool:
	var o := l.order
	if o.is_empty():
		return false
	if l.state == Lutin.State.WALK and (l.has_path() or l.pending_path):
		return true
	var cell: Vector3i = o["cell"]
	match o["kind"]:
		"move":
			if int(o["stage"]) == 1:
				if GameClock.tick_index >= int(o["until"]):
					l.order = {}
					return false
				l.state = Lutin.State.IDLE
				return true
			if Colony._near(l.cell, cell, 1):
				o["stage"] = 1
				var hold := float(o.get("hold_s", DataRegistry.get_table("realm").get("orders", {}).get("hold_s", 40)))
				o["until"] = GameClock.tick_index + int(hold * GameClock.ticks_per_second())
				l.state = Lutin.State.IDLE
				return true
			return _walk(colony, l, cell)
		"cart":
			if int(o["stage"]) == 0:
				if Colony._near(l.cell, colony.stock.pos, 1):
					o["stage"] = 1
					o["tries"] = 0
				else:
					return _walk(colony, l, colony.stock.pos)
			if Colony._near(l.cell, cell, 1):
				colony.move_cart(cell)
				l.order = {}
				return false
			return _walk(colony, l, cell)
	l.order = {}
	return false


static func _walk(colony: Colony, l: Lutin, cell: Vector3i) -> bool:
	l.order["tries"] = int(l.order["tries"]) + 1
	if int(l.order["tries"]) > 4:
		EventBus.alert.emit("alerte", "%s ne trouve pas de chemin." % l.name)
		l.order = {}
		return false
	colony.send(l, cell, true)
	return true


static func order_to_dict(o: Dictionary) -> Dictionary:
	if o.is_empty():
		return {}
	var c: Vector3i = o["cell"]
	return {"kind": o["kind"], "cell": [c.x, c.y, c.z], "stage": o["stage"], "until": o["until"], "tries": o["tries"]}


static func order_from_dict(d: Dictionary) -> Dictionary:
	if d.is_empty():
		return {}
	var c: Array = d["cell"]
	return {
		"kind": str(d["kind"]),
		"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])),
		"stage": int(d["stage"]),
		"until": int(d["until"]),
		"tries": int(d["tries"])
	}
