class_name Terraform
extends RefCounted
## Terraformation (1.3.2) : verser de l'eau (seau d'eau), remettre de la terre, de l'herbe, de la pierre, du sable,
## planter un arbre ou un buisson. Le coût est pris à la réserve tout de suite, puis un lutin fait le travail.
## Débug « Terraformation gratuite et instantanée » : tout apparaît sans rien coûter.


static func tools() -> Array:
	return DataRegistry.get_table("world").get("terraform", {}).get("tools", [])


static func tool_def(id: String) -> Dictionary:
	for t: Dictionary in tools():
		if t["id"] == id:
			return t
	return {}


## Cases visées : le cercle (rayon r) posé au-dessus du sol touché ; l'eau et les blocs vont dans les creux.
static func cells_in_circle(world: VoxelWorld, center: Vector3i, r: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			if Vector2(dx, dz).length() > r + 0.5:
				continue
			var x := center.x + dx
			var z := center.z + dz
			var c := Vector3i(x, center.y, z)
			if world.in_bounds(c) and world.get_block(c) == 0:
				out.append(c)
	return out


## Ordonne la terraformation des cases. Renvoie [nombre d'ordres, message].
static func order(sim: GameSim, id: String, cells: Array) -> Array:
	var t := tool_def(id)
	if t.is_empty():
		return [0, ""]
	var free: bool = sim.rules.free_terra
	var stock := sim.colony.stock
	var n := 0
	var missing := false
	for c: Vector3i in cells:
		if not _can(sim, t, c):
			continue
		if not free:
			var cost: Dictionary = t.get("cost", {})
			if cost.keys().any(func(k: String) -> bool: return stock.count(k) < int(cost[k])):
				missing = true
				break
			for k: String in cost:
				stock.take(k, int(cost[k]))
			n += int(
				(
					sim.board._new_task("terra", c, str(t.get("job", "builder")), float(t.get("work", 2)), {"tool": id})
					>= 0
				)
			)
		else:
			apply(sim.board, id, c)
			n += 1
	var msg := "%d case(s) %s." % [n, "terraformée(s)" if free else "à terraformer"]
	if missing:
		msg += " Il manque des ressources (%s)." % _cost_text(t)
	return [n, msg]


static func _can(sim: GameSim, t: Dictionary, c: Vector3i) -> bool:
	var w := sim.world
	if w.get_block(c) != 0 or not sim.structures.at(c).is_empty():
		return false
	if t.has("plant"):
		return w.is_solid(c + Vector3i.DOWN) and not sim.flora.trees.has(c) and not sim.flora.bushes.has(c)
	return true


## Effet final (tâche finie, ou tout de suite en débug).
static func apply(board: TaskBoard, id: String, c: Vector3i) -> void:
	var t := tool_def(id)
	if board.world.get_block(c) != 0:
		return
	if t.has("block"):
		board.world.set_block(c, board.world.types.num(str(t["block"])))
	elif t.get("plant", "") == "tree":
		var kinds: Array = DataRegistry.get_table("flora").get("trees", {}).keys()
		board.flora.add_tree(c, str(kinds[Rng.randi_range(0, kinds.size() - 1)]))
	elif t.get("plant", "") == "bush":
		board.flora.add_bush(c)
	var back: Dictionary = t.get("returns", {})
	if GameRules.active == null or not GameRules.active.free_terra:
		for k: String in back:
			board.colony.stock.add(k, int(back[k]))  # le seau vide revient à la réserve


## Ordre annulé : le coût revient à la réserve.
static func refund(board: TaskBoard, task: Dictionary) -> void:
	var cost: Dictionary = tool_def(str(task.get("tool", ""))).get("cost", {})
	for k: String in cost:
		board.colony.stock.add(k, int(cost[k]))


static func _cost_text(t: Dictionary) -> String:
	var parts := []
	var cost: Dictionary = t.get("cost", {})
	for k: String in cost:
		parts.append("%d %s" % [int(cost[k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
	return ", ".join(parts)
