"""DÜNYA 2 (Uzay): 30 yeni KUTU pet, pets.py ile aynı üslup (Pet Simulator 2 tarzı yuvarlatılmış küp gövde-baş, öne bakan düz yüz, iri gözler, küçük ayaklar).
Yumurta -> petler (en yaygın/zayıf önce; çıkma ağırlıkları 50/30/13/5/2 = Common, Rare, Epic, Legendary, Mythic):
  moon: astrocat moonbunny craterpup lunarowl mooncow            asteroid: rockbeetle meteorpig astercrab cometfox asteroidgolem
  nebula: nebulajelly cloudsquid starfish nebulamoth nebuladragon  comet: iceslug cometbird frostalien cometwolf cometdragon
  supernova: solarlion sunbird novabeast flaredrake novaking      blackhole: voidbat darkoctopus voidcat voidserpent singularity
Nadir petler daha gösterişlidir: parlak (ışık renginde) süsler, boynuz, kanat, taç, hale, yörünge halkası.
Her model TEK MESH + palet dokusu (lib.py), adı pet_<id>. Dünya 1 betiklerine ve src/'ye dokunmaz; ölçüler space_lib.record ile models_space.json'a yazılır.
    blender -b -P tools/blender/pets_space.py                 (hepsi)
    blender -b -P tools/blender/pets_space.py -- voidcat ...  (seçilenler)
Çıktı: assets/blender/fbx/pet_<id>.fbx, textures/pet_<id>_palette.png, previews/pets_space_lineup.png, blend/pets_space.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
import pets as P  # noqa: E402
import space_lib as S  # noqa: E402
from lib import Model, darker, lighter, mix  # noqa: E402

W, D, H = P.W, P.D, P.H
CZ, TOP, FRONT, BACK, FEET = P.CZ, P.TOP, P.FRONT, P.BACK, P.FEET
BLACK, WHITE, PINK, CREAM = P.BLACK, P.WHITE, P.PINK, P.CREAM
GOLD = (255, 210, 70)
GOLD_D = (225, 160, 30)
CYAN = (110, 240, 255)
STAR = (255, 240, 130)
MAGENTA = (255, 90, 220)
VIOLET = (170, 100, 255)
FIRE = (255, 140, 30)
FIRE_Y = (255, 225, 80)
ICE = (200, 245, 255)
VOID = (28, 20, 44)


# ------------------------------------------------------------------ uzay süsleri
def helmet_ring(m, color, glass=None):
    """Astronot kaskı penceresi: yüzün çevresinde halka (+ isteğe bağlı üstte kask tepesi)."""
    m.torus((0, FRONT + 0.02, CZ + 0.02), 0.86, 0.09, color, rot=(90, 0, 0), major_seg=28, minor_seg=6, name="HelmetRing")
    if glass:
        m.box((0, -0.1, TOP + 0.04), (1.5, 1.4, 0.16), glass, bevel=0.07, name="HelmetTop")


def antenna(m, x, color, tip, height=0.6, y=0.0, lean=0.15):
    m.tube([(x, y, TOP - 0.08), (x + lean * 0.5, y, TOP + height * 0.6), (x + lean, y, TOP + height)], 0.05, color, name="Antenna", taper=False)
    m.ball((x + lean, y, TOP + height + 0.1), (0.14, 0.14, 0.14), tip, seg=10, rings=6, name="AntennaTip")


def crown(m, gold=GOLD, gem=(255, 70, 110), side_gem=CYAN, z=TOP, scale=1.0):
    m.box((0, 0.0, z + 0.12 * scale), (1.5 * scale, 1.3 * scale, 0.28 * scale), GOLD_D, bevel=0.07, name="CrownBase")
    for index, x in enumerate((-0.58, -0.29, 0.0, 0.29, 0.58)):
        h = (0.62 if index == 2 else 0.48) * scale
        m.cone((x * scale, 0.5 * scale, z + 0.26 * scale + h / 2), 0.16 * scale, 0.02, h, gold, rot=(0, 0, 45), verts=4, name="CrownSpike")
    m.ball((0, 0.66 * scale, z + 0.38 * scale), (0.12 * scale, 0.07, 0.12 * scale), gem, seg=10, rings=6, name="Gem")
    for x in (-0.58, 0.58):
        m.ball((x * scale, 0.66 * scale, z + 0.32 * scale), (0.08 * scale, 0.05, 0.08 * scale), side_gem, seg=8, rings=5, name="Gem")


def halo(m, color, z=TOP + 0.5, r=0.62):
    m.torus((0, -0.05, z), r, 0.07, color, major_seg=24, minor_seg=6, name="Halo")


def orbit_point(r, angle_deg, tilt, z):
    """Eğik yörünge halkası üzerindeki nokta (halka X çevresinde tilt derece eğik; eksi tilt = önü aşağıda, Satürn gibi)."""
    from mathutils import Euler, Vector

    a = math.radians(angle_deg)
    p = Vector((math.sin(a) * r, math.cos(a) * r, 0))
    p.rotate(Euler((math.radians(tilt), 0, 0), "XYZ"))
    return (p.x, p.y, z + p.z)


def orbit_ring(m, color, tilt=-11, r=1.62, z=CZ - 0.25, moon=None, moon_size=0.22, moon_angle=50, minor=0.07):
    """Gövdeyi saran yörünge halkası: önü aşağıda (yüzü kesmesin), arkası yukarıda."""
    m.torus((0, 0, z), r, minor, color, rot=(tilt, 0, 0), major_seg=36, minor_seg=6, name="OrbitRing")
    if moon:
        m.ball(orbit_point(r, moon_angle, tilt, z), (moon_size, moon_size, moon_size), moon, seg=12, rings=8, name="OrbitMoon")


def wings(m, color, fill, span=1.3, z=CZ + 0.45, y=-0.55, verts=3):
    """pets.dragon'daki gibi yassı koni kanatlar."""
    for s in (-1, 1):
        m.cone((1.35 * s, y, z), 0.5 * span, 0.04, 1.3 * span, color, rot=(0, 70 * s, 25 * s), verts=verts, scale=(1, 0.18, 1), name="Wing")
        if fill:
            m.cone((1.28 * s, y + 0.05, z - 0.1), 0.38 * span, 0.03, 1.0 * span, fill, rot=(0, 70 * s, 25 * s), verts=verts, scale=(1, 0.12, 1), name="WingFill")


def craters(m, color, rim, spots):
    """Gövde yüzeyinde krater lekeleri: (x, y, z, r, yön) yön = 'top' | 'front' | 'side'."""
    for x, y, z, r, face in spots:
        if face == "top":
            m.ball((x, y, z), (r, r, 0.05), color, seg=10, rings=5, name="Crater")
            m.torus((x, y, z + 0.02), r, 0.035, rim, major_seg=12, minor_seg=4, name="CraterRim")
        elif face == "front":
            m.ball((x, y, z), (r, 0.05, r), color, seg=10, rings=5, name="Crater")
            m.torus((x, y + 0.02, z), r, 0.035, rim, rot=(90, 0, 0), major_seg=12, minor_seg=4, name="CraterRim")
        else:
            m.ball((x, y, z), (0.05, r, r), color, seg=10, rings=5, name="Crater")
            m.torus((x + 0.02 * (1 if x > 0 else -1), y, z), r, 0.035, rim, rot=(0, 90, 0), major_seg=12, minor_seg=4, name="CraterRim")


def sparkles(m, items):
    for x, y, z, size, col, rot in items:
        m.star((x, y, z), size, col, thickness=0.08, rot=rot, name="Sparkle")


def body_only(m, color):
    """Ayaksız gövde (yüzen petler: denizanası, ahtapot, kalamar)."""
    m.box((0, 0, CZ), (W, D, H), color, bevel=0.26, segments=3, name="Body")


def tentacles(m, color, tip=None, count=6, curl=1.0):
    for k in range(count):
        ang = 2 * math.pi * (k + 0.5) / count
        sx, sy = math.sin(ang), math.cos(ang)
        x0, y0 = sx * 0.62, sy * 0.55
        pts = [(x0, y0, 0.5), (x0 * 1.25, y0 * 1.25, 0.14), (x0 * 1.65, y0 * 1.6, 0.1), (x0 * (1.85 + 0.15 * curl), y0 * (1.8 + 0.15 * curl), 0.32 * curl)]
        m.tube(pts, 0.13, color, name="Tentacle")
        if tip:
            p = pts[-1]
            m.ball(p, (0.09, 0.09, 0.09), tip, seg=8, rings=5, name="TentacleTip")


