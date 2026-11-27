class_name Realm
extends RefCounted
## Royaume (1.1) : titres et promotions, seigneur (salle du trône), prison (cages), lois et taxes,
## diplomatie avec les voisins, soldats de garnison et entraînement sur le sol d'entraînement.
## Toutes les valeurs : data/realm.json.

static var active: Realm = null

var colony: Colony
var structures: Structures
var world: VoxelWorld
var lord_id: int = -1
var tax: String = "low"
var laws: Dictionary = {}  # id -> true
var relations: Dictionary = {}  # id faction -> {"relation": float, "status": String}
var training_cells: Dictionary = {}  # case au-dessus d'un sol d'entraînement -> true
var gold_frac: float = 0.0
var _cfg: Dictionary
var _training_block: int = -1


func _init(c: Colony, s: Structures, w: VoxelWorld) -> void:
	colony = c
	structures = s
	world = w
	_cfg = DataRegistry.get_table("realm")
	tax = str(_cfg.get("tax", {}).get("default", "low"))
	_training_block = w.types.num("training_ground")
	for f: Dictionary in _cfg.get("diplomacy", {}).get("factions", []):
		relations[f["id"]] = {"relation": float(f.get("relation", 0)), "status": str(f.get("status", "neutral"))}
	w.block_changed.connect(_on_block)
	active = self


# --- titres et seigneur ------------------------------------------------------------------------
func titles() -> Array:
	return _cfg.get("titles", [])


func title_name(l: Lutin) -> String:
	if l.id == lord_id:
		return "Seigneur" if l.sex == "m" else "Dame"
	for t: Dictionary in titles():
		if t["id"] == l.title:
			return t["name"]
	return l.title


## Promouvoir (+1) ou rétrograder (−1) d'un titre. Renvoie le nouveau titre.
func promote(l: Lutin, step: int = 1) -> String:
	var ids := titles().map(func(t: Dictionary) -> String: return t["id"])
	var i := clampi(ids.find(l.title) + step, 0, ids.size() - 1)
	l.title = ids[i]
	return l.title


func throne_room_ok() -> bool:
	for s: Dictionary in structures.built_with_tag("throne"):
		if RoomDetector.room_at(world, structures, s["cell"]).get("type", "") == "throne_room":
			return true
	return false


func set_lord(l: Lutin) -> bool:
	if l == null or not throne_room_ok() or l.jailed.y >= 0:
		return false
	lord_id = l.id
	EventBus.alert.emit("faction", "%s devient %s du village." % [l.name, title_name(l)])
	return true


# --- prison --------------------------------------------------------------------------------------
func free_cages() -> Array:
	var out := []
	for s: Dictionary in structures.built_with_tag("cage"):
		var used := false
		for l in colony.lutins:
			if l.jailed == s["cell"]:
				used = true
		if not used:
			out.append(s)
	return out


func imprison(l: Lutin) -> bool:
	var cages := free_cages()
	if cages.is_empty() or l.id == lord_id:
		return false
	if colony.task_board != null:
		colony.task_board.call("release", l)
	l.order = {}
	l.mobilized = false
	l.jailed = cages[0]["cell"]
	EventBus.alert.emit("faction", "%s est mis en cage." % l.name)
	return true


func release_prisoner(l: Lutin) -> void:
	l.jailed = Vector3i(-1, -1, -1)
	l.state = Lutin.State.IDLE


func prisoners() -> Array:
	return colony.lutins.filter(func(l: Lutin) -> bool: return l.jailed.y >= 0)


# --- lois et taxes -------------------------------------------------------------------------------
func law_on(id: String) -> bool:
	return laws.has(id)


func toggle_law(id: String) -> void:
	if laws.has(id):
		laws.erase(id)
	else:
		laws[id] = true


func _law_product(key: String) -> float:
	var m := 1.0
	for law: Dictionary in _cfg.get("laws", []):
		if laws.has(law["id"]) and law.has(key):
			m *= float(law[key])
	return m


func work_mult() -> float:
	return _law_product("work_mult")


func food_mult() -> float:
	return _law_product("food_mult")


func train_mult() -> float:
	return _law_product("train_mult")


func tax_level() -> Dictionary:
	for t: Dictionary in _cfg.get("tax", {}).get("levels", []):
		if t["id"] == tax:
			return t
	return {}


