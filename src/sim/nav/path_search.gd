class_name PathSearch
extends RefCounted
## Recherche A* incrémentale : avance de quelques nœuds par tick (temps de tick borné sur téléphone).

enum Status { RUNNING, FOUND, FAILED }

var world: VoxelWorld
var to: Vector3i
var near: bool
var reach_up: int
var max_nodes: int
var visited: int = 0
var status: Status = Status.RUNNING
var path: Array[Vector3i] = []
var _heap: Array = []
var _g: Dictionary = {}
var _came: Dictionary = {}
var _counter: int = 0


func _init(w: VoxelWorld, from: Vector3i, target: Vector3i, max_n: int, near_ok: bool, reach: int) -> void:
	world = w
	to = target
	near = near_ok
	reach_up = reach
	max_nodes = max_n
	_g[from] = 0.0
	if from == target:
		path = [from]
		status = Status.FOUND
		return
	Pathfinder._push(_heap, [Pathfinder._h(from, to), 0, from])


## Avance d'au plus `budget` nœuds. Renvoie le nombre de nœuds explorés.
func step(budget: int) -> int:
	var n := 0
	while status == Status.RUNNING and n < budget:
		if _heap.is_empty() or visited >= max_nodes:
			status = Status.FAILED
			break
		var cur: Vector3i = Pathfinder._pop(_heap)[2]
		visited += 1
		n += 1
		if cur == to or (near and Pathfinder._adjacent(cur, to, reach_up)):
			path = Pathfinder._rebuild(_came, cur)
			status = Status.FOUND
			break
		for nb in Pathfinder.neighbors(world, cur):
			var ng: float = _g[cur] + Pathfinder.step_cost(world, nb)
			if ng < _g.get(nb, INF):
				_g[nb] = ng
				_came[nb] = cur
				_counter += 1
				Pathfinder._push(_heap, [ng + Pathfinder._h(nb, to), _counter, nb])
	return n
