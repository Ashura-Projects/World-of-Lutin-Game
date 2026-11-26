"""Thème d'interface v2 « dark fantasy médiéval » : cadres de fer sombre, filets dorés, parchemin vieilli.

Titres en Cinzel (OFL, assets/fonts/), textes en DejaVu Sans (lisibilité téléphone).
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
DEJAVU = "/usr/share/fonts/truetype/dejavu/"

IRON = (34, 30, 30)          # fond des cadres
IRON_L = (52, 46, 44)
GOLD = (196, 158, 84)        # filets et titres
GOLD_D = (120, 92, 46)
PARCH = (222, 206, 172)      # parchemin vieilli
PARCH_D = (186, 166, 128)
INK = (40, 28, 20)
TXT = (232, 220, 196)        # texte clair sur fer
TXT_D = (164, 150, 128)
BLOOD = (140, 36, 32)        # accent (alerte, bouton actif)
STEEL = (110, 150, 190)      # accent bleu lutin
MOSS = (96, 132, 70)
AMBER = (214, 140, 52)


def title_font(size, bold=True):
    return ImageFont.truetype(str(ROOT / f"assets/fonts/Cinzel-{'Bold' if bold else 'Regular'}.ttf"), size)


def font(size, bold=False):
    return ImageFont.truetype(DEJAVU + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), size)


def text_c(d, xy, txt, f, fill=TXT):
    b = d.textbbox((0, 0), txt, font=f)
    d.text((xy[0] - (b[2] - b[0]) / 2, xy[1] - (b[3] - b[1]) / 2 - b[1]), txt, font=f, fill=fill)


def text_r(d, xy, txt, f, fill=TXT):
    b = d.textbbox((0, 0), txt, font=f)
    d.text((xy[0] - (b[2] - b[0]), xy[1]), txt, font=f, fill=fill)


def _diamond(d, cx, cy, r, fill):
    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=fill)


def frame(d, box, fill=IRON, r=10, title=None, title_size=34):
    """Cadre principal : fer sombre, double filet doré, ornements d'angle, titre en bandeau."""
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, radius=r, fill=fill, outline=(14, 12, 12), width=4)
    d.rounded_rectangle((x0 + 6, y0 + 6, x1 - 6, y1 - 6), radius=r, outline=GOLD_D, width=2)
    d.rounded_rectangle((x0 + 11, y0 + 11, x1 - 11, y1 - 11), radius=r, outline=GOLD, width=1)
    for cx, cy in ((x0 + 8, y0 + 8), (x1 - 8, y0 + 8), (x0 + 8, y1 - 8), (x1 - 8, y1 - 8)):
        _diamond(d, cx, cy, 9, GOLD)
        _diamond(d, cx, cy, 4, IRON)
    if title:
        f = title_font(title_size)
        b = d.textbbox((0, 0), title, font=f)
        w = b[2] - b[0] + 80
        cx = (x0 + x1) / 2
        d.polygon([(cx - w / 2 - 18, y0 - 4), (cx + w / 2 + 18, y0 - 4), (cx + w / 2, y0 + 26),
                   (cx + w / 2 + 18, y0 + 56), (cx - w / 2 - 18, y0 + 56), (cx - w / 2, y0 + 26)], fill=BLOOD)
        d.rectangle((cx - w / 2, y0 - 4, cx + w / 2, y0 + 56), fill=(110, 28, 26), outline=GOLD, width=2)
        text_c(d, (cx, y0 + 26), title, f, (240, 222, 180))


def parchment(d, box, r=6):
    d.rounded_rectangle(box, radius=r, fill=PARCH, outline=GOLD_D, width=2)


def button(d, box, label, active=False, f=None, sub=None):
    """Bouton : plaque de fer biseautée, filet doré ; actif = rouge sang."""
    x0, y0, x1, y1 = box
    base = BLOOD if active else IRON_L
    d.rounded_rectangle(box, radius=8, fill=base, outline=(14, 12, 12), width=3)
    d.line((x0 + 6, y0 + 4, x1 - 6, y0 + 4), fill=tuple(min(255, c + 40) for c in base), width=2)
    d.rounded_rectangle((x0 + 4, y0 + 4, x1 - 4, y1 - 4), radius=6, outline=GOLD_D, width=1)
    cy = (y0 + y1) / 2 - (10 if sub else 0)
    text_c(d, ((x0 + x1) / 2, cy), label, f or title_font(24), (244, 226, 186))
    if sub:
        text_c(d, ((x0 + x1) / 2, cy + 26), sub, font(16), TXT_D)


