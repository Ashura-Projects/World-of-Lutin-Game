class_name FogView
extends MultiMeshInstance3D
## Brouillard de guerre : un mur de brume sombre sur chaque colonne pas encore explorée (près de la caméra).

var territory: Territory
var focus := Vector3.ZERO
var _version: int = -1
var _at := Vector3(-9999, 0, -9999)


func bind(t: Territory, world_height: int) -> void:
	territory = t
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cfg: Dictionary = DataRegistry.get_table("realm").get("fog", {})
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(str(cfg.get("color", "1c2028")))
	m.albedo_color.a = float(cfg.get("alpha", 0.94))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var b := BoxMesh.new()
	b.size = Vector3(t.size, world_height + 4, t.size)
	b.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = b
	multimesh = mm


func _process(_d: float) -> void:
	if territory == null:
		return
	var moved := Vector2(focus.x - _at.x, focus.z - _at.z).length() > 12.0
	if not moved and territory.version == _version:
		return
	_version = territory.version
	_at = focus
	var r := Graphics.view_distance() + territory.size * 2
	var s := territory.size
	var c0 := territory.col_of(Vector3i(int(focus.x - r), 0, int(focus.z - r)))
	var c1 := territory.col_of(Vector3i(int(focus.x + r), 0, int(focus.z + r)))
	var list := []
	for x in range(c0.x, c1.x + 1):
		for z in range(c0.y, c1.y + 1):
			var c := Vector2i(x, z)
			if territory.in_map(c) and not territory.explored.has(c):
				list.append(c)
	var h := multimesh.mesh.get_aabb().size.y
	multimesh.instance_count = list.size()
	for i in list.size():
		var c: Vector2i = list[i]
		multimesh.set_instance_transform(
			i, Transform3D(Basis(), Vector3(c.x * s + s / 2.0, h / 2.0 - 2.0, c.y * s + s / 2.0))
		)
