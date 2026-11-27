class_name RealmView
extends Node3D
## Vue 3D du royaume : camps d'orcs (ruines une fois détruits, cachés tant qu'ils ne sont pas explorés)
## et calque des territoires (filtre de la carte) : une dalle colorée par colonne revendiquée.

var orcs: Orcs
var territory: Territory
var world: VoxelWorld
var show_territory: bool = false
var _camps: Dictionary = {}  # id -> [Node3D, état]
var _terr: MultiMeshInstance3D
var _terr_version: int = -1
var _terr_shown: bool = false


func bind(o: Orcs, t: Territory, w: VoxelWorld) -> void:
	orcs = o
	territory = t
	world = w
	_terr = MultiMeshInstance3D.new()
	_terr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := PlaneMesh.new()
	q.size = Vector2(t.size - 0.6, t.size - 0.6)
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = q
	_terr.multimesh = mm
	add_child(_terr)


static func faction_color(id: String) -> Color:
	if id == "player":
		return Color(Faction.current.color1 if Faction.current != null else "2c4a96")
	if id == "orcs":
		return Color("8c2420")
	return Color(str(Rivals.def(id).get("color", "888888")))


func _process(_d: float) -> void:
	if orcs == null or Engine.get_process_frames() % 20 != 0:
		return
	for c: Dictionary in orcs.camps:
		var seen: bool = territory.explored.has(territory.col_of(c["cell"]))
		var state := "hidden" if not seen else ("ruins" if c["destroyed"] else "camp")
		var cur: Array = _camps.get(c["id"], [null, ""])
		if cur[1] == state:
			continue
		if cur[0] != null:
			cur[0].queue_free()
		var n: Node3D = null
		if state == "camp":
			n = OrcModel.camp()
		elif state == "ruins":
			n = Node3D.new()
			for i in 5:
				StructuresView._box(
					n, Vector3(0.8, 0.3, 0.6), "2a2422", Vector3(cos(i) * 2.5, 0.15, sin(i * 1.7) * 2.5)
				)
		if n != null:
			n.position = Vector3(c["cell"]) + Vector3(0.5, 0, 0.5)
			add_child(n)
		_camps[c["id"]] = [n, state]
	if show_territory != _terr_shown or (show_territory and territory.version != _terr_version):
		_rebuild_territory()


func _rebuild_territory() -> void:
	_terr_shown = show_territory
	_terr_version = territory.version
	var mm := _terr.multimesh
	if not show_territory:
		mm.instance_count = 0
		return
	var list := territory.owners.keys().filter(func(c: Vector2i) -> bool: return territory.explored.has(c))
	mm.instance_count = list.size()
	var s := territory.size
	for i in list.size():
		var c: Vector2i = list[i]
		var x := c.x * s + s / 2
		var z := c.y * s + s / 2
		var y := world.surface_y(clampi(x, 0, world.size.x - 1), clampi(z, 0, world.size.z - 1))
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x, y + 0.25, z)))
		var col := faction_color(str(territory.owners[c]))
		col.a = 0.32
		mm.set_instance_color(i, col)