def flames(m, cols, y=BACK - 0.2, z=CZ + 0.2, spread=0.42, length=1.0, count=5, up=60):
    """Arkaya doğru akan alev/kuyruk yuyrukçuğu (yassı koniler)."""
    for k in range(count):
        t = k / max(1, count - 1) - 0.5
        x = t * spread * 2
        col = cols[k % len(cols)]
        h = length * (1.0 - 0.35 * abs(t) * 2)
        m.cone((x, y - h * 0.4, z + abs(t) * -0.3), 0.2, 0.02, h, col, rot=(up, 0, -t * 40), verts=5, scale=(1, 0.45, 1), name="Flame")


def glow_eyes(m, col, size=1.0, dz=0.12, spread=0.52):
    """Parlayan (koyu gövdede ışık renkli) gözler: renkli göz + beyaz parıltı."""
    for s in (-1, 1):
        x = spread * s
        m.ball((x, FRONT, CZ + dz), (0.24 * size, 0.08, 0.3 * size), col, seg=14, rings=8, name="GlowEye")
        m.ball((x, FRONT + 0.05, CZ + dz), (0.12 * size, 0.05, 0.18 * size), lighter(col, 0.7), seg=10, rings=6, name="GlowCore")
        P.shine(m, x, CZ + dz, size)


# ------------------------------------------------------------------ MOON yumurtası
def astrocat(m, C):
    P.base(m, C, feet=(235, 238, 250))
    helmet_ring(m, (240, 242, 252))
    P.ears_point(m, C, inner=PINK, spread=0.66, size=0.9)
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.5, 0.2, 0.34), lighter(C, 0.6), seg=14, rings=8, name="Muzzle")
    P.eyes(m, "bead", size=1.0)
    P.nose(m, PINK, -0.16)
    P.mouth(m, BLACK, -0.36)
    P.cheeks(m, PINK, 0.62, -0.26, 0.8)
    antenna(m, 0.0, (200, 205, 220), (255, 90, 90), height=0.5, y=-0.45, lean=0.0)
    # sırt çantası (oksijen tüpü)
    m.box((0, BACK - 0.18, CZ + 0.05), (1.2, 0.4, 1.2), (235, 238, 250), bevel=0.12, name="Backpack")
    for s in (-1, 1):
        m.cyl((0.32 * s, BACK - 0.42, CZ + 0.05), 0.17, 1.0, (120, 170, 255), verts=12, name="Tank")
    P.tail_curl(m, C, tip=lighter(C, 0.4))


def moonbunny(m, C):
    P.base(m, C)
    for s in (-1, 1):
        m.box((0.5 * s, -0.05, TOP + 0.62), (0.42, 0.26, 1.45), C, bevel=0.12, rot=(-4, 5 * s, 0), name="Ear")
        m.box((0.5 * s, 0.1, TOP + 0.6), (0.22, 0.06, 1.12), (200, 190, 255), bevel=0.04, rot=(-4, 5 * s, 0), name="InnerEar")
    S.crescent(m, (0.0, FRONT - 0.02, CZ + 0.66), 0.26, GOLD, thickness=0.09, rot=(0, 0, 0), name="Moon")
    P.eyes(m, "bead", size=1.0, dz=0.05)
    P.nose(m, PINK, -0.22)
    for s in (-1, 1):
        m.box((0.07 * s, FRONT + 0.02, CZ - 0.52), (0.13, 0.05, 0.2), WHITE, bevel=0.025, name="Tooth")
    P.cheeks(m, (255, 170, 210), 0.82, -0.28)
    P.tail_ball(m, WHITE, 0.4)


def craterpup(m, C):
    P.base(m, C)
    dark, rim = darker(C, 0.22), lighter(C, 0.3)
    for s in (-1, 1):
        m.box((1.2 * s, 0.1, CZ + 0.42), (0.32, 0.6, 1.0), dark, bevel=0.1, rot=(0, 10 * s, 0), name="Ear")
    craters(m, dark, rim, [(-0.45, 0.2, TOP, 0.2, "top"), (0.4, -0.35, TOP, 0.26, "top"), (0.15, 0.45, TOP, 0.12, "top"), (W / 2, -0.3, CZ + 0.3, 0.22, "side"), (-W / 2, 0.1, CZ - 0.2, 0.18, "side"), (-0.7, FRONT, CZ + 0.62, 0.13, "front")])
    m.box((0, FRONT - 0.05, CZ - 0.38), (0.95, 0.5, 0.62), lighter(C, 0.55), bevel=0.15, segments=3, name="Snout")
    m.ball((0, FRONT + 0.22, CZ - 0.18), (0.2, 0.12, 0.14), BLACK, seg=10, rings=6, name="Nose")
    m.box((0, FRONT + 0.15, CZ - 0.66), (0.22, 0.08, 0.22), PINK, bevel=0.04, name="Tongue")
    P.eyes(m, "bead", size=1.0, dz=0.16)
    P.tail_ball(m, C, 0.28)
    m.cone((0, BACK - 0.35, CZ - 0.05), 0.2, 0.06, 0.6, C, rot=(60, 0, 0), verts=6, name="Tail")


def lunarowl(m, C):
    P.base(m, C, feet=GOLD)
    light = lighter(C, 0.45)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.62 * s, 0.0, TOP + 0.28), 0.22, 0.03, 0.62, dark, rot=(0, 14 * s, 0), verts=5, name="EarTuft")
        m.ball((0.5 * s, FRONT - 0.04, CZ + 0.12), (0.56, 0.08, 0.56), light, seg=16, rings=10, name="Disc")
        m.ball((0.5 * s, FRONT + 0.03, CZ + 0.12), (0.34, 0.08, 0.34), STAR, seg=14, rings=8, name="Eye")
        m.ball((0.5 * s, FRONT + 0.09, CZ + 0.1), (0.2, 0.06, 0.2), BLACK, seg=12, rings=8, name="Pupil")
        m.ball((0.5 * s + 0.07, FRONT + 0.14, CZ + 0.18), (0.06, 0.04, 0.06), WHITE, seg=8, rings=5, name="Shine")
        m.ball((1.08 * s, -0.05, CZ - 0.15), (0.2, 0.6, 0.75), dark, rot=(0, 0, 8 * s), name="Wing")
    m.cone((0, FRONT + 0.14, CZ - 0.12), 0.17, 0.03, 0.36, GOLD, rot=(-90, 0, 0), verts=4, name="Beak")
    S.crescent(m, (0.0, FRONT - 0.03, CZ - 0.58), 0.3, GOLD, thickness=0.08, rot=(0, 0, 90), name="ChestMoon")
    sparkles(m, [(-0.62, FRONT - 0.03, CZ - 0.55, 0.12, WHITE, (0, 0, 0)), (0.65, FRONT - 0.03, CZ - 0.66, 0.1, STAR, (0, 0, 0)), (0.0, 0.35, TOP - 0.02, 0.16, STAR, (90, 0, 0))])


def mooncow(m, C):
    P.base(m, C, feet=(120, 100, 170))
    patch = (150, 120, 220)
    for x, y, z, rx, rz, face in ((-0.6, FRONT - 0.02, CZ + 0.6, 0.3, 0.22, "front"), (0.45, -0.2, TOP - 0.01, 0.4, 0.3, "top"), (-0.35, -0.5, TOP - 0.01, 0.25, 0.2, "top")):
        if face == "front":
            m.ball((x, y, z), (rx, 0.06, rz), patch, seg=12, rings=6, name="Patch")
        else:
            m.ball((x, y, z), (rx, rz, 0.05), patch, seg=12, rings=6, name="Patch")
    for s in (-1, 1):
        m.ball((W / 2 * s, -0.2, CZ + 0.15), (0.05, 0.4, 0.32), patch, seg=12, rings=6, name="Patch")
        m.cone((0.62 * s, 0.1, TOP + 0.28), 0.14, 0.03, 0.6, GOLD, rot=(0, 28 * s, 0), verts=8, name="Horn")
        m.ball((1.12 * s, 0.1, TOP - 0.25), (0.14, 0.3, 0.2), C, seg=10, rings=6, rot=(0, 0, 20 * s), name="Ear")
    m.box((0, FRONT + 0.02, CZ - 0.4), (1.25, 0.32, 0.6), (255, 190, 225), bevel=0.18, segments=3, name="Snout")
    for s in (-1, 1):
        m.ball((0.28 * s, FRONT + 0.19, CZ - 0.38), (0.08, 0.05, 0.1), (190, 90, 140), seg=8, rings=5, name="Nostril")
    P.eyes(m, "bead", size=1.05, dz=0.24)
    P.cheeks(m, (255, 150, 200), 0.84, -0.12, 0.8)
    # MİTİK: başta altın hale, çevresinde yörünge halkası + küçük ay, yıldızlar
    halo(m, GOLD, z=TOP + 0.85, r=0.5)
    orbit_ring(m, CYAN, moon=(250, 245, 215), moon_size=0.24)
    sparkles(m, [(0.95, FRONT + 0.4, TOP + 0.4, 0.16, STAR, (0, 0, 0)), (-1.0, FRONT + 0.3, TOP + 0.1, 0.12, WHITE, (0, 0, 0))])
    m.tube([(0, BACK + 0.1, 0.9), (0, BACK - 0.35, 1.0), (0.1, BACK - 0.5, 1.4)], 0.07, C, name="Tail")
    m.ball((0.1, BACK - 0.5, 1.48), (0.13, 0.13, 0.16), STAR, seg=8, rings=6, name="TailTip")


