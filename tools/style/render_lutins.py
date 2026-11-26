"""Rendus Blender des lutins : variantes, métiers, âges, portrait.

Usage : blender -b -P tools/style/render_lutins.py -- <dossier_sortie> [quoi]
quoi = variantes | metiers | ages | portrait | tout (défaut)
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import blib  # noqa: E402
import lutin  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(argv[0] if argv else "build/style/renders")
WHAT = argv[1] if len(argv) > 1 else "tout"
OUT.mkdir(parents=True, exist_ok=True)

VIEWS = {"face": 0.0, "trois_quarts": math.radians(35), "dos": math.pi}


def studio(cam_loc=(0, -4.2, 1.2), target=(0, 0, 0.52), lens=95):
    blib.reset_scene()
    blib.lights(sun_dir=(math.radians(50), 0, math.radians(-30)), strength=3.2, world=(214, 222, 238), world_strength=0.8)
    blib.backdrop((236, 228, 212))
    blib.camera(cam_loc, target, lens=lens)


def shot(variant, job, age, rot, path, w=420, h=520, **cam):
    studio(**cam)
    lutin.build(variant, job, age, rot_z=rot)
    blib.render(path, w, h)


if WHAT in ("variantes", "tout"):
    for v in "ABC":
        for vname, rot in VIEWS.items():
            shot(v, "base", "adult", rot, OUT / f"variante_{v}_{vname}.png")
        shot(v, "bucheron", "adult", VIEWS["trois_quarts"], OUT / f"variante_{v}_outil.png")

if WHAT in ("metiers", "tout"):
    for job in lutin.OUTFITS:
        shot("A", job, "adult", math.radians(25), OUT / f"metier_{job}.png", 360, 460,
             cam_loc=(0, -4.4, 1.3), target=(0, 0, 0.55))

if WHAT in ("ages", "tout"):
    for age in ("baby", "child", "adult", "elder"):
        studio(cam_loc=(0, -4.2, 1.2), target=(0, 0, 0.5))
        lutin.build("A", "bucheron" if age == "adult" else "base", age, rot_z=math.radians(20))
        blib.render(OUT / f"age_{age}.png", 400, 520)
    # Les quatre âges côte à côte pour juger les tailles relatives
    studio(cam_loc=(0, -6.5, 1.4), target=(0, 0, 0.45), lens=55)
    for i, age in enumerate(("baby", "child", "adult", "elder")):
        lutin.build("A", "bucheron" if age == "adult" else "base", age, loc=(-1.2 + i * 0.8, 0, 0),
                    rot_z=math.radians(15))
    blib.render(OUT / "ages_ensemble.png", 1500, 640)

if WHAT in ("portrait", "tout"):
    studio(cam_loc=(0, -2.8, 1.0), target=(0, 0, 0.74), lens=80)
    lutin.build("A", "bucheron", "adult", rot_z=math.radians(20))
    blib.render(OUT / "portrait.png", 400, 400)
