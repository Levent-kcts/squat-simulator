"""Video için şeffaf yazı katmanları ve kapanış kartı (1920x1080)."""
import os
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

S = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Versions\version-4f087c32742644ab\content\fonts")
BIG = os.path.join(FONTS, "LuckiestGuy-Regular.ttf")
W, H = 1920, 1080
YELLOW, WHITE, BLACK = (255, 216, 60, 255), (255, 255, 255, 255), (18, 14, 30, 255)


def text(d, xy, s, size, fill=YELLOW):
    font = ImageFont.truetype(BIG, size)
    st = max(6, size // 9)
    x, y = xy
    d.text((x + size // 18, y + size // 14), s, font=font, fill=(0, 0, 0, 255), anchor="mm", stroke_width=st, stroke_fill=(0, 0, 0, 255))
    d.text((x, y), s, font=font, fill=fill, anchor="mm", stroke_width=st, stroke_fill=BLACK)


def overlay(name, lines):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for xy, s, size, fill in lines:
        text(d, xy, s, size, fill)
    im.save(os.path.join(S, name))


overlay("ov_hook.png", [((W // 2, 130), "SMASH WALLS!", 170, YELLOW)])
overlay("ov_lvl1.png", [((W // 2, 130), "LVL 1", 170, WHITE)])
overlay("ov_lvl200.png", [((W // 2, 130), "LVL 200", 170, YELLOW), ((W // 2, H - 110), "+1 SQUAT = BIGGER LEGS", 92, WHITE)])
overlay("ov_walls.png", [((W // 2, 130), "BREAK 100 WALLS", 150, YELLOW)])
overlay("ov_pets.png", [((W // 2, H - 120), "HATCH EPIC PETS!", 140, YELLOW)])

# Kapanış kartı
bg = Image.open(os.path.join(S, "cmp_big.png")).convert("RGB").crop((298, 0, 1621, 744)).resize((W, H), Image.LANCZOS)
bg = ImageEnhance.Color(bg).enhance(1.3)
bg = ImageEnhance.Brightness(bg.filter(ImageFilter.GaussianBlur(6)), ).enhance(0.6)
card = bg.convert("RGBA")
d = ImageDraw.Draw(card)
text(d, (W // 2, 300), "+1 SQUAT EVOLUTION", 150, YELLOW)
text(d, (W // 2, 450), "SMASH WALLS!", 120, WHITE)
d.rounded_rectangle((W // 2 - 330, 600, W // 2 + 330, 760), 40, fill=(70, 205, 80, 255), outline=BLACK, width=10)
text(d, (W // 2, 683), "PLAY NOW", 110, WHITE)
text(d, (W // 2, 900), "CODE: SPOOKY", 80, YELLOW)
card.convert("RGB").save(os.path.join(S, "endcard.png"))
print("ok")
