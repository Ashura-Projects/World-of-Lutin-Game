class_name HudWindows
extends Node
## Fenêtres en jeu : chaque fenêtre a une croix ✕ (ajoutée ici si elle n'en a pas), et reste dans la zone libre
## de l'écran (entre la barre du haut et celle du bas, sans couvrir les boutons de caméra).
## Sert aussi à « toucher la carte » pour choisir un endroit (unités, charrette…).

const AREA := Rect2(8, 66, 1516, 556)  # zone libre (barre du haut 62 px, barre du bas à 628, colonne caméra à droite)

var root: Control
var game: Node
var _items: Array = []  # [fenêtre, bouton ✕ ou null, était visible]
var _pick_cb: Callable
var _pick_bar: PanelContainer
var _pick_label: Label


func setup(r: Control, g: Node) -> void:
	root = r
	game = g
	_pick_bar = PanelContainer.new()
	_pick_bar.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD, 2, 24))
	_pick_bar.position = Vector2(520, 72)
	_pick_bar.visible = false
	root.add_child(_pick_bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_pick_bar.add_child(h)
	_pick_label = Label.new()
	_pick_label.add_theme_font_size_override("font_size", 22)
	h.add_child(_pick_label)
	h.add_child(UiStyle.close_button(cancel_pick))


## Inscrit une fenêtre. on_close = ce que fait la croix ; own_close = la fenêtre a déjà sa croix.
func add(panel: Control, on_close: Callable, own_close: bool = false) -> void:
	var x: Button = null
	if not own_close:
		x = UiStyle.close_button(on_close)
		x.custom_minimum_size = Vector2(50, 46)
		x.visible = false
		root.add_child(x)
	_items.append([panel, x, false])


func _process(_d: float) -> void:
	for it: Array in _items:
		var p: Control = it[0]
		var x: Button = it[1]
		if not is_instance_valid(p):
			continue
		var shown := p.visible and p.is_visible_in_tree()
		if shown and not it[2] and p.get_parent() == root:
			root.move_child(p, -1)  # la fenêtre qui s'ouvre passe devant les autres (avec sa croix)
			if x != null:
				root.move_child(x, -1)
		it[2] = shown
		if shown:
			_clamp(p)
		if x != null:
			x.visible = shown
			if shown:
				x.position = p.position + Vector2(p.size.x - 40, -12)


## Garde la fenêtre dans la zone libre (aucun menu ne déborde sur la barre du bas).
func _clamp(p: Control) -> void:
	var pos := p.position
	pos.x = clampf(pos.x, AREA.position.x, maxf(AREA.position.x, AREA.end.x - p.size.x))
	pos.y = clampf(pos.y, AREA.position.y, maxf(AREA.position.y, AREA.end.y - p.size.y))
	if pos != p.position:
		p.position = pos


# --- toucher la carte pour choisir un endroit ----------------------------------------------------
func pick_cell(prompt: String, cb: Callable) -> void:
	_pick_cb = cb
	_pick_label.text = "  👆 %s" % prompt
	_pick_bar.visible = true
	root.move_child(_pick_bar, -1)


func picking() -> bool:
	return _pick_bar.visible


func cancel_pick() -> void:
	_pick_bar.visible = false
	_pick_cb = Callable()


## Appelé par la scène de jeu sur un toucher : renvoie true si le toucher a servi à choisir un endroit.
func on_tap(screen: Vector2) -> bool:
	if not picking():
		return false
	var cell := ground_cell(screen)
	if cell.y < 0:
		return true
	var cb := _pick_cb
	cancel_pick()
	if cb.is_valid():
		cb.call(cell)
	return true


## Case d'air au-dessus du bloc touché (là où un lutin peut se tenir).
func ground_cell(screen: Vector2) -> Vector3i:
	var cam: Camera3D = game.camera.cam
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if not r["hit"]:
		return Vector3i(-1, -1, -1)
	return r["pos"] + Vector3i.UP
