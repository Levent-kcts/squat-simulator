"""10 antrenör (Config.Training.Areas): pet modelleriyle aynı KUTU/sevimli üslup, iri yuvarlak başlı, kollarını kas yapan (biceps) minik koçlar.
Her koçun vücudu pedinin rengindedir (Config.Training.Areas[].color), siyah şortu vardır (çocuk oyunu: kalça bölgesi her zaman kapalı), boynunda düdük asılıdır;
kıyafeti/aksesuarı server/Mannequin'deki yer tutucu antrenörle aynı temayı taşır (Sprout yaprak, Wave dalga, Blaze alev, Ember köz, Pixel piksel, Frost buz, Volt şimşek, Nova yıldız, Prism gökkuşağı, Shadow gölge).
Parçacıklar (ateş, kar, kıvılcım, duman) modele GÖMÜLÜ DEĞİLDİR, Mannequin.luau kodla ekler. Model adı: coach_<kıyafet> (leaf, wave, flame, ember, pixel, frost, volt, nova, prism, shadow).
Her model TEK MESH + palet dokusu (lib.py). Ön +Y, orijin tabanın ortası, ~5.3 stud boy (+ aksesuar). Çalıştırma:
    blender -b -P tools/blender/coaches.py              (hepsi)
    blender -b -P tools/blender/coaches.py -- leaf wave (seçilenler)
Çıktı: assets/blender/fbx/coach_<kıyafet>.fbx, textures/, previews/coaches_lineup.png, blend/coaches_all.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402
import common as c  # noqa: E402
from lib import Model, darker, lighter, mix, record_manifest  # noqa: E402

BLACK = (34, 28, 40)
WHITE = (255, 255, 255)
SHORTS = (20, 20, 25)
GOLD = (255, 205, 70)
PINK = (255, 150, 175)

HEAD_Z = 4.3  # kafa merkezi
HW, HD, HH = 2.1, 1.9, 1.9  # kafa kutusu
FRONT = HD / 2  # yüzün ön düzlemi (y)
TOP = HEAD_Z + HH / 2  # kafanın tepesi
EYE_Z = 4.18
BAND_Z = 4.98


# ------------------------------------------------------------------ yardımcılar
def aim(zdir, ydir=(0, 0, 1)):
    """Yerel Z'yi zdir'e (ve Y'yi mümkünse ydir'e) bakan Euler (derece)."""
    z = Vector(zdir).normalized()
    y = Vector(ydir) - z * Vector(ydir).dot(z)
    if y.length < 1e-6:
        y = Vector((1, 0, 0)) - z * z.x
    y.normalize()
    x = y.cross(z)
    matrix = Matrix((x, y, z)).transposed()
    return tuple(math.degrees(a) for a in matrix.to_euler())


def spike(m, base, direction, length, radius, rgb, verts=6, tip=0.03, name="Spike"):
    """Tabanı base'de, ucu direction yönünde koni."""
    d = Vector(direction).normalized()
    center = Vector(base) + d * (length / 2)
    return m.cone(tuple(center), radius, tip, length, rgb, rot=aim(d), verts=verts, name=name)


def leaf(m, base, direction, length, width, rgb, face=(0, 0, 1), name="Leaf"):
    """Yaprak: yassı elips, tabanı base'de, ucu direction yönünde (yassı yüzünün normali face yönüne yakın)."""
    d = Vector(direction).normalized()
    center = Vector(base) + d * (length / 2)
    return m.ball(tuple(center), (width, 0.07, length / 2), rgb, seg=10, rings=6, rot=aim(d, face), name=name)


def ring_positions(count, radius, z, start=0.0):
    for index in range(count):
        angle = start + index * (2 * math.pi / count)
        yield angle, (math.cos(angle) * radius, math.sin(angle) * radius, z)


