class_name VoxelRaycast
extends RefCounted
## Lancer de rayon sur la grille (DDA) : renvoie le bloc touché ET la face (pose « à la Minecraft »).


## Renvoie {"hit": bool, "pos": Vector3i, "normal": Vector3i}. max_y : blocs au-dessus ignorés (curseur d'étage).
static func cast(
	world: VoxelWorld, origin: Vector3, dir: Vector3, max_dist: float = 300.0, max_y: int = 9999
) -> Dictionary:
	var d := dir.normalized()
	var cell := Vector3i(floori(origin.x), floori(origin.y), floori(origin.z))
	var step := Vector3i(signi(int(signf(d.x))), signi(int(signf(d.y))), signi(int(signf(d.z))))
	var t_delta := Vector3(
		absf(1.0 / d.x) if d.x != 0.0 else INF,
		absf(1.0 / d.y) if d.y != 0.0 else INF,
		absf(1.0 / d.z) if d.z != 0.0 else INF
	)
	var t_max := Vector3(_first(origin.x, d.x, cell.x), _first(origin.y, d.y, cell.y), _first(origin.z, d.z, cell.z))
	var normal := Vector3i.ZERO
	var t := 0.0
	while t <= max_dist:
		if cell.y < max_y and world.is_solid(cell):
			return {"hit": true, "pos": cell, "normal": normal}
		if t_max.x < t_max.y and t_max.x < t_max.z:
			cell.x += step.x
			t = t_max.x
			t_max.x += t_delta.x
			normal = Vector3i(-step.x, 0, 0)
		elif t_max.y < t_max.z:
			cell.y += step.y
			t = t_max.y
			t_max.y += t_delta.y
			normal = Vector3i(0, -step.y, 0)
		else:
			cell.z += step.z
			t = t_max.z
			t_max.z += t_delta.z
			normal = Vector3i(0, 0, -step.z)
	return {"hit": false, "pos": Vector3i.ZERO, "normal": Vector3i.ZERO}


static func _first(o: float, d: float, c: int) -> float:
	if d > 0.0:
		return (c + 1.0 - o) / d
	if d < 0.0:
		return (o - c) / -d
	return INF
