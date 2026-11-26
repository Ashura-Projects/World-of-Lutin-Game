class_name Combat
extends RefCounted
## Prédateurs (loups la nuit, ours), combat simple, cloche d'alerte : Mobiliser (armes + uniforme) ou Se cacher.
## PV, dégâts, portées et cadences fixes (data/animals.json, data/equipment.json, data/population.json › combat).

signal lutin_died(name: String, cause: String)

var colony: Colony
var fauna: Fauna
var ground: GroundItems
var alert: String = "none"  # none / mobilize / hide
var _cfg: Dictionary


func _init(c: Colony, f: Fauna, g: GroundItems) -> void:
	colony = c
	fauna = f
	ground = g
	_cfg = DataRegistry.get_table("population").get("combat", {})
	c.combat = self


static func weapon_def(id: String) -> Dictionary:
	return DataRegistry.find("equipment", "weapons", id)


func _weapon_stats(l: Lutin) -> Dictionary:
	if l.weapon != "":
		var w := weapon_def(l.weapon)
		return {
			"attack": float(w.get("attack", 5)),
			"reach": float(w.get("range", w.get("reach", 1.5))),
			"every": float(w.get("every_s", 1.5))
		}
	var u: Dictionary = _cfg.get("unarmed", {})
	return {
		"attack": float(u.get("attack", 3)), "reach": float(u.get("reach", 1.0)), "every": float(u.get("every_s", 1.2))
	}


## Cloche : Mobiliser (les adultes prennent les armes et l'uniforme), Se cacher, ou fin de l'alerte.
func ring(mode: String) -> void:
	stand_down()
	alert = mode
	if mode == "none":
		return
	for l in colony.lutins:
		if not _is_adult(l):
			l.hiding = true
			continue
		if mode == "hide":
			l.hiding = true
		elif mode == "mobilize":
			if colony.task_board != null:
				colony.task_board.call("release", l)
			l.mobilized = true
			for w: String in _cfg.get("weapon_priority", ["flintlock", "spear"]):
				if colony.stock.take(w, 1) == 1:
					l.weapon = w
					break
			l.state = Lutin.State.IDLE
	EventBus.alert.emit("cloche", "Mobilisation !" if mode == "mobilize" else "Tout le monde à l'abri !")


func stand_down() -> void:
	for l in colony.lutins:
		if l.weapon != "":
			colony.stock.add(l.weapon, 1)
			l.weapon = ""
		l.mobilized = false
		if l.hiding:
			l.hiding = false
			l.state = Lutin.State.IDLE
	alert = "none"


func _is_adult(l: Lutin) -> bool:
	for a: Dictionary in DataRegistry.get_table("population").get("ages", []):
		if a["id"] == "adult":
			return l.age_days >= int(a["from_day"])
	return true


func tick() -> void:
	var tps := float(GameClock.ticks_per_second())
	_predators(tps)
	for l in colony.lutins.duplicate():
		if l.attack_cool > 0:
			l.attack_cool -= 1
		if l.hp <= 0.0:
			lutin_died.emit(l.name, "blessures")
			EventBus.alert.emit("mort", "%s est mort." % l.name)
			colony.remove_lutin(l)
			continue
		if l.mobilized:
			_militia(l, tps)
		_self_heal(l)


func _predators(tps: float) -> void:
	var night := GameClock.is_night()
	for a in fauna.animals.duplicate():
		var d := fauna.def(a["kind"])
		if not d.get("hostile", false):
			continue
		a["cool"] = maxi(0, int(a.get("cool", 0)) - 1)
		var radius := float(d.get("aggro_radius", 8))
		if a["kind"] == "wolf" and not night and a.get("prey", -1) == -1:
			continue  # les loups chassent la nuit
		var prey := _nearest_lutin(a["pos"], radius if a.get("prey", -1) == -1 else radius * 2.0)
		if prey == null:
			a["prey"] = -1
			continue
		a["prey"] = prey.id
		var dist: float = a["pos"].distance_to(prey.pos)
		if dist <= float(d.get("reach", 1.2)) + 0.3:
			a["path"] = []
			if a["cool"] == 0:
				prey.hp -= float(d.get("damage", 5))
				a["cool"] = int(float(d.get("attack_every_s", 1.5)) * tps)
				if not prey.mobilized and prey.attack_cool == 0:
					_strike(prey, a, tps)  # il se défend
		elif int(GameClock.tick_index) >= int(a.get("repath_at", 0)):
			a["repath_at"] = int(GameClock.tick_index) + int(tps * 1.5)  # pas plus d'une recherche toutes les 1,5 s
			a["path"] = Pathfinder.find(colony.world, a["cell"], prey.cell, 600, true)
			a["path_i"] = 1
			a["wait"] = 0


func _nearest_lutin(p: Vector3, radius: float) -> Lutin:
	var best: Lutin = null
	var bd := radius
	for l in colony.lutins:
		var dd := p.distance_to(l.pos)
		if dd < bd:
			bd = dd
			best = l
	return best


func _militia(l: Lutin, tps: float) -> void:
	var target: Dictionary = {}
	var bd := float(_cfg.get("engage_radius", 16))
	for a in fauna.animals:
		if not fauna.def(a["kind"]).get("hostile", false):
			continue
		var dd: float = l.pos.distance_to(a["pos"])
		if dd < bd:
			bd = dd
			target = a
	if target.is_empty():
		if not Colony._near(l.cell, colony.stock.pos, 3) and not l.has_path() and not l.pending_path:
			colony.send(l, colony.stock.pos, true)  # point de rassemblement
		return
	var ws := _weapon_stats(l)
	if bd <= float(ws["reach"]):
		l.path = []
		l.path_i = 0
		l.state = Lutin.State.WORK
		if l.attack_cool == 0:
			_strike(l, target, tps)
	elif not l.pending_path and (not l.has_path() or int(GameClock.tick_index) % int(tps * 2) == l.id % int(tps * 2)):
		colony.send(l, target["cell"], true)


## Un coup (ou un tir) d'un lutin sur un animal. Tuer donne de l'XP de combat et compte au tableau de chasse.
func _strike(l: Lutin, a: Dictionary, tps: float) -> void:
	var ws := _weapon_stats(l)
	l.attack_cool = int(float(ws["every"]) * tps)
	var cell: Vector3i = a["cell"]
	var kind: String = a["kind"]
	if fauna.damage(a["id"], float(ws["attack"])):
		l.kills[kind] = int(l.kills.get(kind, 0)) + 1
		l.combat_xp += float(fauna.def(kind).get("xp", 10))
		ground.drop(cell, fauna.def(kind).get("drop", {}))
		EventBus.alert.emit("victoire", "%s a abattu un %s." % [l.name, fauna.def(kind).get("name", kind)])


## Blessé : boit une potion de soin s'il y en a à la réserve et qu'il y est ; récupération lente sinon.
func _self_heal(l: Lutin) -> void:
	var max_hp := float(_cfg.get("hp", 50))
	if l.hp >= max_hp:
		return
	l.hp = minf(max_hp, l.hp + float(_cfg.get("regen_per_day", 5)) / GameClock.ticks_per_day())
	if l.hp < max_hp * float(_cfg.get("self_potion_below", 0.5)) and Colony._near(l.cell, colony.stock.pos, 2):
		if colony.stock.take("healing_potion", 1) == 1:
			l.hp = minf(max_hp, l.hp + float(Stockpile._resource("healing_potion").get("heal", 30)))


func to_dict() -> Dictionary:
	return {"alert": alert}


func from_dict(d: Dictionary) -> void:
	alert = str(d.get("alert", "none"))
