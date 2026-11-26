class_name FloraView
extends Node3D
## Arbres et buissons en MultiMeshInstance3D (un par espèce) — modèles low-poly du style validé.

var _multis: Dictionary = {}


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


## Mesh d'un arbre : tronc + feuillage, couleurs désaturées (STYLE-VALIDE §6).
static func tree_mesh(kind: String) -> Mesh:
	var st := SurfaceTool.new()
	var mesh := ArrayMesh.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.1 if kind != "chene" else 0.14
	trunk.bottom_radius = trunk.top_radius * 1.2
	trunk.height = 1.4
	trunk.radial_segments = 6
	trunk.rings = 1
	st.append_from(trunk, 0, Transform3D(Basis(), Vector3(0, 0.7, 0)))
	var trunk_arr := st.commit_to_arrays()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, trunk_arr)
	mesh.surface_set_material(0, _mat(Color("e0dccf") if kind == "bouleau" else Color("5a3e28")))
	st = SurfaceTool.new()
	if kind == "pin":
		for i in 3:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = [1.0, 0.8, 0.55][i]
			cone.height = [1.2, 1.0, 0.8][i]
			cone.radial_segments = 7
			cone.rings = 1
			st.append_from(cone, 0, Transform3D(Basis(), Vector3(0, 1.6 + i * 0.7, 0)))
	else:
		var blobs := [[Vector3(0, 2.0, 0), 0.9], [Vector3(0.45, 1.7, 0.2), 0.6], [Vector3(-0.4, 1.75, -0.25), 0.62]]
		if kind == "bouleau":
			blobs = [[Vector3(0, 1.9, 0), 0.6], [Vector3(0.1, 2.4, 0.1), 0.45]]
		for b: Array in blobs:
			var s := SphereMesh.new()
			s.radius = b[1]
			s.height = b[1] * 2.0
			s.radial_segments = 7
			s.rings = 4
			st.append_from(s, 0, Transform3D(Basis(), b[0]))
	st.generate_normals()
	var leaves := {"pin": Color("3a5e40"), "chene": Color("4f7436"), "bouleau": Color("7a9442")}
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	mesh.surface_set_material(1, _mat(leaves.get(kind, Color("4f7436"))))
	return mesh


static func bush_mesh() -> Mesh:
	var s := SphereMesh.new()
	s.radius = 0.35
	s.height = 0.55
	s.radial_segments = 7
	s.rings = 4
	s.material = _mat(Color("44703a"))
	return s


func show_items(kind: String, mesh: Mesh, positions: Array) -> void:
	var mmi: MultiMeshInstance3D = _multis.get(kind)
	if mmi == null:
		mmi = MultiMeshInstance3D.new()
		add_child(mmi)
		_multis[kind] = mmi
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in positions.size():
		var p: Vector3i = positions[i]
		var rot := Basis(Vector3.UP, float((p.x * 73 + p.z * 37) % 628) / 100.0)
		var sc := 0.9 + float((p.x * 13 + p.z * 7) % 40) / 100.0
		mm.set_instance_transform(i, Transform3D(rot.scaled(Vector3.ONE * sc), Vector3(p) + Vector3(0.5, 0, 0.5)))
	mmi.multimesh = mm


func show_flora(trees: Array, bushes: Array) -> void:
	var by_kind := {}
	for t: Dictionary in trees:
		by_kind.get_or_add(t["kind"], []).append(t["pos"])
	for kind: String in by_kind:
		show_items(kind, tree_mesh(kind), by_kind[kind])
	var bp := []
	for b: Dictionary in bushes:
		bp.append(b["pos"])
	show_items("buisson", bush_mesh(), bp)
