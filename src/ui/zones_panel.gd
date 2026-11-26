class_name ZonesPanel
extends PanelContainer
## Menu Zones : champs posés case par case (tap = une case ; « Rectangle » = deux taps), culture choisie par case.

var game: Node
var crop_id: String = "wheat"
var rect_mode: bool = false
var _first := Vector3i(-1, -1, -1)
var _info: Label
var _crop_buttons: Dictionary = {}


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for c: Dictionary in DataRegistry.get_table("crops").get("crops", []):
		var b := Button.new()
		b.text = c["name"]
		b.custom_minimum_size = Vector2(150, 54)
		var id: String = c["id"]
		b.pressed.connect(func() -> void: _select(id))
		row.add_child(b)
		_crop_buttons[id] = b
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	v.add_child(row2)
	var rb := Button.new()
	rb.text = "Rectangle"
	rb.toggle_mode = true
	rb.custom_minimum_size = Vector2(150, 52)
	rb.toggled.connect(
		func(on: bool) -> void:
			rect_mode = on
			_first = Vector3i(-1, -1, -1)
	)
	row2.add_child(rb)
	_info = Label.new()
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	row2.add_child(_info)
	_select("wheat")


func _select(id: String) -> void:
	crop_id = id
	for k: String in _crop_buttons:
		_crop_buttons[k].add_theme_stylebox_override(
			"normal", UiStyle.box(UiStyle.BLOOD if k == id else UiStyle.IRON_L)
		)
	var c := Fields.crop(id)
	_info.text = (
		"%s : semis %s, %d jours, 1 → %s"
		% [c.get("name", id), ", ".join(c.get("sow", [])), int(c.get("grow_days", 8)), str(c.get("yield", {}))]
	)


static func farmable(world: VoxelWorld, cell: Vector3i) -> bool:
	var id := world.get_block(cell)
	var ok := [
		world.types.num("grass"),
		world.types.num("dirt"),
		world.types.num("fertile_soil"),
		world.types.num("field_plot")
	]
	return ok.has(id) and world.types.solid[world.get_block(cell + Vector3i.UP)] == 0


func on_tap(screen: Vector2) -> void:
	var cam: Camera3D = game.camera.cam
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if not r["hit"]:
		return
	var cell: Vector3i = r["pos"]
	var cells: Array[Vector3i] = [cell]
	if rect_mode:
		if _first.y < 0:
			_first = cell
			_info.text = "Touchez le coin opposé."
			return
		cells = Shapes.rect(_first, Vector3i(cell.x, _first.y, cell.z))
		_first = Vector3i(-1, -1, -1)
	var n := 0
	for p in cells:
		var top := Vector3i(p.x, game.world.surface_y(p.x, p.z) - 1, p.z)
		if farmable(game.world, top):
			game.fields.plan(top, crop_id)
			n += 1
	_info.text = "%d case(s) de %s prévue(s)." % [n, Fields.crop(crop_id).get("name", crop_id)]
