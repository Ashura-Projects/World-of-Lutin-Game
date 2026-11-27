"""Génère l'atlas de textures des blocs (pixel art 32×32) en deux palettes.

Usage : python3 tools/style/atlas.py <dossier_sortie>
Produit atlas_A.png (chaleureuse) et atlas_B.png (plus réaliste), plus atlas_layout.json
(nom de tuile -> [colonne, ligne]) lu par les scripts Blender.
"""

import json
import random
import sys
from pathlib import Path

from PIL import Image

TILE = 32
COLS = 8

# Ordre des tuiles dans l'atlas. Certains blocs ont une face dessus et une face côté.
TILES = [
    "bedrock", "grass_top", "grass_side", "dirt", "fertile_soil", "sand", "clay", "stone",
    "iron_ore", "coal_ore", "snow", "snow_side", "water", "wood_top", "wood_side", "plank",
    "cobble", "cut_stone", "brick", "thatch_top", "thatch_side", "dirt_packed", "ice", "leaves",
    "gravel", "deep_stone", "beam", "road_stone", "field_wet", "gold_ore", "crenel", "rampart",
    "rampart_plain", "flue_top", "pillar", "straw",
]

PALETTES = {
    "A": {  # chaleureuse : couleurs saturées, chaudes, conte
        "grass": (112, 186, 62), "dirt": (150, 96, 56), "fertile": (96, 60, 38),
        "sand": (240, 212, 140), "clay": (196, 120, 90), "stone": (150, 146, 150),
        "bedrock": (60, 56, 66), "iron": (214, 140, 92), "coal": (34, 32, 38),
        "snow": (244, 248, 255), "water": (64, 156, 220), "wood": (150, 98, 52),
        "wood_core": (226, 186, 120), "plank": (204, 150, 84), "cobble": (138, 136, 142),
        "cut": (196, 190, 178), "brick": (190, 84, 60), "mortar": (222, 206, 182),
        "thatch": (226, 186, 88), "packed": (130, 86, 54), "ice": (176, 222, 246),
        "leaves": (80, 160, 60),
    },
    "B": {  # plus réaliste : couleurs désaturées, terreuses
        "grass": (92, 128, 64), "dirt": (112, 86, 64), "fertile": (70, 54, 42),
        "sand": (206, 190, 150), "clay": (156, 112, 94), "stone": (124, 124, 122),
        "bedrock": (52, 52, 54), "iron": (170, 120, 96), "coal": (40, 40, 42),
        "snow": (230, 234, 238), "water": (58, 104, 130), "wood": (104, 80, 58),
        "wood_core": (180, 152, 112), "plank": (156, 122, 84), "cobble": (112, 110, 108),
        "cut": (168, 164, 156), "brick": (148, 82, 66), "mortar": (186, 178, 164),
        "thatch": (182, 156, 96), "packed": (104, 80, 60), "ice": (164, 196, 212),
        "leaves": (70, 110, 56),
    },
    "C": {  # sombre « dark fantasy » : tons froids et sales, contraste fort
        "grass": (58, 72, 40), "dirt": (66, 50, 38), "fertile": (44, 34, 28),
        "sand": (128, 116, 92), "clay": (104, 74, 62), "stone": (86, 86, 88),
        "bedrock": (30, 30, 34), "iron": (138, 84, 56), "coal": (22, 22, 24),
        "snow": (196, 202, 210), "water": (48, 84, 92), "wood": (70, 52, 38),
        "wood_core": (132, 108, 78), "plank": (102, 78, 54), "cobble": (82, 80, 80),
        "cut": (118, 114, 108), "brick": (100, 52, 42), "mortar": (110, 104, 96),
        "thatch": (122, 102, 62), "packed": (72, 56, 42), "ice": (126, 150, 164),
        "leaves": (44, 62, 38),
    },
}


def grime(img, rng):
    """Palette sombre : salissures et bords assombris (aspect usé, réaliste)."""
    for y in range(TILE):
        for x in range(TILE):
            e = min(x, y, TILE - 1 - x, TILE - 1 - y)
            f = (0.9 if e == 0 else 1.0) * rng.uniform(0.9, 1.05)
            img.putpixel((x, y), shade(img.getpixel((x, y)), f))
    return img


