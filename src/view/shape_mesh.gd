class_name ShapeMesh
extends RefCounted
## Géométrie des blocs façonnés (1.3) : demi-blocs, escalier, pente, coins de pente, arrondi, quart de cône,
## quart de dôme. Triangles dans un cube unité, tournés par quarts de tour autour de l'axe vertical.
## Les UV sont projetées à plat dans la tuile du bloc (dessus, côté, dessous selon la normale).

enum Shape { CUBE, SLAB, SLAB_TOP, STAIRS, SLOPE, SLOPE_OUT, SLOPE_IN, ROUND, CONE, DOME }

const NAMES := [
	"Cube",
	"Demi-bloc (sol)",
	"Demi-bloc (plafond)",
	"Escalier",
	"Pente (toit)",
	"Coin de toit extérieur",
	"Coin de toit intérieur",
	"Angle arrondi",
	"Quart de cône (toit rond)",
	"Quart de dôme (coupole)"
]
const ARC := 6  # segments d'un quart de cercle

static var _cache: Dictionary = {}


static func _box(t: Array, a: Vector3, b: Vector3) -> void:
	var c := [
		Vector3(a.x, a.y, a.z),
		Vector3(b.x, a.y, a.z),
		Vector3(b.x, a.y, b.z),
		Vector3(a.x, a.y, b.z),
		Vector3(a.x, b.y, a.z),
		Vector3(b.x, b.y, a.z),
		Vector3(b.x, b.y, b.z),
		Vector3(a.x, b.y, b.z)
	]
	for q: Array in [[4, 5, 6, 7], [3, 2, 1, 0], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [3, 0, 4, 7]]:
		_quad(t, c[q[0]], c[q[1]], c[q[2]], c[q[3]])