def headband(m, rgb, trim=None, z=BAND_Z):
    m.box((0, 0, z), (HW + 0.1, HD + 0.1, 0.32), rgb, bevel=0.1, name="Band")
    if trim:
        m.box((0, FRONT + 0.06, z), (0.42, 0.06, 0.42), trim, bevel=0.05, name="BandBadge")


def box_at(m, x, y, z, w, d, h, rgb, bevel=0.03, rot=(0, 0, 0), name="Bit"):
    return m.box((x, y, z), (w, d, h), rgb, bevel=bevel, rot=rot, name=name)


def eyes(m, style="bead", color=BLACK, glow=None):
    for s in (-1, 1):
        x = 0.5 * s
        if style == "glow":  # parlayan göz (Shadow)
            m.ball((x, FRONT - 0.02, EYE_Z), (0.28, 0.1, 0.2), glow, seg=14, rings=8, name="Eye")
            m.ball((x, FRONT + 0.06, EYE_Z), (0.09, 0.05, 0.1), WHITE, seg=8, rings=5, name="Pupil")
            continue
        m.ball((x, FRONT - 0.02, EYE_Z), (0.27, 0.1, 0.33), WHITE, seg=14, rings=8, name="Eye")
        m.ball((x, FRONT + 0.05, EYE_Z - 0.02), (0.17, 0.08, 0.22), glow or color, seg=12, rings=8, name="Pupil")
        m.ball((x + 0.06, FRONT + 0.11, EYE_Z + 0.07), (0.065, 0.04, 0.07), WHITE, seg=8, rings=5, name="Shine")
        m.ball((x - 0.05, FRONT + 0.1, EYE_Z - 0.09), (0.03, 0.03, 0.035), WHITE, seg=8, rings=5, name="Shine")


def brows(m, rgb, tilt=0.0, z=4.66):
    """tilt > 0: iç uçlar aşağıda (kararlı/kızgın bakış), < 0: iç uçlar yukarıda (şefkatli)."""
    for s in (-1, 1):
        m.box((0.5 * s, FRONT + 0.0, z), (0.5, 0.08, 0.11), rgb, bevel=0.03, rot=(0, -tilt * s, 0), name="Brow")


def mouth(m, style="smile", rgb=BLACK, z=3.62):
    if style == "grin":  # açık ağız
        m.ball((0, FRONT - 0.01, z), (0.38, 0.1, 0.2), rgb, seg=14, rings=8, name="Mouth")
        m.box((0, FRONT + 0.07, z + 0.08), (0.46, 0.04, 0.09), WHITE, bevel=0.02, name="Teeth")
        m.ball((0, FRONT + 0.06, z - 0.1), (0.2, 0.05, 0.08), PINK, seg=10, rings=6, name="Tongue")
        return
    if style == "flat":
        m.box((0, FRONT + 0.02, z), (0.5, 0.06, 0.07), rgb, bevel=0.025, name="Mouth")
        return
    lift = 0.2 if style == "smile" else 0.12
    pts = []
    for i in range(-5, 6):
        x = i * 0.07
        skew = 0.1 * x if style == "smirk" else 0
        pts.append((x, FRONT + 0.03, z + 0.02 + lift * (x / 0.35) ** 2 * 0.5 + skew))
    m.tube(pts, 0.04, rgb, name="Mouth", taper=False)


def blush(m, rgb):
    for s in (-1, 1):
        m.ball((0.84 * s, FRONT - 0.07, 3.85), (0.2, 0.06, 0.11), rgb, seg=10, rings=6, name="Blush")


def whistle(m, rgb=(235, 235, 245), cord=(40, 40, 50)):
    for s in (-1, 1):
        m.box((0.36 * s, 0.6, 3.32), (0.7, 0.05, 0.07), cord, bevel=0.01, rot=(0, 52 * s, 0), name="Cord")
    m.box((0, 0.66, 3.05), (0.32, 0.2, 0.17), rgb, bevel=0.05, name="Whistle")
    m.ball((0.13, 0.67, 3.05), (0.1, 0.1, 0.1), rgb, seg=8, rings=6, name="Whistle")


