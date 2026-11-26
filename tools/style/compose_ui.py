"""Maquettes 2D : fiche d'un lutin et écran principal (paysage, 20:9 comme le Xiaomi 14T Pro).

Usage : python3 tools/style/compose_ui.py <dossier_rendus> <dossier_sortie>
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
from pcommon import (BLUE, GREEN, INK, ORANGE, PARCH, PARCH_D, RED, WOOD, WOOD_L, bar, font, header,  # noqa: E402
                     panel, stack, text_c)

R, OUT = Path(sys.argv[1]), Path(sys.argv[2])
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1600, 720  # 20:9


def icon(d, kind, cx, cy, s=16, color=INK):
    """Petites icônes dessinées (pas de police d'icônes)."""
    if kind == "soleil":
        d.ellipse((cx - s * 0.6, cy - s * 0.6, cx + s * 0.6, cy + s * 0.6), fill=(250, 200, 60))
        for k in range(8):
            import math
            a = k * math.pi / 4
            d.line((cx + s * 0.8 * math.cos(a), cy + s * 0.8 * math.sin(a), cx + s * 1.1 * math.cos(a),
                    cy + s * 1.1 * math.sin(a)), fill=(250, 200, 60), width=3)
    elif kind == "lutin":
        d.ellipse((cx - s * 0.6, cy - s * 0.5, cx + s * 0.6, cy + s * 0.7), fill=BLUE)
        d.polygon([(cx - s * 0.6, cy - s * 0.2), (cx + s * 0.6, cy - s * 0.2), (cx + s * 0.2, cy - s * 1.2)], fill=RED)
    elif kind == "alerte":
        d.polygon([(cx, cy - s), (cx + s, cy + s * 0.8), (cx - s, cy + s * 0.8)], fill=ORANGE)
        text_c(d, (cx, cy + 2), "!", font(int(s * 1.1), True), INK)
    elif kind == "pause":
        d.rectangle((cx - s * 0.5, cy - s * 0.6, cx - s * 0.15, cy + s * 0.6), fill=color)
        d.rectangle((cx + s * 0.15, cy - s * 0.6, cx + s * 0.5, cy + s * 0.6), fill=color)
    elif kind == "lecture":
        d.polygon([(cx - s * 0.5, cy - s * 0.6), (cx + s * 0.6, cy), (cx - s * 0.5, cy + s * 0.6)], fill=color)


def tool_button(d, box, label, active=False, glyph=None):
    fill = (250, 226, 160) if active else PARCH
    panel(d, box, fill=fill, r=14, w=4)
    cx = (box[0] + box[2]) / 2
    if glyph:
        glyph(d, cx, box[1] + 30)
    text_c(d, (cx, box[3] - 22), label, font(20, True))


def g_bloc(d, cx, cy):
    d.polygon([(cx, cy - 16), (cx + 16, cy - 8), (cx, cy), (cx - 16, cy - 8)], fill=(120, 200, 80))
    d.polygon([(cx - 16, cy - 8), (cx, cy), (cx, cy + 16), (cx - 16, cy + 8)], fill=(150, 100, 60))
    d.polygon([(cx + 16, cy - 8), (cx, cy), (cx, cy + 16), (cx + 16, cy + 8)], fill=(120, 80, 50))


def g_hache(d, cx, cy):
    d.line((cx - 10, cy + 16, cx + 8, cy - 14), fill=WOOD_L, width=5)
    d.polygon([(cx + 2, cy - 16), (cx + 18, cy - 10), (cx + 12, cy + 2)], fill=(170, 175, 185))


def g_zone(d, cx, cy):
    d.rectangle((cx - 16, cy - 14, cx + 16, cy + 14), outline=GREEN, width=4)
    d.rectangle((cx - 8, cy - 6, cx + 8, cy + 6), fill=(200, 170, 80))


def g_lutin(d, cx, cy):
    icon(d, "lutin", cx, cy + 4, 18)


def g_gestion(d, cx, cy):
    for i, h in enumerate((10, 20, 30)):
        d.rectangle((cx - 16 + i * 12, cy + 14 - h, cx - 6 + i * 12, cy + 14), fill=(BLUE, GREEN, ORANGE)[i])


# ---------------------------------------------------------------------------- fiche personnage
def fiche():
    bg = Image.open(R / "scene_A_ete_zoom.png").convert("RGB").resize((W, 900)).filter(ImageFilter.GaussianBlur(6))
    img = Image.blend(bg, Image.new("RGB", bg.size, (40, 30, 20)), 0.45)
    d = ImageDraw.Draw(img)
    panel(d, (160, 60, 1440, 850), r=26, w=7)
    d.rounded_rectangle((160, 60, 1440, 150), radius=26, fill=WOOD)
    d.rectangle((160, 120, 1440, 150), fill=WOOD)
    text_c(d, (800, 104), "Brindille", font(48, True, True), PARCH)
    d.ellipse((1370, 80, 1420, 130), fill=RED)
    text_c(d, (1395, 104), "✕", font(28, True), PARCH)
    # portrait
    por = Image.open(R / "portrait.png").resize((290, 290))
    mask = Image.new("L", por.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, 289, 289), fill=255)
    d.ellipse((235, 172, 545, 482), fill=PARCH_D, outline=WOOD, width=6)
    img.paste(por, (245, 182), mask)
    # identité
    f_lab, f_val = font(26), font(28, True)
    rows = [("Âge", "Adulte · 4 ans"), ("Métier", "Bûcheron · niv. 2"), ("Outil", "Hache de fer"),
            ("Bâtiment", "Scierie du Gué")]
    y = 505
    for lab, val in rows:
        d.text((210, y), lab, font=f_lab, fill=(120, 96, 70))
        d.text((360, y), val, font=f_val, fill=INK)
        y += 48
    d.text((210, y + 4), "Expérience", font=f_lab, fill=(120, 96, 70))
    bar(d, 360, y + 12, 220, 18, 0.62, BLUE)
    # aptitudes
    x0 = 650
    d.text((x0, 180), "Aptitudes", font=font(34, True, True), fill=INK)
    apt = [("Savoir", 0.35, (110, 90, 200)), ("Force", 0.72, RED), ("Adresse", 0.55, GREEN), ("Magie", 0.12, (180, 90, 200))]
    for i, (n, v, c) in enumerate(apt):
        yy = 240 + i * 56
        d.text((x0, yy), n, font=font(26), fill=INK)
        bar(d, x0 + 150, yy + 6, 400, 24, v, c)
        d.text((x0 + 570, yy), str(int(v * 100)), font=font(26, True), fill=INK)
    # besoins
    d.text((x0, 480), "Besoins", font=font(34, True, True), fill=INK)
    bes = [("Faim", 0.8, GREEN, "rassasié"), ("Sommeil", 0.45, ORANGE, "fatigué"), ("Chaleur", 0.9, GREEN, "au chaud"),
           ("Moral", 0.7, GREEN, "content")]
    for i, (n, v, c, t) in enumerate(bes):
        yy = 540 + i * 56
        d.text((x0, yy), n, font=font(26), fill=INK)
        bar(d, x0 + 150, yy + 6, 400, 24, v, c)
        d.text((x0 + 570, yy), t, font=font(22), fill=(110, 90, 70))
    # boutons
    for i, lab in enumerate(("Changer d'affectation", "Suivre", "Historique")):
        bx = 210 + i * 400
        panel(d, (bx, 770, bx + 370, 830), fill=(250, 226, 160) if i == 0 else PARCH, r=14, w=4)
        text_c(d, (bx + 185, 800), lab, font(24, True))
    return stack([header(W, "Fiche d'un lutin (maquette)", "tap sur un lutin → cette fiche · boutons ≥ 48 dp"), img])


