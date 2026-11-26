class_name Education
extends RefCounted
## École (aptitudes des enfants), centres de formation (chercheur, artisan expert, guérisseur), production de recherche.

var colony: Colony
var structures: Structures
var production: Production
var research: Research
var focus: String = "balanced"  # cours de l'école
var trainees: Dictionary = {}  # id lutin -> {"center": id centre, "days": jours restants, "eff": efficacité}
var _cfg: Dictionary


func _init(c: Colony, s: Structures, p: Production, r: Research) -> void:
	colony = c
	structures = s
	production = p
	research = r
	_cfg = DataRegistry.get_table("education")
	focus = str(_cfg.get("school", {}).get("default_focus", "balanced"))
	c.education = self


func _first_built(kind: String) -> Dictionary:
	for s: Dictionary in structures.items.values():
		if s["built"] and s["kind"] == kind:
			return s
	return {}


func school_cell() -> Vector3i:
	var s := _first_built("school")
	return s["cell"] if not s.is_empty() else Vector3i(-1, -1, -1)


## Un maître d'école est-il affecté à l'école ?
func has_teacher() -> bool:
	var s := _first_built("school")
	if s.is_empty():
		return false
	for lid: int in production.staff.get(s["id"], []):
		var l := colony.find_lutin(lid)
		if l != null and l.job == "teacher":
			return true
	return false


static func center(id: String) -> Dictionary:
	return DataRegistry.find("education", "training_centers", id)


## Efficacité de la formation : 1 si l'aptitude requise est atteinte (enfant bien éduqué), sinon formation courte d'adulte.
func efficiency_for(l: Lutin, center_id: String) -> float:
	var req: Dictionary = center(center_id).get("requires", {})
	for k: String in req:
		if int(l.aptitudes.get(k, 0)) < int(req[k]):
			return float(_cfg.get("adult_without_school_penalty", 0.5))
	return 1.0


## Inscrire un adulte à un centre de formation construit (bibliothèque, atelier de maître, herboristerie).
func enroll(l: Lutin, center_struct_id: int) -> bool:
	var s: Dictionary = structures.items.get(center_struct_id, {})
	if s.is_empty() or not s["built"] or not l.can_work():
		return false
	var cid := str(Structures.def(s["kind"]).get("training", ""))
	var c := center(cid)
	if c.is_empty() or int(c.get("phase", 1)) > 1:
		return false
	trainees[l.id] = {"center": cid, "days": int(c.get("days", 10)), "eff": efficiency_for(l, cid)}
	return true


func daily() -> void:
	# école : les enfants gagnent des aptitudes chaque jour où un maître enseigne
	if has_teacher():
		var courses: Array = _cfg.get("school", {}).get("courses", []).filter(
			func(c: Dictionary) -> bool: return int(c.get("phase", 1)) <= 1
		)
		var mult := 1.0 + research.bonus("school_gain")
		for l in colony.lutins:
			if l.age_stage() != "child":
				continue
			for c: Dictionary in courses:
				if focus != "balanced" and c["id"] != focus:
					continue
				var share := 1.0 if focus != "balanced" else 1.0 / courses.size()
				for k: String in c.get("gives", {}):
					l.aptitudes[k] = mini(
						100, int(l.aptitudes.get(k, 0)) + maxi(1, roundi(float(c["gives"][k]) * share * mult))
					)
	# formations
	for lid: int in trainees.keys():
		var l := colony.find_lutin(lid)
		if l == null:
			trainees.erase(lid)
			continue
		var t: Dictionary = trainees[lid]
		t["days"] = int(t["days"]) - 1
		if int(t["days"]) <= 0:
			var job := str(center(t["center"]).get("trains", ""))
			l.trained[job] = float(t["eff"])
			colony.change_job(l, job)
			trainees.erase(lid)
			EventBus.alert.emit(
				"formation", "%s est maintenant %s." % [l.name, DataRegistry.find("jobs", "jobs", job).get("name", job)]
			)
	# recherche : chercheurs affectés à une bibliothèque
	var per_day := float(_cfg.get("research", {}).get("points_per_day", 10))
	for s: Dictionary in production.stations():
		if s["kind"] != "library":
			continue
		for lid: int in production.staff.get(s["id"], []):
			var l := colony.find_lutin(lid)
			if l != null and l.job == "researcher":
				research.add_points(per_day * float(l.trained.get("researcher", 0.5)))


func to_dict() -> Dictionary:
	var tr := {}
	for k: int in trainees:
		tr[str(k)] = trainees[k]
	return {"focus": focus, "trainees": tr, "research": research.to_dict()}


func from_dict(d: Dictionary) -> void:
	focus = str(d.get("focus", "balanced"))
	trainees.clear()
	for k: String in d.get("trainees", {}):
		var t: Dictionary = d["trainees"][k]
		trainees[int(k)] = {"center": t["center"], "days": int(t["days"]), "eff": float(t["eff"])}
	research.from_dict(d.get("research", {}))
