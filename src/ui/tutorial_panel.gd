class_name TutorialPanel
extends PanelContainer
## Tutoriel : quelques conseils l'un après l'autre (data/tutorial.json) ; « Passer » le coupe pour de bon.

var _i: int = 0
var _title: Label
var _text: Label
var _steps: Array = []


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(Color(0.1, 0.08, 0.06, 0.95), UiStyle.GOLD, 2, 10))
	custom_minimum_size = Vector2(640, 0)
	position = Vector2(20, 400)
	_steps = DataRegistry.get_table("tutorial").get("steps", [])
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_title = UiStyle.title_label("", 24)
	v.add_child(_title)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(600, 0)
	_text.add_theme_color_override("font_color", UiStyle.PARCH)
	_text.add_theme_font_size_override("font_size", 19)
	v.add_child(_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var skip := Button.new()
	skip.text = "Passer le tutoriel"
	skip.custom_minimum_size = Vector2(260, 50)
	skip.pressed.connect(
		func() -> void:
			Settings.set_value("tutorial", false)
			queue_free()
	)
	row.add_child(skip)
	var nxt := Button.new()
	nxt.text = "Suivant ▸"
	nxt.custom_minimum_size = Vector2(220, 50)
	UiStyle.make_primary(nxt)
	nxt.pressed.connect(_next)
	row.add_child(nxt)
	_show()


func _show() -> void:
	if _i >= _steps.size():
		Settings.set_value("tutorial", false)
		queue_free()
		return
	_title.text = "%s  (%d/%d)" % [_steps[_i]["title"], _i + 1, _steps.size()]
	_text.text = _steps[_i]["text"]


func _next() -> void:
	_i += 1
	_show()
