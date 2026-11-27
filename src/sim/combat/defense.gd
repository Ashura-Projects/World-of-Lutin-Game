class_name Defense
extends RefCounted
## Défense (Phase 2) : créneaux et hauteur. Un lutin à côté d'un créneau prend moins de dégâts et tire plus loin ;
## tirer d'en haut porte plus loin (data/military.json).

static var _crenel: int = -1


static func _crenel_id(world: VoxelWorld) -> int:
	if _crenel < 0:
		_crenel = world.types.num("crenel")
	return _crenel


## Un créneau juste à côté (même hauteur) ?
static func behind_crenel(world: VoxelWorld, cell: Vector3i) -> bool:
	var c := _crenel_id(world)
	for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]:
		if world.get_block(cell + d) == c:
			return true
	return false


## Portée supplémentaire : hauteur au-dessus de la cible + créneau.
static func range_bonus(world: VoxelWorld, shooter: Vector3i, target: Vector3i) -> float:
	var m := DataRegistry.get_table("military")
	var h := maxf(0.0, float(shooter.y - target.y)) * float(m.get("height_range_bonus_per_block", 0.4))
	var b := minf(h, float(m.get("height_range_bonus_max", 5.0)))
	if behind_crenel(world, shooter):
		b += float(m.get("crenel_range_bonus", 2.0))
	return b
