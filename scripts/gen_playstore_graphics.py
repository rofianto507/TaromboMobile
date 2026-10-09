"""Generate Play Store graphics: icon 512x512 and feature graphic 1024x500.
Kombinasi badge logo (lingkaran putih + cincin emas + ikon pohon) dengan
foto rumah adat (assets/images/rumah.png) yang di-tint hijau.
Run dari root proyek: python scripts/gen_playstore_graphics.py
Output: playstore/graphics/
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

sys.path.insert(0, os.path.dirname(__file__))
import gen_launcher_icon as g  # noqa: E402

OUT = "playstore/graphics"
os.makedirs(OUT, exist_ok=True)
BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
REG = r"C:\Windows\Fonts\segoeui.ttf"
G0, G1 = (16, 30, 21), (46, 83, 57)
GOLD = g.GOLD[:3]


def rumah_hijau(box, size, terang=(165, 205, 172)):
    """Potong rumah.png lalu warnai jadi duotone hijau (gelap -> terang)."""
    im = Image.open("assets/images/rumah.png").convert("RGB").crop(box)
    im = ImageOps.grayscale(im.resize(size, Image.LANCZOS))
    im = ImageOps.autocontrast(im, cutoff=2)
    return ImageOps.colorize(im, G0, terang)


def badge(im, cx, cy, r, ring):
    """Badge logo dengan bayangan lembut."""
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((cx - r, cy - r + r // 8, cx + r, cy + r + r // 8), fill=(0, 0, 0, 150))
    im.paste(sh.filter(ImageFilter.GaussianBlur(r // 5)), (0, 0), sh.filter(ImageFilter.GaussianBlur(r // 5)))
    d = ImageDraw.Draw(im)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255), outline=GOLD, width=ring)
    d.text((cx, cy), g.ACCOUNT_TREE_ROUNDED, font=ImageFont.truetype(g.FONT_PATH, int(r * 1.05)),
           fill=G1, anchor="mm")


def icon_512():
    # Play menerapkan sudut membulat sendiri: kirim persegi penuh tanpa alpha.
    s = 1024  # kerjakan 2x lalu perkecil supaya tepi halus
    im = rumah_hijau((0, 60, 736, 796), (s, s), terang=(120, 165, 130))
    # gelapkan merata + vignette supaya badge tetap jadi fokus
    im = Image.blend(im, Image.new("RGB", (s, s), G1), 0.35)
    vig = Image.new("L", (s, s), 0)
    ImageDraw.Draw(vig).ellipse((-s * 0.15, -s * 0.15, s * 1.15, s * 1.15), fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(s // 6))
    im = Image.composite(im, Image.new("RGB", (s, s), G0), vig)
    badge(im, s // 2, s // 2, int(s * 0.30), 18)
    im.resize((512, 512), Image.LANCZOS).save(f"{OUT}/ikon-512.png", optimize=True)


def feature_1024x500():
    w, h = 1024, 500
    im = Image.new("RGB", (w, h), G1)
    d = ImageDraw.Draw(im)
    for x in range(w):  # gradasi dasar kiri (gelap) -> kanan
        t = x / (w - 1)
        d.line([(x, 0), (x, h)], fill=tuple(int(G0[i] + (G1[i] - G0[i]) * t) for i in range(3)))
    # rumah adat di sisi kanan, memudar ke kiri
    rw = 640
    foto = rumah_hijau((0, 90, 736, 90 + int(736 * h / rw)), (rw, h))
    mask = Image.linear_gradient("L").rotate(90, expand=True).resize((rw, h)).point(
        lambda v: int(min(255, v * 1.5) * 0.85))
    im.paste(foto, (w - rw, 0), mask)
    # cincin emas dekoratif
    ring = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse((-170, -210, 250, 210), outline=GOLD + (90,), width=3)
    rd.ellipse((790, 300, 1210, 720), outline=GOLD + (110,), width=3)
    im.paste(ring, (0, 0), ring)

    badge(im, 170, h // 2, 108, 7)
    d = ImageDraw.Draw(im)
    d.text((316, 196), "TAROMBO", font=ImageFont.truetype(BOLD, 86), fill=(255, 255, 255), anchor="lm")
    d.line((320, 254, 470, 254), fill=GOLD, width=5)
    d.text((318, 298), "Silsilah Marga Silaen", font=ImageFont.truetype(REG, 38),
           fill=(232, 240, 233), anchor="lm")
    d.text((318, 346), "Telusuri tarombo  \u2022  Kenali kerabat", font=ImageFont.truetype(REG, 26),
           fill=(200, 215, 205), anchor="lm")
    im.save(f"{OUT}/feature-graphic-1024x500.png", optimize=True)


if __name__ == "__main__":
    icon_512()
    feature_1024x500()
    for f in sorted(os.listdir(OUT)):
        p = os.path.join(OUT, f)
        i = Image.open(p)
        print(f, i.size, i.mode, os.path.getsize(p) // 1024, "KB")
