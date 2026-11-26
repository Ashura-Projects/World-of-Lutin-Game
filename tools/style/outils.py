"""Outils des lutins (v2) : modèles à l'échelle, construits en coordonnées locales.

Convention : la poignée (là où la main serre) est à l'origine, le manche suit +Z,
la partie « travaillante » de l'outil est orientée vers +X. Le lutin place ensuite
l'outil dans sa main avec une rotation propre à chaque geste (voir POSES).
L'outil n'apparaît que pendant l'action (validé par Ashura).
"""

import math

import bpy

from blib import box, cone, cyl, mat, sphere, torus

WOOD = (128, 88, 52)
WOOD_D = (92, 62, 38)
IRON = (120, 124, 132)
EDGE = (196, 200, 206)
DARK = (58, 58, 64)
BRASS = (190, 150, 70)

# outil -> (rotation de l'outil dans la main en action, décalage de la main)
# rotation (x, y, z) : x > 0 penche l'outil vers l'avant, y < 0 vers l'extérieur (côté main droite).
POSES = {
    "hache": ((0.15, -0.95, 0.0), (0, 0, 0)),         # levée, prête à frapper
    "pioche": ((0.15, -0.95, 0.0), (0, 0, 0)),
    "marteau": ((0.15, -0.8, 0.0), (0, 0, 0)),
    "marteau_or": ((0.15, -0.8, 0.0), (0, 0, 0)),
    "pelle": ((0.35, 0.15, 0.0), (0, 0, -0.05)),     # tenue basse, lame vers le sol
    "houe": ((0.2, -0.8, 1.57), (0, 0, 0)),
    "scie": ((1.45, 0.0, 0.0), (0, 0, -0.04)),       # horizontale, vers l'avant
    "ciseau": ((0.4, -0.5, 0.0), (0, 0, 0)),
    "pinces": ((0.5, -0.6, 0.0), (0, 0, 0)),
    "louche": ((0.3, -0.6, 0.0), (0, 0, 0)),
    "canne": ((0.75, -0.35, 0.0), (0, 0, 0)),
    "fusil_vise": ((math.pi / 2, 0.0, 0.0), (0.0, 0.0, 0.0)),   # épaulé, canon pointé vers l'avant (-Y)
    "fusil_dos": ((0.0, 0.75, 0.0), (0.0, 0.0, 0.0)),           # en bandoulière, canon vers le haut
    "epee": ((0.2, -0.7, 0.0), (0, 0, 0)),
    "panier": ((0.0, 0.0, 0.0), (0, -0.02, -0.02)),
    "livre": ((0.3, 0.0, 0.0), (0.04, -0.02, 0.04)),
    "parchemin": ((0.0, 0.0, 0.0), (0.03, -0.04, 0.04)),
}


def _handle(length, below=0.08, r=0.018, color=WOOD):
    return cyl((0, 0, length / 2 - below), r, length, mat("manche", color, 0.8), verts=8)


