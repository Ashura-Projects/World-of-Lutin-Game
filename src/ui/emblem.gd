class_name Emblem
extends Control
## Dessin de l'emblème de la faction (forme, partition, symbole) —
## en 2D pour l'interface et dans une texture pour les fanions.

var faction: Faction


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(160, 190)


func show_faction(f: Faction) -> void:
	faction = f
	queue_redraw()


func _shape_points(r: Rect2) -> PackedVector2Array:
	var p := PackedVector2Array()
	var c := r.get_center()
	match faction.shape:
		"rond":
			for i in 40:
				var a := TAU * i / 40.0
				p.append(c + Vector2(cos(a), sin(a)) * minf(r.size.x, r.size.y) * 0.48)
		"losange":
			p = PackedVector2Array(
				[Vector2(c.x, r.position.y), Vector2(r.end.x, c.y), Vector2(c.x, r.end.y), Vector2(r.position.x, c.y)]
			)
		"etendard":
			p = PackedVector2Array(
				[
					r.position,
					Vector2(r.end.x, r.position.y),
					Vector2(r.end.x, r.end.y),
					Vector2(c.x, r.end.y - r.size.y * 0.18),
					Vector2(r.position.x, r.end.y)
				]
			)
		_:  # écu
			p.append(r.position)
			p.append(Vector2(r.end.x, r.position.y))
			p.append(Vector2(r.end.x, r.position.y + r.size.y * 0.55))
			for i in range(1, 12):
				var t := i / 12.0
				p.append(Vector2(lerpf(r.end.x, c.x, t), r.position.y + r.size.y * (0.55 + 0.45 * sin(t * PI / 2))))
			p.append(Vector2(c.x, r.end.y))
			for i in range(11, 0, -1):
				var t := i / 12.0
				p.append(
					Vector2(lerpf(r.position.x, c.x, t), r.position.y + r.size.y * (0.55 + 0.45 * sin(t * PI / 2)))
				)
			p.append(Vector2(r.position.x, r.position.y + r.size.y * 0.55))
	return p


## Moitié « seconde couleur » de la partition, découpée à l'intérieur de la forme.
func _division_polys(r: Rect2) -> Array:
	var c := r.get_center()
	match faction.division:
		"pale":
			return [
				PackedVector2Array(
					[Vector2(c.x, r.position.y), r.position + Vector2(r.size.x, 0), r.end, Vector2(c.x, r.end.y)]
				)
			]
		"fess":
			return [
				PackedVector2Array(
					[Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), r.end, Vector2(r.position.x, r.end.y)]
				)
			]
		"quarter":
			return [
				PackedVector2Array(
					[Vector2(c.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, c.y), c]
				),
				PackedVector2Array(
					[Vector2(r.position.x, c.y), c, Vector2(c.x, r.end.y), Vector2(r.position.x, r.end.y)]
				)
			]
		"bend":
			return [PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end])]
	return []


func _draw() -> void:
	if faction == null:
		return
	var r := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	var outline := _shape_points(r)
	draw_colored_polygon(outline, Color(faction.color1))
	for poly: PackedVector2Array in _division_polys(r):
		var clipped := Geometry2D.intersect_polygons(poly, outline)
		for cp: PackedVector2Array in clipped:
			draw_colored_polygon(cp, Color(faction.color2))
	_draw_symbol(
		r.get_center() + Vector2(0, -r.size.y * 0.04), minf(r.size.x, r.size.y) * 0.3, Color(faction.symbol_color)
	)
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, UiStyle.GOLD, 4.0, true)


func _draw_symbol(c: Vector2, s: float, col: Color) -> void:
	match faction.symbol:
		"arbre":
			draw_rect(Rect2(c + Vector2(-s * 0.1, s * 0.2), Vector2(s * 0.2, s * 0.7)), col)
			draw_colored_polygon(
				PackedVector2Array(
					[c + Vector2(0, -s), c + Vector2(s * 0.7, s * 0.35), c + Vector2(-s * 0.7, s * 0.35)]
				),
				col
			)
		"epee":
			draw_rect(Rect2(c + Vector2(-s * 0.07, -s), Vector2(s * 0.14, s * 1.4)), col)
			draw_rect(Rect2(c + Vector2(-s * 0.45, s * 0.35), Vector2(s * 0.9, s * 0.12)), col)
			draw_rect(Rect2(c + Vector2(-s * 0.08, s * 0.47), Vector2(s * 0.16, s * 0.4)), col)
		"marteau":
			draw_rect(Rect2(c + Vector2(-s * 0.07, -s * 0.4), Vector2(s * 0.14, s * 1.3)), col)
			draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.75), Vector2(s * 1.1, s * 0.4)), col)
		"etoile", "soleil":
			var pts := PackedVector2Array()
			var n := 5 if faction.symbol == "etoile" else 12
			for i in n * 2:
				var a := -PI / 2 + PI * i / n
				pts.append(c + Vector2(cos(a), sin(a)) * (s if i % 2 == 0 else s * (0.42 if n == 5 else 0.7)))
			draw_colored_polygon(pts, col)
		"gland":
			draw_circle(c + Vector2(0, s * 0.25), s * 0.5, col)
			draw_rect(Rect2(c + Vector2(-s * 0.6, -s * 0.45), Vector2(s * 1.2, s * 0.4)), col.darkened(0.25))
			draw_rect(Rect2(c + Vector2(-s * 0.05, -s * 0.8), Vector2(s * 0.1, s * 0.35)), col.darkened(0.25))
		"montagne":
			draw_colored_polygon(
				PackedVector2Array(
					[
						c + Vector2(-s, s * 0.7),
						c + Vector2(-s * 0.2, -s * 0.8),
						c + Vector2(s * 0.3, s * 0.1),
						c + Vector2(s * 0.55, -s * 0.3),
						c + Vector2(s, s * 0.7)
					]
				),
				col
			)
		"lune":
			draw_circle(c, s * 0.8, col)
			draw_circle(c + Vector2(s * 0.35, -s * 0.15), s * 0.7, Color(faction.color1))
		"couronne":
			draw_colored_polygon(
				PackedVector2Array(
					[
						c + Vector2(-s, s * 0.5),
						c + Vector2(-s, -s * 0.5),
						c + Vector2(-s * 0.5, 0),
						c + Vector2(0, -s * 0.7),
						c + Vector2(s * 0.5, 0),
						c + Vector2(s, -s * 0.5),
						c + Vector2(s, s * 0.5)
					]
				),
				col
			)
		"cerf":
			for sx: float in [-1.0, 1.0]:
				draw_line(c + Vector2(sx * s * 0.15, s * 0.6), c + Vector2(sx * s * 0.5, -s * 0.9), col, s * 0.14)
				draw_line(c + Vector2(sx * s * 0.3, -s * 0.1), c + Vector2(sx * s * 0.85, -s * 0.35), col, s * 0.12)
				draw_line(c + Vector2(sx * s * 0.4, -s * 0.5), c + Vector2(sx * s * 0.8, -s * 0.85), col, s * 0.1)
		"epi":
			draw_line(c + Vector2(0, s), c + Vector2(0, -s), col, s * 0.1)
			for i in 4:
				var y := -s * 0.7 + i * s * 0.35
				draw_circle(c + Vector2(-s * 0.18, y), s * 0.16, col)
				draw_circle(c + Vector2(s * 0.18, y), s * 0.16, col)