# ---------------------------------------------------------------------------- écran principal
def ecran():
    sc = Image.open(R / "scene_A_ete.png").convert("RGB")
    sc = sc.resize((W, int(sc.height * W / sc.width))).crop((0, 60, W, 60 + H))
    img = sc.copy()
    d = ImageDraw.Draw(img, "RGBA")
    # barre du haut
    d.rectangle((0, 0, W, 64), fill=(60, 40, 24, 225))
    icon(d, "soleil", 40, 32, 14)
    d.text((66, 16), "Printemps · jour 3", font=font(26, True), fill=PARCH)
    for i, (k, act) in enumerate((("pause", False), ("x1", True), ("x2", False), ("x4", False))):
        bx = 420 + i * 70
        d.rounded_rectangle((bx, 10, bx + 60, 54), radius=10, fill=(250, 226, 160) if act else PARCH_D)
        if k == "pause":
            icon(d, "pause", bx + 30, 32, 16)
        else:
            text_c(d, (bx + 30, 32), k, font(22, True))
    icon(d, "lutin", 760, 34, 14)
    d.text((784, 16), "8 lutins", font=font(26, True), fill=PARCH)
    d.text((930, 16), "Bois 42 · Pierre 18 · Pain 25", font=font(24), fill=PARCH_D)
    icon(d, "alerte", 1400, 32, 15)
    d.text((1424, 16), "Cuisine vide", font=font(22, True), fill=(255, 210, 120))
    # barre d'outils du bas
    d.rectangle((0, H - 100, W, H), fill=(60, 40, 24, 225))
    for i, (lab, gl) in enumerate((("Construire", g_bloc), ("Récolter", g_hache), ("Zones", g_zone),
                                   ("Lutins", g_lutin), ("Gestion", g_gestion))):
        bx = 300 + i * 170
        tool_button(d, (bx, H - 92, bx + 150, H - 10), lab, lab == "Lutins", gl)
    # curseur d'étage (bord droit)
    d.rounded_rectangle((W - 60, 100, W - 20, H - 120), radius=20, fill=(60, 40, 24, 200))
    d.rounded_rectangle((W - 56, 330, W - 24, 380), radius=12, fill=PARCH)
    text_c(d, (W - 40, 355), "4", font(22, True))
    text_c(d, (W - 40, 120), "▲", font(18), PARCH)
    text_c(d, (W - 40, H - 140), "▼", font(18), PARCH)
    # panneau d'affectation
    px0, py0, px1, py1 = 40, 90, 790, H - 118
    panel(d, (px0, py0, px1, py1), r=20, w=5)
    d.text((px0 + 24, py0 + 16), "Affectation", font=font(32, True, True), fill=INK)
    d.rounded_rectangle((px1 - 170, py0 + 16, px1 - 24, py0 + 56), radius=12, fill=GREEN)
    text_c(d, (px1 - 97, py0 + 36), "Auto : oui", font(20, True), PARCH)
    bats = [("Scierie du Gué", 3, ["Brindille", "Pic"], None), ("Ferme", 2, ["Myrtille", "Tom"], None),
            ("Cuisine", 1, [], "poste vide"), ("Carrière", 2, ["Galet"], "pas de pioche en réserve")]
    y = py0 + 76
    for nom, postes, lutins, alerte in bats:
        d.rounded_rectangle((px0 + 18, y, px1 - 18, y + 92), radius=12, fill=(238, 224, 194))
        d.text((px0 + 34, y + 8), f"{nom}", font=font(24, True), fill=INK)
        d.text((px0 + 34, y + 40), f"{len(lutins)}/{postes} postes", font=font(20), fill=(110, 90, 70))
        if alerte:
            icon(d, "alerte", px0 + 50, y + 74, 10)
            d.text((px0 + 66, y + 64), alerte, font=font(18, True), fill=(190, 90, 20))
        for k in range(postes):
            cx = px0 + 322 + k * 134
            if k < len(lutins):
                d.rounded_rectangle((cx, y + 18, cx + 128, y + 74), radius=28, fill=(200, 222, 248), outline=BLUE, width=3)
                icon(d, "lutin", cx + 22, y + 48, 12)
                d.text((cx + 38, y + 35), lutins[k], font=font(16, True), fill=INK)
            else:
                d.rounded_rectangle((cx, y + 18, cx + 128, y + 74), radius=28, outline=(160, 130, 90), width=3)
                text_c(d, (cx + 64, y + 46), "+ libre", font(20, True), (140, 110, 80))
        y += 102
    # bulle d'explication
    return stack([header(W, "Écran principal (maquette, paysage 20:9)",
                         "haut : jour, vitesse, population, alertes · bas : 5 menus · droite : curseur d'étage"), img])


fiche().save(OUT / "fiche-personnage.png")
ecran().save(OUT / "interface.png")
print("maquettes OK")
