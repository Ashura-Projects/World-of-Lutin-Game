"""Modèles low-poly originaux des Lutins (3 variantes A/B/C), tenues par métier, âges.

Tout est construit à partir de primitives : aucun asset externe.
"""

import math

from blib import box, cone, cyl, group, mat, sphere, torus

SKIN = (92, 156, 226)        # bleu du lutin
SKIN_DARK = (70, 128, 204)
SKIN_ELDER = (128, 166, 214)
CHEEK = (236, 146, 176)
EYE = (24, 22, 34)
WHITE = (250, 250, 246)
BOOT = (92, 58, 36)
PANTS = (70, 64, 82)
WOOD = (150, 100, 56)
METAL = (176, 180, 188)
LEATHER = (120, 76, 44)
GOLD = (232, 182, 60)

# Tenue par métier : tunique, chapeau (type, couleur), outil, accessoires.
OUTFITS = {
    "base":             dict(tunic=(120, 150, 90), hat=("pointu", (200, 70, 60)), tool=None, extras=[]),
    "porteur":          dict(tunic=(196, 170, 120), hat=("bandeau", (210, 80, 60)), tool=None, extras=["caisse_bras"]),
    "bucheron":         dict(tunic=(170, 60, 50), hat=("pointu", (60, 130, 70)), tool="hache", extras=[]),
    "mineur":           dict(tunic=(90, 90, 100), hat=("casque", (210, 170, 60)), tool="pioche", extras=[]),
    "terrassier":       dict(tunic=(150, 110, 70), hat=("pointu", (120, 80, 50)), tool="pelle", extras=[]),
    "batisseur":        dict(tunic=(230, 150, 50), hat=("pointu", (240, 200, 60)), tool="marteau", extras=["ceinture_outils"]),
    "cueilleur":        dict(tunic=(140, 170, 80), hat=("capuche", (200, 80, 120)), tool="panier", extras=[]),
    "pecheur":          dict(tunic=(60, 110, 150), hat=("large", (230, 200, 70)), tool="canne", extras=[]),
    "chasseur":         dict(tunic=(80, 110, 60), hat=("capuche", (60, 90, 50)), tool="arc", extras=["carquois"]),
    "fermier":          dict(tunic=(110, 150, 190), hat=("large", (220, 190, 110)), tool="houe", extras=[]),
    "menuisier":        dict(tunic=(200, 120, 60), hat=("pointu", (150, 90, 50)), tool="scie", extras=["tablier_cuir"]),
    "tailleur_pierre":  dict(tunic=(160, 160, 150), hat=("beret", (110, 110, 120)), tool="ciseau", extras=["tablier_cuir"]),
    "forgeron":         dict(tunic=(60, 56, 60), hat=("calotte", (40, 40, 44)), tool="pinces", extras=["tablier_cuir"]),
    "cuisinier":        dict(tunic=(230, 230, 224), hat=("toque", (252, 252, 250)), tool="louche", extras=["tablier_blanc"]),
    "maitre_ecole":     dict(tunic=(120, 70, 140), hat=("beret", (70, 50, 110)), tool="livre", extras=["lunettes"]),
    "chercheur":        dict(tunic=(50, 70, 130), hat=("pointu_haut", (40, 50, 110)), tool="parchemin", extras=["lunettes", "robe"]),
    "artisan_expert":   dict(tunic=(150, 40, 50), hat=("beret", (190, 50, 60)), tool="marteau_or", extras=["ceinture_outils", "medaille"]),
}

JOB_NAMES = {
    "porteur": "Porteur", "bucheron": "Bûcheron", "mineur": "Mineur", "terrassier": "Terrassier",
    "batisseur": "Bâtisseur", "cueilleur": "Cueilleur", "pecheur": "Pêcheur", "chasseur": "Chasseur",
    "fermier": "Fermier", "menuisier": "Menuisier", "tailleur_pierre": "Tailleur de pierre",
    "forgeron": "Forgeron", "cuisinier": "Cuisinier", "maitre_ecole": "Maître d'école",
    "chercheur": "Chercheur", "artisan_expert": "Artisan expert",
}


