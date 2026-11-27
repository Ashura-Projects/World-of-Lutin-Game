class_name MenuCategories
extends Node
## Barre du bas par catégories (1.4) : Construire, Terre, Peuple, Armée, Royaume, Gestion. Un toucher sur une
## catégorie ouvre un petit sous-menu juste au-dessus (au plus 4 choix), un toucher sur un choix ouvre le panneau.
## Les anciens boutons de menu restent (cachés) : chaque panneau garde son bouton, sa croix et son « Retour ».

## [titre, [[libellé, bouton de menu caché ou action]]]
const CATS := [
	["Construire", []],
	["Terre", [["Récolter", "Récolter"], ["Terrain", "Terrain"], ["Zones", "Zones"]]],
	["Peuple", [["Lutins", "Lutins"], ["Villages et villes", "@villages"], ["Statistiques", "@stats"]]],
	["Armée", [["Militaire et unités", "Militaire"], ["Bataille", "@battle"]]],
	["Royaume", [["Royaume et diplomatie", "Royaume"], ["Commerce", "Commerce"]]],
	["Gestion", [["Ateliers", "Gestion"], ["Recherche", "@research"], ["Tableau de bord", "@dashboard"]]]
]

var hud: Hud
var _popup: PanelContainer
var _open: String = ""
var _cat_btns: Dictionary = {}


func setup(h: Hud, row: HBoxContainer) -> void:
	hud = h
	for c: Array in CATS:
		var b := Button.new()
		b.text = c[0] + ("" if c[1].is_empty() else " ▴")
		b.custom_minimum_size = Vector2(196, 76)
		b.add_theme_font_size_override("font_size", 19)
		row.add_child(b)
		_cat_btns[c[0]] = b
		if c[1].is_empty():
			b.toggle_mode = true
			b.toggled.connect(func(on: bool) -> void: h.menu_button("Construire").button_pressed = on)
		else:
			b.pressed.connect(_toggle.bind(str(c[0]), c[1], b))
	_popup = PanelContainer.new()
	_popup.add_theme_stylebox_override("panel", UiStyle.box(Color(0.08, 0.06, 0.06, 0.95), UiStyle.GOLD, 2, 8))
	_popup.visible = false
	h.root.add_child(_popup)


## Le bouton « Construire » de la barre suit l'état du vrai bouton (réduit en bulle, fermé par la croix…).
func sync_build(on: bool) -> void:
	var b: Button = _cat_btns["Construire"]
	if b.button_pressed != on:
		b.set_pressed_no_signal(on)


func _toggle(cat: String, items: Array, from: Button) -> void:
	if _popup.visible and _open == cat:
		close()
		return
	_open = cat
	for c in _popup.get_children():
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_popup.add_child(v)
	for it: Array in items:
		if str(it[1]) == "@battle" and hud._game.sim.rules.mode != "battle":
			continue
		var b := Button.new()
		b.text = it[0]
		b.custom_minimum_size = Vector2(300, 60)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_choose.bind(str(it[1])))
		v.add_child(b)
	_popup.visible = true
	_popup.reset_size()
	var h := 66 * items.size() + 20
	_popup.position = Vector2(clampf(from.global_position.x - 50, 8, 1260), 620 - h)


func close() -> void:
	_popup.visible = false
	_open = ""


func is_open() -> bool:
	return _popup.visible


func _choose(target: String) -> void:
	close()
	match target:
		"@villages":
			hud.settlements_panel.visible = true
			hud.settlements_panel.show_tab("villages")
		"@stats":
			hud.stats_panel.visible = true
			hud.stats_panel.refresh()
		"@battle":
			hud.battle_panel.visible = true
			hud.battle_panel.refresh()
		"@research":
			hud.toggle_research()
		"@dashboard":
			hud.toggle_dashboard()
		_:
			var b := hud.menu_button(target)
			if b != null:
				b.button_pressed = true
