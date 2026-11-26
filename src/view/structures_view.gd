class_name StructuresView
extends Node3D
## Bâtiments et objets : modèle low-poly quand c'est construit, fantôme bleu tant que c'est un plan.

static var emblem_texture: Texture2D = null  # emblème de la faction, rendu une fois pour les fanions

var _st: Structures
var _nodes: Dictionary = {}
var _emblem_vp: SubViewport
var _emblem: Emblem
var _ghost := BuildTool._ghost_mat(Color(0.35, 0.67, 1.0, 0.4))


func bind(s: Structures) -> void:
	_st = s
	_emblem_vp = SubViewport.new()
	_emblem_vp.size = Vector2i(256, 320)
	_emblem_vp.transparent_bg = true
	_emblem_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_emblem_vp)
	_emblem = Emblem.new()
	_emblem.size = Vector2(256, 320)
	_emblem_vp.add_child(_emblem)
	_emblem.show_faction(Faction.current if Faction.current != null else Faction.new())
	emblem_texture = _emblem_vp.get_texture()
	EventBus.faction_changed.connect(func() -> void: _emblem.show_faction(Faction.current))
	s.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for id: int in _nodes.keys():
		if not _st.items.has(id) or _nodes[id][1] != _st.items[id]["built"]:
			_nodes[id][0].queue_free()
			_nodes.erase(id)
	for s: Dictionary in _st.items.values():
		if _nodes.has(s["id"]):
			continue
		var n := model(s["kind"])
		n.position = Vector3(s["cell"]) + Vector3(0.5, 0, 0.5)
		n.rotation.y = _facing(s["cell"])
		if not s["built"]:
			_ghostify(n)
		add_child(n)
		_nodes[s["id"]] = [n, s["built"]]


## Orientation : dos au mur le plus proche (fanions muraux, armoires…).
func _facing(cell: Vector3i) -> float:
	var w: VoxelWorld = _st.get_meta("world") if _st.has_meta("world") else null
	if w == null:
		return 0.0
	for d: Array in [
		[Vector3i(0, 0, 1), 0.0], [Vector3i(1, 0, 0), PI / 2], [Vector3i(0, 0, -1), PI], [Vector3i(-1, 0, 0), -PI / 2]
	]:
		if w.is_solid(cell + d[0]):
			return d[1]
	return 0.0


func _ghostify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			c.material_override = _ghost
		elif c is Light3D:
			c.visible = false
		_ghostify(c)


static func _box(
	root: Node3D, size: Vector3, color: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, emit: float = 0.0
) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = LutinModel.mat(color, 0.85, 0.0, emit)
	mi.position = pos
	mi.rotation = rot
	root.add_child(mi)