# ------------------------------------------------------------------ ASTEROID yumurtası
def rockbeetle(m, C):
    P.base(m, C, feet=darker(C, 0.35))
    shell, dark = lighter(C, 0.12), darker(C, 0.35)
    m.box((0, -0.1, TOP - 0.02), (W - 0.2, D - 0.3, 0.2), shell, bevel=0.1, name="Shell")
    m.box((0, -0.1, TOP + 0.08), (0.06, D - 0.35, 0.06), dark, bevel=0.01, name="ShellSplit")
    for x, y, s in ((-0.5, -0.3, 0.2), (0.45, 0.1, 0.16), (0.3, -0.55, 0.14), (-0.3, 0.3, 0.12)):
        m.ball((x, y, TOP + 0.1), (s, s, s * 0.7), darker(C, 0.18), seg=8, rings=5, name="Pebble")
    m.cone((0, FRONT - 0.15, TOP + 0.3), 0.16, 0.03, 0.75, (90, 80, 75), rot=(-30, 0, 0), verts=6, name="Horn")
    for s in (-1, 1):
        m.tube([(0.35 * s, FRONT - 0.05, TOP - 0.1), (0.5 * s, FRONT + 0.25, TOP + 0.2), (0.62 * s, FRONT + 0.3, TOP + 0.45)], 0.04, dark, name="Feeler")
        for k in range(3):
            m.tube([(1.0 * s, -0.45 + 0.42 * k, 0.75), (1.25 * s, -0.45 + 0.42 * k, 0.45), (1.3 * s, -0.45 + 0.42 * k, 0.1)], 0.07, dark, name="Leg")
    P.eyes(m, "bead", size=0.95, dz=0.05)
    P.mouth(m, BLACK, -0.42)
    P.cheeks(m, (255, 160, 140), 0.82, -0.26)


def meteorpig(m, C):
    P.base(m, C)
    for s in (-1, 1):
        m.cone((0.62 * s, 0.1, TOP + 0.16), 0.28, 0.04, 0.45, C, rot=(-30, 18 * s, 45), verts=4, name="Ear")
    m.box((0, FRONT + 0.06, CZ - 0.3), (0.82, 0.3, 0.55), lighter(C, 0.35), bevel=0.16, segments=3, name="Snout")
    for s in (-1, 1):
        m.ball((0.18 * s, FRONT + 0.22, CZ - 0.3), (0.08, 0.05, 0.12), darker(C, 0.35), seg=8, rings=5, name="Nostril")
    P.eyes(m, "bead", size=1.0, dz=0.22)
    P.cheeks(m, (255, 120, 120), 0.84, -0.2)
    craters(m, darker(C, 0.18), lighter(C, 0.2), [(-0.4, 0.0, TOP, 0.2, "top"), (0.45, -0.4, TOP, 0.16, "top")])
    # meteor kuyruğu: arkadan çıkan alev
    flames(m, (FIRE, FIRE_Y, (255, 100, 40)), y=BACK, z=CZ + 0.3, spread=0.5, length=1.1, count=5, up=70)
    m.tube([(0, BACK + 0.05, 0.75), (0.1, BACK - 0.25, 0.8), (-0.05, BACK - 0.3, 1.05), (0.05, BACK - 0.15, 1.1)], 0.06, darker(C, 0.15), name="Tail")


def astercrab(m, C):
    P.base(m, C, feet=darker(C, 0.25))
    dark = darker(C, 0.3)
    rock = (140, 125, 120)
    for x, y, s, r in ((-0.45, -0.1, 0.32, 20), (0.35, 0.25, 0.26, -15), (0.15, -0.5, 0.22, 35)):
        m.box((x, y, TOP + 0.05), (s, s, s * 0.8), rock, bevel=0.05, rot=(r, r * 0.6, r), name="Rock")
    for s in (-1, 1):
        m.tube([(0.4 * s, 0.3, TOP - 0.1), (0.42 * s, 0.35, TOP + 0.35)], 0.06, C, name="EyeStalk", taper=False)
        m.ball((0.42 * s, 0.4, TOP + 0.45), (0.2, 0.18, 0.2), WHITE, seg=12, rings=8, name="Eye")
        m.ball((0.42 * s, 0.56, TOP + 0.45), (0.1, 0.05, 0.12), BLACK, seg=10, rings=6, name="Pupil")
        m.tube([(1.0 * s, 0.2, CZ), (1.4 * s, 0.55, CZ + 0.05), (1.45 * s, 0.9, CZ + 0.2)], 0.11, C, name="Arm")
        m.ball((1.45 * s, 1.05, CZ + 0.3), (0.32, 0.36, 0.32), C, seg=12, rings=8, name="Claw")
        m.cone((1.45 * s + 0.12 * s, 1.35, CZ + 0.45), 0.13, 0.02, 0.36, dark, rot=(-70, 0, 0), verts=5, name="Pincer")
        m.cone((1.45 * s - 0.12 * s, 1.35, CZ + 0.2), 0.11, 0.02, 0.3, dark, rot=(-110, 0, 0), verts=5, name="Pincer")
        for k in range(2):
            m.tube([(1.0 * s, -0.4 + 0.4 * k, 0.7), (1.3 * s, -0.5 + 0.4 * k, 0.35), (1.35 * s, -0.55 + 0.4 * k, 0.08)], 0.07, dark, name="Leg")
    P.mouth(m, BLACK, -0.3)
    P.cheeks(m, (255, 150, 140), 0.66, -0.15)
    for x, z in ((-0.45, CZ + 0.25), (0.45, CZ + 0.25)):
        m.ball((x, FRONT, z), (0.13, 0.06, 0.13), BLACK, seg=10, rings=6, name="Eye")
        P.shine(m, x, z, 0.6)


def cometfox(m, C):
    P.base(m, C)
    tip = (40, 60, 140)
    P.ears_point(m, C, inner=tip, spread=0.66, size=1.05, tip=ICE)
    m.ball((0, FRONT - 0.05, CZ - 0.45), (0.78, 0.2, 0.46), WHITE, seg=14, rings=8, name="Bib")
    for s in (-1, 1):
        m.cone((1.1 * s, FRONT - 0.5, CZ - 0.3), 0.3, 0.03, 0.55, WHITE, rot=(0, 90 * s, 0), verts=4, name="CheekFluff")
    P.eyes(m, "white", size=0.95, dz=0.18, iris=(40, 120, 255))
    P.nose(m, BLACK, -0.12)
    P.mouth(m, BLACK, -0.34)
    m.star((0, FRONT - 0.02, CZ + 0.72), 0.18, STAR, thickness=0.09, name="Star")
    # LEGENDARY: buzlu kuyruklu yıldız kuyruğu (parlayan camgöbeği alev)
    m.ball((0, BACK - 0.35, 0.8), (0.34, 0.45, 0.34), C, seg=12, rings=8, name="Tail")
    m.ball((0, BACK - 0.8, 1.05), (0.4, 0.5, 0.4), lighter(C, 0.35), seg=12, rings=8, name="Tail")
    m.ball((0, BACK - 1.25, 1.35), (0.34, 0.42, 0.36), ICE, seg=12, rings=8, name="TailTip")
    flames(m, (CYAN, ICE, WHITE), y=BACK - 1.35, z=1.45, spread=0.3, length=0.9, count=3, up=60)
    sparkles(m, [(0.7, BACK - 1.0, 1.9, 0.14, WHITE, (0, 0, 90)), (-0.6, BACK - 0.6, 1.7, 0.1, CYAN, (0, 0, 90))])


