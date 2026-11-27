class_name Gates
extends RefCounted
## Herses (2 de large × 3 de haut) et ponts-levis (1 à 4 de large × 1 à 4 de long), 1.3.
## Une fois bâtis, on les ouvre / ferme d'un toucher (dialogue) ; le cadenas empêche de les manœuvrer.
## Fermée, une herse remplit son ouverture de blocs « gate_solid » (invisibles, solides) ; baissé, un pont-levis
## pose son tablier en gate_solid au-dessus du vide. Un modèle 3D animé montre la herse / le pont.

signal changed(id: int)

var world: VoxelWorld
var structures: Structures
var gates: Dictionary = {}  # id -> {"id", "struct_id", "kind", "cell", "rot", "w", "l", "open", "locked"}
var next_id: int = 1
var _block: int = -1
var fences: Dictionary = {}  # case -> id de la clôture (bloc invisible solide : les bêtes ne passent pas)


func _init(w: VoxelWorld, s: Structures) -> void:
	world = w
	structures = s
	_block = w.types.num("gate_solid")


## Axe de la largeur (le long du mur) et direction « devant » selon le sens (0 à 3).
static func axes(rot: int) -> Array:
	var across := Vector3i(1, 0, 0) if rot % 2 == 0 else Vector3i(0, 0, 1)
	var fwd: Vector3i = [Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0)][rot % 4]
	return [across, fwd]


## Cases occupées quand la herse est fermée / le pont-levis baissé.
func cells(g: Dictionary) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var ax := axes(int(g["rot"]))
	var c: Vector3i = g["cell"]
	if g["kind"] == "portcullis":
		for i in 2:
			for j in 3:
				out.append(c + ax[0] * i + Vector3i.UP * j)
	elif g["kind"] == "door":
		for i in int(g["w"]):
			for j in 2:
				out.append(c + ax[0] * i + Vector3i.UP * j)
	else:
		for k in range(1, int(g["l"]) + 1):
			for i in int(g["w"]):
				out.append(c + Vector3i.DOWN + ax[1] * k + ax[0] * i)
	return out


## Crée la herse / le pont pour un objet bâti (appelé quand la construction se termine).
func sync_with_structures() -> void:
	for s: Dictionary in structures.items.values():
		var kind := str(Structures.def(s["kind"]).get("gate", ""))
		if kind == "" and Structures.def(s["kind"]).get("tags", []).has("door"):
			kind = "door"  # portes : ouvrir, fermer, verrouiller ; les lutins passent si elles ne sont pas verrouillées
		if (
			kind == ""
			or not s["built"]
			or gates.values().any(func(g: Dictionary) -> bool: return g["struct_id"] == s["id"])
		):
			continue
		var g := {
			"id": next_id,
			"struct_id": s["id"],
			"kind": kind,
			"cell": s["cell"],
			"rot": int(s.get("rot", 0)),
			"w": (2 if s["kind"] == "double_door" else 1) if kind == "door" else int(s.get("gate_w", 2)),
			"door": s["kind"],
			"l": int(s.get("gate_l", 2)),
			"open": true,  # au départ : herse levée, pont baissé (on passe)
			"locked": false
		}
		gates[next_id] = g
		next_id += 1
		_apply(g)
	for g: Dictionary in gates.values().duplicate():
		if not structures.items.has(g["struct_id"]):
			_clear(g)
			gates.erase(g["id"])
	_sync_fences()


## Clôtures bâties : un bloc invisible solide dans leur case ; retiré quand on les démonte.
func _sync_fences() -> void:
	for s: Dictionary in structures.items.values():
		if s["kind"] == "fence" and s["built"] and not fences.has(s["cell"]):
			fences[s["cell"]] = s["id"]
			for c: Vector3i in [s["cell"], s["cell"] + Vector3i.UP]:  # 2 de haut : on ne saute pas par-dessus
				if world.get_block(c) == 0:
					world.set_block(c, _block)
	for c: Vector3i in fences.keys():
		var s: Dictionary = structures.items.get(fences[c], {})
		if s.is_empty() or s["cell"] != c:
			fences.erase(c)
			for q: Vector3i in [c, c + Vector3i.UP]:
				if world.get_block(q) == _block:
					world.set_block(q, 0)


