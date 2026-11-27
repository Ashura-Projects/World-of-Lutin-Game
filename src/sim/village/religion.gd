class_name Religion
extends RefCounted
## Religion (1.2) : les prêtres célèbrent des offices dans la chapelle ou l'église (la foi monte), marient
## les couples ; clergé : prêtre → cardinal → chef de culte. Avec au moins un cardinal et un chef de culte,
## on personnalise la religion (nom, symbole, 2 dogmes). Les prédicateurs vont dans les villages voisins :
## la foi des villageois monte ; à 100 % ils peuvent être recrutés. Valeurs : data/religion.json.

signal married(a: Lutin, b: Lutin)

static var active: Religion = null

var colony: Colony
var structures: Structures
var fauna: Fauna
var name: String = ""
var symbol: String = "soleil"
var color: String = "e8c440"
var dogmas: Array = []
var custom: bool = false
var clergy: Dictionary = {}  # id lutin -> priest / cardinal / leader
var preachers: Dictionary = {}  # id lutin -> id faction visée
var _cfg: Dictionary


func _init(c: Colony, s: Structures, f: Fauna) -> void:
	colony = c
	structures = s
	fauna = f
	_cfg = DataRegistry.get_table("religion")
	var d: Dictionary = _cfg.get("default", {})
	name = str(d.get("name", "Culte des Anciens"))
	symbol = str(d.get("symbol", "soleil"))
	color = str(d.get("color", "e8c440"))
	active = self


# --- lieux de culte et clergé --------------------------------------------------------------------
## Lieux de culte = pièces (chapelle, église, cathédrale) reconnues autour des autels (data/rooms.json).
func temples() -> Array:
	var out := []
	var seen := {}
	if colony.world == null:
		return out
	for s: Dictionary in structures.built_with_tag("altar"):
		var room := RoomDetector.room_at(colony.world, structures, s["cell"])
		if room.is_empty() or seen.has(room["cells"].keys()[0]):
			continue
		var t := str(room["type"])
		if t in ["chapel_room", "church_room", "cathedral_room"]:
			seen[room["cells"].keys()[0]] = true
			out.append(t)
	return out


func capacity() -> int:
	var n := 0
	for t: String in temples():
		n += int(DataRegistry.find("rooms", "room_types", t).get("faith_capacity", 10))
	var cap: Dictionary = _cfg.get("capacity", {})
	for k: String in ["chapel", "church"]:  # anciens bâtiments entiers (parties d'avant la 1.3.1)
		n += structures.built_with_tag(k).size() * int(cap.get(k, 0))
	return n


func has_temple() -> bool:
	return capacity() > 0


func rank_name(id: String) -> String:
	for r: Dictionary in _cfg.get("ranks", []):
		if r["id"] == id:
			return str(r["name"])
	return id


## Ordonner prêtre (il faut une chapelle ou une église) ; il quitte son métier pour « prêtre ».
func ordain(l: Lutin) -> bool:
	if not has_temple() or not l.can_work() or clergy.has(l.id):
		return false
	l.trained["priest"] = 1.0
	if not colony.change_job(l, "priest"):
		return false
	clergy[l.id] = "priest"
	return true


## Prêtre → cardinal → chef de culte (un seul chef).
func promote(l: Lutin) -> bool:
	var r := str(clergy.get(l.id, ""))
	if r == "priest":
		clergy[l.id] = "cardinal"
		return true
	if r == "cardinal" and not clergy.values().has("leader"):
		clergy[l.id] = "leader"
		return true
	return false


func count_rank(r: String) -> int:
	return clergy.values().count(r)


func can_customize() -> bool:
	var need: Dictionary = _cfg.get("customize_needs", {})
	return (
		count_rank("cardinal") >= int(need.get("cardinals", 1)) and count_rank("leader") >= int(need.get("leader", 1))
	)


func customize(new_name: String, new_symbol: String, new_dogmas: Array) -> bool:
	if not can_customize():
		return false
	name = new_name.strip_edges().substr(0, 32) if new_name.strip_edges() != "" else name
	symbol = new_symbol
	dogmas = new_dogmas.slice(0, int(_cfg.get("max_dogmas", 2)))
	custom = true
	return true


# --- effets des dogmes ---------------------------------------------------------------------------
func _dogma_product(key: String) -> float:
	var m := 1.0
	for d: Dictionary in _cfg.get("dogmas", []):
		if dogmas.has(d["id"]) and d.has(key):
			m *= float(d[key])
	return m


func work_mult() -> float:
	return _dogma_product("work_mult")


func food_mult() -> float:
	return _dogma_product("food_mult")


func damage_mult() -> float:
	return _dogma_product("damage_mult")


func birth_mult() -> float:
	return _dogma_product("birth_mult")


func mood_for(l: Lutin) -> float:
	var m := 0.0
	if l.faith >= float(_cfg.get("faith_mood_from", 50)):
		m += float(_cfg.get("faith_mood", 5))
		for d: Dictionary in _cfg.get("dogmas", []):
			if dogmas.has(d["id"]):
				m += float(d.get("mood", 0))
	return m


