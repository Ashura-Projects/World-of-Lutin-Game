class_name Shapes
extends RefCounted
## Formes de construction : ligne, rectangle plein, mur (ligne × hauteur).


## Ligne droite entre deux cases (axe dominant, comme un tracé au doigt).
static func line(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var d := b - a
	var n := maxi(absi(d.x), maxi(absi(d.y), absi(d.z)))
	if n == 0:
		out.append(a)
		return out
	for i in n + 1:
		var f := float(i) / n
		var p := Vector3i(roundi(a.x + d.x * f), roundi(a.y + d.y * f), roundi(a.z + d.z * f))
		if out.is_empty() or out[-1] != p:
			out.append(p)
	return out


## Rectangle plein horizontal (hauteur de a).
static func rect(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
		for z in range(mini(a.z, b.z), maxi(a.z, b.z) + 1):
			out.append(Vector3i(x, a.y, z))
	return out


## Mur : la ligne au sol, montée sur `height` blocs.
static func wall(a: Vector3i, b: Vector3i, height: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var base := line(Vector3i(a.x, a.y, a.z), Vector3i(b.x, a.y, b.z))
	for h in maxi(height, 1):
		for p in base:
			out.append(p + Vector3i(0, h, 0))
	return out


## Boîte de creusage : largeur × longueur × profondeur vers le bas depuis `top` (boutons + / −).
static func dig_box(top: Vector3i, width: int, length: int, depth: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for y in depth:
		for x in width:
			for z in length:
				out.append(top + Vector3i(x, -y, z))
	return out
