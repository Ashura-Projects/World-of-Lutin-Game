class_name Production
extends RefCounted
## Planificateur de l'économie : tâches des champs (labour, semis, récolte), commandes des ateliers
## (« faire N » ou « garder N en stock »), postes de travail (affectation lutin → bâtiment), combustible l'hiver.

var board: TaskBoard
var fields: Fields
var orders: Dictionary = {}  # id structure -> [{"recipe", "mode": make/keep, "n", "done"}]
var staff: Dictionary = {}  # id structure -> [id lutins]
var auto: Dictionary = {}  # id structure -> bool (mode auto : postes remplis par les lutins libres)
var fire_out: bool = false


func _init(b: TaskBoard, f: Fields) -> void:
	board = b
	fields = f


static func recipe(id: String) -> Dictionary:
	return DataRegistry.find("recipes", "recipes", id)


static func recipes_for(station: String) -> Array:
	var out := []
	for r: Dictionary in DataRegistry.get_table("recipes").get("recipes", []):
		if r["station"] == station:
			out.append(r)
	return out


func stations() -> Array:
	var out := []
	if board.structures == null:
		return out
	for s: Dictionary in board.structures.items.values():
		if s["built"] and Structures.def(s["kind"]).has("station"):
			out.append(s)
	return out


func add_order(struct_id: int, recipe_id: String, mode: String, n: int) -> void:
	orders.get_or_add(struct_id, []).append({"recipe": recipe_id, "mode": mode, "n": n, "done": 0})


## Affecter un lutin à un bâtiment : il prend le métier (et l'outil) du poste. False si pas d'outil en réserve.
func assign_staff(struct_id: int, l: Lutin) -> bool:
	var s: Dictionary = board.structures.items.get(struct_id, {})
	if s.is_empty():
		return false
	var d := Structures.def(s["kind"])
	var job: String = d.get("job", l.job)
	if not board.colony.change_job(l, job):
		EventBus.alert.emit("outil", "Pas d'outil en réserve pour %s (%s)" % [l.name, job])
		return false
	for sid: int in staff:
		staff[sid].erase(l.id)
	var list: Array = staff.get_or_add(struct_id, [])
	if list.size() >= int(d.get("staff", 1)):
		return false
	list.append(l.id)
	return true


func empty_seats() -> Array:
	var out := []
	for s: Dictionary in stations():
		var n: int = int(Structures.def(s["kind"]).get("staff", 1)) - staff.get(s["id"], []).size()
		if n > 0:
			out.append([s, n])
	return out


## Appelé chaque seconde de jeu : crée les tâches des champs et des ateliers.
func plan() -> void:
	_plan_fields()
	for s: Dictionary in stations():
		if auto.get(s["id"], false):
			_auto_fill(s)
		_plan_station(s)


func _plan_fields() -> void:
	var w := board.world
	for cell: Vector3i in fields.plots:
		var p: Dictionary = fields.plots[cell]
		if board._by_cell.has(cell):
			continue
		match p["state"]:
			"planned":
				board._new_task(
					"till", cell, "farmer", float(DataRegistry.get_table("crops")["field"].get("till_work", 2))
				)
			"tilled":
				if Fields.can_sow_now(p["crop"]):
					board._new_task(
						"sow",
						cell,
						"farmer",
						float(DataRegistry.get_table("crops")["field"].get("sow_work", 2)),
						{"crop": p["crop"]}
					)
			"ripe":
				board._new_task(
					"harvest",
					cell,
					"farmer",
					float(DataRegistry.get_table("crops")["field"].get("harvest_work", 3)),
					{"crop": p["crop"]}
				)
		if p["state"] == "planned" and w.get_block(cell) == w.types.num("field_plot"):
			p["state"] = "tilled"


func _plan_station(s: Dictionary) -> void:
	for t: Dictionary in board.tasks.values():
		if t["kind"] == "craft" and t["struct_id"] == s["id"]:
			return  # une commande à la fois par atelier
	var st: Stockpile = board.colony.stock
	for o: Dictionary in orders.get(s["id"], []):
		var r := recipe(o["recipe"])
		if r.is_empty():
			continue
		var outs: Dictionary = r.get("out", {})
		var out_id: String = outs.keys()[0] if not outs.is_empty() else ""
		if o["mode"] == "keep" and st.count(out_id) >= int(o["n"]):
			continue
		if o["mode"] == "make" and int(o["done"]) >= int(o["n"]):
			continue
		var ok := true
		for k: String in r.get("in", {}):
			if st.count(k) < int(r["in"][k]):
				ok = false
		if not ok:
			continue
		var id := board._new_task(
			"craft",
			s["cell"] + Vector3i(0, 0, 0),
			r["job"],
			float(r.get("work", 10)),
			{"recipe": r["id"], "struct_id": s["id"], "order": o}
		)
		if id >= 0:
			board.tasks[id]["assigned"] = staff.get(s["id"], []).duplicate()
		return


func _auto_fill(s: Dictionary) -> void:
	var d := Structures.def(s["kind"])
	var seats: int = int(d.get("staff", 1)) - staff.get(s["id"], []).size()
	if seats <= 0:
		return
	var taken := {}
	for sid: int in staff:
		for lid: int in staff[sid]:
			taken[lid] = true
	var best: Lutin = null
	for l in board.colony.lutins:
		if taken.has(l.id) or l.job not in ["hauler", d.get("job", "")]:
			continue
		if best == null or l.job_level(d.get("job", "")) > best.job_level(d.get("job", "")):
			best = l
	if best:
		assign_staff(s["id"], best)


## Chaque matin : croissance des champs, combustible des feux l'hiver.
func daily() -> void:
	fields.grow_day(board.world)
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	if seasons.is_empty() or seasons[GameClock.season_index()]["id"] != "winter":
		fire_out = false
		return
	fire_out = false
	for s: Dictionary in board.structures.items.values():
		var fuel: Dictionary = Structures.def(s["kind"]).get("fuel_per_day", {})
		for k: String in fuel:
			if board.colony.stock.take(k, int(fuel[k])) < int(fuel[k]):
				fire_out = true
				EventBus.alert.emit("froid", "Plus de bûches pour le feu !")


func to_dict() -> Dictionary:
	var o := {}
	for k: int in orders:
		o[str(k)] = orders[k]
	var st := {}
	for k: int in staff:
		st[str(k)] = staff[k]
	var au := {}
	for k: int in auto:
		au[str(k)] = auto[k]
	return {"orders": o, "staff": st, "auto": au, "fields": fields.to_dict()}


func from_dict(d: Dictionary) -> void:
	orders.clear()
	staff.clear()
	auto.clear()
	for k: String in d.get("orders", {}):
		orders[int(k)] = d["orders"][k]
	for k: String in d.get("staff", {}):
		var ids := []
		for v in d["staff"][k]:
			ids.append(int(v))
		staff[int(k)] = ids
	for k: String in d.get("auto", {}):
		auto[int(k)] = bool(d["auto"][k])
	fields.from_dict(d.get("fields", {}))
