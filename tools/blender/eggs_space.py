"""DÜNYA 2 (Uzay): 6 yeni fantastik yumurta, eggs.py ile aynı üslup ve ölçü (beneksiz; temalı süsler, ~4.8 x 6.2 stud, orijin tabanın ortası, ön +Y).
Moon (krater halkaları, altın hilal, tepede ay), Asteroid (kaya yumruları, parlayan çatlaklar, kaya kuşağı), Nebula (renkli bulut girdapları, yıldızlar),
Comet (buz kabuğu, öne bakan kuyruklu yıldız + akan kuyruk şeritleri, buz kristalleri), Supernova (patlama yıldızları, alev dişli bant, güneş tacı),
Blackhole (koyu kabuk, parlayan yığılma diski, mor girdap, tepede kara küre + hale).
Her yumurta TEK MESH + palet dokusu (lib.py), adı egg_<id>. Dünya 1 dosyalarına ve src/'ye dokunmaz (ölçüler space_lib.record).
    blender -b -P tools/blender/eggs_space.py [-- moon nebula ...]
Çıktı: assets/blender/fbx/egg_<id>.fbx, textures/egg_<id>_palette.png, previews/eggs_space_lineup.png, blend/eggs_space.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
import eggs as E  # noqa: E402
import space_lib as S  # noqa: E402
from lib import Model, darker, lighter, mix  # noqa: E402
from mathutils import Euler, Vector  # noqa: E402

RX, H = E.RX, E.H
WHITE = (255, 255, 255)
GOLD = (255, 215, 70)
STAR = (255, 240, 130)
CYAN = (120, 240, 255)
ICE = (215, 248, 255)
MAGENTA = (255, 100, 220)
FIRE = (255, 140, 30)
FIRE_Y = (255, 225, 80)
surface, normal_at, radius_at, theta_for_z = E.surface, E.normal_at, E.radius_at, E.theta_for_z


def on_surface(z, phi, lift=0.02):
    th = theta_for_z(z)
    n = normal_at(th, phi)
    return surface(th, phi) + n * lift, n


def crater(m, z, phi, r, col, rim):
    pos, n = on_surface(z, phi, 0.0)
    m.ball(tuple(pos), (r, 0.06, r), col, seg=12, rings=6, rot=E.euler_align("y", n), name="Crater")
    m.torus(tuple(pos + n * 0.03), r, 0.06, rim, rot=E.euler_align("z", n), major_seg=16, minor_seg=5, name="CraterRim")


def star_on(m, z, phi, size, col, points=4, thickness=0.12):
    pos, n = on_surface(z, phi)
    m.star(tuple(pos), size, col, thickness=thickness, points=points, rot=E.euler_align("y", n), name="Star")


def ring_band(m, z, col, minor=0.12, segs=40):
    m.torus((0, 0, z), radius_at(z) + 0.02, minor, col, major_seg=segs, minor_seg=8, name="Band")


# ------------------------------------------------------------------ yumurtalar
def moon(m):
    C = (215, 215, 235)
    dark, rim = (175, 175, 205), (240, 240, 252)
    E.shell(m, C)
    for z, phi, r in ((1.4, 0.5, 0.42), (2.2, -0.9, 0.5), (3.6, 1.2, 0.36), (4.6, -0.6, 0.3), (1.2, -2.4, 0.45), (3.0, 2.6, 0.5), (4.4, 2.0, 0.3), (2.0, 3.6, 0.38), (5.3, 0.9, 0.22)):
        crater(m, z, phi, r, dark, rim)
    # ön yüzde büyük altın hilal + yıldızlar
    pos, n = on_surface(3.3, 0.0, 0.04)
    S.crescent(m, tuple(pos), 0.75, GOLD, thickness=0.18, rot=(0, 0, 0), name="Moon")
    star_on(m, 4.4, 0.45, 0.24, STAR)
    star_on(m, 2.1, 0.55, 0.18, WHITE)
    star_on(m, 4.9, -0.3, 0.16, WHITE)
    # tepede minik ay küresi + halka
    m.cyl((0, 0, H - 0.02), 0.14, 0.5, (190, 190, 220), verts=8, name="Stem")
    m.ball((0, 0, H + 0.55), (0.42, 0.42, 0.42), (250, 245, 220), seg=16, rings=10, name="MoonOrb")
    m.torus((0, 0, H + 0.55), 0.68, 0.06, GOLD, rot=(-18, 0, 0), major_seg=24, minor_seg=5, name="OrbRing")


def asteroid(m):
    C = (130, 115, 112)
    rock, rock2 = (100, 88, 88), (155, 140, 132)
    glow = (255, 150, 60)
    E.shell(m, C)
    for z, phi, s in ((1.0, 0.3, 0.55), (2.4, 1.0, 0.45), (3.8, -0.4, 0.5), (4.9, 0.7, 0.35), (2.0, -1.2, 0.5), (1.6, 2.6, 0.5), (3.4, 2.0, 0.45), (4.4, -2.2, 0.4), (2.8, 3.5, 0.5)):
        pos, n = on_surface(z, phi, -0.1)
        m.ball(tuple(pos), (s, s * 0.6, s * 0.85), rock if int(z * 10) % 2 else rock2, seg=8, rings=5, rot=E.euler_align("y", n), name="Lump")
    for z, phi, r in ((3.0, 0.2, 0.35), (1.6, -0.5, 0.3), (4.2, 1.5, 0.28)):
        crater(m, z, phi, r, rock, rock2)
    # parlayan çatlaklar (eggs.lava gibi zikzak)
    for phi0, seq in ((0.75, (0.9, 1.3, 1.7, 2.1, 2.5)), (-0.8, (0.8, 1.2, 1.6, 2.0))):
        pts = [(th, phi0 + (0.15 if k % 2 else -0.15)) for k, th in enumerate(seq)]
        for k in range(len(pts) - 1):
            a, b = surface(*pts[k]), surface(*pts[k + 1])
            n = (normal_at(*pts[k]) + normal_at(*pts[k + 1])).normalized()
            d = b - a
            m.box(tuple((a + b) / 2 + n * 0.03), (0.13, 0.07, d.length + 0.1), glow if k % 2 == 0 else FIRE_Y, bevel=0.02, rot=E.euler_from_axes(d, n), name="Crack")
    # eğik kaya kuşağı (halka + üstünde yüzen kayalar)
    tilt = (-20, 0, 10)
    r = RX * 1.5
    m.torus((0, 0, H / 2), r, 0.06, (200, 170, 140), rot=tilt, major_seg=40, minor_seg=5, name="Belt")
    for k in range(9):
        a = 2 * math.pi * k / 9
        p = Vector((math.sin(a) * r, math.cos(a) * r, 0))
        p.rotate(Euler(tuple(math.radians(t) for t in tilt), "XYZ"))
        s = 0.28 + 0.1 * (k % 3)
        m.box((p.x, p.y, H / 2 + p.z), (s, s * 0.9, s * 0.8), rock2 if k % 2 else rock, bevel=0.06, rot=(25 * k, 40, 15 * k), name="BeltRock")
    # tepede kaya tacı + parlayan kristal
    for k in range(5):
        a = 2 * math.pi * k / 5
        m.box((math.sin(a) * 0.45, math.cos(a) * 0.45, H - 0.05), (0.4, 0.4, 0.35), rock, bevel=0.06, rot=(20, 15 * k, 30), name="CrownRock")
    m.cone((0, 0, H + 0.45), 0.25, 0.03, 1.0, glow, verts=6, name="Crystal")


def nebula(m):
    C = (170, 90, 235)
    pink, blue, violet = (255, 140, 220), (110, 190, 255), (210, 150, 255)
    E.shell(m, C)
    # bulut girdapları: yüzeyde üst üste yassı renkli lekeler (spiral boyunca)
    for k in range(26):
        t = k / 25
        z = 0.8 + t * 4.6
        phi = t * 3.2 * math.pi
        pos, n = on_surface(z, phi, -0.02)
        col = (pink, blue, violet)[k % 3]
        s = 0.55 - 0.2 * abs(t - 0.5)
        m.ball(tuple(pos), (s, 0.08, s * 0.7), col, seg=10, rings=5, rot=E.euler_align("y", n), name="Cloud")
    for z, phi, size, col in ((3.4, 0.0, 0.5, STAR), (4.6, 0.6, 0.25, WHITE), (2.2, -0.6, 0.28, WHITE), (1.6, 0.8, 0.2, STAR), (5.0, -0.8, 0.2, CYAN), (3.0, 1.9, 0.3, STAR), (2.6, -2.2, 0.26, WHITE), (4.2, 3.1, 0.3, CYAN)):
        star_on(m, z, phi, size, col, points=4 if size < 0.4 else 5)
    # tepede dönen bulut tutamı + yıldız
    for k in range(3):
        m.ball((0, 0, H - 0.1 + 0.32 * k), (0.62 - 0.17 * k, 0.62 - 0.17 * k, 0.24), (pink, violet, blue)[k], seg=14, rings=6, name="Swirl")
    m.star((0, 0, H + 0.95), 0.4, STAR, thickness=0.14, points=5, name="TopStar")
    for x, y, z, col in ((2.0, 1.4, 5.8, WHITE), (-2.1, 1.0, 4.8, STAR), (2.3, -0.6, 1.4, CYAN)):
        m.star((x, y, z), 0.18, col, thickness=0.08, name="Dust")


def comet(m):
    C = (150, 215, 255)
    deep = (80, 150, 240)
    E.shell(m, C)
    # beyaz buz bandı + sarkıtlar
    z = 2.0
    r = radius_at(z)
    ring_band(m, z, ICE, minor=0.13)
    for i in range(16):
        ang = 2 * math.pi * i / 16
        h = 0.4 + 0.2 * ((i * 5) % 3)
        m.cone((math.sin(ang) * (r + 0.03), math.cos(ang) * (r + 0.03), z - h / 2), 0.14, 0.02, h, ICE, rot=(180, 0, 0), verts=5, name="Icicle")
    # ön yüzde parlayan kuyruklu yıldız başı + yüzey boyunca arkaya akan kuyruk şeritleri
    pos, n = on_surface(3.8, 0.35, 0.05)
    m.ball(tuple(pos), (0.42, 0.18, 0.42), WHITE, seg=14, rings=8, rot=E.euler_align("y", n), name="CometHead")
    m.ball(tuple(pos + n * 0.1), (0.24, 0.1, 0.24), STAR, seg=12, rings=6, rot=E.euler_align("y", n), name="CometCore")
    for k, (dz, col, rad) in enumerate(((0.0, ICE, 0.13), (0.35, CYAN, 0.09), (-0.35, WHITE, 0.08))):
        pts = []
        for j in range(6):
            t = j / 5
            zz = 3.8 + dz * t + 0.6 * t
            ph = 0.35 - t * 2.3
            pts.append(tuple(surface(theta_for_z(zz), ph) + normal_at(theta_for_z(zz), ph) * 0.06))
        m.tube(pts, rad, col, name="CometTail", taper=True)
    star_on(m, 4.9, 0.9, 0.2, WHITE)
    star_on(m, 2.9, -0.5, 0.18, STAR)
    star_on(m, 3.0, 1.1, 0.16, WHITE)
    # tepede buz kristalleri
    for i, (x, y, h, tilt) in enumerate(((0, 0, 1.4, 0), (-0.45, 0.1, 1.0, 14), (0.45, -0.05, 1.05, -14), (0.1, -0.42, 0.8, 10))):
        m.cone((x, y, H - 0.1 + h / 2), 0.26, 0.04, h, ICE if i % 2 == 0 else deep, rot=(0, tilt, 0), verts=6, name="Crystal")


def supernova(m):
    C = (255, 140, 40)
    red = (235, 70, 50)
    E.shell(m, C)
    # orta bant: altın halka + iki yana alev dişleri
    z = 2.7
    r = radius_at(z)
    ring_band(m, z, GOLD, minor=0.14)
    for i in range(16):
        ang = 2 * math.pi * i / 16
        for up, col in ((1, FIRE_Y), (-1, red)):
            pos = (math.sin(ang + (0 if up > 0 else math.pi / 16)) * (r + 0.04), math.cos(ang + (0 if up > 0 else math.pi / 16)) * (r + 0.04), z + 0.25 * up)
            m.cone(pos, 0.2, 0.02, 0.55, col, rot=(0 if up > 0 else 180, 0, 45), verts=4, name="Flame")
    # patlama yıldızları (çok köşeli)
    pos, n = on_surface(4.1, 0.0, 0.03)
    m.star(tuple(pos), 0.8, FIRE_Y, thickness=0.16, points=8, rot=E.euler_align("y", n), name="Nova")
    m.star(tuple(pos + n * 0.12), 0.42, WHITE, thickness=0.1, points=8, rot=E.euler_align("y", n), name="NovaCore")
    for z2, phi, size in ((1.4, 0.6, 0.35), (1.6, -0.8, 0.3), (4.2, 1.6, 0.4), (4.0, -1.7, 0.38), (1.5, 2.8, 0.35), (4.6, 3.2, 0.3)):
        star_on(m, z2, phi, size, FIRE_Y if size > 0.33 else WHITE, points=6)
    # tepede güneş tacı: disk + ışınlar
    m.ball((0, 0, H + 0.1), (0.55, 0.55, 0.3), GOLD, seg=16, rings=8, name="SunCap")
    for i in range(10):
        a = 2 * math.pi * i / 10
        d = Vector((math.sin(a), math.cos(a), 1.2)).normalized()
        m.cone((math.sin(a) * 0.5, math.cos(a) * 0.5, H + 0.45), 0.15, 0.02, 0.7 if i % 2 else 0.5, FIRE_Y if i % 2 else red, rot=E.euler_align("z", d), verts=4, name="SunRay")
    for x, y, z3 in ((1.9, 1.2, 6.4), (-1.6, 1.4, 6.8), (0.5, -1.6, 6.9)):
        m.ball((x, y, z3), (0.11, 0.11, 0.11), FIRE_Y, seg=6, rings=4, name="Ember")


def blackhole(m):
    C = (34, 24, 56)
    accretion, accretion2 = (255, 150, 50), (255, 90, 200)
    violet = (170, 100, 255)
    E.shell(m, C)
    # olay ufkunun çevresinde dönen sarmal galaksi kolları (yüzeyde yassı lekeler)
    for arm in range(3):
        for j in range(9):
            t = j / 8
            ang = math.radians(arm * 120 + t * 200)
            rad = 0.75 + t * 1.25
            z = 3.3 + math.sin(ang) * rad
            phi = math.cos(ang) * rad / RX
            pos, n = on_surface(z, phi, -0.02)
            size = 0.2 - 0.09 * t
            m.ball(tuple(pos), (size, 0.07, size), (violet, MAGENTA, CYAN)[arm] if j % 3 else WHITE, seg=8, rings=5, rot=E.euler_align("y", n), name="SwirlDot")
    # ön yüzde 'olay ufku': koyu çekirdek + parlak halkalar
    pos, n = on_surface(3.3, 0.0, 0.02)
    m.torus(tuple(pos), 0.62, 0.1, accretion, rot=E.euler_align("z", n), major_seg=24, minor_seg=6, name="Horizon")
    m.torus(tuple(pos + n * 0.02), 0.42, 0.06, violet, rot=E.euler_align("z", n), major_seg=20, minor_seg=5, name="Horizon2")
    m.ball(tuple(pos + n * 0.04), (0.36, 0.08, 0.36), (8, 6, 14), seg=14, rings=6, rot=E.euler_align("y", n), name="Core")
    for z, phi, size, col in ((4.8, 0.6, 0.22, WHITE), (1.8, -0.5, 0.2, violet), (2.0, 0.9, 0.16, WHITE), (4.5, -1.0, 0.18, CYAN), (2.6, 2.5, 0.24, WHITE)):
        star_on(m, z, phi, size, col)
    # yumurtayı saran eğik yığılma diski (üç halka)
    tilt = (-16, 0, 8)
    for r, minor, col in ((RX * 1.45, 0.14, accretion), (RX * 1.65, 0.08, accretion2), (RX * 1.28, 0.06, FIRE_Y)):
        m.torus((0, 0, H * 0.45), r, minor, col, rot=tilt, major_seg=44, minor_seg=6, name="Accretion")
    # tepede kara küre + mor hale
    m.cyl((0, 0, H - 0.02), 0.12, 0.45, violet, verts=8, name="Stem")
    m.ball((0, 0, H + 0.55), (0.4, 0.4, 0.4), (10, 8, 18), seg=16, rings=10, name="VoidOrb")
    m.torus((0, 0, H + 0.55), 0.62, 0.07, MAGENTA, rot=(-20, 0, 0), major_seg=24, minor_seg=5, name="OrbRing")
    m.torus((0, 0, H + 1.35), 0.42, 0.06, violet, major_seg=20, minor_seg=5, name="Halo")


EGGS = [
    ("moon", moon),
    ("asteroid", asteroid),
    ("nebula", nebula),
    ("comet", comet),
    ("supernova", supernova),
    ("blackhole", blackhole),
]


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    textures = os.path.join(c.OUT, "textures")
    models = []
    for egg_id, builder in EGGS:
        if wanted and egg_id not in wanted:
            continue
        model = Model("egg_" + egg_id)
        builder(model)
        obj = model.finish(textures)
        S.record(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "egg_" + egg_id + ".fbx"))
        print("MODEL", egg_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    name = "eggs_space_check.png" if wanted else "eggs_space_lineup.png"
    S.render_grid(models, os.path.join(c.OUT, "previews", name), cols=min(3, len(models)), spacing=(9.0, 13.0), height=3.2, elevation=30, resolution=1800, margin=1.12, obj_height=8.5)
    if not wanted:
        c.save_blend(os.path.join(c.OUT, "blend", "eggs_space.blend"))


if __name__ == "__main__":
    main()
