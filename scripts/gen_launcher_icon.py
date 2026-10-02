"""Generate launcher icon assets to match the badge shown on the login screen:
white circle, gold ring border, green `account_tree_rounded` glyph inside.
Run once, then `dart run flutter_launcher_icons` to regenerate platform icons.
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
GREEN = (0x2E, 0x53, 0x39, 255)   # _kGreen1
GOLD = (0xC8, 0xA2, 0x4A, 255)    # _kGold
WHITE = (255, 255, 255, 255)

FONT_PATH = r"D:\Flutter_SDK\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf"
ACCOUNT_TREE_ROUNDED = chr(0xf523)

CIRCLE_D = int(SIZE * 0.62)          # diameter of white badge circle
RING_W = int(CIRCLE_D * 2.5 / 92)    # same ratio as login screen Container border
ICON_SIZE = int(CIRCLE_D * 46 / 92)  # same ratio as login screen icon vs circle


def draw_badge(canvas: Image.Image):
    draw = ImageDraw.Draw(canvas)
    cx, cy = SIZE // 2, SIZE // 2
    r = CIRCLE_D // 2
    bbox = (cx - r, cy - r, cx + r, cy + r)
    draw.ellipse(bbox, fill=WHITE, outline=GOLD, width=RING_W)

    font = ImageFont.truetype(FONT_PATH, ICON_SIZE)
    draw.text((cx, cy), ACCOUNT_TREE_ROUNDED, font=font, fill=GREEN, anchor="mm")


def make_logo():
    """Legacy Android/base icon: rounded-square green background, badge centered, transparent corners."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    radius = int(SIZE * 0.19)
    draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=radius, fill=GREEN)
    draw_badge(im)
    im.save("assets/images/logo.png")


def make_logo_foreground():
    """Adaptive icon foreground: badge only, transparent background, within safe zone."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_badge(im)
    im.save("assets/images/logo_foreground.png")


def make_logo_ios():
    """iOS icon: full-bleed opaque square (iOS applies its own corner rounding)."""
    im = Image.new("RGB", (SIZE, SIZE), GREEN[:3])
    im_rgba = im.convert("RGBA")
    draw_badge(im_rgba)
    im_rgba.convert("RGB").save("assets/images/logo_ios.png")


if __name__ == "__main__":
    make_logo()
    make_logo_foreground()
    make_logo_ios()
    print("Done.")
