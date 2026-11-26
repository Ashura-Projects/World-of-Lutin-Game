class_name WorldGenerator
extends RefCounted
## Génère la carte vierge (data/world.json) : grande plaine, rivière, lac, forêts, collines à minerais,
## montagne à explorer ; couches façon Minecraft. Déterministe : même graine = même monde.

var world: VoxelWorld
var cfg: Dictionary
var seed_value: int
var trees: Array = []  # [{"pos": Vector3i, "kind": String}]
var bushes: Array = []
var herbs: Array = []  # lin sauvage, plantes médicinales : [{"pos", "kind"}]
var _n_base := FastNoiseLite.new()
var _n_hill := FastNoiseLite.new()
var _n_forest := FastNoiseLite.new()
var _n_detail := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _init(w: VoxelWorld, seed_in: int) -> void:
	world = w
	seed_value = seed_in
	cfg = DataRegistry.get_table("world")
	_rng.seed = seed_in
	for pair: Array in [[_n_base, 0.012], [_n_hill, 0.008], [_n_forest, 0.02], [_n_detail, 0.06]]:
		var n: FastNoiseLite = pair[0]
		n.seed = seed_in + _rng.randi_range(1, 99999)
		n.frequency = pair[1]
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH


func _biome(id: String) -> Dictionary:
	for b: Dictionary in cfg.get("biomes", []):
		if b["id"] == id:
			return b
	return {}


func generate() -> void:
	var sx := world.size.x
	var sz := world.size.z
	var sea := int(cfg.get("sea_level", 24))
	var water_y := sea - 1
	var plain: Array = _biome("plain").get("height", [24, 28])
	var hills: Array = _biome("hills").get("height", [30, 44])
	var mount: Array = _biome("mountain").get("height", [44, 62])
	var snow_above := int(_biome("mountain").get("snow_above", 54))
	var river: Dictionary = cfg.get("river", {})
	var rw: Array = river.get("width", [3, 6])
	var half_w := (float(rw[0]) + float(rw[1])) / 4.0
	var bank_w := float(river.get("sand_banks", 2))
	# montagne dans un coin, lac dans un autre, rivière qui serpente au milieu
	var mc := Vector2(sx * (0.82 if _rng.randf() < 0.5 else 0.18), sz * 0.85)
	var lake := Vector2(sx - mc.x, sz * 0.2)
	var lake_r := sx * 0.06 if _rng.randf() < float(river.get("lake_chance", 0.6)) else 0.0
	var r_phase := _rng.randf() * TAU
	var t := world.types
	var id_grass := t.num("grass")
	var id_dirt := t.num("dirt")
	var id_stone := t.num("stone")
	var id_deep := t.num("deep_stone")
	var id_bed := t.num("bedrock")
	var id_sand := t.num("sand")
	var id_water := t.num("water")
	var id_snow := t.num("snow")
	var id_fert := t.num("fertile_soil")
	for x in sx:
		for z in sz:
			var base := float(plain[0]) + (float(plain[1]) - float(plain[0])) * (0.5 + 0.5 * _n_base.get_noise_2d(x, z))
			var hill_f := clampf((_n_hill.get_noise_2d(x, z) - 0.15) * 2.2, 0.0, 1.0)
			var h := base + hill_f * (float(hills[1]) - float(plain[1])) * (0.6 + 0.4 * _n_detail.get_noise_2d(x, z))
			var md := Vector2(x, z).distance_to(mc) / (sx * 0.3)
			var mount_f := pow(clampf(1.0 - md, 0.0, 1.0), 1.3)
			h += mount_f * (float(mount[1]) - float(plain[1]))
			var ry := sz * 0.45 + sz * 0.15 * sin(x / (sx * 0.16) + r_phase) + 4.0 * _n_detail.get_noise_2d(x * 0.5, 0)
			var dr := absf(z - ry)
			var ld := Vector2(x, z).distance_to(lake)
			var wet := (dr < half_w and mount_f < 0.3) or ld < lake_r
			var bank := not wet and mount_f < 0.3 and (dr < half_w + bank_w or ld < lake_r + bank_w)
			if wet:
				h = water_y - 2
			elif bank:
				h = minf(h, water_y + 1)
			var top := clampi(roundi(h), 3, world.size.y - 2)
			var dirt_depth := 3 if mount_f < 0.45 else 0
			for y in top:
				var id := id_stone
				if y == 0:
					id = id_bed
				elif y < top - 1 - dirt_depth:
					id = id_deep if y < 12 else id_stone
				elif y < top - 1:
					id = id_sand if bank else id_dirt
				else:
					id = id_grass
					if bank or wet:
						id = id_sand
					elif top > snow_above:
						id = id_snow
					elif mount_f > 0.45:
						id = id_stone
					elif dr < half_w + bank_w + 4 and _n_detail.get_noise_2d(x, z) > 0.2:
						id = id_fert
				world.set_raw(Vector3i(x, y, z), id)
			if wet:
				for y in range(top, water_y + 1):
					world.set_raw(Vector3i(x, y, z), id_water)
			elif bank:
				_wild(Vector3i(x, top, z), "bank")
			elif mount_f < 0.25:
				_flora(x, top, z, hill_f)
	_ores()


