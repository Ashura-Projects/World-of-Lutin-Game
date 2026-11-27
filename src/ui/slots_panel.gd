class_name SlotsPanel
extends PanelContainer
## Écran « Charger » : 5 emplacements de partie (+ le tutoriel) ; charger ou supprimer.

signal load_requested(slot: String)

var _list: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(900, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiStyle.header("Charger une partie", 30, func() -> void: visible = false))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	v.add_child(_list)
	refresh()


func refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var slots: Array = SaveManager.SLOTS.duplicate()
	if SaveManager.has_save("tutoriel"):
		slots.append("tutoriel")
	for i in slots.size():
		var slot: String = slots[i]
		var info := SaveManager.slot_info(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_list.add_child(row)
		var lab := Label.new()
		lab.custom_minimum_size = Vector2(560, 0)
		lab.add_theme_font_size_override("font_size", 19)
		var title := "Tutoriel" if slot == "tutoriel" else "Emplacement %d" % (i + 1)
		if info.is_empty():
			lab.text = "%s — libre" % title
			lab.add_theme_color_override("font_color", UiStyle.TXT_D)
		else:
			lab.text = (
				"%s — %s · %s · jour %s · %s lutins\n%s"
				% [
					title,
					info.get("name", "Partie"),
					info.get("mode", ""),
					str(info.get("day", "?")),
					str(info.get("lutins", "?")),
					str(info.get("saved_at", "")).replace("T", " ")
				]
			)
		row.add_child(lab)
		var load_b := Button.new()
		load_b.text = "Charger"
		load_b.custom_minimum_size = Vector2(150, 52)
		load_b.disabled = info.is_empty()
		load_b.pressed.connect(func() -> void: load_requested.emit(slot))
		row.add_child(load_b)
		var del := Button.new()
		del.text = "Supprimer"
		del.custom_minimum_size = Vector2(150, 52)
		del.disabled = info.is_empty()
		del.pressed.connect(func() -> void: _confirm_delete(slot, del))
		row.add_child(del)


## Deux touchers pour supprimer (évite les erreurs).
func _confirm_delete(slot: String, b: Button) -> void:
	if b.text != "Sûr ?":
		b.text = "Sûr ?"
		UiStyle.make_primary(b)
		return
	SaveManager.delete_slot(slot)
	refresh()
