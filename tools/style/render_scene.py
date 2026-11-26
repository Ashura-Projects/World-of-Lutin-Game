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
MOODS = [argv[3]] if len(argv) > 3 else ["jour", "crepuscule", "hiver"]
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
            hill = max(0.0, 11.0 - math.hypot(x - 31, y - 24) / 1.05)  # montagne à explorer
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
                    if hill >= 9:
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


def point_light(loc, color, energy, radius=0.1):
    ld = bpy.data.lights.new("feu", "POINT")
    ld.energy = energy
    ld.color = blib.srgb(color)[:3]
    ld.shadow_soft_size = radius
    ob = bpy.data.objects.new("feu", ld)
    ob.location = loc
    bpy.context.scene.collection.objects.link(ob)


def torch(x, y, z):
    """Torche sur poteau : flamme émissive + lumière chaude."""
    blib.cyl((x, y, z + 0.6), 0.04, 1.2, blib.mat("poteau", (60, 44, 30)), verts=6)
    blib.cone((x, y, z + 1.32), 0.07, 0.22, blib.mat("flamme", (255, 150, 50), emit=20.0), verts=6)
    point_light((x, y, z + 1.5), (255, 150, 70), 60, 0.15)


def fog(color, start, depth):
    """Brume par la passe « mist » + compositeur (pas de volumétrie : rendu rapide)."""
    sc = bpy.context.scene
    sc.view_layers[0].use_pass_mist = True
    sc.world.mist_settings.start = start
    sc.world.mist_settings.depth = depth
    sc.world.mist_settings.falloff = "QUADRATIC"
    sc.use_nodes = True
    nt = sc.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    mix = nt.nodes.new("CompositorNodeMixRGB")
    mix.inputs[2].default_value = blib.srgb(color)
    comp = nt.nodes.new("CompositorNodeComposite")
    scale = nt.nodes.new("CompositorNodeMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = 0.5  # brume légère : on voit encore le décor
    nt.links.new(rl.outputs["Mist"], scale.inputs[0])
    nt.links.new(scale.outputs[0], mix.inputs[0])
    nt.links.new(rl.outputs["Image"], mix.inputs[1])
    nt.links.new(mix.outputs[0], comp.inputs["Image"])


def scene(mood):
    season = mood
    winter = mood == "hiver"
    voxel.SOMBRE = True
    blib.reset_scene()
    bpy.context.scene.cycles.samples = 80
    vs = bpy.context.scene.view_settings
    vs.view_transform = "AgX"
    vs.look = "AgX - Medium High Contrast"
    vs.exposure = 0.6
    if mood == "hiver":  # jour d'hiver gris et froid
        blib.lights(sun_dir=(math.radians(55), 0, math.radians(-40)), strength=3.0, world=(150, 162, 186),
                    world_strength=0.9, sun_color=(210, 222, 255))
        fog_c, fog_s = (150, 158, 176), 10
    elif mood == "crepuscule":  # soleil bas orangé, torches allumées
        blib.lights(sun_dir=(math.radians(74), 0, math.radians(-60)), strength=4.0, world=(84, 90, 110),
                    world_strength=0.8, sun_color=(255, 160, 90))
        fog_c, fog_s = (78, 82, 98), 12
    else:  # jour : lumière franche mais voilée, couleurs sobres
        blib.lights(sun_dir=(math.radians(48), 0, math.radians(-40)), strength=4.6, world=(160, 176, 200),
                    world_strength=0.9, sun_color=(255, 236, 206))
        fog_c, fog_s = (170, 180, 196), 16
    grid = terrain(winter)
    ghosts = house(grid, winter)
    voxel.build_mesh(grid, ATLAS / f"atlas_{PAL}.png", ATLAS / "atlas_layout.json")
    voxel.ghost_blocks(ghosts)
    for (x, y, k, s) in [(2, 9, "chene", 1.1), (5, 21, "pin", 1.3), (8, 20, "pin", 1.5), (1, 18, "pin", 1.2),
                         (27, 4, "chene", 1.2), (30, 9, "pin", 1.4), (24, 2, "pin", 1.2), (11, 20, "chene", 1.0),
                         (1, 2, "pin", 1.3), (19, 21, "pin", 1.4), (29, 14, "pin", 1.2), (3, 23, "pin", 1.5)]:
        top = max(z for (gx, gy, z) in grid if gx == x and gy == y) + 1
        voxel.tree(k, x + 0.5, y + 0.5, top, s, winter)
    voxel.tree("chene", 22.5, 19.5, G, 1.0, True)  # arbre mort
    for (x, y) in [(10, 14), (4, 11)]:
        voxel.bush(x + 0.5, y + 0.5, G, winter)
    if not winter:
        for x in range(3, 9):
            for y in range(13, 18):
                if (x + y) % 5:
                    voxel.wheat(x, y, G)
        for x in (6, 9, 20, 25):
            voxel.reed(x, int(river_y(x) + 2.0), G)
    voxel.log_pile(9, 10, G)
    # rochers
    rock = blib.mat("roche", (70, 70, 74), 0.9)
    for (x, y, r) in [(20.5, 15.5, 0.45), (26, 13, 0.6), (1.5, 12.5, 0.4)]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r, location=(x, y, G + r * 0.5))
        bpy.context.object.data.materials.append(rock)
    # petit cimetière (les anciens meurent de vieillesse)
    grave = blib.mat("tombe", (96, 96, 100), 0.9)
    for i in range(3):
        gx, gy = 21.5 + i * 1.2, 17.5
        blib.box((gx, gy, G + 0.3), (0.12, 0.1, 0.6), grave)
        blib.box((gx, gy, G + 0.45), (0.4, 0.1, 0.1), grave)
    # feu de camp
    blib.cyl((12.5, 14.0 - 3.5, G + 0.05), 0.35, 0.1, blib.mat("pierres_feu", (60, 58, 56)), verts=8)
    blib.cone((12.5, 10.5, G + 0.3), 0.18, 0.45, blib.mat("flamme", (255, 150, 50), emit=20.0), verts=6)
    point_light((12.5, 10.5, G + 0.8), (255, 140, 60), 120, 0.3)
    # torches et fenêtres éclairées
    torch(14.4, 11.3, G)
    torch(20.6, 8.4, G)
    point_light((15.5, 14.0, G + 1.5), (255, 170, 90), 80, 0.3)  # intérieur de la maison
    # lutins (peau bleu sombre, outils seulement en action)
    s = 0.82
    kw = dict(scale=s, skin="bleu_sombre", sombre=True)
    lutin.build("bucheron", loc=(3.4, 8.3, G), rot_z=math.radians(-60), action=True, **kw)
    lutin.build("porteur", loc=(12.2, 8.0, G), rot_z=math.radians(40), action=True, **kw)
    lutin.build("batisseur", loc=(22.5, 8.0, G), rot_z=math.radians(20), action=True, **kw)
    lutin.build("batisseur", loc=(25.5, 8.2, G), rot_z=math.radians(-30), action=True, **kw)
    lutin.build("fermier", loc=(6.0, 12.4, G), rot_z=math.radians(10), action=not winter, **kw)
    lutin.build("pecheur", loc=(16.5, river_y(16) + 2.2, G), rot_z=math.radians(150), action=True, **kw)
    lutin.build("cueilleur", loc=(11.2, 11.6, G), rot_z=math.radians(-120), **kw)
    lutin.build("base", "child", loc=(13.6, 11.0, G), rot_z=math.radians(150), **kw)
    lutin.build("chasseur", loc=(18.5, 18.0, G), rot_z=math.radians(-150), action=True, **kw)
    fog(fog_c, fog_s, 45)
    blib.camera((1.0, -9.0, 19.0), (16.0, 13.5, 4.0), lens=32)
    blib.render(OUT / f"scene_{PAL}_{season}.png", 1600, 900)
    if mood == "jour":
        fog(fog_c, 8, 35)
        blib.camera((7.0, -0.5, 8.5), (12.5, 9.5, 3.4), lens=38)
        blib.render(OUT / f"scene_{PAL}_{season}_zoom.png", 1600, 900)


for mood in MOODS:
    scene(mood)
