class_name StructuresView
extends Node3D
## Bâtiments et objets : modèle low-poly quand c'est construit, fantôme bleu tant que c'est un plan.

var _st: Structures
var _nodes: Dictionary = {}
var _ghost := BuildTool._ghost_mat(Color(0.35, 0.67, 1.0, 0.4))


func bind(s: Structures) -> void:
	_st = s
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
		if not s["built"]:
			_ghostify(n)
		add_child(n)
		_nodes[s["id"]] = [n, s["built"]]


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
