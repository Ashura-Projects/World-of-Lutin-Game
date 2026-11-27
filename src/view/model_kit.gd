class_name ModelKit
extends RefCounted
## Boîte à outils des modèles low poly : matériaux texturés tirés de l'atlas des blocs (pierre, brique, planche,
## bois, chaume…), plaqués en triplanaire (1 tuile = 1 bloc, pixels nets) pour garder le style du monde ;
## formes de base (boîte, cylindre, cône, sphère, prisme), flamme et lumière.

static var _tiles: Dictionary = {}  # tuile -> ImageTexture
static var _mats: Dictionary = {}
static var _atlas: Image = null


## Matériau texturé d'une tuile de l'atlas (« stone », « brick », « plank », « wood_side »…), teinté au besoin.
static func tex(tile: String, tint: String = "ffffff", scale: float = 1.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [tile, tint, scale]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var t := _tile(tile)
	if t != null:
		m.albedo_texture = t
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.albedo_color = Color(tint)
	m.roughness = 0.92
	_mats[key] = m
	return m


static func _tile(tile: String) -> ImageTexture:
	if _tiles.has(tile):
		return _tiles[tile]
	var cfg := DataRegistry.get_table("atlas")
	var pos: Array = cfg.get("tiles", {}).get(tile, [])
	if pos.is_empty():
		return null
	if _atlas == null:
		var t: Texture2D = load(WorldView.ATLAS_PATH)
		if t == null:
			return null
		_atlas = t.get_image()
		if _atlas.is_compressed():
			_atlas.decompress()
	var sz := int(cfg.get("tile", 32))
	var img := _atlas.get_region(Rect2i(int(pos[0]) * sz, int(pos[1]) * sz, sz, sz))
	img.generate_mipmaps()
	var it := ImageTexture.create_from_image(img)
	_tiles[tile] = it
	return it


## Couleur unie (métal, tissu, flamme…).
static func col(hex: String, rough: float = 0.85, metal: float = 0.0, emit: float = 0.0) -> StandardMaterial3D:
	return LutinModel.mat(hex, rough, metal, emit)


static func _add(r: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	r.add_child(mi)
	return mi


static func box(r: Node3D, size: Vector3, m: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _add(r, b, m, pos, rot)


static func cyl(
	r: Node3D, top: float, bottom: float, h: float, m: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, seg: int = 8
) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return _add(r, c, m, pos, rot)


static func ball(r: Node3D, radius: float, m: Material, pos: Vector3, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 8
	s.rings = 4
	var mi := _add(r, s, m, pos, Vector3.ZERO)
	mi.scale = scale
	return mi


## Prisme triangulaire (toit à deux pans) : arête en haut, le long de Z.
static func prism(r: Node3D, size: Vector3, m: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var p := PrismMesh.new()
	p.size = size
	return _add(r, p, m, pos, rot)


## Roue (cylindre couché sur l'axe X).
static func wheel(r: Node3D, radius: float, width: float, m: Material, pos: Vector3, axis_z: bool = false) -> void:
	cyl(r, radius, radius, width, m, pos, Vector3(PI / 2.0, 0, 0) if axis_z else Vector3(0, 0, PI / 2.0), 10)


static func flame(r: Node3D, pos: Vector3, s: float = 1.0) -> void:
	box(r, Vector3(0.2, 0.28, 0.2) * s, col("ff9a40", 0.8, 0.0, 6.0), pos, Vector3(0, 0.7, 0))
	box(r, Vector3(0.11, 0.2, 0.11) * s, col("fff0b0", 0.8, 0.0, 9.0), pos + Vector3(0, 0.05, 0), Vector3(0, 0.3, 0))


static func light(r: Node3D, pos: Vector3, energy: float = 1.2, rng: float = 6.0, c: String = "ffa050") -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(c)
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	r.add_child(l)


## Petit tas de bûches (couchées sur X).
static func logs(r: Node3D, pos: Vector3, n: int = 3) -> void:
	for i in n:
		cyl(
			r,
			0.09,
			0.09,
			0.7,
			tex("wood_side"),
			pos + Vector3(0, 0.09 + (i / 2) * 0.16, -0.1 + (i % 2) * 0.2 + (i / 2) * 0.1),
			Vector3(0, 0, PI / 2.0)
		)


## Pieds d'établi / de table (4 montants).
static func legs(r: Node3D, w: float, d: float, h: float, m: Material, center: Vector3, t: float = 0.08) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			box(r, Vector3(t, h, t), m, center + Vector3(sx * (w / 2.0 - t), h / 2.0, sz * (d / 2.0 - t)))


## Fusionne les morceaux d'un modèle en un seul maillage (une surface par matériau) : beaucoup moins d'appels
## de dessin, utile pour les tas d'objets répétés.
static func merge(r: Node3D) -> MeshInstance3D:
	var by_mat := {}
	for c in r.get_children():
		if c is MeshInstance3D and c.mesh != null:
			var m: Material = c.material_override
			var st: SurfaceTool = by_mat.get(m)
			if st == null:
				st = SurfaceTool.new()
				by_mat[m] = st
			st.append_from(c.mesh, 0, c.transform)
	var mesh := ArrayMesh.new()
	for m: Material in by_mat:
		var st: SurfaceTool = by_mat[m]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	r.free()
	return mi
