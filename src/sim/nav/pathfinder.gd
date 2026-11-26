class_name Pathfinder
extends RefCounted

static var last_visited: int = 0  # nœuds explorés par la dernière recherche (budget par tick)
## A* sur la grille de blocs. Case marchable = air (et pas d'eau) avec un bloc solide dessous.
## Déplacements : 4 voisins horizontaux, en montant ou descendant d'1 bloc max (le lutin fait 1 bloc de haut).


static func walkable(world: VoxelWorld, p: Vector3i) -> bool:
	if not world.in_bounds(p) or p.y < 1:
		return false
	var here := world.get_block(p)
	if world.types.solid[here] == 1 or world.types.liquid[here] == 1:
		return false
	return world.types.solid[world.get_block(p + Vector3i.DOWN)] == 1


## Case marchable la plus proche verticalement (pour poser un lutin ou viser un bloc).
static func snap(world: VoxelWorld, p: Vector3i, search: int = 6) -> Vector3i:
	for dy in range(0, search + 1):
		for s: int in [1, -1]:
			var q := p + Vector3i(0, dy * s, 0)
			if walkable(world, q):
				return q
	return Vector3i(-1, -1, -1)


static func neighbors(world: VoxelWorld, p: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		var q := p + d
		if walkable(world, q):
			out.append(q)
		elif walkable(world, q + Vector3i.UP) and world.types.solid[world.get_block(p + Vector3i.UP)] == 0:
			out.append(q + Vector3i.UP)  # marche montante (tête libre au départ)
		elif walkable(world, q + Vector3i.DOWN) and world.types.solid[world.get_block(q)] == 0:
			out.append(q + Vector3i.DOWN)
	return out


## Coût d'un pas : les routes accélèrent (speed_mult du bloc sous les pieds).
static func step_cost(world: VoxelWorld, q: Vector3i) -> float:
	return 1.0 / world.types.speed[world.get_block(q + Vector3i.DOWN)]


## Chemin de `from` à `to` (inclus). Vide si impossible. `near` : accepte d'arriver à côté de la cible.
static func find(
	world: VoxelWorld, from: Vector3i, to: Vector3i, max_nodes: int = 20000, near: bool = false, reach_up: int = 1
) -> Array[Vector3i]:
	var empty: Array[Vector3i] = []
	if from == to:
		return [from] as Array[Vector3i]
	var open_heap: Array = []  # [f, compteur, case]
	var g := {from: 0.0}
	var came := {}
	var counter := 0
	_push(open_heap, [_h(from, to), counter, from])
	var visited := 0
	while not open_heap.is_empty() and visited < max_nodes:
		var cur: Vector3i = _pop(open_heap)[2]
		visited += 1
		if cur == to or (near and _adjacent(cur, to, reach_up)):
			last_visited = visited
			return _rebuild(came, cur)
		for nb in neighbors(world, cur):
			var ng: float = g[cur] + step_cost(world, nb)
			if ng < g.get(nb, INF):
				g[nb] = ng
				came[nb] = cur
				counter += 1
				_push(open_heap, [ng + _h(nb, to), counter, nb])
	last_visited = visited
	return empty


## `a` (case du lutin) est à portée de `b` : 1 case à l'horizontale, de 1 bloc plus bas à `reach_up` blocs plus haut.
static func _adjacent(a: Vector3i, b: Vector3i, reach_up: int = 1) -> bool:
	var d := (a - b).abs()
	var dy := b.y - a.y
	return d.x + d.z <= 1 and dy >= -2 and dy <= reach_up


static func _h(a: Vector3i, b: Vector3i) -> float:
	var d := (a - b).abs()
	return float(d.x + d.y + d.z) * 0.6


static func _rebuild(came: Dictionary, cur: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = [cur]
	while came.has(cur):
		cur = came[cur]
		path.push_front(cur)
	return path


# tas binaire minimal (tri sur [f, compteur])
static func _push(heap: Array, item: Array) -> void:
	heap.append(item)
	var i := heap.size() - 1
	while i > 0:
		var parent := (i - 1) / 2
		if _less(heap[i], heap[parent]):
			var tmp: Array = heap[i]
			heap[i] = heap[parent]
			heap[parent] = tmp
			i = parent
		else:
			break


static func _pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < heap.size() and _less(heap[l], heap[m]):
				m = l
			if r < heap.size() and _less(heap[r], heap[m]):
				m = r
			if m == i:
				break
			var tmp: Array = heap[i]
			heap[i] = heap[m]
			heap[m] = tmp
			i = m
	return top


static func _less(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])
