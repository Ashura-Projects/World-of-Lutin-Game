class_name EditHistory
extends RefCounted
## Annuler / Rétablir pour la construction (chaque action = liste de [position, ancien id, nouvel id]).

var world: VoxelWorld
var max_size: int = 64
var _undo: Array = []
var _redo: Array = []


func _init(w: VoxelWorld) -> void:
	world = w


## Applique id sur les cases (les cases interdites sont ignorées). Renvoie le nombre de blocs changés.
func apply(cells: Array, id: int, only_into_air: bool = true) -> int:
	var changes := []
	for p: Vector3i in cells:
		if not world.in_bounds(p):
			continue
		var old := world.get_block(p)
		if old == id or (only_into_air and id != 0 and old != 0 and world.types.liquid[old] == 0):
			continue
		if id == 0 and DataRegistry.block(old).get("diggable", true) == false:
			continue
		changes.append([p, old, id])
		world.set_block(p, id)
	if not changes.is_empty():
		_undo.append(changes)
		if _undo.size() > max_size:
			_undo.pop_front()
		_redo.clear()
	return changes.size()


func undo() -> bool:
	if _undo.is_empty():
		return false
	var changes: Array = _undo.pop_back()
	for i in range(changes.size() - 1, -1, -1):
		world.set_block(changes[i][0], changes[i][1])
	_redo.append(changes)
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	var changes: Array = _redo.pop_back()
	for c: Array in changes:
		world.set_block(c[0], c[2])
	_undo.append(changes)
	return true


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()
