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


var _flora: Flora


func bind(f: Flora) -> void:
	_flora = f
	f.changed.connect(func(_k: String) -> void: refresh())
	EventBus.day_changed.connect(func(_d: int) -> void: refresh())
	refresh()


static func herb_mesh(kind: String) -> Mesh:
	var st := SurfaceTool.new()
	var color := Color("9fb870")
	match kind:
		"mushroom":  # pieds clairs + chapeaux bruns
			for i in 3:
				var off := Vector3(0.18 * cos(i * 2.1), 0, 0.18 * sin(i * 2.1))
				var stem := CylinderMesh.new()
				stem.top_radius = 0.035
				stem.bottom_radius = 0.045
				stem.height = 0.14
				stem.radial_segments = 6
				st.append_from(stem, 0, Transform3D(Basis(), off + Vector3(0, 0.07, 0)))
				var cap := SphereMesh.new()
				cap.radius = 0.1
				cap.height = 0.1
				cap.radial_segments = 8
				cap.rings = 3
				st.append_from(cap, 0, Transform3D(Basis(), off + Vector3(0, 0.15, 0)))
			color = Color("8a5a3a")
		"reed":
			for i in 6:
				var c := CylinderMesh.new()
				c.top_radius = 0.015
				c.bottom_radius = 0.02
				c.height = 0.9
				c.radial_segments = 4
				st.append_from(
					c,
					0,
					Transform3D(Basis(Vector3.RIGHT, 0.08 * (i % 3 - 1)), Vector3(0.15 * cos(i), 0.45, 0.15 * sin(i)))
				)
				var head := CylinderMesh.new()
				head.top_radius = 0.035
				head.bottom_radius = 0.035
				head.height = 0.15
				head.radial_segments = 5
				st.append_from(head, 0, Transform3D(Basis(), Vector3(0.15 * cos(i), 0.92, 0.15 * sin(i))))
			color = Color("7a8a4a")
		_:
			for i in 3:
				var c := CylinderMesh.new()
				c.top_radius = 0.0
				c.bottom_radius = 0.06
				c.height = 0.45
				c.radial_segments = 4
				c.rings = 1
				st.append_from(
					c,
					0,
					Transform3D(
						Basis(Vector3.UP, i * 2.1).rotated(Vector3.RIGHT, 0.2),
						Vector3(0.15 * cos(i * 2.1), 0.22, 0.15 * sin(i * 2.1))
					)
				)
			color = Color("6f8fc8") if kind == "wild_flax" else Color("9fb870")
	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, _mat(color))
	return m


## Buisson garni de baies rouges (prêt à cueillir).
static func berry_bush_mesh() -> Mesh:
	var st := SurfaceTool.new()
	var s := SphereMesh.new()
	s.radius = 0.35
	s.height = 0.55
	s.radial_segments = 7
	s.rings = 4
	st.append_from(s, 0, Transform3D())
	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, _mat(Color("44703a")))
	var st2 := SurfaceTool.new()
	for i in 8:
		var b := SphereMesh.new()
		b.radius = 0.055
		b.height = 0.11
		b.radial_segments = 5
		b.rings = 3
		var a := i * 0.8
		st2.append_from(b, 0, Transform3D(Basis(), Vector3(0.3 * cos(a), 0.1 + 0.08 * (i % 3), 0.3 * sin(a))))
	st2.generate_normals()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st2.commit_to_arrays())
	m.surface_set_material(1, _mat(Color("a01e3a")))
	return m


## Reconstruit les MultiMesh depuis la simulation (arbres coupés, buissons cueillis…).
func refresh() -> void:
	var trees := []
	for p: Vector3i in _flora.trees:
		trees.append({"pos": p, "kind": _flora.trees[p]})
	var bushes := []
	var bare := []
	for p: Vector3i in _flora.bushes:
		if _flora.bush_ready(p, GameClock.day()):
			bushes.append({"pos": p})
		else:
			bare.append(p)
	show_items("buisson_nu", bush_mesh(), bare)
	for k: String in ["pin", "chene", "bouleau"]:
		if not trees.any(func(t: Dictionary) -> bool: return t["kind"] == k):
			show_items(k, tree_mesh(k), [])
	show_flora(trees, bushes)
	var herbs := {}
	for p: Vector3i in _flora.herbs:
		herbs.get_or_add(_flora.herbs[p], []).append(p)
	for k: String in ["wild_flax", "medicinal_herb", "mushroom", "reed"]:
		show_items(k, herb_mesh(k), herbs.get(k, []))


func show_flora(trees: Array, bushes: Array) -> void:
	var by_kind := {}
	for t: Dictionary in trees:
		by_kind.get_or_add(t["kind"], []).append(t["pos"])
	for kind: String in by_kind:
		show_items(kind, tree_mesh(kind), by_kind[kind])
	var bp := []
	for b: Dictionary in bushes:
		bp.append(b["pos"])
	show_items("buisson", berry_bush_mesh(), bp)