def asteroidgolem(m, C):
    dark = darker(C, 0.35)
    glow = (190, 110, 255)
    glow2 = (255, 160, 60)
    P.base(m, C, feet=dark)
    for x, y, s, r in ((-0.5, 0.2, 0.45, 20), (0.35, -0.25, 0.5, -15), (0.0, 0.35, 0.36, 35), (-0.25, -0.5, 0.4, 5)):
        m.box((x, y, TOP + 0.1), (s, s, s * 0.9), lighter(C, 0.12) if r > 0 else dark, bevel=0.06, rot=(r, r * 0.6, r), name="Rock")
    for x, y, h, tilt in ((0.0, 0.0, 0.9, 0), (-0.42, 0.05, 0.6, 18), (0.42, -0.05, 0.65, -18)):  # tepede kristal tacı
        m.cone((x, y, TOP + 0.35 + h / 2), 0.18, 0.02, h, glow, rot=(0, tilt, 0), verts=6, name="Crystal")
    for s in (-1, 1):
        m.box((1.12 * s, 0.0, CZ + 0.15), (0.4, 0.7, 0.62), dark, bevel=0.07, rot=(0, 0, 15 * s), name="Boulder")
        m.box((0.5 * s, FRONT + 0.0, CZ + 0.55), (0.55, 0.07, 0.12), dark, bevel=0.02, rot=(0, 0, -14 * s), name="Brow")
    P.eyes(m, "screen", size=1.1, dz=0.12, iris=glow)
    for k, x in enumerate((-0.56, -0.28, 0.0, 0.28, 0.56)):
        m.box((x, FRONT + 0.0, CZ - 0.36 + (0.1 if k % 2 else -0.04)), (0.2, 0.05, 0.07), glow2, bevel=0.01, rot=(0, 30 if k % 2 else -30, 0), name="MouthZig")
    for x, z, rot in ((-0.7, CZ + 0.9, 60), (0.75, CZ - 0.7, -50), (0.05, CZ + 0.62, 90)):
        m.box((x, FRONT - 0.02, z), (0.35, 0.05, 0.05), glow, bevel=0.01, rot=(0, rot, 0), name="Crack")
    # MİTİK: etrafında yüzen kaya parçaları (asteroit kuşağı)
    orbit_ring(m, glow, r=1.7)
    for k in range(5):
        m.box(orbit_point(1.7, 72 * k + 36, -11, CZ - 0.25), (0.3, 0.28, 0.26), lighter(C, 0.15) if k % 2 else dark, bevel=0.05, rot=(30 * k, 20, 15 * k), name="FloatRock")


# ------------------------------------------------------------------ NEBULA yumurtası
def nebulajelly(m, C):
    body_only(m, C)
    light = lighter(C, 0.45)
    m.box((0, 0, TOP - 0.1), (W + 0.1, D + 0.1, 0.4), light, bevel=0.18, segments=3, name="Bell")  # şemsiye kenarı
    for k in range(8):  # kenarda dalgalı fırfır
        a = 2 * math.pi * k / 8
        m.ball((math.sin(a) * 1.1, math.cos(a) * 1.0, TOP - 0.32), (0.22, 0.22, 0.12), light, seg=10, rings=5, name="Frill")
    tentacles(m, light, tip=MAGENTA, count=6, curl=1.0)
    P.eyes(m, "bead", size=1.05, dz=0.0)
    P.mouth(m, BLACK, -0.36)
    P.cheeks(m, MAGENTA, 0.8, -0.24)
    sparkles(m, [(0.55, 0.25, TOP + 0.12, 0.14, WHITE, (90, 0, 0)), (-0.5, -0.3, TOP + 0.12, 0.11, STAR, (90, 0, 0))])


def cloudsquid(m, C):
    body_only(m, C)
    dark = darker(C, 0.2)
    m.cone((0, -0.05, TOP + 0.5), 0.95, 0.05, 1.0, lighter(C, 0.25), rot=(0, 0, 45), verts=4, name="Fin")
    for s in (-1, 1):
        m.cone((0.7 * s, -0.05, TOP + 0.35), 0.35, 0.03, 0.8, dark, rot=(0, 55 * s, 0), verts=3, scale=(1, 0.25, 1), name="SideFin")
    tentacles(m, C, tip=lighter(C, 0.5), count=6, curl=1.6)
    for k, (x, y, s) in enumerate(((-0.55, 0.2, 0.28), (0.5, -0.3, 0.32), (0.05, -0.6, 0.22))):  # nebula bulutları
        m.ball((x, y, TOP - 0.02), (s, s * 0.8, 0.07), (255, 180, 240) if k % 2 else (150, 220, 255), seg=10, rings=5, name="Cloud")
    P.eyes(m, "white", size=1.0, dz=0.05, iris=(90, 60, 180))
    P.mouth(m, BLACK, -0.42)
    P.cheeks(m, (255, 150, 220), 0.84, -0.26)


def starfish(m, C):
    P.base(m, C)
    light = lighter(C, 0.45)
    for s in (-1, 1):  # yanlarda ve tepede yıldız kolları
        m.cone((1.2 * s, 0.0, CZ + 0.15), 0.42, 0.08, 0.7, C, rot=(0, 90 * s, 0), verts=5, bevel=0.04, name="Arm")
    m.cone((0.0, 0.0, TOP + 0.3), 0.45, 0.08, 0.65, C, verts=5, bevel=0.04, name="Arm")
    for k in range(5):  # sırtta benekler
        a = 2 * math.pi * k / 5
        m.ball((math.sin(a) * 0.55, math.cos(a) * 0.5 - 0.1, TOP + 0.01), (0.1, 0.1, 0.05), light, seg=8, rings=5, name="Dot")
    m.star((0, FRONT - 0.02, CZ + 0.62), 0.2, STAR, thickness=0.09, points=5, name="Star")
    P.eyes(m, "bead", size=1.05, dz=0.05)
    P.mouth(m, BLACK, -0.38)
    P.cheeks(m, (255, 120, 150), 0.82, -0.25)
    sparkles(m, [(-0.85, FRONT - 0.02, CZ + 0.65, 0.1, WHITE, (0, 0, 0))])


def nebulamoth(m, C):
    P.base(m, C)
    wing1, wing2 = (200, 120, 255), (255, 140, 220)
    for s in (-1, 1):  # büyük yuvarlak kanatlar (arkada, yukarı-dışa)
        m.ball((1.35 * s, BACK + 0.05, CZ + 0.75), (0.85, 0.08, 0.7), wing1, seg=16, rings=8, rot=(0, -25 * s, 0), name="Wing")
        m.ball((1.1 * s, BACK + 0.1, CZ - 0.05), (0.6, 0.07, 0.5), wing2, seg=14, rings=8, rot=(0, 20 * s, 0), name="WingLow")
        m.ball((1.5 * s, BACK + 0.16, CZ + 0.85), (0.24, 0.04, 0.24), STAR, seg=10, rings=5, name="WingSpot")
        m.ball((1.5 * s, BACK + 0.2, CZ + 0.85), (0.11, 0.03, 0.11), CYAN, seg=8, rings=5, name="WingSpot")
        m.tube([(0.3 * s, 0.4, TOP - 0.05), (0.45 * s, 0.6, TOP + 0.4), (0.75 * s, 0.6, TOP + 0.7)], 0.05, darker(C, 0.35), name="Antenna")
        for k in range(3):  # tüylü anten dalları
            t = 0.4 + 0.2 * k
            m.cone((0.45 * s + 0.12 * k * s, 0.62, TOP + 0.3 + 0.15 * k), 0.06, 0.01, 0.3, lighter(C, 0.5), rot=(0, 60 * s, 0), verts=4, name="Plume")
    m.ball((0, FRONT - 0.08, CZ - 0.4), (0.75, 0.16, 0.42), lighter(C, 0.55), seg=14, rings=8, name="Fluff")
    P.eyes(m, "bead", size=1.15, dz=0.2)
    P.mouth(m, BLACK, -0.34)
    P.cheeks(m, (255, 150, 220), 0.84, -0.18)
    sparkles(m, [(0.0, FRONT - 0.02, CZ + 0.75, 0.15, STAR, (0, 0, 0))])


