class_name Battle
extends RefCounted
## Mode Bataille (1.4) : une carte au choix (plaine, forêt, colline), sans village à gérer. On pose ses soldats
## (fusiliers, lanciers, épéistes, cavaliers) et des ennemis (orcs, bandits, soldats d'une faction voisine), on forme
## des unités et on combat. Construction libre, armes en réserve à volonté. Données : data/military.json › battle.

const ALLIES := {
	"fusilier": {"name": "Fusilier", "weapon": "flintlock", "horse": false},
	"lancer": {"name": "Lancier", "weapon": "spear", "horse": false},
	"swordsman": {"name": "Épéiste", "weapon": "short_sword", "horse": false},
	"rider": {"name": "Cavalier", "weapon": "spear", "horse": true}
}


static func cfg() -> Dictionary:
	return DataRegistry.get_table("military").get("battle", {})


static func enemies() -> Array:
	return cfg().get("enemies", ["orc", "orc_archer", "orc_brute", "bandit_club", "bandit_archer"])


## Départ d'une bataille : règles libres, réserve d'armes, premiers soldats en uniforme.
static func setup(sim: GameSim) -> void:
	sim.rules.free_build = true
	sim.rules.free_dig = true
	sim.rules.free_clear = true
	sim.rules.free_terra = true
	for k: String in cfg().get("stock", {}):
		sim.colony.stock.add(k, int(cfg()["stock"][k]))
	for l: Lutin in sim.colony.lutins:
		_soldier(sim, l, "fusilier")


## Pose n soldats alliés d'un type autour d'une case.
static func place_allies(sim: GameSim, kind: String, cell: Vector3i, n: int) -> int:
	var made := 0
	for i in n:
		var l := DebugTools.spawn_lutin_at(sim.colony, cell + Vector3i(i % 5 - 2, 0, i / 5))
		if l != null:
			_soldier(sim, l, kind)
			made += 1
	return made


static func _soldier(sim: GameSim, l: Lutin, kind: String) -> void:
	var d: Dictionary = ALLIES.get(kind, ALLIES["fusilier"])
	l.set_job("soldier")
	l.weapon = str(d["weapon"])
	if l.armor == "":
		l.armor = str(cfg().get("armor", ""))
	if d["horse"]:
		var h := sim.fauna.spawn("horse", l.cell)
		h["owned"] = true
		h["home"] = l.cell
		l.horse = h["id"]
		h["rider"] = l.id
	l.hp = Soldiering.max_hp(l)


## Pose n ennemis d'une sorte (orc, bandit, soldat d'une faction voisine) : ils foncent sur nos soldats.
static func place_enemies(sim: GameSim, kind: String, cell: Vector3i, n: int) -> int:
	var made := 0
	for i in n:
		var p := Pathfinder.snap(sim.world, cell + Vector3i(i % 5 - 2, 0, i / 5))
		if p.y < 0 or sim.fauna.def(kind).is_empty():
			continue
		var a := sim.fauna.spawn(kind, p)
		a["faction"] = str(sim.fauna.def(kind).get("faction", "orcs"))
		a["home"] = p
		a["roam"] = 3
		a["battle"] = true
		made += 1
	return made


## Retire tous les ennemis posés.
static func clear_enemies(sim: GameSim) -> int:
	var n := 0
	for a: Dictionary in sim.fauna.animals.duplicate():
		if sim.fauna.def(a["kind"]).get("enemy", false):
			sim.fauna.damage(a["id"], 99999.0)
			n += 1
	return n


## Forces en présence : [nos soldats vivants, ennemis vivants].
static func forces(sim: GameSim) -> Array:
	var foes := sim.fauna.animals.filter(
		func(a: Dictionary) -> bool: return sim.fauna.def(a["kind"]).get("enemy", false)
	)
	return [sim.colony.lutins.size(), foes.size()]
