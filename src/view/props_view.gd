class_name PropsView
extends Node3D
## Objets posés dans le monde (chariot de départ, puis tentes, feux, établis…).


static func cart() -> Node3D:
	var root := Node3D.new()
	var wood := LutinModel.mat("60462e", 0.85)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.45, 0.9)
	box.mesh = bm
	box.material_override = wood
	box.position = Vector3(0, 0.55, 0)
	root.add_child(box)
	var cover := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.8
	cm.height = 0.8
	cm.radial_segments = 10
	cm.rings = 4
	cover.mesh = cm
	cover.scale = Vector3(1.0, 0.75, 0.6)
	cover.material_override = LutinModel.mat("aaa082", 0.9)
	cover.position = Vector3(0, 0.8, 0)
	root.add_child(cover)
	for dx: float in [-0.6, 0.6]:
		for dz: float in [-0.5, 0.5]:
			var w := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.3
			wm.bottom_radius = 0.3
			wm.height = 0.08
			wm.radial_segments = 10
			w.mesh = wm
			w.material_override = LutinModel.mat("463222", 0.8)
			w.rotation = Vector3(PI / 2, 0, 0)
			w.position = Vector3(dx, 0.3, dz)
			root.add_child(w)
	return root


func place(node: Node3D, cell: Vector3i) -> void:
	node.position = Vector3(cell) + Vector3(0.5, 0, 0.5)
	add_child(node)
