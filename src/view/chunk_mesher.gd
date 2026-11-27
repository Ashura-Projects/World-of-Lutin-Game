class_name ChunkMesher
extends RefCounted
## Construit les tableaux de maillage d'un chunk : faces visibles seulement, UV dans l'atlas unique.
## Fonction pure (lecture seule du monde) : appelée sur un thread de travail.

# Pour chaque direction : normale, puis 4 coins (sens horaire vu de l'extérieur = face avant pour Godot).
const DIRS := [
	[Vector3i(0, 1, 0), [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)], 0],
	[Vector3i(0, -1, 0), [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)], 2],
	[Vector3i(1, 0, 0), [Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)], 1],
	[Vector3i(-1, 0, 0), [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(0, 0, 0)], 1],
	[Vector3i(0, 0, 1), [Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1), Vector3(0, 0, 1)], 1],
	[Vector3i(0, 0, -1), [Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0), Vector3(1, 0, 0)], 1],
]
const LIQUID_DROP := 0.12
const UV_INSET := 0.002


## Renvoie {"opaque": Array (ARRAY_MAX) ou [], "liquid": idem, "faces": int}.
## Optimisé : copie du chunk + bordure dans un tampon 18³, puis boucle sur des index entiers uniquement.
static func build(world: VoxelWorld, key: Vector3i, max_y: int = 9999, shapes: Dictionary = {}) -> Dictionary:
	var t := world.types
	var chunk: Chunk = world.chunks.get(key)
	var result := {"opaque": [], "liquid": [], "faces": 0}
	if chunk == null or chunk.is_empty():
		return result
	var origin := key * Chunk.SIZE
	var pad := _padded(world, chunk, origin, max_y)
	var liquid := t.liquid
	var invisible := t.invisible
	# « cache » : 1 si la case cache la face du voisin (bloc plein, non façonné, visible)
	var solid := PackedByteArray()
	solid.resize(256)
	for i in 256:
		solid[i] = 1 if t.solid[i] == 1 and invisible[i] == 0 else 0
	var shaped := PackedByteArray()
	shaped.resize(18 * 18 * 18)
	for p: Vector3i in shapes:
		var d := p - origin
		shaped[(d.x + 1) + (d.z + 1) * 18 + (d.y + 1) * 324] = 1
	var dshape := t.default_shape
	for i in pad.size():
		if dshape[pad[i]] > 0:
			shaped[i] = 1  # bloc façonné par défaut (créneau = demi-bloc)
	# décalages dans le tampon 18³ (x + 18 z + 324 y) pour les 6 directions de DIRS
	var offs := PackedInt32Array([324, -324, 1, -1, 18, -18])
	var acc := [_new_acc(), _new_acc()]
	var cols := float(t.atlas_cols)
	var rows := float(t.atlas_rows)
	var faces := 0
	for ly in Chunk.SIZE:
		for lz in Chunk.SIZE:
			var row := lx_base(lz, ly)
			for lx in Chunk.SIZE:
				var pi := row + lx
				var id := pad[pi]
				if id == 0 or invisible[id] == 1:
					continue
				if shaped[pi] == 1:
					var wpos := Vector3(origin.x + lx, origin.y + ly, origin.z + lz)
					var code: int = shapes.get(Vector3i(origin.x + lx, origin.y + ly, origin.z + lz), dshape[id] * 4)
					faces += ShapeMesh.add(
						acc[0], wpos, code, [t.tile_top[id], t.tile_side[id], t.tile_bottom[id]], cols, rows
					)
					if code / 4 == ShapeMesh.Shape.WINDOW_GLASS or code / 4 == ShapeMesh.Shape.WINDOW_STAINED:
						var gt := t.glass_tile if code / 4 == ShapeMesh.Shape.WINDOW_GLASS else t.stained_tile
						ShapeMesh.add_pane(acc[1], wpos, code, gt, cols, rows)
					continue
				var is_liq := liquid[id] == 1
				for di in 6:
					var nb := pad[pi + offs[di]]
					if (solid[nb] == 1 and shaped[pi + offs[di]] == 0) or (is_liq and nb == id):
						continue
					var d: Array = DIRS[di]
					var kind: int = d[2]
					var tile := t.tile_top[id] if kind == 0 else (t.tile_bottom[id] if kind == 2 else t.tile_side[id])
					var drop := LIQUID_DROP if (is_liq and pad[pi + 324] == 0) else 0.0
					var wp := Vector3(origin.x + lx, origin.y + ly, origin.z + lz)
					_add_face(acc[1 if is_liq else 0], wp, d[1], Vector3(d[0]), tile, cols, rows, drop)
					faces += 1
	result["faces"] = faces
	result["opaque"] = _to_arrays(acc[0])
	result["liquid"] = _to_arrays(acc[1])
	return result


## Index du début de la rangée (x = 0) dans le tampon 18³, pour (lz, ly) intérieurs.
static func lx_base(lz: int, ly: int) -> int:
	return 1 + (lz + 1) * 18 + (ly + 1) * 324


## Tampon 18×18×18 : le chunk au centre, la bordure lue chez les voisins ; au-dessus de max_y = air.
static func _padded(world: VoxelWorld, chunk: Chunk, origin: Vector3i, max_y: int) -> PackedByteArray:
	var pad := PackedByteArray()
	pad.resize(18 * 18 * 18)
	var src := chunk.data
	for ly in 16:
		if origin.y + ly >= max_y:
			break
		for lz in 16:
			var s0 := lz * 16 + ly * 256
			var d0 := lx_base(lz, ly)
			for lx in 16:
				pad[d0 + lx] = src[s0 + lx]
	for y in range(-1, 17):
		for z in range(-1, 17):
			for x in range(-1, 17):
				if x >= 0 and x < 16 and y >= 0 and y < 16 and z >= 0 and z < 16:
					continue
				var wy := origin.y + y
				if wy >= max_y:
					continue
				pad[(x + 1) + (z + 1) * 18 + (y + 1) * 324] = world.get_block(Vector3i(origin.x + x, wy, origin.z + z))
	return pad


static func _new_acc() -> Dictionary:
	return {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array()}


static func _add_face(
	a: Dictionary, base: Vector3, corners: Array, normal: Vector3, tile: int, cols: float, rows: float, drop: float
) -> void:
	var start: int = a["v"].size()
	var c := float(tile % int(cols))
	var r := float(tile / int(cols))
	var u0 := c / cols + UV_INSET
	var u1 := (c + 1.0) / cols - UV_INSET
	var v0 := r / rows + UV_INSET
	var v1 := (r + 1.0) / rows - UV_INSET
	var uvs := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
	for k in 4:
		var corner: Vector3 = corners[k]
		if drop > 0.0 and corner.y > 0.5:
			corner.y -= drop
		a["v"].append(base + corner)
		a["n"].append(normal)
		a["uv"].append(uvs[k])
	a["i"].append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))


static func _to_arrays(a: Dictionary) -> Array:
	if a["v"].is_empty():
		return []
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = a["v"]
	arr[Mesh.ARRAY_NORMAL] = a["n"]
	arr[Mesh.ARRAY_TEX_UV] = a["uv"]
	arr[Mesh.ARRAY_INDEX] = a["i"]
	return arr