def figure(m, C, tank, shoe, sole=WHITE, wrist=None, mouth_style="smile", brow_tilt=None, brow_color=None, eye_style="bead",
           eye_color=BLACK, glow=None, face=True, blush_color=None, tank_trim=None, belt=None):
    """Ortak gövde: bacak + ayakkabı, siyah şort, kolsuz atlet, kaslı kollar (biceps pozu), iri yuvarlak baş, düdük."""
    for s in (-1, 1):
        m.box((0.52 * s, 0.0, 1.0), (0.86, 0.9, 1.1), C, bevel=0.12, name="Leg")
        m.box((0.52 * s, 0.2, 0.3), (1.0, 1.35, 0.6), shoe, bevel=0.15, segments=3, name="Shoe")
        m.box((0.52 * s, 0.2, 0.06), (1.02, 1.37, 0.14), sole, bevel=0.05, name="Sole")
    m.box((0, 0, 1.86), (2.12, 1.1, 0.95), SHORTS, bevel=0.2, segments=3, name="Shorts")
    if belt:
        m.box((0, 0, 2.28), (2.16, 1.14, 0.16), belt, bevel=0.05, name="Belt")
    m.box((0, 0, 2.88), (2.0, 1.05, 1.35), C, bevel=0.18, segments=3, name="Torso")
    m.box((0, 0, 2.8), (2.08, 1.13, 1.1), tank, bevel=0.1, name="Tank")
    if tank_trim:
        m.box((0, 0, 2.3), (2.1, 1.15, 0.14), tank_trim, bevel=0.04, name="TankHem")
    for s in (-1, 1):
        m.box((0.62 * s, 0, 3.45), (0.46, 1.1, 0.36), tank, bevel=0.07, name="Strap")
        # kollar: yan uzanan üst kol + yukarı kıvrık ön kol + yumruk (biceps pozu)
        m.box((1.58 * s, 0, 3.15), (1.1, 0.8, 0.8), C, bevel=0.2, segments=3, name="UpperArm")
        m.ball((1.58 * s, 0, 3.52), (0.52, 0.46, 0.44), C, seg=12, rings=8, name="Biceps")
        m.box((2.0 * s, 0, 3.95), (0.82, 0.82, 1.2), C, bevel=0.2, segments=3, name="Forearm")
        m.box((2.0 * s, 0.03, 4.78), (0.98, 0.95, 0.8), C, bevel=0.28, segments=3, name="Fist")
        if wrist:
            m.box((2.0 * s, 0, 4.3), (0.92, 0.92, 0.26), wrist, bevel=0.05, name="Wristband")
    m.box((0, 0, HEAD_Z), (HW, HD, HH), C, bevel=0.4, segments=4, name="Head")
    for s in (-1, 1):
        m.ball((1.08 * s, 0, 4.2), (0.2, 0.22, 0.26), C, seg=10, rings=6, name="Ear")
    if face:
        eyes(m, eye_style, eye_color, glow)
        if brow_tilt is not None:
            brows(m, brow_color or darker(C, 0.5), brow_tilt)
        mouth(m, mouth_style)
    if blush_color:
        blush(m, blush_color)
    whistle(m)


