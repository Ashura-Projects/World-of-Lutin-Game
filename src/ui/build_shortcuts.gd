class_name BuildShortcuts
extends VBoxContainer
## Raccourcis sous la bulle de construction (menu réduit) : outils (bloc, ligne, remplir, mur, gomme),
## forme du bloc (cube, demi-bloc, escalier…), sens ⟳, annuler ↶ et déplacer ✋ ; pour un objet : ⟳ tourner.
## Petits boutons carrés de même taille, symboles seulement (le nom s'affiche au survol / appui long).

const SIZE := Vector2(54, 50)

var panel: BuildPanel
var _rows: Array[HBoxContainer] = []


func setup(p: BuildPanel) -> void:
	panel = p
	add_theme_constant_override("separation", 4)
	for i in 2:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		add_child(h)
		_rows.append(h)
	refresh()


func refresh() -> void:
	for h in _rows:
		for c in h.get_children():
			c.queue_free()
	var t := panel.tool
	if t.mode == BuildTool.Mode.OBJECT:
		_btn(0, "⟳", "Tourner l'objet d'un quart de tour", _rotate_object)
		_btn(0, "↶", "Annuler le dernier plan", panel._undo)
		_btn(0, "⌫", "Gomme", func() -> void: _mode(BuildTool.Mode.ERASE))
		_move(0)
		var lab := Label.new()
		lab.text = " Sens %s" % ("auto" if t.object_rot < 0 else str(t.object_rot + 1))
		lab.add_theme_font_size_override("font_size", 16)
		_rows[0].add_child(lab)
		return
	for m: Array in [
		[BuildTool.Mode.BLOCK, "■", "Bloc"],
		[BuildTool.Mode.LINE, "━", "Ligne"],
		[BuildTool.Mode.FILL, "▦", "Remplir"],
		[BuildTool.Mode.WALL, "▥", "Mur"],
		[BuildTool.Mode.ERASE, "⌫", "Gomme"]
	]:
		var b := _btn(0, m[1], m[2], _mode.bind(int(m[0])))
		if t.mode == m[0]:
			b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD, 2, 8))
	if t.mode == BuildTool.Mode.ERASE:
		_move(1)
		return
	var shape := t.shape_code / 4
	if shape < ShapeMesh.BUILD_SHAPES:
		var f := _btn(1, "◩", "Forme suivante", func() -> void: _shape(shape + 1, t.shape_code % 4))
		f.tooltip_text = "Forme : %s" % ShapeMesh.NAMES[shape]
		var rb := _btn(1, "⟳", "Tourner la forme", func() -> void: _shape(shape, t.shape_code % 4 + 1))
		rb.disabled = shape in [0, 1, 2]
	_btn(1, "↶", "Annuler le dernier plan", panel._undo)
	_move(1)
	var lab2 := Label.new()
	lab2.text = " " + str(ShapeMesh.NAMES[mini(shape, ShapeMesh.NAMES.size() - 1)])
	lab2.add_theme_font_size_override("font_size", 16)
	_rows[1].add_child(lab2)


func _btn(row: int, sym: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = sym
	b.tooltip_text = tip
	b.custom_minimum_size = SIZE
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_stylebox_override("normal", UiStyle.box(Color(0.08, 0.06, 0.06, 0.85), UiStyle.GOLD_D, 2, 8))
	b.pressed.connect(cb)
	_rows[row].add_child(b)
	return b


func _move(row: int) -> void:
	var b := _btn(row, "✋", "Déplacer la vue (sans construire)", func() -> void: _toggle_move())
	if panel.tool.move_only:
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.BLOOD, UiStyle.GOLD, 2, 8))


func _toggle_move() -> void:
	panel._move_btn.button_pressed = not panel._move_btn.button_pressed
	refresh()


func _mode(m: int) -> void:
	panel._select_mode(m)
	refresh()


func _shape(s: int, r: int) -> void:
	panel._set_shape(s, r)
	refresh()


func _rotate_object() -> void:
	var t := panel.tool
	if t.object_rot < 0:
		t.object_rot = posmod(roundi(-t.camera.yaw / (PI / 2.0)), 4)
	t.object_rot = (t.object_rot + 1) % 4
	t.show_object_ghost()
	refresh()
