"""13 pet: KUTU (küp) tarzı modeller (sahibinin referansı: Pet Simulator 2 3B petleri): yuvarlatılmış küp gövde-baş, öne bakan düz yüz (iri gözler), küçük ayaklar,
türe göre kulak/boynuz/kanat/kuyruk. Pet seçimi ve adları Config.Pets ile aynıdır; ana renk Config renkleridir.
Her model TEK MESH + palet dokusu (lib.py). Çalıştırma:
    blender -b -P tools/blender/pets.py              (hepsi)
    blender -b -P tools/blender/pets.py -- cat dog   (seçilenler)
Çıktı: assets/blender/fbx/pet_<id>.fbx, textures/pet_<id>_palette.png, previews/pets_lineup.png (hepsi yan yana), blend/pets_all.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
from lib import Model, darker, lighter, mix  # noqa: E402

W, D, H = 2.1, 1.9, 1.85  # gövde-baş küpü
FEET = 0.28
CZ = FEET + H / 2 - 0.05  # küp merkezi
TOP = CZ + H / 2
FRONT = D / 2
BACK = -D / 2

BLACK = (34, 28, 40)
WHITE = (255, 255, 255)
PINK = (255, 150, 175)
CREAM = (255, 238, 215)


# ------------------------------------------------------------------ ortak parçalar
def base(m, color, feet=None):
    m.box((0, 0, CZ), (W, D, H), color, bevel=0.26, segments=3, name="Body")
    for s in (-1, 1):
        m.box((0.58 * s, 0.32, FEET / 2 + 0.04), (0.62, 0.78, FEET + 0.12), feet or darker(color, 0.22), bevel=0.09, name="Foot")


def shine(m, x, z, scale=1.0):
    m.ball((x + 0.075, FRONT + 0.065, z + 0.1), (0.075 * scale, 0.03, 0.095 * scale), WHITE, seg=10, rings=6, name="Shine")
    m.ball((x - 0.07, FRONT + 0.06, z - 0.1), (0.036 * scale, 0.025, 0.04 * scale), WHITE, seg=8, rings=5, name="Shine")


def eyes(m, style="bead", spread=0.52, dz=0.1, size=1.0, color=BLACK, iris=None):
    z = CZ + dz
    for s in (-1, 1):
        x = spread * s
        if style == "bead":
            m.ball((x, FRONT, z), (0.22 * size, 0.08, 0.3 * size), color, seg=14, rings=8, name="Eye")
            shine(m, x, z, size)
        elif style == "white":
            m.ball((x, FRONT, z), (0.27 * size, 0.08, 0.34 * size), WHITE, seg=14, rings=8, name="Eye")
            m.ball((x, FRONT + 0.04, z - 0.02), (0.15 * size, 0.06, 0.22 * size), iris or color, seg=12, rings=8, name="Pupil")
            shine(m, x, z - 0.02, size * 0.8)
        elif style == "slit":
            m.ball((x, FRONT, z), (0.24 * size, 0.08, 0.28 * size), iris or (255, 215, 70), seg=14, rings=8, name="Eye")
            m.ball((x, FRONT + 0.05, z), (0.07 * size, 0.05, 0.24 * size), color, seg=10, rings=6, name="Pupil")
            m.ball((x + 0.06, FRONT + 0.09, z + 0.1), (0.05, 0.03, 0.06), WHITE, seg=8, rings=5, name="Shine")
        elif style == "screen":
            m.box((x, FRONT, z), (0.46 * size, 0.1, 0.4 * size), (22, 34, 56), bevel=0.05, name="Screen")
            m.box((x, FRONT + 0.06, z), (0.3 * size, 0.06, 0.24 * size), iris or (120, 245, 255), bevel=0.04, name="Light")


def nose(m, color=BLACK, z_off=-0.22, size=1.0):
    m.ball((0, FRONT + 0.03, CZ + z_off), (0.13 * size, 0.08, 0.09 * size), color, seg=10, rings=6, name="Nose")


def mouth(m, color=BLACK, z_off=-0.42, spread=0.1, wide=0.2):
    for s in (-1, 1):
        m.box((spread * s, FRONT + 0.02, CZ + z_off), (wide, 0.045, 0.055), color, bevel=0.015, rot=(0, -22 * s, 0), name="Mouth")


def cheeks(m, color=PINK, spread=0.8, z_off=-0.24, size=1.0):
    for s in (-1, 1):
        m.ball((spread * s, FRONT - 0.02, CZ + z_off), (0.2 * size, 0.06, 0.12 * size), color, seg=10, rings=6, name="Cheek")


def whiskers(m, color=(110, 90, 90)):
    for s in (-1, 1):
        for index, tilt in enumerate((-14, 0, 14)):
            m.box((1.28 * s, FRONT - 0.1, CZ - 0.2 + 0.08 * (1 - index)), (0.5, 0.03, 0.03), color, bevel=0, rot=(0, 0, tilt * s), name="Whisker")


def ears_point(m, color, inner=None, spread=0.66, size=1.0, tilt=14, tip=None):
    for s in (-1, 1):
        m.cone((spread * s, 0.1, TOP + 0.22 * size), 0.44 * size, 0.04, 0.7 * size, color, rot=(-6, tilt * s, 45), verts=4, name="Ear")
        if tip:
            m.cone((spread * s + 0.05 * s, 0.1, TOP + 0.5 * size), 0.2 * size, 0.03, 0.26 * size, tip, rot=(-6, tilt * s, 45), verts=4, name="EarTip")
        if inner:
            m.cone((spread * s, 0.2, TOP + 0.2 * size), 0.28 * size, 0.03, 0.48 * size, inner, rot=(-6, tilt * s, 45), verts=4, name="InnerEar")


def ears_round(m, color, inner=None, spread=0.78, size=0.36):
    for s in (-1, 1):
        m.ball((spread * s, 0.0, TOP + 0.02), (size, size * 0.7, size), color, seg=12, rings=8, name="Ear")
        if inner:
            m.ball((spread * s, 0.2 * size, TOP + 0.04), (size * 0.6, size * 0.4, size * 0.6), inner, seg=10, rings=6, name="InnerEar")


def tail_ball(m, color, size=0.34, z=0.8):
    m.ball((0, BACK - 0.12, CZ - 0.25 + (z - 0.8)), (size, size, size), color, seg=12, rings=8, name="Tail")


def tail_curl(m, color, tip=None, thick=0.16):
    m.tube([(0, BACK + 0.1, 0.7), (0, BACK - 0.45, 0.8), (0, BACK - 0.7, 1.3), (0.15, BACK - 0.6, 1.75)], thick, color, name="Tail")
    if tip:
        m.ball((0.15, BACK - 0.6, 1.8), (0.14, 0.14, 0.16), tip, seg=10, rings=6, name="TailTip")


# ------------------------------------------------------------------ türler
def cat(m, C):
    base(m, C)
    L = lighter(C, 0.65)
    ears_point(m, C, inner=PINK)
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.5, 0.2, 0.34), L, seg=14, rings=8, name="Muzzle")
    eyes(m, "bead", size=1.05)
    nose(m, PINK, -0.16)
    mouth(m, BLACK, -0.36)
    cheeks(m)
    whiskers(m)
    tail_curl(m, C, tip=darker(C, 0.15))
    for x in (-0.3, 0.0, 0.3):  # alında çizgiler
        m.box((x, FRONT - 0.2, TOP - 0.05), (0.1, 0.5, 0.05), darker(C, 0.18), bevel=0.01, name="Stripe")


def dog(m, C):
    base(m, C)
    L = (240, 214, 180)
    dark = darker(C, 0.28)
    for s in (-1, 1):  # sarkık kulaklar
        m.box((1.2 * s, 0.1, CZ + 0.42), (0.32, 0.6, 1.0), dark, bevel=0.1, rot=(0, 10 * s, 0), name="Ear")
    m.box((0, FRONT - 0.05, CZ - 0.38), (0.95, 0.5, 0.62), L, bevel=0.15, segments=3, name="Snout")
    m.ball((0, FRONT + 0.22, CZ - 0.18), (0.2, 0.12, 0.14), BLACK, seg=10, rings=6, name="Nose")
    m.box((0, FRONT + 0.15, CZ - 0.66), (0.22, 0.08, 0.22), PINK, bevel=0.04, name="Tongue")
    m.ball((0.55, FRONT - 0.02, CZ + 0.18), (0.4, 0.06, 0.42), dark, seg=12, rings=8, name="EyePatch")
    eyes(m, "bead", size=1.0, dz=0.14)
    tail_ball(m, C, 0.3)
    m.cone((0, BACK - 0.35, CZ - 0.05), 0.2, 0.06, 0.6, C, rot=(60, 0, 0), verts=6, name="Tail")


def bunny(m, C):
    base(m, C)
    inner = PINK
    for s in (-1, 1):
        m.box((0.5 * s, -0.05, TOP + 0.62), (0.42, 0.26, 1.45), C, bevel=0.12, rot=(-4, 5 * s, 0), name="Ear")
        m.box((0.5 * s, 0.1, TOP + 0.6), (0.22, 0.06, 1.12), inner, bevel=0.04, rot=(-4, 5 * s, 0), name="InnerEar")
    eyes(m, "bead", size=1.0)
    nose(m, PINK, -0.18)
    for s in (-1, 1):
        m.box((0.07 * s, FRONT + 0.02, CZ - 0.5), (0.13, 0.05, 0.2), WHITE, bevel=0.025, name="Tooth")
    cheeks(m, PINK, 0.82)
    tail_ball(m, WHITE, 0.4)


def fox(m, C):
    base(m, C)
    tipc = (70, 35, 25)
    ears_point(m, C, inner=tipc, spread=0.66, size=1.05, tip=None)
    m.ball((0, FRONT - 0.05, CZ - 0.45), (0.78, 0.2, 0.46), WHITE, seg=14, rings=8, name="Bib")  # beyaz çene
    for s in (-1, 1):
        m.cone((1.1 * s, FRONT - 0.5, CZ - 0.3), 0.3, 0.03, 0.55, WHITE, rot=(0, 90 * s, 0), verts=4, name="CheekFluff")
    eyes(m, "bead", size=1.0, dz=0.18)
    nose(m, BLACK, -0.12)
    mouth(m, BLACK, -0.34)
    # bol kuyruk
    m.ball((0, BACK - 0.4, 0.75), (0.34, 0.5, 0.34), C, seg=12, rings=8, name="Tail")
    m.ball((0, BACK - 0.85, 0.95), (0.4, 0.5, 0.4), C, seg=12, rings=8, name="Tail")
    m.ball((0, BACK - 1.28, 1.2), (0.38, 0.4, 0.38), WHITE, seg=12, rings=8, name="TailTip")


def panda(m, C):
    base(m, C, feet=BLACK)
    ears_round(m, BLACK, None, spread=0.78, size=0.4)
    for s in (-1, 1):
        m.ball((0.55 * s, FRONT - 0.02, CZ + 0.08), (0.36, 0.07, 0.46), BLACK, seg=14, rings=8, rot=(0, 0, 18 * s), name="EyePatch")
        m.ball((0.55 * s, FRONT + 0.07, CZ + 0.12), (0.13, 0.05, 0.17), WHITE, seg=10, rings=6, name="Eye")
        m.ball((0.58 * s, FRONT + 0.1, CZ + 0.17), (0.05, 0.03, 0.06), BLACK, seg=8, rings=5, name="Pupil")
    m.ball((0, FRONT - 0.04, CZ - 0.34), (0.42, 0.18, 0.3), CREAM, seg=12, rings=8, name="Muzzle")
    nose(m, BLACK, -0.2, 1.2)
    mouth(m, BLACK, -0.42)
    cheeks(m, PINK, 0.9, -0.3)
    tail_ball(m, WHITE, 0.26)


def tiger(m, C):
    base(m, C)
    dark = (58, 34, 24)
    ears_round(m, C, inner=lighter(C, 0.6), spread=0.78, size=0.34)
    for index, y in enumerate((0.45, 0.0, -0.45)):  # üstte şeritler
        m.box((0, y, TOP - 0.02), (0.7 - 0.06 * index, 0.16, 0.06), dark, bevel=0.015, name="Stripe")
    for s in (-1, 1):
        for index, z in enumerate((CZ + 0.4, CZ + 0.05, CZ - 0.3)):
            m.box((W / 2 * s, 0.1 - 0.3 * index * 0.0, z), (0.07, 0.5, 0.15), dark, bevel=0.015, name="Stripe")
    m.box((0, FRONT - 0.02, CZ - 0.38), (0.95, 0.12, 0.55), WHITE, bevel=0.12, name="Muzzle")
    eyes(m, "bead", size=1.0, dz=0.14)
    nose(m, PINK, -0.2)
    mouth(m, BLACK, -0.4)
    for x in (-0.28, 0.0, 0.28):
        m.box((x, FRONT - 0.03, CZ + 0.6), (0.1, 0.05, 0.28), dark, bevel=0.015, name="Brow")
    whiskers(m)
    tail_curl(m, C, tip=dark)


def wolf(m, C):
    base(m, C)
    dark = darker(C, 0.38)
    L = lighter(C, 0.6)
    ears_point(m, C, inner=dark, spread=0.7, size=1.15, tilt=10)
    m.box((0, FRONT + 0.1, CZ - 0.34), (0.8, 0.55, 0.5), L, bevel=0.14, segments=3, name="Snout")
    m.ball((0, FRONT + 0.4, CZ - 0.2), (0.15, 0.1, 0.1), BLACK, seg=10, rings=6, name="Nose")
    eyes(m, "slit", size=0.9, dz=0.22, iris=(250, 215, 90), color=BLACK)
    for s in (-1, 1):
        m.box((0.5 * s, FRONT - 0.02, CZ + 0.5), (0.4, 0.05, 0.1), dark, bevel=0.015, rot=(0, 0, -16 * s), name="Brow")
        m.cone((1.1 * s, FRONT - 0.55, CZ - 0.35), 0.32, 0.03, 0.6, L, rot=(0, 90 * s, 0), verts=4, name="CheekFluff")
    mouth(m, BLACK, -0.5, 0.16, 0.24)
    m.ball((0, BACK - 0.45, 0.8), (0.3, 0.5, 0.3), C, seg=12, rings=8, rot=(35, 0, 0), name="Tail")
    m.ball((0, BACK - 0.85, 1.1), (0.34, 0.45, 0.34), L, seg=12, rings=8, name="TailTip")


def dragon(m, C):
    base(m, C)
    horn = (255, 236, 190)
    belly = lighter(C, 0.55)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.55 * s, 0.05, TOP + 0.2), 0.2, 0.03, 0.55, horn, rot=(-10, 14 * s, 0), verts=6, name="Horn")
        # kanatlar: yassı konikler
        m.cone((1.35 * s, -0.55, CZ + 0.45), 0.5, 0.04, 1.3, dark, rot=(0, 70 * s, 25 * s), verts=3, scale=(1, 0.18, 1), name="Wing")
        m.cone((1.28 * s, -0.5, CZ + 0.35), 0.38, 0.03, 1.0, belly, rot=(0, 70 * s, 25 * s), verts=3, scale=(1, 0.12, 1), name="WingFill")
        m.cone((0.45 * s, FRONT - 0.15, CZ - 0.46), 0.07, 0.01, 0.22, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
    # ağız: geniş koyu gülümseme + iki beyaz diş, üstünde iki burun deliği
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.9, 0.06, 0.1), (60, 20, 80), bevel=0.03, name="Mouth")
    for s in (-1, 1):
        m.box((0.46 * s, FRONT + 0.02, CZ - 0.37), (0.2, 0.05, 0.08), (60, 20, 80), bevel=0.02, rot=(0, -35 * s, 0), name="MouthCorner")
        m.ball((0.15 * s, FRONT + 0.03, CZ - 0.2), (0.06, 0.05, 0.05), dark, seg=8, rings=5, name="Nostril")
    eyes(m, "white", size=1.0, dz=0.22, iris=BLACK)
    for index, y in enumerate((0.35, -0.05, -0.45)):  # sırtta dikenler
        m.cone((0, y, TOP + 0.05), 0.16, 0.02, 0.4, horn, rot=(0, 0, 45), verts=4, name="Spike")
    m.cone((0, BACK - 0.35, 0.75), 0.22, 0.04, 0.9, C, rot=(70, 0, 0), verts=6, name="Tail")
    m.cone((0, BACK - 0.75, 0.55), 0.14, 0.02, 0.3, horn, rot=(70, 0, 0), verts=4, name="TailTip")


def phoenix(m, C):
    base(m, C)
    gold = (255, 215, 60)
    orange = (255, 150, 30)
    m.cone((0, FRONT + 0.3, CZ - 0.12), 0.3, 0.05, 0.75, gold, rot=(-90, 0, 0), verts=6, name="Beak")
    m.cone((0, FRONT + 0.22, CZ - 0.36), 0.22, 0.04, 0.5, orange, rot=(-90, 0, 0), verts=6, name="BeakLow")
    eyes(m, "bead", size=0.95, dz=0.2)
    for index, (x, h, col) in enumerate(((0, 0.95, gold), (-0.35, 0.75, orange), (0.35, 0.75, orange), (-0.65, 0.5, gold), (0.65, 0.5, gold))):
        m.cone((x, 0.0, TOP + h / 2 - 0.05), 0.18, 0.02, h, col, rot=(0, -x * 16, 0), verts=5, scale=(1, 0.5, 1), name="Crest")
    for s in (-1, 1):  # kanat tüyleri
        for index, (ang, length, col) in enumerate(((10, 1.1, C), (35, 1.0, orange), (60, 0.85, gold))):
            m.cone((1.25 * s + 0.2 * s * index * 0.0, -0.1, CZ + 0.15 + 0.12 * index), 0.2, 0.03, length, col, rot=(0, 90 * s + ang * s * -0.0, 0), verts=5, scale=(1, 0.2, 1), name="Feather")
    for index, (x, col) in enumerate(((0, orange), (-0.3, gold), (0.3, gold))):
        m.cone((x, BACK - 0.35, 0.8 + abs(x)), 0.14, 0.02, 0.9, col, rot=(70, 0, -x * 25), verts=5, scale=(1, 0.4, 1), name="TailFeather")
    cheeks(m, orange, 0.85)


def unicorn(m, C):
    base(m, C)
    gold = (255, 226, 120)
    cyan, yellow, purple = (120, 225, 255), (255, 235, 120), (190, 130, 255)
    m.cone((0, 0.5, TOP + 0.62), 0.3, 0.03, 1.4, gold, rot=(-14, 0, 0), verts=8, name="Horn")
    for index in range(3):  # boynuzda spiral halkalar
        m.torus((0, 0.5 - 0.1 + 0.03 * index, TOP + 0.22 + 0.38 * index), 0.28 - 0.08 * index, 0.045, (255, 170, 80), rot=(-14, 0, 0), major_seg=10, minor_seg=5, name="HornRing")
    ears_point(m, C, inner=PINK, spread=0.8, size=0.7, tilt=22)
    for index, (y, col) in enumerate(((0.5, cyan), (0.05, yellow), (-0.4, purple), (-0.8, cyan))):  # yele
        m.box((0.0, y, TOP + 0.02), (0.55, 0.42, 0.28), col, bevel=0.1, name="Mane")
    m.box((0, FRONT - 0.15, TOP - 0.05), (0.55, 0.25, 0.4), cyan, bevel=0.1, name="Forelock")
    eyes(m, "bead", size=1.1, dz=0.12)
    nose(m, PINK, -0.2, 0.7)
    mouth(m, BLACK, -0.4)
    cheeks(m, (255, 120, 170), 0.82)
    m.tube([(0, BACK + 0.1, 0.7), (0, BACK - 0.45, 0.85), (0, BACK - 0.65, 1.3)], 0.18, purple, name="Tail")


def robot(m, C):
    base(m, C, feet=(90, 100, 120))
    dark = (60, 78, 104)
    m.box((0, 0, TOP - 0.02), (W + 0.04, D + 0.04, 0.12), lighter(C, 0.35), bevel=0.04, name="Plate")
    for s in (-1, 1):
        m.cyl((1.12 * s, 0.05, CZ), 0.38, 0.22, dark, rot=(0, 90, 0), verts=14, name="EarDisc")
        m.cyl((1.2 * s, 0.05, CZ), 0.16, 0.1, (230, 90, 90), rot=(0, 90, 0), verts=10, name="EarBolt")
        for z in (CZ + 0.62, CZ - 0.62):
            m.cyl((0.82 * s, FRONT - 0.02, z), 0.07, 0.05, (200, 210, 225), rot=(90, 0, 0), verts=8, name="Bolt")
    m.cyl((0, 0, TOP + 0.3), 0.045, 0.6, dark, verts=8, name="Antenna")
    m.ball((0, 0, TOP + 0.65), (0.14, 0.14, 0.14), (255, 90, 90), seg=12, rings=8, name="AntennaTip")
    eyes(m, "screen", size=1.05, dz=0.18, iris=(120, 245, 255))
    for index in range(5):  # ağız ızgarası
        m.box(((index - 2) * 0.16, FRONT + 0.01, CZ - 0.45), (0.08, 0.05, 0.22), dark, bevel=0.01, name="Grille")
    m.box((0, FRONT + 0.0, CZ - 0.2), (0.7, 0.04, 0.05), dark, bevel=0.01, name="Seam")


def galaxy(m, C):
    base(m, C)
    cyan, yellow = (120, 235, 255), (255, 235, 120)
    ears_point(m, C, inner=(190, 140, 255))
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.5, 0.2, 0.34), lighter(C, 0.55), seg=14, rings=8, name="Muzzle")
    eyes(m, "bead", size=1.1, dz=0.1)
    nose(m, (255, 150, 220), -0.16)
    mouth(m, BLACK, -0.36)
    cheeks(m, (255, 150, 220))
    m.star((0, FRONT - 0.02, CZ + 0.72), 0.22, yellow, thickness=0.1, name="Star")
    m.star((-0.88, FRONT - 0.02, CZ - 0.05), 0.15, WHITE, thickness=0.09, name="Star")
    m.star((0.88, FRONT - 0.02, CZ - 0.5), 0.17, cyan, thickness=0.09, name="Star")
    m.star((0.9, 0.2, TOP - 0.02), 0.2, WHITE, thickness=0.09, rot=(90, 0, 0), name="Star")
    m.star((-0.95, FRONT - 0.7, CZ + 0.5), 0.2, yellow, thickness=0.09, rot=(0, 0, 90), name="StarSide")
    m.star((0.95, FRONT - 0.9, CZ + 0.4), 0.2, cyan, thickness=0.09, rot=(0, 0, 90), name="StarSide")
    tail_curl(m, C, tip=yellow)
    m.star((0.15, BACK - 0.6, 1.95), 0.2, yellow, thickness=0.08, name="TailStar")


def titan(m, C):
    base(m, C, feet=darker(C, 0.3))
    dk = (225, 160, 30)
    cream = (255, 240, 200)
    ears_round(m, C, inner=dk, spread=0.82, size=0.36)
    m.box((0, 0.0, TOP + 0.12), (1.6, 1.4, 0.3), dk, bevel=0.07, name="CrownBase")
    for index, x in enumerate((-0.62, -0.31, 0.0, 0.31, 0.62)):  # taç sivrileri
        h = 0.62 if index == 2 else 0.5
        m.cone((x, 0.55, TOP + 0.3 + h / 2), 0.17, 0.02, h, (255, 205, 60), rot=(0, 0, 45), verts=4, name="CrownSpike")
    m.ball((0, 0.7, TOP + 0.4), (0.12, 0.08, 0.12), (255, 70, 90), seg=10, rings=6, name="Gem")
    for x, col in ((-0.62, (90, 170, 255)), (0.62, (90, 170, 255))):
        m.ball((x, 0.7, TOP + 0.34), (0.08, 0.06, 0.08), col, seg=8, rings=5, name="Gem")
    m.box((0, FRONT - 0.05, CZ - 0.38), (1.0, 0.45, 0.58), cream, bevel=0.15, segments=3, name="Snout")
    nose(m, BLACK, -0.18, 1.2)
    mouth(m, BLACK, -0.4)
    eyes(m, "bead", size=1.0, dz=0.14)
    for s in (-1, 1):
        m.box((0.52 * s, FRONT - 0.03, CZ + 0.5), (0.5, 0.06, 0.12), dk, bevel=0.02, rot=(0, 0, -14 * s), name="Brow")
    cheeks(m, (255, 150, 120), 0.85)
    tail_ball(m, dk, 0.32)


PETS = [
    ("cat", cat, (255, 190, 120)),
    ("dog", dog, (170, 120, 80)),
    ("bunny", bunny, (250, 220, 235)),
    ("fox", fox, (255, 120, 40)),
    ("panda", panda, (235, 235, 235)),
    ("tiger", tiger, (255, 170, 40)),
    ("wolf", wolf, (140, 150, 170)),
    ("dragon", dragon, (180, 60, 255)),
    ("phoenix", phoenix, (255, 80, 40)),
    ("unicorn", unicorn, (255, 130, 230)),
    ("robot", robot, (100, 220, 255)),
    ("galaxy", galaxy, (120, 80, 255)),
    ("titan", titan, (255, 220, 60)),
]


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1400, samples=40)
    textures = os.path.join(c.OUT, "textures")
    models = []
    column = 0
    for pet_id, builder, color in PETS:
        if wanted and pet_id not in wanted:
            continue
        model = Model("pet_" + pet_id)
        builder(model, color)
        obj = model.finish(textures)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "pet_" + pet_id + ".fbx"))
        print("MODEL", pet_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    # yan yana dizilim (5 sütun)
    cols = 5 if len(models) > 6 else max(1, len(models))
    spacing = 4.4
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * spacing, row * spacing * 1.25, 0)  # kamera -Y'ye baktığı için x ters: soldan sağa sıra korunur
    rows = (len(models) + cols - 1) // cols
    center = (0, (rows - 1) * spacing * 0.625, 0.9)
    c.add_floor((205, 214, 240), size=80)
    c.add_lights(center=center, distance=16)
    c.render_view(os.path.join(c.OUT, "previews", "pets_lineup.png"), center=center, distance=9 + cols * 1.9 + rows * 1.7, azimuth_deg=0, elevation_deg=36, lens=45)
    c.save_blend(os.path.join(c.OUT, "blend", "pets_all.blend"))


main()
