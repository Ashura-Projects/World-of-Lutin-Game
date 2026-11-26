class_name Population
extends RefCounted
## Cycle de vie : vieillissement, naissances (couple dans une maison avec un lit libre, village nourri et content),
## mort de vieillesse des anciens (data/population.json).

signal born(l: Lutin)

var colony: Colony
var structures: Structures
var world: VoxelWorld
var _cfg: Dictionary


func _init(c: Colony, s: Structures, w: VoxelWorld) -> void:
	colony = c
	structures = s
	world = w
	_cfg = DataRegistry.get_table("population")


func daily() -> void:
	for l in colony.lutins.duplicate():
		l.age_days += 1
		_old_age(l)
	_births()


func _old_age(l: Lutin) -> void:
	var d: Dictionary = _cfg.get("death_of_old_age", {})
	if (
		bool(d.get("enabled", true))
		and l.age_days >= int(d.get("from_day", 500))
		and Rng.chance(float(d.get("chance_per_day", 0.02)))
	):
		EventBus.alert.emit("mort", "%s est mort de vieillesse, entouré des siens." % l.name)
		if colony.combat != null:
			colony.combat.call("emit_signal", "lutin_died", l.name, "vieillesse")
		colony.remove_lutin(l)


func food_days() -> float:
	var per := float(_cfg.get("birth", {}).get("food_per_lutin_day", 2.75)) * maxi(1, colony.lutins.size())
	return colony.stock.food_total() / per


func mood() -> float:
	var m := 0.0
	for l in colony.lutins:
		m += float(l.needs["mood"])
	return m / maxf(1.0, colony.lutins.size())


## Lit libre dans la même pièce que le couple (maison).
func _free_bed_in(room: Dictionary) -> Dictionary:
	for s: Dictionary in structures.items.values():
		if s["built"] and s["kind"] == "bed" and s["owner"] == -1 and room["cells"].has(s["cell"]):
			return s
	return {}


func _births() -> void:
	var b: Dictionary = _cfg.get("birth", {})
	if food_days() < 5.0 or mood() < 50.0:
		return
	var done := {}
	for a in colony.lutins:
		if a.sex != "f" or a.age_stage() != "adult" or a.home.y < 0 or done.has(a.id):
			continue
		var room := RoomDetector.room_at(world, structures, a.home)
		if room.is_empty():
			continue
		for m in colony.lutins:
			if (
				m.sex == "m"
				and m.age_stage() == "adult"
				and m.home.y >= 0
				and room["cells"].has(m.home)
				and not done.has(m.id)
			):
				var bed := _free_bed_in(room)
				if bed.is_empty() or not Rng.chance(float(b.get("chance_per_day", 0.08))):
					break
				done[a.id] = true
				done[m.id] = true
				_birth(a, m, bed)
				break


func _birth(mother: Lutin, father: Lutin, bed: Dictionary) -> void:
	var l := Lutin.new()
	l.id = colony.next_id
	colony.next_id += 1
	var names: Array = DataRegistry.get_table("names").get("names", ["Lutin"])
	l.name = colony.unique_name(names)
	l.sex = "f" if Rng.chance(0.5) else "m"
	l.age_days = 0
	l.parents = [mother.id, father.id]
	var apt: Array = _cfg.get("birth", {}).get("baby_aptitude", [0, 10])
	for k: String in l.aptitudes:
		l.aptitudes[k] = Rng.randi_range(int(apt[0]), int(apt[1]))
	l.hp = float(_cfg.get("combat", {}).get("hp", 50))
	l.set_job("hauler")
	l.home = bed["cell"]
	bed["owner"] = l.id
	l.place_at(mother.cell)
	colony.lutins.append(l)
	colony.lutin_added.emit(l)
	born.emit(l)
	EventBus.alert.emit("naissance", "%s est né(e), enfant de %s et %s !" % [l.name, mother.name, father.name])
