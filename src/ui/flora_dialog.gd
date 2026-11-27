class_name FloraDialog
extends RefCounted
## Fiche d'un arbre, d'un buisson ou d'une plante touché : ce qu'il donne, et les ordres
## Couper / Cueillir / Enlever (déraciner), ou annuler l'ordre en cours.


## Arbre, buisson ou plante le plus proche du doigt à l'écran (rayon 50 px). {} si rien.
static func pick(game: Node, screen: Vector2) -> Dictionary:
	var cam: Camera3D = game.camera.cam
	var f: Flora = game.flora
	var near := Vector3(game.camera.target)
	var best := {}
	var bd := 50.0
	for e: Array in [[f.trees, "tree", 1.6], [f.bushes, "bush", 0.45], [f.herbs, "herb", 0.25]]:
		for p: Vector3i in e[0]:
			var w := Vector3(p) + Vector3(0.5, float(e[2]), 0.5)
			if w.distance_to(near) > 60.0 or cam.is_position_behind(w):
				continue
			var d := cam.unproject_position(w).distance_to(screen)
			if d < bd:
				bd = d
				best = {"what": e[1], "cell": p}
	return best


static func fill(dlg: ObjectDialog, what: String, cell: Vector3i) -> void:
	var game: Node = dlg.game
	var f: Flora = game.flora
	var cfg := DataRegistry.get_table("flora")
	var board: TaskBoard = game.board
	var gives := {}
	match what:
		"tree":
			var k: String = f.trees.get(cell, "")
			dlg._title.text = str(cfg["trees"].get(k, {}).get("name", "Arbre"))
			gives = cfg["trees"].get(k, {}).get("drop", {})
		"bush":
			dlg._title.text = str(cfg["bush"].get("name", "Buisson"))
			if f.bush_ready(cell, GameClock.day()):
				gives = cfg["bush"].get("drop", {})
			else:
				dlg._label("Pas de baies pour l'instant : elles repoussent.", 18, UiStyle.TXT_D)
		"herb":
			var k: String = f.herbs.get(cell, "")
			for w: Dictionary in DataRegistry.get_table("crops").get("wild", []):
				if w["id"] == k:
					dlg._title.text = str(w.get("name", k))
					gives = w.get("gather", {})
	if not gives.is_empty():
		var parts := []
		for k: String in gives:
			parts.append("%d %s" % [int(gives[k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
		dlg._label("Ressources : " + ", ".join(parts), 20, UiStyle.GOLD)
	var busy: int = board._by_cell.get(cell, -1)
	if busy >= 0 and board.tasks.has(busy):
		var names := {"cut": "couper", "gather": "cueillir", "uproot": "enlever"}
		dlg._label("Ordre en cours : %s" % names.get(board.tasks[busy]["kind"], "?"), 19, UiStyle.TXT_D)
	var row := dlg._row()
	if what == "tree":
		dlg._button(row, "🪓 Couper", func() -> void: _order(dlg, board.add_cut(cell)), 180)
	elif what == "herb" or f.bush_ready(cell, GameClock.day()):
		dlg._button(row, "🧺 Cueillir", func() -> void: _order(dlg, board.add_gather(cell)), 180)
	dlg._button(row, "Enlever", func() -> void: _order(dlg, Clearing.uproot(board, cell)), 160)
	if busy >= 0:
		dlg._button(
			row,
			"✕ Annuler l'ordre",
			func() -> void:
				board.cancel(busy)
				dlg._say(""),
			210
		)
	dlg._label(
		"« Enlever » dégage le terrain (déraciner). En débug, l'option instantanée l'efface tout de suite.",
		16,
		UiStyle.TXT_D
	)


static func _order(dlg: ObjectDialog, id: int) -> void:
	if id == 0:
		dlg.visible = false  # enlevé tout de suite (débug)
		return
	dlg._say("Ordre donné." if id > 0 else "Déjà ordonné ou impossible.")
