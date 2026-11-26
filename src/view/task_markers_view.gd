class_name TaskMarkersView
extends Node3D
## Cercles lumineux au sol sous chaque élément ciblé par un ordre
## (arbre à couper, plante à cueillir, gibier, poste de pêche).
## Ils montrent ce qui est pris en compte et pulsent doucement.

const KINDS := {"cut": "e8c25a", "gather": "8ce06a", "hunt": "e86a4a", "fish": "6ac0e8"}

var _board: TaskBoard
var _mmis: Dictionary = {}
var _mats: Dictionary = {}
var _dirty: bool = true
var _t: float = 0.0


func bind(b: TaskBoard) -> void:
	_board = b
	b.tasks_changed.connect(func() -> void: _dirty = true)
	for k: String in KINDS:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(KINDS[k])
		m.emission_enabled = true
		m.emission = Color(KINDS[k])
		m.emission_energy_multiplier = 2.5
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mats[k] = m
		var mmi := MultiMeshInstance3D.new()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var ring := TorusMesh.new()
		ring.inner_radius = 0.46
		ring.outer_radius = 0.56
		ring.rings = 24
		ring.ring_segments = 4
		ring.material = m
		mm.mesh = ring
		mmi.multimesh = mm
		add_child(mmi)
		_mmis[k] = mmi


func _process(delta: float) -> void:
	_t += delta
	for k: String in _mats:
		_mats[k].emission_energy_multiplier = 1.8 + sin(_t * 4.0) * 0.9
	var has_hunt := false
	for t: Dictionary in _board.tasks.values():
		if t["kind"] == "hunt":
			has_hunt = true
			break
	if not _dirty and not has_hunt:
		return
	_dirty = false
	var groups := {}
	for t: Dictionary in _board.tasks.values():
		if not KINDS.has(t["kind"]):
			continue
		var p := Vector3(t["cell"]) + Vector3(0.5, 0.06, 0.5)
		if t["kind"] == "hunt":
			var a := _board.fauna.find(t["target"])
			if a.is_empty():
				continue
			p = a["pos"] + Vector3(0, 0.06, 0)
		elif t["kind"] == "fish":
			p.y += 1.0
		groups.get_or_add(t["kind"], []).append(p)
	for k: String in _mmis:
		var cells: Array = groups.get(k, [])
		var mm: MultiMesh = _mmis[k].multimesh
		mm.instance_count = cells.size()
		for i in cells.size():
			mm.set_instance_transform(i, Transform3D(Basis(), cells[i]))