static func model(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"tent":  # toile de peaux tendue sur deux perches
			var cloth := MeshInstance3D.new()
			var prism := PrismMesh.new()
			prism.size = Vector3(1.8, 1.3, 1.9)
			cloth.mesh = prism
			cloth.material_override = LutinModel.mat("9a7a58", 0.95)
			cloth.position = Vector3(0.5, 0.65, 0.5)
			r.add_child(cloth)
			_box(r, Vector3(0.06, 1.5, 0.06), "5a3e28", Vector3(0.5, 0.75, -0.48))
			_box(r, Vector3(0.06, 1.5, 0.06), "5a3e28", Vector3(0.5, 0.75, 1.48))
		"campfire", "hearth":
			for i in 6:
				var a := i * TAU / 6.0
				_box(r, Vector3(0.18, 0.14, 0.18), "6e6c6a", Vector3(cos(a) * 0.32, 0.07, sin(a) * 0.32))
			_box(r, Vector3(0.5, 0.08, 0.1), "5a3e28", Vector3(0, 0.1, 0), Vector3(0, 0.6, 0))
			_box(r, Vector3(0.5, 0.08, 0.1), "5a3e28", Vector3(0, 0.12, 0), Vector3(0, -0.6, 0))
			_box(r, Vector3(0.18, 0.3, 0.18), "ff9a40", Vector3(0, 0.3, 0), Vector3(0, 0.7, 0), 6.0)
			var light := OmniLight3D.new()
			light.light_color = Color("ffa050")
			light.light_energy = 1.6
			light.omni_range = 7.0
			light.position = Vector3(0, 0.8, 0)
			r.add_child(light)
		"bed":
			_box(r, Vector3(0.9, 0.25, 0.9), "6e5236", Vector3(0, 0.13, 0))
			_box(r, Vector3(0.8, 0.1, 0.85), "c8b48a", Vector3(0, 0.3, 0))
			_box(r, Vector3(0.8, 0.12, 0.25), "e0d6c0", Vector3(0, 0.38, -0.28))
		"table":
			_box(r, Vector3(0.9, 0.08, 0.9), "7a5836", Vector3(0, 0.6, 0))
			for sx: float in [-0.38, 0.38]:
				for sz: float in [-0.38, 0.38]:
					_box(r, Vector3(0.08, 0.6, 0.08), "5a3e28", Vector3(sx, 0.3, sz))
		"shelf":
			for i in 3:
				_box(r, Vector3(0.9, 0.06, 0.4), "7a5836", Vector3(0, 0.3 + i * 0.4, 0.25))
		"door":
			_box(r, Vector3(0.9, 1.9, 0.12), "6e4e30", Vector3(0, 0.95, -0.44))
			_box(r, Vector3(0.1, 0.1, 0.06), "c49e54", Vector3(0.3, 0.95, -0.52))
		"torch":
			_box(r, Vector3(0.08, 1.2, 0.08), "5a3e28", Vector3(0, 0.6, 0))
			_box(r, Vector3(0.14, 0.2, 0.14), "ffb050", Vector3(0, 1.3, 0), Vector3.ZERO, 8.0)
			var tl := OmniLight3D.new()
			tl.light_color = Color("ffa050")
			tl.omni_range = 5.0
			tl.position = Vector3(0, 1.4, 0)
			r.add_child(tl)
		"sawbench":
			_box(r, Vector3(1.8, 0.12, 0.7), "7a5836", Vector3(0.5, 0.7, 0))
			_box(r, Vector3(0.1, 0.7, 0.6), "5a3e28", Vector3(-0.3, 0.35, 0))
			_box(r, Vector3(0.1, 0.7, 0.6), "5a3e28", Vector3(1.3, 0.35, 0))
			_box(r, Vector3(0.5, 0.15, 0.2), "6a4a2e", Vector3(0.6, 0.85, 0))
		"wood_bed":
			_box(r, Vector3(0.9, 0.3, 0.95), "7a5836", Vector3(0, 0.15, 0))
			_box(r, Vector3(0.9, 0.6, 0.08), "5a3e28", Vector3(0, 0.4, 0.45))
			_box(r, Vector3(0.8, 0.12, 0.85), "8c3a30", Vector3(0, 0.34, -0.03))
			_box(r, Vector3(0.7, 0.1, 0.2), "e8dcc4", Vector3(0, 0.42, 0.3))
		"chair":
			_box(r, Vector3(0.45, 0.06, 0.45), "7a5836", Vector3(0, 0.45, 0))
			_box(r, Vector3(0.45, 0.5, 0.06), "6a4a2e", Vector3(0, 0.7, 0.2))
			for sx: float in [-0.18, 0.18]:
				for sz: float in [-0.18, 0.18]:
					_box(r, Vector3(0.06, 0.45, 0.06), "5a3e28", Vector3(sx, 0.22, sz))
		"bench":
			_box(r, Vector3(0.95, 0.08, 0.35), "7a5836", Vector3(0, 0.42, 0))
			_box(r, Vector3(0.08, 0.42, 0.3), "5a3e28", Vector3(-0.38, 0.21, 0))
			_box(r, Vector3(0.08, 0.42, 0.3), "5a3e28", Vector3(0.38, 0.21, 0))
		"chest":
			_box(r, Vector3(0.8, 0.5, 0.5), "6e4e30", Vector3(0, 0.25, 0))
			_box(r, Vector3(0.82, 0.08, 0.52), "4a4a50", Vector3(0, 0.45, 0))
			_box(r, Vector3(0.1, 0.12, 0.04), "c49e54", Vector3(0, 0.35, -0.27))
		"wardrobe":
			_box(r, Vector3(0.9, 1.8, 0.5), "6e4e30", Vector3(0, 0.9, 0.2))
			_box(r, Vector3(0.02, 1.6, 0.02), "3a2a1e", Vector3(0, 0.9, -0.06))
			_box(r, Vector3(0.06, 0.06, 0.04), "c49e54", Vector3(-0.08, 1.0, -0.07))
			_box(r, Vector3(0.06, 0.06, 0.04), "c49e54", Vector3(0.08, 1.0, -0.07))
		"barrel":
			var cyl := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.3
			cm.bottom_radius = 0.3
			cm.height = 0.75
			cm.radial_segments = 10
			cyl.mesh = cm
			cyl.material_override = LutinModel.mat("7a5836", 0.85)
			cyl.position = Vector3(0, 0.375, 0)
			r.add_child(cyl)
			for y: float in [0.15, 0.6]:
				_box(r, Vector3(0.64, 0.04, 0.64), "4a4a50", Vector3(0, y, 0))
		"crate":
			_box(r, Vector3(0.7, 0.6, 0.7), "9a7448", Vector3(0, 0.3, 0))
			_box(r, Vector3(0.72, 0.06, 0.06), "6a4a2e", Vector3(0, 0.3, -0.34), Vector3(0, 0, 0.7))
		"lantern":
			_box(r, Vector3(0.06, 1.3, 0.06), "3a3a3e", Vector3(0, 0.65, 0))
			_box(r, Vector3(0.2, 0.26, 0.2), "ffd27a", Vector3(0, 1.4, 0), Vector3.ZERO, 6.0)
			var ll := OmniLight3D.new()
			ll.light_color = Color("ffc070")
			ll.omni_range = 6.0
			ll.position = Vector3(0, 1.4, 0)
			r.add_child(ll)
		"carpet":
			_box(r, Vector3(0.95, 0.03, 0.95), "8c2420", Vector3(0, 0.015, 0))
			_box(r, Vector3(0.75, 0.035, 0.75), "c49e54", Vector3(0, 0.02, 0))
		"flowerpot":
			_box(r, Vector3(0.3, 0.3, 0.3), "a0603c", Vector3(0, 0.15, 0))
			for i in 5:
				_box(
					r,
					Vector3(0.08, 0.08, 0.08),
					["d04060", "f0d040", "e8e8f0"][i % 3],
					Vector3(0.1 * cos(i * 1.3), 0.4, 0.1 * sin(i * 1.3))
				)
		"weapon_rack":
			_box(r, Vector3(0.9, 0.08, 0.2), "6a4a2e", Vector3(0, 0.3, 0.3))
			_box(r, Vector3(0.9, 0.08, 0.2), "6a4a2e", Vector3(0, 1.2, 0.3))
			for i in 3:
				_box(r, Vector3(0.04, 1.4, 0.04), "8a8a90", Vector3(-0.3 + i * 0.3, 0.8, 0.28))
		"banner_wall", "banner_pole":
			var pole := kind == "banner_pole"
			if pole:
				_box(r, Vector3(0.08, 2.6, 0.08), "5a3e28", Vector3(0, 1.3, 0))
				_box(r, Vector3(0.9, 0.06, 0.06), "5a3e28", Vector3(0.0, 2.5, 0))
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.8, 1.0)
			q.mesh = qm
			var m := StandardMaterial3D.new()
			m.albedo_texture = emblem_texture
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			q.material_override = m
			q.position = Vector3(0, 1.95, -0.06) if pole else Vector3(0, 0.55, 0.42)
			q.rotation.y = PI
			r.add_child(q)
		_:
			var d := Structures.def(kind)
			var sz: Array = d.get("size", [1, 1, 1])
			_box(
				r,
				Vector3(float(sz[0]), float(sz[2]) * 0.8, float(sz[1])),
				"7a6a58",
				Vector3((float(sz[0]) - 1.0) / 2.0, float(sz[2]) * 0.4, (float(sz[1]) - 1.0) / 2.0)
			)
	return r
