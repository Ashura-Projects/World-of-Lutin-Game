"""Outils Pillow communs : polices, couleurs de l'interface, panneaux, textes."""

from PIL import Image, ImageDraw, ImageFont

FONT_DIR = "/usr/share/fonts/truetype/dejavu/"

# Palette de l'interface (parchemin + bois sombre + accent bleu lutin)
PARCH = (246, 236, 212)
PARCH_D = (226, 210, 176)
WOOD = (92, 60, 36)
WOOD_L = (140, 96, 58)
INK = (52, 36, 24)
BLUE = (70, 140, 220)
GREEN = (96, 168, 72)
ORANGE = (232, 150, 50)
RED = (206, 70, 56)
BG = (250, 246, 236)


def font(size, bold=False, serif=False):
    name = ("DejaVuSerif" if serif else "DejaVuSans") + ("-Bold" if bold else "") + ".ttf"
    return ImageFont.truetype(FONT_DIR + name, size)


def text_c(d: ImageDraw.ImageDraw, xy, txt, f, fill=INK):
    """Texte centré sur xy."""
    b = d.textbbox((0, 0), txt, font=f)
    d.text((xy[0] - (b[2] - b[0]) / 2, xy[1] - (b[3] - b[1]) / 2 - b[1]), txt, font=f, fill=fill)


def panel(d, box, fill=PARCH, border=WOOD, r=18, w=5):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=border, width=w)


def bar(d, x, y, w, h, frac, color, back=(214, 200, 170)):
    d.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=back)
    if frac > 0:
        d.rounded_rectangle((x, y, x + max(h, int(w * frac)), y + h), radius=h // 2, fill=color)


def header(width, title, subtitle, h=150):
    img = Image.new("RGB", (width, h), WOOD)
    d = ImageDraw.Draw(img)
    text_c(d, (width / 2, 52), title, font(52, True, True), PARCH)
    text_c(d, (width / 2, 112), subtitle, font(28), PARCH_D)
    return img


def fit(im, w=None, h=None):
    if w and not h:
        h = round(im.height * w / im.width)
    if h and not w:
        w = round(im.width * h / im.height)
    return im.resize((w, h), Image.LANCZOS)


def stack(parts, bg=BG):
    w = max(p.width for p in parts)
    out = Image.new("RGB", (w, sum(p.height for p in parts)), bg)
    y = 0
    for p in parts:
        out.paste(p, ((w - p.width) // 2, y))
        y += p.height
    return out


def label_strip(width, items, h=70, f=None, fill=INK, bg=BG):
    """Bande de libellés centrés (un par colonne)."""
    img = Image.new("RGB", (width, h), bg)
    d = ImageDraw.Draw(img)
    f = f or font(30, True)
    cw = width / len(items)
    for i, t in enumerate(items):
        text_c(d, (cw * i + cw / 2, h / 2), t, f, fill)
    return img