# ----------------------------------------------------------------------------- outils

def _tool(name, hand, objs, pose="tenu"):
    """Ajoute l'outil `name` dans la main droite (hand = position de la main)."""
    hx, hy, hz = hand
    wood, metal = mat("bois", WOOD), mat("metal", METAL, 0.35, metal=0.6)
    if name in ("hache", "pioche", "marteau", "marteau_or", "houe"):
        ln = 0.42 if name in ("marteau", "marteau_or") else 0.55
        tilt = -0.4  # outil penché vers l'extérieur : la tête de l'outil reste bien visible
        handle = cyl((hx, hy, hz + ln / 2 - 0.08), 0.022, ln, wood, rot=(0, tilt, 0))
        objs.append(handle)
        tx = hx + math.sin(tilt) * (ln - 0.08)
        tz = hz + math.cos(tilt) * (ln - 0.08)
        if name == "hache":
            objs.append(box((tx - 0.06, hy, tz - 0.03), (0.13, 0.03, 0.11), metal, rot=(0, tilt, 0)))
            objs.append(box((tx - 0.125, hy, tz - 0.03), (0.02, 0.032, 0.15), mat("tranchant", (220, 224, 230), 0.2, metal=0.8), rot=(0, tilt, 0)))
        elif name == "pioche":
            objs.append(box((tx, hy, tz), (0.36, 0.04, 0.045), metal, rot=(0, tilt + 0.1, 0)))
            objs.append(cone((tx - 0.2, hy, tz + 0.03), 0.025, 0.08, metal, rot=(0, -1.4, 0)))
            objs.append(cone((tx + 0.2, hy, tz - 0.0), 0.025, 0.08, metal, rot=(0, 1.8, 0)))
        elif name == "houe":
            objs.append(box((tx - 0.03, hy - 0.06, tz - 0.04), (0.12, 0.12, 0.025), metal, rot=(0.9, tilt, 0)))
        else:
            hm = mat("or", GOLD, 0.3, metal=0.9) if name == "marteau_or" else metal
            objs.append(box((tx, hy, tz), (0.15, 0.07, 0.07), hm, rot=(0, tilt, 0), bevel=0.01))
    elif name == "pelle":
        objs.append(cyl((hx, hy - 0.02, hz + 0.05), 0.022, 0.62, wood))
        objs.append(box((hx, hy - 0.02, hz - 0.33), (0.13, 0.025, 0.17), metal, bevel=0.01))
        objs.append(box((hx, hy - 0.02, hz + 0.37), (0.1, 0.03, 0.03), wood))
    elif name == "panier":
        wick = mat("osier", (196, 150, 84), 0.9)
        objs.append(cyl((hx, hy - 0.08, hz - 0.05), 0.11, 0.12, wick, verts=12, r2=0.13))
        objs.append(torus((hx, hy - 0.08, hz + 0.02), 0.1, 0.012, wick, rot=(0, math.pi / 2, 0)))
        berry = mat("baies", (200, 30, 60), 0.3)
        for i in range(6):
            a = i * 1.05
            objs.append(sphere((hx + 0.05 * math.cos(a), hy - 0.08 + 0.05 * math.sin(a), hz + 0.02), 0.03, berry, 8, 6))
    elif name == "canne":
        objs.append(cyl((hx - 0.2, hy - 0.2, hz + 0.32), 0.012, 0.95, wood, rot=(0.75, -0.45, 0)))
        tip = (hx - 0.42, hy - 0.56, hz + 0.64)
        objs.append(cyl((tip[0], tip[1], tip[2] - 0.3), 0.004, 0.6, mat("fil", (240, 240, 240))))
        objs.append(sphere((tip[0], tip[1], tip[2] - 0.6), 0.035, mat("bouchon", (220, 50, 40), 0.3), 10, 6))
    elif name == "arc":
        bow = mat("arc", (130, 80, 40), 0.5)
        pts = []
        for i in range(9):
            a = -1.0 + i * 0.25
            pts.append((hx - 0.04 - 0.16 * math.cos(a), hy - 0.06, hz + 0.1 + 0.4 * math.sin(a)))
        for a, b in zip(pts, pts[1:]):
            mid = [(a[k] + b[k]) / 2 for k in range(3)]
            dx, dz = b[0] - a[0], b[2] - a[2]
            ln = math.hypot(dx, dz)
            objs.append(cyl(mid, 0.016, ln + 0.01, bow, rot=(0, math.atan2(dx, dz), 0)))
        objs.append(cyl((pts[0][0], hy - 0.06, hz + 0.1), 0.004, pts[-1][2] - pts[0][2], mat("fil", (240, 240, 240))))
    elif name == "scie":
        objs.append(box((hx - 0.16, hy - 0.04, hz - 0.02), (0.3, 0.01, 0.09), metal, rot=(0, 0.3, 0)))
        objs.append(box((hx, hy - 0.04, hz + 0.02), (0.06, 0.03, 0.08), wood, bevel=0.01))
    elif name == "ciseau":
        objs.append(cyl((hx, hy - 0.02, hz + 0.1), 0.02, 0.2, wood, rot=(0, 0.3, 0)))
        objs.append(cyl((hx + 0.06, hy - 0.02, hz + 0.22), 0.06, 0.12, mat("maillet", (170, 120, 70)), rot=(0, 1.87, 0)))
    elif name == "pinces":
        dark = mat("fer_noir", (60, 60, 66), 0.4, metal=0.7)
        for dx, rr in ((-0.03, -0.38), (0.03, -0.22)):
            objs.append(box((hx - 0.06 + dx, hy - 0.06, hz + 0.16), (0.025, 0.025, 0.4), dark, rot=(0, rr, 0)))
        objs.append(box((hx - 0.16, hy - 0.06, hz + 0.37), (0.14, 0.07, 0.06), mat("lingot", (255, 120, 30), 0.4, emit=5.0)))
    elif name == "louche":
        objs.append(cyl((hx - 0.06, hy - 0.03, hz + 0.18), 0.014, 0.4, metal, rot=(0, -0.3, 0)))
        objs.append(sphere((hx - 0.12, hy - 0.03, hz + 0.39), (0.08, 0.08, 0.05), metal, 10, 6))
    elif name == "livre":
        objs.append(box((hx, hy - 0.08, hz + 0.02), (0.16, 0.05, 0.2), mat("couverture", (170, 40, 40), 0.6), rot=(0.2, 0, 0)))
        objs.append(box((hx, hy - 0.08, hz + 0.02), (0.15, 0.054, 0.185), mat("pages", (246, 238, 214), 0.9), rot=(0.2, 0, 0)))
    elif name == "parchemin":
        objs.append(cyl((hx, hy - 0.07, hz + 0.03), 0.04, 0.26, mat("parch", (240, 226, 186), 0.9), rot=(0, math.pi / 2, 0.3)))
        objs.append(sphere((hx + 0.13, hy - 0.11, hz + 0.03), 0.02, mat("sceau", (200, 40, 40)), 8, 6))


