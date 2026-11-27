class_name Village
extends RefCounted
## Gestion du village : rang (Campement → Hameau → Village → Bourg), objectifs facultatifs, bilan quotidien
## (production / consommation par jour), alertes (famine, froid, outils).

signal rank_changed(name: String)
signal objective_done(name: String)

var colony: Colony
var structures: Structures
var world: VoxelWorld
var rank_id: String = "camp"
var done: Dictionary = {}  # objectifs accomplis
var deaths_this_winter: int = 0
var last_stock: Dictionary = {}
var daily_delta: Dictionary = {}  # ressource -> variation sur la dernière journée
var alerts: Array[String] = []
var tower_height: int = 0


func _init(c: Colony, s: Structures, w: VoxelWorld) -> void:
	colony = c
	structures = s
	world = w


func built_count(kind: String = "") -> int:
	var n := 0
	for s: Dictionary in structures.items.values():
		if s["built"] and (kind == "" or s["kind"] == kind):
			n += 1
	return n


func compute_rank() -> String:
	var best := "camp"
	var rooms := 0
	for s: Dictionary in structures.built_with_tag("bed"):
		if not RoomDetector.room_at(world, structures, s["cell"]).is_empty():
			rooms += 1
	for r: Dictionary in DataRegistry.get_table("ranks").get("ranks", []):
		if (
			colony.lutins.size() >= int(r.get("pop", 0))
			and built_count() >= int(r.get("buildings", 0))
			and rooms >= int(r.get("rooms", 0))
		):
			best = r["id"]
	return best


func rank_name() -> String:
	return str(DataRegistry.find("ranks", "ranks", rank_id).get("name", rank_id))


func objective_ok(o: Dictionary) -> bool:
	match o["kind"]:
		"stock":
			return colony.stock.count(o["res"]) >= int(o["n"])
		"built":
			return built_count(o["what"]) >= int(o["n"])
		"pop":
			return colony.lutins.size() >= int(o["n"])
		"homes":
			return colony.lutins.all(func(l: Lutin) -> bool: return l.home.y >= 0)
		"kills":
			var k := 0
			for l in colony.lutins:
				k += int(l.kills.get(o["what"], 0))
			return k >= int(o["n"])
		"tower":
			return tower_height >= int(o["n"])
		"winter":
			return done.has("_winter_passed")
	return false


## Hauteur de la plus haute colonne construite (blocs avec coût) : pour l'objectif « tour ».
func on_block(p: Vector3i, _old: int, new_id: int) -> void:
	if new_id == 0 or not DataRegistry.block(new_id).has("cost"):
		return
	var h := 0
	var y := p.y
	while y >= 0 and DataRegistry.block(world.get_block(Vector3i(p.x, y, p.z))).has("cost"):
		h += 1
		y -= 1
	tower_height = maxi(tower_height, h)


func check() -> void:
	var r := compute_rank()
	if r != rank_id:
		rank_id = r
		rank_changed.emit(rank_name())
		EventBus.alert.emit("rang", "Le village devient : %s !" % rank_name())
	for o: Dictionary in DataRegistry.get_table("objectives").get("objectives", []):
		if not done.has(o["id"]) and objective_ok(o):
			done[o["id"]] = true
			objective_done.emit(o["name"])
			EventBus.alert.emit("objectif", "Objectif atteint : %s" % o["name"])


## Moral : base + logement (lit, pièce décorée) − froid (data/population.json, rooms.json).
func update_mood() -> void:
	var base := float(DataRegistry.get_table("population").get("needs", {}).get("mood", {}).get("base", 70))
	var dec: Dictionary = DataRegistry.get_table("rooms").get("decor", {})
	for l in colony.lutins:
		var m := base - (10.0 if l.home.y < 0 else 0.0)
		if l.home.y >= 0:
			var room := RoomDetector.room_at(world, structures, l.home)
			if not room.is_empty():
				var decor: int = mini(room["tags"].count("decor"), int(dec.get("max_items", 8)))
				m += 5.0 + decor * float(dec.get("mood_per_item", 2))
		if l.needs["warmth"] < 30.0:
			m -= float(
				DataRegistry.get_table("population").get("needs", {}).get("warmth", {}).get("cold_mood_penalty", 20)
			)
		if Realm.active != null:
			m += Realm.active.mood_for(l)  # lois, taxes, titre, seigneur, prison
		if Religion.active != null:
			m += Religion.active.mood_for(l)  # foi et dogmes
		l.needs["mood"] = clampf(m, 0.0, 100.0)


## Chaque matin : bilan de la veille et alertes.
func daily() -> void:
	update_mood()
	daily_delta.clear()
	for id: String in colony.stock.items:
		daily_delta[id] = colony.stock.count(id) - int(last_stock.get(id, 0))
	for id: String in last_stock:
		if not colony.stock.items.has(id):
			daily_delta[id] = -int(last_stock[id])
	last_stock = colony.stock.items.duplicate()
	alerts.clear()
	var food := colony.stock.food_total()
	if food < colony.lutins.size() * 3:
		alerts.append("Famine proche : %d de nourriture pour %d lutins" % [food, colony.lutins.size()])
	var cold := colony.lutins.filter(func(l: Lutin) -> bool: return l.needs["warmth"] < 30.0).size()
	if cold > 0:
		alerts.append("%d lutin(s) ont froid" % cold)
	for a in alerts:
		EventBus.alert.emit("alerte", a)
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	var season: String = seasons[GameClock.season_index()]["id"] if not seasons.is_empty() else ""
	if (
		season == "spring"
		and GameClock.day() > 0
		and GameClock.day() % (seasons.size() * int(DataRegistry.get_table("time").get("days_per_season", 5))) == 0
	):
		if deaths_this_winter == 0:
			done["_winter_passed"] = true
		deaths_this_winter = 0
	check()


func on_death() -> void:
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	if not seasons.is_empty() and seasons[GameClock.season_index()]["id"] == "winter":
		deaths_this_winter += 1


func to_dict() -> Dictionary:
	return {
		"rank": rank_id, "done": done, "winter_deaths": deaths_this_winter, "last": last_stock, "tower": tower_height
	}


func from_dict(d: Dictionary) -> void:
	rank_id = str(d.get("rank", "camp"))
	done = d.get("done", {})
	deaths_this_winter = int(d.get("winter_deaths", 0))
	last_stock = {}
	var ls: Dictionary = d.get("last", {})
	for k: String in ls:
		last_stock[k] = int(ls[k])
	tower_height = int(d.get("tower", 0))
