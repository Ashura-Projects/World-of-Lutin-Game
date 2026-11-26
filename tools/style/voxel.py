"""Maillage de blocs pour les rendus de style : faces cachées supprimées, UV dans l'atlas.

C'est une maquette de rendu (pas le code du jeu) : même principe que le futur mailleur par chunk.
"""

import json
import math
from pathlib import Path

import bpy

from blib import cone, cyl, mat, sphere, srgb

# bloc -> (tuile dessus, tuile côté, tuile dessous)
FACES = {
    "bedrock": ("bedrock",) * 3,
    "grass": ("grass_top", "grass_side", "dirt"),
    "dirt": ("dirt",) * 3,
    "fertile_soil": ("fertile_soil", "dirt", "dirt"),
    "sand": ("sand",) * 3,
    "clay": ("clay",) * 3,
    "stone": ("stone",) * 3,
    "iron_ore": ("iron_ore",) * 3,
    "coal_ore": ("coal_ore",) * 3,
    "snow": ("snow", "snow_side", "dirt"),
    "snow_block": ("snow",) * 3,
    "water": ("water",) * 3,
    "ice": ("ice",) * 3,
    "wood_block": ("wood_top", "wood_side", "wood_top"),
    "plank_block": ("plank",) * 3,
    "stone_block": ("cobble",) * 3,
    "cut_stone_block": ("cut_stone",) * 3,
    "brick_block": ("brick",) * 3,
    "thatch_block": ("thatch_top", "thatch_side", "thatch_top"),
    "thatch_snow": ("snow", "thatch_side", "thatch_top"),
    "dirt_block": ("dirt_packed",) * 3,
    "gravel": ("gravel",) * 3,
    "deep_stone": ("deep_stone",) * 3,
}
LIQUID = {"water", "ice"}
SOMBRE = False  # ambiance dark fantasy : végétation désaturée et assombrie


def g_(c):
    if not SOMBRE:
        return c
    g = sum(c) / 3
    return tuple(int((v * 0.55 + g * 0.45) * 0.62) for v in c)

DIRS = [  # normale, 4 coins (sens anti-horaire vu de l'extérieur), type de face
    ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)], 0),
    ((0, 0, -1), [(0, 1, 0), (1, 1, 0), (1, 0, 0), (0, 0, 0)], 2),
    ((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)], 1),
    ((-1, 0, 0), [(0, 1, 0), (0, 0, 0), (0, 0, 1), (0, 1, 1)], 1),
    ((0, 1, 0), [(1, 1, 0), (0, 1, 0), (0, 1, 1), (1, 1, 1)], 1),
    ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)], 1),
]


def atlas_material(atlas_png, name, rough=0.85, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(atlas_png))
    tex.interpolation = "Closest"  # pixel art net
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
    return m