# ------------------------------------------------------------------ koçlar
def sprout(m, C):
    brown, dark, light = (120, 78, 36), (30, 140, 62), (150, 245, 125)
    figure(m, C, tank=(252, 242, 210), shoe=brown, wrist=brown, mouth_style="smile", brow_tilt=-6, blush_color=lighter(C, 0.55), tank_trim=dark)
    headband(m, brown, trim=light)
    for i, (angle, pos) in enumerate(ring_positions(7, 0.88, BAND_Z + 0.1)):
        out = Vector((math.cos(angle), math.sin(angle), 0))
        leaf(m, pos, out * 0.55 + Vector((0, 0, 1)), 0.95, 0.3, dark if i % 2 else light, face=out)
    # tepede filiz
    m.tube([(0, 0, TOP - 0.1), (0, 0.04, TOP + 0.5), (0.05, 0.1, TOP + 0.85)], 0.09, dark, name="Stem", taper=False)
    leaf(m, (0.05, 0.1, TOP + 0.85), (0.85, 0, 0.5), 0.8, 0.26, light, face=(0, 0, 1))
    leaf(m, (0.05, 0.1, TOP + 0.85), (-0.85, 0, 0.5), 0.8, 0.26, dark, face=(0, 0, 1))
    # göğüste yaprak amblemi
    m.ball((0, 0.58, 2.68), (0.3, 0.05, 0.15), light, seg=10, rings=6, rot=(0, 35, 0), name="LeafMark")
    box_at(m, 0, 0.58, 2.62, 0.5, 0.04, 0.04, dark, rot=(0, 35, 0), name="LeafVein")


def wave(m, C):
    white, navy, cyan = (242, 249, 255), (28, 55, 150), (110, 225, 255)
    figure(m, C, tank=navy, shoe=white, sole=cyan, wrist=white, mouth_style="smile", brow_tilt=0, blush_color=lighter(C, 0.5), tank_trim=cyan)
    headband(m, white, trim=cyan)
    for s in (-1, 1):  # arkada uçuşan kurdele kuyrukları
        box_at(m, 0.3 * s, -1.2, 4.7, 0.34, 0.7, 0.12, white, bevel=0.04, rot=(-20, 0, 12 * s), name="BandTail")
        box_at(m, 0.5 * s, -1.65, 4.45, 0.3, 0.5, 0.1, cyan, bevel=0.04, rot=(-35, 0, 20 * s), name="BandTail")
    # tepede dalga kıvrımı
    m.tube([(0, -0.6, TOP - 0.05), (0, -0.4, TOP + 0.5), (0, 0.1, TOP + 0.95), (0, 0.65, TOP + 0.9), (0, 0.95, TOP + 0.55)], 0.32, cyan, name="Curl")
    # göğüste dalga çizgileri
    for k, zz in enumerate((2.8, 2.55)):
        pts = [(x / 10, 0.6, zz + 0.07 * math.sin(x / 10 * 8 + k)) for x in range(-5, 6)]
        m.tube(pts, 0.04, white if k == 0 else cyan, name="WaveLine", taper=False)


def blaze(m, C):
    char, orange, yellow = (45, 35, 40), (255, 130, 30), (255, 220, 70)
    figure(m, C, tank=char, shoe=char, sole=orange, wrist=orange, mouth_style="grin", brow_tilt=14, brow_color=(110, 20, 20), blush_color=lighter(C, 0.4), tank_trim=orange)
    headband(m, char, trim=orange)
    # alev saçı: büyük turuncu dilimler + içlerinde sarı
    plan = [(0.0, 0.0, 1.5, 0.42), (-0.55, 0.05, 1.15, 0.36), (0.55, 0.05, 1.15, 0.36), (-0.9, -0.1, 0.8, 0.3), (0.9, -0.1, 0.8, 0.3), (0.0, -0.5, 1.2, 0.36), (0.0, 0.5, 0.8, 0.3)]
    for x, y, h, r in plan:
        spike(m, (x, y, TOP - 0.25), (x * 0.25, -0.2 + y * 0.2, 1), h, r, orange, verts=6, name="Flame")
        spike(m, (x, y + 0.02, TOP - 0.2), (x * 0.25, -0.2 + y * 0.2, 1), h * 0.65, r * 0.6, yellow, verts=6, name="FlameCore")
    # göğüste alev amblemi
    spike(m, (0, 0.58, 2.38), (0, 0, 1), 0.62, 0.27, orange, verts=5, name="FlameMark")
    spike(m, (0, 0.6, 2.38), (0, 0, 1), 0.4, 0.15, yellow, verts=5, name="FlameMark")


