"""Oyun içi karelerden 1920x1080 küçük resimler üretir (Roblox oyun sayfası)."""
import os, sys
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
FONTS = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Versions\version-4f087c32742644ab\content\fonts")
BIG = os.path.join(FONTS, "LuckiestGuy-Regular.ttf")
W, H = 1920, 1080
YELLOW = (255, 216, 60)
WHITE = (255, 255, 255)
BLACK = (18, 14, 30)


def load(name):
    return Image.open(os.path.join(S, name)).convert("RGB")


def grade(im, contrast=1.14, color=1.28, bright=0.94):
    im = ImageEnhance.Contrast(im).enhance(contrast)
    im = ImageEnhance.Color(im).enhance(color)
    im = ImageEnhance.Brightness(im).enhance(bright)
    return im.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))


def fit(im, box):  # box: (x0, y0, x1, y1) kaynakta, hedef W x H
    return im.crop(box).resize((W, H), Image.LANCZOS)


def text(draw, xy, s, size, fill=YELLOW, anchor="mm", stroke=None, rotate=0, base=None):
    font = ImageFont.truetype(BIG, size)
    stroke = stroke or max(6, size // 9)
    x, y = xy
    # gölge
    draw.text((x + size // 18, y + size // 14), s, font=font, fill=(0, 0, 0), anchor=anchor, stroke_width=stroke, stroke_fill=(0, 0, 0))
    draw.text((x, y), s, font=font, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=BLACK)


def vignette(im, strength=0.45):
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    for i in range(40):
        d.rectangle((i * 12, i * 7, W - i * 12, H - i * 7), fill=int(255 * (i / 40)))
    mask = mask.filter(ImageFilter.GaussianBlur(60))
    dark = Image.new("RGB", (W, H), (20, 10, 40))
    return Image.composite(im, Image.blend(im, dark, strength), mask)


def save(im, name):
    path = os.path.join(OUT, name)
    im.save(path, "PNG", optimize=True)
    print(path)


os.makedirs(OUT, exist_ok=True)

# 1) DUVAR KIRMA
im = vignette(grade(fit(load("f_smash_21.0.png"), (300, 0, 1620, 742))), 0.35)
d = ImageDraw.Draw(im)
text(d, (W // 2, 120), "SMASH 100 WALLS!", 150)
text(d, (W // 2, H - 95), "KICK THROUGH 20 BRICK WORLDS", 70, fill=WHITE)
save(im, "thumb_1_smash_walls.png")

# 2) LEVEL 1 > LEVEL 200 (aynı kamera, sabit uzaklık)
left = grade(load("cmp_small.png").crop((615, 0, 1276, 744)).resize((W // 2, H), Image.LANCZOS))
right = grade(load("cmp_big.png").crop((630, 0, 1291, 744)).resize((W // 2, H), Image.LANCZOS))
im = Image.new("RGB", (W, H))
im.paste(ImageEnhance.Color(left).enhance(0.75), (0, 0))
im.paste(right, (W // 2, 0))
im = vignette(im, 0.3)
d = ImageDraw.Draw(im)
d.rectangle((W // 2 - 7, 0, W // 2 + 7, H), fill=BLACK)
d.rectangle((W // 2 - 3, 0, W // 2 + 3, H), fill=WHITE)
# ok
cx, cy = W // 2, H // 2 + 60
d.polygon([(cx - 95, cy - 45), (cx + 15, cy - 45), (cx + 15, cy - 95), (cx + 115, cy), (cx + 15, cy + 95), (cx + 15, cy + 45), (cx - 95, cy + 45)], fill=YELLOW, outline=BLACK, width=10)
text(d, (W // 4, 120), "LVL 1", 150, fill=WHITE)
text(d, (3 * W // 4, 120), "LVL 200", 150)
text(d, (W // 2, H - 90), "+1 SQUAT = BIGGER LEGS", 92, fill=WHITE)
save(im, "thumb_2_level1_vs_200.png")

# 3) YUMURTA: EPIC
frame = load("f_hatch_5.6.png")
bg = grade(fit(frame, (296, 0, 1616, 742))).filter(ImageFilter.GaussianBlur(14))
bg = ImageEnhance.Brightness(bg).enhance(0.55)
panel = grade(frame.crop((625, 95, 1290, 560)), contrast=1.08, color=1.2, bright=1.12)
scale = 1.52
panel = panel.resize((int(panel.width * scale), int(panel.height * scale)), Image.LANCZOS)
im = bg.copy()
px, py = (W - panel.width) // 2, 175
glow = Image.new("RGB", (W, H), (190, 90, 255))
gmask = Image.new("L", (W, H), 0)
ImageDraw.Draw(gmask).rounded_rectangle((px - 30, py - 30, px + panel.width + 30, py + panel.height + 30), 50, fill=200)
im = Image.composite(glow, im, gmask.filter(ImageFilter.GaussianBlur(40)))
im.paste(panel, (px, py))
d = ImageDraw.Draw(im)
text(d, (W // 2, 95), "HATCH 30 PETS!", 140)
text(d, (W // 2, H - 85), "6 EGGS  •  MERGE INTO BOSS PETS", 66, fill=WHITE)
save(im, "thumb_3_hatch_pets.png")

# 4) DEV KARAKTER
im = vignette(grade(fit(load("cmp_big.png"), (298, 0, 1621, 744))), 0.35)
d = ImageDraw.Draw(im)
text(d, (W // 2, 110), "SQUAT. GROW. SMASH!", 140)
text(d, (W // 2, H - 90), "BECOME THE STRONGEST LEGS", 76, fill=WHITE)
save(im, "thumb_4_giant.png")
