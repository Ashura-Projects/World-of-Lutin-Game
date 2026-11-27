class_name UnitCamp
extends RefCounted
## Vie de l'unité (1.4) : repos (camp de tentes autour d'un feu, le cuisinier de l'unité fait à manger),
## entraînement sur le sol d'entraînement (force, agilité ou robustesse), service de la catapulte (viser, charger,
## tirer, la pousser avec l'unité). Appelé chaque seconde par Units.tick_second().


## Repos : tentes de camp et feu autour du commandant ; chacun va à sa tente.
static func make_camp(units: Units, u: Dictionary) -> void:
	var st: Structures = units.colony.structures
	var w := units.colony.world
	if st == null:
		return
	break_camp(units, u)
	var cap := units.colony.find_lutin(int(u["captain"]))
	var c: Vector3i = cap.cell if cap != null else u["cell"]
	var ids: Array = []
	var fire := Pathfinder.snap(w, c)
	if fire.y >= 0 and st.at(fire).is_empty():
		ids.append(st.add("campfire", fire, true, {"camp": u["id"]}))
	var members: Array = u["members"]
	var tents := ceili(members.size() / 2.0)
	var r := int(Soldiering.cfg().get("camp_radius", 4))
	var spots: Array[Vector3i] = []
	for i in tents:
		var a := TAU * i / maxf(1.0, tents)
		var p := Pathfinder.snap(w, c + Vector3i(roundi(cos(a) * r), 0, roundi(sin(a) * r)))
		if p.y >= 0 and st.footprint_free("camp_tent", p, 0):
			ids.append(st.add("camp_tent", p, true, {"camp": u["id"], "rot": posmod(roundi(-a / (PI / 2.0)), 4)}))
			spots.append(p)
	u["camp"] = ids
	for i in members.size():
		var l := units.colony.find_lutin(members[i])
		if l == null:
			continue
		var dest: Vector3i = spots[i / 2] + Vector3i(i % 2, 0, -1) if not spots.is_empty() else c
		LutinOrders.give(units.colony, units.colony.task_board, l, "move", dest, {"hold_s": 1.0e6})
	EventBus.alert.emit("info", "%s monte le camp." % u["name"])


static func break_camp(units: Units, u: Dictionary) -> void:
	var st: Structures = units.colony.structures
	for id: int in u.get("camp", []):
		if st != null and st.items.has(id):
			st.remove(id)
	u["camp"] = []


## Entraînement : chacun va sur une case du sol d'entraînement le plus proche.
static func go_train(units: Units, u: Dictionary) -> void:
	var cells: Array = Realm.active.training_cells.keys() if Realm.active != null else []
	if cells.is_empty():
		EventBus.alert.emit("alerte", "Il faut un sol d'entraînement (Construire › Sols) pour s'entraîner.")
		u["order"] = "none"
		return
	var members: Array = u["members"]
	for i in members.size():
		var l := units.colony.find_lutin(members[i])
		if l != null:
			LutinOrders.give(
				units.colony, units.colony.task_board, l, "move", cells[i % cells.size()], {"hold_s": 1.0e6}
			)


## Catapulte : en marche, les servants la poussent ; à l'attaque, ils la tournent vers la cible.
static func serve_catapult(units: Units, u: Dictionary, kind: String, cell: Vector3i) -> void:
	var cat: Catapults = Catapults.active
	if cat == null:
		return
	var s: Dictionary = units.colony.structures.items.get(int(u["catapult_id"]), {})
	if s.is_empty():
		u["catapult_id"] = -1
		return
	u["catapult_target"] = cell if kind == "attack" else Vector3i(-1, -1, -1)
	if kind == "move":
		var crew := []
		for m: int in u["members"]:
			var l := units.colony.find_lutin(m)
			if l != null and crew.size() < 2:
				crew.append(l)
		if crew.size() >= 2:
			cat.move(s, cell, crew)
	else:
		cat.aim(s, cell)


## Chaque seconde : entraînement, repas du camp, tirs de catapulte.
static func tick_second(units: Units) -> void:
	var col := units.colony
	for u: Dictionary in units.units.values():
		match str(u["order"]):
			"train":
				var stat := str(u.get("train", "force"))
				var pts := float(Soldiering.cfg().get("drill_per_second", 1.5))
				if Realm.active != null:
					pts *= Realm.active.train_mult()
				for m: int in u["members"]:
					var l := col.find_lutin(m)
					if l != null and Realm.active != null and Realm.active.training_cells.has(l.cell):
						Soldiering.add_drill(l, stat, pts)
			"rest":
				_feed(units, u)
		_fire(units, u)


## Le cuisinier de l'unité nourrit les soldats au camp (1 plat de la réserve par soldat affamé).
static func _feed(units: Units, u: Dictionary) -> void:
	var col := units.colony
	var cook := col.find_lutin(int(u.get("cook", -1)))
	if cook == null:
		return
	for m: int in u["members"]:
		var l := col.find_lutin(m)
		if l == null or float(l.needs.get("hunger", 100.0)) > 60.0:
			continue
		for food: String in col.stock.items.keys():
			if str(Stockpile._resource(food).get("category", "")) == "food" and col.stock.take(food, 1) == 1:
				l.needs["hunger"] = minf(100.0, float(l.needs["hunger"]) + 45.0)
				break


static func _fire(units: Units, u: Dictionary) -> void:
	var cat: Catapults = Catapults.active
	var tgt: Vector3i = u.get("catapult_target", Vector3i(-1, -1, -1))
	if cat == null or tgt.y < 0 or u["order"] != "attack":
		return
	var s: Dictionary = units.colony.structures.items.get(int(u["catapult_id"]), {})
	if s.is_empty():
		return
	var crew_near := false
	for m: int in u["members"]:
		var l := units.colony.find_lutin(m)
		if l != null and Vector3(l.cell).distance_to(Vector3(s["cell"])) < 4.0:
			crew_near = true
	if not crew_near:
		return
	if not s.get("loaded", false):
		cat.load(s)
	else:
		cat.fire(s, tgt)
