class_name HarvestPanel
extends PanelContainer
## Menu Récolter : Couper, Creuser (trou / mine / puits), Cueillir, Chasser, Pêcher.
## Tap = cercle de sélection (rayon 1 à 20) ou boîte de creusage réglable (+ / −), puis Valider. Assigner des lutins.

var game: Node
var mode: String = "cut"
var radius: int = 5
var dims := Vector3i(2, 2, 1)  # largeur, longueur, profondeur
var _center := Vector3i(-1, -1, -1)
var _last_ids: Array = []
var _info: Label
var _dims_label: Label
var _preview: MeshInstance3D
var _mode_buttons: Dictionary = {}
var _assign_box: VBoxContainer


func setup(g: Node) -> void:
	game = g
	var hc: Dictionary = DataRegistry.get_table("world").get("harvest_circle", {})
	radius = int(hc.get("default", 5))
	var dig: Dictionary = DataRegistry.get_table("world").get("dig", {})
	var dd: Array = dig.get("default", [2, 2, 1])
	dims = Vector3i(int(dd[0]), int(dd[1]), int(dd[2]))
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for m: Array in [
		["cut", "Couper"],
		["dig", "Creuser"],
		["well", "Puits"],
		["gather", "Cueillir"],
		["hunt", "Chasser"],
		["fish", "Pêcher"]
	]:
		var b := Button.new()
		b.text = m[1]
		b.custom_minimum_size = Vector2(112, 56)
		b.add_theme_font_size_override("font_size", 19)
		var id: String = m[0]
		b.pressed.connect(func() -> void: _set_mode(id))
		row.add_child(b)
		_mode_buttons[id] = b
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	v.add_child(row2)
	row2.add_child(_btn("−", func() -> void: _adjust(-1)))
	_dims_label = Label.new()
	_dims_label.custom_minimum_size = Vector2(260, 0)
	_dims_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row2.add_child(_dims_label)
	row2.add_child(_btn("+", func() -> void: _adjust(1)))
	for axis: Array in [["Larg", 0], ["Long", 1], ["Prof", 2]]:
		var a: int = axis[1]
		row2.add_child(_btn(axis[0] + "−", func() -> void: _dim(a, -1), 84))
		row2.add_child(_btn(axis[0] + "+", func() -> void: _dim(a, 1), 84))
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	v.add_child(row3)
	var ok := _btn("Valider", _validate, 150)
	UiStyle.make_primary(ok)
	row3.add_child(ok)
	row3.add_child(_btn("Assigner…", _toggle_assign, 150))
	_info = Label.new()
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	row3.add_child(_info)
	_assign_box = VBoxContainer.new()
	_assign_box.visible = false
	v.add_child(_assign_box)
	_preview = MeshInstance3D.new()
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.add_child(_preview)
	_set_mode("cut")


func _btn(t: String, cb: Callable, w: int = 56) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 52)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(cb)
	return b


func _set_mode(m: String) -> void:
	mode = m
	for k: String in _mode_buttons:
		_mode_buttons[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == m else UiStyle.IRON_L))
	_refresh_labels()
	_show_preview()


func _adjust(d: int) -> void:
	var hc: Dictionary = DataRegistry.get_table("world").get("harvest_circle", {})
	radius = clampi(radius + d, int(hc.get("radius_min", 1)), int(hc.get("radius_max", 20)))
	_refresh_labels()
	_show_preview()


func _dim(axis: int, d: int) -> void:
	var dig: Dictionary = DataRegistry.get_table("world").get("dig", {})
	var lim: Array = [dig.get("width", [1, 32]), dig.get("length", [1, 32]), dig.get("depth", [1, 48])]
	dims[axis] = clampi(dims[axis] + d, int(lim[axis][0]), int(lim[axis][1]))
	_refresh_labels()
	_show_preview()


