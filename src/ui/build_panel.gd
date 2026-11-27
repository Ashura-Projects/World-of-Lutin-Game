class_name BuildPanel
extends PanelContainer
## Menu Construire : catégories en onglets en haut (Blocs, Sols et routes, Meubles, Décoration, Ateliers, Bâtiments),
## choix en dessous, puis les formes et outils. Choisir un élément réduit le menu en bulle (on voit l'écran) ;
## toucher la bulle le rouvre. « Déplacer » : 1 doigt bouge la caméra au lieu de construire.

signal collapsed(label: String)

const CATEGORIES := [
	["blocks", "Blocs"],
	["ground", "Sols et routes"],
	["furniture", "Meubles"],
	["decor", "Décoration"],
	["workshops", "Ateliers"],
	["buildings", "Bâtiments"],
	["defense", "Défense"],
	["religion", "Religion"],
]
const FURNITURE := [
	"bed",
	"wood_bed",
	"table",
	"chair",
	"bench",
	"chest",
	"wardrobe",
	"shelf",
	"door",
	"barrel",
	"crate",
	"throne",
	"wood_cage",
	"iron_cage"
]
const GROUND := ["road_dirt", "road_stone", "dirt_block", "training_ground"]
const DEFENSE := ["crenel", "rampart", "barracks", "watchtower", "claim_post", "weapon_rack"]
const RELIGION := ["chapel", "church", "altar", "church_bell"]

var tool: BuildTool
var board: TaskBoard
var category: String = "blocks"
var selection_label: String = ""
var _tabs: Dictionary = {}
var _choices: HFlowContainer
var _choice_buttons: Dictionary = {}  # bouton -> id (pour les verrous de technologie)
var _mode_buttons: Dictionary = {}
var _height_label: Label
var _move_btn: Button


func setup(t: BuildTool, b: TaskBoard) -> void:
	tool = t
	board = b
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.94), UiStyle.GOLD, 2, 8))
	custom_minimum_size = Vector2(1240, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	# 1) catégories
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for c: Array in CATEGORIES:
		var tb := Button.new()
		tb.text = c[1]
		tb.custom_minimum_size = Vector2(134, 52)
		tb.add_theme_font_size_override("font_size", 16)
		tb.pressed.connect(show_category.bind(str(c[0])))
		tabs.add_child(tb)
		_tabs[c[0]] = tb
	var close := _small("▾", collapse)
	close.tooltip_text = "Réduire"
	tabs.add_child(close)
	# 2) choix de la catégorie
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1210, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_choices = HFlowContainer.new()
	_choices.custom_minimum_size = Vector2(1190, 0)
	_choices.add_theme_constant_override("h_separation", 6)
	_choices.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_choices)
	# 3) formes et outils
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for m: Array in [
		[BuildTool.Mode.BLOCK, "Bloc"],
		[BuildTool.Mode.LINE, "Ligne"],
		[BuildTool.Mode.FILL, "Remplir"],
		[BuildTool.Mode.WALL, "Mur"],
		[BuildTool.Mode.ERASE, "Gomme"]
	]:
		var b2 := Button.new()
		b2.text = m[1]
		b2.custom_minimum_size = Vector2(118, 54)
		b2.add_theme_font_size_override("font_size", 19)
		b2.pressed.connect(_select_mode.bind(int(m[0])))
		row.add_child(b2)
		_mode_buttons[int(m[0])] = b2
	row.add_child(_small("−", func() -> void: _height(-1)))
	_height_label = Label.new()
	_height_label.custom_minimum_size = Vector2(80, 0)
	_height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_height_label)
	row.add_child(_small("+", func() -> void: _height(1)))
	var undo := Button.new()
	undo.text = "↶ Annuler"
	undo.custom_minimum_size = Vector2(150, 54)
	undo.tooltip_text = "Annule le dernier plan posé"
	undo.pressed.connect(_undo)
	row.add_child(undo)
	_move_btn = Button.new()
	_move_btn.text = "✋ Déplacer"
	_move_btn.toggle_mode = true
	_move_btn.custom_minimum_size = Vector2(170, 54)
	_move_btn.toggled.connect(_on_move_toggled)
	row.add_child(_move_btn)
	_height(0)
	show_category("blocks")
	_select_mode(BuildTool.Mode.BLOCK)


func _undo() -> void:
	if board != null:
		TaskCancel.undo_last_plans(board)
	else:
		tool.history.undo()


func _small(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 52)
	b.pressed.connect(cb)
	return b


