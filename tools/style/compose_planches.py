"""Assemble les planches de style (largeur 1600 px) à partir des rendus Blender.

Usage : python3 tools/style/compose_planches.py <dossier_rendus> <dossier_atlas> <dossier_sortie>
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from pcommon import BG, INK, WOOD, font, fit, header, label_strip, stack, text_c  # noqa: E402

R, ATL, OUT = (Path(a) for a in sys.argv[1:4])
OUT.mkdir(parents=True, exist_ok=True)
ROOT = Path(__file__).resolve().parents[2]
W = 1600


def grid(images, cols, cell_w, labels=None, label_h=60, gap=0, f=None):
    rows = (len(images) + cols - 1) // cols
    cells = [fit(im, cell_w) for im in images]
    ch = cells[0].height + (label_h if labels else 0)
    out = Image.new("RGB", (W, rows * (ch + gap)), BG)
    d = ImageDraw.Draw(out)
    x0 = (W - cols * cell_w) // 2
    for i, c in enumerate(cells):
        x, y = x0 + (i % cols) * cell_w, (i // cols) * (ch + gap)
        out.paste(c, (x, y))
        if labels:
            text_c(d, (x + cell_w / 2, y + c.height + label_h / 2 - 4), labels[i], f or font(28, True))
    return out


# a. Variantes du lutin ---------------------------------------------------------------
NOMS_VAR = {"A": "A — « Bouille »  (tête ronde, bonnet pointu, oreilles en pointe)",
            "B": "B — « Gland »  (corps en œuf, grands yeux, bonnet-cupule)",
            "C": "C — « Bloc »  (formes cubiques comme le monde, longues oreilles)"}
parts = [header(W, "Le Lutin — 3 propositions", "face · trois-quarts · dos · avec un outil (hache)")]
for v in "ABC":
    band = Image.new("RGB", (W, 64), (234, 222, 196))
    text_c(ImageDraw.Draw(band), (W / 2, 32), NOMS_VAR[v], font(32, True))
    parts.append(band)
    ims = [Image.open(R / f"variante_{v}_{k}.png") for k in ("face", "trois_quarts", "dos", "outil")]
    parts.append(grid(ims, 4, 400))
parts.append(label_strip(W, ["Face", "Trois-quarts", "Dos", "Avec outil"], 56, font(26)))
stack(parts).save(OUT / "lutin-variantes.png")

# b. Fiches métiers ----------------------------------------------------------------------
JOBS = [("porteur", "Porteur", "caisse (sans outil)"), ("bucheron", "Bûcheron", "hache"),
        ("mineur", "Mineur", "pioche + lampe"), ("terrassier", "Terrassier", "pelle"),
        ("batisseur", "Bâtisseur", "marteau"), ("cueilleur", "Cueilleur", "panier"),
        ("pecheur", "Pêcheur", "canne à pêche"), ("chasseur", "Chasseur", "arc + carquois"),
        ("fermier", "Fermier", "houe"), ("menuisier", "Menuisier", "scie"),
        ("tailleur_pierre", "Tailleur de pierre", "ciseau + maillet"), ("forgeron", "Forgeron", "pinces + lingot"),
        ("cuisinier", "Cuisinier", "louche"), ("maitre_ecole", "Maître d'école", "livre (formé)"),
        ("chercheur", "Chercheur", "parchemin (formé)"), ("artisan_expert", "Artisan expert", "marteau d'or (formé)")]
cards = []
for job, name, tool in JOBS:
    im = fit(Image.open(R / f"metier_{job}.png"), 380)
    card = Image.new("RGB", (400, im.height + 110), BG)
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((4, 4, 395, card.height - 6), radius=16, fill=(240, 232, 214), outline=WOOD, width=3)
    card.paste(im.crop((0, 30, 380, im.height)), (10, 14))
    text_c(d, (200, im.height + 22), name, font(30, True, True))
    text_c(d, (200, im.height + 62), tool, font(22), (110, 90, 70))
    cards.append(card)
rows = []
for i in range(0, 16, 4):
    row = Image.new("RGB", (W, cards[0].height + 8), BG)
    for k, c in enumerate(cards[i:i + 4]):
        row.paste(c, (k * 400, 0))
    rows.append(row)
stack([header(W, "Les métiers (variante A)", "le métier se lit à la silhouette : bonnet + tenue + outil")] + rows).save(OUT / "fiches-metiers.png")

# c. Âges ------------------------------------------------------------------------------------
pop = json.loads((ROOT / "data/population.json").read_text())
days = {a["id"]: a["from_day"] for a in pop["ages"]}
year = 20
ens = fit(Image.open(R / "ages_ensemble.png"), W)
labels = [f"Bébé · dès {days['baby']} j", f"Enfant · dès {days['child']} j (école)",
          f"Adulte · dès {days['adult'] // year} ans", f"Ancien · dès {days['elder'] // year} ans"]
ims = [Image.open(R / f"age_{a}.png") for a in ("baby", "child", "adult", "elder")]
stack([header(W, "Les âges du lutin", "bébé → enfant → adulte → ancien (meurt de vieillesse)"), ens,
       label_strip(W, ["Bébé", "Enfant", "Adulte", "Ancien"], 60, font(30, True)),
       grid(ims, 4, 400, labels, 70, f=font(22, True))]).save(OUT / "ages.png")

# e. Blocs ------------------------------------------------------------------------------------
blocks = [b for b in json.loads((ROOT / "data/blocks.json").read_text())["blocks"] if b["id"] != "air"]
parts = [header(W, "Les blocs", "atlas unique 32×32 px par tuile · 2 palettes")]
for pal, titre in (("A", "Palette A — chaleureuse (conte)"), ("B", "Palette B — plus réaliste (terreuse)")):
    band = Image.new("RGB", (W, 70), (234, 222, 196))
    text_c(ImageDraw.Draw(band), (W / 2, 35), titre, font(34, True, True))
    parts.append(band)
    ims = [Image.open(R / f"bloc_{pal}_{b['id']}.png") for b in blocks]
    parts.append(grid(ims, 9, 176, [b["name"] for b in blocks], 46, f=font(17, True)))
    atlas = Image.open(ATL / f"atlas_{pal}.png")
    a = atlas.resize((atlas.width * 4, atlas.height * 4), Image.NEAREST)
    strip = Image.new("RGB", (W, a.height + 60), BG)
    text_c(ImageDraw.Draw(strip), (W / 2, 22), f"Atlas {pal} (agrandi ×4)", font(22), (110, 90, 70))
    strip.paste(a, ((W - a.width) // 2, 50))
    parts.append(strip)
stack(parts).save(OUT / "blocs.png")

# f. Scène du village --------------------------------------------------------------------------
parts = [header(W, "Scène de démonstration", "caméra du jeu · rivière, champ, maison en blocs, mur en construction (blocs-plans bleus)")]
for season, titre in (("ete", "Été — vue « village »"), ("hiver", "Hiver — vue « village »")):
    parts.append(label_strip(W, [titre], 70, font(34, True, True), bg=(234, 222, 196)))
    parts.append(Image.open(R / f"scene_A_{season}.png"))
zooms = Image.new("RGB", (W, 450), BG)
zooms.paste(fit(Image.open(R / "scene_A_ete_zoom.png"), 800), (0, 0))
zooms.paste(fit(Image.open(R / "scene_A_hiver_zoom.png"), 800), (800, 0))
parts += [label_strip(W, ["Zoom « près des lutins » — été", "Zoom — hiver"], 70, font(28, True), bg=(234, 222, 196)), zooms]
stack(parts).save(OUT / "scene-village.png")

# h. Orcs ---------------------------------------------------------------------------------------
stack([header(W, "Aperçu des Orcs (Phase 2)", "rouges, grassouillets, armures de bric et de broc — lutin au centre pour l'échelle"),
       Image.open(R / "orcs.png"),
       label_strip(W, ["A — « Marmite » (gourdin)", "Lutin", "B — « Bedaine à crête » (couperet)"], 80, font(30, True))]
      ).save(OUT / "orcs-apercu.png")
print("planches OK")
