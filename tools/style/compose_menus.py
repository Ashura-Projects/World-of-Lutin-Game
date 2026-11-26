"""Maquettes v2 : écran de jeu (ressources déroulantes, dialogue), menu engrenage, menu principal.

Usage : python3 tools/style/compose_menus.py <dossier_rendus> <dossier_sortie>
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from ui_theme import (AMBER, BLOOD, GOLD, GOLD_D, INK, IRON, IRON_L, MOSS, PARCH, TXT, TXT_D, button,  # noqa: E402
                      circle_portrait, dim_background, font, frame, g_balance, g_bloc, g_cloche, g_engrenage,
                      g_epees, g_hache, g_lutin, g_sac, g_zone, header, parchment, round_icon, stack, text_c,
                      text_r, title_font)

R, OUT = Path(sys.argv[1]), Path(sys.argv[2])
W, H = 1600, 720  # 20:9 (Xiaomi 14T Pro)


def hud(img, active="Lutins"):
    """Barres fixes : haut (temps, vitesse, population, ressources), bas (7 menus), droite (engrenage, étage)."""
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle((0, 0, W, 62), fill=(20, 16, 16, 235))
    d.line((0, 62, W, 62), fill=GOLD_D, width=2)
    d.text((20, 14), "Été · jour 3", font=title_font(26), fill=GOLD)
    for i, (k, a) in enumerate((("II", False), ("x1", True), ("x2", False), ("x4", False))):
        button(d, (240 + i * 62, 9, 294 + i * 62, 53), k, a, title_font(20))
    round_icon(d, 530, 31, 20, g_lutin)
    d.text((558, 16), "8", font=font(26, True), fill=TXT)
    # ressources principales (la nourriture = total de tous les aliments)
    res = [("Nourriture", "125"), ("Bois", "42"), ("Pierre", "18"), ("Fer", "6"), ("Or", "30")]
    for i, (n, v) in enumerate(res):
        x = 620 + i * 150
        d.rounded_rectangle((x, 10, x + 140, 52), radius=6, fill=(48, 40, 36, 255) if i else (90, 30, 28, 255), outline=GOLD_D)
        d.text((x + 10, 12), n, font=font(14), fill=TXT_D)
        d.text((x + 10, 28), v, font=font(18, True), fill=TXT)
        if i == 0:
            d.text((x + 118, 22), "▾", font=font(18), fill=GOLD)
    button(d, (1372, 9, 1460, 53), "Tout ▾", False, font(18, True))
    round_icon(d, 1500, 31, 22, g_cloche, fill=BLOOD)
    round_icon(d, 1560, 31, 22, g_engrenage)
    # barre du bas : 7 menus
    d.rectangle((0, H - 92, W, H), fill=(20, 16, 16, 235))
    d.line((0, H - 92, W, H - 92), fill=GOLD_D, width=2)
    menus = [("Construire", g_bloc), ("Récolter", g_hache), ("Zones", g_zone), ("Lutins", g_lutin),
             ("Militaire", g_epees), ("Commerce", g_sac), ("Gestion", g_balance)]
    for i, (n, g) in enumerate(menus):
        x = 175 + i * 180
        a = n == active
        d.rounded_rectangle((x, H - 84, x + 166, H - 8), radius=8, fill=BLOOD if a else IRON_L, outline=GOLD if a else GOLD_D, width=2)
        g(d, x + 83, H - 58, 22)
        text_c(d, (x + 83, H - 22), n, font(18, True), TXT)
    # curseur d'étage
    d.rounded_rectangle((W - 52, 110, W - 16, H - 120), radius=16, fill=(20, 16, 16, 210), outline=GOLD_D)
    d.rounded_rectangle((W - 50, 300, W - 18, 344), radius=10, fill=GOLD)
    text_c(d, (W - 34, 322), "4", font(20, True), INK)
    return d


def ecran_jeu():
    sc = Image.open(R / "scene_C_jour.png").convert("RGB")
    img = sc.resize((W, int(sc.height * W / sc.width))).crop((0, 70, W, 70 + H))
    d = hud(img, "Gestion")
    # menu déroulant « Nourriture » ouvert
    x, y = 620, 66
    frame(d, (x - 10, y, x + 330, y + 330))
    d.text((x + 14, y + 18), "Nourriture : 125", font=title_font(24), fill=GOLD)
    d.text((x + 14, y + 52), "≈ 6 jours de réserve", font=font(16), fill=TXT_D)
    items = [("Pain", 40, "+12/j"), ("Poisson", 28, "+6/j"), ("Viande", 22, "+4/j"), ("Baies", 20, "−3/j"), ("Légumes", 15, "+2/j")]
    for i, (n, v, t) in enumerate(items):
        yy = y + 90 + i * 44
        d.line((x + 14, yy - 6, x + 300, yy - 6), fill=(70, 60, 54), width=1)
        d.text((x + 14, yy), n, font=font(20), fill=TXT)
        text_r(d, (x + 220, yy), str(v), font(20, True), TXT)
        text_r(d, (x + 306, yy + 2), t, font(16), MOSS if t.startswith("+") else AMBER)
    # boîte de dialogue (événement)
    bx0, by0, bx1, by1 = 520, 330, 1300, 600
    frame(d, (bx0, by0, bx1, by1), title="Un marchand au gué")
    circle_portrait(img, R / "portrait.png", bx0 + 110, by0 + 130, 70)
    parchment(d, (bx0 + 200, by0 + 60, bx1 - 30, by0 + 170))
    d.multiline_text((bx0 + 216, by0 + 72),
                     "« Le bonjour, chef ! J'ai du fer et du sel de la vallée.\n"
                     "  Contre 20 pièces d'or, ou du bois si tu préfères. »", font=font(19), fill=INK, spacing=8)
    button(d, (bx0 + 200, by0 + 186, bx0 + 380, by0 + 244), "Commercer", True)
    button(d, (bx0 + 395, by0 + 186, bx0 + 575, by0 + 244), "Plus tard")
    button(d, (bx0 + 590, by0 + 186, bx1 - 30, by0 + 244), "Renvoyer")
    return stack([header(W, "Écran de jeu (20:9)", "ressources déroulantes · dialogue d'événement · 7 menus en bas · engrenage à droite"), img])


def menu_engrenage():
    img = dim_background(R / "scene_C_crepuscule.png", (W, H), blur=6, dark=0.55)
    d = hud(img, "")
    # menu principal de partie
    frame(d, (520, 100, 1080, 610), title="Menu")
    for i, (t, a) in enumerate((("Reprendre", True), ("Sauvegarder", False), ("Charger", False), ("Paramètres", False),
                                ("Menu principal", False), ("Quitter", False))):
        button(d, (580, 170 + i * 70, 1020, 226 + i * 70), t, a, title_font(26))
    # sous-menu paramètres (exemple, à droite)
    frame(d, (1110, 100, 1520, 610), title="Paramètres")
    rows = [("Musique", 0.7), ("Effets", 0.8), ("Qualité graphique", None), ("Langue", None), ("Taille des textes", None)]
    vals = {"Qualité graphique": "Moyenne ▾", "Langue": "Français ▾", "Taille des textes": "Grande ▾"}
    for i, (n, v) in enumerate(rows):
        y = 180 + i * 82
        d.text((1140, y), n, font=font(20, True), fill=TXT)
        if v is not None:
            d.rectangle((1140, y + 34, 1480, y + 46), fill=(20, 18, 18), outline=GOLD_D)
            d.rectangle((1142, y + 36, 1142 + int(336 * v), y + 44), fill=GOLD)
            d.ellipse((1142 + int(336 * v) - 10, y + 30, 1142 + int(336 * v) + 10, y + 50), fill=PARCH, outline=GOLD_D)
        else:
            button(d, (1140, y + 30, 1480, y + 68), vals[n], False, font(18, True))
    return stack([header(W, "Menu engrenage", "en jeu : sauvegarder, charger, paramètres, retour au menu principal"), img])


def menu_principal():
    sc = Image.open(R / "scene_C_crepuscule.png").convert("RGB")
    img = sc.resize((W, int(sc.height * W / sc.width))).crop((0, 60, W, 60 + H))
    veil = Image.new("RGB", (W, H), (12, 10, 10))
    mask = Image.linear_gradient("L").rotate(90).resize((W, H))  # sombre à gauche
    img = Image.composite(img, veil, mask.point(lambda v: int(60 + v * 0.75)))
    d = ImageDraw.Draw(img)
    text_c(d, (330, 120), "World of Lutin", title_font(72), GOLD)
    d.line((90, 172, 570, 172), fill=GOLD_D, width=2)
    text_c(d, (330, 200), "Bâtis. Règne. Deviens légende.", title_font(24, False), TXT_D)
    items = [("Continuer", "Le Val du Gué · jour 3", True), ("Nouvelle partie", None, False), ("Charger", None, False),
             ("Paramètres", None, False), ("Crédits", None, False), ("Quitter", None, False)]
    for i, (t, sub, a) in enumerate(items):
        y = 250 + i * 72
        button(d, (130, y, 530, y + 60), t, a, title_font(26), sub)
    # sous-menu « Nouvelle partie » déroulé
    d.polygon([(540, 352), (560, 340), (560, 364)], fill=GOLD)
    frame(d, (565, 250, 1035, 560), title="Nouvelle partie")
    modes = [("Bac à sable", "pas d'ennemis · construire et prospérer"),
             ("Aventure Royale", "orcs, sièges, royaumes · (Phase 2)")]
    for i, (t, sub) in enumerate(modes):
        button(d, (600, 320 + i * 96, 1000, 400 + i * 96), t, i == 0, title_font(28), sub)
    d.text((600, 515), "Graine de carte : 48213   ⟲", font=font(18), fill=TXT_D)
    d.text((20, H - 30), "v0.1 · projet d'Ashura", font=font(16), fill=TXT_D)
    return stack([header(W, "Menu principal", "titre, continuer la partie, nouvelle partie (2 modes), charger, paramètres"), img])


OUT.mkdir(parents=True, exist_ok=True)
ecran_jeu().save(OUT / "interface.png")
menu_engrenage().save(OUT / "menu-engrenage.png")
menu_principal().save(OUT / "menu-principal.png")
print("menus OK")
