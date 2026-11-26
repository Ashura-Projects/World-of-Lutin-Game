class_name UiStyle
extends RefCounted
## Thème validé (STYLE-VALIDE.md §7) : fer sombre, filets dorés, boutons rouge sang et or, parchemin.

const IRON := Color("221e1e")
const IRON_L := Color("342e2c")
const GOLD := Color("c49e54")
const GOLD_D := Color("785c2e")
const BLOOD := Color("8c2420")
const PARCH := Color("deceac")
const INK := Color("28180f")
const TXT := Color("e8dcc4")
const TXT_D := Color("a49680")
const TITLE_FONT_PATH := "res://assets/fonts/Cinzel-Bold.ttf"


static func title_font() -> Font:
	return load(TITLE_FONT_PATH)


static func box(bg: Color, border: Color = GOLD_D, width: int = 2, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 4
	return s


static func make_theme() -> Theme:
	var t := Theme.new()
	var f := title_font()
	t.set_stylebox("normal", "Button", box(IRON_L))
	t.set_stylebox("hover", "Button", box(IRON_L.lightened(0.08), GOLD))
	t.set_stylebox("pressed", "Button", box(BLOOD, GOLD))
	t.set_stylebox("focus", "Button", box(IRON_L, GOLD))
	t.set_stylebox("disabled", "Button", box(IRON.darkened(0.2), GOLD_D.darkened(0.4)))
	t.set_font("font", "Button", f)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Button", Color("f4e2ba"))
	t.set_color("font_disabled_color", "Button", TXT_D.darkened(0.3))
	t.set_stylebox("panel", "PanelContainer", box(IRON, GOLD, 3, 10))
	t.set_stylebox("panel", "Panel", box(IRON, GOLD, 3, 10))
	t.set_color("font_color", "Label", TXT)
	t.set_font_size("font_size", "Label", 22)
	return t


## Bouton « actif » (rouge sang) : action principale.
static func make_primary(b: Button) -> void:
	b.add_theme_stylebox_override("normal", box(BLOOD, GOLD))
	b.add_theme_stylebox_override("hover", box(BLOOD.lightened(0.1), GOLD))


static func title_label(text: String, size: int, color: Color = GOLD) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", title_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## En-tête de fenêtre : titre à gauche, croix ✕ de fermeture à droite (toutes les fenêtres en ont une).
static func header(text: String, size: int, on_close: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	var t := title_label(text, size)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(close_button(on_close))
	return h


static func close_button(on_close: Callable) -> Button:
	var x := Button.new()
	x.text = "✕"
	x.tooltip_text = "Fermer"
	x.custom_minimum_size = Vector2(56, 52)
	x.add_theme_stylebox_override("normal", box(BLOOD, GOLD, 2, 26))
	x.pressed.connect(on_close)
	return x