def clamp(v: float) -> int:
    return max(0, min(255, int(v)))


def shade(c, f):
    return tuple(clamp(x * f) for x in c)


def noise_fill(img, c, amp, rng):
    """Remplit avec une couleur + bruit doux par pixel (évite l'effet damier)."""
    for y in range(TILE):
        for x in range(TILE):
            f = 1.0 + rng.uniform(-amp, amp)
            img.putpixel((x, y), shade(c, f))


def blobs(img, c, n, size, rng, amp=0.08):
    for _ in range(n):
        cx, cy = rng.randrange(TILE), rng.randrange(TILE)
        r = rng.randint(1, size)
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + rng.randint(0, 1):
                    img.putpixel((x % TILE, y % TILE), shade(c, 1 + rng.uniform(-amp, amp)))


def border(img, f=0.82):
    """Léger liseré sombre : les blocs restent lisibles un par un."""
    for i in range(TILE):
        for (x, y) in ((i, 0), (i, TILE - 1), (0, i), (TILE - 1, i)):
            img.putpixel((x, y), shade(img.getpixel((x, y)), f))


def make_tile(name, p, rng):
    img = Image.new("RGB", (TILE, TILE))
    if name == "grass_top":
        noise_fill(img, p["grass"], 0.10, rng)
        blobs(img, shade(p["grass"], 1.15), 10, 2, rng)
        blobs(img, shade(p["grass"], 0.85), 8, 1, rng)
    elif name == "grass_side":
        noise_fill(img, p["dirt"], 0.10, rng)
        blobs(img, shade(p["dirt"], 0.8), 6, 1, rng)
        for x in range(TILE):
            h = 7 + rng.randint(0, 4)
            for y in range(h):
                img.putpixel((x, y), shade(p["grass"], 1 + rng.uniform(-0.1, 0.1)))
    elif name in ("dirt", "dirt_packed", "fertile_soil"):
        c = {"dirt": p["dirt"], "dirt_packed": p["packed"], "fertile_soil": p["fertile"]}[name]
        noise_fill(img, c, 0.12, rng)
        blobs(img, shade(c, 0.75), 8, 1, rng)
        blobs(img, shade(c, 1.2), 5, 1, rng)
        if name == "fertile_soil":  # sillons
            for y in range(3, TILE, 8):
                for x in range(TILE):
                    img.putpixel((x, y), shade(c, 0.6))
                    img.putpixel((x, y + 1), shade(c, 1.25))
        if name == "dirt_packed":
            border(img, 0.7)
    elif name == "sand":
        noise_fill(img, p["sand"], 0.07, rng)
        blobs(img, shade(p["sand"], 0.9), 12, 1, rng)
    elif name == "clay":
        noise_fill(img, p["clay"], 0.06, rng)
        for y in range(0, TILE, 6):
            for x in range(TILE):
                img.putpixel((x, (y + x // 8) % TILE), shade(p["clay"], 0.88))
    elif name == "beam":  # poutres : grosses lames verticales avec chevilles
        for x in range(TILE):
            for y in range(TILE):
                f = 1 + rng.uniform(-0.05, 0.05) - (0.3 if x % 16 in (0, 15) else 0)
                img.putpixel((x, y), shade(p["wood"], f * 1.05))
        for cx in (8, 24):
            for cy in (5, 26):
                img.putpixel((cx, cy), shade(p["wood"], 0.5))
    elif name == "road_stone":  # pavés réguliers
        noise_fill(img, shade(p["mortar"], 0.8), 0.04, rng)
        for gy in range(4):
            for gx in range(4):
                f = rng.uniform(0.85, 1.1)
                ox = 4 if gy % 2 else 0
                for y in range(gy * 8 + 1, gy * 8 + 7):
                    for x in range(gx * 8 + 1, gx * 8 + 7):
                        img.putpixel(((x + ox) % TILE, y), shade(p["cobble"], f + rng.uniform(-0.03, 0.03)))
    elif name == "field_wet":
        noise_fill(img, shade(p["fertile"], 0.85), 0.1, rng)
        for y in range(2, TILE, 6):
            for x in range(TILE):
                img.putpixel((x, y), shade(p["fertile"], 0.55))
    elif name == "gravel":
        noise_fill(img, shade(p["stone"], 0.8), 0.06, rng)
        for _ in range(70):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            c = shade(p["stone"], rng.uniform(0.75, 1.25))
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                img.putpixel(((x + dx) % TILE, (y + dy) % TILE), c)
    elif name in ("stone", "bedrock", "iron_ore", "coal_ore", "deep_stone", "gold_ore"):
        base = p["bedrock"] if name == "bedrock" else shade(p["stone"], 0.68) if name == "deep_stone" else p["stone"]
        noise_fill(img, base, 0.08, rng)
        blobs(img, shade(base, 0.82), 9, 3, rng, 0.04)
        blobs(img, shade(base, 1.12), 6, 2, rng, 0.04)
        if name == "iron_ore":
            blobs(img, p["iron"], 7, 2, rng)
        if name == "coal_ore":
            blobs(img, p["coal"], 8, 2, rng)
        if name == "gold_ore":
            blobs(img, (226, 184, 60), 6, 2, rng)
    elif name in ("snow", "snow_side"):
        if name == "snow":
            noise_fill(img, p["snow"], 0.03, rng)
            blobs(img, shade(p["snow"], 0.93), 8, 2, rng, 0.01)
        else:
            noise_fill(img, p["dirt"], 0.10, rng)
            for x in range(TILE):
                h = 8 + rng.randint(0, 3)
                for y in range(h):
                    img.putpixel((x, y), shade(p["snow"], 1 + rng.uniform(-0.04, 0.02)))
    elif name in ("water", "ice"):
        c = p[name]
        noise_fill(img, c, 0.04, rng)
        for _ in range(6):
            y, x0 = rng.randrange(TILE), rng.randrange(TILE)
            for x in range(x0, x0 + rng.randint(4, 9)):
                img.putpixel((x % TILE, y), shade(c, 1.25))
    elif name == "wood_top":
        cx = cy = TILE / 2 - 0.5
        for y in range(TILE):
            for x in range(TILE):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if d > 14:
                    c = shade(p["wood"], 0.8)
                else:
                    c = shade(p["wood_core"], 0.88 if int(d) % 4 == 0 else 1.0)
                img.putpixel((x, y), shade(c, 1 + rng.uniform(-0.04, 0.04)))
    elif name == "wood_side":
        for x in range(TILE):
            f = 1 + rng.uniform(-0.12, 0.12)
            for y in range(TILE):
                img.putpixel((x, y), shade(p["wood"], f * (0.75 if x % 7 == 0 else 1.0) + rng.uniform(-0.03, 0.03)))
    elif name == "plank":
        for y in range(TILE):
            row = y // 8
            for x in range(TILE):
                f = 1 + 0.05 * ((row * 7) % 3 - 1) + rng.uniform(-0.05, 0.05)
                if y % 8 == 7:
                    f = 0.62
                if x == (row * 13 + 5) % TILE and y % 8 != 7:
                    f = 0.7
                img.putpixel((x, y), shade(p["plank"], f))
    elif name == "cobble":
        noise_fill(img, shade(p["cobble"], 0.55), 0.05, rng)
        for gy in range(4):
            for gx in range(4):
                cx = gx * 8 + 4 + rng.randint(-1, 1) + (4 if gy % 2 else 0)
                cy = gy * 8 + 4 + rng.randint(-1, 1)
                rx, ry = rng.uniform(3.2, 4.4), rng.uniform(3.0, 3.8)
                f = rng.uniform(0.88, 1.12)
                for y in range(cy - 5, cy + 6):
                    for x in range(cx - 5, cx + 6):
                        d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                        if d < 1.0:
                            hl = 1.12 if (x - cx) + (y - cy) < -2 else (0.86 if (x - cx) + (y - cy) > 3 else 1.0)
                            img.putpixel((x % TILE, y % TILE), shade(p["cobble"], f * hl + rng.uniform(-0.03, 0.03)))
    elif name == "straw":
        c = p["thatch"]
        noise_fill(img, shade(c, 0.9), 0.05, rng)
        for _ in range(140):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            f = rng.uniform(0.8, 1.25)
            for k in range(rng.randint(3, 9)):
                img.putpixel(((x + k) % TILE, (y + (k * rng.choice((0, 1)))) % TILE), shade(c, f))
    elif name == "flue_top":
        c = p["brick"]
        noise_fill(img, shade(c, 0.9), 0.05, rng)
        for y in range(8, 24):
            for x in range(8, 24):
                img.putpixel((x, y), (20, 18, 18))
    elif name == "pillar":
        c = p["cut"]
        for y in range(TILE):
            for x in range(TILE):
                f = 0.85 + 0.25 * abs(((x % 8) - 3.5) / 3.5) * -1 + 0.2 + rng.uniform(-0.04, 0.04)
                img.putpixel((x, y), shade(c, f))
    elif name in ("crenel", "rampart", "rampart_plain"):
        c = p["cut"]
        bh, bw = (11, 16) if name != "crenel" else (16, 32)
        for y in range(TILE):
            row = y // bh
            off = (bw // 2) * (row % 2)
            for x in range(TILE):
                f = (0.82 if name != "crenel" else 1.0) + rng.uniform(-0.05, 0.05)
                if y % bh == bh - 1 or (x + off) % bw == bw - 1:
                    img.putpixel((x, y), shade(p["mortar"], 0.85))
                else:
                    img.putpixel((x, y), shade(c, f))
        if name == "crenel":  # merlons : deux embrasures sombres en haut
            for x0 in (8, 24):
                for y in range(0, 12):
                    for x in range(x0 - 4, x0 + 4):
                        img.putpixel((x, y), shade(c, 0.32 + 0.02 * (y % 3)))
        elif name == "rampart":  # meurtrière au milieu
            for y in range(9, 24):
                for x in range(15, 17):
                    img.putpixel((x, y), (24, 22, 26))
    elif name in ("cut_stone", "brick"):
        c = p["cut"] if name == "cut_stone" else p["brick"]
        bh, bw = (16, 32) if name == "cut_stone" else (8, 16)
        for y in range(TILE):
            row = y // bh
            off = (bw // 2) * (row % 2)
            for x in range(TILE):
                col = (x + off) // bw
                f = 1 + 0.06 * (((row * 5 + col * 3) % 5) - 2) / 2 + rng.uniform(-0.04, 0.04)
                if y % bh == bh - 1 or (x + off) % bw == bw - 1:
                    img.putpixel((x, y), shade(p["mortar"], 0.95))
                else:
                    img.putpixel((x, y), shade(c, f))
    elif name in ("thatch_top", "thatch_side", "leaves"):
        c = p["leaves"] if name == "leaves" else p["thatch"]
        noise_fill(img, shade(c, 0.8), 0.05, rng)
        for _ in range(90):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            ln = rng.randint(3, 8)
            f = rng.uniform(0.85, 1.2)
            for k in range(ln):
                if name == "thatch_side":
                    img.putpixel((x, (y + k) % TILE), shade(c, f))
                else:
                    img.putpixel(((x + k) % TILE, (y + k // 3) % TILE), shade(c, f))
        if name == "thatch_side":
            for y in range(7, TILE, 8):
                for x in range(TILE):
                    img.putpixel((x, y), shade(c, 0.65))
    return img


def build(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    rows = (len(TILES) + COLS - 1) // COLS
    layout = {name: [i % COLS, i // COLS] for i, name in enumerate(TILES)}
    for key, pal in PALETTES.items():
        rng = random.Random(42)  # même graine : seules les couleurs changent
        atlas = Image.new("RGB", (COLS * TILE, rows * TILE), (255, 0, 255))
        for i, name in enumerate(TILES):
            tile = make_tile(name, pal, rng)
            if key == "C" and name not in ("water", "ice", "snow", "grass_top", "sand"):
                tile = grime(tile, rng)
            atlas.paste(tile, ((i % COLS) * TILE, (i // COLS) * TILE))
        atlas.save(out_dir / f"atlas_{key}.png")
    (out_dir / "atlas_layout.json").write_text(
        json.dumps({"tile": TILE, "cols": COLS, "rows": rows, "tiles": layout}, indent=1)
    )


if __name__ == "__main__":
    build(Path(sys.argv[1] if len(sys.argv) > 1 else "build/style"))
