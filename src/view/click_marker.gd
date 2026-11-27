class_name ClickMarker
extends Node3D
## Marqueur de toucher (1.3.2) : un anneau qui se resserre et une flèche qui descend là où l'on a touché la carte
## (ordres, déplacements, choix d'un endroit), pour bien voir où l'on a cliqué. Disparaît après ~1,2 s.

const LIFE := 1.2

var _ring: MeshInstance3D
var _arrow: MeshInstance3D
var _mat: StandardMaterial3D
var _t: float = LIFE


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.no_depth_test = true
	_mat.render_priority = 2
	_ring = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.38
	t.outer_radius = 0.5
	t.rings = 24
	t.ring_segments = 6
	_ring.mesh = t
	_ring.material_override = _mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_arrow = MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.22
	c.bottom_radius = 0.0
	c.height = 0.45
	c.radial_segments = 6
	_arrow.mesh = c
	_arrow.material_override = _mat
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_arrow)
	visible = false


func show_at(p: Vector3, hex: String = "f0d060") -> void:
	position = p + Vector3(0, 0.06, 0)
	_mat.albedo_color = Color(hex)
	_t = 0.0
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var k := clampf(_t / LIFE, 0.0, 1.0)
	_ring.scale = Vector3.ONE * lerpf(1.6, 0.8, minf(1.0, k * 2.5))
	_arrow.position.y = 0.4 + 0.5 * absf(sin(_t * 6.0)) * (1.0 - k)
	var c := _mat.albedo_color
	c.a = 1.0 - k * k
	_mat.albedo_color = c
	if _t >= LIFE:
		visible = false