## Bonus/malus de moral d'un lutin (ajouté au calcul du moral du village).
func mood_for(l: Lutin) -> float:
	var m := float(tax_level().get("mood", 0))
	for law: Dictionary in _cfg.get("laws", []):
		if laws.has(law["id"]):
			m += float(law.get("mood", 0))
	for t: Dictionary in titles():
		if t["id"] == l.title:
			m += float(t.get("mood", 0))
	var lord: Dictionary = _cfg.get("lord", {})
	if lord_id >= 0 and colony.find_lutin(lord_id) != null:
		m += float(lord.get("lord_mood", 15)) if l.id == lord_id else float(lord.get("mood_all", 4))
	var pr: Dictionary = _cfg.get("prison", {})
	if l.jailed.y >= 0:
		m += float(pr.get("mood_per_day", -20))
	else:
		m += float(pr.get("village_mood_per_prisoner", -1)) * prisoners().size()
	return m


# --- diplomatie ----------------------------------------------------------------------------------
## Voisins : ceux présents sur la carte (Rivals), sinon la liste de data/realm.json (voisins lointains).
func neighbours() -> Array:
	var all: Array = _cfg.get("diplomacy", {}).get("factions", [])
	if Rivals.active == null or Rivals.active.states.is_empty():
		return all
	return all.filter(func(f: Dictionary) -> bool: return Rivals.active.is_met(f["id"]))


func relation(id: String) -> float:
	return float(relations.get(id, {}).get("relation", 0))


func status(id: String) -> String:
	return str(relations.get(id, {}).get("status", "neutral"))


func status_name(id: String) -> String:
	return str(_cfg.get("diplomacy", {}).get("statuses", {}).get(status(id), status(id)))


## Actions diplomatiques : gift, treaty, peace, war, insult. Renvoie un message pour le joueur.
func diplomacy(id: String, action: String) -> String:
	if not relations.has(id):
		return ""
	var d: Dictionary = _cfg.get("diplomacy", {})
	var r: Dictionary = relations[id]
	var msg := ""
	if status(id) == "conquered":
		return "Ce village est déjà à vous."
	var rv := Rivals.active
	match action:
		"gift":
			var cost := int(d.get("gift_gold", 20))
			if colony.stock.count("gold") < cost:
				msg = "Pas assez d'or (%d)." % cost
			else:
				colony.stock.take("gold", cost)
				r["relation"] = minf(100.0, float(r["relation"]) + float(d.get("gift_relation", 10)))
				msg = "Cadeau envoyé : relation %+d." % int(d.get("gift_relation", 10))
		"treaty":
			if status(id) == "war":
				msg = "Il faut d'abord faire la paix."
			elif float(r["relation"]) < float(d.get("treaty_min", 30)):
				msg = "Ils refusent : relation trop basse (%d requis)." % int(d.get("treaty_min", 30))
			else:
				r["status"] = "trade"
				msg = "Accord commercial signé : meilleurs prix chez le marchand."
		"peace":
			var offer: bool = rv != null and bool(rv.states.get(id, {}).get("peace_offer", false))
			if float(r["relation"]) < 0.0 and not offer:
				msg = "Ils refusent la paix : relation négative."
			else:
				r["status"] = "peace"
				r["relation"] = maxf(float(r["relation"]), 0.0)
				if rv != null:
					rv.on_peace(id)
				msg = "La paix est signée."
		"alliance":
			if status(id) == "war" or float(r["relation"]) < float(d.get("alliance_min", 70)):
				msg = "Ils refusent l'alliance : relation trop basse (%d requis)." % int(d.get("alliance_min", 70))
			else:
				r["status"] = "alliance"
				msg = "Alliance conclue !"
		"war":
			r["status"] = "war"
			r["relation"] = minf(float(r["relation"]), -20.0)
			if rv != null:
				rv.on_war(id)
			msg = "Vous avez déclaré la guerre : conquérez leur village avec vos soldats."
		"insult":
			r["relation"] = maxf(-100.0, float(r["relation"]) + float(d.get("insult_relation", -15)))
			msg = "Votre messager les a insultés."
	return msg


## Bonus de prix du marchand grâce aux accords commerciaux.
func trade_bonus() -> float:
	var b := 0.0
	for f: Dictionary in neighbours():
		if status(f["id"]) in ["trade", "alliance"]:
			b += float(f.get("price_bonus_trade", 0.1))
	return minf(b, 0.3)


# --- soldats, garnison, entraînement -------------------------------------------------------------
func soldiers() -> Array:
	var job := str(_cfg.get("military", {}).get("soldier_job", "soldier"))
	return colony.lutins.filter(func(l: Lutin) -> bool: return l.job == job)


