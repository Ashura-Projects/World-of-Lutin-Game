class_name WindowMaker
extends RefCounted


## Fenêtre percée dans un mur construit : le bloc devient un cadre (matériau choisi) avec ouverture, vitre ou vitrail.
## Coût : le matériau du cadre (et 1 verre pour une vitre ou un vitrail). Pas dans le terrain naturel.
static func make(board: TaskBoard, p: Vector3i, block_id: int, shape: int) -> bool:
	var world := board.world
	var colony := board.colony
	var cur := DataRegistry.block(world.get_block(p))
	if not cur.has("cost") or not DataRegistry.block(block_id).has("cost"):
		return false
	var cost: Dictionary = DataRegistry.block(block_id).get("cost", {}).duplicate()
	if shape / 4 != 10:
		cost["glass"] = int(cost.get("glass", 0)) + 1
	for k: String in cost:
		if colony.stock.count(k) < int(cost[k]):
			EventBus.alert.emit("alerte", "Fenêtre : il manque %s." % Stockpile._resource(k).get("name", k))
			return false
	for k: String in cost:
		colony.stock.take(k, int(cost[k]))
	world.set_block(p, block_id)
	world.set_shape(p, shape)
	return true
