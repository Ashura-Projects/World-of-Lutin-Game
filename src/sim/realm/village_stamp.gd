class_name VillageStamp
extends RefCounted
## Pose les maisons d'un village voisin dans la grille de blocs (murs en planches, toit de chaume, porte ouverte).


## Maison 5 × 5 posée sur un terrain aplani autour de `c` (c.y = première case d'air au-dessus du sol).
static func house(world: VoxelWorld, flora: Flora, c: Vector3i, wall: String = "plank_block") -> void:
	var w := world.types.num(wall)
	var roof := world.types.num("thatch_block")
	var dirt := world.types.num("dirt")
	var beam := world.types.num("beam_block")
	var y0 := c.y
	for x in range(c.x - 2, c.x + 3):
		for z in range(c.z - 2, c.z + 3):
			for y in range(y0 - 3, y0):
				if world.in_bounds(Vector3i(x, y, z)) and world.get_block(Vector3i(x, y, z)) == 0:
					world.set_block(Vector3i(x, y, z), dirt)  # remblai sous la maison
			for y in range(y0, y0 + 6):
				var p := Vector3i(x, y, z)
				if world.in_bounds(p):
					world.set_block(p, 0)
				flora.trees.erase(p)
	for x in range(c.x - 2, c.x + 3):
		for z in range(c.z - 2, c.z + 3):
			var edge := x in [c.x - 2, c.x + 2] or z in [c.z - 2, c.z + 2]
			var corner := x in [c.x - 2, c.x + 2] and z in [c.z - 2, c.z + 2]
			for y in range(y0, y0 + 3):
				if not edge:
					continue
				if z == c.z + 2 and x == c.x and y < y0 + 2:
					continue  # porte
				world.set_block(Vector3i(x, y, z), beam if corner else w)
			world.set_block(Vector3i(x, y0 + 3, z), roof)
	world.set_block(Vector3i(c.x, y0 + 4, c.z), roof)


## Village : maisons autour d'un centre. Renvoie les centres des maisons.
static func village(world: VoxelWorld, flora: Flora, center: Vector3i, houses: int, spread: int) -> Array:
	var out := []
	for i in houses:
		var a := i * TAU / houses + 0.3
		var r := spread * (0.6 + 0.4 * float(i % 2))
		var x := clampi(center.x + int(cos(a) * r), 4, world.size.x - 5)
		var z := clampi(center.z + int(sin(a) * r), 4, world.size.z - 5)
		var y := world.surface_y(x, z)
		if y <= 0 or y >= world.size.y - 7:
			continue
		if world.get_block(Vector3i(x, y - 1, z)) == world.types.num("water"):
			continue
		house(world, flora, Vector3i(x, y, z))
		out.append(Vector3i(x, y, z))
	flora.changed.emit("trees")
	return out