func _refresh_labels() -> void:
	if mode == "dig":
		_dims_label.text = "Trou %d × %d, profondeur %d" % [dims.x, dims.y, dims.z]
	elif mode == "well":
		_dims_label.text = "Puits 1 × 1 jusqu'à la nappe"
	elif mode == "fish":
		_dims_label.text = "Touchez l'eau : poste de pêche"
	else:
		_dims_label.text = "Cercle : rayon %d cases" % radius


func on_tap(screen: Vector2) -> void:
	var cam: Camera3D = game.camera.cam
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if not r["hit"]:
		return
	_center = r["pos"]
	_show_preview()


func _cells() -> Array[Vector3i]:
	if mode == "dig":
		return Shapes.dig_box(_center, dims.x, dims.y, dims.z)
	if mode == "well":
		var wt := int(DataRegistry.get_table("world").get("water_table", 20))
		return Shapes.dig_box(_center, 1, 1, maxi(1, _center.y - wt + 1))
	var empty: Array[Vector3i] = []
	return empty


func _show_preview() -> void:
	if _preview == null or _center.y < 0:
		return
	if mode in ["dig", "well"]:
		var st := SurfaceTool.new()
		for p in _cells():
			var b := BoxMesh.new()
			b.size = Vector3.ONE * 1.03
			st.append_from(b, 0, Transform3D(Basis(), Vector3(p) + Vector3(0.5, 0.5, 0.5)))
		_preview.mesh = st.commit()
		_preview.material_override = BuildTool._ghost_mat(Color(1.0, 0.3, 0.2, 0.4))
	else:
		var t := TorusMesh.new()
		var rr := 0.6 if mode == "fish" else float(radius) + 0.5
		t.inner_radius = rr - 0.15
		t.outer_radius = rr + 0.15
		t.rings = 48
		_preview.mesh = t
		_preview.material_override = LutinModel.mat("c49e54", 0.4, 0.0, 1.2)
		_preview.position = Vector3(_center) + Vector3(0.5, 1.1, 0.5)
		return
	_preview.position = Vector3.ZERO


func _validate() -> void:
	if _center.y < 0:
		_info.text = "Touchez d'abord la carte."
		return
	var b: TaskBoard = game.board
	var before := b.next_id
	var n := 0
	match mode:
		"dig", "well":
			n = b.order_dig(_cells())
		"fish":
			var p := _center + Vector3i.UP
			while game.world.types.liquid[game.world.get_block(p + Vector3i.UP)] == 1:
				p += Vector3i.UP
			n = int(b.add_fish(p) >= 0) if game.world.types.liquid[game.world.get_block(p)] == 1 else 0
		_:
			n = b.order_circle(mode, _center + Vector3i.UP, radius)
	_last_ids = range(before, b.next_id)
	_info.text = "%d ordre(s) ajouté(s) · %d en cours" % [n, b.tasks.size()]
	_center = Vector3i(-1, -1, -1)
	_preview.mesh = null


func _toggle_assign() -> void:
	_assign_box.visible = not _assign_box.visible
	for c in _assign_box.get_children():
		c.queue_free()
	if not _assign_box.visible:
		return
	_assign_box.add_child(UiStyle.title_label("Assigner le dernier ordre à :", 20))
	var row := HFlowContainer.new()
	_assign_box.add_child(row)
	for l: Lutin in game.colony.lutins:
		var b := Button.new()
		b.text = "%s (%s %d)" % [l.name, LutinSheet.job_name(l.job), l.job_level()]
		b.add_theme_font_size_override("font_size", 17)
		b.custom_minimum_size = Vector2(0, 48)
		var lid := l.id
		b.pressed.connect(
			func() -> void:
				for id: int in _last_ids:
					var cur: Array = game.board.tasks.get(id, {}).get("assigned", [])
					if not cur.has(lid):
						cur.append(lid)
					game.board.assign_lutins(id, cur)
				b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD))
		)
		row.add_child(b)


func hide_preview() -> void:
	if _preview:
		_preview.mesh = null
