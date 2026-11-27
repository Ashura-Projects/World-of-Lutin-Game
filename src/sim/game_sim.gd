class_name GameSim
extends RefCounted
## Toute la simulation d'une partie (sans aucun nœud) : utilisée par la scène de jeu et par les tests headless.

const SAVE_KEYS := [
	"world",
	"colony",
	"flora",
	"fauna",
	"ground",
	"structures",
	"production",
	"tasks",
	"combat",
	"village",
	"education",
	"faction",
	"research",
	"trade",
	"realm",
	"units",
	"rules",
	"orcs",
	"territory",
	"rivals",
	"religion",
	"gates",
	"missions"
]

var world: VoxelWorld
var colony: Colony
var flora: Flora
var fauna: Fauna
var ground: GroundItems
var board: TaskBoard
var structures: Structures
var fields: Fields
var production: Production
var combat: Combat
var village: Village
var research: Research
var education: Education
var population: Population
var faction: Faction
var trade: Trade
var realm: Realm
var units: Units
var rules: GameRules
var orcs: Orcs
var territory: Territory
var rivals: Rivals
var religion: Religion
var gates: Gates
var missions: TutorialMissions
var catapults: Catapults
var water: WaterFlow


func _init(w: VoxelWorld) -> void:
	world = w
	rules = GameRules.new(GameSetup.rules())
	colony = Colony.new(w)
	flora = Flora.new()
	fauna = Fauna.new(w)
	ground = GroundItems.new()
	board = TaskBoard.new(w, colony, flora, fauna, ground)
	structures = Structures.new()
	board.structures = structures
	colony.structures = structures
	fields = Fields.new()
	board.fields = fields
	production = Production.new(board, fields)
	combat = Combat.new(colony, fauna, ground)
	village = Village.new(colony, structures, w)
	combat.lutin_died.connect(func(_n: String, _c: String) -> void: village.on_death())
	w.block_changed.connect(village.on_block)
	research = Research.new()
	education = Education.new(colony, structures, production, research)
	population = Population.new(colony, structures, w)
	faction = Faction.new(GameSetup.faction)
	trade = Trade.new(colony)
	realm = Realm.new(colony, structures, w)
	units = Units.new(colony, combat)
	orcs = Orcs.new(w, fauna, colony, flora)
	territory = Territory.new(w)
	rivals = Rivals.new(w, fauna, colony, flora, territory)
	religion = Religion.new(colony, structures, fauna)
	gates = Gates.new(w, structures)
	colony.fauna_ref = fauna
	missions = TutorialMissions.new(self)
	catapults = Catapults.new(self)
	water = WaterFlow.new(w)
	structures.changed.connect(gates.sync_with_structures)


## Nouvelle partie sur un monde généré.
func new_game(gen: WorldGenerator, start: Vector3i, lutins: int) -> void:
	flora.load_from_generator(gen)
	colony.spawn_start(start, lutins)
	colony.auto_assign_jobs()
	fauna.populate(["deer", "boar", "horse"], start)
	fauna.populate(["wolf", "bear"], start, 40.0)
	orcs.setup_new(start)
	rivals.setup_new(start, rules.ai_factions)
	if rules.mode == "tutorial":
		missions.start_current()
	for c: Dictionary in orcs.camps:
		territory.claim(
			c["cell"], int(DataRegistry.get_table("factions").get("territory", {}).get("camp_radius", 1)), "orcs"
		)
	village.last_stock = colony.stock.items.duplicate()


func tick() -> void:
	colony.tick()
	Horses.tick(self)
	Hauling.tick(self)
	catapults.tick()
	water.tick()
	combat.tick()
	orcs.tick()
	var tps := GameClock.ticks_per_second()
	if GameClock.tick_index % 2 == 0:
		var cells := []
		for l in colony.lutins:
			cells.append(l.cell)
		fauna.tick(cells)
	if GameClock.tick_index % tps == 0:
		religion.tick_second()
		production.plan()
		UnitCamp.tick_second(units)
		colony.heating_ok = not production.fire_out
	if GameClock.tick_index % (tps * 5) == 0:
		village.check()
		rivals.check_conquest()
		for l in colony.lutins:
			territory.explore(l.cell, int(DataRegistry.find("jobs", "jobs", l.job).get("explore_radius", 2)))
		_buildings_effects()
		if rules.mode == "tutorial":
			missions.check()
		rivals.check_meetings()
		orcs.check_discovery(territory)


func daily() -> void:
	production.daily()
	population.daily()
	education.daily()
	structures.assign_homes(colony)
	trade.daily(GameClock.day())
	village.daily()
	realm.daily()
	orcs.daily(GameClock.day())
	rivals.daily(GameClock.day())
	religion.daily()
	Horses.daily(self)
	Livestock.daily(self)
	Leisure.daily(colony)


func register_saves() -> void:
	var objs := [
		world,
		colony,
		flora,
		fauna,
		ground,
		structures,
		production,
		board,
		combat,
		village,
		education,
		faction,
		research,
		trade,
		realm,
		units,
		rules,
		orcs,
		territory,
		rivals,
		religion,
		gates,
		missions
	]
	for i in SAVE_KEYS.size():
		SaveManager.register(SAVE_KEYS[i], objs[i])


func unregister_saves() -> void:
	for k: String in SAVE_KEYS:
		SaveManager.unregister(k)


## Bornes de territoire (revendiquent les colonnes autour contre de l'or) et tours de guet (vue lointaine).
func _buildings_effects() -> void:
	var tc: Dictionary = DataRegistry.get_table("factions").get("territory", {})
	for s: Dictionary in structures.built_with_tag("claim"):
		if s.get("claimed", false):
			continue
		s["claimed"] = true
		var cost := int(tc.get("claim_post_gold", 20))
		if colony.stock.count("gold") < cost:
			EventBus.alert.emit("alerte", "Borne de territoire : il faut %d or pour revendiquer." % cost)
			s["claimed"] = false
			continue
		var owner := territory.owner_at(s["cell"])
		var force: bool = owner != "" and owner != "player" and realm.status(owner) in ["war", "conquered"]
		colony.stock.take("gold", cost)
		var n := territory.claim(s["cell"], int(tc.get("claim_post_radius", 1)), "player", force)
		EventBus.alert.emit("faction", "Territoire revendiqué : %d zone(s)." % n)
	var wr := int(DataRegistry.get_table("realm").get("watchtower_radius_cols", 5))
	for s: Dictionary in structures.built_with_tag("watchtower"):
		territory.explore(s["cell"], wr)
