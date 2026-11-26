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
	"units"
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


func _init(w: VoxelWorld) -> void:
	world = w
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


## Nouvelle partie sur un monde généré.
func new_game(gen: WorldGenerator, start: Vector3i, lutins: int) -> void:
	flora.load_from_generator(gen)
	colony.spawn_start(start, lutins)
	colony.auto_assign_jobs()
	fauna.populate(["deer", "boar"], start)
	fauna.populate(["wolf", "bear"], start, 40.0)
	village.last_stock = colony.stock.items.duplicate()


func tick() -> void:
	colony.tick()
	combat.tick()
	var tps := GameClock.ticks_per_second()
	if GameClock.tick_index % 2 == 0:
		var cells := []
		for l in colony.lutins:
			cells.append(l.cell)
		fauna.tick(cells)
	if GameClock.tick_index % tps == 0:
		production.plan()
		colony.heating_ok = not production.fire_out
	if GameClock.tick_index % (tps * 5) == 0:
		village.check()


func daily() -> void:
	production.daily()
	population.daily()
	education.daily()
	structures.assign_homes(colony)
	trade.daily(GameClock.day())
	village.daily()
	realm.daily()


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
		units
	]
	for i in SAVE_KEYS.size():
		SaveManager.register(SAVE_KEYS[i], objs[i])


func unregister_saves() -> void:
	for k: String in SAVE_KEYS:
		SaveManager.unregister(k)
