class_name DebugTools
extends RefCounted
## Commandes du menu débug (caché) : ressources, apparitions, temps, triches. Agit seulement sur la simulation.

const BASIC := ["log", "plank", "beam", "stone", "cut_stone", "iron_ingot", "nails", "cloth", "clay", "bread", "gold"]


static func add_resources(sim: GameSim, n: int, ids: Array = BASIC) -> void:
	for id: String in ids:
		sim.colony.stock.add(id, n)


## +n de toutes les ressources connues.
static func add_everything(sim: GameSim, n: int) -> void:
	for r: Dictionary in DataRegistry.get_table("resources").get("resources", []):
		sim.colony.stock.add(r["id"], n)


static func spawn_lutin(sim: GameSim, cell: Vector3i, child: bool = false) -> Lutin:
	return spawn_lutin_at(sim.colony, cell, "", child)


## Un nouveau lutin adulte (ou enfant) rejoint la colonie à cette case.
static func spawn_lutin_at(c: Colony, cell: Vector3i, name: String = "", child: bool = false) -> Lutin:
	var l := Lutin.new()
	l.id = c.next_id
	c.next_id += 1
	l.name = name if name != "" else c.unique_name(DataRegistry.get_table("names").get("names", ["Lutin"]))
	l.sex = "f" if Rng.chance(0.5) else "m"
	var adult := 60
	for a: Dictionary in DataRegistry.get_table("population").get("ages", []):
		if a["id"] == ("child" if child else "adult"):
			adult = int(a["from_day"])
	l.age_days = adult + (5 if child else 20)
	l.hp = float(DataRegistry.get_table("population").get("combat", {}).get("hp", 50))
	l.set_job("hauler")
	var spot := Pathfinder.snap(c.world, cell)
	l.place_at(spot if spot.y >= 0 else c.stock.pos)
	c.lutins.append(l)
	c.lutin_added.emit(l)
	return l


static func spawn_animal(sim: GameSim, kind: String, cell: Vector3i) -> bool:
	var p := Pathfinder.snap(sim.world, cell)
	if p.y < 0 or sim.fauna.def(kind).is_empty():
		return false
	sim.fauna.spawn(kind, p)
	return true


## Tue tous les animaux hostiles (loups, ours, orcs, soldats ennemis).
static func kill_enemies(sim: GameSim) -> int:
	var n := 0
	for a in sim.fauna.animals.duplicate():
		if sim.fauna.def(a["kind"]).get("hostile", false):
			sim.fauna.damage(a["id"], 99999.0)
			n += 1
	return n


static func heal_all(sim: GameSim) -> void:
	for l in sim.colony.lutins:
		l.hp = Soldiering.max_hp(l)
		for k: String in l.needs:
			l.needs[k] = 100.0


static func skip_days(n: int) -> void:
	for _i in n:
		GameClock.tick_index += GameClock.ticks_per_day()
		EventBus.day_changed.emit(GameClock.day())


static func set_hour(tod: float) -> void:
	var d := GameClock.day()
	GameClock.tick_index = d * GameClock.ticks_per_day() + int(tod * GameClock.ticks_per_day())


static func unlock_all_research(sim: GameSim) -> void:
	for t: Dictionary in DataRegistry.get_table("technologies").get("technologies", []):
		sim.research.unlocked[t["id"]] = true
	sim.research.current = ""


## Termine tout de suite les plans de construction (blocs et objets).
static func finish_builds(sim: GameSim) -> int:
	var n := 0
	for t: Dictionary in sim.board.tasks.values().duplicate():
		match t["kind"]:
			"build":
				sim.world.set_block(t["cell"], int(t["block"]))
			"build_struct":
				sim.structures.set_built(int(t["struct_id"]))
			_:
				continue
		sim.board.finish(t)
		n += 1
	sim.structures.assign_homes(sim.colony)
	return n


static func merchant_now(sim: GameSim) -> void:
	if not sim.trade.present:
		sim.trade.next_day = GameClock.day()
		sim.trade.daily(GameClock.day())
