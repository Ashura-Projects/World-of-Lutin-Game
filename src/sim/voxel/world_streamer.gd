class_name WorldStreamer
extends RefCounted
## Campagne Impériale (1.4) : la carte immense est générée par zones de 64 × 64 colonnes autour de la caméra et des
## lutins, sur un fil de travail (jamais dans le fil principal). Les zones lointaines jamais modifiées sont oubliées
## (elles se régénèrent à l'identique) ; les zones modifiées restent et sont les seules sauvegardées.
## Graphismes Ultra ou personnalisés : toute la carte est générée au départ (pas de streamer).

signal region_loaded(keys: Array)

const REGION := 64

static var active: WorldStreamer = null

var world: VoxelWorld
var gen: WorldGenerator
var enabled: bool = false
## Fusion permise seulement quand le maillage ne lit pas le monde (WorldView inactif) : évite les accès croisés.
var merge_gate: Callable
var flora: Flora
var loaded: Dictionary = {}  # Vector2i -> true
var modified: Dictionary = {}  # Vector2i -> true
var flora_done: Dictionary = {}  # Vector2i -> true (végétation déjà ajoutée, même si la zone a été oubliée)
var _queue: Array[Vector2i] = []
var _task: int = -1
var _task_r := Vector2i.ZERO
var _tmp_gen: WorldGenerator


func _init(w: VoxelWorld, f: Flora) -> void:
	world = w
	flora = f


## Active la génération par zones (nouvelle Campagne Impériale ou chargement d'une campagne).
func start(g: WorldGenerator) -> void:
	gen = g
	enabled = true
	active = self
	if not world.block_changed.is_connected(_on_block):
		world.block_changed.connect(_on_block)
	world.keep_chunk = _keep


func _on_block(p: Vector3i, _o: int, _n: int) -> void:
	modified[region_of(p)] = true


func _keep(k: Vector3i) -> bool:
	return modified.has(Vector2i(floori(k.x * 16.0 / REGION), floori(k.z * 16.0 / REGION)))


## Zones déjà générées par le chargement initial (leur végétation est déjà dans Flora).
func mark_generated(rs: Array) -> void:
	for r: Vector2i in rs:
		loaded[r] = true
		flora_done[r] = true


static func region_of(p: Vector3i) -> Vector2i:
	return Vector2i(floori(p.x / float(REGION)), floori(p.z / float(REGION)))


func regions() -> Vector2i:
	return Vector2i(ceili(world.size.x / float(REGION)), ceili(world.size.z / float(REGION)))


func is_loaded(p: Vector3i) -> bool:
	return loaded.has(region_of(p))


## Hauteur du sol : réelle si la zone est chargée, sinon calculée par le générateur (sans rien générer).
static func surface(w: VoxelWorld, x: int, z: int) -> int:
	if active == null or not active.enabled or active.loaded.has(region_of(Vector3i(x, 0, z))):
		return w.surface_y(x, z)
	return active.gen.height_at(x, z)


## Génère tout de suite (chargement, placement des villages) les zones autour d'une case.
static func ensure_at(p: Vector3i, r: int = 1) -> void:
	if active == null or not active.enabled:
		return
	var c := region_of(p)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			active.generate_now(c + Vector2i(dx, dz))


func generate_now(r: Vector2i) -> void:
	var n := regions()
	if loaded.has(r) or r.x < 0 or r.y < 0 or r.x >= n.x or r.y >= n.y:
		return
	var before := gen.trees.size()
	var b0 := gen.bushes.size()
	var h0 := gen.herbs.size()
	gen.generate_region(r.x * REGION, r.y * REGION, (r.x + 1) * REGION, (r.y + 1) * REGION)
	_add_flora(r, gen.trees.slice(before), gen.bushes.slice(b0), gen.herbs.slice(h0))
	loaded[r] = true


func _add_flora(r: Vector2i, t: Array, b: Array, h: Array) -> void:
	if flora_done.has(r):
		return
	flora_done[r] = true
	for e: Dictionary in t:
		flora.trees[e["pos"]] = e["kind"]
	for e: Dictionary in b:
		flora.bushes[e["pos"]] = 0
	for e: Dictionary in h:
		flora.herbs[e["pos"]] = e["kind"]


