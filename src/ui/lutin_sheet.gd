class_name LutinSheet
extends PanelContainer
## Fiche d'un lutin (maquette validée) : identité, besoins, aptitudes, métiers connus (niveau + XP).

var lutin: Lutin
var game: Node
var _title: Label
var _family: Label
var _info: Label
var _bars: Dictionary = {}
var _jobs_box: VBoxContainer


func setup(g: Node) -> void:
	game = g


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_title = UiStyle.title_label("", 34)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(56, 56)
	close.pressed.connect(func() -> void: visible = false)
	close.tooltip_text = "Fermer la fiche (la barre d'ordres reste ouverte)"
	top.add_child(close)
	_info = Label.new()
	v.add_child(_info)
	_family = Label.new()
	_family.add_theme_color_override("font_color", UiStyle.PARCH)
	_family.add_theme_font_size_override("font_size", 18)
	_family.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_family.custom_minimum_size = Vector2(520, 0)
	v.add_child(_family)
	v.add_child(UiStyle.title_label("Besoins", 24))
	for k: Array in [["hunger", "Faim"], ["sleep", "Sommeil"], ["warmth", "Chaleur"], ["mood", "Moral"]]:
		_bars[k[0]] = _bar_row(v, k[1])
	v.add_child(UiStyle.title_label("Métiers connus", 24))
	_jobs_box = VBoxContainer.new()
	v.add_child(_jobs_box)
	visible = false


func _bar_row(parent: Control, text: String) -> ProgressBar:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(130, 0)
	h.add_child(l)
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(360, 22)
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("60844a")
	b.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("141212")
	bg.border_color = UiStyle.GOLD_D
	bg.set_border_width_all(1)
	b.add_theme_stylebox_override("background", bg)
	h.add_child(b)
	return b


func show_lutin(l: Lutin) -> void:
	lutin = l
	visible = l != null
	refresh()


static func job_name(id: String) -> String:
	return str(DataRegistry.find("jobs", "jobs", id).get("name", id))


func refresh() -> void:
	if lutin == null:
		return
	_title.text = lutin.name
	var states := ["Libre", "Marche", "Dort", "Mange", "Travaille"]
	_info.text = (
		"Âge : %d ans (%d j)   ·   Métier : %s niv. %d   ·   %s"
		% [lutin.age_days / 20, lutin.age_days, job_name(lutin.job), lutin.job_level(), states[lutin.state]]
	)
	if game != null:
		var title := str(game.sim.realm.title_name(lutin))
		_info.text += "\nTitre : %s   ·   PV %d   ·   XP de combat %d" % [title, int(lutin.hp), int(lutin.combat_xp)]
		if lutin.jailed.y >= 0:
			_info.text += "   ·   EN CAGE"
		_family.text = "Famille — " + Kinship.summary(game.colony, lutin)
	for k: String in _bars:
		_bars[k].value = float(lutin.needs.get(k, 0))
	for c in _jobs_box.get_children():
		c.queue_free()
	for j: String in lutin.jobs_known:
		var l := Label.new()
		var k: Dictionary = lutin.jobs_known[j]
		l.text = (
			"%s — niveau %d   (XP %d)%s"
			% [job_name(j), k["level"], int(k["xp"]), "   ← actif" if j == lutin.job else ""]
		)
		_jobs_box.add_child(l)


func _process(_d: float) -> void:
	if visible and Engine.get_process_frames() % 10 == 0:
		refresh()
