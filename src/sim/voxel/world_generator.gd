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
## Carte de bataille (1.4) : "plain" (plaine), "forest" (forêt), "hills" (collines) ; "" = carte normale.
var preset: String = ""
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


## Paramètres globaux de la carte (montagne, lac, rivière), tirés une fois de la graine.
var _ready_params: bool = false
var _p: Dictionary = {}


func _prepare() -> void:
	if _ready_params:
		return
	_ready_params = true
	var sx := world.size.x
	var sz := world.size.z
	var river: Dictionary = cfg.get("river", {})
	var rw: Array = river.get("width", [3, 6])
	var mc := Vector2(sx * (0.82 if _rng.randf() < 0.5 else 0.18), sz * 0.85)
	var lake_r := sx * 0.06 if _rng.randf() < float(river.get("lake_chance", 0.6)) else 0.0
	var t := world.types
	_p = {
		"water_y": int(cfg.get("sea_level", 24)) - 1,
		"plain": _biome("plain").get("height", [24, 28]),
		"hills": _biome("hills").get("height", [30, 44]),
		"mount": _biome("mountain").get("height", [44, 62]),
		"snow_above": int(_biome("mountain").get("snow_above", 54)),
		"half_w": (float(rw[0]) + float(rw[1])) / 4.0,
		"bank_w": float(river.get("sand_banks", 2)),
		"mc": mc,
		"lake": Vector2(sx - mc.x, sz * 0.2),
		"lake_r": lake_r,
		"r_phase": _rng.randf() * TAU,
		"grass": t.num("grass"),
		"dirt": t.num("dirt"),
		"stone": t.num("stone"),
		"deep": t.num("deep_stone"),
		"bed": t.num("bedrock"),
		"sand": t.num("sand"),
		"water": t.num("water"),
		"snow": t.num("snow"),
		"fert": t.num("fertile_soil")
	}


## Carte entière (petites et grandes cartes ; Campagne Impériale en graphismes Ultra ou personnalisés).
func generate() -> void:
	_prepare()
	generate_region(0, 0, world.size.x, world.size.z)


## Une zone de la carte (colonnes x0..x1-1, z0..z1-1) : utilisée pour générer la Campagne Impériale par zones.
## Déterministe colonne par colonne : une zone donne toujours le même terrain, quel que soit l'ordre.
func generate_region(x0: int, z0: int, x1: int, z1: int) -> void:
	_prepare()
	for x in range(maxi(0, x0), mini(world.size.x, x1)):
		for z in range(maxi(0, z0), mini(world.size.z, z1)):
			_column(x, z)
	_ores_region(x0, z0, x1, z1)


## Hauteur du terrain (première case d'air) sans rien générer : pour choisir des emplacements à l'avance.
func height_at(x: int, z: int) -> int:
	_prepare()
	return int(_shape(x, z)[0])


## [hauteur, hill_f, mount_f, wet, bank, dr]
func _shape(x: int, z: int) -> Array:
	var sx := world.size.x
	var sz := world.size.z
	var plain: Array = _p["plain"]
	var hills: Array = _p["hills"]
	var mount: Array = _p["mount"]
	var base := float(plain[0]) + (float(plain[1]) - float(plain[0])) * (0.5 + 0.5 * _n_base.get_noise_2d(x, z))
	var hill_f := clampf((_n_hill.get_noise_2d(x, z) - 0.15) * 2.2, 0.0, 1.0)
	if preset == "hills":
		hill_f = clampf((_n_hill.get_noise_2d(x, z) + 0.3) * 1.4, 0.0, 1.0)
	elif preset != "":
		hill_f *= 0.15
	var h := base + hill_f * (float(hills[1]) - float(plain[1])) * (0.6 + 0.4 * _n_detail.get_noise_2d(x, z))
	var md := Vector2(x, z).distance_to(_p["mc"]) / (sx * 0.3)
	var mount_f := pow(clampf(1.0 - md, 0.0, 1.0), 1.3) if preset == "" else 0.0
	h += mount_f * (float(mount[1]) - float(plain[1]))
	var ry := (
		sz * 0.45 + sz * 0.15 * sin(x / (sx * 0.16) + float(_p["r_phase"])) + 4.0 * _n_detail.get_noise_2d(x * 0.5, 0)
	)
	var dr := absf(z - ry)
	var ld := Vector2(x, z).distance_to(_p["lake"])
	var half_w: float = _p["half_w"]
	var bank_w: float = _p["bank_w"]
	var lake_r: float = _p["lake_r"]
	var wet := ((dr < half_w and mount_f < 0.3) or ld < lake_r) and preset == ""
	var bank := not wet and mount_f < 0.3 and (dr < half_w + bank_w or ld < lake_r + bank_w) and preset == ""
	var water_y: int = _p["water_y"]
	if wet:
		h = water_y - 2
	elif bank:
		h = minf(h, water_y + 1)
	return [clampi(roundi(h), 3, world.size.y - 2), hill_f, mount_f, wet, bank, dr]


