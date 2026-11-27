class_name MapImage
extends RefCounted
## Image de la carte vue du dessus (couleur du bloc de surface + relief), réduite à ~256 px de côté,
## et repérage des minerais proches de la surface (ressources découvertes). À appeler sur un thread de travail.


static func build(world: VoxelWorld) -> Dictionary:
	var cfg := DataRegistry.get_table("map")
	var step := maxi(1, ceili(float(maxi(world.size.x, world.size.z)) / float(cfg.get("max_size", 256))))
	var w := ceili(float(world.size.x) / step)
	var h := ceili(float(world.size.z) / step)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var colors := {}
	var cols: Dictionary = cfg.get("colors", {})
	for b: Dictionary in DataRegistry.get_table("blocks").get("blocks", []):
		colors[int(b["num"])] = Color(str(cols.get(b["id"], cfg.get("default_color", "7a7a72"))))
	var ores := {}
	for id: String in cfg.get("resources", {}):
		ores[world.types.num(id)] = id
	var depth := int(cfg.get("ore_depth", 6))
	var res := []
	for px in w:
		for pz in h:
			var x := px * step
			var z := pz * step
			var y := world.surface_y(x, z)
			var top := world.get_block(Vector3i(x, y - 1, z)) if y > 0 else 0
			var c: Color = colors.get(top, Color(0.4, 0.4, 0.4))
			c = (
				c.lightened(clampf((y - 24) / 80.0, 0.0, 0.35))
				if y > 24
				else c.darkened(clampf((24 - y) / 40.0, 0.0, 0.3))
			)
			img.set_pixel(px, pz, c)
			for dy in range(2, depth):
				var o: int = world.get_block(Vector3i(x, y - dy, z))
				if ores.has(o):
					res.append([Vector2i(x, z), ores[o]])
					break
	return {"image": img, "step": step, "resources": res}
