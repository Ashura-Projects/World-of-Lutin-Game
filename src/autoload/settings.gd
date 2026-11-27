extends Node
## Réglages du joueur (son, graphismes, langue, taille des textes), stockés dans user://settings.cfg.

const PATH := "user://settings.cfg"

var values: Dictionary = {
	"music": 0.7,
	"effects": 0.8,
	"quality": "medium",  # préréglage graphique : low, medium, high, custom
	"shadows": "low",
	"view_distance": 128,
	"render_scale": 0.85,
	"aa": "fxaa",
	"fog": true,
	"fps_cap": 60,
	"vegetation": 0.8,
	"show_fps": false,
	"tutorial": true,
	"autosave_min": 5,
	"camera_speed": 1.0,
	"last_slot": "",
	"debug": false,  # menu débug caché (5 touchers dans le coin de l'accueil)
	"language": "fr",
	"text_size": "large",
	"music_mode": "all",  # all (toutes en boucle), shuffle (aléatoire), one (un seul morceau)
	"music_track": "",
	"playlist": [],  # morceaux cochés (vide = tous)
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


## Applique un préréglage graphique (low, medium, high) ; « custom » garde les choix.
func apply_preset(p: String) -> void:
	values["quality"] = p
	var pr: Dictionary = DataRegistry.get_table("graphics").get("presets", {}).get(p, {})
	for k: String in pr:
		values[k] = pr[k]
	save_settings()
	EventBus.settings_changed.emit()


func get_value(key: String) -> Variant:
	return values.get(key)


func set_value(key: String, v: Variant) -> void:
	values[key] = v
	save_settings()
	EventBus.settings_changed.emit()