def bar(d, x, y, w, h, frac, color):
    d.rectangle((x, y, x + w, y + h), fill=(20, 18, 18), outline=GOLD_D, width=1)
    if frac > 0:
        d.rectangle((x + 2, y + 2, x + 2 + int((w - 4) * frac), y + h - 2), fill=color)
        d.line((x + 2, y + 3, x + 2 + int((w - 4) * frac), y + 3), fill=tuple(min(255, c + 50) for c in color), width=1)


def round_icon(d, cx, cy, r, glyph, fill=IRON_L):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=GOLD, width=3)
    glyph(d, cx, cy, r)


# --- glyphes dessinés (pas de police d'icônes) -----------------------------------------
def g_cloche(d, cx, cy, r):
    s = r * 0.55
    d.pieslice((cx - s, cy - s * 1.1, cx + s, cy + s * 0.9), 180, 360, fill=GOLD)
    d.polygon([(cx - s, cy - s * 0.1), (cx + s, cy - s * 0.1), (cx + s * 1.2, cy + s * 0.6), (cx - s * 1.2, cy + s * 0.6)], fill=GOLD)
    d.ellipse((cx - s * 0.25, cy + s * 0.55, cx + s * 0.25, cy + s * 1.0), fill=GOLD)


def g_engrenage(d, cx, cy, r):
    s = r * 0.6
    for k in range(8):
        a = k * math.pi / 4
        d.line((cx, cy, cx + s * 1.15 * math.cos(a), cy + s * 1.15 * math.sin(a)), fill=GOLD, width=int(r * 0.32))
    d.ellipse((cx - s * 0.85, cy - s * 0.85, cx + s * 0.85, cy + s * 0.85), fill=GOLD)
    d.ellipse((cx - s * 0.35, cy - s * 0.35, cx + s * 0.35, cy + s * 0.35), fill=IRON_L)


def g_croix(d, cx, cy, r):
    s = r * 0.4
    d.line((cx - s, cy - s, cx + s, cy + s), fill=GOLD, width=4)
    d.line((cx - s, cy + s, cx + s, cy - s), fill=GOLD, width=4)


def g_epees(d, cx, cy, r):
    s = r * 0.6
    for sgn in (-1, 1):
        d.line((cx - sgn * s, cy + s, cx + sgn * s, cy - s), fill=(210, 214, 222), width=4)
        d.line((cx - sgn * s * 0.55 - s * 0.25, cy + s * 0.3, cx - sgn * s * 0.55 + s * 0.25, cy + s * 0.75), fill=GOLD, width=4)


def g_sac(d, cx, cy, r):
    s = r * 0.55
    d.ellipse((cx - s, cy - s * 0.6, cx + s, cy + s * 1.0), fill=GOLD)
    d.polygon([(cx - s * 0.4, cy - s * 0.6), (cx + s * 0.4, cy - s * 0.6), (cx + s * 0.6, cy - s * 1.1), (cx - s * 0.6, cy - s * 1.1)], fill=GOLD)
    d.line((cx - s * 0.5, cy - s * 0.6, cx + s * 0.5, cy - s * 0.6), fill=IRON, width=3)


def g_marteau(d, cx, cy, r):
    s = r * 0.6
    d.line((cx - s * 0.6, cy + s, cx + s * 0.4, cy - s * 0.4), fill=(160, 120, 70), width=5)
    d.polygon([(cx + s * 0.0, cy - s * 0.9), (cx + s * 0.9, cy - s * 0.0), (cx + s * 0.55, cy + s * 0.35), (cx - s * 0.35, cy - s * 0.55)], fill=(190, 194, 202))


