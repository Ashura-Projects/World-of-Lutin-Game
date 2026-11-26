"""Scène de démonstration du village (caméra du jeu), de jour et en hiver.

Usage : blender -b -P tools/style/render_scene.py -- <dossier_atlas> <dossier_sortie> [palette] [saison]
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402

import blib  # noqa: E402
import lutin  # noqa: E402
import voxel  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
ATLAS, OUT = Path(argv[0]), Path(argv[1])
PAL = argv[2] if len(argv) > 2 else "A"
SEASONS = [argv[3]] if len(argv) > 3 else ["ete", "hiver"]
OUT.mkdir(parents=True, exist_ok=True)

W, D = 32, 24
G = 3  # nombre de blocs du sol : la surface est à z = 3


def river_y(x):
    return 5.5 + 1.6 * math.sin(x / 4.5)


def terrain(winter):
    grid = {}
    for x in range(W):
        for y in range(D):
            # colline en fond à droite
            hill = max(0.0, 7.0 - math.hypot(x - 30, y - 23) / 1.3)
            top = G + int(hill)
            ry = river_y(x)
            in_river = abs(y + 0.5 - ry) < 1.6
            bank = abs(y + 0.5 - ry) < 2.6 and not in_river
            for z in range(top):
                if z == 0:
                    b = "bedrock"
                elif z < top - 2 and hill > 0:
                    b = "stone" if (x * 7 + y * 3 + z) % 11 else "iron_ore"
                elif z < top - 1:
                    b = "dirt"
                else:
                    b = "sand" if bank else "grass"
                    if hill >= 6:
                        b = "snow" if not winter else "snow_block"
                    elif hill >= 2:
                        b = "stone"
                    if winter and b in ("grass", "sand"):
                        b = "snow"
                grid[(x, y, z)] = b
            if in_river:
                grid[(x, y, G - 1)] = "ice" if winter else "water"
                grid[(x, y, G - 2)] = "water"
    # champ de terre fertile
    for x in range(3, 9):
        for y in range(13, 18):
            grid[(x, y, G - 1)] = "snow" if winter else "fertile_soil"
    return grid


def house(grid, winter):
    x0, y0, x1, y1 = 13, 12, 18, 16
    for z in range(G, G + 3):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                edge_x, edge_y = x in (x0, x1), y in (y0, y1)
                if not (edge_x or edge_y):
                    continue
                if x == 15 and y == y0 and z < G + 2:
                    continue  # porte
                if z == G + 1 and ((x == 17 and y == y0) or (y == 14 and x == x0)):
                    continue  # fenêtres
                grid[(x, y, z)] = "wood_block" if (edge_x and edge_y) else ("cut_stone_block" if z == G else "plank_block")
    roof = "thatch_snow" if winter else "thatch_block"
    for i in range(3):
        for x in range(x0 - 1 + i, x1 + 2 - i):
            for y in range(y0 - 1 + i, y1 + 2 - i):
                if i == 2 or x in (x0 - 1 + i, x1 + 1 - i) or y in (y0 - 1 + i, y1 + 1 - i):
                    grid[(x, y, G + 3 + i)] = roof
    for z in range(G, G + 7):
        grid[(x1 - 1, y1, z)] = "brick_block"
    # mur de pierre en construction + blocs-plans
    for x in range(21, 27):
        grid[(x, 9, G)] = "stone_block"
        if x < 24:
            grid[(x, 9, G + 1)] = "stone_block"
    # tas de terre tassée et quelques blocs de réserve
    grid[(20, 13, G)] = "dirt_block"
    grid[(11, 9, G)] = "wood_block"
    grid[(11, 10, G)] = "wood_block"
    grid[(12, 9, G)] = "plank_block"
    return [(x, 9, G + 1) for x in range(24, 27)] + [(x, 9, G + 2) for x in range(21, 27)]


def scene(season):
    winter = season == "hiver"
    blib.reset_scene()
    bpy.context.scene.cycles.samples = 64
    if winter:
        blib.lights(sun_dir=(math.radians(62), 0, math.radians(-40)), strength=2.6, world=(186, 206, 236),
                    world_strength=1.0, sun_color=(236, 242, 255))
    else:
        blib.lights(sun_dir=(math.radians(50), 0, math.radians(-40)), strength=3.6, world=(170, 205, 245),
                    world_strength=0.9, sun_color=(255, 240, 214))
    grid = terrain(winter)
    ghosts = house(grid, winter)
    voxel.build_mesh(grid, ATLAS / f"atlas_{PAL}.png", ATLAS / "atlas_layout.json")
    voxel.ghost_blocks(ghosts)
    # végétation
    for (x, y, k, s) in [(2, 9, "chene", 1.1), (5, 21, "pin", 1.0), (8, 20, "pin", 1.2), (1, 18, "bouleau", 1.0),
                         (27, 4, "chene", 1.2), (30, 9, "pin", 1.1), (24, 2, "bouleau", 1.0), (11, 20, "chene", 1.0),
                         (1, 2, "pin", 1.0), (19, 21, "pin", 1.1), (29, 14, "pin", 1.0)]:
        top = max(z for (gx, gy, z) in grid if gx == x and gy == y) + 1
        voxel.tree(k, x + 0.5, y + 0.5, top, s, winter)
    for (x, y) in [(10, 14), (21, 17), (4, 11)]:
        voxel.bush(x + 0.5, y + 0.5, G, winter)
    if not winter:
        for x in range(3, 9):
            for y in range(13, 18):
                if (x + y) % 5:
                    voxel.wheat(x, y, G)
        for x in (6, 9, 20, 25):
            y = int(river_y(x) + 2.0)
            voxel.reed(x, y, G)
    voxel.log_pile(9, 10, G)
    # lanterne à la porte (lumière chaude)
    blib.sphere((15.5, 11.7, G + 2.2), 0.09, blib.mat("lanterne", (255, 200, 110), emit=8.0), 8, 6)
    # lutins au travail (taille ≈ 1 bloc)
    s = 0.82
    lutin.build("A", "bucheron", "adult", loc=(3.4, 8.3, G), rot_z=math.radians(-60), scale=s)
    lutin.build("A", "porteur", "adult", loc=(12.2, 8.0, G), rot_z=math.radians(40), scale=s)
    lutin.build("A", "batisseur", "adult", loc=(22.5, 8.0, G), rot_z=math.radians(20), scale=s)
    lutin.build("A", "batisseur", "adult", loc=(25.5, 8.2, G), rot_z=math.radians(-30), scale=s)
    lutin.build("A", "fermier", "adult", loc=(6.0, 12.4, G), rot_z=math.radians(10), scale=s)
    lutin.build("A", "pecheur", "adult", loc=(16.5, river_y(16) + 2.2, G), rot_z=math.radians(150), scale=s)
    lutin.build("A", "cueilleur", "adult", loc=(10.5, 13.2, G), rot_z=math.radians(-20), scale=s)
    lutin.build("A", "base", "child", loc=(14.8, 10.6, G), rot_z=math.radians(-10), scale=s)
    # caméra du jeu : vue plongeante libre (~45°)
    blib.camera((1.0, -9.0, 19.0), (15.0, 12.0, 2.5), lens=34)
    blib.render(OUT / f"scene_{PAL}_{season}.png", 1600, 900)
    # zoom « près des lutins »
    blib.camera((7.0, -0.5, 8.5), (12.5, 9.5, 3.4), lens=38)
    blib.render(OUT / f"scene_{PAL}_{season}_zoom.png", 1600, 900)


for season in SEASONS:
    scene(season)
