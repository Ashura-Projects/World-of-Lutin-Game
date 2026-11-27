class_name Scouting
extends RefCounted
## Exploration autonome (ordre « Explorer ») : l'éclaireur file vers la zone inconnue la plus proche,
## par bonds ; la nuit il monte un petit camp et dort, il repart au matin. « Retour » = ordre Aller à la base.


static func _cfg() -> Dictionary:
	return DataRegistry.get_table("realm").get("scouting", {})


## Appelé à chaque décision. Renvoie true tant que l'éclaireur est occupé.
static func tick(colony: Colony, l: Lutin) -> bool:
	var o := l.order
	var cfg := _cfg()
	var t: Territory = Territory.active
	if t == null:
		l.order = {}
		return false
	# provisions : il mange en route (prélevées sur la réserve)
	if l.needs["hunger"] < float(cfg.get("food_below", 35)) and colony.stock.food_total() > 0:
		l.needs["hunger"] = minf(100.0, l.needs["hunger"] + colony.stock.take_best_food())
	if GameClock.is_night() and bool(cfg.get("camp_at_night", true)):
		if l.state == Lutin.State.WALK and (l.has_path() or l.pending_path):
			l.path = []
			l.path_i = 0
		o["camp"] = l.cell
		l.state = Lutin.State.SLEEP  # nuit au camp
		return true
	if o.has("camp"):
		o.erase("camp")  # le matin : on replie le camp
		l.state = Lutin.State.IDLE
	if l.state == Lutin.State.WALK and (l.has_path() or l.pending_path):
		return true
	var goal: Vector3i = o.get("goal", Vector3i(-1, -1, -1))
	if goal.y < 0 or t.explored.has(t.col_of(goal)) or int(o["tries"]) > 4:
		goal = next_goal(colony.world, t, l.cell, int(cfg.get("search_cols", 40)))
		o["tries"] = 0
		if goal.y < 0:
			EventBus.alert.emit("info", "%s a exploré toute la région et rentre." % l.name)
			LutinOrders.give(colony, colony.task_board, l, "move", colony.stock.pos)
			return true
		o["goal"] = goal
	var d := Vector2(goal.x - l.cell.x, goal.z - l.cell.z)
	var step := minf(d.length(), float(cfg.get("step", 24)))
	var wp2 := Vector2(l.cell.x, l.cell.z) + d.normalized() * step
	var wp := Pathfinder.snap(
		colony.world, Vector3i(int(wp2.x), colony.world.surface_y(int(wp2.x), int(wp2.y)), int(wp2.y))
	)
	if wp.y < 0:
		o["tries"] = int(o["tries"]) + 1
		return true
	o["tries"] = int(o["tries"]) + 1 if wp == l.cell else 0
	colony.send(l, wp, true)
	return true


## Centre de la colonne inexplorée la plus proche (recherche en anneaux), ou (-1,-1,-1).
static func next_goal(world: VoxelWorld, t: Territory, from: Vector3i, max_r: int) -> Vector3i:
	var c0 := t.col_of(from)
	for r in range(1, max_r + 1):
		var best := Vector2i(-1, -1)
		for dx in range(-r, r + 1):
			for dz in [-r, r]:
				for c: Vector2i in [c0 + Vector2i(dx, dz), c0 + Vector2i(dz, dx)]:
					if t.in_map(c) and not t.explored.has(c) and best.x < 0:
						best = c
		if best.x >= 0:
			var x := best.x * t.size + t.size / 2
			var z := best.y * t.size + t.size / 2
			var y := world.surface_y(x, z)
			if y > 0:
				return Vector3i(x, y, z)
	return Vector3i(-1, -1, -1)