def ember(m, C):
    dark, red, glow = (62, 40, 36), (170, 45, 25), (255, 205, 60)
    figure(m, C, tank=dark, shoe=red, sole=glow, wrist=dark, mouth_style="smirk", brow_tilt=9, brow_color=(120, 50, 10), blush_color=lighter(C, 0.45), tank_trim=red)
    headband(m, red, trim=glow)
    # tepede küçük alev tutamı
    for x, h in ((-0.4, 0.55), (0.0, 0.85), (0.4, 0.55)):
        spike(m, (x, 0, TOP - 0.2), (0, -0.1, 1), h, 0.28, (255, 110, 35), verts=5, name="Tuft")
    # uçuşan közler
    bits = [((-1.5, 0.2, 5.9), 0.26, (255, 205, 60)), ((1.4, -0.1, 6.2), 0.2, (255, 110, 35)), ((0.5, 0.5, 6.6), 0.22, (255, 235, 150)), ((-0.7, -0.5, 6.7), 0.18, (255, 150, 40)),
            ((1.7, 0.4, 5.5), 0.17, (255, 235, 150)), ((-1.9, -0.2, 6.5), 0.15, (255, 110, 35))]
    for index, (pos, size, rgb) in enumerate(bits):
        m.box(pos, (size, size, size), rgb, bevel=0.03, rot=(20 + index * 17, 15 * index, 30 + index * 11), name="Ember")
    # atlet üstünde parlayan köz noktaları
    for x, z in ((-0.55, 2.55), (0.4, 2.75), (0.05, 2.45), (-0.2, 2.95), (0.6, 2.5)):
        box_at(m, x, 0.58, z, 0.13, 0.05, 0.13, glow, bevel=0.02, rot=(0, 30, 0), name="Cinder")


def pixel(m, C):
    navy, cyan = (30, 25, 85), (90, 240, 255)
    figure(m, C, tank=navy, shoe=(25, 25, 40), sole=cyan, wrist=cyan, mouth_style="smirk", brow_tilt=None, face=False, blush_color=lighter(C, 0.5), tank_trim=cyan)
    # gözlük (gözler arkada kaldığı için ayrı çizilmez)
    m.box((0, FRONT + 0.06, 4.2), (2.05, 0.17, 0.52), (20, 20, 28), bevel=0.04, name="Shades")
    for s in (-1, 1):
        m.box((0.5 * s, FRONT + 0.15, 4.2), (0.76, 0.1, 0.4), (14, 14, 38), bevel=0.04, name="Lens")
        box_at(m, 0.5 * s - 0.15, FRONT + 0.22, 4.3, 0.14, 0.04, 0.14, cyan, bevel=0.01, name="Glint")
        box_at(m, 0.5 * s + 0.13, FRONT + 0.22, 4.12, 0.08, 0.04, 0.08, (255, 90, 235), bevel=0.01, name="Glint")
        box_at(m, 1.08 * s, 0.35, 4.22, 0.1, 1.2, 0.12, (20, 20, 28), bevel=0.02, name="Temple")
    mouth(m, "smirk")
    # basamaklı piksel saç
    hair = [((-0.75, 5.5), cyan), ((-0.25, 5.5), (40, 120, 255)), ((0.25, 5.5), cyan), ((0.75, 5.5), (40, 120, 255)),
            ((-0.25, 5.98), (40, 120, 255)), ((0.25, 5.98), cyan), ((0.75, 5.98), (255, 255, 255)),
            ((0.75, 6.46), cyan)]
    for (x, z), rgb in hair:
        m.box((x, 0.0, z), (0.5, 1.5, 0.5), rgb, bevel=0.04, name="PixelHair")
    # havada süzülen pikseller
    for pos, rgb in (((-1.7, 0.1, 6.0), (255, 255, 255)), ((1.8, -0.1, 6.3), cyan), ((-1.2, 0.5, 6.7), (255, 255, 120)), ((1.6, 0.5, 6.8), (255, 90, 235))):
        m.box(pos, (0.3, 0.3, 0.3), rgb, bevel=0.03, name="PixelBit")
    # göğüste piksel kalp
    heart = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    size = 0.1
    for row, line in enumerate(heart):
        for col, ch in enumerate(line):
            if ch == "1":
                box_at(m, (col - 3) * size, 0.58, 2.95 - row * size - 0.02, size * 0.98, 0.05, size * 0.98, (255, 90, 235), bevel=0.005, name="HeartPx")


