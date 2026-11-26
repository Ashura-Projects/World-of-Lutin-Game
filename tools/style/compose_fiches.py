"""Maquettes v2 : fiche d'un lutin (métiers connus, cloche d'alerte) et fiche de guerrier (Phase 2).

Usage : python3 tools/style/compose_fiches.py <dossier_rendus> <dossier_sortie>
"""

import sys
from pathlib import Path

from PIL import ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from ui_theme import (AMBER, BLOOD, GOLD, GOLD_D, INK, IRON_L, MOSS, STEEL, TXT, TXT_D, bar, button,  # noqa: E402
                      circle_portrait, dim_background, font, frame, g_cloche, g_croix, header, parchment,
                      round_icon, stack, text_c, text_r, title_font)

R, OUT = Path(sys.argv[1]), Path(sys.argv[2])
W, H = 1600, 900


def lab(d, x, y, k, v):
    d.text((x, y), k, font=font(22), fill=TXT_D)
    d.text((x + 140, y - 2), v, font=font(24, True), fill=TXT)


def fiche_lutin():
    img = dim_background(R / "scene_C_jour_zoom.png", (W, H))
    d = ImageDraw.Draw(img)
    frame(d, (60, 50, 1540, 870), title="Brindille")
    round_icon(d, 1480, 110, 30, g_croix)
    round_icon(d, 1404, 110, 30, g_cloche, fill=BLOOD)
    circle_portrait(img, R / "portrait.png", 250, 260, 150)
    lab(d, 100, 440, "Âge", "Adulte · 4 ans")
    lab(d, 100, 480, "Métier", "Bûcheron (actif)")
    lab(d, 100, 520, "Bâtiment", "Scierie du Gué")
    lab(d, 100, 560, "Humeur", "Content")
    # aptitudes
    x0 = 470
    d.text((x0, 120), "Aptitudes", font=title_font(30), fill=GOLD)
    for i, (n, v, c) in enumerate((("Savoir", 35, STEEL), ("Force", 72, BLOOD), ("Adresse", 55, MOSS), ("Magie", 12, (120, 90, 150)))):
        y = 170 + i * 44
        d.text((x0, y), n, font=font(22), fill=TXT)
        bar(d, x0 + 120, y + 4, 230, 20, v / 100, c)
        text_r(d, (x0 + 410, y), str(v), font(22, True))
    # besoins
    d.text((x0, 360), "Besoins", font=title_font(30), fill=GOLD)
    for i, (n, v, c) in enumerate((("Faim", 0.8, MOSS), ("Sommeil", 0.45, AMBER), ("Chaleur", 0.9, MOSS), ("Moral", 0.7, MOSS))):
        y = 410 + i * 44
        d.text((x0, y), n, font=font(22), fill=TXT)
        bar(d, x0 + 120, y + 4, 290, 20, v, c)
    # métiers connus (validé : chaque métier garde son niveau et son XP)
    x1 = 960
    d.text((x1, 120), "Métiers connus", font=title_font(30), fill=GOLD)
    parchment(d, (x1 - 10, 165, 1500 - 10, 600))
    jobs = [("Bûcheron", 3, 0.62, True), ("Mineur", 2, 0.30, False), ("Fermier", 5, 0.85, False), ("Porteur", 1, 0.10, False)]
    for i, (n, lv, xp, actif) in enumerate(jobs):
        y = 185 + i * 100
        if actif:
            d.rectangle((x1, y - 6, 1480, y + 82), fill=(236, 220, 186), outline=GOLD_D, width=2)
        d.text((x1 + 14, y), n, font=title_font(28), fill=INK)
        d.text((x1 + 14, y + 40), "métier actif" if actif else "connu", font=font(18), fill=(120, 90, 60))
        d.ellipse((x1 + 250, y + 2, x1 + 316, y + 68), fill=(60, 44, 32), outline=GOLD, width=3)
        text_c(d, (x1 + 283, y + 24), "niv.", font(14), (220, 200, 160))
        text_c(d, (x1 + 283, y + 46), str(lv), font(24, True), GOLD)
        d.text((x1 + 335, y + 8), "Expérience", font=font(16), fill=(110, 84, 60))
        bar(d, x1 + 335, y + 32, 170, 18, xp, STEEL)
    d.text((x1, 612), "Changer vers un métier de base : libre.\nJamais pratiqué → niveau 1 ; déjà connu → garde son niveau.",
           font=font(18), fill=TXT_D, spacing=6)
    # menu de la cloche ouvert : 2 choix
    d.polygon([(1404, 144), (1394, 158), (1414, 158)], fill=GOLD)
    frame(d, (1200, 156, 1500, 330))
    button(d, (1222, 176, 1478, 244), "Mobiliser", sub="aux armes !")
    button(d, (1222, 254, 1478, 316), "Se cacher", sub="à l'abri")
    for i, (t, a) in enumerate((("Changer de métier", True), ("Affectation", False), ("Suivre", False), ("Historique", False))):
        button(d, (100 + i * 350, 770, 420 + i * 350, 836), t, active=a)
    return stack([header(W, "Fiche d'un lutin", "métiers connus avec niveau et expérience · cloche : mobiliser ou se cacher"), img])


