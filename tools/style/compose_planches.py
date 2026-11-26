"""Assemble les planches de style v2 (largeur 1600 px) à partir des rendus Blender.

Usage : python3 tools/style/compose_planches.py <dossier_rendus> <dossier_atlas> <dossier_sortie>
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from ui_theme import GOLD, GOLD_D, TXT, TXT_D, font, header, stack, text_c, title_font  # noqa: E402

R, ATL, OUT = (Path(a) for a in sys.argv[1:4])
OUT.mkdir(parents=True, exist_ok=True)
ROOT = Path(__file__).resolve().parents[2]
W = 1600
BG = (22, 18, 18)
BAND = (40, 32, 30)


def fit(im, w):
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def band(txt, h=64, size=30):
    b = Image.new("RGB", (W, h), BAND)
    d = ImageDraw.Draw(b)
    d.line((0, h - 1, W, h - 1), fill=GOLD_D)
    text_c(d, (W / 2, h / 2), txt, title_font(size), GOLD)
    return b


def labels(items, h=56, f=None):
    img = Image.new("RGB", (W, h), BG)
    d = ImageDraw.Draw(img)
    cw = W / len(items)
    for i, t in enumerate(items):
        text_c(d, (cw * i + cw / 2, h / 2), t, f or font(24, True), TXT)
    return img


def row(images, cell_w):
    cells = [fit(im.convert("RGB"), cell_w) for im in images]
    out = Image.new("RGB", (W, cells[0].height), BG)
    x0 = (W - cell_w * len(cells)) // 2
    for i, c in enumerate(cells):
        out.paste(c, (x0 + i * cell_w, 0))
    return out


# a. Peaux du lutin A -----------------------------------------------------------------------
parts = [header(W, "Le Lutin A — quelle peau ?", "ambiance sombre · face · trois-quarts · en action (l'outil n'apparaît qu'en travaillant)")]
for skin, titre in (("bleu", "Bleu (actuel)"), ("bleu_sombre", "Bleu sombre"), ("vert", "Vert foncé (proposition gobelin)")):
    parts += [band(titre), row([Image.open(R / f"peau_{skin}_{v}.png") for v in ("face", "34", "action")], 420)]
stack(parts, BG).save(OUT / "lutin-peaux.png")

# b. Métiers : repos / action ------------------------------------------------------------------
JOBS = [("porteur", "Porteur", "caisse"), ("bucheron", "Bûcheron", "hache"), ("mineur", "Mineur", "pioche + lampe"),
        ("terrassier", "Terrassier", "pelle"), ("batisseur", "Bâtisseur", "marteau"), ("cueilleur", "Cueilleur", "panier"),
        ("pecheur", "Pêcheur", "canne"), ("chasseur", "Chasseur", "fusil à silex"), ("fermier", "Fermier", "houe"),
        ("menuisier", "Menuisier", "scie"), ("tailleur_pierre", "Tailleur de pierre", "ciseau + maillet"),
        ("forgeron", "Forgeron", "pinces"), ("cuisinier", "Cuisinier", "louche"), ("maitre_ecole", "Maître d'école", "livre"),
        ("chercheur", "Chercheur", "parchemin"), ("artisan_expert", "Artisan expert", "marteau d'or")]
cards = []
for job, name, tool in JOBS:
    card = Image.new("RGB", (400, 330), BG)
    d = ImageDraw.Draw(card)
    d.rectangle((4, 4, 395, 325), fill=(32, 27, 26), outline=GOLD_D, width=2)
    for k, v in enumerate(("repos", "action")):
        im = fit(Image.open(R / f"metier_{job}_{v}.png").convert("RGB"), 190).crop((0, 20, 190, 230))
        card.paste(im, (10 + k * 190, 12))
        text_c(d, (105 + k * 190, 232), "au repos" if v == "repos" else "en action", font(15), TXT_D)
    text_c(d, (200, 268), name, title_font(26), GOLD)
    text_c(d, (200, 302), tool, font(18), TXT)
    cards.append(card)
rows_ = []
for i in range(0, 16, 4):
    r_ = Image.new("RGB", (W, 334), BG)
    for k, c in enumerate(cards[i:i + 4]):
        r_.paste(c, (k * 400, 0))
    rows_.append(r_)
stack([header(W, "Les métiers", "outil seulement pendant l'action · le métier se lit au bonnet et à la tenue")] + rows_, BG
      ).save(OUT / "fiches-metiers.png")

# c. Âges ------------------------------------------------------------------------------------------
pop = json.loads((ROOT / "data/population.json").read_text())
stack([header(W, "Les âges du lutin", "bébé → enfant → adulte → ancien (validé)"),
       fit(Image.open(R / "ages_ensemble.png").convert("RGB"), W),
       labels(["Bébé", "Enfant (école)", "Adulte", "Ancien"], 60, title_font(26))], BG).save(OUT / "ages.png")

# e. Blocs ------------------------------------------------------------------------------------------
blocks = [b for b in json.loads((ROOT / "data/blocks.json").read_text())["blocks"] if b["id"] != "air"]
parts = [header(W, "Les blocs", "atlas unique 32×32 px par tuile")]
for pal, titre in (("B", "Palette B — réaliste (choisie)"), ("C", "Palette C — sombre, usée (dark fantasy)")):
    parts.append(band(titre))
    shown = [b for b in blocks if (R / f"bloc_{pal}_{b['id']}.png").exists()]  # nouveaux blocs : rendus plus tard
    ims = [Image.open(R / f"bloc_{pal}_{b['id']}.png").convert("RGB") for b in shown]
    for i in range(0, len(ims), 9):
        parts.append(row(ims[i:i + 9], 176))
        lab = Image.new("RGB", (W, 40), BG)
        dl = ImageDraw.Draw(lab)
        for k, b in enumerate(shown[i:i + 9]):
            text_c(dl, (8 + 176 * k + 88, 20), b["name"], font(16, True), TXT)
        parts.append(lab)
    atlas = Image.open(ATL / f"atlas_{pal}.png")
    a = atlas.resize((atlas.width * 4, atlas.height * 4), Image.NEAREST)
    strip = Image.new("RGB", (W, a.height + 30), BG)
    strip.paste(a, ((W - a.width) // 2, 15))
    parts.append(strip)
stack(parts, BG).save(OUT / "blocs.png")

# f. Scène -----------------------------------------------------------------------------------------
parts = [header(W, "Scène de démonstration", "plaines, rivière, montagne à explorer · palette C · brume légère")]
for mood, titre in (("jour", "Jour"), ("crepuscule", "Crépuscule (torches allumées)"), ("hiver", "Hiver")):
    parts += [band(titre), Image.open(R / f"scene_C_{mood}.png").convert("RGB")]
parts += [band("Zoom « près des lutins » — jour"), Image.open(R / "scene_C_jour_zoom.png").convert("RGB")]
stack(parts, BG).save(OUT / "scene-village.png")
# g. Fusil à silex : porté, visée, tir --------------------------------------------------------------
if (R / "tir_feu.png").exists():
    top = row([Image.open(R / "tir_repos.png"), Image.open(R / "tir_vise.png")], 420)
    stack([header(W, "Le fusil à silex", "porté dans le dos · épaulé, canon vers l'avant · tir : flash et fumée au bout du canon"),
           top, labels(["Au repos : en bandoulière", "En visée"], 56),
           band("Le tir, face à un loup"), fit(Image.open(R / "tir_feu.png").convert("RGB"), W)], BG).save(OUT / "fusil-tir.png")
print("planches OK")
