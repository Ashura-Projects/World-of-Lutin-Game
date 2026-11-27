class_name OrderBar
extends Node
## Ordres à un lutin choisi (1.1). Tant que la barre est ouverte, chaque toucher sur la carte donne un ordre :
## Auto = arbre → couper, plante → cueillir, animal → chasser, sol → aller ici ;
## Construire = poser un bloc (matériau choisi dans Construire) ; Creuser = creuser le bloc touché ;
## Charrette = la déplacer ici. La croix ✕ quitte le mode ordres.

const MODES := [["auto", "Auto"], ["build", "Construire"], ["dig", "Creuser"], ["cart", "Charrette"]]

var hud: Hud
var game: Node
var lutin: Lutin
var mode: String = "auto"
var _bar: PanelContainer
var _name: Label
var _hint: Label
var _btns: Dictionary = {}


func setup(h: Hud, g: Node) -> void:
	hud = h
	game = g
	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 24))
	_bar.position = Vector2(300, 70)
	_bar.visible = false
	h.root.add_child(_bar)
	var v := VBoxContainer.new()
	_bar.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	_name = UiStyle.title_label("", 22)
	_name.custom_minimum_size = Vector2(210, 0)
	row.add_child(_name)
	for m: Array in MODES:
		var b := Button.new()
		b.text = m[1]
		b.custom_minimum_size = Vector2(138, 52)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(set_mode.bind(str(m[0])))
		row.add_child(b)
		_btns[m[0]] = b
	for e: Array in [["Explorer", _explore], ["Base", _go_home]]:
		var eb := Button.new()
		eb.text = e[0]
		eb.custom_minimum_size = Vector2(120, 52)
		eb.add_theme_font_size_override("font_size", 19)
		eb.pressed.connect(e[1])
		row.add_child(eb)
	var sheet_btn := Button.new()
	sheet_btn.text = "Fiche"
	sheet_btn.custom_minimum_size = Vector2(100, 52)
	sheet_btn.pressed.connect(func() -> void: hud.sheet.visible = not hud.sheet.visible)
	row.add_child(sheet_btn)
	row.add_child(UiStyle.close_button(func() -> void: hud.show_lutin(null)))
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.add_theme_color_override("font_color", UiStyle.TXT_D)
	v.add_child(_hint)


func select(l: Lutin) -> void:
	lutin = l
	_bar.visible = true
	game.lutins_view.selected_id = l.id
	set_mode("auto")


func clear() -> void:
	lutin = null
	_bar.visible = false
	game.lutins_view.selected_id = -1


func active() -> bool:
	return lutin != null and _bar.visible


## Exploration autonome (éclaireurs) : il part découvrir la carte, campe la nuit, repart au matin.
func _explore() -> void:
	if lutin != null and LutinOrders.give(game.colony, game.board, lutin, "explore", lutin.cell):
		EventBus.alert.emit("ordre", "%s part en exploration." % lutin.name)


func _go_home() -> void:
	if lutin != null and LutinOrders.give(game.colony, game.board, lutin, "move", game.colony.stock.pos):
		EventBus.alert.emit("ordre", "%s rentre à la base." % lutin.name)


func set_mode(m: String) -> void:
	mode = m
	for k: String in _btns:
		_btns[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == m else UiStyle.IRON_L))
	if lutin != null:
		_name.text = "Ordres : %s" % lutin.name
	match m:
		"auto":
			_hint.text = "Touchez : un arbre (couper), une plante (cueillir), un animal (chasser), le sol (aller)."
		"build":
			var b := DataRegistry.block(game.build_tool.material_id)
			_hint.text = "Touchez un bloc : %s posé dessus (matériau choisi dans Construire)." % b.get("name", "?")
		"dig":
			_hint.text = "Touchez le bloc à creuser."
		"cart":
			_hint.text = "Touchez l'endroit où amener la charrette."


## Toucher sur la carte pendant le mode ordres. Renvoie true (le toucher est consommé).
func on_tap(screen: Vector2) -> bool:
	if lutin == null or not game.colony.lutins.has(lutin):
		hud.show_lutin(null)
		return false
	var cam: Camera3D = game.camera.cam
	var other := _lutin_near(cam, screen)
	if other != null and other != lutin:
		hud.show_lutin(other)
		return true
	var ok := false
	var what := ""
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	match mode:
		"auto":
			var t := _target_at(cam, screen)
			if not t.is_empty():
				ok = LutinOrders.give(game.colony, game.board, lutin, t["kind"], t["cell"], t)
				what = t["label"]
			elif r["hit"]:
				ok = LutinOrders.give(game.colony, game.board, lutin, "move", r["pos"] + Vector3i.UP)
				what = "va ici"
		"build":
			if r["hit"]:
				var cell: Vector3i = r["pos"] + r["normal"]
				var block: int = game.build_tool.material_id
				ok = LutinOrders.give(game.colony, game.board, lutin, "build", cell, {"block": block})
				what = "construit"
		"dig":
			if r["hit"]:
				ok = LutinOrders.give(game.colony, game.board, lutin, "dig", r["pos"])
				what = "creuse"
		"cart":
			if r["hit"]:
				ok = LutinOrders.give(game.colony, game.board, lutin, "cart", r["pos"] + Vector3i.UP)
				what = "déplace la charrette"
				set_mode("auto")
	if ok:
		hud.sheet.visible = false
		EventBus.alert.emit("ordre", "%s %s." % [lutin.name, what])
	elif what != "" or r["hit"]:
		EventBus.alert.emit("alerte", "%s ne peut pas faire ça." % lutin.name)
	return true


func _lutin_near(cam: Camera3D, screen: Vector2) -> Lutin:
	var best: Lutin = null
	var bd := 45.0
	for l: Lutin in game.colony.lutins:
		var p := l.pos + Vector3(0, 0.5, 0)
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(screen)
		if d < bd:
			bd = d
			best = l
	return best


## Arbre, plante ou animal sous le doigt (recherche à l'écran, rayon 45 px).
func _target_at(cam: Camera3D, screen: Vector2) -> Dictionary:
	var best := {}
	var bd := 45.0
	var focus: Vector3 = game.camera.target
	var lists := [
		["cut", "coupe l'arbre", game.flora.trees, 1.2],
		["gather", "cueille", game.flora.bushes, 0.4],
		["gather", "cueille", game.flora.herbs, 0.3]
	]
	for e: Array in lists:
		for c: Vector3i in e[2]:
			var p := Vector3(c) + Vector3(0.5, e[3], 0.5)
			if p.distance_to(focus) > 60.0 or cam.is_position_behind(p):
				continue
			var d := cam.unproject_position(p).distance_to(screen)
			if d < bd:
				bd = d
				best = {"kind": e[0], "cell": c, "label": e[1]}
	for a: Dictionary in game.fauna.animals:
		var p: Vector3 = a["pos"] + Vector3(0, 0.4, 0)
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(screen)
		if d < bd:
			bd = d
			best = {"kind": "hunt", "cell": a["cell"], "animal": a["id"], "label": "chasse"}
	return best


func _process(_d: float) -> void:
	if lutin != null and not game.colony.lutins.has(lutin):
		hud.show_lutin(null)