def fiche_guerrier():
    img = dim_background(R / "scene_C_crepuscule.png", (W, H))
    d = ImageDraw.Draw(img)
    frame(d, (60, 50, 1540, 870), title="Galet « Lame du Gué »")
    round_icon(d, 1480, 110, 30, g_croix)
    circle_portrait(img, R / "portrait_soldat.png", 250, 260, 150)
    lab(d, 100, 440, "Grade", "Capitaine")
    lab(d, 100, 480, "Unité", "Garde du Gué")
    lab(d, 100, 520, "Arme", "Épée courte")
    lab(d, 100, 560, "Blessures", "Aucune")
    # grades
    x0 = 470
    d.text((x0, 120), "Grade", font=title_font(30), fill=GOLD)
    grades = ["Recrue", "Soldat", "Capitaine", "Commandant", "Général"]
    for i, g in enumerate(grades):
        x = x0 + i * 205
        done, cur = i < 2, i == 2
        fill = BLOOD if cur else ((70, 60, 50) if done else IRON_L)
        d.polygon([(x, 170), (x + 180, 170), (x + 200, 200), (x + 180, 230), (x, 230), (x + 20, 200)], fill=fill,
                  outline=GOLD if (cur or done) else GOLD_D)
        text_c(d, (x + 100, 200), g, font(20, True), TXT if (cur or done) else TXT_D)
    # réputation
    d.text((x0, 260), "Réputation", font=title_font(30), fill=GOLD)
    bar(d, x0, 310, 560, 26, 0.58, AMBER)
    d.text((x0, 344), "Titre : « Lame du Gué »   ·   580 / 1000", font=font(20, True), fill=TXT)
    d.text((x0, 372), "Prochain titre : « Rempart du Val »", font=font(18), fill=TXT_D)
    # ennemis vaincus
    d.text((1130, 260), "Ennemis vaincus", font=title_font(30), fill=GOLD)
    for i, (n, v) in enumerate((("Orcs", 37), ("Chefs orcs", 2), ("Bêtes sauvages", 11))):
        d.text((1130, 310 + i * 36), n, font=font(22), fill=TXT)
        text_r(d, (1480, 310 + i * 36), str(v), font(24, True), GOLD)
    # techniques de combat (inspiration murim, sans magie)
    d.text((x0, 410), "Techniques de combat", font=title_font(30), fill=GOLD)
    parchment(d, (x0 - 10, 455, 1490, 735))
    techs = [("Coupe du ruisseau", "frappe rapide en enchaînement", 3, 0.7), ("Garde de fer", "bloque une attaque sur trois", 2, 0.4),
             ("Pas du héron", "esquive et contre", 2, 0.15), ("Charge du sanglier", "renverse l'ennemi", 1, 0.5),
             ("Tir posé", "fusil à silex, dégâts ×2 à l'arrêt", 1, 0.2), ("Cri de ralliement", "+moral aux alliés proches", 1, 0.0)]
    for i, (n, desc, lv, xp) in enumerate(techs):
        cx, cy = x0 + (i % 2) * 510, 470 + (i // 2) * 88
        d.text((cx + 6, cy), n, font=title_font(24), fill=INK)
        d.text((cx + 6, cy + 34), desc, font=font(17), fill=(100, 76, 52))
        stars = "★" * lv + "☆" * (5 - lv)
        d.text((cx + 300, cy + 2), stars, font=font(22), fill=(170, 110, 30))
        bar(d, cx + 300, cy + 38, 160, 14, xp, STEEL)
    for i, (t, a) in enumerate((("Entraîner", True), ("Équipement", False), ("Unité", False), ("Hauts faits", False))):
        button(d, (100 + i * 350, 770, 420 + i * 350, 836), t, active=a)
    return stack([header(W, "Fiche d'un guerrier (Phase 2)", "techniques de combat · ennemis vaincus · réputation, titres et grades"), img])


OUT.mkdir(parents=True, exist_ok=True)
fiche_lutin().save(OUT / "fiche-personnage.png")
fiche_guerrier().save(OUT / "fiche-guerrier.png")
print("fiches OK")
