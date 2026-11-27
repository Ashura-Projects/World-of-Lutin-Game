class_name StoreZonesView
extends MultiMeshInstance3D
## Zones de réserve : dalles dorées translucides posées au sol (reconstruites quand les zones changent).

var _colony: Colony
var _version: int = -1


func bind(c: Colony) -> void:
	_colony = c
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.77, 0.62, 0.33, 0.38)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := PlaneMesh.new()
	q.size = Vector2(0.92, 0.92)
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	m.vertex_color_use_as_albedo = true
	mm.mesh = q
	multimesh = mm


func _process(_d: float) -> void:
	if _colony == null or _colony.stores.version == _version:
		return
	_version = _colony.stores.version
	var cells := _colony.stores.cells()
	var graves := _colony.cemetery
	multimesh.instance_count = cells.size() + graves.size()
	for i in graves.size():
		multimesh.set_instance_transform(
			cells.size() + i,
			Transform3D(Basis().scaled(Vector3(1, 1, 1)), Vector3(graves[i]) + Vector3(0.5, 0.05, 0.5))
		)
		multimesh.set_instance_color(cells.size() + i, Color(0.35, 0.45, 0.35, 0.5))
	for i in cells.size():
		multimesh.set_instance_color(i, Color(0.77, 0.62, 0.33, 0.38))
		var c: Vector3i = cells[i]
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(c) + Vector3(0.5, 0.04, 0.5)))
