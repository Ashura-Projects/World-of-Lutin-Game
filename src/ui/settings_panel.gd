class_name SettingsPanel
extends PanelContainer
## Paramètres : volume de la musique et des effets, qualité graphique (ombres), taille des textes.

signal closed


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(UiStyle.title_label("Paramètres", 30))
	for k: Array in [["music", "Musique"], ["effects", "Effets et ambiances"]]:
		var l := Label.new()
		l.text = k[1]
		v.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Settings.get_value(k[0]))
		s.custom_minimum_size = Vector2(500, 40)
		s.value_changed.connect(_set_volume.bind(k[0]))
		v.add_child(s)
	var q := Button.new()
	q.text = "Qualité graphique : %s" % _qname(str(Settings.get_value("quality")))
	q.custom_minimum_size = Vector2(500, 54)
	q.pressed.connect(
		func() -> void:
			var order := ["low", "medium", "high"]
			var cur := str(Settings.get_value("quality"))
			Settings.set_value("quality", order[(order.find(cur) + 1) % order.size()])
			q.text = "Qualité graphique : %s" % _qname(str(Settings.get_value("quality")))
	)
	v.add_child(q)
	var ok := Button.new()
	ok.text = "Fermer"
	ok.custom_minimum_size = Vector2(500, 54)
	UiStyle.make_primary(ok)
	ok.pressed.connect(
		func() -> void:
			closed.emit()
			queue_free()
	)
	v.add_child(ok)


static func _qname(q: String) -> String:
	return {"low": "basse (sans ombres)", "medium": "moyenne", "high": "haute"}.get(q, q)


func _set_volume(v: float, key: String) -> void:
	Settings.set_value(key, v)
	Audio.apply_volumes()