func _flora(x: int, y: int, z: int, hill_f: float) -> void:
	var forest := _n_forest.get_noise_2d(x, z) > 0.25
	var b := _biome("forest" if forest else ("hills" if hill_f > 0.3 else "plain"))
	var p := Vector3i(x, y, z)
	if _rng.randf() * 100.0 < float(b.get("trees_per_100", 1)):
		var kind := "pin" if (hill_f > 0.3 or _rng.randf() < 0.55) else ("bouleau" if _rng.randf() < 0.3 else "chene")
		trees.append({"pos": p, "kind": kind})
	elif _rng.randf() * 100.0 < float(b.get("bushes_per_100", 1)):
		bushes.append({"pos": p})
	else:
		_wild(p, "forest" if forest else ("hills" if hill_f > 0.3 else "plain"))


## Plantes sauvages (lin, plantes médicinales, champignons, roseaux) selon le milieu.
func _wild(p: Vector3i, here: String) -> void:
	for w: Dictionary in DataRegistry.get_table("crops").get("wild", []):
		if w.get("biome", []).has(here) and _rng.randf() * 100.0 < float(w.get("per_100", 0)):
			herbs.append({"pos": p, "kind": w["id"]})
			return


## Poches de minerais, gravier, argile dans la pierre (data/world.json › pockets).
func _ores() -> void:
	var t := world.types
	var id_stone := t.num("stone")
	var chunks_x := ceili(world.size.x / 16.0)
	var chunks_z := ceili(world.size.z / 16.0)
	for pk: Dictionary in cfg.get("pockets", []):
		if not pk.has("per_chunk") or pk.get("in", "") != "stone":
			continue
		var id := t.num(pk["block"])
		var hr: Array = pk.get("height", [1, world.size.y - 1])
		var sz: Array = pk.get("size", [2, 4])
		for cx in chunks_x:
			for cz in chunks_z:
				for _i in int(pk["per_chunk"]):
					var c := Vector3i(
						cx * 16 + _rng.randi_range(0, 15),
						_rng.randi_range(int(hr[0]), int(hr[1])),
						cz * 16 + _rng.randi_range(0, 15)
					)
					var n := _rng.randi_range(int(sz[0]), int(sz[1]))
					var p := c
					for _k in n:
						if world.get_block(p) == id_stone:
							world.set_raw(p, id)
						p += [
							Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK
						][_rng.randi_range(0, 5)]


## Empreinte du monde (tests de déterminisme).
func fingerprint() -> int:
	var h := 0
	for k: Vector3i in world.chunks:
		h = h ^ hash([k, world.chunks[k].data])
	return h