## Choix de la catégorie : remplit la zone des choix.
func show_category(cat: String) -> void:
	category = cat
	for k: String in _tabs:
		_tabs[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == cat else UiStyle.IRON_L))
	for c in _choices.get_children():
		c.queue_free()
	_choice_buttons.clear()
	match cat:
		"blocks", "ground":
			for b: Dictionary in DataRegistry.get_table("blocks").get("blocks", []):
				if not b.has("cost") or b["id"] == "field_plot" or DEFENSE.has(b["id"]):
					continue
				if (cat == "ground") != (GROUND.has(b["id"]) or b.get("surface", false)):
					continue
				_add_block_choice(b)
		"defense":
			for b: Dictionary in DataRegistry.get_table("blocks").get("blocks", []):
				if DEFENSE.has(b["id"]):
					_add_block_choice(b)
			for b: Dictionary in DataRegistry.get_table("buildings").get("buildings", []):
				if DEFENSE.has(b["id"]):
					_add_object_choice(b)
		_:
			for b: Dictionary in DataRegistry.get_table("buildings").get("buildings", []):
				if b.get("zone", false) or _building_category(b) != cat:
					continue
				_add_object_choice(b)
	_refresh_locks()


static func _building_category(b: Dictionary) -> String:
	if RELIGION.has(b["id"]):
		return "religion"
	if DEFENSE.has(b["id"]):
		return "defense"
	if FURNITURE.has(b["id"]):
		return "furniture"
	if b.get("object", false):
		return "decor"
	if b.has("station"):
		return "workshops"
	return "buildings"


func _add_block_choice(b: Dictionary) -> void:
	var n := int(b["num"])
	var btn := Button.new()
	btn.text = b["name"]
	btn.custom_minimum_size = Vector2(190, 62)
	btn.add_theme_font_size_override("font_size", 17)
	var at := AtlasTexture.new()
	at.atlas = load(WorldView.ATLAS_PATH)
	var cols := tool.world.types.atlas_cols
	var tile := tool.world.types.tile_top[n] if b.get("surface", false) else tool.world.types.tile_side[n]
	at.region = Rect2((tile % cols) * 32, (tile / cols) * 32, 32, 32)
	btn.icon = at
	btn.expand_icon = false
	btn.add_theme_constant_override("icon_max_width", 40)
	btn.pressed.connect(_choose_block.bind(n, str(b["name"]), bool(b.get("surface", false))))
	_choices.add_child(btn)
	_choice_buttons[btn] = b["id"]


func _add_object_choice(b: Dictionary) -> void:
	var btn := Button.new()
	var cost := []
	for k: String in b.get("cost", {}):
		cost.append("%d %s" % [int(b["cost"][k]), str(Stockpile._resource(k).get("name", k)).to_lower()])
	btn.text = "%s\n%s" % [b["name"], ", ".join(cost)]
	btn.custom_minimum_size = Vector2(230, 66)
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_choose_object.bind(str(b["id"]), str(b["name"])))
	_choices.add_child(btn)
	_choice_buttons[btn] = b["id"]


func _choose_block(n: int, label: String, surface: bool) -> void:
	tool.material_id = n
	if surface:
		_select_mode(BuildTool.Mode.ROAD)
	elif tool.mode in [BuildTool.Mode.ROAD, BuildTool.Mode.OBJECT, BuildTool.Mode.ERASE]:
		_select_mode(BuildTool.Mode.BLOCK)
	_selected(label)


func _choose_object(kind: String, label: String) -> void:
	tool.object_kind = kind
	_select_mode(BuildTool.Mode.OBJECT)
	_selected(label)


## Un élément choisi : le menu se réduit en bulle pour libérer l'écran.
func _selected(label: String) -> void:
	selection_label = label
	collapse()


func collapse() -> void:
	visible = false
	collapsed.emit(selection_label if selection_label != "" else "Construire")


func _select_mode(m: int) -> void:
	tool.mode = m as BuildTool.Mode
	for k: int in _mode_buttons:
		_mode_buttons[k].add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD if k == m else UiStyle.IRON_L))
	if m == BuildTool.Mode.ERASE:
		selection_label = "Gomme"


func _height(d: int) -> void:
	tool.wall_height = clampi(tool.wall_height + d, 1, 16)
	_height_label.text = "Mur %d" % tool.wall_height


func _on_move_toggled(on: bool) -> void:
	tool.move_only = on
	tool.camera.pan_enabled = on or not tool.active


func _process(_d: float) -> void:
	if visible and Engine.get_process_frames() % 30 == 0:
		_refresh_locks()


func _refresh_locks() -> void:
	for b: Button in _choice_buttons:
		var locked := Research.is_locked(_choice_buttons[b])
		b.disabled = locked
		b.tooltip_text = "Technologie requise" if locked else ""
