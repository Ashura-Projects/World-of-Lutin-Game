class_name Lutin
extends RefCounted
## Un lutin : identité, âge, métiers connus (niveau + XP), besoins, position et chemin.

enum State { IDLE, WALK, SLEEP, EAT, WORK }

var id: int = 0
var name: String = ""
var sex: String = "f"
var age_days: int = 80
var job: String = "hauler"
var jobs_known: Dictionary = {}  # id métier -> {"level": int, "xp": float}
var aptitudes: Dictionary = {"knowledge": 0, "strength": 0, "dexterity": 0}
var needs: Dictionary = {"hunger": 100.0, "sleep": 100.0, "warmth": 100.0, "mood": 70.0}
var hp: float = 50.0
var pos := Vector3.ZERO  # pieds du lutin (coordonnées monde)
var cell := Vector3i.ZERO
var path: Array[Vector3i] = []
var path_i: int = 0
var state: State = State.IDLE
var wait_ticks: int = 0
var task_id: int = -1
var carrying: Dictionary = {}  # {"id": ressource, "n": quantité}
var home := Vector3i(-1, -1, -1)  # tente ou lit attribué
var mobilized: bool = false
var weapon: String = ""  # arme prise en réserve pendant la mobilisation
var combat_xp: float = 0.0
var kills: Dictionary = {}  # espèce -> nombre abattu
var hiding: bool = false
var attack_cool: int = 0
var trained: Dictionary = {}  # métier formé -> efficacité (1.0 enfant éduqué, 0.5 formation courte d'adulte)
var parents: Array = []
var pending_path: bool = false  # une recherche de chemin est en cours (non sauvegardé)


func place_at(c: Vector3i) -> void:
	cell = c
	pos = Vector3(c) + Vector3(0.5, 0.0, 0.5)
	path = []
	path_i = 0


func set_path(p: Array[Vector3i]) -> void:
	path = p
	path_i = 1 if p.size() > 1 else p.size()
	state = State.WALK if path_i < path.size() else State.IDLE


func has_path() -> bool:
	return path_i < path.size()


## Avance le long du chemin. Renvoie true à l'arrivée.
func walk(distance: float) -> bool:
	while distance > 0.0 and path_i < path.size():
		var target := Vector3(path[path_i]) + Vector3(0.5, 0.0, 0.5)
		var to := target - pos
		var len := to.length()
		if len <= distance:
			pos = target
			cell = path[path_i]
			path_i += 1
			distance -= len
		else:
			pos += to / len * distance
			distance = 0.0
	return path_i >= path.size()


## Change de métier (base : libre). Métier jamais pratiqué → niveau 1 ; déjà connu → garde son niveau (validé).
## Âge : baby / child / adult / elder (data/population.json).
func age_stage() -> String:
	var stage := "adult"
	for a: Dictionary in DataRegistry.get_table("population").get("ages", []):
		if age_days >= int(a["from_day"]):
			stage = a["id"]
	return stage


func can_work() -> bool:
	return age_stage() in ["adult", "elder"]


func set_job(j: String) -> void:
	job = j
	if not jobs_known.has(j):
		jobs_known[j] = {"level": 1, "xp": 0.0}


func job_level(j: String = "") -> int:
	return int(jobs_known.get(job if j == "" else j, {}).get("level", 1))


func add_xp(amount: float, xp_per_level: float) -> void:
	var k: Dictionary = jobs_known.get_or_add(job, {"level": 1, "xp": 0.0})
	k["xp"] = float(k["xp"]) + amount
	while float(k["xp"]) >= xp_per_level * int(k["level"]):
		k["xp"] = float(k["xp"]) - xp_per_level * int(k["level"])
		k["level"] = int(k["level"]) + 1


func to_dict() -> Dictionary:
	var p := []
	for c in path:
		p.append([c.x, c.y, c.z])
	return {
		"id": id,
		"name": name,
		"sex": sex,
		"age": age_days,
		"job": job,
		"jobs": jobs_known,
		"apt": aptitudes,
		"needs": needs,
		"hp": hp,
		"pos": [pos.x, pos.y, pos.z],
		"cell": [cell.x, cell.y, cell.z],
		"path": p,
		"path_i": path_i,
		"state": state,
		"wait": wait_ticks,
		"task": task_id,
		"carry": carrying,
		"home": [home.x, home.y, home.z],
		"mob": mobilized,
	}


func from_dict(d: Dictionary) -> void:
	id = int(d["id"])
	name = d["name"]
	sex = d.get("sex", "f")
	age_days = int(d["age"])
	job = d["job"]
	jobs_known = d.get("jobs", {})
	for k: String in jobs_known:
		jobs_known[k] = {"level": int(jobs_known[k]["level"]), "xp": float(jobs_known[k]["xp"])}
	aptitudes = {}
	var apt: Dictionary = d.get("apt", {})
	for k: String in apt:
		aptitudes[k] = int(apt[k])
	needs = d["needs"]
	hp = float(d.get("hp", 50))
	var p: Array = d["pos"]
	pos = Vector3(p[0], p[1], p[2])
	var c: Array = d["cell"]
	cell = Vector3i(int(c[0]), int(c[1]), int(c[2]))
	path = []
	for q: Array in d.get("path", []):
		path.append(Vector3i(int(q[0]), int(q[1]), int(q[2])))
	path_i = int(d.get("path_i", 0))
	state = int(d.get("state", 0)) as State
	wait_ticks = int(d.get("wait", 0))
	task_id = int(d.get("task", -1))
	carrying = d.get("carry", {})
	var h: Array = d.get("home", [-1, -1, -1])
	home = Vector3i(int(h[0]), int(h[1]), int(h[2]))
	mobilized = bool(d.get("mob", false))
	weapon = str(d.get("weapon", ""))
	combat_xp = float(d.get("cxp", 0.0))
	kills = {}
	var ks: Dictionary = d.get("kills", {})
	for k: String in ks:
		kills[k] = int(ks[k])
	hiding = bool(d.get("hiding", false))
	trained = {}
	var tr: Dictionary = d.get("trained", {})
	for k: String in tr:
		trained[k] = float(tr[k])
	parents = []
	for p_id in d.get("parents", []):
		parents.append(int(p_id))
