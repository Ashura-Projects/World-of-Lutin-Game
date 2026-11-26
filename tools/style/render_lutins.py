"""Rendus Blender des lutins (v2, ambiance sombre) : peaux, métiers repos/action, âges, portraits.

Usage : blender -b -P tools/style/render_lutins.py -- <dossier_sortie> [quoi]
quoi = peaux | metiers | ages | portrait | tout (défaut)
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402

import blib  # noqa: E402
import lutin  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(argv[0] if argv else "build/style/renders")
WHAT = argv[1] if len(argv) > 1 else "tout"
OUT.mkdir(parents=True, exist_ok=True)
SKIN = "bleu_sombre"  # peau utilisée pour les planches métiers (en attendant le choix bleu / vert)


def studio(cam_loc=(0, -4.2, 1.2), target=(0, 0, 0.52), lens=95):
    """Clair-obscur : lumière chaude basse + contre-jour froid, fond sombre."""
    blib.reset_scene()
    blib.lights(sun_dir=(math.radians(58), 0, math.radians(-45)), strength=4.2, world=(56, 60, 76),
                world_strength=0.7, sun_color=(255, 214, 160))
    rim = bpy.data.lights.new("contre_jour", "SUN")
    rim.energy = 5.0
    rim.color = blib.srgb((150, 180, 255))[:3]
    ob = bpy.data.objects.new("contre_jour", rim)
    ob.rotation_euler = (math.radians(-60), 0, math.radians(20))
    bpy.context.scene.collection.objects.link(ob)
    blib.backdrop((58, 54, 52))
    blib.camera(cam_loc, target, lens=lens)


def shot(path, w=420, h=520, cam=None, **kw):
    studio(**(cam or {}))
    lutin.build(sombre=True, **kw)
    blib.render(path, w, h)


if WHAT in ("peaux", "tout"):
    for skin in ("bleu", "bleu_sombre", "vert"):
        shot(OUT / f"peau_{skin}_face.png", job="base", skin=skin)
        shot(OUT / f"peau_{skin}_34.png", job="base", skin=skin, rot_z=math.radians(35))
        shot(OUT / f"peau_{skin}_action.png", job="bucheron", skin=skin, action=True, rot_z=math.radians(30))

if WHAT in ("metiers", "tout"):
    cam = dict(cam_loc=(0, -4.6, 1.35), target=(0, 0, 0.55))
    for job in lutin.OUTFITS:
        if job in ("base", "soldat"):
            continue
        shot(OUT / f"metier_{job}_repos.png", 360, 460, cam, job=job, skin=SKIN, rot_z=math.radians(25))
        shot(OUT / f"metier_{job}_action.png", 360, 460, cam, job=job, skin=SKIN, action=True, rot_z=math.radians(30))

if WHAT in ("ages", "tout"):
    studio(cam_loc=(0, -6.5, 1.4), target=(0, 0, 0.45), lens=55)
    for i, age in enumerate(("baby", "child", "adult", "elder")):
        lutin.build("bucheron" if age == "adult" else "base", age, loc=(-1.2 + i * 0.8, 0, 0),
                    rot_z=math.radians(15), skin=SKIN, sombre=True)
    blib.render(OUT / "ages_ensemble.png", 1500, 640)

if WHAT in ("portrait", "tout"):
    for job, name in (("bucheron", "portrait"), ("soldat", "portrait_soldat")):
        studio(cam_loc=(0, -2.8, 1.0), target=(0, 0, 0.74), lens=80)
        lutin.build(job, rot_z=math.radians(20), skin=SKIN, sombre=True, action=(job == "soldat"))
        blib.render(OUT / f"{name}.png", 400, 400)
