"""Modèles low-poly originaux des Lutins (variante A « Bouille », retenue), tenues par métier, âges.

Tout est construit à partir de primitives : aucun asset externe.
"""

import math

import outils
from blib import box, cone, cyl, group, limb, mat, sphere, torus

# Peaux proposées : (peau, nez/ombre). « vert » = proposition gobelin vert foncé d'Ashura.
SKINS = {
    "bleu": ((92, 156, 226), (70, 128, 204)),
    "bleu_sombre": ((70, 108, 160), (54, 86, 132)),
    "vert": ((84, 110, 60), (64, 88, 46)),
}
SKIN_DARK = SKINS["bleu"][1]
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
    "porteur":          dict(tunic=(196, 170, 120), hat=("bandeau", (210, 80, 60)), tool=None, extras=["sangles"]),
    "bucheron":         dict(tunic=(170, 60, 50), hat=("pointu", (60, 130, 70)), tool="hache", extras=[]),
    "mineur":           dict(tunic=(90, 90, 100), hat=("casque", (210, 170, 60)), tool="pioche", extras=[]),
    "terrassier":       dict(tunic=(150, 110, 70), hat=("pointu", (120, 80, 50)), tool="pelle", extras=[]),
    "batisseur":        dict(tunic=(230, 150, 50), hat=("pointu", (240, 200, 60)), tool="marteau", extras=["ceinture_outils"]),
    "cueilleur":        dict(tunic=(140, 170, 80), hat=("capuche", (200, 80, 120)), tool="panier", extras=[]),
    "pecheur":          dict(tunic=(60, 110, 150), hat=("large", (230, 200, 70)), tool="canne", extras=[]),
    "chasseur":         dict(tunic=(80, 110, 60), hat=("capuche", (60, 90, 50)), tool="fusil", extras=["corne_poudre"]),
    "fermier":          dict(tunic=(110, 150, 190), hat=("large", (220, 190, 110)), tool="houe", extras=[]),
    "menuisier":        dict(tunic=(200, 120, 60), hat=("pointu", (150, 90, 50)), tool="scie", extras=["tablier_cuir"]),
    "tailleur_pierre":  dict(tunic=(160, 160, 150), hat=("beret", (110, 110, 120)), tool="ciseau", extras=["tablier_cuir"]),
    "forgeron":         dict(tunic=(60, 56, 60), hat=("calotte", (40, 40, 44)), tool="pinces", extras=["tablier_cuir"]),
    "cuisinier":        dict(tunic=(230, 230, 224), hat=("toque", (252, 252, 250)), tool="louche", extras=["tablier_blanc"]),
    "maitre_ecole":     dict(tunic=(120, 70, 140), hat=("beret", (70, 50, 110)), tool="livre", extras=["lunettes"]),
    "chercheur":        dict(tunic=(50, 70, 130), hat=("pointu_haut", (40, 50, 110)), tool="parchemin", extras=["lunettes", "robe"]),
    "soldat":           dict(tunic=(120, 36, 40), hat=("heaume", (150, 152, 160)), tool="epee", extras=["cotte"]),
    "artisan_expert":   dict(tunic=(150, 40, 50), hat=("beret", (190, 50, 60)), tool="marteau_or", extras=["ceinture_outils", "medaille"]),
}

JOB_NAMES = {
    "porteur": "Porteur", "bucheron": "Bûcheron", "mineur": "Mineur", "terrassier": "Terrassier",
    "batisseur": "Bâtisseur", "cueilleur": "Cueilleur", "pecheur": "Pêcheur", "chasseur": "Chasseur",
    "fermier": "Fermier", "menuisier": "Menuisier", "tailleur_pierre": "Tailleur de pierre",
    "forgeron": "Forgeron", "cuisinier": "Cuisinier", "maitre_ecole": "Maître d'école",
    "chercheur": "Chercheur", "artisan_expert": "Artisan expert",
}


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
    elif kind == "heaume":  # casque de fer à nasal (Phase 2)
        steel = mat("acier", color, 0.35, metal=0.8)
        objs.append(sphere((x, y, top - 0.06), (r * 1.04, r * 1.04, r * 0.7), steel, 14, 7))
        objs.append(torus((x, y, top - 0.08), r * 1.02, r * 0.07, steel, seg=16))
        objs.append(box((x, y - r * 1.02, z + r * 0.2), (0.04, 0.03, r * 0.6), steel))
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


