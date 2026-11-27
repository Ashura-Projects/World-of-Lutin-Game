class_name ZonesPanel
extends PanelContainer
## Menu Zones : onglets Champs (culture par case ; « Rectangle » = deux taps), Réserves (zones de stockage
## avec filtre : tout, catégories ou objets) et Charrette (un lutin la déplace où l'on veut).

const TABS := [["fields", "Champs"], ["stores", "Réserves"], ["cart", "Charrette"]]

var game: Node
var crop_id: String = "wheat"
var rect_mode: bool = false
var zone_mode: String = "crop"  # crop, store, edit, unstore
var tab: String = "fields"
var filter_panel: StoreFilterPanel
var _first := Vector3i(-1, -1, -1)
var _info: Label
var _tabs: Dictionary = {}
var _choice_buttons: Dictionary = {}
var _choices: HFlowContainer
var _rect_btn: Button
var preview: Array[Vector3i] = []  # cases de champ en aperçu (posées seulement après « Valider »)
var _preview_mmi: MultiMeshInstance3D
var _validate_row: HBoxContainer


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	custom_minimum_size = Vector2(1000, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var t := UiStyle.title_label("Zones", 26)
	t.custom_minimum_size = Vector2(130, 0)
	head.add_child(t)
	for e: Array in TABS:
		var b := Button.new()
		b.text = e[1]
		b.custom_minimum_size = Vector2(170, 50)
		b.pressed.connect(show_tab.bind(str(e[0])))
		head.add_child(b)
		_tabs[e[0]] = b
	_choices = HFlowContainer.new()
	_choices.add_theme_constant_override("h_separation", 6)
	_choices.add_theme_constant_override("v_separation", 6)
	_choices.custom_minimum_size = Vector2(980, 0)
	v.add_child(_choices)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	v.add_child(row2)
	_rect_btn = Button.new()
	_rect_btn.text = "Rectangle"
	_rect_btn.toggle_mode = true
	_rect_btn.custom_minimum_size = Vector2(150, 50)
	_rect_btn.toggled.connect(
		func(on: bool) -> void:
			rect_mode = on
			_first = Vector3i(-1, -1, -1)
	)
	row2.add_child(_rect_btn)
	_info = Label.new()
	_info.add_theme_color_override("font_color", UiStyle.TXT_D)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(800, 0)
	row2.add_child(_info)
	_validate_row = HBoxContainer.new()
	_validate_row.add_theme_constant_override("separation", 8)
	v.add_child(_validate_row)
	var ok := Button.new()
	ok.text = "✔ Valider les champs"
	ok.custom_minimum_size = Vector2(300, 52)
	UiStyle.make_primary(ok)
	ok.pressed.connect(_validate_fields)
	_validate_row.add_child(ok)
	var clr := Button.new()
	clr.text = "Effacer l'aperçu"
	clr.custom_minimum_size = Vector2(240, 52)
	clr.pressed.connect(func() -> void: _set_preview([]))
	_validate_row.add_child(clr)
	_preview_mmi = MultiMeshInstance3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.85, 0.35, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := PlaneMesh.new()
	q.size = Vector2(0.9, 0.9)
	q.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = q
	_preview_mmi.multimesh = mm
	g.add_child.call_deferred(_preview_mmi)
	visibility_changed.connect(func() -> void: _preview_mmi.visible = visible)
	filter_panel = StoreFilterPanel.new()
	filter_panel.setup(g)
	filter_panel.visible = false
	show_tab("fields")


func show_tab(t: String) -> void:
	tab = t
	_first = Vector3i(-1, -1, -1)
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == t else UiStyle.IRON_L))
	for c in _choices.get_children():
		c.queue_free()
	_choice_buttons.clear()
	_rect_btn.visible = t != "cart"
	if _validate_row != null:
		_validate_row.visible = t == "fields"
	match t:
		"fields":
			for c: Dictionary in DataRegistry.get_table("crops").get("crops", []):
				_choice(str(c["id"]), str(c["name"]))
			_select(crop_id)
		"stores":
			_choice("store", "Nouvelle réserve")
			_choice("edit", "Régler une réserve")
			_choice("unstore", "Retirer")
			_select("store")
		"cart":
			var b := Button.new()
			b.text = "Déplacer la charrette…"
			b.custom_minimum_size = Vector2(320, 54)
			UiStyle.make_primary(b)
			b.pressed.connect(_move_cart)
			_choices.add_child(b)
			zone_mode = "none"
			_info.text = "La charrette est la réserve principale : un lutin libre va la tirer jusqu'à l'endroit touché."


func _choice(id: String, label: String) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(150, 52)
	b.pressed.connect(_select.bind(id))
	_choices.add_child(b)
	_choice_buttons[id] = b


