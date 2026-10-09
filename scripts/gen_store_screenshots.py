"""Susun screenshot listing Play Store (1080x1920) dari tangkapan mentah di
playstore/screenshots/raw -> playstore/screenshots/store."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

RAW, OUT = 'playstore/screenshots/raw', 'playstore/screenshots/store'
W, H = 1080, 1920
G0, G1, G2, GOLD = (16, 30, 21), (46, 83, 57), (70, 122, 84), (200, 162, 74)
BOLD = 'C:/Windows/Fonts/segoeuib.ttf'
REG = 'C:/Windows/Fonts/segoeui.ttf'
CROP_TOP, CROP_BOTTOM = 82, 130  # buang status bar & tombol navigasi sistem

SAMARKAN = {'06-akun.png': (280, 415, 720, 468)}

ITEMS = [
    ('01-login.png', 'Tarombo Marga Silaen', 'Silsilah keluarga dalam genggaman Anda'),
    ('02-beranda.png', 'Semua dalam satu beranda', 'Profil keluarga, partuturan, usulan, hingga arsip'),
    ('03-kerabat-terdekat.png', 'Temukan kerabat terdekat', 'Berbagi lokasi sepenuhnya atas pilihan Anda'),
    ('05-arsip.png', 'Arsip keluarga terjaga', 'Foto, dokumen, dan naskah warisan leluhur'),
    ('06-akun.png', 'Privasi di tangan Anda', 'Kelola akun dan ajukan penghapusan kapan saja'),
]


def latar():
    bg = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        a, b, u = (G0, G1, t / 0.55) if t < 0.55 else (G1, G2, (t - 0.55) / 0.45)
        d.line([(0, y), (W, y)], fill=tuple(int(a[k] + (b[k] - a[k]) * u) for k in range(3)))
    # tekstur Danau Toba di-tint hijau, memudar ke atas
    toba = ImageOps.grayscale(Image.open('assets/images/toba.png').convert('RGB'))
    toba = ImageOps.fit(toba, (W, 900))
    tint = ImageOps.colorize(toba, G0, (150, 200, 160))
    mask = Image.linear_gradient('L').resize((W, 900)).point(lambda v: int(v * 0.42))
    bg.paste(tint, (0, H - 900), mask)
    # cahaya lembut di belakang ponsel + cincin emas dekoratif
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([90, 520, W - 90, 1500], fill=(190, 230, 195, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    bg.paste(glow, (0, 0), glow)
    ring = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse([760, -240, 1320, 320], outline=GOLD + (120,), width=4)
    rd.ellipse([830, -170, 1250, 250], outline=GOLD + (60,), width=2)
    rd.ellipse([-260, 1500, 240, 2000], outline=GOLD + (90,), width=4)
    bg.paste(ring, (0, 0), ring)
    return bg


def tulis(d, teks, font, y, warna, maks):
    kata, baris, cur = teks.split(), [], ''
    for k in kata:
        uji = (cur + ' ' + k).strip()
        if d.textlength(uji, font=font) > maks and cur:
            baris.append(cur); cur = k
        else:
            cur = uji
    baris.append(cur)
    tinggi = int(font.size * 1.15)
    for b in baris:
        d.text((W / 2, y), b, font=font, fill=warna, anchor='mt')
        y += tinggi
    return y


def susun(i, berkas, judul, sub):
    img = latar()
    d = ImageDraw.Draw(img)
    # label emas kecil
    f_tag = ImageFont.truetype(BOLD, 30)
    tag = 'T A R O M B O'
    tw = d.textlength(tag, font=f_tag)
    d.rounded_rectangle([W / 2 - tw / 2 - 28, 92, W / 2 + tw / 2 + 28, 150], radius=29, outline=GOLD, width=3)
    d.text((W / 2, 121), tag, font=f_tag, fill=GOLD, anchor='mm')
    y = tulis(d, judul, ImageFont.truetype(BOLD, 78), 190, (255, 255, 255), W - 140)
    tulis(d, sub, ImageFont.truetype(REG, 38), y + 14, (214, 229, 218), W - 180)

    scr = Image.open(os.path.join(RAW, berkas)).convert('RGB')
    if berkas in SAMARKAN:  # tutup data pribadi (email akun) dengan warna latar kartunya
        x0, y0, x1, y1 = SAMARKAN[berkas]
        ImageDraw.Draw(scr).rectangle([x0, y0, x1, y1], fill=scr.getpixel((x1 + 60, (y0 + y1) // 2)))
    scr = scr.crop((0, CROP_TOP, scr.width, scr.height - CROP_BOTTOM))
    sw = 640
    sh = int(scr.height * sw / scr.width)
    scr = scr.resize((sw, sh), Image.LANCZOS)
    bz = 18  # tebal bingkai ponsel
    px, py = (W - sw) // 2 - bz, 520
    pw, ph = sw + bz * 2, sh + bz * 2
    bayang = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(bayang).rounded_rectangle([px + 10, py + 34, px + pw + 10, py + ph + 34], radius=74, fill=(0, 0, 0, 150))
    bayang = bayang.filter(ImageFilter.GaussianBlur(34))
    img.paste(bayang, (0, 0), bayang)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([px, py, px + pw, py + ph], radius=74, fill=(14, 18, 15))
    d.rounded_rectangle([px, py, px + pw, py + ph], radius=74, outline=(92, 104, 96), width=3)
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=58, fill=255)
    img.paste(scr, (px + bz, py + bz), mask)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, f'{i:02d}-store.png'), optimize=True)


if __name__ == '__main__':
    for f in os.listdir(OUT) if os.path.isdir(OUT) else []:
        os.remove(os.path.join(OUT, f))
    for i, it in enumerate(ITEMS, 1):
        susun(i, *it)
    # lembar kontak untuk pratinjau cepat
    files = sorted(os.listdir(OUT))
    sheet = Image.new('RGB', (len(files) * 380 + 20, 700), (240, 240, 240))
    for n, f in enumerate(files):
        sheet.paste(Image.open(os.path.join(OUT, f)).resize((360, 640), Image.LANCZOS), (20 + n * 380, 30))
    sheet.save('playstore/screenshots/_pratinjau.png')
    print('selesai', files)