def build(name):
    """Crée les objets de l'outil (coordonnées locales) et les renvoie."""
    iron, edge, wood = mat("fer", IRON, 0.4, metal=0.7), mat("tranchant", EDGE, 0.25, metal=0.9), mat("bois_o", WOOD, 0.8)
    o = []
    if name == "hache":
        o.append(_handle(0.46))
        o.append(box((0.045, 0, 0.33), (0.07, 0.035, 0.08), iron, bevel=0.01))
        o.append(cyl((0.11, 0, 0.33), 0.075, 0.025, edge, verts=6, rot=(math.pi / 2, 0, 0)))  # fer en éventail
        o.append(box((0.07, 0, 0.33), (0.05, 0.026, 0.12), iron))
    elif name == "pioche":
        o.append(_handle(0.48))
        o.append(box((0, 0, 0.36), (0.06, 0.05, 0.06), iron, bevel=0.01))
        for s in (-1, 1):
            o.append(cone((s * 0.11, 0, 0.34), 0.028, 0.18, iron, verts=6, rot=(0, s * (math.pi / 2 + 0.25), 0)))
    elif name in ("marteau", "marteau_or"):
        m = mat("or", (226, 176, 60), 0.3, metal=0.9) if name == "marteau_or" else iron
        o.append(_handle(0.32))
        o.append(box((0.02, 0, 0.21), (0.14, 0.065, 0.065), m, bevel=0.012))
    elif name == "pelle":
        o.append(cyl((0, 0, -0.18), 0.018, 0.5, wood, verts=8))
        o.append(torus((0, 0, 0.1), 0.035, 0.01, wood, rot=(math.pi / 2, 0, 0), seg=10))
        o.append(box((0, 0, -0.5), (0.13, 0.02, 0.16), iron, bevel=0.01))
        o.append(cone((0, 0, -0.6), 0.09, 0.07, iron, verts=4, rot=(math.pi, 0, math.pi / 4)))
    elif name == "houe":
        o.append(_handle(0.5))
        o.append(box((0.04, 0, 0.4), (0.03, 0.12, 0.02), iron))
        o.append(box((0.07, 0, 0.36), (0.02, 0.12, 0.09), edge))
    elif name == "scie":
        o.append(box((0, 0, 0.0), (0.05, 0.035, 0.08), wood, bevel=0.01))
        o.append(box((0.0, 0, 0.2), (0.008, 0.07, 0.32), edge, rot=(0.08, 0, 0)))
    elif name == "ciseau":
        o.append(cyl((0, 0, 0.05), 0.016, 0.22, wood, verts=6))
        o.append(cyl((0, 0, 0.17), 0.055, 0.13, mat("maillet", (160, 112, 66), 0.8), verts=8, rot=(0, math.pi / 2, 0)))
    elif name == "pinces":
        dark = mat("fer_noir", DARK, 0.4, metal=0.7)
        for s in (-1, 1):
            o.append(box((s * 0.012, 0, 0.16), (0.016, 0.02, 0.36), dark, rot=(0, s * 0.05, 0)))
        o.append(box((0, 0, 0.36), (0.1, 0.05, 0.045), mat("lingot", (255, 120, 30), 0.4, emit=6.0)))
    elif name == "louche":
        o.append(cyl((0, 0, 0.12), 0.011, 0.34, iron, verts=6))
        o.append(sphere((0.04, 0, 0.3), (0.07, 0.07, 0.045), iron, 10, 6))
    elif name == "canne":
        o.append(cyl((0, 0, 0.42), 0.012, 0.95, mat("bambou", (170, 140, 80), 0.6), verts=6))
        o.append(torus((0.02, 0, 0.12), 0.025, 0.008, iron, rot=(math.pi / 2, 0, 0), seg=8))  # moulinet
    elif name in ("fusil", "fusil_vise", "fusil_dos"):  # fusil à silex, à l'échelle du lutin
        stock = mat("crosse", WOOD_D, 0.6)
        o.append(box((0, 0, -0.1), (0.05, 0.035, 0.2), stock, rot=(0.12, 0, 0), bevel=0.008))  # crosse
        o.append(box((0, 0, 0.22), (0.032, 0.03, 0.5), stock, bevel=0.006))                   # fût long (fusil à silex)
        o.append(cyl((0, -0.012, 0.38), 0.014, 0.56, mat("canon", DARK, 0.35, metal=0.8), verts=8))
        o.append(box((0.022, 0, 0.04), (0.012, 0.03, 0.05), mat("platine", BRASS, 0.35, metal=0.8)))  # platine à silex
        o.append(box((0.03, 0, 0.075), (0.01, 0.012, 0.03), mat("chien", DARK, 0.4, metal=0.7), rot=(0, -0.5, 0)))
        o.append(torus((-0.022, 0, 0.0), 0.018, 0.004, mat("pontet", BRASS, 0.35, metal=0.8), rot=(0, math.pi / 2, 0), seg=8))
    elif name == "epee":
        o.append(cyl((0, 0, 0.0), 0.016, 0.1, mat("poignee", (70, 44, 30), 0.7), verts=6))
        o.append(sphere((0, 0, -0.06), 0.025, mat("pommeau", BRASS, 0.3, metal=0.8), 8, 6))
        o.append(box((0, 0, 0.06), (0.14, 0.03, 0.025), mat("garde", BRASS, 0.3, metal=0.8)))
        o.append(box((0, 0, 0.28), (0.045, 0.012, 0.4), edge))
        o.append(cone((0, 0, 0.5), 0.032, 0.05, edge, verts=4, rot=(0, 0, math.pi / 4)))
    elif name == "panier":
        wick = mat("osier", (176, 132, 74), 0.9)
        o.append(cyl((0, 0, -0.14), 0.1, 0.11, wick, verts=12, r2=0.12))
        o.append(torus((0, 0, -0.06), 0.09, 0.01, wick, rot=(0, math.pi / 2, 0), seg=12))
        for i in range(5):
            a = i * 1.25
            o.append(sphere((0.05 * math.cos(a), 0.05 * math.sin(a), -0.08), 0.028, mat("baies", (170, 30, 50), 0.3), 8, 6))
    elif name == "livre":
        o.append(box((0, -0.04, 0.0), (0.15, 0.04, 0.19), mat("couverture", (110, 36, 36), 0.6)))
        o.append(box((0, -0.04, 0.0), (0.14, 0.044, 0.175), mat("pages", (230, 220, 196), 0.9)))
    elif name == "parchemin":
        o.append(cyl((0, -0.04, 0), 0.035, 0.24, mat("parch", (226, 210, 170), 0.9), verts=8, rot=(0, math.pi / 2, 0)))
        o.append(sphere((0.0, -0.08, 0.0), 0.018, mat("sceau", (160, 30, 30)), 8, 6))
    return o


