class_name Catapults
extends RefCounted
## Catapultes (1.3.1) : on la touche pour Charger (2 pierres), Tirer (toucher la cible, dans l'angle de tir),
## Tourner, Déplacer (deux lutins la poussent ; elle s'oriente dans le sens de la marche).
## Le rocher casse les blocs construits (pas le terrain naturel) et blesse les ennemis autour.

static var active: Catapults = null

var sim: GameSim
var shots: Array = []  # rochers en vol : {"from", "to", "t", "dur"}
var _cfg: Dictionary


func _init(s: GameSim) -> void:
	sim = s
	_cfg = DataRegistry.get_table("military").get("catapult", {})
	active = self


func get_all() -> Array:
	return sim.structures.items.values().filter(
		func(s: Dictionary) -> bool: return s["kind"] == "catapult" and s["built"]
	)


func load(s: Dictionary) -> String:
	if s.get("loaded", false):
		return "Déjà chargée."
	var ammo: Dictionary = _cfg.get("ammo", {"stone": 2})
	for k: String in ammo:
		if sim.colony.stock.count(k) < int(ammo[k]):
			return "Il faut %d %s pour charger." % [int(ammo[k]), str(Stockpile._resource(k).get("name", k)).to_lower()]
	for k: String in ammo:
		sim.colony.stock.take(k, int(ammo[k]))
	s["loaded"] = true
	return "Catapulte chargée."


func rotate(s: Dictionary, steps: int) -> void:
	s["yaw"] = wrapf(float(s.get("yaw", 0.0)) + deg_to_rad(float(_cfg.get("rotate_step_deg", 15))) * steps, -PI, PI)
	sim.structures.changed.emit()


## Direction « devant » de la catapulte (le rocher part vers -Z tourné de yaw).
static func forward(yaw: float) -> Vector2:
	return Vector2(-sin(yaw), -cos(yaw))


func fire(s: Dictionary, target: Vector3i) -> String:
	if not s.get("loaded", false):
		return "Chargez d'abord la catapulte."
	var c: Vector3i = s["cell"]
	var d := Vector2(target.x - c.x, target.z - c.z)
	var rng: Array = _cfg.get("range", [8, 45])
	if d.length() < float(rng[0]) or d.length() > float(rng[1]):
		return "Hors de portée (%d à %d blocs)." % [int(rng[0]), int(rng[1])]
	if absf(rad_to_deg(forward(float(s.get("yaw", 0.0))).angle_to(d))) > float(_cfg.get("arc_deg", 40)):
		return "Tournez la catapulte vers la cible."
	s["loaded"] = false
	shots.append(
		{
			"from": Vector3(c) + Vector3(0.5, 2.5, 0.5),
			"to": target,
			"t": 0.0,
			"dur": d.length() / float(_cfg.get("speed", 14.0))
		}
	)
	EventBus.sfx.emit("marteau", Vector3(c))
	return "Tir !"


## Chaque tick : les rochers avancent ; à l'impact, ils cassent et blessent.
func tick() -> void:
	if shots.is_empty():
		return
	var dt := 1.0 / GameClock.ticks_per_second()
	for sh: Dictionary in shots.duplicate():
		sh["t"] = float(sh["t"]) + dt
		if float(sh["t"]) >= float(sh["dur"]):
			shots.erase(sh)
			impact(sh["to"])


func impact(target: Vector3i) -> int:
	var w := sim.world
	var r := int(_cfg.get("break_radius", 1))
	var natural: Array = DataRegistry.get_table("military").get("orcs", {}).get("natural_blocks", [])
	var broken := 0
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			for dy in range(-1, 3):
				var p := target + Vector3i(dx, dy, dz)
				var id := w.get_block(p)
				var b := DataRegistry.block(id)
				if id == 0 or natural.has(str(b.get("id", ""))) or not b.get("diggable", true):
					continue
				w.set_block(p, 0)
				sim.orcs.collapse_above(p)
				broken += 1
	var dmg := float(_cfg.get("damage", 45))
	for a in sim.fauna.animals.duplicate():
		if (
			sim.fauna.def(a["kind"]).get("enemy", false)
			and Vector3(a["cell"]).distance_to(Vector3(target)) <= float(_cfg.get("damage_radius", 2.5))
		):
			sim.fauna.damage(a["id"], dmg)
	EventBus.sfx.emit("pioche", Vector3(target))
	return broken


## Déplacer : deux lutins libres vont la pousser jusqu'à l'endroit choisi.
func move(s: Dictionary, dest: Vector3i) -> String:
	var free := sim.colony.lutins.filter(
		func(l: Lutin) -> bool: return l.can_work() and not l.mobilized and l.jailed.y < 0 and l.order.is_empty()
	)
	free.sort_custom(
		func(a: Lutin, b: Lutin) -> bool:
			return Vector3(a.cell).distance_to(Vector3(s["cell"])) < Vector3(b.cell).distance_to(Vector3(s["cell"]))
	)
	var n := int(_cfg.get("pushers", 2))
	if free.size() < n:
		return "Il faut %d lutins libres pour la pousser." % n
	for i in n:
		LutinOrders.give(sim.colony, sim.board, free[i], "push", dest, {"struct": s["id"], "lead": i == 0})
	return "%s et %s poussent la catapulte." % [free[0].name, free[1].name]