## Quadrilatère (sens antihoraire vu de l'extérieur).
static func _quad(t: Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	t.append_array([a, b, c, a, c, d])


static func _tri(t: Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	t.append_array([a, b, c])


## Triangles (non tournés) d'une forme ; l'avant (le bas de la pente) est vers -Z.
static func triangles(shape: int) -> Array:
	if _cache.has(shape):
		return _cache[shape]
	var t := []
	var p000 := Vector3(0, 0, 0)
	var p100 := Vector3(1, 0, 0)
	var p101 := Vector3(1, 0, 1)
	var p001 := Vector3(0, 0, 1)
	match shape:
		Shape.SLAB:
			_box(t, Vector3.ZERO, Vector3(1, 0.5, 1))
		Shape.SLAB_TOP:
			_box(t, Vector3(0, 0.5, 0), Vector3.ONE)
		Shape.STAIRS:
			_box(t, Vector3.ZERO, Vector3(1, 0.5, 1))
			_box(t, Vector3(0, 0.5, 0.5), Vector3.ONE)
		Shape.SLOPE:
			_quad(t, p001, p101, p100, p000)  # dessous
			_quad(t, p101, p001, Vector3(0, 1, 1), Vector3(1, 1, 1))  # dos
			_quad(t, p000, p100, Vector3(1, 1, 1), Vector3(0, 1, 1))  # pente
			_tri(t, p100, p101, Vector3(1, 1, 1))
			_tri(t, p001, p000, Vector3(0, 1, 1))
		Shape.SLOPE_OUT:
			var a := Vector3(1, 1, 1)
			_quad(t, p001, p101, p100, p000)
			_tri(t, p100, p101, a)
			_tri(t, p101, p001, a)
			_tri(t, p000, p100, a)
			_tri(t, p001, p000, a)
		Shape.SLOPE_IN:
			var b := Vector3(0, 1, 1)
			var c := Vector3(1, 1, 1)
			var d := Vector3(1, 1, 0)
			_quad(t, p001, p101, p100, p000)
			_quad(t, p100, p101, c, d)
			_quad(t, p101, p001, b, c)
			_tri(t, p001, p000, b)
			_tri(t, p000, p100, d)
			_tri(t, p000, c, b)
			_tri(t, p000, d, c)
		Shape.ROUND, Shape.CONE, Shape.DOME:
			_round(t, shape)
	_cache[shape] = t
	return t


## Quart de cylindre / cône / dôme : centre au coin (0, 0) du bloc, rayon 1, bord courbe vers +X +Z.
static func _round(t: Array, shape: int) -> void:
	var rings := 1 if shape != Shape.DOME else 4
	var prev := []
	for k in range(rings + 1):
		var y := float(k) / rings if shape == Shape.DOME else float(k)
		var r := 1.0
		if shape == Shape.DOME:
			r = cos(asin(clampf(y, 0.0, 1.0)))
		elif shape == Shape.CONE:
			r = 1.0 - y
		var ring := []
		for i in ARC + 1:
			var a := PI / 2.0 * i / ARC
			ring.append(Vector3(cos(a) * r, y, sin(a) * r))
		if k > 0:
			for i in ARC:
				_quad(t, prev[i], prev[i + 1], ring[i + 1], ring[i])
		prev = ring
	var top_y := 1.0
	var base := []
	for i in ARC + 1:
		var a := PI / 2.0 * i / ARC
		base.append(Vector3(cos(a), 0, sin(a)))
	for i in ARC:
		_tri(t, Vector3.ZERO, base[i + 1], base[i])  # dessous
		if shape == Shape.ROUND:
			_tri(t, Vector3(0, 1, 0), Vector3(base[i].x, 1, base[i].z), Vector3(base[i + 1].x, 1, base[i + 1].z))
	# les deux faces planes (contre les blocs voisins)
	if shape == Shape.ROUND:
		_quad(t, Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0))
		_quad(t, Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1))
	else:
		var side_x := [Vector3(0, 0, 0)]
		var side_z := [Vector3(0, 0, 0)]
		for k in range(rings + 1):
			var y := float(k) / rings if shape == Shape.DOME else float(k)
			var r := cos(asin(clampf(y, 0.0, 1.0))) if shape == Shape.DOME else 1.0 - y
			side_x.append(Vector3(r, y, 0))
			side_z.append(Vector3(0, y, r))
		side_x.append(Vector3(0, top_y, 0))
		side_z.append(Vector3(0, top_y, 0))
		for i in range(1, side_x.size() - 1):
			_tri(t, side_x[0], side_x[i], side_x[i + 1])
			_tri(t, side_z[0], side_z[i + 1], side_z[i])


## Ajoute un bloc façonné au maillage. code = forme × 4 + sens.
static func add(acc: Dictionary, base: Vector3, code: int, tiles: Array, cols: float, rows: float) -> int:
	var shape := code / 4
	var rot := code % 4
	var tris := triangles(shape)
	var center := Vector3(0.5, 0, 0.5)
	var basis := Basis(Vector3.UP, -PI / 2.0 * rot)
	for i in range(0, tris.size(), 3):
		var v := [
			basis * (tris[i] - center) + center,
			basis * (tris[i + 1] - center) + center,
			basis * (tris[i + 2] - center) + center
		]
		var n: Vector3 = (v[1] - v[0]).cross(v[2] - v[0]).normalized() * -1.0
		var tile: int = tiles[0] if n.y > 0.5 else (tiles[2] if n.y < -0.5 else tiles[1])
		var c := float(tile % int(cols))
		var r := float(tile / int(cols))
		var start: int = acc["v"].size()
		for k in 3:
			var p: Vector3 = v[k]
			var uv := (
				Vector2(p.x, p.z)
				if absf(n.y) > 0.5
				else (Vector2(p.z, 1.0 - p.y) if absf(n.x) > absf(n.z) else Vector2(p.x, 1.0 - p.y))
			)
			uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
			acc["v"].append(base + p)
			acc["n"].append(n)
			acc["uv"].append(Vector2((c + 0.002 + uv.x * 0.996) / cols, (r + 0.002 + uv.y * 0.996) / rows))
		acc["i"].append_array(PackedInt32Array([start, start + 1, start + 2]))
	return tris.size() / 3
