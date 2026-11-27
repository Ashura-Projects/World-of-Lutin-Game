class_name TutorialMissions
extends RefCounted
## Tutoriel à missions (mode « tutorial ») : une mission à la fois, vérifiée automatiquement
## (data/missions.json) ; à la fin, on peut continuer la partie.

signal mission_done(title: String)
signal all_done

var sim: GameSim
var index: int = 0
var base: Dictionary = {}  # valeurs au début de la mission (stock, zones explorées…)
var finished: bool = false


func _init(s: GameSim) -> void:
	sim = s


func missions() -> Array:
	return DataRegistry.get_table("missions").get("missions", [])


func current() -> Dictionary:
	return missions()[index] if index < missions().size() else {}


## Démarre la mission courante (point de départ des compteurs, apparitions éventuelles).
func start_current() -> void:
	var m := current()
	if m.is_empty():
		return
	base = {
		"stock": sim.colony.stock.count(str(m.get("res", ""))),
		"explored": sim.territory.explored.size(),
		"kills": _kills(str(m.get("what", "")))
	}
	var sp: Dictionary = m.get("spawn", {})
	for kind: String in sp:
		for i in int(sp[kind]):
			var c := sim.colony.stock.pos + Vector3i(14 + i * 2, 0, 10)
			DebugTools.spawn_animal(sim, kind, Vector3i(c.x, sim.world.surface_y(c.x, c.z), c.z))


func _kills(what: String) -> int:
	var k := 0
	for l in sim.colony.lutins:
		k += int(l.kills.get(what, 0))
	return k


## Avancement de la mission courante : [fait, objectif].
func progress() -> Array:
	var m := current()
	if m.is_empty():
		return [1, 1]
	var n := int(m.get("n", 1))
	var v := 0
	match str(m["kind"]):
		"stock_gain":
			v = sim.colony.stock.count(str(m["res"])) - int(base.get("stock", 0))
		"built":
			v = (
				sim
				. structures
				. items
				. values()
				. filter(func(s: Dictionary) -> bool: return s["built"] and s["kind"] == m["what"])
				. size()
			)
		"store_zone":
			v = sim.colony.stores.zones.size()
		"home_in_room":
			for l in sim.colony.lutins:
				if l.home.y >= 0 and not RoomDetector.room_at(sim.world, sim.structures, l.home).is_empty():
					v += 1
		"sown":
			v = (
				sim
				. fields
				. plots
				. values()
				. filter(func(f: Dictionary) -> bool: return str(f.get("state", "")) in ["sown", "ripe"])
				. size()
			)
		"kills":
			v = _kills(str(m["what"])) - int(base.get("kills", 0))
		"explored":
			v = sim.territory.explored.size() - int(base.get("explored", 0))
	return [clampi(v, 0, n), n]


## Vérifié régulièrement : passe à la mission suivante quand l'objectif est atteint.
func check() -> void:
	if finished or current().is_empty():
		return
	var p := progress()
	if p[0] >= p[1]:
		var title := str(current()["title"])
		EventBus.alert.emit("objectif", "Mission réussie : %s" % title)
		mission_done.emit(title)
		index += 1
		if current().is_empty():
			finished = true
			all_done.emit()
		else:
			start_current()


func to_dict() -> Dictionary:
	return {"index": index, "base": base, "finished": finished}


func from_dict(d: Dictionary) -> void:
	index = int(d.get("index", 0))
	base = d.get("base", {})
	finished = bool(d.get("finished", false))