def build_mesh(grid, atlas_png, layout_json, name="terrain", water_drop=0.12):
    """grid : dict (x, y, z) -> nom de bloc. Renvoie (objet solide, objet liquide)."""
    lay = json.loads(Path(layout_json).read_text())
    cols, rows, tiles = lay["cols"], lay["rows"], lay["tiles"]
    eps = 0.5 / (cols * lay["tile"])

    def uv_rect(tile):
        c, r = tiles[tile]
        u0, u1 = c / cols + eps, (c + 1) / cols - eps
        v1 = 1 - r / rows - eps
        v0 = 1 - (r + 1) / rows + eps
        return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]

    out = []
    for liquid in (False, True):
        verts, faces, uvs = [], [], []
        for (x, y, z), b in grid.items():
            if (b in LIQUID) != liquid:
                continue
            for n, corners, kind in DIRS:
                nb = grid.get((x + n[0], y + n[1], z + n[2]))
                # face cachée si le voisin la recouvre : un solide cache tout, un liquide ne cache que du liquide
                if nb is not None and (nb not in LIQUID or liquid):
                    continue
                top = 1.0 - water_drop if (liquid and grid.get((x, y, z + 1)) is None) else 1.0
                base = len(verts)
                for cx, cy, cz in corners:
                    verts.append((x + cx, y + cy, z + (top if cz else 0.0)))
                faces.append((base, base + 1, base + 2, base + 3))
                uvs.extend(uv_rect(FACES[b][kind]))
        if not faces:
            out.append(None)
            continue
        me = bpy.data.meshes.new(name + ("_eau" if liquid else ""))
        me.from_pydata(verts, [], faces)
        uvl = me.uv_layers.new(name="UVMap")
        for i in range(len(me.loops)):
            uvl.data[i].uv = uvs[i]
        ob = bpy.data.objects.new(me.name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.data.materials.append(atlas_material(atlas_png, me.name + "_mat", 0.08 if liquid else 0.9))
        out.append(ob)
    return out


def ghost_blocks(cells):
    """Blocs-plans : fantômes bleus translucides (ordre de construction)."""
    m = bpy.data.materials.new("plan")
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb((90, 170, 255))
    b.inputs["Alpha"].default_value = 0.45
    b.inputs["Emission Color"].default_value = srgb((90, 170, 255))
    b.inputs["Emission Strength"].default_value = 0.6
    for (x, y, z) in cells:
        bpy.ops.mesh.primitive_cube_add(size=0.96, location=(x + 0.5, y + 0.5, z + 0.5))
        bpy.context.object.data.materials.append(m)
        w = bpy.context.object.modifiers.new("fil", "WIREFRAME")
        w.thickness = 0.04
        w.use_replace = False


# ----------------------------------------------------------------------------- végétation

def tree(kind, x, y, z, s=1.0, winter=False):
    trunk_c = (236, 232, 222) if kind == "bouleau" else (110, 74, 44)
    trunk = mat("tronc_" + kind, g_(trunk_c), 0.9)
    leaf_c = {"chene": (78, 150, 58), "pin": (46, 112, 70), "bouleau": (140, 186, 70)}[kind]
    if winter and kind != "pin":
        leaf_c = None
    snow = mat("neige_feuille", g_((240, 244, 250)), 0.9)
    if kind == "pin":
        cyl((x, y, z + 0.6 * s), 0.12 * s, 1.2 * s, trunk)
        for i, (r, h) in enumerate(((1.0, 1.2), (0.8, 1.0), (0.55, 0.8))):
            cone((x, y, z + (1.2 + i * 0.7) * s), r * s, h * s, mat("pin", g_(leaf_c), 0.8), verts=7)
            if winter:
                cone((x, y, z + (1.32 + i * 0.7) * s), r * 0.8 * s, h * 0.75 * s, snow, verts=7)
        return
    h = 1.6 if kind == "chene" else 2.0
    cyl((x, y, z + h / 2 * s), 0.14 * s if kind == "chene" else 0.09 * s, h * s, trunk, verts=6)
    if leaf_c is None:  # hiver : branches nues + un peu de neige
        for a in range(4):
            ang = a * math.pi / 2 + 0.4
            cyl((x + 0.3 * s * math.cos(ang), y + 0.3 * s * math.sin(ang), z + (h + 0.25) * s), 0.04 * s, 0.8 * s, trunk,
                verts=5, rot=(math.sin(ang) * -0.8, math.cos(ang) * 0.8, 0))
        return
    leaves = mat("feuilles_" + kind, g_(leaf_c), 0.8)
    blobs = [(0, 0, h + 0.4, 0.9), (0.45, 0.2, h + 0.1, 0.6), (-0.4, -0.25, h + 0.15, 0.62), (0.1, -0.2, h + 0.85, 0.6)]
    if kind == "bouleau":
        blobs = [(0, 0, h + 0.3, 0.6), (0.1, 0.1, h + 0.8, 0.45), (-0.1, 0, h - 0.1, 0.5)]
    for bx, by, bz, br in blobs:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=br * s, location=(x + bx * s, y + by * s, z + bz * s))
        o = bpy.context.object
        o.data.materials.append(leaves)


def bush(x, y, z, winter=False):
    sphere((x, y, z + 0.25), (0.35, 0.35, 0.28), mat("buisson", g_((66, 130, 54)) if not winter else (110, 96, 80), 0.9), 8, 5)
    if not winter:
        for i in range(5):
            a = i * 1.3
            sphere((x + 0.28 * math.cos(a), y + 0.28 * math.sin(a), z + 0.3 + 0.05 * (i % 2)), 0.05, mat("baie", g_((200, 30, 60)), 0.3), 6, 4)


def wheat(x, y, z):
    for i in range(3):
        for j in range(3):
            cone((x + 0.2 + i * 0.3, y + 0.2 + j * 0.3, z + 0.18), 0.05, 0.36, mat("ble", g_((220, 190, 80)), 0.8), verts=5)


def reed(x, y, z):
    for i in range(4):
        cyl((x + 0.2 * (i % 2) + 0.3, y + 0.2 * (i // 2) + 0.3, z + 0.35), 0.02, 0.7, mat("roseau", g_((110, 140, 60))), verts=4)
        cyl((x + 0.2 * (i % 2) + 0.3, y + 0.2 * (i // 2) + 0.3, z + 0.75), 0.035, 0.15, mat("massette", g_((110, 70, 40))), verts=5)


def log_pile(x, y, z):
    for i in range(3):
        cyl((x + 0.5, y + 0.2 + i * 0.22, z + 0.12), 0.11, 0.9, mat("buche", g_((130, 86, 48))), verts=7, rot=(0, math.pi / 2, 0))
    for i in range(2):
        cyl((x + 0.5, y + 0.31 + i * 0.22, z + 0.31), 0.11, 0.9, mat("buche", g_((130, 86, 48))), verts=7, rot=(0, math.pi / 2, 0))