def g_hache(d, cx, cy, r):
    s = r * 0.6
    d.line((cx - s * 0.6, cy + s, cx + s * 0.3, cy - s * 0.8), fill=(160, 120, 70), width=5)
    d.pieslice((cx - s * 0.2, cy - s * 1.1, cx + s * 1.0, cy + s * 0.1), 250, 70, fill=(190, 194, 202))


def g_drapeau(d, cx, cy, r):
    s = r * 0.6
    d.line((cx - s * 0.6, cy + s, cx - s * 0.6, cy - s), fill=(160, 120, 70), width=4)
    d.polygon([(cx - s * 0.6, cy - s), (cx + s * 0.8, cy - s * 0.6), (cx - s * 0.6, cy - s * 0.1)], fill=MOSS)


def g_lutin(d, cx, cy, r):
    s = r * 0.55
    d.ellipse((cx - s * 0.8, cy - s * 0.3, cx + s * 0.8, cy + s * 1.1), fill=STEEL)
    d.polygon([(cx - s * 0.85, cy), (cx + s * 0.85, cy), (cx + s * 0.2, cy - s * 1.3)], fill=BLOOD)


def g_parchemin(d, cx, cy, r):
    s = r * 0.6
    d.rectangle((cx - s * 0.7, cy - s * 0.8, cx + s * 0.7, cy + s * 0.8), fill=PARCH)
    for k in range(3):
        d.line((cx - s * 0.45, cy - s * 0.4 + k * s * 0.4, cx + s * 0.45, cy - s * 0.4 + k * s * 0.4), fill=INK, width=2)


def g_bloc(d, cx, cy, r):
    s = r * 0.6
    d.polygon([(cx, cy - s), (cx + s, cy - s * 0.5), (cx, cy), (cx - s, cy - s * 0.5)], fill=MOSS)
    d.polygon([(cx - s, cy - s * 0.5), (cx, cy), (cx, cy + s), (cx - s, cy + s * 0.5)], fill=(110, 80, 56))
    d.polygon([(cx + s, cy - s * 0.5), (cx, cy), (cx, cy + s), (cx + s, cy + s * 0.5)], fill=(84, 60, 42))


def g_zone(d, cx, cy, r):
    s = r * 0.6
    d.rectangle((cx - s, cy - s * 0.8, cx + s, cy + s * 0.8), outline=MOSS, width=4)
    d.rectangle((cx - s * 0.4, cy - s * 0.3, cx + s * 0.4, cy + s * 0.3), fill=AMBER)


def g_balance(d, cx, cy, r):  # gestion
    s = r * 0.6
    for i, h in enumerate((0.6, 1.1, 1.6)):
        d.rectangle((cx - s + i * s * 0.75, cy + s - h * s, cx - s * 0.5 + i * s * 0.75, cy + s), fill=(STEEL, MOSS, AMBER)[i])


def dim_background(img_path, size, blur=5, dark=0.5):
    bg = Image.open(img_path).convert("RGB").resize(size).filter(ImageFilter.GaussianBlur(blur))
    return Image.blend(bg, Image.new("RGB", size, (10, 8, 8)), dark)


def header(width, title, subtitle, h=140):
    img = Image.new("RGB", (width, h), (22, 18, 18))
    d = ImageDraw.Draw(img)
    d.line((0, h - 3, width, h - 3), fill=GOLD_D, width=3)
    text_c(d, (width / 2, 50), title, title_font(50), GOLD)
    text_c(d, (width / 2, 104), subtitle, font(24), TXT_D)
    return img


def stack(parts, bg=(22, 18, 18)):
    w = max(p.width for p in parts)
    out = Image.new("RGB", (w, sum(p.height for p in parts)), bg)
    y = 0
    for p in parts:
        out.paste(p, ((w - p.width) // 2, y))
        y += p.height
    return out


def circle_portrait(img, path, cx, cy, r):
    d = ImageDraw.Draw(img)
    d.ellipse((cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8), fill=GOLD_D)
    d.ellipse((cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), fill=GOLD)
    por = Image.open(path).convert("RGB").resize((2 * r, 2 * r))
    mask = Image.new("L", por.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, 2 * r - 1, 2 * r - 1), fill=255)
    img.paste(por, (cx - r, cy - r), mask)
