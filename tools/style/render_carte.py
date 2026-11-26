"""Aperçu de la grande carte vierge (256×256×64) : plaine, rivière, forêt, collines, montagne,
couches visibles sur les bords (terre, pierre, minerais, roche profonde, socle), une mine et un puits.

Maquette de rendu seulement : le vrai générateur sera écrit en GDScript au J1 (même principe, data/world.json).
Usage : blender -b -P tools/style/render_carte.py -- <dossier_atlas> <dossier_sortie>
"""

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402

import blib  # noqa: E402
import voxel  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
ATLAS, OUT = Path(argv[0]), Path(argv[1])
OUT.mkdir(parents=True, exist_ok=True)
ROOT = Path(__file__).resolve().parents[2]
WORLD = json.loads((ROOT / "data/world.json").read_text())
N = 256
WATER = WORLD["sea_level"] - 1
rng = np.random.default_rng(7)


def value_noise(cell):
    g = rng.random((N // cell + 2, N // cell + 2))
    x = np.arange(N) / cell
    i, f = x.astype(int), x - x.astype(int)
    f = f * f * (3 - 2 * f)
    a = g[i][:, i] * (1 - f)[None, :] + g[i][:, i + 1] * f[None, :]
    b = g[i + 1][:, i] * (1 - f)[None, :] + g[i + 1][:, i + 1] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]


# ---------------------------------------------------------------- hauteurs et biomes
n1, n2, n3 = value_noise(48), value_noise(20), value_noise(8)
yy, xx = np.mgrid[0:N, 0:N]
h = 25 + 2.5 * n2 + 1.0 * n3
hills = np.clip((value_noise(64) - 0.55) * 3.0, 0, 1)
h += hills * (8 + 6 * n2)
mount = np.clip(1 - np.hypot(xx - 225, yy - 225) / 75, 0, 1) ** 1.3
h += mount * (34 + 6 * n3)
river_y = 110 + 38 * np.sin(xx / 42.0) + 6 * np.sin(xx / 11.0)
dist_r = np.abs(yy - river_y)
lake = np.hypot(xx - 40, yy - 60) < 16
in_water = ((dist_r < 3.0) & (mount < 0.3)) | lake
h = np.where(in_water, WATER - 2, h)
bank = (~in_water) & ((dist_r < 5.5) | (np.hypot(xx - 40, yy - 60) < 19)) & (mount < 0.3)
h = np.where(bank, np.minimum(h, WATER + 1), h)
forest = (n1 > 0.5) & (~in_water) & (~bank) & (mount < 0.25)
H = np.clip(np.round(h), 2, 63).astype(int)

# exemples creusés : une mine à ciel ouvert dans les collines, un puits dans la plaine
mine_c = np.unravel_index(np.argmax(hills * (mount < 0.1) * (xx > 20) * (yy > 20) * (xx < 236) * (yy < 236)), H.shape)
my, mx = mine_c
for k in range(4):  # gradins de 4×4 en 4×4
    r = 7 - 2 * k
    H[my - r:my + r, mx - r:mx + r] = np.minimum(H[my - r:my + r, mx - r:mx + r], H[my, mx] - 3 * (k + 1))
well = (150, 60)
H[well[1], well[0]] = WORLD["water_table"]


def block_at(x, y, z, top):
    """Couches façon Minecraft + poches de minerais (déterministe)."""
    if z == 0:
        return "bedrock"
    depth = top - 1 - z
    if depth == 0:
        if in_water[y, x]:
            return "sand"
        if top > 54:
            return "snow"
        if bank[y, x]:
            return "sand"
        return "stone" if mount[y, x] > 0.45 else "grass"
    if depth <= 3 and mount[y, x] < 0.45:
        return "dirt" if not bank[y, x] else "sand"
    hsh = ((x * 73856093) ^ (y * 19349663) ^ (z * 83492791)) & 0xFFFF
    if z < 12:
        return "iron_ore" if hsh < 900 else "deep_stone"
    if hsh < 1800 and z < 40:
        return "coal_ore"
    if hsh < 2600 and z < 30:
        return "iron_ore"
    if hsh < 3600:
        return "gravel"
    return "stone"


def mesh(lay):
    cols, rows, tiles = lay["cols"], lay["rows"], lay["tiles"]
    eps = 0.5 / (cols * lay["tile"])

    def uv(tile):
        c, r = tiles[tile]
        u0, u1 = c / cols + eps, (c + 1) / cols - eps
        v0, v1 = 1 - (r + 1) / rows + eps, 1 - r / rows - eps
        return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]

    verts, faces, uvs = [], [], []

    def quad(pts, tile):
        b = len(verts)
        verts.extend(pts)
        faces.append((b, b + 1, b + 2, b + 3))
        uvs.extend(uv(tile))

    faces_of = voxel.FACES
    for y in range(N):
        for x in range(N):
            t = H[y, x]
            quad([(x, y, t), (x + 1, y, t), (x + 1, y + 1, t), (x, y + 1, t)], faces_of[block_at(x, y, t - 1, t)][0])
            for dx, dy, side in ((1, 0, "e"), (-1, 0, "w"), (0, 1, "n"), (0, -1, "s")):
                nx, ny = x + dx, y + dy
                nt = H[ny, nx] if 0 <= nx < N and 0 <= ny < N else 0
                for z in range(nt, t):
                    tile = faces_of[block_at(x, y, z, t)][1]
                    if side == "e":
                        p = [(x + 1, y, z), (x + 1, y + 1, z), (x + 1, y + 1, z + 1), (x + 1, y, z + 1)]
                    elif side == "w":
                        p = [(x, y + 1, z), (x, y, z), (x, y, z + 1), (x, y + 1, z + 1)]
                    elif side == "n":
                        p = [(x + 1, y + 1, z), (x, y + 1, z), (x, y + 1, z + 1), (x + 1, y + 1, z + 1)]
                    else:
                        p = [(x, y, z), (x + 1, y, z), (x + 1, y, z + 1), (x, y, z + 1)]
                    quad(p, tile)
    me = bpy.data.meshes.new("carte")
    me.from_pydata(verts, [], faces)
    uvl = me.uv_layers.new(name="UVMap")
    flat = [c for q in uvs for c in q]
    uvl.data.foreach_set("uv", flat)
    ob = bpy.data.objects.new("carte", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(voxel.atlas_material(ATLAS / "atlas_C.png", "carte_mat", 0.9))
    # eau : une nappe plane sur la rivière, le lac et au fond du puits
    wv, wf = [], []
    for y in range(N):
        for x in range(N):
            if in_water[y, x] or (x, y) == well:
                z = WATER + 0.85 if in_water[y, x] else WORLD["water_table"] + 0.6
                b = len(wv)
                wv += [(x, y, z), (x + 1, y, z), (x + 1, y + 1, z), (x, y + 1, z)]
                wf.append((b, b + 1, b + 2, b + 3))
    wm = bpy.data.meshes.new("eau")
    wm.from_pydata(wv, [], wf)
    wo = bpy.data.objects.new("eau", wm)
    bpy.context.scene.collection.objects.link(wo)
    wo.data.materials.append(blib.mat("eau_c", (44, 82, 92), 0.05))


def trees():
    """Arbres en copies liées (le jeu utilisera des MultiMesh)."""
    voxel.SOMBRE = True
    protos = {}
    for k in ("pin", "chene"):
        before = set(bpy.data.objects)
        voxel.tree(k, 0, 0, -200, 1.3)
        protos[k] = [o for o in bpy.data.objects if o not in before]
    pts = np.argwhere(forest & (rng.random((N, N)) < 0.09))
    pts = np.vstack([pts, np.argwhere((~forest) & (~in_water) & (~bank) & (mount < 0.3) & (rng.random((N, N)) < 0.004))])
    for (y, x) in pts:
        k = "pin" if (hills[y, x] > 0.2 or (x + y) % 3) else "chene"
        for o in protos[k]:
            c = o.copy()
            c.location = (o.location.x + x + 0.5, o.location.y + y + 0.5, o.location.z + 200 + H[y, x])
            bpy.context.scene.collection.objects.link(c)
    return len(pts)


def cart(x, y):
    """Chariot de départ : la seule chose posée sur la carte vierge."""
    z = H[y, x]
    blib.box((x + 0.5, y + 0.5, z + 0.6), (1.6, 0.9, 0.5), blib.mat("chariot", (96, 70, 46)), bevel=0.03)
    for dx in (-0.6, 0.6):
        for dy in (-0.5, 0.5):
            blib.cyl((x + 0.5 + dx, y + 0.5 + dy, z + 0.3), 0.3, 0.08, blib.mat("roue", (70, 50, 34)), verts=10, rot=(math.pi / 2, 0, 0))
    blib.sphere((x + 0.5, y + 0.5, z + 0.95), (0.8, 0.5, 0.35), blib.mat("bache", (170, 160, 130)), 10, 6)


blib.reset_scene()
sc = bpy.context.scene
sc.cycles.samples = 64
sc.view_settings.view_transform = "AgX"
sc.view_settings.look = "AgX - Medium High Contrast"
sc.view_settings.exposure = 0.5
blib.lights(sun_dir=(math.radians(50), 0, math.radians(-35)), strength=4.4, world=(160, 176, 200), world_strength=0.9,
            sun_color=(255, 236, 206))
lay = json.loads((ATLAS / "atlas_layout.json").read_text())
mesh(lay)
nt = trees()
cart(120, 165)
print("arbres:", nt, "mine:", mx, my)
blib.camera((-120, -150, 230), (128, 118, 20), lens=40)
blib.render(OUT / "carte_ensemble.png", 1600, 900)
# zoom sur un coin : couches visibles en coupe + mine
blib.camera((mx - 40, my - 50, H[my, mx] + 38), (mx, my, H[my, mx] - 6), lens=40)
blib.render(OUT / "carte_mine.png", 1600, 900)
# coin de carte en coupe (bord sud-ouest)
blib.camera((-22, -26, 48), (14, 14, 18), lens=35)
blib.render(OUT / "carte_coupe.png", 1600, 900)
