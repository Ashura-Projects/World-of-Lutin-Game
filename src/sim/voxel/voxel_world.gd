class_name VoxelWorld
extends RefCounted
## La grille de blocs 3D : c'est la vérité du monde. Le maillage n'en est qu'une représentation.

signal block_changed(pos: Vector3i, old_id: int, new_id: int)

var size: Vector3i  # x, y (hauteur), z
var chunks: Dictionary = {}  # Vector3i -> Chunk
var types: BlockTypes
var shapes: Dictionary = {}  # Vector3i -> forme × 4 + sens (escalier, demi-bloc, pente…) ; absent = cube
## Campagne Impériale : ne sauvegarder que certains chunks (zones modifiées). Vide = tout.
var keep_chunk: Callable


func _init(world_size: Vector3i = Vector3i(64, 32, 64)) -> void:
	size = world_size
	types = BlockTypes.new()


func in_bounds(p: Vector3i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.z >= 0 and p.x < size.x and p.y < size.y and p.z < size.z


static func chunk_key(p: Vector3i) -> Vector3i:
	return Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0))


func get_block(p: Vector3i) -> int:
	if not in_bounds(p):
		return 0
	var c: Chunk = chunks.get(chunk_key(p))
	if c == null:
		return 0
	return c.get_local(p.x & 15, p.y & 15, p.z & 15)


## Écriture brute (génération) : pas de signal.
func set_raw(p: Vector3i, id: int) -> void:
	if not in_bounds(p):
		return
	var k := chunk_key(p)
	var c: Chunk = chunks.get(k)
	if c == null:
		if id == 0:
			return
		c = Chunk.new(k)
		chunks[k] = c
	c.set_local(p.x & 15, p.y & 15, p.z & 15, id)


## Écriture en jeu : émet block_changed (remaillage, navigation, pièces…).
func set_block(p: Vector3i, id: int) -> bool:
	if not in_bounds(p):
		return false
	var old := get_block(p)
	if old == id:
		return false
	set_raw(p, id)
	shapes.erase(p)  # un nouveau bloc repart en cube (la forme est posée ensuite)
	block_changed.emit(p, old, id)
	return true


## Forme d'un bloc (0 = cube). code = forme × 4 + sens (0 à 3, quart de tour).
func get_shape(p: Vector3i) -> int:
	return int(shapes.get(p, 0))


func set_shape(p: Vector3i, code: int) -> void:
	if code <= 0 or get_block(p) == 0:
		shapes.erase(p)
	else:
		shapes[p] = code
	var id := get_block(p)
	block_changed.emit(p, id, id)


## Formes autour d'un chunk (chunk + bordure d'un bloc), copiées pour le maillage sur un thread.
func shapes_near(origin: Vector3i) -> Dictionary:
	var out := {}
	if shapes.is_empty():
		return out
	for p: Vector3i in shapes:
		var d := p - origin
		if d.x >= -1 and d.y >= -1 and d.z >= -1 and d.x <= 16 and d.y <= 16 and d.z <= 16:
			out[p] = shapes[p]
	return out


func is_solid(p: Vector3i) -> bool:
	return types.solid[get_block(p)] == 1


## Hauteur de la surface solide (première case libre au-dessus du sol), -1 si colonne vide.
func surface_y(x: int, z: int) -> int:
	for y in range(size.y - 1, -1, -1):
		if types.solid[get_block(Vector3i(x, y, z))] == 1:
			return y + 1
	return -1


func chunk_keys() -> Array:
	return chunks.keys()


## Clés des chunks touchés par un bloc (lui + voisins si le bloc est au bord).
static func affected_chunks(p: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = [chunk_key(p)]
	for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
		var k := chunk_key(p + d)
		if not out.has(k):
			out.append(k)
	return out


func to_dict() -> Dictionary:
	var cs := {}
	for k: Vector3i in chunks:
		var c: Chunk = chunks[k]
		if not c.is_empty() and (not keep_chunk.is_valid() or keep_chunk.call(k)):
			cs["%d,%d,%d" % [k.x, k.y, k.z]] = Marshalls.raw_to_base64(c.to_rle())
	var sh := []
	for p: Vector3i in shapes:
		sh.append([p.x, p.y, p.z, shapes[p]])
	return {"size": [size.x, size.y, size.z], "chunks": cs, "shapes": sh}


func from_dict(d: Dictionary) -> void:
	var s: Array = d.get("size", [size.x, size.y, size.z])
	size = Vector3i(int(s[0]), int(s[1]), int(s[2]))
	chunks.clear()
	var cs: Dictionary = d.get("chunks", {})
	for key_str: String in cs:
		var parts := key_str.split(",")
		var k := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		var c := Chunk.new(k)
		c.from_rle(Marshalls.base64_to_raw(cs[key_str]))
		chunks[k] = c
	shapes.clear()
	for e: Array in d.get("shapes", []):
		shapes[Vector3i(int(e[0]), int(e[1]), int(e[2]))] = int(e[3])