def frost(m, C):
    ice, deep, snow = (225, 250, 255), (70, 150, 230), (245, 252, 255)
    figure(m, C, tank=snow, shoe=ice, sole=deep, wrist=ice, mouth_style="smile", brow_tilt=-3, blush_color=lighter(C, 0.6), tank_trim=ice)
    # buz tacı: bant + sivri kristaller
    m.box((0, 0, 5.08), (HW + 0.08, HD + 0.08, 0.3), (190, 238, 252), bevel=0.08, name="CrownBand")
    for i, (angle, pos) in enumerate(ring_positions(7, 0.78, 5.15)):
        h = 1.15 if i % 2 == 0 else 0.8
        spike(m, pos, (math.cos(angle) * 0.25, math.sin(angle) * 0.25, 1), h, 0.24, ice if i % 2 == 0 else (160, 225, 250), verts=4, name="IceSpike")
    # boyun atkısı + arka kuyruğu
    m.box((0, 0, 3.55), (2.3, 1.3, 0.34), (170, 222, 250), bevel=0.1, name="Scarf")
    box_at(m, 0.55, -0.62, 2.9, 0.5, 0.14, 1.3, (170, 222, 250), bevel=0.05, rot=(-8, 0, 0), name="ScarfTail")
    box_at(m, 0.55, -0.66, 2.5, 0.52, 0.15, 0.14, snow, bevel=0.03, rot=(-8, 0, 0), name="ScarfStripe")
    # göğüste kar tanesi
    for angle in (0, 60, 120):
        box_at(m, 0, 0.58, 2.7, 0.72, 0.05, 0.07, deep, bevel=0.015, rot=(0, angle, 0), name="Snowflake")
    m.ball((0, 0.6, 2.7), (0.1, 0.05, 0.1), deep, seg=8, rings=6, name="SnowflakeHub")


def volt(m, C):
    black, orange, white = (32, 32, 44), (245, 140, 10), (255, 252, 205)
    figure(m, C, tank=black, shoe=black, sole=white, wrist=black, mouth_style="grin", brow_tilt=10, brow_color=(150, 90, 0), blush_color=lighter(C, 0.5), tank_trim=white)
    # yukarı dikilmiş şimşek saçı: turuncu dikenler + öne eğik beyaz şimşek
    for i, (angle, pos) in enumerate(ring_positions(8, 0.7, TOP - 0.2)):
        spike(m, pos, (math.cos(angle) * 0.55, math.sin(angle) * 0.55, 1), 0.95 + 0.25 * (i % 2), 0.3, orange, verts=5, name="HairSpike")
    box_at(m, 0.2, 0.0, 5.7, 0.34, 0.34, 0.8, white, bevel=0.05, rot=(0, -28, 0), name="Bolt")
    box_at(m, 0.135, 0.0, 6.27, 0.34, 0.34, 0.5, white, bevel=0.05, rot=(0, 30, 0), name="Bolt")
    spike(m, (0.26, 0, 6.49), (0.5, 0, 0.87), 0.5, 0.17, white, verts=4, name="BoltTip")
    # göğüste şimşek amblemi
    box_at(m, 0.1, 0.58, 2.8, 0.2, 0.05, 0.42, white, bevel=0.015, rot=(0, -25, 0), name="BoltMark")
    box_at(m, 0.0, 0.58, 2.62, 0.4, 0.05, 0.1, white, bevel=0.015, name="BoltMark")
    box_at(m, -0.08, 0.58, 2.46, 0.2, 0.05, 0.36, white, bevel=0.015, rot=(0, -25, 0), name="BoltMark")
    for s in (-1, 1):  # bileklerde sarı çizgi
        m.box((2.0 * s, 0, 4.3), (0.94, 0.94, 0.09), (255, 230, 40), bevel=0.02, name="WristStripe")