def _variant_a(o, objs, skin, s_head=1.0, action=False, nose=SKIN_DARK):
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
    hands = {}
    for s in (-1, 1):
        shoulder = (s * 0.18, 0, 0.44)
        # en action, la main droite (côté -X) se lève devant le corps pour tenir l'outil
        hand = (-0.3, -0.12, 0.4) if (action and s == -1) else (s * 0.25, -0.03, 0.25)
        objs.append(limb(shoulder, hand, 0.045, tunic))
        objs.append(sphere(hand, 0.055, sk, 10, 6))
        hands[s] = hand
    # tête
    r = 0.28 * s_head
    hc = (0, 0, 0.66 + (r - 0.28) * 0.8)
    objs.append(sphere(hc, r, sk, 16, 10))
    objs.append(sphere((0, -r * 0.98, hc[2] - r * 0.08), r * 0.26, mat("nez", nose, 0.5), 10, 6))
    for s in (-1, 1):
        objs.append(cone((s * r * 1.02, 0.02, hc[2] + 0.02), r * 0.2, r * 0.7, sk, verts=6, rot=(0, s * 1.25, 0)))
    _face(hc, r, objs)
    return hc, r, hands


def _extras(o, objs, hc, r):
    ex = o["extras"]
    if "sangles" in ex:  # porteur au repos : sangles de portage sur le dos
        objs.append(box((0, 0.17, 0.36), (0.26, 0.05, 0.24), mat("sangle", LEATHER), bevel=0.01))
    if "caisse_bras" in ex:
        # le porteur transporte une caisse de vivres dans les bras
        objs.append(box((0, -0.22, 0.3), (0.34, 0.2, 0.22), mat("caisse", (176, 126, 70), 0.8), bevel=0.01))
        objs.append(box((0, -0.22, 0.3), (0.35, 0.21, 0.035), mat("cerclage", (110, 74, 40))))
        for i, c in enumerate(((210, 60, 40), (230, 180, 50), (210, 60, 40))):
            objs.append(sphere((-0.09 + i * 0.09, -0.22, 0.43), 0.055, mat(f"fruit{i}", c, 0.4), 8, 6))
    if "corne_poudre" in ex:  # corne à poudre + sacoche à balles
        objs.append(cone((0.17, -0.1, 0.3), 0.035, 0.16, mat("corne", (226, 210, 170), 0.5), verts=8, rot=(0, 1.9, 0.3)))
        objs.append(box((-0.12, -0.15, 0.24), (0.08, 0.04, 0.07), mat("sacoche", LEATHER), bevel=0.01))
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
    if "cotte" in ex:  # plastron de cuir clouté
        objs.append(sphere((0, -0.03, 0.36), (0.205, 0.17, 0.16), mat("plastron", (70, 52, 40), 0.6), 12, 6))
        for i in range(5):
            objs.append(sphere((-0.1 + i * 0.05, -0.2, 0.38), 0.014, mat("clou", (170, 170, 176), 0.3, metal=0.8), 6, 4))
    if "medaille" in ex:
        objs.append(cyl((0, -0.19, 0.42), 0.04, 0.015, mat("or", GOLD, 0.3, metal=0.9), rot=(math.pi / 2, 0, 0), verts=12))


def grade(c, sombre):
    """Ambiance sombre : couleurs désaturées et assombries (dark fantasy)."""
    if not sombre:
        return c
    g = sum(c) / 3
    return tuple(int((v * 0.6 + g * 0.4) * 0.72) for v in c)


def build(job="porteur", age="adult", name="lutin", loc=(0, 0, 0), rot_z=0.0, scale=1.0,
          action=False, skin="bleu", sombre=False):
    """Construit un lutin et renvoie son objet racine.

    action : l'outil du métier n'apparaît qu'en action (sinon mains vides).
    """
    o = dict(OUTFITS[job])
    o["extras"] = list(o["extras"])
    objs = []
    sk, nose = SKINS[skin]
    if age == "elder":
        sk = tuple(min(255, int(v * 0.8 + 50)) for v in sk)
    s_age = {"baby": 0.5, "child": 0.72, "adult": 1.0, "elder": 0.95}[age]
    if age == "baby":
        o.update(tunic=(250, 236, 180), hat=("calotte", (250, 206, 214)), tool=None, extras=[])
    if age == "child":
        o.update(tunic=(120, 190, 120), hat=("pointu", (240, 150, 60)), tool=None, extras=[])
    if age == "elder":
        o.update(hat=("pointu", (150, 140, 160)), tool=None, extras=[])
    if action and job == "porteur":
        o["extras"] = ["caisse_bras"]
    o["tunic"] = grade(o["tunic"], sombre)
    o["hat"] = (o["hat"][0], grade(o["hat"][1], sombre))
    holds = action and bool(o["tool"]) and job != "porteur"
    hc, r, hands = _variant_a(o, objs, sk, s_head={"baby": 1.22, "child": 1.1}.get(age, 1.0), action=holds, nose=nose)
    _hat(o["hat"][0], o["hat"][1], hc, r, objs)
    _extras(o, objs, hc, r)
    if holds:
        outils.place(o["tool"], hands[-1], objs)
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
