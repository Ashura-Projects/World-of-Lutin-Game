class_name BuildTool
extends Node3D
## Construction au doigt : tap sur une face = bloc collé à cette face ; glisser = ligne, rectangle ou mur ; gomme.
## En mode construction, 1 doigt = construire, 2 doigts = caméra.

signal changed

enum Mode { BLOCK, LINE, FILL, WALL, ERASE, ROAD, OBJECT }

var active: bool = false
var move_only: bool = false  # « Déplacer » : le doigt bouge la caméra, sans construire
var mode: Mode = Mode.BLOCK
var material_id: int = 0
var wall_height: int = 3
var world: VoxelWorld
var camera: CameraController
var history: EditHistory
var shape_code: int = 0  # forme des blocs posés (ShapeMesh) × 4 + sens
var gate_size := Vector2i(2, 2)  # pont-levis : largeur × longueur
var max_y: int = 9999
## Appelé à la place d'une pose instantanée (J5 : plans pour les bâtisseurs). Signature : (cells, id, erase).
var place_handler: Callable
## Pose d'un objet ou bâtiment (tente, lit…) : (kind, case) -> bool.
var structure_handler: Callable
var object_kind: String = ""
var _touches: Dictionary = {}
var _start := Vector3i.ZERO
var _start_ok: bool = false
var _cells: Array[Vector3i] = []
var _preview: MultiMeshInstance3D
var _mat_ok: StandardMaterial3D
var _mat_erase: StandardMaterial3D


func setup(w: VoxelWorld, cam: CameraController) -> void:
	world = w
	camera = cam
	history = EditHistory.new(w)
	_mat_ok = _ghost_mat(Color(0.35, 0.67, 1.0, 0.45))
	_mat_erase = _ghost_mat(Color(1.0, 0.25, 0.2, 0.45))
	_preview = MultiMeshInstance3D.new()
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_preview)


static func _ghost_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = false
	return m


func set_active(on: bool) -> void:
	active = on
	camera.pan_enabled = not on or move_only
	_cancel()


func _ray(screen: Vector2) -> Dictionary:
	var cam := camera.cam
	return VoxelRaycast.cast(world, cam.project_ray_origin(screen), cam.project_ray_normal(screen), 400.0, max_y)


## Case visée : collée à la face (pose) ou le bloc lui-même (gomme).
func target_cell(screen: Vector2) -> Dictionary:
	var r := _ray(screen)
	if not r["hit"]:
		return {"ok": false}
	var p: Vector3i = r["pos"]
	return {"ok": true, "cell": p if mode in [Mode.ERASE, Mode.ROAD] else p + r["normal"]}


## Case sous le doigt dans le plan horizontal du début du tracé (lignes, rectangles, murs).
func _plane_cell(screen: Vector2) -> Vector3i:
	var cam := camera.cam
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	var y := _start.y + 0.5
	if absf(d.y) < 0.0001:
		return _start
	var t := (y - o.y) / d.y
	var hit := o + d * t
	return Vector3i(floori(hit.x), _start.y, floori(hit.z))


func _shape(end: Vector3i) -> Array[Vector3i]:
	match mode:
		Mode.LINE:
			return Shapes.line(_start, end)
		Mode.FILL:
			return Shapes.rect(_start, end)
		Mode.WALL:
			return Shapes.wall(_start, end, wall_height)
		Mode.ERASE:
			return Shapes.rect(_start, end)
		Mode.ROAD:
			return Shapes.line(_start, end)
	var one: Array[Vector3i] = [_start]
	return one


func _unhandled_input(event: InputEvent) -> void:
	if not active or move_only:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				var t := target_cell(event.position)
				_start_ok = t["ok"]
				if _start_ok:
					_start = t["cell"]
					_cells = _shape(_start)
					_show_preview()
			else:
				_cancel()  # 2 doigts : la caméra prend la main
		else:
			if _touches.size() == 1 and _start_ok:
				commit()
			_touches.erase(event.index)
			if _touches.is_empty():
				_cancel()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _touches.size() == 1 and _start_ok:
		_touches[event.index] = event.position
		if mode != Mode.BLOCK:
			_cells = _shape(_plane_cell(event.position))
			_show_preview()
		get_viewport().set_input_as_handled()


## Valide le tracé en cours : pose (mode créatif) ou transmet aux plans (place_handler).
func commit() -> int:
	var n := 0
	var erase := mode == Mode.ERASE
	if mode == Mode.OBJECT:
		n = int(structure_handler.is_valid() and structure_handler.call(object_kind, _start))
		_cancel()
		changed.emit()
		return n
	if place_handler.is_valid():
		n = place_handler.call(_cells, material_id, erase)
	else:
		n = history.apply(_cells, 0 if erase else material_id, not erase and mode != Mode.ROAD)
	_cancel()
	changed.emit()
	return n


## Pour les tests : tracé programmatique de a à b.
func stroke(a: Vector3i, b: Vector3i) -> int:
	_start = a
	_start_ok = true
	_cells = _shape(b)
	return commit()


func _cancel() -> void:
	_start_ok = false
	_cells = []
	if _preview:
		_preview.multimesh = null


func _show_preview() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 1.02
	box.material = _mat_erase if mode == Mode.ERASE else _mat_ok
	mm.mesh = box
	mm.instance_count = _cells.size()
	for i in _cells.size():
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(_cells[i]) + Vector3(0.5, 0.5, 0.5)))
	_preview.multimesh = mm