def _hat(kind, color, head_c, r, objs):
    """Chapeaux de la variante A. head_c = centre de la tête, r = rayon."""
    x, y, z = head_c
    m = mat(f"chapeau_{kind}_{color}", color, 0.8)
    top = z + r * 0.62
    if kind in ("pointu", "pointu_haut"):
        h = r * (1.7 if kind == "pointu_haut" else 1.35)
        t = 0.22  # pointe légèrement rejetée vers l'arrière
        base = top - 0.05
        objs.append(cone((x, y + math.sin(t) * h / 2, base + math.cos(t) * h / 2), r * 0.95, h, m, verts=12, rot=(-t, 0, 0)))
        objs.append(torus((x, y, base + 0.01), r * 0.9, r * 0.17, m, seg=14))
        objs.append(sphere((x, y + math.sin(t) * h, base + math.cos(t) * h), r * 0.18, mat("pompon", WHITE, 0.9), 8, 6))
    elif kind == "capuche":
        objs.append(sphere((x, y + r * 0.3, z + 0.05), (r * 1.1, r * 1.0, r * 1.06), m, 14, 8))
        objs.append(cone((x, y + r * 1.05, z + r * 0.35), r * 0.45, r * 1.1, m, verts=8, rot=(-2.1, 0, 0)))
    elif kind == "casque":
        objs.append(sphere((x, y, top - 0.04), (r * 1.0, r * 1.0, r * 0.62), m, 14, 7))
        objs.append(torus((x, y, top - 0.05), r * 0.98, r * 0.06, m, seg=14))
        objs.append(cyl((x, y - r * 0.95, top + 0.02), 0.05, 0.05, mat("lampe", (255, 210, 120), emit=6.0), rot=(math.pi / 2, 0, 0)))
    elif kind == "large":
        objs.append(cyl((x, y, top + 0.0), r * 1.7, 0.03, m, verts=16))
        objs.append(cyl((x, y, top + 0.08), r * 0.75, 0.16, m, verts=12, r2=r * 0.62))
        objs.append(torus((x, y, top + 0.03), r * 0.74, 0.02, mat("ruban", (170, 50, 40)), seg=12))
    elif kind == "beret":
        objs.append(sphere((x + 0.04, y + 0.02, top + 0.02), (r * 1.08, r * 1.08, r * 0.32), m, 14, 6))
        objs.append(sphere((x + 0.04, y + 0.02, top + 0.11), 0.025, m, 6, 4))
    elif kind == "calotte":
        objs.append(sphere((x, y, top - 0.02), (r * 0.95, r * 0.95, r * 0.5), m, 12, 6))
    elif kind == "toque":
        objs.append(cyl((x, y, top + 0.1), r * 0.7, 0.22, m, verts=12))
        objs.append(sphere((x, y, top + 0.24), (r * 0.9, r * 0.9, r * 0.38), m, 12, 6))
    elif kind == "bandeau":
        objs.append(torus((x, y, z + r * 0.42), r * 0.93, r * 0.09, m, seg=16))
        objs.append(sphere((x + 0.03, y + r * 0.95, z + r * 0.42), 0.04, m, 6, 4))


