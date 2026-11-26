class_name Faction
extends RefCounted
## La faction du joueur : nom, devise, couleurs et emblème (sauvegardés ; utilisés par fanions et uniforme).

static var current: Faction = null

var name: String = ""
var motto: String = ""
var color1: String = "2c4a96"
var color2: String = "c49e54"
var symbol_color: String = "f0e6cc"
var shape: String = "ecu"
var division: String = "plain"
var symbol: String = "arbre"


func _init(d: Dictionary = {}) -> void:
	from_dict(d if not d.is_empty() else DataRegistry.get_table("faction").get("default", {}))
	current = self


func set_name_text(t: String) -> void:
	name = t.strip_edges().substr(0, int(DataRegistry.get_table("faction").get("name_max", 28)))


func set_motto_text(t: String) -> void:
	motto = t.strip_edges().substr(0, int(DataRegistry.get_table("faction").get("motto_max", 40)))


## Passe à la valeur suivante d'une liste de data/faction.json (couleur, forme, partition, symbole).
func cycle(field: String, step: int = 1) -> void:
	var cfg := DataRegistry.get_table("faction")
	var list: Array = []
	if field.begins_with("color") or field == "symbol_color":
		list = cfg.get("colors", [])
	else:
		for e: Dictionary in cfg.get(field + "s" if field != "division" else "divisions", []):
			list.append(e["id"])
	if list.is_empty():
		return
	var cur: String = get(field)
	var i := list.find(cur)
	set(field, list[(i + step + list.size()) % list.size()])


func to_dict() -> Dictionary:
	return {
		"name": name,
		"motto": motto,
		"color1": color1,
		"color2": color2,
		"symbol_color": symbol_color,
		"shape": shape,
		"division": division,
		"symbol": symbol
	}


func from_dict(d: Dictionary) -> void:
	var def: Dictionary = DataRegistry.get_table("faction").get("default", {})
	for k: String in ["name", "motto", "color1", "color2", "symbol_color", "shape", "division", "symbol"]:
		set(k, str(d.get(k, def.get(k, ""))))
	current = self
