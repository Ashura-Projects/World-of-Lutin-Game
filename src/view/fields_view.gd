class_name FieldsView
extends Node3D
## Cultures sur les cases de champ : pousses (semé), plantes mûres (blé doré, lin bleu, pommes de terre en feuilles).

const COLORS := {
	"wheat": ["7aa04a", "d8b84a"],
	"barley": ["7aa04a", "c8b060"],
	"flax": ["6a9a50", "6f8fc8"],
	"potato": ["5a8a40", "4a7a34"]
}

var _fields: Fields
var _mmis: Dictionary = {}
var _dirty: bool = true


func bind(f: Fields) -> void:
	_fields = f
	f.changed.connect(func(_c: Vector3i) -> void: _dirty = true)
	EventBus.day_changed.connect(func(_d: int) -> void: _dirty = true)


func _mesh(height: float, color: String) -> Mesh:
	var st := SurfaceTool.new()
	for i in 3:
		for j in 3:
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 0.05
			c.height = height
			c.radial_segments = 4
			c.rings = 1
			st.append_from(c, 0, Transform3D(Basis(), Vector3(-0.3 + i * 0.3, height / 2.0, -0.3 + j * 0.3)))
	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, LutinModel.mat(color, 0.85))
	return m


func _process(_d: float) -> void:
	if not _dirty or _fields == null:
		return
	_dirty = false
	var groups := {}
	for cell: Vector3i in _fields.plots:
		var p: Dictionary = _fields.plots[cell]
		if p["state"] in ["sown", "ripe"]:
			var g := float(p["growth"]) / float(Fields.crop(p["crop"]).get("grow_days", 8))
			var stage := "ripe" if p["state"] == "ripe" else ("mid" if g > 0.4 else "young")
			groups.get_or_add(p["crop"] + "_" + stage, []).append(cell)
	for key: String in _mmis.keys():
		if not groups.has(key):
			_mmis[key].multimesh.instance_count = 0
	for key: String in groups:
		var parts := key.split("_")
		var crop := parts[0]
		var stage := parts[1]
		if not _mmis.has(key):
			var mmi := MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			var cols: Array = COLORS.get(crop, ["7aa04a", "d8b84a"])
			mm.mesh = _mesh({"young": 0.15, "mid": 0.35, "ripe": 0.6}[stage], cols[1] if stage == "ripe" else cols[0])
			mmi.multimesh = mm
			add_child(mmi)
			_mmis[key] = mmi
		var cells: Array = groups[key]
		var m: MultiMesh = _mmis[key].multimesh
		m.instance_count = cells.size()
		for i in cells.size():
			m.set_instance_transform(i, Transform3D(Basis(), Vector3(cells[i]) + Vector3(0.5, 1.0, 0.5)))