# ----------------------------------------------------------------------------- corps

def _face(head_c, r, objs, big_eyes=1.0, eye_spread=0.36):
    x, y, z = head_c
    eye, white = mat("oeil", EYE, 0.2), mat("reflet", WHITE, 0.2, emit=0.6)
    for s in (-1, 1):
        ex = x + s * r * eye_spread
        ey = y - r * 0.9
        objs.append(sphere((ex, ey, z + r * 0.12), (0.042 * big_eyes, 0.025, 0.058 * big_eyes), eye, 10, 6))
        objs.append(sphere((ex + 0.012, ey - 0.02, z + r * 0.12 + 0.022 * big_eyes), 0.013 * big_eyes, white, 6, 4))
        objs.append(sphere((x + s * r * 0.58, y - r * 0.72, z - r * 0.15), (0.05, 0.02, 0.03), mat("joue", CHEEK, 0.8), 8, 4))


def _variant_a(o, objs, skin, s_head=1.0):
    tunic = mat("tunique", o["tunic"], 0.85)
    sk = mat("peau", skin, 0.55)
    # jambes et bottes
    for s in (-1, 1):
        objs.append(cyl((s * 0.08, 0, 0.11), 0.05, 0.12, mat("pantalon", PANTS, 0.9)))
        objs.append(sphere((s * 0.08, -0.025, 0.045), (0.07, 0.095, 0.05), mat("botte", BOOT, 0.7), 10, 6))
    # corps
    body_h = 0.24 if "robe" not in o["extras"] else 0.27
    objs.append(sphere((0, 0, 0.32), (0.2, 0.18, body_h), tunic, 14, 8))
    if "robe" in o["extras"]:
        objs.append(cyl((0, 0, 0.17), 0.2, 0.24, tunic, verts=14, r2=0.15))
    objs.append(torus((0, 0, 0.27), 0.19, 0.022, mat("ceinture", LEATHER, 0.7), seg=16))
    # bras + mains
    for s in (-1, 1):
        objs.append(cyl((s * 0.21, 0, 0.36), 0.045, 0.18, tunic, rot=(0, s * 0.35, 0)))
        objs.append(sphere((s * 0.25, -0.03, 0.25), 0.055, sk, 10, 6))
    # tête
    r = 0.28 * s_head
    hc = (0, 0, 0.66 + (r - 0.28) * 0.8)
    objs.append(sphere(hc, r, sk, 16, 10))
    objs.append(sphere((0, -r * 0.98, hc[2] - r * 0.08), r * 0.26, mat("nez", SKIN_DARK, 0.5), 10, 6))
    for s in (-1, 1):
        objs.append(cone((s * r * 1.02, 0.02, hc[2] + 0.02), r * 0.2, r * 0.7, sk, verts=6, rot=(0, s * 1.25, 0)))
    _face(hc, r, objs)
    return hc, r


