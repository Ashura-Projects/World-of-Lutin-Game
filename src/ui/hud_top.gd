class_name HudTop
extends Node
## Barre du haut en jeu : ressources principales (un toucher ouvre le menu Ressources), alertes en bulles,
## dialogue du marchand ambulant.

var hud: Hud
var root: Control
var game: Node
var resources_panel: ResourcesPanel
var _toasts: VBoxContainer
var _res_labels: Dictionary = {}


func setup(h: Hud, g: Node) -> void:
	hud = h
	root = h.root
	game = g
	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(1100, 120)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)
	EventBus.alert.connect(_toast)
	game.sim.trade.merchant_arrived.connect(_merchant_dialog)
	resources_panel = ResourcesPanel.new()
	resources_panel.setup(game)
	resources_panel.position = Vector2(300, 70)
	resources_panel.visible = false
	root.add_child(resources_panel)
	h.windows.add(resources_panel, func() -> void: resources_panel.visible = false)
	var x := 668
	for r: Array in [
		["food", "Nourriture"], ["log", "Bûches"], ["stone", "Pierre"], ["iron_ore", "Fer"], ["gold", "Or"]
	]:
		var b := Button.new()
		b.position = Vector2(x, 6)
		var wide := 200 if r[0] == "food" else 140
		b.custom_minimum_size = Vector2(wide, 50)
		b.add_theme_font_size_override("font_size", 17)
		b.tooltip_text = "Toutes les ressources"
		var cat := "food" if r[0] == "food" else ""
		b.pressed.connect(func() -> void: toggle_resources(cat))
		root.add_child(b)
		_res_labels[r[0]] = [b, r[1]]
		x += wide + 8


func toggle_resources(cat: String = "") -> void:
	resources_panel.visible = not resources_panel.visible
	if resources_panel.visible:
		resources_panel.open(cat)


func refresh() -> void:
	var st: Stockpile = game.colony.stock
	for k: String in _res_labels:
		var n := st.food_total() if k == "food" else st.count(k)
		_res_labels[k][0].text = "%s %d ▾" % [_res_labels[k][1], n] if k == "food" else "%s %d" % [_res_labels[k][1], n]


## Alertes en bulles (en haut à droite), quelques secondes.
func _toast(kind: String, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override(
		"font_color", Color("ffd27a") if kind in ["mort", "alerte", "froid", "cloche"] else UiStyle.TXT
	)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.9), UiStyle.GOLD_D, 1, 6))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	_toasts.add_child(p)
	if _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
	get_tree().create_timer(6.0).timeout.connect(p.queue_free)


## Dialogue d'événement : un marchand arrive (croix ✕ ou « Plus tard » pour fermer).
func _merchant_dialog() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.box(UiStyle.IRON, UiStyle.GOLD, 3, 10))
	p.position = Vector2(500, 330)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiStyle.header("Un marchand au village", 28, p.queue_free))
	var txt := Label.new()
	txt.text = "« Le bonjour ! J'ai du fer, du sel et des remèdes.\n  Contre de l'or, ou je rachète vos surplus. »"
	txt.add_theme_color_override("font_color", UiStyle.PARCH)
	v.add_child(txt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for b: Array in [["Commercer", true], ["Plus tard", false]]:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(220, 56)
		if b[1]:
			UiStyle.make_primary(btn)
		var open: bool = b[1]
		btn.pressed.connect(
			func() -> void:
				p.queue_free()
				if open:
					hud.menu_button("Commerce").button_pressed = true
		)
		row.add_child(btn)
	root.add_child(p)
