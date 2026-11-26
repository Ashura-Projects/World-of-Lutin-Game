class_name Fields
extends RefCounted
## Champs case par case : culture choisie par case, labour, semis (saison), croissance (jours), récolte (+ paille).

signal changed(cell: Vector3i)

var plots: Dictionary = {}  # case du sol (bloc field_plot) -> {"crop", "state": planned/tilled/sown/ripe, "growth": jours}


static func crop(id: String) -> Dictionary:
	for c: Dictionary in DataRegistry.get_table("crops").get("crops", []):
		if c["id"] == id:
			return c
	return {}


func plan(cell: Vector3i, crop_id: String) -> void:
	plots[cell] = {"crop": crop_id, "state": "planned", "growth": 0.0}
	changed.emit(cell)


func set_state(cell: Vector3i, state: String) -> void:
	if plots.has(cell):
		plots[cell]["state"] = state
		if state == "sown":
			plots[cell]["growth"] = 0.0
		changed.emit(cell)


## Peut-on semer aujourd'hui ? (saison de semis de la culture)
static func can_sow_now(crop_id: String) -> bool:
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	var sid: String = seasons[GameClock.season_index()]["id"] if not seasons.is_empty() else ""
	return crop(crop_id).get("sow", []).has(sid)


## Croissance quotidienne (rien ne pousse l'hiver), multipliée par la fertilité.
func grow_day(world: VoxelWorld) -> void:
	var seasons: Array = DataRegistry.get_table("time").get("seasons", [])
	if not seasons.is_empty() and seasons[GameClock.season_index()]["id"] == "winter":
		if not bool(DataRegistry.get_table("crops").get("winter_growth", false)):
			return
	for cell: Vector3i in plots:
		var p: Dictionary = plots[cell]
		if p["state"] != "sown":
			continue
		p["growth"] = float(p["growth"]) + 1.0
		if float(p["growth"]) >= float(crop(p["crop"]).get("grow_days", 8)):
			p["state"] = "ripe"
			changed.emit(cell)


## Rendement d'une case : rendement de base × fertilité × bonus du fermier (arrondi).
static func harvest_yield(crop_id: String, fertile: bool, farmer_level: int) -> Dictionary:
	var cfg := DataRegistry.get_table("crops")
	var mult := float(cfg.get("fertile_multiplier", 1.3)) if fertile else 1.0
	mult *= 1.0 + float(cfg.get("farmer_level_bonus", 0.05)) * (farmer_level - 1)
	var out := {}
	var y: Dictionary = crop(crop_id).get("yield", {})
	for k: String in y:
		out[k] = maxi(1, roundi(float(y[k]) * mult))
	return out


func to_dict() -> Dictionary:
	var out := []
	for c: Vector3i in plots:
		out.append([c.x, c.y, c.z, plots[c]["crop"], plots[c]["state"], plots[c]["growth"]])
	return {"plots": out}


func from_dict(d: Dictionary) -> void:
	plots.clear()
	for e: Array in d.get("plots", []):
		plots[Vector3i(int(e[0]), int(e[1]), int(e[2]))] = {"crop": e[3], "state": e[4], "growth": float(e[5])}