## Pose ou retire les blocs selon l'état.
func _apply(g: Dictionary) -> void:
	var filled: bool = (g["kind"] == "portcullis" and not g["open"]) or (g["kind"] == "drawbridge" and g["open"])
	if g["kind"] == "door":
		filled = g["locked"]  # porte non verrouillée : les lutins l'ouvrent pour passer
		if str(g.get("door", "")) == "fence_gate":
			filled = g["locked"] or not g["open"]  # portillon fermé : les bêtes restent dans l'enclos
	for c in cells(g):
		var cur := world.get_block(c)
		if filled and cur == 0:
			world.set_block(c, _block)
		elif not filled and cur == _block:
			world.set_block(c, 0)
	changed.emit(g["id"])


func _clear(g: Dictionary) -> void:
	for c in cells(g):
		if world.get_block(c) == _block:
			world.set_block(c, 0)


func toggle(id: int) -> bool:
	var g: Dictionary = gates.get(id, {})
	if g.is_empty() or g["locked"]:
		return false
	g["open"] = not g["open"]
	_apply(g)
	return true


func set_locked(id: int, on: bool) -> void:
	if gates.has(id):
		gates[id]["locked"] = on
		if on and gates[id]["kind"] == "door":
			gates[id]["open"] = false
		_apply(gates[id])


## Herse ou pont-levis à cette case (case du tablier, de l'ouverture ou de l'objet), sinon {}.
func for_struct(struct_id: int) -> Dictionary:
	for g: Dictionary in gates.values():
		if int(g["struct_id"]) == struct_id:
			return g
	return {}


func at(cell: Vector3i) -> Dictionary:
	for g: Dictionary in gates.values():
		if g["cell"] == cell or g["cell"] + Vector3i.DOWN == cell:
			return g
		var ax := axes(int(g["rot"]))
		for c in cells(g):
			if c == cell:
				return g
		if g["kind"] == "portcullis":
			for i in 2:
				for j in 3:
					if g["cell"] + ax[0] * i + Vector3i.UP * j == cell:
						return g
	return {}


static func name_of(g: Dictionary) -> String:
	if g["kind"] == "door":
		return str(Structures.def(str(g.get("door", "door"))).get("name", "Porte"))
	return "Herse" if g["kind"] == "portcullis" else "Pont-levis %d × %d" % [int(g["w"]), int(g["l"])]


func state_text(g: Dictionary) -> String:
	var s: String
	if g["kind"] == "door":
		s = "ouverte" if g["open"] else "fermée (les lutins l'ouvrent pour passer)"
	elif g["kind"] == "portcullis":
		s = "levée (ouverte)" if g["open"] else "baissée (fermée)"
	else:
		s = "baissé (on passe)" if g["open"] else "levé (passage coupé)"
	return s + (" · verrouillé" if g["locked"] else "")


func to_dict() -> Dictionary:
	var out := []
	for g: Dictionary in gates.values():
		var c: Vector3i = g["cell"]
		var e := g.duplicate()
		e["cell"] = [c.x, c.y, c.z]
		out.append(e)
	return {"gates": out, "next_id": next_id}


func from_dict(d: Dictionary) -> void:
	gates.clear()
	for e: Dictionary in d.get("gates", []):
		var c: Array = e["cell"]
		var g := e.duplicate()
		g["cell"] = Vector3i(int(c[0]), int(c[1]), int(c[2]))
		for k: String in ["id", "struct_id", "rot", "w", "l"]:
			g[k] = int(e[k])
		gates[g["id"]] = g
	next_id = int(d.get("next_id", gates.size() + 1))
