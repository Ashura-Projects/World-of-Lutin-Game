extends Node
## Sauvegardes : chaque système enregistré fournit to_dict()/from_dict(). Fichiers JSON compressés dans user://saves/.

const SAVE_DIR := "user://saves/"
const VERSION := 1

var _savables: Dictionary = {}


func register(key: String, obj: Object) -> void:
	_savables[key] = obj


func unregister(key: String) -> void:
	_savables.erase(key)


func build_snapshot() -> Dictionary:
	var data := {"version": VERSION, "rng": Rng.to_dict(), "clock": GameClock.to_dict(), "systems": {}}
	for key: String in _savables:
		data["systems"][key] = _savables[key].to_dict()
	return data


func apply_snapshot(data: Dictionary) -> void:
	Rng.from_dict(data.get("rng", {}))
	GameClock.from_dict(data.get("clock", {}))
	var systems: Dictionary = data.get("systems", {})
	for key: String in _savables:
		if systems.has(key):
			_savables[key].from_dict(systems[key])


func save_game(slot: String = "auto") -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open_compressed(SAVE_DIR + slot + ".sav", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	f.store_string(JSON.stringify(build_snapshot()))
	f.close()
	EventBus.game_saved.emit(slot)
	return true


func load_game(slot: String = "auto") -> bool:
	var path := SAVE_DIR + slot + ".sav"
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return false
	apply_snapshot(parsed)
	EventBus.game_loaded.emit(slot)
	return true


func has_save(slot: String = "auto") -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot + ".sav")
