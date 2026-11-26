class_name BuildPanel
extends PanelContainer
## Barre du mode Construire : matériaux, formes, hauteur du mur, annuler / rétablir.

var tool: BuildTool
var _height_label: Label
var _mode_buttons: Array[Button] = []
var _mat_buttons: Dictionary = {}
var _locks: Dictionary = {}  # bouton -> id bloqué par une technologie


func setup(t: BuildTool) -> void:
	tool = t
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.92), UiStyle.GOLD, 2, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var mats := HBoxContainer.new()
	mats.add_theme_constant_override("separation", 6)
	v.add_child(mats)
	var atlas: Texture2D = load(WorldView.ATLAS_PATH)
	var cols := tool.world.types.atlas_cols
	var first := true
	for b: Dictionary in DataRegistry.get_table("blocks").get("blocks", []):
		if not b.has("cost") or b.get("surface", false) or b["id"] == "field_plot":
			continue
		var n := int(b["num"])
		var btn := Button.new()
		btn.tooltip_text = b["name"]
		btn.custom_minimum_size = Vector2(64, 64)
		var at := AtlasTexture.new()
		at.atlas = atlas
		var tile := tool.world.types.tile_side[n]
		at.region = Rect2((tile % cols) * 32, (tile / cols) * 32, 32, 32)
		btn.icon = at
		btn.expand_icon = true
		btn.pressed.connect(func() -> void: _select_material(n))
		mats.add_child(btn)
		_locks[btn] = b["id"]
		_mat_buttons[n] = btn
		if first:
			_select_material(n)
			first = false
	var objs := HBoxContainer.new()
	objs.add_theme_constant_override("separation", 6)
	v.add_child(objs)
	for b: Dictionary in DataRegistry.get_table("buildings").get("buildings", []):
		if not b.get("available_from_start", false) or b.get("zone", false):
			continue
		var ob := Button.new()
		ob.text = b["name"]
		ob.custom_minimum_size = Vector2(0, 50)
		ob.add_theme_font_size_override("font_size", 17)
		var kind: String = b["id"]
		ob.pressed.connect(
			func() -> void:
				_select_mode(BuildTool.Mode.OBJECT)
				tool.object_kind = kind
		)
		objs.add_child(ob)
		_locks[ob] = kind
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var labels := ["Bloc", "Ligne", "Remplir", "Mur", "Gomme"]
	for i in labels.size():
		var b := Button.new()
		b.text = labels[i]
		b.custom_minimum_size = Vector2(110, 56)
		b.add_theme_font_size_override("font_size", 20)
		var m := i
		b.pressed.connect(func() -> void: _select_mode(m))
		row.add_child(b)
		_mode_buttons.append(b)
	for road: Array in [["road_dirt", "Route terre"], ["road_stone", "Route pavée"]]:
		var rb := Button.new()
		rb.text = road[1]
		rb.custom_minimum_size = Vector2(130, 56)
		rb.add_theme_font_size_override("font_size", 18)
		var rid := tool.world.types.num(road[0])
		rb.pressed.connect(
			func() -> void:
				_select_mode(BuildTool.Mode.ROAD)
				tool.material_id = rid
		)
		row.add_child(rb)
	row.add_child(_small("−", func() -> void: _height(-1)))
	_height_label = Label.new()
	_height_label.custom_minimum_size = Vector2(70, 0)
	_height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_height_label)
	row.add_child(_small("+", func() -> void: _height(1)))
	row.add_child(_small("↶", func() -> void: tool.history.undo()))
	row.add_child(_small("↷", func() -> void: tool.history.redo()))
	_select_mode(0)
	_height(0)


func _process(_d: float) -> void:
	if not visible or Engine.get_process_frames() % 30 != 0:
		return
	for b: Button in _locks:
		var locked := Research.is_locked(_locks[b])
		b.disabled = locked
		b.tooltip_text = "Technologie requise" if locked else ""


func _small(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 56)
	b.pressed.connect(cb)
	return b


func _select_material(n: int) -> void:
	tool.material_id = n
	for k: int in _mat_buttons:
		var on := k == n
		_mat_buttons[k].add_theme_stylebox_override(
			"normal", UiStyle.box(UiStyle.BLOOD if on else UiStyle.IRON_L, UiStyle.GOLD if on else UiStyle.GOLD_D)
		)


func _select_mode(m: int) -> void:
	tool.mode = m as BuildTool.Mode
	for i in _mode_buttons.size():
		_mode_buttons[i].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if i == m else UiStyle.IRON_L))


func _height(d: int) -> void:
	tool.wall_height = clampi(tool.wall_height + d, 1, 16)
	_height_label.text = "Mur %d" % tool.wall_height
