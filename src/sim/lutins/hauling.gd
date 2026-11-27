class_name Hauling
extends RefCounted
## Charrette et catapulte tirées (1.3.1) : elles suivent le lutin de tête et s'orientent dans le sens de la marche ;
## une fois posées, elles gardent cette orientation.


static func tick(sim: GameSim) -> void:
	for l in sim.colony.lutins:
		var o := l.order
		if o.is_empty() or int(o.get("stage", 0)) != 1:
			continue
		var kind := str(o["kind"])
		if kind != "cart" and not (kind == "push" and o.get("lead", false)):
			continue
		var last := Vector2(float(o.get("px", l.pos.x)), float(o.get("pz", l.pos.z)))
		var d := Vector2(l.pos.x, l.pos.z) - last
		o["px"] = l.pos.x
		o["pz"] = l.pos.z
		if d.length() < 0.01:
			continue
		var yaw := atan2(-d.x, -d.y)
		if kind == "cart":
			sim.colony.cart_yaw = yaw
		else:
			var st: Dictionary = sim.structures.items.get(int(o.get("struct", -1)), {})
			if not st.is_empty():
				st["yaw"] = yaw
				st["cell"] = l.cell  # la catapulte suit les pousseurs
