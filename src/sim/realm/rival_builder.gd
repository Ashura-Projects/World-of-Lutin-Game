class_name RivalBuilder
extends RefCounted
## Les villages IA bâtissent (1.4) : ils suivent un ordre de construction (data/factions.json › build_order) et
## posent à chaque fois le même schéma de bâtiment (champ, atelier, grenier, chapelle, caserne, tour, château) dès
## qu'ils ont l'or. Chaque bâtiment change leurs règles : nourriture (croissance), revenus, soldats, foi, défense.
## Un village de 50 habitants avec un château devient une ville. Ils font aussi un peu de diplomatie.


static func cfg() -> Dictionary:
	return DataRegistry.get_table("factions")


static func schema(id: String) -> Dictionary:
	for s: Dictionary in cfg().get("schemas", []):
		if s["id"] == id:
			return s
	return {}


## Somme d'un effet sur tous les bâtiments du village.
static func effect(st: Dictionary, key: String) -> float:
	var v := 0.0
	for b: Dictionary in st.get("buildings", []):
		v += float(schema(str(b["id"])).get("effects", {}).get(key, 0.0)) * int(b.get("level", 1))  # amélioré : × niveau
	return v


## Pose un schéma dans le monde, centré sur c (c.y = première case d'air au-dessus du sol).
static func stamp(world: VoxelWorld, flora: Flora, c: Vector3i, sc: Dictionary) -> void:
	var legend: Dictionary = cfg().get("legend", {})
	var ground: Array = sc.get("ground", [])
	var layers: Array = sc.get("layers", [])
	var rows: Array = ground if not ground.is_empty() else (layers[0] if not layers.is_empty() else [])
	var d := rows.size()
	var w := str(rows[0]).length() if d > 0 else 0
	var o := c - Vector3i(w / 2, 0, d / 2)
	for z in d:  # terrain aplani sous le bâtiment, place dégagée au-dessus
		for x in w:
			var col := o + Vector3i(x, 0, z)
			for y in range(-3, 0):
				if world.get_block(col + Vector3i(0, y, 0)) == 0:
					world.set_block(col + Vector3i(0, y, 0), world.types.num("dirt"))
			for y in range(0, layers.size() + 2):
				world.set_block(col + Vector3i(0, y, 0), 0)
				flora.trees.erase(col + Vector3i(0, y, 0))
				flora.bushes.erase(col + Vector3i(0, y, 0))
	for z in ground.size():
		var row := str(ground[z])
		for x in row.length():
			if legend.has(row[x]):
				world.set_block(o + Vector3i(x, -1, z), world.types.num(str(legend[row[x]])))
	for y in layers.size():
		var layer: Array = layers[y]
		for z in layer.size():
			var row := str(layer[z])
			for x in row.length():
				if legend.has(row[x]):
					world.set_block(o + Vector3i(x, y, z), world.types.num(str(legend[row[x]])))
	flora.changed.emit("trees")


## Chaque jour, pour un village IA : construire le bâtiment suivant s'il a l'or, puis appliquer ses règles.
static func daily(rv: Rivals, st: Dictionary) -> void:
	var r: Dictionary = cfg().get("ai_rules", {})
	if not st.has("buildings"):
		st["buildings"] = []
		st["plan_i"] = 0
	RivalEconomy.daily(st)  # 1.4.1 : métiers, production, repas, ventes
	var order: Array = cfg().get("build_order", [])
	if order.is_empty() or int(st["population"]) < int(r.get("build_min_population", 4)):
		return
	var done := int(st["plan_i"]) >= order.size()
	if done and RivalEconomy.upgrade(st) != "":
		pass  # plan fini : on améliore d'abord ce qu'on a
	else:
		var sc := schema(str(order[int(st["plan_i"]) % order.size()]))
		var mats: Dictionary = sc.get("materials", {})
		if not sc.is_empty() and float(st["wealth"]) >= float(sc.get("cost", 30)) and RivalEconomy.pay(st, mats):
			var spot := _spot(rv, st, int(r.get("spacing", 9)))
			if spot.y > 0:
				stamp(rv.world, rv.flora, spot, sc)
				st["wealth"] = float(st["wealth"]) - float(sc.get("cost", 30))
				st["buildings"].append({"id": sc["id"], "cell": [spot.x, spot.y, spot.z], "level": 1})
				st["plan_i"] = int(st["plan_i"]) + 1
				rv.territory.claim(spot, 1, st["id"])
			else:
				for k: String in mats:  # pas de place : matériaux rendus
					st["stock"][k] = float(st["stock"].get(k, 0.0)) + float(mats[k])
	# règles : revenus et soldats en plus selon les bâtiments, ville avec un château
	st["wealth"] = float(st["wealth"]) + effect(st, "wealth")
	st["city"] = int(st["population"]) >= int(r.get("city_population", 50)) and effect(st, "city") > 0.0


## Bonus de croissance (nourriture des champs et greniers) pour Rivals.daily.
static func growth_bonus(st: Dictionary) -> float:
	return (
		effect(st, "food") * float(cfg().get("ai_rules", {}).get("food_growth_mult", 1.0))
		+ RivalEconomy.growth_bonus(st)
	)


## Emplacement en spirale autour du centre, sur un sol plat et sec.
static func _spot(rv: Rivals, st: Dictionary, spacing: int) -> Vector3i:
	var w := rv.world
	var n: int = st["buildings"].size() + st["houses"].size()
	for k in 12:
		var a := (n + k) * 2.39996 + 1.2
		var rr := spacing * (1.4 + 0.35 * (n + k))
		var x := clampi(st["center"].x + int(cos(a) * rr), 8, w.size.x - 9)
		var z := clampi(st["center"].z + int(sin(a) * rr), 8, w.size.z - 9)
		WorldStreamer.ensure_at(Vector3i(x, 0, z), 0)
		var y := w.surface_y(x, z)
		if y <= 0 or y >= w.size.y - 9:
			continue
		if w.get_block(Vector3i(x, y - 1, z)) == w.types.num("water"):
			continue
		return Vector3i(x, y, z)
	return Vector3i(-1, -1, -1)


## Un peu de diplomatie : un voisin qui nous aime fait des cadeaux ; les plus agressifs se trouvent un rival.
static func diplomacy(rv: Rivals, st: Dictionary, realm: Realm) -> void:
	var r: Dictionary = cfg().get("ai_rules", {})
	var fd := Rivals.def(st["id"])
	if realm != null and realm.relation(st["id"]) >= float(r.get("gift_relation", 45)):
		if Rng.chance(float(r.get("gift_chance", 0.05))) and float(st["wealth"]) > 60.0:
			var g := int(r.get("gift_gold", 10))
			st["wealth"] = float(st["wealth"]) - g
			realm.colony.stock.add("gold", g)
			EventBus.alert.emit("faction", "%s vous offre %d or en signe d'amitié." % [fd.get("name", st["id"]), g])
	if (
		str(st.get("rival_of", "")) == ""
		and Rng.chance(float(r.get("rivalry_chance", 0.02)) * float(fd.get("aggression", 0.5)))
	):
		var others := rv.present().filter(func(o: Dictionary) -> bool: return o["id"] != st["id"])
		if not others.is_empty():
			st["rival_of"] = others[Rng.randi_range(0, others.size() - 1)]["id"]