func _select(id: String) -> void:
	zone_mode = id if id in ["store", "edit", "unstore"] else "crop"
	if zone_mode == "crop":
		crop_id = id
	for k: String in _choice_buttons:
		_choice_buttons[k].add_theme_stylebox_override(
			"normal", UiStyle.box(UiStyle.BLOOD if k == id else UiStyle.IRON_L)
		)
	match zone_mode:
		"store":
			_info.text = "Touchez le sol (ou 2 coins en Rectangle) : nouvelle réserve, puis choisissez ce qu'elle garde."
		"edit":
			_info.text = "Touchez une réserve (dalles dorées) pour choisir ce qu'elle garde."
		"unstore":
			_info.text = "Touchez les cases de réserve à retirer (ou 2 coins en Rectangle)."
		_:
			var c := Fields.crop(id)
			_info.text = (
				"%s : semis %s, %d jours, 1 → %s"
				% [c.get("name", id), ", ".join(c.get("sow", [])), int(c.get("grow_days", 8)), str(c.get("yield", {}))]
			)


static func farmable(world: VoxelWorld, cell: Vector3i) -> bool:
	var id := world.get_block(cell)
	var ok := [
		world.types.num("grass"),
		world.types.num("dirt"),
		world.types.num("fertile_soil"),
		world.types.num("field_plot")
	]
	return ok.has(id) and world.types.solid[world.get_block(cell + Vector3i.UP)] == 0


func on_tap(screen: Vector2) -> void:
	if zone_mode == "none":
		return
	var cam: Camera3D = game.camera.cam
	var r := VoxelRaycast.cast(game.world, cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if not r["hit"]:
		return
	var cell: Vector3i = r["pos"]
	if zone_mode == "edit":
		var z: Dictionary = game.colony.stores.zone_at(cell + Vector3i.UP)
		if z.is_empty():
			_info.text = "Ce n'est pas une réserve."
		else:
			filter_panel.open(int(z["id"]))
		return
	var cells: Array[Vector3i] = [cell]
	if rect_mode:
		if _first.y < 0:
			_first = cell
			_info.text = "Touchez le coin opposé."
			return
		cells = Shapes.rect(_first, Vector3i(cell.x, _first.y, cell.z))
		_first = Vector3i(-1, -1, -1)
	if zone_mode != "crop":
		_store(cells)
		return
	var list := preview.duplicate()
	for p in cells:
		var top := Vector3i(p.x, game.world.surface_y(p.x, p.z) - 1, p.z)
		if farmable(game.world, top):
			if list.has(top):
				list.erase(top)  # toucher une case en aperçu l'enlève
			else:
				list.append(top)
	_set_preview(list)
	_info.text = (
		"Aperçu : %d case(s) de %s. Touchez « Valider » pour les planter."
		% [preview.size(), Fields.crop(crop_id).get("name", crop_id)]
	)


func _set_preview(list: Array) -> void:
	preview.assign(list)
	var mm := _preview_mmi.multimesh
	mm.instance_count = preview.size()
	for i in preview.size():
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(preview[i]) + Vector3(0.5, 1.06, 0.5)))
	_validate_row.visible = tab == "fields"


## Valider : les cases en aperçu deviennent des champs de la culture choisie.
func _validate_fields() -> void:
	var n := 0
	for top in preview:
		if farmable(game.world, top):
			game.fields.plan(top, crop_id)
			n += 1
	_set_preview([])
	_info.text = "%d case(s) de %s plantée(s)." % [n, Fields.crop(crop_id).get("name", crop_id)]


func _store(cells: Array[Vector3i]) -> void:
	var tops: Array = []
	for p in cells:
		tops.append(Vector3i(p.x, game.world.surface_y(p.x, p.z), p.z))
	if zone_mode == "store":
		var id: int = game.colony.stores.add_zone(tops)
		if id < 0:
			_info.text = "Pas de case libre et praticable ici."
			return
		_info.text = "Réserve créée (%d case(s))." % game.colony.stores.find(id)["cells"].size()
		filter_panel.open(id)
	else:
		game.colony.remove_store_cells(tops)
		_info.text = "Réserve retirée."


## Un lutin adulte libre (le plus proche de la charrette) va la tirer jusqu'à l'endroit touché.
func _move_cart() -> void:
	game.hud.menu_button("Zones").button_pressed = false
	game.hud.windows.pick_cell(
		"Touchez où amener la charrette",
		func(cell: Vector3i) -> void:
			var best: Lutin = null
			var bd := INF
			for l: Lutin in game.colony.lutins:
				if l.can_work() and not l.mobilized and l.jailed.y < 0:
					var d := Vector3(l.cell).distance_squared_to(Vector3(game.colony.stock.pos))
					if d < bd:
						bd = d
						best = l
			if best != null and LutinOrders.give(game.colony, game.board, best, "cart", cell):
				EventBus.alert.emit("ordre", "%s va déplacer la charrette." % best.name)
	)
