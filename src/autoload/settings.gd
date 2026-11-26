extends Node
## Réglages du joueur (son, graphismes, langue, taille des textes), stockés dans user://settings.cfg.

const PATH := "user://settings.cfg"

var values: Dictionary = {
	"music": 0.7,
	"effects": 0.8,
	"quality": "medium",
	"language": "fr",
	"text_size": "large",
}


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key: String in values:
		values[key] = cfg.get_value("settings", key, values[key])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(PATH)


func get_value(key: String) -> Variant:
	return values.get(key)


func set_value(key: String, v: Variant) -> void:
	values[key] = v
	save_settings()