def nova(m, C):
    indigo, gold, star = (50, 25, 125), (255, 225, 110), (255, 240, 170)
    figure(m, C, tank=indigo, shoe=(30, 15, 80), sole=gold, wrist=gold, mouth_style="smile", brow_tilt=3, blush_color=lighter(C, 0.5), tank_trim=gold)
    # pelerin
    box_at(m, 0, -0.78, 2.85, 2.5, 0.16, 1.9, (45, 20, 105), bevel=0.06, rot=(-8, 0, 0), name="Cape")
    box_at(m, 0, -0.83, 1.95, 2.55, 0.17, 0.14, gold, bevel=0.03, rot=(-8, 0, 0), name="CapeTrim")
    for s in (-1, 1):
        m.ball((1.0 * s, 0.1, 3.52), (0.2, 0.2, 0.2), gold, seg=10, rings=6, name="Clasp")
    # hale (havada süzülür) ve yıldızlar
    m.torus((0, 0, 6.05), 0.95, 0.1, gold, major_seg=28, minor_seg=8, name="Halo")
    for pos, size, rgb in (((-1.9, 0.2, 5.9), 0.34, star), ((1.9, 0.2, 6.2), 0.28, gold), ((-1.3, 0.3, 6.9), 0.24, gold), ((1.2, 0.3, 6.9), 0.3, star), ((2.6, 0.2, 5.3), 0.2, gold)):
        m.star(pos, size, rgb, thickness=0.12, points=4, name="Star")
    # göğüste yıldız madalyon
    m.star((0, 0.56, 2.7), 0.34, gold, thickness=0.08, points=5, name="Medal")
    for x, z in ((-0.6, 2.5), (0.6, 2.95), (-0.5, 3.0)):
        m.star((x, 0.56, z), 0.1, star, thickness=0.05, points=4, name="Twinkle")


def prism(m, C):
    rainbow = [(255, 70, 70), (255, 150, 40), (255, 230, 60), (80, 220, 100), (60, 220, 255), (70, 110, 255), (170, 90, 255)]
    figure(m, C, tank=rainbow[0], shoe=rainbow[5], sole=WHITE, wrist=None, mouth_style="grin", brow_tilt=-5, blush_color=(255, 190, 210), eye_color=(255, 255, 255), glow=(120, 90, 255))
    # gökkuşağı atlet: 6 yatay şerit (atlet figure içinde tek renk çizildi, şeritler önüne biner)
    for index, rgb in enumerate(rainbow[:6]):
        box_at(m, 0, 0.0, 2.3 + 0.18 * index + 0.09, 2.12, 1.16, 0.19, rgb, bevel=0.01, name="Stripe")
    # yumruklarda gökkuşağı bileklikleri
    for s in (-1, 1):
        for index in range(3):
            m.box((2.0 * s, 0, 4.22 + 0.12 * index), (0.94, 0.94, 0.12), rainbow[(index * 2) % 7], bevel=0.015, name="Wristband")
    # taç: altın bant + 7 gökkuşağı mücevheri
    m.box((0, 0, 5.1), (HW + 0.08, HD + 0.08, 0.28), GOLD, bevel=0.08, name="CrownBand")
    for index, (angle, pos) in enumerate(ring_positions(7, 0.8, 5.2, start=math.pi / 2)):
        spike(m, pos, (math.cos(angle) * 0.2, math.sin(angle) * 0.2, 1), 0.85, 0.24, rainbow[index], verts=4, name="Gem")
        m.ball((pos[0], pos[1], pos[2] + 0.08), (0.17, 0.17, 0.17), rainbow[index], seg=8, rings=6, name="GemBase")
    for pos, size, rgb in (((-1.9, 0.2, 5.9), 0.26, WHITE), ((1.8, 0.2, 6.3), 0.3, GOLD), ((-1.2, 0.3, 6.6), 0.2, rainbow[4]), ((1.2, 0.3, 6.9), 0.22, rainbow[6])):
        m.star(pos, size, rgb, thickness=0.1, points=4, name="Sparkle")


