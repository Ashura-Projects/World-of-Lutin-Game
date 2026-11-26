class_name PlansView
extends Node3D
## Plans du joueur : blocs-plans bleus translucides (à bâtir), blocs à démolir en rouge (STYLE-VALIDE §5).

var _board: TaskBoard
var _build: MultiMeshInstance3D
var _dig: MultiMeshInstance3D
var _dirty: bool = true


func bind(b: TaskBoard) -> void:
	_board = b
	b.tasks_changed.connect(func() -> void: _dirty = true)
	_build = _mmi(Color(0.35, 0.67, 1.0, 0.42))
	_dig = _mmi(Color(1.0, 0.28, 0.2, 0.35))


func _mmi(c: Color) -> MultiMeshInstance3D:
	var m := MultiMeshInstance3D.new()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 1.02
	box.material = BuildTool._ghost_mat(c)
	mm.mesh = box
	m.multimesh = mm
	add_child(m)
	return m


func _process(_d: float) -> void:
	if not _dirty:
		return
	_dirty = false
	var b := []
	var d := []
	for t: Dictionary in _board.tasks.values():
		if t["kind"] == "build":
			b.append(t["cell"])
		elif t["kind"] == "dig":
			d.append(t["cell"])
	_fill(_build, b)
	_fill(_dig, d)


func _fill(m: MultiMeshInstance3D, cells: Array) -> void:
	m.multimesh.instance_count = cells.size()
	for i in cells.size():
		m.multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(cells[i]) + Vector3(0.5, 0.5, 0.5)))
