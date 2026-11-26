class_name BlockTypes
extends RefCounted
## Propriétés des blocs lues dans data/blocks.json, rangées par id numérique (tableaux rapides pour le maillage).

const AIR := 0

var solid := PackedByteArray()
var liquid := PackedByteArray()
var tile_top := PackedInt32Array()
var tile_side := PackedInt32Array()
var tile_bottom := PackedInt32Array()
var speed := PackedFloat32Array()  # multiplicateur de marche (routes)
var ids: Dictionary = {}
var atlas_cols: int = 8
var atlas_rows: int = 4


func _init() -> void:
	solid.resize(256)
	liquid.resize(256)
	tile_top.resize(256)
	tile_side.resize(256)
	tile_bottom.resize(256)
	speed.resize(256)
	speed.fill(1.0)
	var atlas := DataRegistry.get_table("atlas")
	atlas_cols = int(atlas.get("cols", 8))
	atlas_rows = int(atlas.get("rows", 4))
	var tiles: Dictionary = atlas.get("tiles", {})
	for b: Dictionary in DataRegistry.get_table("blocks").get("blocks", []):
		var n := int(b["num"])
		ids[b["id"]] = n
		solid[n] = 1 if b.get("solid", false) else 0
		speed[n] = float(b.get("speed_mult", 1.0))
		liquid[n] = 1 if b.get("liquid", false) else 0
		var t: Dictionary = b.get("tiles", {})
		tile_top[n] = _tile_index(tiles, t.get("top", ""))
		tile_side[n] = _tile_index(tiles, t.get("side", ""))
		tile_bottom[n] = _tile_index(tiles, t.get("bottom", ""))


func _tile_index(tiles: Dictionary, name: String) -> int:
	if not tiles.has(name):
		return 0
	var cr: Array = tiles[name]
	return int(cr[0]) + int(cr[1]) * atlas_cols


func num(id: String) -> int:
	return int(ids.get(id, 0))


## Un bloc opaque cache la face de son voisin (l'eau ne cache que l'eau).
func is_opaque(n: int) -> bool:
	return solid[n] == 1