func _column(x: int, z: int) -> void:
	var sh := _shape(x, z)
	var top: int = sh[0]
	var hill_f: float = sh[1]
	var mount_f: float = sh[2]
	var wet: bool = sh[3]
	var bank: bool = sh[4]
	var dr: float = sh[5]
	var dirt_depth := 3 if mount_f < 0.45 else 0
	var half_w: float = _p["half_w"]
	var bank_w: float = _p["bank_w"]
	for y in top:
		var id: int = _p["stone"]
		if y == 0:
			id = _p["bed"]
		elif y < top - 1 - dirt_depth:
			id = _p["deep"] if y < 12 else _p["stone"]
		elif y < top - 1:
			id = _p["sand"] if bank else _p["dirt"]
		else:
			id = _p["grass"]
			if bank or wet:
				id = _p["sand"]
			elif top > int(_p["snow_above"]):
				id = _p["snow"]
			elif mount_f > 0.45:
				id = _p["stone"]
			elif dr < half_w + bank_w + 4 and _n_detail.get_noise_2d(x, z) > 0.2:
				id = _p["fert"]
		world.set_raw(Vector3i(x, y, z), id)
	if wet:
		for y in range(top, int(_p["water_y"]) + 1):
			world.set_raw(Vector3i(x, y, z), _p["water"])
	elif bank:
		_wild(Vector3i(x, top, z), "bank")
	elif mount_f < 0.25:
		_flora(x, top, z, hill_f)


## Nombre pseudo-aléatoire 0..1 propre à une colonne (indépendant de l'ordre de génération).
func _r(x: int, z: int, k: int) -> float:
	var h := (x * 73856093) ^ (z * 19349663) ^ (seed_value * 83492791) ^ (k * 2654435761)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / 16777216.0


func _flora(x: int, y: int, z: int, hill_f: float) -> void:
	var forest := _n_forest.get_noise_2d(x, z) > 0.25
	if preset == "forest":
		forest = _n_forest.get_noise_2d(x, z) > -0.35
	elif preset in ["plain", "hills"]:
		forest = _n_forest.get_noise_2d(x, z) > 0.55
	var b := _biome("forest" if forest else ("hills" if hill_f > 0.3 else "plain"))
	var p := Vector3i(x, y, z)
	if _r(x, z, 1) * 100.0 < float(b.get("trees_per_100", 1)):
		var kind := "pin" if (hill_f > 0.3 or _r(x, z, 2) < 0.55) else ("bouleau" if _r(x, z, 3) < 0.3 else "chene")
		trees.append({"pos": p, "kind": kind})
	elif _r(x, z, 4) * 100.0 < float(b.get("bushes_per_100", 1)):
		bushes.append({"pos": p})
	else:
		_wild(p, "forest" if forest else ("hills" if hill_f > 0.3 else "plain"))


## Plantes sauvages (lin, plantes médicinales, champignons, roseaux) selon le milieu.
func _wild(p: Vector3i, here: String) -> void:
	for w: Dictionary in DataRegistry.get_table("crops").get("wild", []):
		if w.get("biome", []).has(here) and _r(p.x, p.z, 5 + hash(w["id"]) % 7) * 100.0 < float(w.get("per_100", 0)):
			herbs.append({"pos": p, "kind": w["id"]})
			return


## Poches de minerais, gravier, argile dans la pierre (data/world.json › pockets), chunk par chunk (graine du chunk).
func _ores_region(x0: int, z0: int, x1: int, z1: int) -> void:
	var t := world.types
	var id_stone := t.num("stone")
	var rng := RandomNumberGenerator.new()
	for cx in range(floori(maxi(0, x0) / 16.0), ceili(mini(world.size.x, x1) / 16.0)):
		for cz in range(floori(maxi(0, z0) / 16.0), ceili(mini(world.size.z, z1) / 16.0)):
			rng.seed = hash([seed_value, cx, cz])
			for pk: Dictionary in cfg.get("pockets", []):
				if not pk.has("per_chunk") or pk.get("in", "") != "stone":
					continue
				var id := t.num(pk["block"])
				var hr: Array = pk.get("height", [1, world.size.y - 1])
				var sz: Array = pk.get("size", [2, 4])
				for _i in int(pk["per_chunk"]):
					var c := Vector3i(
						cx * 16 + rng.randi_range(0, 15),
						rng.randi_range(int(hr[0]), int(hr[1])),
						cz * 16 + rng.randi_range(0, 15)
					)
					var n := rng.randi_range(int(sz[0]), int(sz[1]))
					var p := c
					for _k in n:
						if world.get_block(p) == id_stone:
							world.set_raw(p, id)
						p += [
							Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK
						][rng.randi_range(0, 5)]


## Empreinte du monde (tests de déterminisme).
func fingerprint() -> int:
	var h := 0
	for k: Vector3i in world.chunks:
		h = h ^ hash([k, world.chunks[k].data])
	return h
