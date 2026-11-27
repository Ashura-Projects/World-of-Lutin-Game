class_name FaunaView
extends Node3D
## Animaux (cerf, sanglier ; loup et ours au J7) en primitives low-poly, couleurs désaturées.

var _fauna: Fauna
var _nodes: Dictionary = {}
var _t: float = 0.0


func bind(f: Fauna) -> void:
	_fauna = f
	f.animal_added.connect(_add, CONNECT_DEFERRED)  # différé : le métier d'un villageois est connu ensuite
	f.animal_removed.connect(
		func(id: int) -> void:
			if _nodes.has(id):
				_nodes[id].queue_free()
				_nodes.erase(id)
	)
	for a in f.animals:
		_add(a)


static func _part(
	root: Node3D, mesh: Mesh, color: String, p: Vector3, s: Vector3 = Vector3.ONE, r: Vector3 = Vector3.ZERO
) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = LutinModel.mat(color, 0.9)
	mi.position = p
	mi.scale = s
	mi.rotation = r
	root.add_child(mi)


static func model(kind: String) -> Node3D:
	if kind.begins_with("orc"):
		return OrcModel.build(kind)
	if kind == "horse":
		return HorseModel.build()
	if kind in ["cow", "pig"]:
		return FarmModels.animal(kind)
	if NpcLook.is_npc(kind):
		return NpcLook.build(kind)
	var root := Node3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	var leg := CylinderMesh.new()
	leg.top_radius = 0.05
	leg.bottom_radius = 0.04
	leg.height = 0.5
	leg.radial_segments = 5
	var cols := {
		"deer": ["8a6440", "5a402a"],
		"boar": ["4a3a30", "2e2420"],
		"wolf": ["8a847c", "5c5650"],
		"bear": ["5a3e2c", "3a2a1e"]
	}
	var c: Array = cols.get(kind, ["888888", "555555"])
	var big := 1.6 if kind == "bear" else (0.8 if kind == "boar" else 1.0)
	_part(root, sphere, c[0], Vector3(0, 0.6 * big, 0), Vector3(0.45, 0.42, 1.0) * big)
	_part(root, sphere, c[0], Vector3(0, 0.82 * big, -0.5 * big), Vector3(0.3, 0.3, 0.38) * big)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_part(root, leg, c[1], Vector3(sx * 0.13 * big, 0.25 * big, sz * 0.3 * big), Vector3.ONE * big)
	if kind == "deer":
		var ant := CylinderMesh.new()
		ant.top_radius = 0.01
		ant.bottom_radius = 0.025
		ant.height = 0.4
		ant.radial_segments = 4
		for sx: float in [-1.0, 1.0]:
			_part(root, ant, "c8b898", Vector3(sx * 0.1, 1.15, -0.5), Vector3.ONE, Vector3(0, 0, sx * 0.5))
	if kind == "boar" or kind == "wolf":
		var tusk := CylinderMesh.new()
		tusk.top_radius = 0.0
		tusk.bottom_radius = 0.025
		tusk.height = 0.1
		_part(root, tusk, "eee6d0", Vector3(0.06, 0.6, -0.78 * big), Vector3.ONE, Vector3(0.4, 0, 0))
		_part(root, tusk, "eee6d0", Vector3(-0.06, 0.6, -0.78 * big), Vector3.ONE, Vector3(0.4, 0, 0))
	return root


func _add(a: Dictionary) -> void:
	if not _fauna.animals.has(a):
		return  # déjà retiré avant d'être affiché
	var m := HorseModel.build(int(a["id"]), a.get("owned", false)) if a["kind"] == "horse" else model(a["kind"])
	if a.has("npc_job") and NpcLook.is_npc(a["kind"]):
		m = NpcLook.build(a["kind"], str(a["npc_job"]))
	m.position = a["pos"]
	add_child(m)
	_nodes[a["id"]] = m


var focus := Vector3.ZERO


func visible_animal(a: Dictionary) -> bool:
	var m: Node3D = _nodes.get(a["id"])
	return m != null and m.visible


var fog: Territory = null


func _process(delta: float) -> void:
	_t += delta
	var r := Graphics.view_distance()
	for a in _fauna.animals:
		var m: Node3D = _nodes.get(a["id"])
		if m == null:
			continue
		var p: Vector3 = a["pos"]
		m.visible = Vector2(p.x - focus.x, p.z - focus.z).length() <= r
		if m.visible and fog != null:
			m.visible = fog.explored.has(fog.col_of(Vector3i(p)))
		if not m.visible:
			m.position = p
			continue
		var dir: Vector3 = a["pos"] - m.position
		dir.y = 0
		if dir.length() > 0.02:
			m.rotation.y = lerp_angle(m.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 6.0))
		m.position = m.position.lerp(a["pos"], minf(1.0, delta * 8.0))
