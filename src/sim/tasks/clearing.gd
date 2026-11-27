class_name Clearing
extends RefCounted
## Dégager le terrain : enlever (déraciner) arbres, buissons et plantes sauvages.
## Un arbre enlevé = coupé (bûches) ; un buisson ou une plante = déraciné par un cueilleur.
## Débug « Enlever instantané » : la végétation disparaît tout de suite, sans rien donner.


## Ordre d'enlever ce qui pousse en `cell` (arbre, buisson ou plante). Renvoie l'id de tâche, 0 si instantané.
static func uproot(board: TaskBoard, cell: Vector3i) -> int:
	var f := board.flora
	if not (f.trees.has(cell) or f.bushes.has(cell) or f.herbs.has(cell)):
		return -1
	if GameRules.active != null and GameRules.active.free_clear:
		clear_now(f, cell)
		return 0
	if f.trees.has(cell):
		return board.add_cut(cell)
	var cfg: Dictionary = DataRegistry.get_table("flora").get("uproot", {})
	var what := "bush" if f.bushes.has(cell) else "herb"
	return board._new_task("uproot", cell, "gatherer", float(cfg.get("work", 4)), {"what": what})


## Enlève tout de suite (débug, terraformation).
static func clear_now(f: Flora, cell: Vector3i) -> void:
	if f.trees.has(cell):
		f.remove_tree(cell)
	if f.bushes.has(cell):
		f.remove_bush(cell)
	if f.herbs.has(cell):
		f.remove_herb(cell)


## Cercle « Enlever » du menu Récolter : arbres, buissons (même sans baies) et plantes.
static func order_circle(board: TaskBoard, center: Vector3i, radius: int) -> int:
	var n := 0
	var cells: Array[Vector3i] = []
	cells.append_array(board.flora.in_circle("tree", center, radius, 0))
	cells.append_array(board.flora.in_circle("bush_any", center, radius, 0))
	cells.append_array(board.flora.in_circle("herb", center, radius, 0))
	for p in cells:
		n += int(uproot(board, p) >= 0)
	return n


## Fin du travail d'un cueilleur : le buisson ou la plante disparaît ; on récupère ce qu'il portait.
static func complete(board: TaskBoard, l: Lutin, t: Dictionary) -> void:
	var cell: Vector3i = t["cell"]
	var f := board.flora
	var cfg: Dictionary = DataRegistry.get_table("flora").get("uproot", {})
	if f.bushes.has(cell):
		var drop: Dictionary = cfg.get("bush_drop", {}).duplicate()
		if f.bush_ready(cell, GameClock.day()):
			for k: String in DataRegistry.get_table("flora")["bush"].get("drop", {}):
				drop[k] = int(drop.get(k, 0)) + int(DataRegistry.get_table("flora")["bush"]["drop"][k])
		f.remove_bush(cell)
		if not drop.is_empty():
			board.ground.drop(l.cell, drop)
	elif f.herbs.has(cell):
		var kind := f.remove_herb(cell)
		for w: Dictionary in DataRegistry.get_table("crops").get("wild", []):
			if w["id"] == kind:
				board.ground.drop(l.cell, w.get("gather", {}))