def nebuladragon(m, C):
    P.base(m, C)
    belly = lighter(C, 0.5)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.55 * s, 0.05, TOP + 0.25), 0.2, 0.03, 0.65, CYAN, rot=(-10, 18 * s, 0), verts=6, name="Horn")
        m.cone((0.45 * s, FRONT - 0.15, CZ - 0.46), 0.07, 0.01, 0.22, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
        m.ball((0.15 * s, FRONT + 0.03, CZ - 0.2), (0.06, 0.05, 0.05), dark, seg=8, rings=5, name="Nostril")
    wings(m, dark, (255, 150, 230), span=1.25)
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.9, 0.06, 0.1), (60, 20, 80), bevel=0.03, name="Mouth")
    for s in (-1, 1):
        m.box((0.46 * s, FRONT + 0.02, CZ - 0.37), (0.2, 0.05, 0.08), (60, 20, 80), bevel=0.02, rot=(0, -35 * s, 0), name="MouthCorner")
    eyes_nd = (90, 255, 230)
    P.eyes(m, "slit", size=1.0, dz=0.24, iris=eyes_nd, color=BLACK)
    for y, col in ((0.35, CYAN), (-0.05, STAR), (-0.45, MAGENTA)):
        m.cone((0, y, TOP + 0.05), 0.16, 0.02, 0.4, col, rot=(0, 0, 45), verts=4, name="Spike")
    # MİTİK: gövdede yıldız benekleri, kafada küçük taç, nebula halesi
    sparkles(m, [(-0.8, FRONT - 0.02, CZ + 0.6, 0.12, STAR, (0, 0, 0)), (0.82, FRONT - 0.02, CZ - 0.55, 0.12, CYAN, (0, 0, 0)), (W / 2 + 0.01, -0.3, CZ + 0.2, 0.18, STAR, (0, 0, 90)), (-W / 2 - 0.01, 0.0, CZ - 0.2, 0.16, WHITE, (0, 0, 90))])
    crown(m, scale=0.6, z=TOP + 0.05, gem=CYAN, side_gem=MAGENTA)
    halo(m, (255, 150, 240), z=TOP + 1.0, r=0.55)
    m.cone((0, BACK - 0.35, 0.75), 0.22, 0.04, 0.9, C, rot=(70, 0, 0), verts=6, name="Tail")
    m.star((0, BACK - 0.85, 0.55), 0.2, STAR, thickness=0.08, rot=(0, 0, 0), name="TailStar")


# ------------------------------------------------------------------ COMET yumurtası
def iceslug(m, C):
    P.base(m, C, feet=lighter(C, 0.3))
    light = lighter(C, 0.5)
    m.box((0, BACK - 0.45, 0.32), (1.5, 1.1, 0.5), C, bevel=0.2, segments=3, name="SlugTail")  # arkaya uzanan gövde
    m.box((0, BACK - 0.95, 0.2), (1.1, 0.6, 0.3), light, bevel=0.12, name="SlugTailTip")
    for s in (-1, 1):
        m.tube([(0.4 * s, 0.25, TOP - 0.1), (0.48 * s, 0.35, TOP + 0.35), (0.55 * s, 0.4, TOP + 0.6)], 0.07, C, name="EyeStalk")
        m.ball((0.55 * s, 0.42, TOP + 0.68), (0.13, 0.13, 0.13), ICE, seg=10, rings=6, name="StalkTip")
    for x, y, h in ((0.0, -0.3, 0.5), (-0.35, -0.6, 0.35), (0.35, -0.55, 0.38)):  # sırtta buz kristalleri
        m.cone((x, y, TOP + h / 2 - 0.05), 0.14, 0.02, h, ICE, verts=6, name="Crystal")
    P.eyes(m, "bead", size=1.0, dz=0.1)
    P.mouth(m, BLACK, -0.36)
    P.cheeks(m, (255, 170, 210), 0.82, -0.22)


def cometbird(m, C):
    P.base(m, C, feet=FIRE_Y)
    m.cone((0, FRONT + 0.28, CZ - 0.1), 0.27, 0.04, 0.58, FIRE_Y, rot=(-90, 0, 0), verts=6, name="Beak")
    m.cone((0, FRONT + 0.2, CZ - 0.34), 0.19, 0.03, 0.4, darker(FIRE_Y, 0.15), rot=(-90, 0, 0), verts=6, name="BeakLow")
    P.eyes(m, "bead", size=1.0, dz=0.22)
    P.cheeks(m, (150, 200, 255), 0.86)
    for x, h, col in ((-0.22, 0.55, CYAN), (0.0, 0.8, ICE), (0.22, 0.55, CYAN)):
        m.cone((x, 0.05, TOP + h / 2 - 0.08), 0.14, 0.02, h, col, rot=(0, -x * 45, 0), verts=5, name="Tuft")
    for s in (-1, 1):
        m.ball((1.08 * s, -0.05, CZ - 0.05), (0.2, 0.6, 0.62), darker(C, 0.1), rot=(0, 0, 10 * s), name="Wing")
    # kuyruklu yıldız kuyruğu: uzun akan tüyler
    for x, length, col in ((0.0, 1.5, CYAN), (-0.3, 1.2, ICE), (0.3, 1.2, ICE), (-0.55, 0.9, (120, 170, 255)), (0.55, 0.9, (120, 170, 255))):
        m.cone((x, BACK - length * 0.42, 0.95 + abs(x) * 0.4), 0.16, 0.02, length, col, rot=(78, 0, -x * 30), verts=5, scale=(1, 0.4, 1), name="TailFeather")


def frostalien(m, C):
    glow = CYAN
    P.base(m, C)
    for s in (-1, 1):
        m.ball((0.5 * s, FRONT - 0.02, CZ + 0.08), (0.42, 0.1, 0.56), (15, 25, 50), seg=16, rings=10, rot=(0, 0, 24 * s), name="Eye")
        m.ball((0.5 * s + 0.08, FRONT + 0.08, CZ + 0.28), (0.1, 0.05, 0.13), WHITE, seg=8, rings=5, name="Shine")
        m.ball((0.5 * s - 0.1, FRONT + 0.07, CZ - 0.05), (0.05, 0.04, 0.06), ICE, seg=8, rings=5, name="Shine")
        m.tube([(0.4 * s, 0.0, TOP - 0.1), (0.5 * s, 0.0, TOP + 0.5), (0.65 * s, 0.0, TOP + 0.9)], 0.06, darker(C, 0.3), name="Antenna")
        m.ball((0.65 * s, 0.0, TOP + 1.0), (0.17, 0.17, 0.17), glow, seg=12, rings=8, name="AntennaOrb")
    for x, y, h, tilt in ((0.0, 0.1, 0.7, 0), (-0.25, -0.3, 0.5, 15), (0.25, -0.35, 0.5, -15)):  # kafada buz kristalleri
        m.cone((x, y, TOP + h / 2 - 0.05), 0.16, 0.02, h, ICE, rot=(0, tilt, 0), verts=6, name="Crystal")
    m.box((0, FRONT + 0.0, CZ - 0.45), (0.3, 0.05, 0.07), darker(C, 0.5), bevel=0.02, name="Mouth")
    m.ball((W / 2, 0.0, CZ - 0.2), (0.05, 0.3, 0.3), ICE, seg=10, rings=5, name="FrostPatch")
    m.ball((-W / 2, -0.2, CZ + 0.3), (0.05, 0.26, 0.26), ICE, seg=10, rings=5, name="FrostPatch")
    P.cheeks(m, (150, 200, 255), 0.86, -0.3, 0.8)
    m.ball((0, BACK - 0.05, CZ - 0.35), (0.22, 0.18, 0.22), lighter(C, 0.3), seg=10, rings=6, name="Tail")


