"""Chasseur au fusil à silex : porté dans le dos, en visée, et au tir (flash) face à un loup.

Usage : blender -b -P tools/style/render_tir.py -- <dossier_sortie>
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402

import blib  # noqa: E402
import lutin  # noqa: E402
from blib import cone, group, limb, mat, sphere  # noqa: E402

OUT = Path(sys.argv[sys.argv.index("--") + 1])
OUT.mkdir(parents=True, exist_ok=True)


def loup(loc, rot_z=0.0):
    """Loup low-poly original (premier prédateur) : ~0,8 bloc au garrot, tourné vers -Y par défaut."""
    fur, dark = mat("fourrure", (138, 132, 124), 0.9), mat("fourrure_d", (92, 86, 80), 0.9)
    o = [sphere((0, 0, 0.55), (0.22, 0.5, 0.22), fur, 12, 8),                 # corps
         sphere((0, -0.48, 0.72), (0.17, 0.2, 0.16), fur, 10, 8),             # tête
         cone((0, -0.72, 0.68), 0.09, 0.26, dark, verts=6, rot=(math.pi / 2, 0, 0)),  # museau
         sphere((0, -0.84, 0.69), 0.03, mat("truffe", (20, 18, 18)), 6, 4),
         limb((0, 0.45, 0.62), (0, 0.85, 0.45), 0.07, dark)]                  # queue
    for s in (-1, 1):
        o.append(cone((s * 0.09, -0.46, 0.9), 0.05, 0.14, dark, verts=4))   # oreilles
        o.append(sphere((s * 0.08, -0.62, 0.77), 0.022, mat("oeil_loup", (230, 190, 60), 0.3, emit=2.0), 6, 4))
        for fy in (-0.3, 0.3):
            o.append(limb((s * 0.12, fy, 0.5), (s * 0.12, fy - 0.05, 0.03), 0.05, dark))
    # babines retroussées : crocs
    for s in (-1, 1):
        o.append(cone((s * 0.04, -0.78, 0.62), 0.012, 0.05, mat("croc", (236, 230, 210)), verts=4, rot=(math.pi, 0, 0)))
    return group(o, "loup", loc, rot_z)


def studio():
    blib.reset_scene()
    blib.lights(sun_dir=(math.radians(52), 0, math.radians(-40)), strength=4.2, world=(70, 76, 92), world_strength=0.8,
                sun_color=(255, 226, 190))
    blib.backdrop((96, 108, 70))


kw = dict(skin="bleu_sombre", sombre=True)
# 1) repos : fusil porté en bandoulière
studio()
lutin.build("chasseur", rot_z=math.radians(210), **kw)
blib.camera((0, -4.2, 1.3), (0, 0, 0.5), lens=90)
blib.render(OUT / "tir_repos.png", 420, 520)
# 2) visée (sans tirer) — vue de trois-quarts
studio()
lutin.build("chasseur", rot_z=math.radians(-35), action=True, **kw)
blib.camera((0, -4.2, 1.3), (0, -0.3, 0.5), lens=80)
blib.render(OUT / "tir_vise.png", 420, 520)
# 3) le tir : flash au bout du canon, face au loup (vue de côté)
studio()
lutin.build("chasseur", loc=(0, 1.6, 0), action=True, tir=True, **kw)
loup((0, -2.2, 0), rot_z=math.pi)
blib.camera((7.5, -0.6, 2.2), (0, -0.2, 0.55), lens=50)
blib.render(OUT / "tir_feu.png", 1200, 620)