# --- journée : offices, mariages -----------------------------------------------------------------
func daily() -> void:
	var priests := colony.lutins.filter(func(l: Lutin) -> bool: return clergy.has(l.id) and not preachers.has(l.id))
	var cap := capacity() if not priests.is_empty() else 0
	var gain := float(_cfg.get("faith_per_day_office", 12)) * (1.0 + _bells())
	var flock := colony.lutins.duplicate()
	flock.sort_custom(func(a: Lutin, b: Lutin) -> bool: return a.faith < b.faith)
	for i in flock.size():
		var l: Lutin = flock[i]
		if i < cap:
			l.faith = minf(100.0, l.faith + gain)
		else:
			l.faith = maxf(0.0, l.faith - float(_cfg.get("faith_decay_per_day", 2)))
	_marriages()


func _bells() -> float:
	return structures.built_with_tag("bell").size() * float(_cfg.get("bell_bonus", 0.1))


## Mariages : deux adultes célibataires de sexe différent, de bon moral ; plus fréquents avec un lieu de culte.
func _marriages() -> void:
	var m: Dictionary = _cfg.get("marriage", {})
	var chance := float(m.get("chance_per_day", 0.06)) * (float(m.get("chapel_mult", 2.0)) if has_temple() else 1.0)
	var singles := colony.lutins.filter(
		func(l: Lutin) -> bool:
			return (
				l.spouse < 0
				and l.age_stage() == "adult"
				and l.jailed.y < 0
				and l.needs["mood"] >= float(m.get("min_mood", 45))
			)
	)
	for a: Lutin in singles:
		if a.sex != "f" or a.spouse >= 0 or not Rng.chance(chance):
			continue
		for b: Lutin in singles:
			if b.sex == "m" and b.spouse < 0 and not Kinship.close_kin(colony, a, b):
				marry(a, b)
				break


func marry(a: Lutin, b: Lutin) -> void:
	a.spouse = b.id
	b.spouse = a.id
	if a.home.y >= 0 and b.home != a.home:
		b.home = a.home  # le couple partage le même foyer
	var where := " à la chapelle" if has_temple() else ""
	EventBus.alert.emit("naissance", "%s et %s se marient%s !" % [a.name, b.name, where])
	married.emit(a, b)


# --- prédication chez les voisins ----------------------------------------------------------------
func send_preacher(l: Lutin, faction: String) -> bool:
	if not clergy.has(l.id) or Rivals.active == null or not Rivals.active.states.has(faction):
		return false
	preachers[l.id] = faction
	return LutinOrders.give(
		colony, colony.task_board, l, "move", Rivals.active.states[faction]["center"], {"hold_s": 100000.0}
	)


func recall(l: Lutin) -> void:
	preachers.erase(l.id)
	LutinOrders.give(colony, colony.task_board, l, "move", colony.stock.pos)


## Chaque seconde : un prédicateur arrivé au village voisin fait monter la foi des villageois autour de lui.
func tick_second() -> void:
	if preachers.is_empty():
		return
	var rate := float(_cfg.get("preach_per_day", 20)) / float(GameClock.ticks_per_day()) * GameClock.ticks_per_second()
	rate *= _dogma_product("convert_mult")
	var r := float(_cfg.get("preach_radius", 16))
	for id: int in preachers.keys():
		var p := colony.find_lutin(id)
		if p == null:
			preachers.erase(id)
			continue
		var f: String = preachers[id]
		for a in fauna.animals:
			if a["kind"] == "villager_" + f and Vector3(a["cell"]).distance_to(Vector3(p.cell)) <= r:
				a["faith"] = minf(100.0, float(a.get("faith", 0.0)) + rate)


## Villageois voisins à 100 % de foi : ils peuvent rejoindre le village.
func converts() -> Array:
	return fauna.animals.filter(
		func(a: Dictionary) -> bool:
			return str(a["kind"]).begins_with("villager_") and float(a.get("faith", 0.0)) >= 100.0
	)


func recruit(a: Dictionary) -> Lutin:
	if Rivals.active == null or float(a.get("faith", 0.0)) < 100.0:
		return null
	var f := str(a.get("faction", ""))
	var l := Rivals.active.recruit(a)
	l.faith = 100.0
	if Realm.active != null and Realm.active.relations.has(f):
		var r: Dictionary = Realm.active.relations[f]
		r["relation"] = float(r["relation"]) - float(_cfg.get("recruit_relation_cost", 5))
	var st: Dictionary = Rivals.active.states.get(f, {})
	if not st.is_empty():
		st["population"] = maxi(0, int(st["population"]) - 1)
	EventBus.alert.emit("naissance", "%s, converti(e), rejoint votre village !" % l.name)
	return l


func to_dict() -> Dictionary:
	var c := {}
	for k: int in clergy:
		c[str(k)] = clergy[k]
	var p := {}
	for k: int in preachers:
		p[str(k)] = preachers[k]
	return {
		"name": name, "symbol": symbol, "color": color, "dogmas": dogmas, "custom": custom, "clergy": c, "preachers": p
	}


func from_dict(d: Dictionary) -> void:
	name = str(d.get("name", name))
	symbol = str(d.get("symbol", symbol))
	color = str(d.get("color", color))
	dogmas = Array(d.get("dogmas", []))
	custom = bool(d.get("custom", false))
	clergy.clear()
	var c: Dictionary = d.get("clergy", {})
	for k: String in c:
		clergy[int(k)] = str(c[k])
	preachers.clear()
	var p: Dictionary = d.get("preachers", {})
	for k: String in p:
		preachers[int(k)] = str(p[k])
	active = self