def cometwolf(m, C):
    P.base(m, C)
    dark = darker(C, 0.35)
    L = lighter(C, 0.55)
    P.ears_point(m, C, inner=CYAN, spread=0.7, size=1.15, tilt=10)
    m.box((0, FRONT + 0.1, CZ - 0.34), (0.8, 0.55, 0.5), L, bevel=0.14, segments=3, name="Snout")
    m.ball((0, FRONT + 0.4, CZ - 0.2), (0.15, 0.1, 0.1), BLACK, seg=10, rings=6, name="Nose")
    P.eyes(m, "slit", size=0.9, dz=0.22, iris=CYAN, color=BLACK)
    for s in (-1, 1):
        m.box((0.5 * s, FRONT - 0.02, CZ + 0.5), (0.4, 0.05, 0.1), dark, bevel=0.015, rot=(0, 0, -16 * s), name="Brow")
        m.cone((1.1 * s, FRONT - 0.55, CZ - 0.35), 0.32, 0.03, 0.6, L, rot=(0, 90 * s, 0), verts=4, name="CheekFluff")
    P.mouth(m, BLACK, -0.5, 0.16, 0.24)
    m.star((0, FRONT - 0.02, CZ + 0.72), 0.17, STAR, thickness=0.08, name="Star")
    # LEGENDARY: sırtta akan parlak kuyruklu yıldız yelesi
    for k, (y, h) in enumerate(((0.3, 0.6), (-0.1, 0.75), (-0.5, 0.85))):
        m.cone((0, y, TOP + 0.15), 0.2, 0.02, h, CYAN if k % 2 == 0 else ICE, rot=(55, 0, 0), verts=5, scale=(0.5, 1, 1), name="Mane")
    m.ball((0, BACK - 0.45, 0.85), (0.3, 0.5, 0.3), C, seg=12, rings=8, rot=(35, 0, 0), name="Tail")
    m.ball((0, BACK - 0.85, 1.15), (0.34, 0.45, 0.34), ICE, seg=12, rings=8, name="TailTip")
    flames(m, (CYAN, WHITE, ICE), y=BACK - 0.9, z=1.3, spread=0.3, length=0.8, count=3, up=55)


def cometdragon(m, C):
    P.base(m, C)
    belly = lighter(C, 0.55)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.55 * s, 0.05, TOP + 0.28), 0.22, 0.03, 0.75, ICE, rot=(-12, 16 * s, 0), verts=6, name="Horn")
        m.cone((0.45 * s, FRONT - 0.15, CZ - 0.46), 0.07, 0.01, 0.22, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
        m.ball((0.15 * s, FRONT + 0.03, CZ - 0.2), (0.06, 0.05, 0.05), dark, seg=8, rings=5, name="Nostril")
    wings(m, (235, 245, 255), CYAN, span=1.3)
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.9, 0.06, 0.1), (30, 40, 90), bevel=0.03, name="Mouth")
    P.eyes(m, "white", size=1.0, dz=0.22, iris=(40, 110, 255))
    for y in (0.35, -0.05, -0.45):  # sırtta buz kristali dikenleri
        m.cone((0, y, TOP + 0.15), 0.15, 0.02, 0.55, ICE, verts=6, name="Crystal")
    # MİTİK: buz tacı + kuyruklu yıldız kuyruğu + parıltılar
    for x, h in ((-0.3, 0.5), (0.0, 0.7), (0.3, 0.5)):
        m.cone((x, 0.55, TOP + 0.05 + h / 2), 0.12, 0.02, h, CYAN, verts=6, name="IceCrown")
    halo(m, ICE, z=TOP + 1.05, r=0.55)
    m.cone((0, BACK - 0.35, 0.75), 0.22, 0.04, 0.9, C, rot=(70, 0, 0), verts=6, name="Tail")
    flames(m, (CYAN, ICE, WHITE, (120, 170, 255), CYAN), y=BACK - 0.85, z=0.75, spread=0.45, length=1.1, count=5, up=75)
    sparkles(m, [(-0.82, FRONT - 0.02, CZ + 0.6, 0.12, WHITE, (0, 0, 0)), (0.85, FRONT - 0.02, CZ - 0.6, 0.11, CYAN, (0, 0, 0))])


# ------------------------------------------------------------------ SUPERNOVA yumurtası
def sun_rays(m, cols, r=1.3, count=12, z=CZ + 0.05, y=-0.15, length=0.6):
    """Yüzün çevresinde güneş ışınları (yelesi)."""
    for k in range(count):
        a = 2 * math.pi * k / count
        dx, dz = math.sin(a), math.cos(a)
        m.cone((dx * r, y, z + dz * r), 0.24, 0.02, length, cols[k % len(cols)], rot=(0, math.degrees(a), 0), verts=4, scale=(1, 0.5, 1), name="Ray")


def solarlion(m, C):
    mane, mane2 = (255, 130, 30), FIRE_Y
    P.base(m, C)
    m.box((0, -0.2, CZ + 0.02), (W + 0.7, D - 0.3, H + 0.7), mane, bevel=0.45, segments=3, name="Mane")
    sun_rays(m, (mane2, FIRE), r=1.45, count=12, length=0.55)
    P.ears_round(m, C, inner=lighter(C, 0.5), spread=0.78, size=0.3)
    m.box((0, FRONT - 0.03, CZ - 0.38), (0.95, 0.14, 0.55), CREAM, bevel=0.12, name="Muzzle")
    P.eyes(m, "bead", size=1.0, dz=0.14)
    P.nose(m, (150, 70, 40), -0.2, 1.1)
    P.mouth(m, BLACK, -0.42)
    P.cheeks(m, (255, 140, 100), 0.84, -0.25)
    m.tube([(0, BACK + 0.1, 0.7), (0, BACK - 0.45, 0.8), (0, BACK - 0.65, 1.2)], 0.1, C, name="Tail")
    m.ball((0, BACK - 0.68, 1.3), (0.22, 0.22, 0.24), FIRE, seg=10, rings=6, name="TailTip")


def sunbird(m, C):
    P.base(m, C)
    m.cone((0, FRONT + 0.3, CZ - 0.12), 0.3, 0.05, 0.75, GOLD, rot=(-90, 0, 0), verts=6, name="Beak")
    m.cone((0, FRONT + 0.22, CZ - 0.36), 0.22, 0.04, 0.5, FIRE, rot=(-90, 0, 0), verts=6, name="BeakLow")
    P.eyes(m, "bead", size=0.95, dz=0.2)
    for x, h, col in ((0, 0.95, FIRE_Y), (-0.35, 0.75, FIRE), (0.35, 0.75, FIRE), (-0.65, 0.5, FIRE_Y), (0.65, 0.5, FIRE_Y)):
        m.cone((x, 0.0, TOP + h / 2 - 0.05), 0.18, 0.02, h, col, rot=(0, -x * 16, 0), verts=5, scale=(1, 0.5, 1), name="Crest")
    for s in (-1, 1):
        for k, (length, col) in enumerate(((1.0, C), (0.9, FIRE), (0.75, FIRE_Y))):
            m.cone((1.25 * s, -0.1, CZ + 0.15 + 0.14 * k), 0.2, 0.03, length, col, rot=(0, 90 * s - 15 * k * s, 0), verts=5, scale=(1, 0.2, 1), name="Feather")
    m.ball((0, FRONT - 0.05, CZ - 0.6), (0.6, 0.12, 0.3), FIRE_Y, seg=12, rings=6, name="Chest")
    for x, col in ((0, FIRE), (-0.3, FIRE_Y), (0.3, FIRE_Y)):
        m.cone((x, BACK - 0.35, 0.8 + abs(x)), 0.14, 0.02, 0.9, col, rot=(70, 0, -x * 25), verts=5, scale=(1, 0.4, 1), name="TailFeather")
    P.cheeks(m, FIRE, 0.85)


def novabeast(m, C):
    dark = darker(C, 0.35)
    P.base(m, C, feet=dark)
    for s in (-1, 1):  # büyük kıvrık boynuzlar
        m.tube([(0.6 * s, 0.0, TOP - 0.1), (0.95 * s, 0.05, TOP + 0.3), (1.0 * s, 0.25, TOP + 0.75), (0.8 * s, 0.4, TOP + 1.0)], 0.13, (255, 235, 200), name="Horn")
        m.box((0.5 * s, FRONT - 0.02, CZ + 0.5), (0.5, 0.06, 0.12), dark, bevel=0.02, rot=(0, 0, -14 * s), name="Brow")
        m.cone((0.3 * s, FRONT - 0.05, CZ - 0.6), 0.08, 0.01, 0.26, WHITE, rot=(0, 0, 0), verts=4, name="Tusk")
    m.box((0, FRONT - 0.04, CZ - 0.38), (1.0, 0.18, 0.55), lighter(C, 0.4), bevel=0.14, name="Muzzle")
    P.eyes(m, "slit", size=1.0, dz=0.18, iris=FIRE_Y, color=BLACK)
    P.nose(m, BLACK, -0.24, 1.2)
    m.box((0, FRONT + 0.0, CZ - 0.5), (0.5, 0.06, 0.08), BLACK, bevel=0.02, name="Mouth")
    # EPIC: göğüste parlayan süpernova yıldızı (yanlarda)
    for s in (-1, 1):
        m.star((W / 2 * s + 0.01 * s, 0.0, CZ + 0.1), 0.35, FIRE_Y, thickness=0.08, points=6, rot=(0, 0, 90), name="SideNova")
    for x, y in ((-0.4, -0.2), (0.4, -0.3), (0.0, -0.6)):
        m.cone((x, y, TOP + 0.12), 0.16, 0.02, 0.35, FIRE, rot=(0, 0, 45), verts=4, name="Spike")
    m.cone((0, BACK - 0.35, 0.75), 0.22, 0.04, 0.9, C, rot=(70, 0, 0), verts=6, name="Tail")
    m.ball((0, BACK - 0.75, 0.6), (0.18, 0.18, 0.18), FIRE_Y, seg=10, rings=6, name="TailTip")