## Demande les zones autour d'un point (les plus proches d'abord). À appeler souvent (caméra, lutins).
func request(center: Vector3, radius: float) -> void:
	var c := region_of(Vector3i(center))
	var rr := ceili(radius / REGION)
	var n := regions()
	for dx in range(-rr, rr + 1):
		for dz in range(-rr, rr + 1):
			var r := c + Vector2i(dx, dz)
			if (
				r.x < 0
				or r.y < 0
				or r.x >= n.x
				or r.y >= n.y
				or loaded.has(r)
				or _queue.has(r)
				or (r == _task_r and _task >= 0)
			):
				continue
			_queue.append(r)
	var f := Vector2(c)
	_queue.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return Vector2(a).distance_squared_to(f) < Vector2(b).distance_squared_to(f)
	)


## Chaque image : une zone à la fois sur un fil de travail, puis fusion rapide dans le monde.
func process() -> void:
	if not enabled:
		return
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		if merge_gate.is_valid() and not merge_gate.call():
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_merge()
	if _queue.is_empty():
		return
	_task_r = _queue.pop_front()
	if loaded.has(_task_r):
		return
	var tmp := VoxelWorld.new(world.size)
	_tmp_gen = WorldGenerator.new(tmp, gen.seed_value)
	_tmp_gen.preset = gen.preset
	var r := _task_r
	_task = WorkerThreadPool.add_task(
		func() -> void: _tmp_gen.generate_region(r.x * REGION, r.y * REGION, (r.x + 1) * REGION, (r.y + 1) * REGION)
	)


func _merge() -> void:
	var keys: Array = []
	for k: Vector3i in _tmp_gen.world.chunks:
		var fresh: Chunk = _tmp_gen.world.chunks[k]
		var old: Chunk = world.chunks.get(k)
		if old != null:  # blocs déjà posés là (bâtiment d'un voisin) : ils restent par-dessus le terrain
			for i in old.data.size():
				if old.data[i] != 0:
					fresh.data[i] = old.data[i]
			fresh.recount()
		world.chunks[k] = fresh
		keys.append(k)
	_add_flora(_task_r, _tmp_gen.trees, _tmp_gen.bushes, _tmp_gen.herbs)
	loaded[_task_r] = true
	_tmp_gen = null
	region_loaded.emit(keys)


## Fin de partie : attendre la zone en cours de génération (jamais de fil de travail orphelin).
func finish() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	_queue.clear()
	if active == self:
		active = null


## Oublie les zones loin de tout (jamais modifiées) pour garder la mémoire basse sur téléphone.
func unload_far(points: Array, keep: float) -> int:
	var n := 0
	for r: Vector2i in loaded.keys():
		if modified.has(r):
			continue
		var centre := Vector2((r.x + 0.5) * REGION, (r.y + 0.5) * REGION)
		var near := false
		for p: Vector3 in points:
			if centre.distance_to(Vector2(p.x, p.z)) < keep:
				near = true
				break
		if near:
			continue
		for k: Vector3i in world.chunks.keys():
			if floori(k.x * 16.0 / REGION) == r.x and floori(k.z * 16.0 / REGION) == r.y:
				world.chunks.erase(k)
		loaded.erase(r)
		n += 1
	return n


func to_dict() -> Dictionary:
	if not enabled:
		return {"enabled": false}
	var m := []
	for r: Vector2i in modified:
		m.append([r.x, r.y])
	var f := []
	for r: Vector2i in flora_done:
		f.append([r.x, r.y])
	return {"enabled": true, "seed": gen.seed_value, "preset": gen.preset, "modified": m, "flora": f}


func from_dict(d: Dictionary) -> void:
	if not bool(d.get("enabled", false)):
		enabled = false
		return
	var g := WorldGenerator.new(world, int(d.get("seed", 0)))
	g.preset = str(d.get("preset", ""))
	start(g)
	modified.clear()
	loaded.clear()
	for e: Array in d.get("modified", []):
		modified[Vector2i(int(e[0]), int(e[1]))] = true
		loaded[Vector2i(int(e[0]), int(e[1]))] = true  # ses blocs viennent de la sauvegarde
	flora_done.clear()
	for e: Array in d.get("flora", []):
		flora_done[Vector2i(int(e[0]), int(e[1]))] = true
	active = self