def _variant_b(o, objs, skin):
    """Variante B « Gland » : corps-tête en œuf, grands yeux, bonnet en cupule."""
    tunic = mat("tunique", o["tunic"], 0.85)
    sk = mat("peau", skin, 0.55)
    for s in (-1, 1):
        objs.append(sphere((s * 0.09, -0.03, 0.04), (0.075, 0.1, 0.05), mat("botte", BOOT, 0.7), 10, 6))
    objs.append(sphere((0, 0, 0.27), (0.24, 0.22, 0.22), tunic, 14, 8))
    objs.append(sphere((0, 0, 0.56), (0.31, 0.29, 0.3), sk, 16, 10))
    for s in (-1, 1):
        objs.append(sphere((s * 0.24, -0.02, 0.28), (0.06, 0.06, 0.09), tunic, 8, 6, rot=(0, s * 0.4, 0)))
        objs.append(sphere((s * 0.27, -0.04, 0.2), 0.05, sk, 8, 6))
        objs.append(sphere((s * 0.3, 0.02, 0.6), (0.05, 0.03, 0.08), sk, 8, 6))
    hc, r = (0, 0, 0.56), 0.3
    objs.append(sphere((0, -r * 0.97, 0.53), 0.045, mat("nez", SKIN_DARK, 0.5), 8, 6))
    _face(hc, r, objs, big_eyes=1.35, eye_spread=0.34)
    capm = mat("cupule", o["hat"][1], 0.9)
    objs.append(sphere((0, 0.0, 0.76), (0.33, 0.32, 0.17), capm, 16, 8))
    for i in range(16):  # écailles de la cupule
        a = i * math.pi / 8
        objs.append(sphere((0.3 * math.cos(a), 0.29 * math.sin(a), 0.73), 0.045, capm, 6, 4))
    objs.append(cyl((0.02, 0.02, 0.95), 0.025, 0.1, mat("tige", (110, 80, 40)), rot=(0.2, 0.3, 0)))
    return hc, r


