class_name Research
extends RefCounted
## Technologies : points produits par les chercheurs ; le joueur choisit la prochaine ; effets et déblocages.

static var active: Research = null  # partie en cours (pour lire les bonus depuis les systèmes)

var unlocked: Dictionary = {}
var current: String = ""
var points: float = 0.0


func _init() -> void:
	active = self


static func tech(id: String) -> Dictionary:
	return DataRegistry.find("technologies", "technologies", id)


func available() -> Array:
	var out := []
	for t: Dictionary in DataRegistry.get_table("technologies").get("technologies", []):
		if unlocked.has(t["id"]):
			continue
		if t.get("requires", []).all(func(r: String) -> bool: return unlocked.has(r)):
			out.append(t)
	return out


func choose(id: String) -> bool:
	for t: Dictionary in available():
		if t["id"] == id:
			current = id
			return true
	return false


func add_points(n: float) -> void:
	if current == "":
		var av := available()
		if av.is_empty():
			return
		current = av[0]["id"]
	points += n * (1.0 + bonus("research_speed"))
	var cost := float(tech(current).get("cost", 100))
	if points >= cost:
		points -= cost
		unlocked[current] = true
		EventBus.alert.emit("recherche", "Technologie découverte : %s" % tech(current).get("name", current))
		current = ""


## Somme des effets débloqués (ex. crop_yield : +0.3 avec la charrue).
func bonus(effect: String) -> float:
	var b := 0.0
	for id: String in unlocked:
		b += float(tech(id).get("effect", {}).get(effect, 0.0))
	return b


static func get_bonus(effect: String) -> float:
	return active.bonus(effect) if active != null else 0.0


## Un bâtiment ou un bloc est-il bloqué par une technologie pas encore découverte ?
static func is_locked(id: String) -> bool:
	for t: Dictionary in DataRegistry.get_table("technologies").get("technologies", []):
		if t.get("unlocks", []).has(id):
			return active == null or not active.unlocked.has(t["id"])
	return false


func to_dict() -> Dictionary:
	return {"unlocked": unlocked.keys(), "current": current, "points": points}


func from_dict(d: Dictionary) -> void:
	unlocked.clear()
	for id: String in d.get("unlocked", []):
		unlocked[id] = true
	current = str(d.get("current", ""))
	points = float(d.get("points", 0.0))
	active = self