def flaredrake(m, C):
    P.base(m, C)
    dark = darker(C, 0.3)
    for s in (-1, 1):
        m.cone((0.55 * s, 0.05, TOP + 0.25), 0.2, 0.03, 0.65, FIRE_Y, rot=(-10, 18 * s, 0), verts=6, name="Horn")
        m.cone((0.45 * s, FRONT - 0.15, CZ - 0.46), 0.07, 0.01, 0.22, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
        m.ball((0.15 * s, FRONT + 0.03, CZ - 0.2), (0.06, 0.05, 0.05), dark, seg=8, rings=5, name="Nostril")
    wings(m, dark, FIRE, span=1.35)
    for s in (-1, 1):  # kanat uçlarında alev
        m.cone((2.05 * s, -0.75, CZ + 0.95), 0.18, 0.02, 0.55, FIRE_Y, rot=(0, 30 * s, 0), verts=5, name="WingFlame")
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.9, 0.06, 0.1), (90, 20, 20), bevel=0.03, name="Mouth")
    P.eyes(m, "white", size=1.0, dz=0.22, iris=(255, 120, 20))
    for y, col in ((0.35, FIRE_Y), (-0.05, FIRE), (-0.45, FIRE_Y)):
        m.cone((0, y, TOP + 0.1), 0.17, 0.02, 0.5, col, rot=(0, 0, 45), verts=4, name="Spike")
    # LEGENDARY: alev kuyruk + yanaklarda kor
    m.cone((0, BACK - 0.35, 0.75), 0.22, 0.04, 0.9, C, rot=(70, 0, 0), verts=6, name="Tail")
    flames(m, (FIRE, FIRE_Y, (255, 80, 40)), y=BACK - 0.85, z=0.7, spread=0.35, length=0.9, count=4, up=72)
    P.cheeks(m, FIRE_Y, 0.85, -0.25)


def novaking(m, C):
    P.base(m, C, feet=GOLD_D)
    for s in (-1, 1):
        m.box((0.52 * s, FRONT - 0.03, CZ + 0.5), (0.5, 0.06, 0.12), GOLD_D, bevel=0.02, rot=(0, 0, -14 * s), name="Brow")
    P.ears_round(m, C, inner=GOLD, spread=0.86, size=0.32)
    m.box((0, FRONT - 0.05, CZ - 0.38), (1.0, 0.45, 0.58), (255, 248, 230), bevel=0.15, segments=3, name="Snout")
    P.nose(m, (120, 70, 30), -0.18, 1.2)
    P.mouth(m, BLACK, -0.4)
    P.eyes(m, "white", size=1.0, dz=0.14, iris=(255, 150, 20))
    P.cheeks(m, (255, 150, 120), 0.85)
    # MİTİK: taç, arkada büyük güneş halesi (halka + ışınlar), altın kanatlar, pelerin
    crown(m, gem=(255, 60, 60), side_gem=(255, 140, 30))
    m.torus((0, BACK - 0.25, CZ + 0.3), 1.45, 0.09, GOLD, rot=(90, 0, 0), major_seg=36, minor_seg=6, name="SunHalo")
    for k in range(16):
        a = 2 * math.pi * k / 16
        m.cone((math.sin(a) * 1.75, BACK - 0.25, CZ + 0.3 + math.cos(a) * 1.75), 0.14, 0.02, 0.45 if k % 2 else 0.65, FIRE_Y if k % 2 else FIRE, rot=(0, math.degrees(a), 0), verts=4, scale=(1, 0.4, 1), name="SunRay")
    wings(m, GOLD, (255, 250, 220), span=1.15, z=CZ + 0.2, y=-0.2)
    m.box((0, BACK - 0.06, CZ - 0.1), (W - 0.3, 0.14, H - 0.2), (200, 30, 60), bevel=0.06, name="Cape")  # sırtta kraliyet pelerini
    for s_ in (-1, 1):
        m.ball((0.75 * s_, FRONT - 0.3, TOP - 0.05), (0.12, 0.12, 0.08), WHITE, seg=8, rings=5, name="CapePin")


# ------------------------------------------------------------------ BLACKHOLE yumurtası
def voidbat(m, C):
    P.base(m, C, feet=darker(C, 0.3))
    inner = (200, 90, 255)
    P.ears_point(m, C, inner=inner, spread=0.62, size=1.2, tilt=8)
    for s in (-1, 1):  # yarasa kanatları: üçgen zarlar + kemik
        m.cone((1.4 * s, -0.3, CZ + 0.3), 0.6, 0.04, 1.4, darker(C, 0.15), rot=(0, 75 * s, 15 * s), verts=3, scale=(1, 0.15, 1), name="Wing")
        m.cone((1.33 * s, -0.25, CZ + 0.22), 0.45, 0.03, 1.1, (120, 60, 180), rot=(0, 75 * s, 15 * s), verts=3, scale=(1, 0.1, 1), name="WingFill")
        m.cone((0.22 * s, FRONT + 0.0, CZ - 0.5), 0.07, 0.01, 0.22, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.55, 0.2, 0.34), lighter(C, 0.3), seg=14, rings=8, name="Muzzle")
    glow_eyes(m, (200, 110, 255), size=1.0, dz=0.14)
    m.cone((0, FRONT + 0.06, CZ - 0.16), 0.1, 0.02, 0.15, (60, 30, 80), rot=(180, 0, 45), verts=4, name="Nose")
    m.box((0, FRONT + 0.0, CZ - 0.4), (0.5, 0.05, 0.06), BLACK, bevel=0.02, name="Mouth")
    P.cheeks(m, (200, 110, 255), 0.84, -0.24, 0.8)


def darkoctopus(m, C):
    body_only(m, C)
    glow = (180, 90, 255)
    m.box((0, -0.15, TOP + 0.25), (W - 0.3, D - 0.4, 0.6), C, bevel=0.25, segments=3, name="Dome")  # yuvarlak kafa üstü
    for x, y, s in ((-0.5, -0.1, 0.13), (0.45, 0.2, 0.1), (0.1, -0.5, 0.11), (0.35, -0.3, 0.08)):  # parlayan benekler
        m.ball((x, y, TOP + 0.56), (s, s, 0.05), glow, seg=8, rings=5, name="GlowSpot")
    tentacles(m, C, tip=glow, count=8, curl=1.4)
    for k in range(8):  # tentakül altında vantuz renkleri
        a = 2 * math.pi * (k + 0.5) / 8
        m.ball((math.sin(a) * 0.85, math.cos(a) * 0.78, 0.18), (0.08, 0.08, 0.05), (255, 150, 230), seg=6, rings=4, name="Sucker")
    glow_eyes(m, glow, size=1.1, dz=0.08)
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.35, 0.05, 0.07), BLACK, bevel=0.02, name="Mouth")
    P.cheeks(m, (255, 120, 220), 0.84, -0.3, 0.8)


