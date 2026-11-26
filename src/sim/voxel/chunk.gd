class_name Chunk
extends RefCounted
## Bloc de 16×16×16 cases ; un octet par case (id numérique du type de bloc, 0 = air).

const SIZE := 16
const VOLUME := SIZE * SIZE * SIZE

var key: Vector3i
var data := PackedByteArray()
var solid_count: int = 0


func _init(k: Vector3i = Vector3i.ZERO) -> void:
	key = k
	data.resize(VOLUME)


static func index(x: int, y: int, z: int) -> int:
	return x + z * SIZE + y * SIZE * SIZE


func get_local(x: int, y: int, z: int) -> int:
	return data[index(x, y, z)]


func set_local(x: int, y: int, z: int, id: int) -> void:
	var i := index(x, y, z)
	var old := data[i]
	if old == id:
		return
	if old == 0:
		solid_count += 1
	elif id == 0:
		solid_count -= 1
	data[i] = id


func is_empty() -> bool:
	return solid_count == 0


func recount() -> void:
	solid_count = 0
	for v in data:
		if v != 0:
			solid_count += 1


## Compression RLE (paires valeur, longueur ≤ 255) pour la sauvegarde.
func to_rle() -> PackedByteArray:
	var out := PackedByteArray()
	var i := 0
	while i < VOLUME:
		var v := data[i]
		var n := 1
		while i + n < VOLUME and data[i + n] == v and n < 255:
			n += 1
		out.append(v)
		out.append(n)
		i += n
	return out


func from_rle(rle: PackedByteArray) -> void:
	var i := 0
	for p in range(0, rle.size(), 2):
		for _k in rle[p + 1]:
			data[i] = rle[p]
			i += 1
	recount()
