"""Aperçu des Orcs (Phase 2) : 2 propositions, à côté d'un lutin pour l'échelle.

Usage : blender -b -P tools/style/render_orcs.py -- <dossier_sortie>
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import blib  # noqa: E402
import lutin  # noqa: E402
from blib import box, cone, cyl, group, mat, sphere, torus  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = Path(argv[0])
OUT.mkdir(parents=True, exist_ok=True)

RED = (206, 68, 56)
RED_DARK = (160, 44, 40)
TUSK = (246, 236, 206)
EYE = (255, 214, 60)
SCRAP = (130, 132, 140)
RUST = (150, 86, 50)
LEATHER = (96, 62, 40)


def eyes(objs, y, z, spread, angry=True):
    for s in (-1, 1):
        objs.append(sphere((s * spread, y, z), (0.05, 0.02, 0.035), mat("oeil_orc", EYE, 0.3, emit=0.8), 8, 6))
        objs.append(sphere((s * spread, y - 0.012, z), 0.018, mat("pupille", (20, 16, 20)), 6, 4))
        if angry:  # sourcils froncés
            objs.append(box((s * spread, y - 0.01, z + 0.06), (0.12, 0.03, 0.03), mat("sourcil", (70, 30, 26)), rot=(0, s * -0.35, 0)))


def orc_a(loc):
    """A « Marmite » : gros ventre rond, petite tête, défenses, casque-marmite, gourdin."""
    objs = []
    skin = mat("peau_orc", RED, 0.6)
    for s in (-1, 1):
        objs.append(cyl((s * 0.2, 0, 0.18), 0.1, 0.3, mat("pantalon_orc", (80, 66, 50)), verts=8))
        objs.append(box((s * 0.2, -0.05, 0.06), (0.2, 0.28, 0.12), mat("botte_orc", LEATHER), bevel=0.03))
    objs.append(sphere((0, 0, 0.62), (0.48, 0.42, 0.46), skin, 16, 10))  # ventre
    objs.append(sphere((0, -0.06, 0.52), (0.42, 0.38, 0.2), mat("pagne", (120, 90, 60), 0.9), 14, 6))
    objs.append(torus((0, 0, 0.45), 0.44, 0.04, mat("ceinture_orc", LEATHER), seg=18))
    objs.append(box((0, -0.43, 0.45), (0.12, 0.04, 0.1), mat("boucle", SCRAP, 0.4, metal=0.6)))
    # bretelle + plastron de récupération
    objs.append(box((0.12, -0.36, 0.8), (0.07, 0.04, 0.5), mat("sangle", LEATHER), rot=(0.2, 0.5, 0)))
    objs.append(box((-0.18, -0.38, 0.86), (0.26, 0.05, 0.2), mat("plaque", SCRAP, 0.5, metal=0.5), rot=(0.25, 0, 0.1), bevel=0.02))
    for i in range(3):
        objs.append(sphere((-0.28 + i * 0.1, -0.42, 0.9), 0.016, mat("rivet", (90, 90, 96)), 6, 4))
    # bras épais
    for s in (-1, 1):
        objs.append(sphere((s * 0.5, 0, 0.78), (0.14, 0.14, 0.14), skin, 10, 8))
        objs.append(cyl((s * 0.55, -0.02, 0.6), 0.1, 0.32, skin, verts=8, rot=(0, s * 0.2, 0)))
        objs.append(sphere((s * 0.58, -0.04, 0.42), 0.11, skin, 10, 8))
    objs.append(box((0.5, 0.0, 0.8), (0.24, 0.24, 0.1), mat("epaulette", RUST, 0.6, metal=0.4), rot=(0, 0.35, 0), bevel=0.03))
    # tête
    hz = 1.26
    objs.append(sphere((0, -0.04, hz), (0.26, 0.24, 0.22), skin, 14, 8))
    objs.append(sphere((0, -0.14, hz - 0.1), (0.22, 0.16, 0.1), mat("machoire", RED_DARK, 0.6), 12, 6))
    for s in (-1, 1):
        objs.append(cone((s * 0.12, -0.25, hz - 0.03), 0.035, 0.12, mat("defense", TUSK, 0.4), verts=6, rot=(-0.2, 0, 0)))
        objs.append(cone((s * 0.27, 0.0, hz + 0.02), 0.06, 0.14, skin, verts=6, rot=(0, s * 1.3, 0)))
    objs.append(sphere((0, -0.26, hz + 0.02), (0.07, 0.05, 0.05), mat("nez_orc", RED_DARK), 8, 6))
    eyes(objs, -0.235, hz + 0.04, 0.1)
    # casque-marmite cabossé
    objs.append(sphere((0, 0.0, hz + 0.16), (0.29, 0.27, 0.16), mat("marmite", (90, 90, 96), 0.45, metal=0.7), 14, 6))
    objs.append(torus((0, 0.0, hz + 0.13), 0.28, 0.025, mat("marmite", (90, 90, 96), 0.45, metal=0.7), seg=16))
    objs.append(cyl((0.3, 0.0, hz + 0.2), 0.02, 0.12, mat("anse", (70, 70, 74)), rot=(0, 1.2, 0)))
    # gourdin
    objs.append(cyl((-0.66, -0.12, 0.62), 0.04, 0.6, mat("gourdin", (120, 80, 44)), rot=(0.1, -0.4, 0)))
    objs.append(sphere((-0.78, -0.14, 0.92), (0.11, 0.11, 0.16), mat("gourdin", (120, 80, 44)), 8, 6, rot=(0, -0.4, 0)))
    for i in range(4):
        a = i * 1.6
        objs.append(cone((-0.78 + 0.1 * math.cos(a), -0.14 + 0.1 * math.sin(a), 0.96), 0.02, 0.07, mat("clou", SCRAP), verts=4,
                         rot=(math.sin(a) * -1.4, math.cos(a) * 1.4, 0)))
    return group(objs, "orc_a", loc, math.radians(25))


def orc_b(loc):
    """B « Bedaine à crête » : poire, crête de cheveux, une épaulière de bric et de broc, couperet."""
    objs = []
    skin = mat("peau_orc_b", (214, 84, 66), 0.6)
    for s in (-1, 1):
        objs.append(sphere((s * 0.18, -0.04, 0.08), (0.14, 0.18, 0.09), mat("pied", RED_DARK), 8, 6))
        objs.append(cyl((s * 0.18, 0, 0.2), 0.09, 0.2, skin, verts=8))
    objs.append(sphere((0, 0, 0.6), (0.44, 0.4, 0.5), skin, 16, 10))
    objs.append(cyl((0, 0, 0.4), 0.43, 0.24, mat("jupe_cuir", LEATHER, 0.8), verts=12, r2=0.4))
    for i in range(8):  # lanières de la jupe
        a = i * math.pi / 4
        objs.append(box((0.43 * math.cos(a), 0.41 * math.sin(a), 0.3), (0.08, 0.03, 0.14), mat("lanière", (80, 50, 34)),
                        rot=(0, 0, a + math.pi / 2)))
    objs.append(sphere((0, -0.12, 0.66), (0.3, 0.3, 0.32), mat("ventre_clair", (232, 120, 100), 0.6), 12, 8))
    # épaulière unique en bouclier recyclé
    objs.append(sphere((-0.42, 0, 0.92), (0.2, 0.2, 0.12), mat("bouclier", RUST, 0.55, metal=0.5), 12, 6, rot=(0, -0.6, 0)))
    objs.append(cone((-0.5, 0, 1.02), 0.04, 0.12, mat("pointe", SCRAP, 0.4, metal=0.6), verts=6, rot=(0, -0.6, 0)))
    objs.append(box((0.0, -0.3, 0.85), (0.08, 0.04, 0.55), mat("baudrier", LEATHER), rot=(0, -0.7, 0)))
    for s in (-1, 1):
        objs.append(cyl((s * 0.48, -0.03, 0.66), 0.09, 0.36, skin, verts=8, rot=(0, s * 0.25, 0)))
        objs.append(sphere((s * 0.53, -0.06, 0.46), 0.1, skin, 10, 8))
    # tête dans les épaules
    hz = 1.12
    objs.append(sphere((0, -0.06, hz), (0.25, 0.23, 0.24), skin, 14, 8))
    objs.append(sphere((0, -0.27, hz - 0.03), (0.09, 0.06, 0.06), mat("museau", (180, 56, 50)), 10, 6))
    for s in (-1, 1):
        objs.append(sphere((s * 0.035, -0.32, hz - 0.03), 0.015, mat("narine", (60, 20, 20)), 6, 4))
        objs.append(cone((s * 0.1, -0.24, hz - 0.12), 0.03, 0.1, mat("defense", TUSK, 0.4), verts=6, rot=(0.3, 0, 0)))
        objs.append(cone((s * 0.27, -0.02, hz + 0.08), 0.05, 0.2, skin, verts=5, rot=(0, s * 1.0, 0)))
        objs.append(torus((s * 0.33, -0.02, hz + 0.02), 0.025, 0.007, mat("anneau", (230, 190, 70), 0.3, metal=0.9), seg=10))
    eyes(objs, -0.23, hz + 0.06, 0.1)
    for i in range(6):  # crête de cheveux noirs
        objs.append(cone((0, -0.14 + i * 0.06, hz + 0.24 - abs(i - 2.5) * 0.015), 0.04, 0.16, mat("crete", (40, 30, 34)), verts=4,
                         rot=(-0.3 + i * 0.12, 0, 0)))
    # couperet
    objs.append(cyl((0.56, -0.12, 0.5), 0.03, 0.26, mat("manche", (90, 60, 40)), rot=(0.5, 0, 0)))
    objs.append(box((0.56, -0.3, 0.68), (0.03, 0.3, 0.2), mat("lame", (170, 172, 176), 0.35, metal=0.7), rot=(0.5, 0, 0)))
    return group(objs, "orc_b", loc, math.radians(-20))


blib.reset_scene()
blib.lights(sun_dir=(math.radians(50), 0, math.radians(-30)), strength=3.2, world=(214, 222, 238), world_strength=0.8)
blib.backdrop((232, 224, 210))
orc_a((-0.95, 0.1, 0))
lutin.build("A", "bucheron", "adult", loc=(0.05, -0.3, 0), rot_z=math.radians(10))
orc_b((1.05, 0.1, 0))
blib.camera((0, -6.0, 1.7), (0.05, 0, 0.7), lens=50)
blib.render(OUT / "orcs.png", 1600, 900)
