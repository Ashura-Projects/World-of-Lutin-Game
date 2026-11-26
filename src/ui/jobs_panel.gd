class_name JobsPanel
extends PanelContainer
## Panneau Lutins : métier de chaque lutin (l'outil est pris automatiquement en réserve), mode auto.

var game: Node
var _list: VBoxContainer
var _msg: Label


func setup(g: Node) -> void:
	game = g
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(760, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var t := UiStyle.title_label("Lutins et métiers", 30)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var auto := Button.new()
	auto.text = "Auto"
	auto.custom_minimum_size = Vector2(110, 52)
	auto.pressed.connect(
		func() -> void:
			game.colony.auto_assign_jobs()
			refresh()
	)
	top.add_child(auto)
	_msg = Label.new()
	_msg.add_theme_color_override("font_color", UiStyle.TXT_D)
	v.add_child(_msg)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 380)
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


## Métiers de base disponibles (outil) ; les métiers formés viendront de l'éducation (J8).
static func base_jobs() -> Array:
	var out := []
	for j: Dictionary in DataRegistry.get_table("jobs").get("jobs", []):
		if not j.has("requires_training") and int(j.get("phase", 1)) == 1:
			out.append(j["id"])
	return out


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var jobs := base_jobs()
	for l: Lutin in game.colony.lutins:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_list.add_child(row)
		var name := Label.new()
		name.text = l.name
		name.custom_minimum_size = Vector2(170, 0)
		row.add_child(name)
		var b := Button.new()
		b.text = "%s · niv. %d" % [LutinSheet.job_name(l.job), l.job_level()]
		b.custom_minimum_size = Vector2(320, 50)
		b.add_theme_font_size_override("font_size", 19)
		var lut := l
		b.pressed.connect(func() -> void: _next_job(lut, jobs))
		row.add_child(b)
		var known := Label.new()
		known.text = "%d métier(s) connu(s)" % l.jobs_known.size()
		known.add_theme_color_override("font_color", UiStyle.TXT_D)
		row.add_child(known)


## Passe au métier suivant dont l'outil est en réserve.
func _next_job(l: Lutin, jobs: Array) -> void:
	var i := jobs.find(l.job)
	for k in range(1, jobs.size() + 1):
		var j: String = jobs[(i + k) % jobs.size()]
		if game.colony.change_job(l, j):
			_msg.text = "%s devient %s (niveau %d)." % [l.name, LutinSheet.job_name(j), l.job_level()]
			break
	refresh()
