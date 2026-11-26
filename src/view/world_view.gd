class_name WorldView
extends Node3D
## Affiche les chunks : maillage sur thread de travail (WorkerThreadPool), application dans le thread principal.

const ATLAS_PATH := "res://assets/textures/blocks_atlas.png"
const MAX_APPLY_PER_FRAME := 6

var world: VoxelWorld
var max_y: int = 9999  # curseur d'étage : on masque tout ce qui est au-dessus
var faces_total: int = 0
var _views: Dictionary = {}  # Vector3i -> [MeshInstance3D opaque, MeshInstance3D eau]
var _pending: Dictionary = {}  # clés à remailler
var _running: Dictionary = {}  # task_id -> clé
var _results: Array = []
var _mutex := Mutex.new()
var _mat_opaque: StandardMaterial3D
var _mat_liquid: StandardMaterial3D


func setup(w: VoxelWorld) -> void:
	world = w
	_mat_opaque = StandardMaterial3D.new()
	_mat_opaque.albedo_texture = load(ATLAS_PATH)
	_mat_opaque.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_mat_opaque.roughness = 0.95
	_mat_liquid = StandardMaterial3D.new()
	_mat_liquid.albedo_texture = _mat_opaque.albedo_texture
	_mat_liquid.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_mat_liquid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_liquid.albedo_color = Color(1, 1, 1, 0.82)
	_mat_liquid.roughness = 0.08
	_mat_liquid.metallic_specular = 0.8
	world.block_changed.connect(_on_block_changed)
	for k: Vector3i in world.chunk_keys():
		_pending[k] = true


func remesh_all() -> void:
	for k: Vector3i in world.chunk_keys():
		_pending[k] = true


func set_max_y(y: int) -> void:
	if y == max_y:
		return
	max_y = y
	remesh_all()


func _on_block_changed(p: Vector3i, _old: int, _new: int) -> void:
	for k in VoxelWorld.affected_chunks(p):
		if world.chunks.has(k):
			_pending[k] = true


## Maillage synchrone de tout le monde (chargement, tests).
func build_all_now() -> void:
	for k: Vector3i in world.chunk_keys():
		_apply(k, ChunkMesher.build(world, k, max_y))
	_pending.clear()


func _process(_delta: float) -> void:
	# lancer les tâches en attente (une par chunk)
	for k: Vector3i in _pending.keys():
		if _running.values().has(k):
			continue
		_pending.erase(k)
		var key := k
		var my := max_y
		var id := WorkerThreadPool.add_task(func() -> void: _mesh_task(key, my))
		_running[id] = key
		if _running.size() >= 8:
			break
	for id: int in _running.keys():
		if WorkerThreadPool.is_task_completed(id):
			WorkerThreadPool.wait_for_task_completion(id)
			_running.erase(id)
	_mutex.lock()
	var batch := _results.slice(0, MAX_APPLY_PER_FRAME)
	_results = _results.slice(MAX_APPLY_PER_FRAME)
	_mutex.unlock()
	for r: Array in batch:
		_apply(r[0], r[1])


func _mesh_task(key: Vector3i, my: int) -> void:
	var res := ChunkMesher.build(world, key, my)
	_mutex.lock()
	_results.append([key, res])
	_mutex.unlock()


func _apply(key: Vector3i, res: Dictionary) -> void:
	var pair: Array = _views.get(key, [])
	if pair.is_empty():
		pair = [MeshInstance3D.new(), MeshInstance3D.new()]
		pair[1].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pair[0])
		add_child(pair[1])
		_views[key] = pair
	for i in 2:
		var arrays: Array = res["opaque"] if i == 0 else res["liquid"]
		var mi: MeshInstance3D = pair[i]
		if arrays.is_empty():
			mi.mesh = null
			continue
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		m.surface_set_material(0, _mat_opaque if i == 0 else _mat_liquid)
		mi.mesh = m


func is_idle() -> bool:
	return _pending.is_empty() and _running.is_empty() and _results.is_empty()
