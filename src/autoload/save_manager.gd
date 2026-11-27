extends Node
## Sauvegardes : chaque système enregistré fournit to_dict()/from_dict(). Fichiers JSON compressés dans user://saves/.

const SAVE_DIR := "user://saves/"
const VERSION := 1
const SLOTS := ["slot1", "slot2", "slot3", "slot4", "slot5"]

var _savables: Dictionary = {}
var current_slot: String = "slot1"  # emplacement de la partie en cours (sauvegarde auto et manuelle)
var meta_provider: Callable  # renvoie un résumé de la partie (nom, mode, jour, lutins) pour l'écran Charger


func _ready() -> void:
	# ancienne sauvegarde unique (1.0 à 1.2) → emplacement 1
	if FileAccess.file_exists(SAVE_DIR + "auto.sav") and not FileAccess.file_exists(SAVE_DIR + "slot1.sav"):
		DirAccess.rename_absolute(SAVE_DIR + "auto.sav", SAVE_DIR + "slot1.sav")


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


func save_game(slot: String = "") -> bool:
	if slot == "":
		slot = current_slot
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if meta_provider.is_valid():
		var mf := FileAccess.open(SAVE_DIR + slot + ".json", FileAccess.WRITE)
		if mf != null:
			var meta: Dictionary = meta_provider.call()
			meta["saved_at"] = Time.get_datetime_string_from_system(false, true)
			mf.store_string(JSON.stringify(meta))
			mf.close()
	Settings.set_value("last_slot", slot)
	var f := FileAccess.open_compressed(SAVE_DIR + slot + ".sav", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	f.store_string(JSON.stringify(build_snapshot()))
	f.close()
	EventBus.game_saved.emit(slot)
	return true


func load_game(slot: String = "") -> bool:
	if slot == "":
		slot = current_slot
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


func has_save(slot: String = "") -> bool:
	return FileAccess.file_exists(SAVE_DIR + (slot if slot != "" else current_slot) + ".sav")


## Résumé d'un emplacement (vide s'il est libre).
func slot_info(slot: String) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(SAVE_DIR + slot + ".json", FileAccess.READ)
	if f == null:
		return {"name": "Partie"}
	var d: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {"name": "Partie"}


func delete_slot(slot: String) -> void:
	for ext: String in [".sav", ".json"]:
		if FileAccess.file_exists(SAVE_DIR + slot + ext):
			DirAccess.remove_absolute(SAVE_DIR + slot + ext)


## Premier emplacement libre ("" si tout est pris).
func free_slot() -> String:
	for s: String in SLOTS:
		if not has_save(s):
			return s
	return ""


## Dernière partie jouée (pour « Continuer »), "" s'il n'y en a pas.
func last_slot() -> String:
	var s := str(Settings.get_value("last_slot"))
	if s != "" and s != "<null>" and has_save(s):
		return s
	for k: String in SLOTS:
		if has_save(k):
			return k
	return ""
