extends Node
## Charge tous les fichiers data/*.json (équilibrage). Aucune valeur de jeu n'est écrite en dur dans le code.

const DATA_DIR := "res://data/"

var tables: Dictionary = {}
var blocks_by_id: Dictionary = {}
var blocks_by_num: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	tables.clear()
	var dir := DirAccess.open(DATA_DIR)
	if dir == null:
		push_error("DataRegistry : dossier data introuvable")
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_DIR + file_name))
			if parsed == null:
				push_error("DataRegistry : JSON invalide " + file_name)
				continue
			tables[file_name.get_basename()] = parsed
	_index_blocks()


func _index_blocks() -> void:
	blocks_by_id.clear()
	blocks_by_num.clear()
	for b: Dictionary in get_table("blocks").get("blocks", []):
		blocks_by_id[b["id"]] = b
		blocks_by_num[int(b["num"])] = b


func get_table(table_name: String) -> Dictionary:
	return tables.get(table_name, {})


func value(table_name: String, key: String, default: Variant = null) -> Variant:
	return get_table(table_name).get(key, default)


func block_num(id: String) -> int:
	return int(blocks_by_id[id]["num"]) if blocks_by_id.has(id) else 0


func block(num: int) -> Dictionary:
	return blocks_by_num.get(num, {})


func find(table_name: String, list_key: String, id: String) -> Dictionary:
	for item: Dictionary in get_table(table_name).get(list_key, []):
		if item.get("id", "") == id:
			return item
	return {}
