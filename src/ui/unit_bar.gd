class_name UnitBar
extends Node
## Commander une unité (1.3.2) : une bulle au nom de l'unité et une barre verticale de petits boutons à symboles,
## tous de la même taille. Action en cours : ⬇ aller, ⚔ attaquer — chaque toucher sur la carte donne l'ordre
## (plusieurs ordres d'affilée). ✋ tenir, ⌂ rentrer, ◎ explorer. Formations : ▪▪ ligne, ▪▪/▪▪ double ligne,
## ▪/▪ colonne, carré de 4 = carré, ▴ coin. ✕ arrête de commander.
## 1.4 : « T / C / 1 / 2… » choisit qui reçoit les ordres (toute l'unité, le commandant et les siens, ou une
## sous-unité de lieutenant) ; ☾ repos (camp de tentes, repas du cuisinier) ; ✦ entraînement ; ⚙ gérer l'unité.

const SIZE := Vector2(54, 50)
const FORMATIONS := [
	["line", "■■", 17, "Ligne"],
	["double_line", "■■■\n■■■", 9, "Double ligne"],
	["column", "■\n■", 13, "Colonne"],
	["square", "■■\n■■", 13, "Carré"],
	["wedge", "▲", 22, "Coin"]
]

var hud: Hud
var game: Node
var unit_id: int = -1
var action: String = "move"
var squad: int = -1  # -1 = toute l'unité, 0 = commandant, 1… = sous-unité du lieutenant
var _bubble: Button
var _bar: PanelContainer
var _grid: GridContainer
var _btns: Dictionary = {}


func setup(h: Hud, g: Node) -> void:
	hud = h
	game = g
	_bubble = Button.new()
	_bubble.position = Vector2(12, 136)
	_bubble.custom_minimum_size = Vector2(0, 50)
	_bubble.add_theme_font_size_override("font_size", 18)
	_bubble.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD, 2, 26))
	_bubble.pressed.connect(func() -> void: _bar.visible = not _bar.visible)
	_bubble.visible = false
	h.root.add_child(_bubble)
	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.85), UiStyle.GOLD_D, 2, 10))
	_bar.position = Vector2(12, 192)
	_bar.visible = false
	h.root.add_child(_bar)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	_bar.add_child(_grid)
	_add("move", "⬇", 24, "Aller (touchez la carte)", func() -> void: _set_action("move"))
	_add("attack", "⚔", 24, "Attaquer (touchez la carte)", func() -> void: _set_action("attack"))
	_add("hold", "✋", 22, "Tenir la position", func() -> void: _now("hold"))
	_add("return", "⌂", 24, "Rentrer (vie normale)", func() -> void: _now("return"))
	_add("explore", "◎", 22, "Explorer", func() -> void: _now("explore"))
	_add("focus", "⌖", 24, "Voir l'unité", _focus)
	for f: Array in FORMATIONS:
		_add("f_" + str(f[0]), f[1], int(f[2]), str(f[3]), _formation.bind(str(f[0])))
	_add("squad", "T", 22, "Qui reçoit les ordres : Tous, Commandant, sous-unité 1, 2…", _cycle_squad)
	_add("rest", "☾", 24, "Repos : camp de tentes, le cuisinier fait à manger", func() -> void: _now("rest"))
	_add("train", "✦", 22, "Entraînement (sol d'entraînement)", func() -> void: _now("train"))
	_add("manage", "⚙", 22, "Gérer l'unité (armes, chevaux, rôles…)", func() -> void: hud.unit_editor.open(unit_id))
	_add("close", "✕", 22, "Arrêter de commander", close)


func _add(id: String, sym: String, font: int, tip: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = sym
	b.tooltip_text = tip
	b.custom_minimum_size = SIZE
	b.add_theme_font_size_override("font_size", font)
	b.add_theme_constant_override("line_spacing", -6)
	b.pressed.connect(cb)
	_grid.add_child(b)
	_btns[id] = b


func active() -> bool:
	return unit_id >= 0 and game.sim.units.units.has(unit_id)


func open(id: int) -> void:
	if not game.sim.units.units.has(id):
		return
	unit_id = id
	action = "move"
	squad = -1
	_bubble.visible = true
	_bar.visible = true
	_refresh()


func close() -> void:
	unit_id = -1
	_bubble.visible = false
	_bar.visible = false


func _refresh() -> void:
	if not active():
		close()
		return
	var u: Dictionary = game.sim.units.units[unit_id]
	var who := "tous" if squad < 0 else ("commandant" if squad == 0 else "sous-unité %d" % squad)
	_bubble.text = "  ⚑ %s · %d · %s  " % [u["name"], u["members"].size(), who]
	_btns["squad"].text = "T" if squad < 0 else ("C" if squad == 0 else str(squad))
	for k: String in _btns:
		var on: bool = k == action or k == "f_" + str(u["formation"])
		_btns[k].add_theme_stylebox_override(
			"normal",
			UiStyle.box(
				UiStyle.BLOOD if on else Color(0.12, 0.1, 0.1, 0.9), UiStyle.GOLD if on else UiStyle.GOLD_D, 2, 8
			)
		)


func _set_action(a: String) -> void:
	action = a
	_refresh()
	EventBus.alert.emit("info", "Touchez la carte : %s." % ("l'unité y va" if a == "move" else "l'unité attaque là"))


func _cycle_squad() -> void:
	if not active():
		return
	var n := UnitSetup.max_squads(game.sim.units, game.sim.units.units[unit_id])
	squad = squad + 1 if squad + 1 < n else -1
	_refresh()


func _now(kind: String) -> void:
	if active():
		game.sim.units.command(unit_id, kind, Vector3i(-1, -1, -1), squad if kind not in ["rest", "train"] else -1)
		if kind == "return":
			close()
			return
	_refresh()


func _formation(f: String) -> void:
	if active():
		game.sim.units.set_formation(unit_id, f)
	_refresh()


func _focus() -> void:
	if not active():
		return
	var cap := game.colony.find_lutin(int(game.sim.units.units[unit_id]["captain"])) as Lutin
	if cap != null:
		game.camera.focus(cap.pos)


## Toucher la carte pendant qu'on commande : l'ordre en cours (aller / attaquer) vers ce point. true si utilisé.
func on_tap(screen: Vector2) -> bool:
	if not active():
		return false
	var cell: Vector3i = hud.windows.ground_cell(screen)
	if cell.y < 0:
		return true
	game.sim.units.command(unit_id, action, cell, squad)
	game.click_marker.show_at(Vector3(cell) + Vector3(0.5, 0, 0.5), "e04030" if action == "attack" else "f0d060")
	_refresh()
	return true
