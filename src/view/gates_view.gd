class_name GatesView
extends Node3D
## Herses et ponts-levis animés : la herse coulisse vers le haut, le pont-levis pivote sur sa charnière.

var gates: Gates
var _nodes: Dictionary = {}  # id -> [Node3D pivot, Node3D animé]


func bind(g: Gates) -> void:
	gates = g


func _model(g: Dictionary) -> Array:
	var root := Node3D.new()
	var ax := Gates.axes(int(g["rot"]))
	var across: Vector3 = Vector3(ax[0])
	var fwd: Vector3 = Vector3(ax[1])
	var moving := Node3D.new()
	root.add_child(moving)
	if g["kind"] == "portcullis":
		root.position = Vector3(g["cell"]) + Vector3(0.5, 0, 0.5) - across * 0.5 + across
		root.basis = Basis.looking_at(fwd, Vector3.UP)
		for i in 5:
			StructuresView._box(moving, Vector3(0.08, 3.0, 0.08), "3a3a40", Vector3(-0.8 + i * 0.4, 1.5, 0))
		for j in 6:
			StructuresView._box(moving, Vector3(2.0, 0.07, 0.08), "3a3a40", Vector3(0, 0.25 + j * 0.5, 0))
		for i in 5:
			StructuresView._box(moving, Vector3(0.06, 0.2, 0.06), "6a6a72", Vector3(-0.8 + i * 0.4, -0.05, 0))
	else:
		var w := int(g["w"])
		var l := int(g["l"])
		# charnière au bord de la case de départ, au niveau du sol
		root.position = Vector3(g["cell"]) + Vector3(0.5, 0, 0.5) + fwd * 0.5 + across * (w - 1) * 0.5
		root.basis = Basis.looking_at(fwd, Vector3.UP)
		StructuresView._box(moving, Vector3(w, 0.15, l), "7a5836", Vector3(0, -0.08, -l / 2.0))
		for k in l:
			StructuresView._box(moving, Vector3(w, 0.04, 0.06), "4a3420", Vector3(0, 0.01, -0.5 - k))
		for s: float in [-1.0, 1.0]:
			StructuresView._box(moving, Vector3(0.05, 0.05, l), "3a3a40", Vector3(s * (w / 2.0 - 0.1), 0.05, -l / 2.0))
	add_child(root)
	return [root, moving]


func _process(delta: float) -> void:
	if gates == null:
		return
	for id: int in _nodes.keys():
		if not gates.gates.has(id):
			_nodes[id][0].queue_free()
			_nodes.erase(id)
	for g: Dictionary in gates.gates.values():
		if not _nodes.has(g["id"]):
			_nodes[g["id"]] = _model(g)
			_snap(g)
		var m: Node3D = _nodes[g["id"]][1]
		var k := minf(1.0, delta * 2.0)
		if g["kind"] == "portcullis":
			m.position.y = lerpf(m.position.y, 2.8 if g["open"] else 0.0, k)
		else:
			m.rotation.x = lerp_angle(m.rotation.x, 0.0 if g["open"] else PI / 2.0, k)


func _snap(g: Dictionary) -> void:
	var m: Node3D = _nodes[g["id"]][1]
	if g["kind"] == "portcullis":
		m.position.y = 2.8 if g["open"] else 0.0
	else:
		m.rotation.x = 0.0 if g["open"] else PI / 2.0
