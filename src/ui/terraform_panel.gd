class_name TerraformPanel
extends PanelContainer
## Menu Terrain (terraformation) : verser de l'eau, remettre terre / herbe / pierre / sable, planter arbres et
## buissons, ou enlever la végétation. Toucher la carte = cercle (rayon − / +), puis Valider. Le coût est affiché ;
## en débug « Terraformation gratuite » tout est instantané et gratuit.

var game: Node
var tool_id: String = "water"
var radius: int = 1
var _center := Vector3i(-1, -1, -1)
var _buttons: Dictionary = {}
var _info: Label
var _radius_label: Label
var _preview: MeshInstance3D


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := UiStyle.title_label("Terrain", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)  # la croix ✕ est ajoutée par HudWindows dans le coin libre de cette ligne
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var all: Array = Terraform.tools().duplicate()
	all.append({"id": "clear", "name": "Enlever"})
	for t: Dictionary in all:
		var b := Button.new()
		b.text = str(t["name"])
		b.tooltip_text = Terraform._cost_text(t)
		b.custom_minimum_size = Vector2(112, 54)
		b.add_theme_font_size_override("font_size", 18)
		var id: String = t["id"]
		b.pressed.connect(func() -> void: _set_tool(id))
		row.add_child(b)
		_buttons[id] = b
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	v.add_child(row2)
	row2.add_child(_btn("−", func() -> void: _adjust(-1), 56))
	_radius_label = Label.new()
	_radius_label.custom_minimum_size = Vector2(170, 0)
	_radius_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row2.add_child(_radius_label)
	row2.add_child(_btn("+", func() -> void: _adjust(1), 56))
	var ok := _btn("Valider", _validate, 150)
	UiStyle.make_primary(ok)
	row2.add_child(ok)
	_info = Label.new()
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(500, 0)
	row2.add_child(_info)
	_preview = MeshInstance3D.new()
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.add_child(_preview)
	visibility_changed.connect(func() -> void: _preview.visible = visible)
	_set_tool("water")


func _btn(t: String, cb: Callable, w: int) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 52)
	b.pressed.connect(cb)
	return b


func _set_tool(id: String) -> void:
	tool_id = id
	for k: String in _buttons:
		_buttons[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == id else UiStyle.IRON_L))
	var t := Terraform.tool_def(id)
	var cost := Terraform._cost_text(t) if not t.is_empty() else "rien (le cueilleur déracine)"
	if game.sim.rules.free_terra:
		cost = "gratuit (débug)"
	_info.text = "Coût par case : %s. Touchez la carte puis Valider." % cost
	if id == "water":
		_info.text += " Un seau d'eau se remplit au puits (Gestion › puits)."
	_refresh()


func _adjust(d: int) -> void:
	var mx := int(DataRegistry.get_table("world").get("terraform", {}).get("radius_max", 6))
	radius = clampi(radius + d, 0, mx)
	_refresh()


func _refresh() -> void:
	_radius_label.text = "Cercle : rayon %d" % radius if radius > 0 else "Une seule case"
	_show_preview()


func on_tap(screen: Vector2) -> void:
	var cam: Camera3D = game.camera.cam
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if not r["hit"]:
		return
	_center = r["pos"] + Vector3i.UP  # case au-dessus du sol touché (ou dans le trou touché)
	_show_preview()


func _show_preview() -> void:
	if _preview == null or _center.y < 0:
		return
	var st := SurfaceTool.new()
	var cells := Terraform.cells_in_circle(game.world, _center, radius)
	if tool_id == "clear":
		cells = [_center]
	for p: Vector3i in cells:
		var b := BoxMesh.new()
		b.size = Vector3(1.0, 0.2, 1.0)
		st.append_from(b, 0, Transform3D(Basis(), Vector3(p) + Vector3(0.5, 0.1, 0.5)))
	_preview.mesh = st.commit() if not cells.is_empty() else null
	var col := Color(0.3, 0.6, 1.0, 0.5) if tool_id == "water" else Color(0.5, 0.9, 0.4, 0.5)
	_preview.material_override = BuildTool._ghost_mat(col)


func _validate() -> void:
	if _center.y < 0:
		_info.text = "Touchez d'abord la carte."
		return
	if tool_id == "clear":
		var n := Clearing.order_circle(game.board, _center, maxi(radius, 0))
		_info.text = "%d arbre(s), buisson(s) ou plante(s) à enlever." % n
	else:
		var res: Array = Terraform.order(game.sim, tool_id, Terraform.cells_in_circle(game.world, _center, radius))
		_info.text = str(res[1])
	_center = Vector3i(-1, -1, -1)
	_preview.mesh = null