def shadow(m, C):
    purple, trim, dark = (190, 90, 255), (120, 60, 200), (16, 14, 24)
    figure(m, C, tank=(22, 20, 32), shoe=(24, 20, 36), sole=purple, wrist=trim, mouth_style="smirk", eye_style="glow", glow=purple, face=True, belt=trim)
    # kukuleta: başın üstünü ve arkasını sarar, yüz önde açık kalır
    m.ball((0, -0.45, 4.7), (1.32, 1.22, 1.17), dark, seg=16, rings=10, name="Hood")
    spike(m, (0, -0.8, 5.5), (0, -0.55, 1), 1.1, 0.5, dark, verts=8, name="HoodTip")
    m.torus((0, 0.8, 4.3), 1.08, 0.07, trim, rot=(90, 0, 0), major_seg=28, minor_seg=8, name="HoodTrim")
    # boyun atkısı ve uçuşan kuyruğu
    m.box((0, 0, 3.55), (2.3, 1.3, 0.34), trim, bevel=0.1, name="Scarf")
    m.tube([(0.8, -0.5, 3.55), (1.2, -1.2, 3.2), (1.5, -2.0, 3.6), (1.8, -2.7, 3.3)], 0.2, trim, name="ScarfTail")
    # göğüste hilal
    m.ball((0, 0.57, 2.7), (0.3, 0.06, 0.3), purple, seg=14, rings=8, name="Moon")
    m.ball((0.11, 0.62, 2.76), (0.26, 0.06, 0.26), (22, 20, 32), seg=14, rings=8, name="MoonCut")


COACHES = [
    ("leaf", sprout, (60, 220, 90)),
    ("wave", wave, (60, 100, 255)),
    ("flame", blaze, (255, 50, 50)),
    ("ember", ember, (255, 150, 30)),
    ("pixel", pixel, (255, 50, 230)),
    ("frost", frost, (50, 230, 255)),
    ("volt", volt, (255, 230, 40)),
    ("nova", nova, (160, 80, 255)),
    ("prism", prism, (245, 245, 255)),
    ("shadow", shadow, (35, 35, 48)),
]


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    textures = os.path.join(c.OUT, "textures")
    models = []
    for coach_id, builder, color in COACHES:
        if wanted and coach_id not in wanted:
            continue
        model = Model("coach_" + coach_id)
        builder(model, color)
        obj = model.finish(textures)
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "coach_" + coach_id + ".fbx"))
        print("MODEL", coach_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    cols = 5 if len(models) > 6 else max(1, len(models))
    spacing = 6.6
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * spacing, row * spacing * 1.5, 0)  # kamera ön tarafta olduğu için x ters: soldan sağa sıra korunur
    rows = (len(models) + cols - 1) // cols
    center = (0, (rows - 1) * spacing * 0.75, 2.6)
    c.add_floor((205, 214, 240), size=90)
    c.add_lights(center=center, distance=22)
    c.render_view(os.path.join(c.OUT, "previews", "coaches_lineup.png"), center=center, distance=22 + cols * 4.4 + rows * 4, azimuth_deg=0, elevation_deg=30, lens=50)
    c.save_blend(os.path.join(c.OUT, "blend", "coaches_all.blend"))


if __name__ == "__main__":
    main()
