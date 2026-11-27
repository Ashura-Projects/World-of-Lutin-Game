class_name ShotsView
extends Node3D
## Rochers de catapulte en vol (trajectoire en cloche).

var catapults: Catapults
var _rocks: Array[MeshInstance3D] = []


func _process(_d: float) -> void:
	if catapults == null:
		return
	var shots := catapults.shots
	while _rocks.size() < shots.size():
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.3
		s.height = 0.6
		s.radial_segments = 8
		s.rings = 4
		m.mesh = s
		m.material_override = LutinModel.mat("6a6a6a", 0.9)
		add_child(m)
		_rocks.append(m)
	for i in _rocks.size():
		_rocks[i].visible = i < shots.size()
		if i < shots.size():
			var sh: Dictionary = shots[i]
			var k := clampf(float(sh["t"]) / maxf(0.01, float(sh["dur"])), 0.0, 1.0)
			var a: Vector3 = sh["from"]
			var b := Vector3(sh["to"]) + Vector3(0.5, 0.5, 0.5)
			var p := a.lerp(b, k)
			p.y += sin(k * PI) * maxf(4.0, a.distance_to(b) * 0.35)
			_rocks[i].position = p
