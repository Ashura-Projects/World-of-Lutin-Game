"""Rendu de chaque bloc de data/blocks.json (vue isométrique) pour les palettes A et B.

Usage : blender -b -P tools/style/render_blocs.py -- <dossier_atlas> <dossier_sortie>
"""

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import blib  # noqa: E402
import voxel  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
ATLAS, OUT = Path(argv[0]), Path(argv[1])
OUT.mkdir(parents=True, exist_ok=True)
ROOT = Path(__file__).resolve().parents[2]
blocks = [b for b in json.loads((ROOT / "data/blocks.json").read_text())["blocks"] if b["id"] != "air"]

for pal in "BC":
    for b in blocks:
        blib.reset_scene()
        blib.lights(sun_dir=(math.radians(45), 0, math.radians(-35)), strength=3.0, world=(225, 230, 240), world_strength=1.0)
        blib.backdrop((240, 236, 226))
        grid = {(0, 0, 0): b["id"]}
        voxel.build_mesh(grid, ATLAS / f"atlas_{pal}.png", ATLAS / "atlas_layout.json", water_drop=0.0)
        blib.camera((4.2, -4.2, 4.0), (0.5, 0.5, 0.45), ortho=2.3)
        blib.render(OUT / f"bloc_{pal}_{b['id']}.png", 220, 220, samples=24)