## Places de soldats : quelques-unes sans garnison, puis une par lit dans une pièce « Garnison ».
func garrison_capacity() -> int:
	var m: Dictionary = _cfg.get("military", {})
	var n := int(m.get("max_soldiers_without_garrison", 2))
	for s: Dictionary in structures.built_with_tag("bed"):
		if RoomDetector.room_at(world, structures, s["cell"]).get("type", "") == "garrison":
			n += int(m.get("soldier_per_bed", 1))
	return n


func enroll(l: Lutin) -> bool:
	if not l.can_work() or soldiers().size() >= garrison_capacity() or l.jailed.y >= 0:
		return false
	l.trained["soldier"] = maxf(float(l.trained.get("soldier", 0.0)), 1.0)
	var ok := colony.change_job(l, str(_cfg.get("military", {}).get("soldier_job", "soldier")))
	if ok and colony.combat != null:
		colony.combat.call("equip", l)  # le soldat garde arme et armure (il tire depuis son poste)
	return ok


func discharge(l: Lutin) -> void:
	colony.change_job(l, "hauler")
	if l.weapon != "":
		colony.stock.add(l.weapon, 1)
		l.weapon = ""
	if l.armor != "":
		colony.stock.add(l.armor, 1)
		l.armor = ""


func _on_block(cell: Vector3i, _old: int, new: int) -> void:
	if _training_block < 0:
		return
	if new == _training_block:
		training_cells[cell + Vector3i.UP] = true
	else:
		training_cells.erase(cell + Vector3i.UP)


## Soldat sans tâche : il va s'entraîner sur le sol d'entraînement le plus proche (XP de combat).
func soldier_idle(l: Lutin) -> bool:
	if l.job != str(_cfg.get("military", {}).get("soldier_job", "soldier")) or training_cells.is_empty():
		return false
	var best := Vector3i(-1, -1, -1)
	var bd := float(_cfg.get("training", {}).get("search_radius", 40)) ** 2
	for c: Vector3i in training_cells:
		var d := Vector3(c).distance_squared_to(Vector3(l.cell))
		if d < bd:
			bd = d
			best = c
	if best.y < 0:
		return false
	if Colony._near(l.cell, best, 1):
		l.state = Lutin.State.WORK
		l.wait_ticks = 5 * GameClock.ticks_per_second()
		var rate := float(_cfg.get("training", {}).get("xp_per_s", 0.5)) * train_mult()
		l.combat_xp += rate * 5.0
		return true
	return colony.send(l, best, true)


# --- journée -------------------------------------------------------------------------------------
func daily() -> void:
	var adults := colony.lutins.filter(func(l: Lutin) -> bool: return l.can_work() and l.jailed.y < 0).size()
	gold_frac += float(tax_level().get("gold_per_adult_day", 0)) * adults
	if gold_frac >= 1.0:
		colony.stock.add("gold", int(gold_frac))
		gold_frac -= int(gold_frac)
	for s: Dictionary in structures.built_with_tag("cage"):
		var esc := float(Structures.def(s["kind"]).get("escape_per_day", 0.0))
		for l in prisoners():
			if l.jailed == s["cell"] and Rng.randf() < esc:
				release_prisoner(l)
				EventBus.alert.emit("alerte", "%s s'est évadé de sa cage en bois !" % l.name)
	var drift := float(_cfg.get("diplomacy", {}).get("drift_per_day", 0.5))
	for f: Dictionary in neighbours():
		var r: Dictionary = relations[f["id"]]
		r["relation"] = move_toward(float(r["relation"]), float(f.get("relation", 0)), drift)
	if lord_id >= 0 and colony.find_lutin(lord_id) == null:
		lord_id = -1


func to_dict() -> Dictionary:
	var tc := []
	for c: Vector3i in training_cells:
		tc.append([c.x, c.y, c.z])
	return {
		"lord": lord_id, "tax": tax, "laws": laws.keys(), "relations": relations, "training": tc, "gold_frac": gold_frac
	}


func from_dict(d: Dictionary) -> void:
	lord_id = int(d.get("lord", -1))
	tax = str(d.get("tax", tax))
	laws.clear()
	for k: String in d.get("laws", []):
		laws[k] = true
	var rel: Dictionary = d.get("relations", {})
	for k: String in rel:
		relations[k] = {"relation": float(rel[k]["relation"]), "status": str(rel[k]["status"])}
	training_cells.clear()
	for e: Array in d.get("training", []):
		training_cells[Vector3i(int(e[0]), int(e[1]), int(e[2]))] = true
	gold_frac = float(d.get("gold_frac", 0.0))
	active = self
