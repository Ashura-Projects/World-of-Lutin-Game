class_name Minimap
extends Control
## Carte dessinée (minicarte et grande carte) : relief, brouillard, territoires, villages rencontrés, camps
## d'orcs repérés, ressources découvertes, marqueurs, lutins, cadre de la caméra. Toucher = aller voir là.

signal picked(cell: Vector3i)

var game: Node
var filters := {"territory": true, "factions": true, "resources": true, "markers": true, "lutins": true}
var tex: Texture2D
var data: Dictionary = {}
var _task: int = -1
var _result: Dictionary = {}
var _built_at: int = -100000


func setup(g: Node, sz: Vector2) -> void:
	game = g
	custom_minimum_size = sz
	size = sz
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


## Reconstruit l'image sur un thread (au plus une fois par minute de jeu).
func rebuild() -> void:
	if _task >= 0:
		return
	_built_at = Time.get_ticks_msec()
	var w: VoxelWorld = game.world
	_task = WorkerThreadPool.add_task(func() -> void: _result = MapImage.build(w))


func _process(_d: float) -> void:
	if not is_visible_in_tree():
		return
	if _task < 0 and Time.get_ticks_msec() - _built_at > 60000:
		rebuild()
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		data = _result
		tex = ImageTexture.create_from_image(data["image"])
	if Engine.get_process_frames() % 15 == 0:
		queue_redraw()


func _scale() -> Vector2:
	return size / Vector2(game.world.size.x, game.world.size.z)


func to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) * _scale()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("141618"))
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
	var t: Territory = game.sim.territory
	var k := _scale()
	var cs := Vector2(t.size, t.size) * k
	var n := t.cols()
	for x in n.x:
		for z in n.y:
			var c := Vector2i(x, z)
			var r := Rect2(Vector2(x, z) * cs, cs + Vector2(0.5, 0.5))
			if not t.explored.has(c):
				draw_rect(r, Color(0.07, 0.08, 0.1, 0.96))
			elif filters["territory"] and t.owners.has(c):
				var col := RealmView.faction_color(str(t.owners[c]))
				col.a = 0.38
				draw_rect(r, col)
	var font := UiStyle.title_font()
	if filters["resources"] and data.has("resources"):
		var cfg: Dictionary = DataRegistry.get_table("map").get("resources", {})
		for e: Array in data["resources"]:
			var cell: Vector2i = e[0]
			if t.explored.has(Vector2i(cell.x / t.size, cell.y / t.size)):
				draw_circle(Vector2(cell) * k, 2.2, Color(str(cfg.get(e[1], ["", "ffffff"])[1])))
	if filters["factions"]:
		for st: Dictionary in game.sim.rivals.states.values():
			if not game.sim.rivals.is_met(st["id"]):
				continue
			var p := to_map(Vector3(st["center"]))
			draw_circle(p, 7.0, RealmView.faction_color(st["id"]))
			draw_arc(p, 7.0, 0, TAU, 16, Color.BLACK, 1.5)
		for c: Dictionary in game.sim.orcs.camps:
			if c["discovered"]:
				var p := to_map(Vector3(c["cell"]))
				var col := Color("402020") if c["destroyed"] else Color("e03030")
				draw_line(p - Vector2(5, 5), p + Vector2(5, 5), col, 3.0)
				draw_line(p - Vector2(5, -5), p + Vector2(5, -5), col, 3.0)
	if filters["lutins"]:
		for l: Lutin in game.colony.lutins:
			draw_circle(to_map(l.pos), 1.8, Color("9fd0ff"))
	var home := to_map(Vector3(game.colony.stock.pos))
	draw_circle(home, 5.0, UiStyle.GOLD)
	if filters["markers"]:
		for m: Dictionary in t.markers:
			var p := Vector2(m["cell"]) * k
			draw_string(font, p + Vector2(-6, 6), str(m["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var cam := to_map(game.camera.target)
	var v := Graphics.view_distance() * k.x
	draw_rect(Rect2(cam - Vector2(v, v) * 0.5, Vector2(v, v)), Color(1, 1, 1, 0.8), false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, size), UiStyle.GOLD_D, false, 2.0)


func _gui_input(e: InputEvent) -> void:
	var pressed: bool = (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)
	if not pressed:
		return
	var p: Vector2 = e.position / _scale()
	var x := clampi(int(p.x), 0, game.world.size.x - 1)
	var z := clampi(int(p.y), 0, game.world.size.z - 1)
	picked.emit(Vector3i(x, game.world.surface_y(x, z), z))
	accept_event()
