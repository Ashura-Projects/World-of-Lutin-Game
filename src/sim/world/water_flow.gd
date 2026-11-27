class_name WaterFlow
extends RefCounted
## L'eau remplit les trous (1.3.2) : quand une case se vide (creuser, gomme) ou qu'on verse de l'eau, l'eau des
## cases voisines (côtés ou dessus) coule dedans, puis s'étend de proche en proche sur les côtés et vers le bas.
## Étalé sur plusieurs ticks (quelques cases par tick) et limité par vague pour ne jamais ralentir le jeu.

const SIDES := [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]

var world: VoxelWorld
var water: int = -1
var _queue: Array[Vector3i] = []
var _seen: Dictionary = {}
var _budget: int = 0  # cases encore remplissables dans la vague en cours
var _cfg: Dictionary


func _init(w: VoxelWorld) -> void:
	world = w
	water = w.types.num("water")
	_cfg = DataRegistry.get_table("world").get("water_flow", {})
	w.block_changed.connect(_on_block)


func _on_block(p: Vector3i, _old: int, new_id: int) -> void:
	if new_id == 0:
		_push(p)
	elif new_id == water:
		for d: Vector3i in SIDES + [Vector3i.DOWN]:
			_push(p + d)


func _push(p: Vector3i) -> void:
	if _seen.has(p):
		return
	if _queue.is_empty():
		_budget = int(_cfg.get("max_cells_per_wave", 400))
		_seen.clear()
	_seen[p] = true
	_queue.append(p)


## Une case vide reçoit l'eau d'une voisine (côté ou dessus) ?
func _fed(p: Vector3i) -> bool:
	if world.get_block(p + Vector3i.UP) == water:
		return true
	for d: Vector3i in SIDES:
		if world.get_block(p + d) == water:
			return true
	return false


## Appelé à chaque tick : remplit quelques cases (cases_per_tick).
func tick() -> void:
	var n := int(_cfg.get("cells_per_tick", 12))
	while n > 0 and not _queue.is_empty():
		var p: Vector3i = _queue.pop_front()
		_seen.erase(p)  # pourra revenir si une voisine se remplit plus tard
		n -= 1
		if _budget <= 0 or not world.in_bounds(p) or p.y < 1 or world.get_block(p) != 0 or not _fed(p):
			continue
		_budget -= 1
		world.set_block(p, water)  # le signal pousse les voisines (côtés, dessous)
	if _queue.is_empty():
		_seen.clear()


func busy() -> bool:
	return not _queue.is_empty()