def _variant_c(o, objs, skin):
    """Variante C « Bloc » : formes cubiques arrondies, assorties au monde en blocs, longues oreilles."""
    tunic = mat("tunique", o["tunic"], 0.85)
    sk = mat("peau", skin, 0.55)
    for s in (-1, 1):
        objs.append(box((s * 0.08, -0.01, 0.07), (0.1, 0.14, 0.14), mat("botte", BOOT, 0.7), bevel=0.02))
    objs.append(box((0, 0, 0.3), (0.34, 0.26, 0.3), tunic, bevel=0.05))
    objs.append(box((0, 0, 0.2), (0.35, 0.27, 0.04), mat("ceinture", LEATHER, 0.7), bevel=0.01))
    for s in (-1, 1):
        objs.append(box((s * 0.21, 0, 0.3), (0.08, 0.09, 0.2), tunic, bevel=0.025))
        objs.append(box((s * 0.21, -0.01, 0.17), (0.08, 0.08, 0.07), sk, bevel=0.025))
    hc, r = (0, 0, 0.64), 0.26
    objs.append(box(hc, (0.52, 0.46, 0.44), sk, bevel=0.08))
    objs.append(box((0, -0.25, 0.6), (0.09, 0.07, 0.08), mat("nez", SKIN_DARK, 0.5), bevel=0.025))
    eye, white = mat("oeil", EYE, 0.2), mat("reflet", WHITE, 0.2, emit=0.6)
    for s in (-1, 1):
        objs.append(box((s * 0.11, -0.23, 0.68), (0.07, 0.02, 0.1), eye, bevel=0.01))
        objs.append(box((s * 0.11 + 0.015, -0.245, 0.7), (0.025, 0.01, 0.025), white))
        objs.append(box((s * 0.17, -0.232, 0.58), (0.07, 0.01, 0.035), mat("joue", CHEEK, 0.8)))
        objs.append(box((s * 0.33, 0.06, 0.7), (0.24, 0.05, 0.09), sk, rot=(0, s * -0.35, s * 0.35), bevel=0.02))
    hood = mat("capuche_c", o["hat"][1], 0.85)
    objs.append(box((0, 0.04, 0.84), (0.56, 0.5, 0.12), hood, bevel=0.04))
    objs.append(box((0, 0.22, 0.68), (0.56, 0.12, 0.36), hood, bevel=0.04))
    objs.append(cone((0, 0.3, 0.92), 0.14, 0.32, hood, verts=4, rot=(-1.0, 0, math.pi / 4)))
    return hc, r


def _extras(o, objs, hc, r):
    ex = o["extras"]
    if "caisse_bras" in ex:
        # le porteur transporte une caisse de vivres dans les bras
        objs.append(box((0, -0.22, 0.3), (0.34, 0.2, 0.22), mat("caisse", (176, 126, 70), 0.8), bevel=0.01))
        objs.append(box((0, -0.22, 0.3), (0.35, 0.21, 0.035), mat("cerclage", (110, 74, 40))))
        for i, c in enumerate(((210, 60, 40), (230, 180, 50), (210, 60, 40))):
            objs.append(sphere((-0.09 + i * 0.09, -0.22, 0.43), 0.055, mat(f"fruit{i}", c, 0.4), 8, 6))
    if "carquois" in ex:
        objs.append(cyl((0.08, 0.2, 0.45), 0.06, 0.32, mat("carquois", LEATHER), rot=(0.25, -0.3, 0)))
        for i in range(3):
            objs.append(cone((0.11 + i * 0.025, 0.25, 0.65), 0.02, 0.06, mat("plume", (230, 230, 230)), verts=4))
    if "tablier_cuir" in ex or "tablier_blanc" in ex:
        c = LEATHER if "tablier_cuir" in ex else WHITE
        objs.append(box((0, -0.17, 0.25), (0.26, 0.02, 0.3), mat("tablier", c, 0.8), rot=(0.12, 0, 0), bevel=0.01))
    if "ceinture_outils" in ex:
        for s, c in ((-1, METAL), (1, WOOD)):
            objs.append(box((s * 0.12, -0.15, 0.24), (0.04, 0.03, 0.1), mat("o", c)))
    if "lunettes" in ex:
        gl = mat("monture", (60, 40, 30), 0.4)
        for s in (-1, 1):
            objs.append(torus((s * r * 0.36, hc[1] - r * 0.97, hc[2] + r * 0.12), 0.06, 0.008, gl, rot=(math.pi / 2, 0, 0)))
    if "medaille" in ex:
        objs.append(cyl((0, -0.19, 0.42), 0.04, 0.015, mat("or", GOLD, 0.3, metal=0.9), rot=(math.pi / 2, 0, 0), verts=12))


