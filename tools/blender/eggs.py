"""6 fantastik yumurta (Config.Eggs): benekli değil; her biri temalı süsler taşır (sahibinin referansı: süslü/fantastik Roblox yumurtaları).
Starter (mavi + altın zikzak bant, yıldız, taç), Forest (yapraklar, sarmaşık, çiçek, filiz), Desert (güneş arması, firavun başlığı, çatlaklar),
Ice (buz kristalleri, sarkıtlar, kar tanesi), Lava (bazalt kabuk, parlayan lav çatlakları, boynuzlar, lav havuzu), Galaxy (yörünge halkaları, gezegenler, yıldızlar).
Boyut ~4.8 x 6.2 stud (şimdiki kod yumurtasıyla aynı), orijin tabanın ortası, ön +Y. Her yumurta TEK MESH + palet dokusu (lib.py).
    blender -b -P tools/blender/eggs.py [-- starter forest ...]
Çıktı: assets/blender/fbx/egg_<id>.fbx, textures/egg_<id>_palette.png, previews/eggs_lineup.png, blend/eggs_all.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
import common as c  # noqa: E402
from lib import Model, darker, lighter, mix, record_manifest  # noqa: E402
from mathutils import Vector  # noqa: E402

RX = 2.4
H = 6.2
WHITE = (255, 255, 255)


def surface(theta, phi):
    """Yumurta yüzeyi: theta enlem (0 alt, pi üst), phi boylam (0 = ön +Y)."""
    zn = -math.cos(theta)
    ring = math.sin(theta) * RX * (1.0 - 0.17 * zn)
    return Vector((ring * math.sin(phi), ring * math.cos(phi), H / 2 + zn * H / 2))


def normal_at(theta, phi):
    du = surface(theta + 0.01, phi) - surface(theta - 0.01, phi)
    dv = surface(theta, phi + 0.01) - surface(theta, phi - 0.01)
    n = dv.cross(du).normalized()
    if n.dot(surface(theta, phi) - Vector((0, 0, H / 2))) < 0:
        n = -n
    return n


def radius_at(z):
    zn = max(-1.0, min(1.0, (z - H / 2) / (H / 2)))
    theta = math.acos(-zn)
    return math.sin(theta) * RX * (1.0 - 0.17 * zn)


def theta_for_z(z):
    return math.acos(-max(-1.0, min(1.0, (z - H / 2) / (H / 2))))


def euler_align(axis, normal):
    """Yerel eksen (x/y/z) normal yönüne bakacak Euler (derece)."""
    base = {"x": Vector((1, 0, 0)), "y": Vector((0, 1, 0)), "z": Vector((0, 0, 1))}[axis]
    quat = base.rotation_difference(normal)
    return tuple(math.degrees(a) for a in quat.to_euler())


def euler_from_axes(zdir, ydir):
    """Yerel Z'yi zdir, yerel Y'yi (mümkün olduğunca) ydir yönüne bakan Euler (derece)."""
    from mathutils import Matrix

    z = Vector(zdir).normalized()
    y = Vector(ydir) - z * Vector(ydir).dot(z)
    if y.length < 1e-6:
        y = Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0))
        y = y - z * y.dot(z)
    y.normalize()
    x = y.cross(z)
    matrix = Matrix((x, y, z)).transposed()
    return tuple(math.degrees(a) for a in matrix.to_euler())


def shell(m, rgb, rings=28, segs=48):
    mesh = bpy.data.meshes.new("ShellMesh")
    bm = bmesh.new()
    grid = []
    for i in range(rings + 1):
        theta = math.pi * i / rings
        grid.append([bm.verts.new(surface(theta, 2 * math.pi * j / segs)) for j in range(segs)])
    for i in range(rings):
        for j in range(segs):
            a, b = grid[i][j], grid[i][(j + 1) % segs]
            d, e = grid[i + 1][j], grid[i + 1][(j + 1) % segs]
            bm.faces.new((a, b, e, d))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Shell", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    return m._add(obj, rgb, name="Shell", subdiv=0)


def stud(m, theta, phi, radii, rgb, lift=0.0, seg=10, name="Decor"):
    """Yüzeye paralel yassı elipsoit (radii: x, y, z yerel; y yüzeye dik)."""
    pos = surface(theta, phi) + normal_at(theta, phi) * lift
    n = normal_at(theta, phi)
    return m.ball(tuple(pos), radii, rgb, seg=seg, rings=max(5, seg // 2), rot=euler_align("y", n), name=name)


def spike(m, theta, phi, r1, height, rgb, verts=6, lift=-0.05, name="Spike"):
    """Yüzeyden dışa doğru çıkan koni (uç normal yönünde)."""
    n = normal_at(theta, phi)
    pos = surface(theta, phi) + n * (height / 2 + lift)
    return m.cone(tuple(pos), r1, 0.02, height, rgb, rot=euler_align("z", n), verts=verts, name=name)


# ------------------------------------------------------------------ yumurtalar
def starter(m):
    C, A = (90, 190, 255), (255, 220, 60)
    shell(m, C)
    # altın zikzak bant: halka + yukarı dönük sivri dişler
    z = 2.55
    r = radius_at(z)
    m.torus((0, 0, z), r + 0.02, 0.13, A, major_seg=40, minor_seg=8, name="Band")
    for i in range(18):
        ang = 2 * math.pi * i / 18
        pos = (math.sin(ang) * (r + 0.04), math.cos(ang) * (r + 0.04), z + 0.2)
        m.cone(pos, 0.2, 0.02, 0.5, A, rot=(0, 0, 45), verts=4, name="Tooth")
    for i in range(18):
        ang = 2 * math.pi * (i + 0.5) / 18
        pos = (math.sin(ang) * (r + 0.04), math.cos(ang) * (r + 0.04), z - 0.2)
        m.cone(pos, 0.2, 0.02, 0.5, darker(A, 0.2), rot=(180, 0, 45), verts=4, name="Tooth")
    # ön yüzde büyük yıldız ve parıltılar
    th = theta_for_z(3.9)
    n = normal_at(th, 0)
    m.star(tuple(surface(th, 0) + n * 0.02), 0.85, A, thickness=0.2, points=5, rot=(0, 0, 0), name="Star")
    for phi, zz, size in ((math.radians(-50), 4.6, 0.28), (math.radians(55), 4.2, 0.22), (math.radians(35), 3.2, 0.2)):
        thh = theta_for_z(zz)
        nn = normal_at(thh, phi)
        m.star(tuple(surface(thh, phi) + nn * 0.02), size, WHITE, thickness=0.1, rot=euler_align("y", nn), name="Sparkle")
    # tepede küçük altın taç
    top = surface(math.pi - 0.03, 0)
    m.cyl((0, 0, H - 0.05), 0.55, 0.22, A, verts=16, name="CrownBase")
    for i in range(5):
        ang = 2 * math.pi * i / 5
        m.cone((math.sin(ang) * 0.42, math.cos(ang) * 0.42, H + 0.2), 0.14, 0.02, 0.45, A, rot=(0, 0, 45), verts=4, name="CrownSpike")


def forest(m):
    C, D = (90, 220, 120), (40, 140, 70)
    shell(m, C)
    # tabanı saran büyük yapraklar (ucu dışa doğru yatık, yassı yüzü dışa bakar)
    for i in range(7):
        ang = 2 * math.pi * i / 7
        outward = Vector((math.sin(ang), math.cos(ang), 0))
        axis = outward * 0.5 + Vector((0, 0, 0.87))
        pos = Vector((outward.x * 2.1, outward.y * 2.1, 1.1))
        m.ball(tuple(pos), (0.55, 0.14, 1.25), D if i % 2 == 0 else (60, 175, 85), seg=10, rings=6, rot=euler_from_axes(axis, outward), name="Leaf")
    # sarmaşık: yumurtayı saran sarmal + küçük çiçekler
    pts = []
    for i in range(14):
        t = i / 13
        z = 1.6 + t * 3.4
        ang = t * 2.4 * math.pi
        r = radius_at(z) + 0.05
        pts.append((math.sin(ang) * r, math.cos(ang) * r, z))
    m.tube(pts, 0.1, (110, 75, 40), name="Vine", taper=False)
    for i in (3, 6, 9, 11):
        p = pts[i]
        m.ball((p[0], p[1], p[2]), (0.2, 0.2, 0.2), (255, 150, 190), seg=8, rings=5, name="Flower")
        m.ball((p[0] * 1.03, p[1] * 1.03, p[2]), (0.09, 0.09, 0.09), (255, 225, 90), seg=6, rings=4, name="FlowerCore")
    # tepede filiz
    m.cyl((0, 0, H + 0.05), 0.09, 0.9, (80, 170, 70), verts=8, name="Stem")
    for s in (-1, 1):
        m.ball((0.38 * s, 0, H + 0.55), (0.45, 0.1, 0.22), (150, 255, 120), seg=10, rings=6, rot=(0, 28 * s * -1, 0), name="Sprout")
    m.ball((0, 0, H + 0.62), (0.16, 0.16, 0.2), (170, 255, 140), seg=8, rings=6, name="Bud")


def desert(m):
    C, A = (255, 200, 90), (190, 110, 30)
    gold, blue = (255, 215, 80), (60, 110, 200)
    shell(m, C)
    # ön yüzde güneş arması: disk + ışınlar
    th = theta_for_z(3.4)
    n = normal_at(th, 0)
    pos = surface(th, 0)
    m.ball(tuple(pos + n * 0.02), (0.78, 0.14, 0.78), A, seg=16, rings=8, rot=euler_align("y", n), name="Sun")
    m.ball(tuple(pos + n * 0.1), (0.45, 0.1, 0.45), gold, seg=14, rings=7, rot=euler_align("y", n), name="SunCore")
    for i in range(12):
        ang = 2 * math.pi * i / 12
        d = Vector((math.sin(ang), 0, math.cos(ang)))
        center = pos + d * 1.02 + n * 0.05
        m.cone(tuple(center), 0.17, 0.02, 0.55, gold, rot=euler_from_axes(d, n), verts=4, name="Ray")
    # firavun başlığı: tepede altın kep + mavi/altın şeritli yan kumaşlar
    cap_z = 4.55
    m.ball((0, 0, H - 1.05), (radius_at(H - 0.9) + 0.1, radius_at(H - 0.9) + 0.1, 1.05), gold, seg=24, rings=10, name="Cap")
    for i, col in enumerate((blue, gold, blue)):
        m.torus((0, 0, H - 1.0 + 0.25 * i), radius_at(H - 1.0 + 0.25 * i) + 0.08, 0.08, col, major_seg=28, minor_seg=6, name="CapBand")
    for side in (-1, 1):
        for i in range(5):
            zz = 4.5 - 0.55 * i
            m.box((side * (radius_at(zz) + 0.12), 0.1, zz), (0.4, 1.0, 0.34), blue if i % 2 == 0 else gold, bevel=0.05, rot=(0, 0, 0), name="Nemes")
    m.cone((0, FRONT_OF(H - 0.7), H - 0.75), 0.18, 0.03, 0.6, (255, 90, 70), rot=(-90, 0, 0), verts=8, name="Cobra")
    # kum çatlakları (alt yarıda)
    for phi, z0 in ((-0.7, 1.6), (0.8, 1.2)):
        for k in range(4):
            th = theta_for_z(z0 + 0.35 * k)
            ph = phi + (0.12 if k % 2 else -0.12)
            n2 = normal_at(th, ph)
            p2 = surface(th, ph) + n2 * 0.02
            m.box(tuple(p2), (0.5, 0.05, 0.1), A, bevel=0, rot=(0, 0, 35 if k % 2 else -35), name="Crack")


def FRONT_OF(z):
    return radius_at(z)


def ice(m):
    C, A = (190, 240, 255), (90, 160, 255)
    crystal, tip = (140, 205, 255), (235, 250, 255)
    shell(m, C)
    # tepede buz kristali kümesi
    for i, (x, y, h, tilt) in enumerate(((0, 0, 1.6, 0), (-0.45, 0.1, 1.1, 14), (0.45, -0.05, 1.2, -14), (0.1, -0.4, 0.9, 10), (-0.1, 0.45, 0.9, -10))):
        m.cone((x, y, H - 0.1 + h / 2), 0.28, 0.04, h, crystal if i % 2 == 0 else A, rot=(0, tilt, 0), verts=6, name="Crystal")
        m.cone((x, y, H - 0.1 + h * 0.85), 0.14, 0.02, h * 0.3, tip, rot=(0, tilt, 0), verts=6, name="CrystalTip")
    # tabanda dışa eğik kristaller
    for i in range(7):
        ang = 2 * math.pi * i / 7 + 0.3
        th = theta_for_z(0.9)
        ph = ang
        spike(m, th, ph, 0.3, 1.0 + 0.3 * (i % 2), crystal if i % 2 else A, verts=6, lift=-0.1)
    # tepede kar şapkası + altında beyaz buz saçağı (sarkıtlar)
    z = 4.3
    r = 2.2
    m.ball((0, 0, z), (2.17, 2.17, H - z + 0.12), WHITE, seg=28, rings=12, name="SnowCap")
    m.torus((0, 0, z), r - 0.03, 0.13, tip, major_seg=36, minor_seg=6, name="Frost")
    for i in range(16):
        ang = 2 * math.pi * i / 16
        h = 0.5 + 0.25 * ((i * 7) % 3)
        m.cone((math.sin(ang) * (r + 0.03), math.cos(ang) * (r + 0.03), z - h / 2), 0.16, 0.02, h, tip, rot=(180, 0, 0), verts=5, name="Icicle")
    # kar tanesi: üç çapraz çubuk
    th = theta_for_z(3.1)
    n = normal_at(th, 0)
    pos = surface(th, 0) + n * 0.03
    for ang in (0, 60, 120):
        m.box(tuple(pos), (1.3, 0.14, 0.17), WHITE, bevel=0.04, rot=(0, ang, 0), name="Snowflake")
    for i in range(6):
        a = math.radians(60 * i)
        m.ball((pos.x + math.sin(a) * 0.68, pos.y + 0.03, pos.z + math.cos(a) * 0.68), (0.1, 0.07, 0.1), WHITE, seg=8, rings=5, name="SnowDot")


def lava(m):
    C = (255, 90, 50)
    rock, rock2 = (70, 46, 52), (95, 62, 66)
    glow, glow2 = (255, 160, 40), (255, 225, 80)
    shell(m, rock)
    # parlayan lav çatlakları: yüzeyde zikzak çizgiler (her parça iki yüzey noktası arası ince çubuk)
    for phi0, seq in ((0.0, (0.5, 0.95, 1.4, 1.85, 2.3, 2.75)), (math.radians(62), (0.7, 1.15, 1.6, 2.05, 2.5)), (math.radians(-66), (0.8, 1.25, 1.7, 2.15, 2.6))):
        pts = [(th, phi0 + (0.17 if k % 2 else -0.17)) for k, th in enumerate(seq)]
        for k in range(len(pts) - 1):
            a, b = surface(*pts[k]), surface(*pts[k + 1])
            n = (normal_at(*pts[k]) + normal_at(*pts[k + 1])).normalized()
            d = b - a
            mid = (a + b) / 2 + n * 0.03
            m.box(tuple(mid), (0.15, 0.08, d.length + 0.1), glow if k % 2 == 0 else glow2, bevel=0.02, rot=euler_from_axes(d, n), name="LavaCrack")
    # tepede üç boynuz, uçları parlak
    for i, (x, y, h, tilt) in enumerate(((0, 0.2, 1.3, 0), (-0.6, -0.15, 0.95, 18), (0.6, -0.15, 0.95, -18))):
        m.cone((x, y, H - 0.1 + h / 2), 0.3, 0.04, h, rock2, rot=(0, tilt, 0), verts=5, name="Horn")
        m.cone((x, y, H - 0.1 + h * 0.88), 0.12, 0.02, h * 0.26, glow, rot=(0, tilt, 0), verts=5, name="HornTip")
    # taban: kaya parçaları + lav havuzu
    m.torus((0, 0, 0.12), RX * 0.95, 0.22, glow, major_seg=36, minor_seg=8, name="LavaPool")
    for i in range(9):
        ang = 2 * math.pi * i / 9
        m.ball((math.sin(ang) * (RX + 0.2), math.cos(ang) * (RX + 0.2), 0.35), (0.42, 0.42, 0.38), rock2 if i % 2 else rock, seg=8, rings=5, name="Rock")
    for i, (x, y, z) in enumerate(((1.2, 1.6, 6.6), (-1.0, 1.0, 7.0), (0.3, -1.4, 6.9))):
        m.ball((x, y, z), (0.1, 0.1, 0.1), glow2, seg=6, rings=4, name="Ember")


def galaxy(m):
    C = (110, 70, 220)
    cyan, yellow, pink = (120, 235, 255), (255, 235, 120), (255, 150, 220)
    shell(m, C)
    # yörünge halkaları + gezegenler (halkanın düzlemindeki bir noktaya konur)
    from mathutils import Euler

    for tilt, tilt_z, col, planet, pcol, size in ((-24, 12, (235, 235, 255), 0.5, yellow, 0.34), (28, -14, cyan, 2.4, pink, 0.28)):
        r = RX * 1.62
        m.torus((0, 0, H / 2), r, 0.075, col, rot=(tilt, 0, tilt_z), major_seg=40, minor_seg=6, name="Orbit")
        local = Vector((math.sin(planet) * r, math.cos(planet) * r, 0))
        local.rotate(Euler((math.radians(tilt), 0, math.radians(tilt_z)), "XYZ"))
        m.ball((local.x, local.y, H / 2 + local.z), (size, size, size), pcol, seg=10, rings=7, name="Planet")
    # yüzeyde yıldızlar ve parıltılar
    stars = ((0.0, 3.7, 0.5, yellow), (math.radians(-55), 4.5, 0.3, WHITE), (math.radians(50), 2.9, 0.33, cyan), (math.radians(-35), 2.1, 0.25, WHITE), (math.radians(30), 4.9, 0.22, pink), (math.radians(80), 3.9, 0.22, WHITE), (math.radians(-85), 3.3, 0.24, cyan))
    for phi, z, size, col in stars:
        th = theta_for_z(z)
        n = normal_at(th, phi)
        m.star(tuple(surface(th, phi) + n * 0.02), size, col, thickness=0.12, rot=euler_align("y", n), name="Star")
    # küçük süzülen yıldız tozu
    for x, y, z, col in ((1.9, 1.5, 6.3, WHITE), (-1.8, 1.2, 5.6, yellow), (2.2, -0.8, 1.2, cyan)):
        m.star((x, y, z), 0.18, col, thickness=0.08, name="Dust")


EGGS = [
    ("starter", starter),
    ("forest", forest),
    ("desert", desert),
    ("ice", ice),
    ("lava", lava),
    ("galaxy", galaxy),
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
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "egg_" + egg_id + ".fbx"))
        print("MODEL", egg_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    cols = min(3, len(models))
    spacing = 8.0
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * spacing, row * spacing * 1.35, 0)  # kamera -Y'ye baktığı için x ters: soldan sağa sıra korunur
    rows = (len(models) + cols - 1) // cols
    center = (0, (rows - 1) * spacing * 0.675, 3.0)
    c.add_floor((205, 214, 240), size=90)
    c.add_lights(center=center, distance=20)
    c.render_view(os.path.join(c.OUT, "previews", "eggs_lineup.png"), center=center, distance=22 + rows * 7, azimuth_deg=0, elevation_deg=26, lens=50)
    c.save_blend(os.path.join(c.OUT, "blend", "eggs_all.blend"))


if __name__ == "__main__":
    main()
