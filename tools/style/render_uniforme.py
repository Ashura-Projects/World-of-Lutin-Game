"""Uniforme de mobilisation : quand la cloche sonne « Mobiliser », les lutins adultes passent dans cette tenue.

Usage : blender -b -P tools/style/render_uniforme.py -- <dossier_sortie>
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import blib  # noqa: E402
import lutin  # noqa: E402

OUT = Path(sys.argv[sys.argv.index("--") + 1])
OUT.mkdir(parents=True, exist_ok=True)
kw = dict(skin="bleu_sombre", sombre=True)


def studio():
    blib.reset_scene()
    blib.lights(sun_dir=(math.radians(52), 0, math.radians(-40)), strength=4.4, world=(80, 86, 104), world_strength=0.9,
                sun_color=(255, 226, 190))
    blib.backdrop((96, 108, 70))


for name, job, rot, act in (("uniforme_repos", "milicien", 20, False), ("uniforme_dos", "milicien", 200, False),
                            ("uniforme_vise", "milicien", -35, True), ("uniforme_lance", "milicien_lance", 30, True)):
    studio()
    lutin.build(job, rot_z=math.radians(rot), action=act, **kw)
    blib.camera((0, -4.2, 1.3), (0, -0.15, 0.55), lens=85)
    blib.render(OUT / f"{name}.png", 420, 520)

# escouade mobilisée
studio()
for i, (job, act) in enumerate((("milicien_lance", True), ("milicien", True), ("milicien", False), ("milicien_lance", False))):
    lutin.build(job, loc=(-1.5 + i, 0.3 * (i % 2), 0), rot_z=math.radians(-15), action=act, **kw)
blib.camera((0.6, -6.5, 2.2), (0, 0, 0.5), lens=50)
blib.render(OUT / "uniforme_escouade.png", 1600, 700)