def voidcat(m, C):
    P.base(m, C, feet=darker(C, 0.3))
    glow = (90, 240, 255)
    P.ears_point(m, C, inner=(150, 80, 230), spread=0.66, size=1.05)
    m.ball((0, FRONT - 0.05, CZ - 0.32), (0.5, 0.2, 0.34), lighter(C, 0.25), seg=14, rings=8, name="Muzzle")
    P.eyes(m, "slit", size=1.15, dz=0.12, iris=glow, color=VOID)
    P.nose(m, (255, 120, 220), -0.16)
    P.mouth(m, (200, 180, 255), -0.36)
    P.whiskers(m, (190, 170, 255))
    # EPIC: alnında girdap (küçük kara delik), yanlarda yıldızlar, kuyruk ucu yıldız
    m.torus((0, FRONT + 0.0, CZ + 0.66), 0.17, 0.05, (200, 110, 255), rot=(90, 0, 0), major_seg=14, minor_seg=5, name="Swirl")
    m.ball((0, FRONT - 0.01, CZ + 0.66), (0.11, 0.05, 0.11), VOID, seg=10, rings=6, name="SwirlCore")
    sparkles(m, [(W / 2 + 0.01, -0.2, CZ + 0.35, 0.18, glow, (0, 0, 90)), (-W / 2 - 0.01, 0.1, CZ - 0.2, 0.16, (200, 110, 255), (0, 0, 90)), (0.4, -0.3, TOP + 0.01, 0.16, WHITE, (90, 0, 0))])
    P.tail_curl(m, C, tip=glow)


def voidserpent(m, C):
    dark = darker(C, 0.35)
    glow = (120, 255, 200)
    belly = (150, 110, 220)
    P.base(m, C, feet=dark)
    for r, z, col in ((0.8, 0.35, C), (0.62, 0.8, dark), (0.46, 1.2, C)):
        m.torus((0, BACK - 0.6, z), r, 0.3, col, major_seg=22, minor_seg=8, name="Coil")
    for k in range(6):  # bobinlerde parlayan çizgiler
        a = 2 * math.pi * k / 6
        m.ball((math.sin(a) * 1.1, BACK - 0.6 + math.cos(a) * 1.1, 0.35), (0.09, 0.09, 0.09), glow, seg=8, rings=5, name="GlowScale")
    m.cone((0, BACK - 0.6, 1.75), 0.3, 0.02, 0.7, C, verts=8, name="TailTip")
    for s in (-1, 1):  # kobra başlığı
        m.ball((1.1 * s, -0.15, CZ + 0.3), (0.35, 0.18, 0.85), dark, seg=12, rings=8, rot=(0, 0, -12 * s), name="Hood")
        m.ball((1.12 * s, -0.04, CZ + 0.35), (0.16, 0.1, 0.42), glow, seg=10, rings=6, rot=(0, 0, -12 * s), name="HoodMark")
        m.cone((0.32 * s, FRONT + 0.02, CZ - 0.5), 0.07, 0.01, 0.24, WHITE, rot=(180, 0, 0), verts=4, name="Fang")
    for y, s in ((0.3, 1.0), (-0.1, 0.9), (-0.45, 0.8)):
        m.box((0, y, TOP), (0.34 * s, 0.34 * s, 0.05), glow, bevel=0.015, rot=(0, 0, 45), name="Diamond")
    m.box((0, FRONT - 0.03, CZ - 0.5), (0.95, 0.1, 0.4), belly, bevel=0.08, name="Chin")
    P.eyes(m, "slit", size=1.05, dz=0.2, iris=glow, color=BLACK)
    m.box((0, FRONT + 0.3, CZ - 0.36), (0.1, 0.6, 0.05), (255, 80, 160), bevel=0.01, name="Tongue")
    for s in (-1, 1):
        m.box((0.08 * s, FRONT + 0.66, CZ - 0.36), (0.07, 0.24, 0.05), (255, 80, 160), bevel=0.01, rot=(0, 0, -22 * s), name="TongueFork")
    halo(m, glow, z=TOP + 0.45, r=0.5)


def singularity(m, C):
    accretion, accretion2 = (255, 150, 50), (255, 90, 200)
    glow = (190, 120, 255)
    P.base(m, C, feet=(60, 40, 90))
    P.ears_point(m, C, inner=glow, spread=0.66, size=0.95)
    glow_eyes(m, (255, 255, 255), size=1.15, dz=0.12)
    for s in (-1, 1):  # gözlerin etrafında mor parıltı halkası
        m.torus((0.52 * s, FRONT + 0.01, CZ + 0.12), 0.32, 0.04, glow, rot=(90, 0, 0), major_seg=14, minor_seg=4, name="EyeRing")
    m.box((0, FRONT + 0.0, CZ - 0.42), (0.5, 0.05, 0.07), glow, bevel=0.02, name="Mouth")
    P.cheeks(m, (255, 100, 220), 0.84, -0.3, 0.8)
    # MİTİK: gövdeyi saran çift yığılma diski (turuncu + pembe), taç, hale, yörüngede yıldızlar
    orbit_ring(m, accretion, r=1.65, minor=0.12)
    orbit_ring(m, accretion2, r=1.92, minor=0.07)
    orbit_ring(m, FIRE_Y, r=1.42, minor=0.05)
    crown(m, gold=(220, 190, 255), gem=(255, 255, 255), side_gem=accretion, scale=0.85)
    halo(m, glow, z=TOP + 1.0, r=0.6)
    sparkles(m, [(1.6, 0.6, CZ + 1.3, 0.18, WHITE, (0, 0, 0)), (-1.55, 0.5, CZ + 1.0, 0.14, glow, (0, 0, 0)), (0.0, BACK - 0.3, TOP + 0.3, 0.16, accretion, (0, 0, 0))])


# (id, çizici, renk): yumurta sırasıyla, her yumurtada en yaygından en nadire. Renkler Config.Pets (Dünya 2) ile AYNI olmalı.
EGG_PETS = {
    "moon": ["astrocat", "moonbunny", "craterpup", "lunarowl", "mooncow"],
    "asteroid": ["rockbeetle", "meteorpig", "astercrab", "cometfox", "asteroidgolem"],
    "nebula": ["nebulajelly", "cloudsquid", "starfish", "nebulamoth", "nebuladragon"],
    "comet": ["iceslug", "cometbird", "frostalien", "cometwolf", "cometdragon"],
    "supernova": ["solarlion", "sunbird", "novabeast", "flaredrake", "novaking"],
    "blackhole": ["voidbat", "darkoctopus", "voidcat", "voidserpent", "singularity"],
}

PETS = [
    ("astrocat", astrocat, (185, 195, 235)),
    ("moonbunny", moonbunny, (250, 245, 220)),
    ("craterpup", craterpup, (175, 178, 195)),
    ("lunarowl", lunarowl, (80, 90, 170)),
    ("mooncow", mooncow, (245, 240, 255)),
    ("rockbeetle", rockbeetle, (140, 120, 110)),
    ("meteorpig", meteorpig, (250, 150, 120)),
    ("astercrab", astercrab, (230, 110, 80)),
    ("cometfox", cometfox, (80, 150, 255)),
    ("asteroidgolem", asteroidgolem, (105, 95, 125)),
    ("nebulajelly", nebulajelly, (255, 140, 220)),
    ("cloudsquid", cloudsquid, (175, 150, 255)),
    ("starfish", starfish, (255, 165, 110)),
    ("nebulamoth", nebulamoth, (110, 215, 220)),
    ("nebuladragon", nebuladragon, (205, 90, 235)),
    ("iceslug", iceslug, (150, 215, 255)),
    ("cometbird", cometbird, (225, 238, 255)),
    ("frostalien", frostalien, (140, 230, 255)),
    ("cometwolf", cometwolf, (60, 85, 170)),
    ("cometdragon", cometdragon, (120, 200, 255)),
    ("solarlion", solarlion, (255, 205, 80)),
    ("sunbird", sunbird, (255, 110, 40)),
    ("novabeast", novabeast, (230, 70, 60)),
    ("flaredrake", flaredrake, (255, 95, 30)),
    ("novaking", novaking, (255, 245, 215)),
    ("voidbat", voidbat, (85, 60, 125)),
    ("darkoctopus", darkoctopus, (70, 45, 110)),
    ("voidcat", voidcat, (45, 35, 70)),
    ("voidserpent", voidserpent, (55, 50, 105)),
    ("singularity", singularity, (30, 22, 50)),
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
        S.record(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "pet_" + pet_id + ".fbx"))
        print("MODEL", pet_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    name = "pets_space_check.png" if wanted else "pets_space_lineup.png"
    S.render_grid(models, os.path.join(c.OUT, "previews", name), cols=min(5, len(models)), spacing=(4.8, 5.6), height=1.3, elevation=38, resolution=1800)
    if not wanted:
        c.save_blend(os.path.join(c.OUT, "blend", "pets_space.blend"))


if __name__ == "__main__":
    main()
