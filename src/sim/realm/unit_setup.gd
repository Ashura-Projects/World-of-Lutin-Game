class_name UnitSetup
extends RefCounted
## Réglages d'une unité (1.4) : type (mixte, cavalerie, fusiliers, lanciers, catapulte), arme et monture pour toute
## l'unité ou pour chaque soldat, catapulte servie, rôles (commandant = capitaine, lieutenants, cuisinier) et
## sous-unités : 0 = celle du commandant ; 1 = la première sous-unité (avec un lieutenant) ; tous les 5 niveaux de
## Commandement du commandant, une sous-unité de plus (data/military.json › soldiers.levels_per_squad).

const TYPES := {
	"mixed": {"name": "Mixte", "weapon": "", "mount": "foot", "catapult": false},
	"cavalry": {"name": "Cavalerie", "weapon": "spear", "mount": "horse", "catapult": false},
	"fusiliers": {"name": "Fusiliers", "weapon": "flintlock", "mount": "foot", "catapult": false},
	"lancers": {"name": "Lanciers", "weapon": "spear", "mount": "foot", "catapult": false},
	"swords": {"name": "Épéistes", "weapon": "short_sword", "mount": "foot", "catapult": false},
	"catapult": {"name": "Catapulte", "weapon": "", "mount": "foot", "catapult": true}
}
const WEAPONS := [["", "Au choix"], ["flintlock", "Fusil"], ["spear", "Lance"], ["short_sword", "Épée"]]


## Valeurs par défaut des champs 1.4 (anciennes sauvegardes, nouvelles unités).
static func defaults(u: Dictionary) -> void:
	for k: String in ["type", "weapon", "mount"]:
		if not u.has(k):
			u[k] = {"type": "mixed", "weapon": "", "mount": "foot"}[k]
	for k: String in ["cook", "catapult_id"]:
		if not u.has(k):
			u[k] = -1
	if not u.has("lieutenants"):
		u["lieutenants"] = {}
		if int(u.get("lieutenant", -1)) >= 0:
			u["lieutenants"][1] = int(u["lieutenant"])  # 1.4 : ancien lieutenant unique
	u.erase("lieutenant")
	if not u.has("gear"):
		u["gear"] = {}
	if not u.has("squads"):
		u["squads"] = {}
	if not u.has("train"):
		u["train"] = "force"


## Choisit un type : arme et monture de toute l'unité (les réglages par soldat restent prioritaires).
static func set_type(units: Units, u: Dictionary, t: String) -> void:
	var d: Dictionary = TYPES.get(t, TYPES["mixed"])
	u["type"] = t
	u["weapon"] = d["weapon"]
	u["mount"] = d["mount"]
	if d["catapult"] and int(u["catapult_id"]) < 0:
		u["catapult_id"] = _free_catapult(units, u)
	elif not d["catapult"]:
		u["catapult_id"] = -1
	apply(units, u)


static func _free_catapult(units: Units, u: Dictionary) -> int:
	var st: Structures = units.colony.structures
	if st == null:
		return -1
	var used := {}
	for o: Dictionary in units.units.values():
		used[int(o.get("catapult_id", -1))] = true
	var cap := units.colony.find_lutin(int(u["captain"]))
	var best := -1
	var bd := INF
	for s: Dictionary in st.items.values():
		if s["kind"] == "catapult" and s["built"] and not used.has(int(s["id"])):
			var d := Vector3(s["cell"]).distance_to(Vector3(cap.cell if cap != null else u["cell"]))
			if d < bd:
				bd = d
				best = int(s["id"])
	return best


## Arme / monture voulue pour ce soldat (son réglage, sinon celui de l'unité).
static func wanted(u: Dictionary, lid: int, key: String) -> String:
	var g: Dictionary = u["gear"].get(lid, {})
	return str(g.get(key, u[key])) if g.has(key) else str(u[key])


static func set_gear(units: Units, u: Dictionary, lid: int, key: String, value: String) -> void:
	var g: Dictionary = u["gear"].get_or_add(lid, {})
	if value == "default":
		g.erase(key)
	else:
		g[key] = value
	apply(units, u)


## Équipe l'unité : chaque soldat prend son arme (réserve ou râtelier) et monte / descend de cheval.
static func apply(units: Units, u: Dictionary) -> void:
	var col := units.colony
	for lid: int in u["members"]:
		var l := col.find_lutin(lid)
		if l == null:
			continue
		var w := wanted(u, lid, "weapon")
		if w != "" and l.weapon != w and col.stock.count(w) > 0:
			if l.weapon != "":
				col.stock.add(l.weapon, 1)
			col.stock.take(w, 1)
			l.weapon = w
		var horse := wanted(u, lid, "mount") == "horse"
		if horse and l.horse < 0 and col.fauna_ref != null:
			var h := _free_horse(col, l.cell)
			if not h.is_empty():
				l.horse = h["id"]
				h["rider"] = l.id
		elif not horse and l.horse >= 0:
			var h2 := col.fauna_ref.find(l.horse) if col.fauna_ref != null else {}
			if not h2.is_empty():
				h2["rider"] = -1
				h2["home"] = l.cell
			l.horse = -1


