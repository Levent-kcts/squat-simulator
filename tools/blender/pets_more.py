"""17 yeni pet (her yumurtaya ÖZEL havuz için): kutu pet üslubu pets.py ile aynıdır (yuvarlatılmış küp gövde-baş, öne bakan düz yüz, küçük ayaklar).
Yumurta -> petler (Config.Eggs, her pet SADECE bir yumurtadan çıkar):
  starter: cat dog bunny + chick hamster        forest: fox panda + deer owl frog        desert: tiger + lion camel scorpion snake
  ice: wolf + penguin seal polarbear yeti       lava: dragon phoenix + salamander lavacrab golem        galaxy: unicorn robot galaxy titan + alien
Bu dosya SADECE yeni 17 pet'i tutar (ilk 13 pets.py'de). Çalıştırma:
    blender -b -P tools/blender/pets_more.py              (hepsi)
    blender -b -P tools/blender/pets_more.py -- lion owl  (seçilenler)
Çıktı: assets/blender/fbx/pet_<id>.fbx, textures/, previews/pets_more_lineup.png, blend/pets_more.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
import pets as P  # noqa: E402
from lib import Model, darker, lighter, mix, record_manifest  # noqa: E402

W, D, H = P.W, P.D, P.H
CZ, TOP, FRONT, BACK = P.CZ, P.TOP, P.FRONT, P.BACK
BLACK, WHITE, PINK, CREAM = P.BLACK, P.WHITE, P.PINK, P.CREAM
ORANGE = (255, 150, 40)
RED = (230, 60, 70)
YELLOW = (255, 225, 90)


# ------------------------------------------------------------------ yumurta 1 (starter)
def chick(m, C):
    P.base(m, C, feet=ORANGE)
    m.cone((0, FRONT + 0.28, CZ - 0.1), 0.27, 0.04, 0.58, ORANGE, rot=(-90, 0, 0), verts=6, name="Beak")
    m.cone((0, FRONT + 0.2, CZ - 0.34), 0.19, 0.03, 0.4, darker(ORANGE, 0.12), rot=(-90, 0, 0), verts=6, name="BeakLow")
    P.eyes(m, "bead", size=1.0, dz=0.22)
    P.cheeks(m, (255, 160, 130), 0.86)
    for x, h in ((-0.22, 0.55), (0.0, 0.8), (0.22, 0.55)):  # tepede tüy tutamı
        m.cone((x, 0.05, TOP + h / 2 - 0.08), 0.14, 0.02, h, C, rot=(0, -x * 45, 0), verts=5, name="Tuft")
    for s in (-1, 1):  # küçük kanatlar
        m.ball((1.08 * s, -0.05, CZ - 0.1), (0.2, 0.55, 0.62), darker(C, 0.12), rot=(0, 0, 10 * s), name="Wing")
    for x in (-0.25, 0.0, 0.25):  # kuyruk tüyleri
        m.cone((x, BACK - 0.12, 0.85), 0.14, 0.02, 0.5, C, rot=(60, 0, -x * 40), verts=5, name="TailFeather")


def hamster(m, C):
    P.base(m, C)
    P.ears_round(m, C, inner=PINK, spread=0.8, size=0.3)
    m.ball((0, FRONT - 0.2, TOP - 0.28), (0.34, 0.34, 0.12), darker(C, 0.18), seg=12, rings=6, name="Blaze")  # alında koyu leke
    m.ball((0, FRONT - 0.05, CZ - 0.34), (0.66, 0.22, 0.4), CREAM, seg=14, rings=8, name="Muzzle")
    for s in (-1, 1):  # şişkin yanaklar
        m.ball((0.8 * s, FRONT - 0.12, CZ - 0.22), (0.4, 0.3, 0.34), lighter(C, 0.4), name="CheekPouch")
    P.eyes(m, "bead", size=1.0, dz=0.18)
    P.nose(m, PINK, -0.2, 1.1)
    m.box((0, FRONT + 0.02, CZ - 0.5), (0.18, 0.05, 0.2), WHITE, bevel=0.02, name="Tooth")
    P.cheeks(m, PINK, 0.92, -0.18, 0.8)
    P.tail_ball(m, lighter(C, 0.3), 0.2)


# ------------------------------------------------------------------ yumurta 2 (forest)
def deer(m, C):
    brown = darker(C, 0.35)
    P.base(m, C)
    for s in (-1, 1):
        m.tube([(0.42 * s, 0, TOP - 0.1), (0.55 * s, 0, TOP + 0.5), (0.8 * s, 0, TOP + 0.95)], 0.08, brown, name="Antler")
        m.tube([(0.55 * s, 0, TOP + 0.45), (0.28 * s, 0.05, TOP + 0.85)], 0.06, brown, name="Antler")
        m.tube([(0.6 * s, 0, TOP + 0.62), (0.95 * s, 0.05, TOP + 0.62)], 0.06, brown, name="Antler")
        m.cone((1.0 * s, 0.0, TOP - 0.55), 0.3, 0.04, 0.85, C, rot=(0, 55 * s, 0), verts=4, name="Ear")
        m.cone((0.98 * s, 0.1, TOP - 0.55), 0.18, 0.03, 0.55, PINK, rot=(0, 55 * s, 0), verts=4, name="InnerEar")
    for x, y in ((-0.4, 0.3), (0.45, -0.1), (0.0, -0.45), (-0.3, -0.5)):  # sırtta beyaz benekler
        m.ball((x, y, TOP - 0.02), (0.09, 0.09, 0.04), WHITE, seg=8, rings=5, name="Spot")
    m.box((0, FRONT - 0.05, CZ - 0.4), (0.85, 0.4, 0.55), CREAM, bevel=0.14, segments=3, name="Muzzle")
    P.eyes(m, "bead", size=1.05, dz=0.18)
    P.nose(m, BLACK, -0.2, 1.2)
    P.mouth(m, BLACK, -0.44)
    P.cheeks(m, PINK, 0.9)
    m.ball((0, BACK - 0.1, CZ - 0.3), (0.3, 0.18, 0.3), WHITE, seg=10, rings=6, name="Tail")


def owl(m, C):
    P.base(m, C, feet=ORANGE)
    light = lighter(C, 0.55)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.62 * s, 0.0, TOP + 0.28), 0.22, 0.03, 0.62, dark, rot=(0, 14 * s, 0), verts=5, name="EarTuft")
        m.ball((0.5 * s, FRONT - 0.04, CZ + 0.12), (0.56, 0.08, 0.56), light, seg=16, rings=10, name="Disc")
        m.ball((0.5 * s, FRONT + 0.03, CZ + 0.12), (0.34, 0.08, 0.34), WHITE, seg=14, rings=8, name="Eye")
        m.ball((0.5 * s, FRONT + 0.09, CZ + 0.1), (0.2, 0.06, 0.2), BLACK, seg=12, rings=8, name="Pupil")
        m.ball((0.5 * s + 0.07, FRONT + 0.14, CZ + 0.18), (0.06, 0.04, 0.06), WHITE, seg=8, rings=5, name="Shine")
        m.ball((1.08 * s, -0.05, CZ - 0.15), (0.2, 0.6, 0.75), dark, rot=(0, 0, 8 * s), name="Wing")
    m.cone((0, FRONT + 0.14, CZ - 0.12), 0.17, 0.03, 0.36, (255, 190, 60), rot=(-90, 0, 0), verts=4, name="Beak")
    for row, z in enumerate((CZ - 0.5, CZ - 0.72)):  # göğüs tüyü deseni
        for x in (-0.36, 0.0, 0.36):
            m.box((x + 0.18 * (row % 2), FRONT - 0.03, z), (0.2, 0.05, 0.12), light, bevel=0.02, rot=(0, 0, 45), name="Feather")


def frog(m, C):
    P.base(m, C)
    belly = lighter(C, 0.55)
    dark = darker(C, 0.3)
    for s in (-1, 1):  # tepede çıkık gözler
        m.ball((0.56 * s, 0.35, TOP + 0.08), (0.4, 0.4, 0.36), C, seg=14, rings=8, name="EyeBump")
        m.ball((0.56 * s, 0.66, TOP + 0.1), (0.3, 0.1, 0.3), WHITE, seg=14, rings=8, name="Eye")
        m.ball((0.56 * s, 0.74, TOP + 0.08), (0.17, 0.06, 0.2), BLACK, seg=12, rings=8, name="Pupil")
        m.ball((0.56 * s + 0.06, 0.79, TOP + 0.16), (0.055, 0.04, 0.06), WHITE, seg=8, rings=5, name="Shine")
        m.box((1.0 * s, FRONT - 0.5, 0.2), (0.7, 0.9, 0.2), dark, bevel=0.06, rot=(0, 0, 8 * s), name="WebFoot")  # perdeli ayaklar
    m.box((0, FRONT - 0.02, CZ - 0.45), (1.1, 0.12, 0.6), belly, bevel=0.1, name="Belly")
    m.box((0, FRONT + 0.03, CZ - 0.24), (1.4, 0.05, 0.08), (40, 70, 40), bevel=0.02, name="Mouth")  # geniş ağız
    for s in (-1, 1):
        m.box((0.78 * s, FRONT + 0.03, CZ - 0.18), (0.26, 0.05, 0.08), (40, 70, 40), bevel=0.02, rot=(0, -32 * s, 0), name="MouthCorner")
    for s in (-1, 1):
        m.ball((0.12 * s, FRONT + 0.0, CZ - 0.06), (0.05, 0.04, 0.05), dark, seg=8, rings=5, name="Nostril")
    for x, y in ((-0.5, -0.3), (0.45, -0.45), (0.0, -0.1), (0.25, 0.1), (-0.3, 0.05)):  # sırtta koyu benekler
        m.ball((x, y, TOP - 0.02), (0.14, 0.14, 0.05), dark, seg=8, rings=5, name="Spot")
    P.cheeks(m, (255, 150, 160), 0.88, -0.28)


# ------------------------------------------------------------------ yumurta 3 (desert)
def lion(m, C):
    mane = (150, 85, 35)
    manelight = (190, 115, 50)
    P.base(m, C)
    m.box((0, -0.2, CZ + 0.02), (W + 0.95, D - 0.3, H + 0.95), mane, bevel=0.5, segments=3, name="Mane")
    for index in range(10):  # yele dış kenarında tutamlar
        a = index * math.tau / 10
        m.ball((math.cos(a) * 1.35, 0.2, CZ + math.sin(a) * 1.3), (0.34, 0.3, 0.34), manelight if index % 2 else mane, seg=10, rings=6, name="ManeTuft")
    P.ears_round(m, C, inner=PINK, spread=0.7, size=0.3)
    m.ball((0, FRONT - 0.05, CZ - 0.36), (0.55, 0.22, 0.38), CREAM, seg=14, rings=8, name="Muzzle")
    P.eyes(m, "bead", size=1.0, dz=0.16)
    P.nose(m, (150, 70, 60), -0.2, 1.2)
    P.mouth(m, BLACK, -0.44)
    P.whiskers(m)
    P.tail_curl(m, C, tip=mane)


def camel(m, C):
    dark = darker(C, 0.15)
    P.base(m, C)
    m.ball((0, -0.4, TOP + 0.15), (0.58, 0.52, 0.55), dark, seg=14, rings=8, name="Hump")
    m.ball((0, 0.4, TOP + 0.05), (0.46, 0.44, 0.45), dark, seg=14, rings=8, name="Hump")
    for s in (-1, 1):
        m.ball((1.04 * s, 0.05, TOP - 0.18), (0.24, 0.16, 0.28), dark, seg=10, rings=6, rot=(0, 0, 20 * s), name="Ear")
    m.ball((0, FRONT - 0.04, CZ - 0.36), (0.58, 0.28, 0.42), lighter(C, 0.45), seg=14, rings=8, name="Muzzle")
    for s in (-1, 1):
        m.box((0.2 * s, FRONT + 0.2, CZ - 0.24), (0.06, 0.04, 0.05), BLACK, bevel=0.01, name="Nostril")
    P.eyes(m, "bead", size=1.0, dz=0.2)
    for s in (-1, 1):  # kirpikler
        for k in (-1, 0, 1):
            m.box((0.5 * s + 0.1 * k * s, FRONT + 0.03, CZ + 0.44 + 0.1 * (1 - abs(k))), (0.04, 0.04, 0.12), BLACK, bevel=0.0, rot=(0, 18 * k, 0), name="Lash")
    P.mouth(m, BLACK, -0.5, 0.08, 0.18)
    P.cheeks(m, PINK, 0.86)
    P.tail_ball(m, dark, 0.22)


def scorpion(m, C):
    dark = darker(C, 0.35)
    P.base(m, C, feet=dark)
    for s in (-1, 1):  # kıskaçlar
        m.tube([(0.78 * s, FRONT - 0.25, CZ - 0.25), (1.05 * s, FRONT + 0.2, CZ - 0.2)], 0.14, C, name="Arm")
        m.cone((1.05 * s, FRONT + 0.55, CZ - 0.16), 0.3, 0.05, 0.7, C, rot=(-90, 0, 0), verts=6, scale=(1, 1, 0.55), name="Claw")
        m.cone((1.05 * s, FRONT + 0.5, CZ - 0.3), 0.18, 0.03, 0.5, dark, rot=(-90, 0, 0), verts=5, name="ClawTip")
        m.box((0.45 * s, 0.05, TOP + 0.02), (0.5, 0.35, 0.08), dark, bevel=0.03, name="Plate")
    P.eyes(m, "bead", size=1.0, dz=0.2)
    P.mouth(m, BLACK, -0.38)
    P.cheeks(m, (255, 160, 130), 0.88, -0.22)
    # kıvrık kuyruk: sırttan yukarı ve öne doğru, ucu iğne
    m.tube([(0, BACK + 0.1, 0.8), (0, BACK - 0.55, 1.3), (0, BACK - 0.5, 2.2), (0, -0.05, 3.0), (0, 0.55, 3.0)], 0.2, C, name="Tail")
    m.cone((0, 0.7, 2.9), 0.2, 0.02, 0.5, (255, 220, 90), rot=(-90, 0, 0), verts=5, name="Stinger")
    for k in range(4):  # kuyruk halkaları
        m.torus((0, BACK - 0.56 + 0.0, 1.35 + 0.28 * k), 0.17, 0.04, dark, rot=(0, 0, 0), major_seg=10, minor_seg=5, name="TailRing")


def snake(m, C):
    dark = darker(C, 0.35)
    belly = (240, 230, 160)
    P.base(m, C)
    for index, (r, z, col) in enumerate(((0.75, 0.35, C), (0.58, 0.8, darker(C, 0.12)), (0.42, 1.2, C))):  # arkada yığılmış bobin
        m.torus((0, BACK - 0.55, z), r, 0.3, col, rot=(0, 0, 0), major_seg=20, minor_seg=8, name="Coil")
    m.ball((0, BACK - 0.55, 1.5), (0.3, 0.3, 0.3), C, seg=10, rings=6, name="TailTip")
    for index, (y, s) in enumerate(((0.3, 1.0), (-0.1, 0.9), (-0.45, 0.8))):  # tepede baklava deseni
        m.box((0, y, TOP + 0.0), (0.34 * s, 0.34 * s, 0.05), dark, bevel=0.015, rot=(0, 0, 45), name="Diamond")
    m.box((0, FRONT - 0.03, CZ - 0.5), (0.95, 0.1, 0.4), belly, bevel=0.08, name="Chin")
    P.eyes(m, "slit", size=1.05, dz=0.2, iris=(255, 215, 70), color=BLACK)
    for s in (-1, 1):
        m.ball((0.1 * s, FRONT + 0.0, CZ - 0.12), (0.04, 0.04, 0.04), dark, seg=6, rings=4, name="Nostril")
    # çatallı dil
    m.box((0, FRONT + 0.3, CZ - 0.36), (0.1, 0.6, 0.05), RED, bevel=0.01, name="Tongue")
    for s in (-1, 1):
        m.box((0.08 * s, FRONT + 0.66, CZ - 0.36), (0.07, 0.24, 0.05), RED, bevel=0.01, rot=(0, 0, -22 * s), name="TongueFork")
    P.cheeks(m, (255, 150, 150), 0.88, -0.2)


# ------------------------------------------------------------------ yumurta 4 (ice)
def penguin(m, C):
    P.base(m, C, feet=ORANGE)
    m.ball((0, FRONT - 0.1, CZ - 0.44), (0.9, 0.16, 0.66), WHITE, seg=16, rings=10, name="Belly")
    for s in (-1, 1):
        m.ball((0.46 * s, FRONT - 0.05, CZ + 0.14), (0.45, 0.08, 0.5), WHITE, seg=14, rings=8, name="FaceWhite")
        m.ball((1.1 * s, -0.05, CZ - 0.15), (0.2, 0.55, 0.78), C, rot=(0, 0, 14 * s), name="Flipper")
    P.eyes(m, "bead", size=0.95, dz=0.16, spread=0.46)
    m.cone((0, FRONT + 0.18, CZ - 0.2), 0.22, 0.04, 0.42, ORANGE, rot=(-90, 0, 0), verts=6, name="Beak")
    P.cheeks(m, (255, 150, 150), 0.86, -0.22)
    P.tail_ball(m, darker(C, 0.2), 0.22)


def seal(m, C):
    belly = lighter(C, 0.55)
    P.base(m, C)
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.66, 0.24, 0.42), belly, seg=14, rings=8, name="Muzzle")
    P.eyes(m, "bead", size=1.2, dz=0.2)
    m.ball((0, FRONT + 0.14, CZ - 0.2), (0.18, 0.1, 0.12), BLACK, seg=10, rings=6, name="Nose")
    P.mouth(m, BLACK, -0.44, 0.1, 0.2)
    for s in (-1, 1):
        for k, tilt in enumerate((-12, 0, 12)):
            m.box((1.0 * s * 0.75, FRONT + 0.0, CZ - 0.36 + 0.07 * (1 - k)), (0.55, 0.03, 0.03), WHITE, bevel=0, rot=(0, 0, tilt * s), name="Whisker")
        m.ball((1.12 * s, 0.35, 0.65), (0.2, 0.55, 0.28), darker(C, 0.12), rot=(0, 0, -25 * s), name="Flipper")  # ön yüzgeç
        m.ball((0.45 * s, BACK - 0.35, 0.45), (0.3, 0.5, 0.18), darker(C, 0.12), rot=(0, 0, 25 * s), name="TailFlipper")
    P.cheeks(m, PINK, 0.88, -0.2)


def polarbear(m, C):
    P.base(m, C, feet=darker(C, 0.12))
    P.ears_round(m, C, inner=(220, 200, 205), spread=0.78, size=0.38)
    m.ball((0, FRONT - 0.04, CZ - 0.34), (0.5, 0.2, 0.34), (225, 230, 245), seg=14, rings=8, name="Muzzle")
    P.eyes(m, "bead", size=0.95, dz=0.16)
    m.ball((0, FRONT + 0.1, CZ - 0.24), (0.17, 0.1, 0.11), BLACK, seg=10, rings=6, name="Nose")
    P.mouth(m, BLACK, -0.46)
    P.cheeks(m, (255, 170, 190), 0.9, -0.26)
    P.tail_ball(m, WHITE, 0.28)


def yeti(m, C):
    face = (120, 175, 225)
    fur = lighter(C, 0.5)
    P.base(m, C, feet=darker(C, 0.15))
    for index in range(9):  # yüzün çevresinde sert tüy dikenleri
        a = math.pi * 0.05 + index * math.pi * 0.9 / 8
        m.cone((math.cos(a) * 1.0, 0.25, CZ + 0.1 + math.sin(a) * 0.95), 0.2, 0.02, 0.6, fur, rot=(0, 90 - math.degrees(a), 0), verts=5, name="FurSpike")
    m.ball((0, FRONT - 0.05, CZ - 0.02), (0.82, 0.18, 0.7), face, seg=16, rings=10, name="Face")
    for s in (-1, 1):
        m.cone((0.62 * s, 0.0, TOP + 0.18), 0.18, 0.03, 0.5, WHITE, rot=(0, 16 * s, 0), verts=5, name="Horn")
        m.cone((0.3 * s, FRONT + 0.0, CZ - 0.5), 0.1, 0.02, 0.3, WHITE, rot=(180, 0, 0), verts=4, name="Tusk")
        m.box((0.5 * s, FRONT + 0.06, CZ + 0.46), (0.5, 0.07, 0.12), darker(C, 0.35), bevel=0.02, rot=(0, -16 * s, 0), name="Brow")
    P.eyes(m, "bead", size=1.0, dz=0.18)
    m.box((0, FRONT + 0.06, CZ - 0.38), (0.6, 0.05, 0.1), (60, 70, 110), bevel=0.02, name="Mouth")
    P.nose(m, (60, 70, 110), -0.18, 1.2)
    P.cheeks(m, (255, 170, 200), 0.85, -0.3)
    P.tail_ball(m, fur, 0.3)


# ------------------------------------------------------------------ yumurta 5 (lava)
def salamander(m, C):
    dark = (70, 30, 25)
    fire = (255, 220, 70)
    P.base(m, C, feet=darker(C, 0.2))
    for x, y in ((-0.5, 0.2), (0.45, -0.2), (0.0, 0.4), (-0.2, -0.45), (0.6, 0.45)):
        m.ball((x, y, TOP - 0.02), (0.15, 0.15, 0.05), dark, seg=8, rings=5, name="Spot")
    for index, (y, h) in enumerate(((0.45, 0.4), (0.0, 0.55), (-0.45, 0.4))):  # sırtta ateş yelesi
        m.cone((0, y, TOP + h / 2 - 0.08), 0.18, 0.02, h, fire if index % 2 == 0 else (255, 160, 50), rot=(0, 0, 45), verts=4, name="Crest")
    for s in (-1, 1):  # solungaç püskülleri
        for k, z in enumerate((CZ + 0.3, CZ, CZ - 0.3)):
            m.cone((1.08 * s, 0.1, z), 0.1, 0.02, 0.45, (255, 110, 120), rot=(0, 90 * s, 12 * (k - 1) * s), verts=4, name="Frill")
    P.eyes(m, "white", size=1.2, dz=0.2, iris=BLACK)
    m.box((0, FRONT + 0.01, CZ - 0.36), (0.95, 0.05, 0.08), dark, bevel=0.02, name="Mouth")
    for s in (-1, 1):
        m.box((0.5 * s, FRONT + 0.01, CZ - 0.3), (0.26, 0.05, 0.08), dark, bevel=0.02, rot=(0, -30 * s, 0), name="MouthCorner")
    P.cheeks(m, fire, 0.86, -0.25)
    P.tail_curl(m, C, tip=fire)


def lavacrab(m, C):
    dark = darker(C, 0.4)
    glow = (255, 205, 70)
    P.base(m, C, feet=dark)
    m.ball((0, 0.0, TOP - 0.05), (1.0, 0.88, 0.32), dark, seg=16, rings=8, name="Shell")  # kabuk
    for x, y, rot in ((-0.4, 0.2, 20), (0.35, -0.1, -15), (0.0, -0.4, 60), (0.3, 0.45, 80)):  # parlayan lav çatlakları
        m.box((x, y, TOP + 0.22), (0.5, 0.06, 0.04), glow, bevel=0.01, rot=(0, 0, rot), name="Crack")
    for s in (-1, 1):
        m.tube([(0.7 * s, FRONT - 0.3, CZ - 0.3), (1.15 * s, FRONT + 0.1, CZ - 0.15)], 0.15, C, name="Arm")
        m.ball((1.25 * s, FRONT + 0.3, CZ - 0.1), (0.48, 0.4, 0.4), C, seg=14, rings=8, name="Claw")
        m.box((1.25 * s, FRONT + 0.7, CZ - 0.08), (0.12, 0.3, 0.34), dark, bevel=0.03, name="ClawGap")
        m.tube([(0.35 * s, 0.25, TOP - 0.1), (0.4 * s, 0.4, TOP + 0.6)], 0.07, C, name="EyeStalk")
        m.ball((0.4 * s, 0.4, TOP + 0.68), (0.2, 0.2, 0.2), WHITE, seg=12, rings=8, name="Eye")
        m.ball((0.4 * s, 0.56, TOP + 0.68), (0.1, 0.07, 0.1), BLACK, seg=8, rings=5, name="Pupil")
        for k in range(3):  # yan bacaklar
            m.tube([(1.0 * s, -0.4 + 0.4 * k, 0.8), (1.3 * s, -0.4 + 0.4 * k, 0.4), (1.35 * s, -0.4 + 0.4 * k, 0.1)], 0.07, dark, name="Leg")
    P.eyes(m, "bead", size=0.8, dz=0.0, spread=0.0)
    P.mouth(m, BLACK, -0.4)
    P.cheeks(m, glow, 0.86, -0.22)


def golem(m, C):
    dark = darker(C, 0.35)
    glow = (255, 150, 40)
    P.base(m, C, feet=dark)
    for x, y, s, r in ((-0.5, 0.2, 0.45, 20), (0.35, -0.25, 0.5, -15), (0.0, 0.35, 0.36, 35), (-0.25, -0.5, 0.4, 5)):  # kafada kaya parçaları
        m.box((x, y, TOP + 0.1), (s, s, s * 0.9), lighter(C, 0.12) if r > 0 else dark, bevel=0.06, rot=(r, r * 0.6, r), name="Rock")
    for s in (-1, 1):  # yan çıkıntılar
        m.box((1.12 * s, 0.0, CZ + 0.15), (0.4, 0.7, 0.62), dark, bevel=0.07, rot=(0, 0, 15 * s), name="Boulder")
        m.box((0.5 * s, FRONT + 0.0, CZ + 0.55), (0.55, 0.07, 0.12), dark, bevel=0.02, rot=(0, 0, -14 * s), name="Brow")
    P.eyes(m, "screen", size=1.1, dz=0.12, iris=glow)
    # parlayan çatlaklar ve zikzak ağız
    for k, x in enumerate((-0.56, -0.28, 0.0, 0.28, 0.56)):
        m.box((x, FRONT + 0.0, CZ - 0.36 + (0.1 if k % 2 else -0.04)), (0.2, 0.05, 0.07), glow, bevel=0.01, rot=(0, 0, 30 if k % 2 else -30), name="MouthZig")
    for x, z, rot in ((-0.7, CZ + 0.9, 60), (0.75, CZ - 0.7, -50), (0.05, CZ + 0.62, 90)):
        m.box((x, FRONT - 0.02, z), (0.35, 0.05, 0.05), glow, bevel=0.01, rot=(0, rot, 0), name="Crack")


# ------------------------------------------------------------------ yumurta 6 (galaxy)
def alien(m, C):
    glow = (255, 240, 120)
    P.base(m, C)
    for s in (-1, 1):
        m.ball((0.5 * s, FRONT - 0.02, CZ + 0.08), (0.42, 0.1, 0.56), (15, 15, 28), seg=16, rings=10, rot=(0, 0, 24 * s), name="Eye")
        m.ball((0.5 * s + 0.08, FRONT + 0.08, CZ + 0.28), (0.1, 0.05, 0.13), WHITE, seg=8, rings=5, name="Shine")
        m.ball((0.5 * s - 0.1, FRONT + 0.07, CZ - 0.05), (0.05, 0.04, 0.06), WHITE, seg=8, rings=5, name="Shine")
        m.tube([(0.4 * s, 0.0, TOP - 0.1), (0.5 * s, 0.0, TOP + 0.5), (0.65 * s, 0.0, TOP + 0.9)], 0.06, darker(C, 0.3), name="Antenna")
        m.ball((0.65 * s, 0.0, TOP + 1.0), (0.17, 0.17, 0.17), glow, seg=12, rings=8, name="AntennaOrb")
    m.box((0, FRONT + 0.0, CZ - 0.45), (0.3, 0.05, 0.07), darker(C, 0.5), bevel=0.02, name="Mouth")
    for x, z in ((-0.28, CZ - 0.2), (0.0, CZ - 0.12), (0.28, CZ - 0.2)):
        m.ball((x, FRONT - 0.0, z), (0.04, 0.03, 0.04), darker(C, 0.3), seg=6, rings=4, name="Dot")
    m.star((0.0, FRONT - 0.02, CZ + 0.78), 0.15, glow, thickness=0.08, name="Star")
    m.ball((0, BACK - 0.05, CZ - 0.35), (0.22, 0.18, 0.22), lighter(C, 0.3), seg=10, rings=6, name="Tail")


# (id, çizici, renk): renkler Config.Pets ile AYNI olmalı
PETS = [
    ("chick", chick, (255, 225, 90)),
    ("hamster", hamster, (240, 200, 150)),
    ("deer", deer, (205, 150, 90)),
    ("owl", owl, (160, 130, 100)),
    ("frog", frog, (80, 210, 110)),
    ("lion", lion, (235, 190, 100)),
    ("camel", camel, (225, 195, 140)),
    ("scorpion", scorpion, (170, 60, 50)),
    ("snake", snake, (120, 190, 100)),
    ("penguin", penguin, (45, 55, 85)),
    ("seal", seal, (150, 165, 185)),
    ("polarbear", polarbear, (245, 248, 255)),
    ("yeti", yeti, (170, 215, 245)),
    ("salamander", salamander, (255, 150, 60)),
    ("lavacrab", lavacrab, (225, 70, 50)),
    ("golem", golem, (110, 95, 110)),
    ("alien", alien, (140, 235, 160)),
]


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    textures = os.path.join(c.OUT, "textures")
    models = []
    for pet_id, builder, color in PETS:
        if wanted and pet_id not in wanted:
            continue
        model = Model("pet_" + pet_id)
        builder(model, color)
        obj = model.finish(textures)
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "pet_" + pet_id + ".fbx"))
        print("MODEL", pet_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    cols = 6 if len(models) > 6 else max(1, len(models))
    spacing = 4.4
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * spacing, row * spacing * 1.25, 0)  # kamera ön tarafta: x ters, soldan sağa sıra korunur
    rows = (len(models) + cols - 1) // cols
    center = (0, (rows - 1) * spacing * 0.625, 0.9)
    c.add_floor((205, 214, 240), size=80)
    c.add_lights(center=center, distance=16)
    name = "pets_more_check.png" if wanted else "pets_more_lineup.png"
    c.render_view(os.path.join(c.OUT, "previews", name), center=center, distance=(9 + cols * 1.9 + rows * 1.7) * 1.45, azimuth_deg=0, elevation_deg=34, lens=45)
    if not wanted:
        c.save_blend(os.path.join(c.OUT, "blend", "pets_more.blend"))


if __name__ == "__main__":
    main()