def build(variant="A", job="porteur", age="adult", name="lutin", loc=(0, 0, 0), rot_z=0.0, scale=1.0):
    """Construit un lutin et renvoie son objet racine."""
    o = dict(OUTFITS[job])
    o["extras"] = list(o["extras"])
    objs = []
    skin = SKIN_ELDER if age == "elder" else SKIN
    s_age = {"baby": 0.5, "child": 0.72, "adult": 1.0, "elder": 0.95}[age]
    if age == "baby":
        o.update(tunic=(250, 236, 180), hat=("calotte", (250, 206, 214)), tool=None, extras=[])
    if age == "child":
        o.update(tunic=(120, 190, 120), hat=("pointu", (240, 150, 60)), tool=None, extras=[])
    if age == "elder":
        o.update(hat=("pointu", (150, 140, 160)))
    if variant == "A":
        hc, r = _variant_a(o, objs, skin, s_head={"baby": 1.22, "child": 1.1}.get(age, 1.0))
        _hat(o["hat"][0], o["hat"][1], hc, r, objs)
    elif variant == "B":
        hc, r = _variant_b(o, objs, skin)
    else:
        hc, r = _variant_c(o, objs, skin)
    _extras(o, objs, hc, r)
    hand = (-0.25, -0.07, 0.25)
    if o["tool"]:
        _tool(o["tool"], hand, objs)
    if age == "baby":  # lange et tétine
        objs.append(sphere((0, -r * 1.0, hc[2] - r * 0.35), (0.06, 0.03, 0.045), mat("tetine", (120, 200, 230)), 8, 6))
    if age == "child":  # cartable
        objs.append(box((0, 0.2, 0.36), (0.26, 0.1, 0.22), mat("cartable", (190, 70, 60), 0.7), bevel=0.02))
        objs.append(box((-0.08, -0.17, 0.4), (0.03, 0.02, 0.24), mat("bretelle", LEATHER)))
        objs.append(box((0.08, -0.17, 0.4), (0.03, 0.02, 0.24), mat("bretelle", LEATHER)))
    if age == "elder":  # barbe, sourcils, canne
        beard = mat("barbe", (240, 240, 236), 0.95)
        objs.append(cone((0, -r * 0.82, hc[2] - r * 0.6), r * 0.55, r * 1.1, beard, verts=10, rot=(math.pi + 0.25, 0, 0)))
        for s in (-1, 1):
            objs.append(box((s * r * 0.38, -r * 0.92, hc[2] + r * 0.4), (0.1, 0.03, 0.03), beard, rot=(0, s * 0.25, 0)))
        objs.append(cyl((-0.3, -0.06, 0.2), 0.022, 0.42, mat("canne", (110, 70, 40)), rot=(0, 0.12, 0)))
        objs.append(torus((-0.28, -0.06, 0.42), 0.04, 0.018, mat("canne", (110, 70, 40)), rot=(math.pi / 2, 0, 0), seg=10))
    root = group(objs, name, loc, rot_z, scale * s_age)
    if age == "elder":
        for ob in objs:  # léger dos voûté : on penche la partie haute
            if ob.location.z > 0.45:
                ob.location.y -= (ob.location.z - 0.45) * 0.25
    return root