static func _free_horse(col: Colony, near: Vector3i) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for a: Dictionary in col.fauna_ref.animals:
		if a["kind"] != "horse" or not a.get("owned", false) or int(a.get("rider", -1)) >= 0:
			continue
		var d := Vector3(a["cell"]).distance_to(Vector3(near))
		if d < bd:
			bd = d
			best = a
	return best


## Nombre de sous-unités possibles : 2 (commandant + 1 lieutenant), puis +1 tous les 5 niveaux de Commandement.
static func max_squads(units: Units, u: Dictionary) -> int:
	var cap := units.colony.find_lutin(int(u["captain"]))
	var lvl := Soldiering.skill_level(cap, "command") if cap != null else 0
	return 2 + lvl / maxi(1, int(Soldiering.cfg().get("levels_per_squad", 5)))


## Cuisinier de l'unité.
static func set_cook(u: Dictionary, lid: int) -> void:
	if lid < 0 or Array(u["members"]).has(lid):
		u["cook"] = lid


## Lieutenant d'une sous-unité (1, 2, 3…) : il la mène et elle se commande à part.
static func set_lieutenant(units: Units, u: Dictionary, squad: int, lid: int) -> bool:
	if squad < 1 or squad >= max_squads(units, u) or (lid >= 0 and not Array(u["members"]).has(lid)):
		return false
	if lid == int(u["captain"]):
		return false
	for s: int in u["lieutenants"].keys():
		if int(u["lieutenants"][s]) == lid:
			u["lieutenants"].erase(s)
	if lid < 0:
		u["lieutenants"].erase(squad)
	else:
		u["lieutenants"][squad] = lid
		u["squads"][lid] = squad
	return true


static func lieutenant_of(u: Dictionary, squad: int) -> int:
	return int(u["lieutenants"].get(squad, -1))


static func set_squad(units: Units, u: Dictionary, lid: int, squad: int) -> void:
	if int(u["captain"]) == lid:
		squad = 0
	u["squads"][lid] = clampi(squad, 0, max_squads(units, u) - 1)


static func squad_of(u: Dictionary, lid: int) -> int:
	return int(u["squads"].get(lid, 0))


## Nom du type affiché (le type choisi, ou déduit des armes si mixte).
static func type_name(u: Dictionary) -> String:
	return str(TYPES.get(str(u.get("type", "mixed")), TYPES["mixed"])["name"])


static func _keys_to_str(d: Dictionary) -> Dictionary:
	var out := {}
	for k: Variant in d:
		out[str(k)] = d[k]
	return out


static func gear_to_dict(u: Dictionary) -> Dictionary:
	var g := {}
	for k: int in u["gear"]:
		g[str(k)] = u["gear"][k]
	var s := {}
	for k: int in u["squads"]:
		s[str(k)] = int(u["squads"][k])
	return {
		"type": u["type"],
		"weapon": u["weapon"],
		"mount": u["mount"],
		"lieutenants": _keys_to_str(u["lieutenants"]),
		"cook": u["cook"],
		"catapult_id": u["catapult_id"],
		"gear": g,
		"squads": s,
		"train": u["train"],
		"camp": u.get("camp", [])
	}


static func gear_from_dict(u: Dictionary, e: Dictionary) -> void:
	u["type"] = str(e.get("type", "mixed"))
	u["weapon"] = str(e.get("weapon", ""))
	u["mount"] = str(e.get("mount", "foot"))
	u["lieutenants"] = {}
	var lts: Dictionary = e.get("lieutenants", {})
	for k: String in lts:
		u["lieutenants"][int(k)] = int(lts[k])
	if e.has("lieutenant"):
		u["lieutenant"] = int(e["lieutenant"])
	u["cook"] = int(e.get("cook", -1))
	u["catapult_id"] = int(e.get("catapult_id", -1))
	u["train"] = str(e.get("train", "force"))
	u["camp"] = Array(e.get("camp", [])).map(func(x: Variant) -> int: return int(x))
	u["gear"] = {}
	var g: Dictionary = e.get("gear", {})
	for k: String in g:
		u["gear"][int(k)] = g[k]
	u["squads"] = {}
	var s: Dictionary = e.get("squads", {})
	for k: String in s:
		u["squads"][int(k)] = int(s[k])
	defaults(u)