MUZZLE = 0.68  # bout du canon, en coordonnées locales du fusil (avant l'échelle 1.3)


def muzzle_flash(objs, hand=(-0.1, -0.16, 0.47)):
    """Tir : flamme et fumée au bout du canon (le canon pointe vers -Y)."""
    y = hand[1] - MUZZLE * 1.3
    x, z = hand[0], hand[2]
    fire = mat("flash", (255, 190, 80), 0.3, emit=40.0)
    core = mat("flash_coeur", (255, 250, 210), 0.3, emit=80.0)
    objs.append(cone((x, y - 0.18, z), 0.12, 0.36, fire, verts=7, rot=(math.pi / 2, 0, 0)))
    objs.append(sphere((x, y - 0.04, z), 0.08, core, 8, 6))
    for i, (dx, dz, r) in enumerate(((0.02, 0.04, 0.07), (-0.03, 0.08, 0.06), (0.0, 0.13, 0.05))):
        objs.append(sphere((x + dx, y - 0.22 - i * 0.06, z + dz), r, mat("fumee", (190, 186, 180), 0.9), 8, 6))
    ld = bpy.data.lights.new("eclair_tir", "POINT")
    ld.energy = 25
    ld.color = (1.0, 0.7, 0.35)
    lo = bpy.data.objects.new("eclair_tir", ld)
    lo.location = (x, y - 0.1, z)
    bpy.context.scene.collection.objects.link(lo)
    objs.append(lo)


def place(name, hand, objs, side=-1):
    """Construit l'outil et le pose dans la main (hand = position de la main, repère du lutin)."""
    rot, off = POSES.get(name, ((0, 0, 0), (0, 0, 0)))
    parts = build(name)
    pivot = bpy.data.objects.new("outil_" + name, None)
    bpy.context.scene.collection.objects.link(pivot)
    for p in parts:
        p.parent = pivot
    pivot.location = (hand[0] + off[0] * -side, hand[1] + off[1], hand[2] + off[2])
    pivot.rotation_euler = (rot[0], rot[1] * -side, rot[2] * -side)
    pivot.scale = (1.3, 1.3, 1.3)  # outils un peu exagérés : lisibles sur téléphone
    objs.append(pivot)
