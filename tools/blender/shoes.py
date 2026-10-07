"""15 ayakkabı (Config.Items sırasıyla, zayıftan güçlüye): yumuşak, tombul, oyuncak gibi modeller; her biri kendi karakterini taşır.
Ortak gövde: taban (dış taban + orta taban), boyuna kesitlerden oluşan 'loft' üst kısım (ayak girişi boolean ile oyulur), dil, bağcıklar, burun şapkası, topuk tutamağı;
sonra ayakkabıya özgü ekler: kanvas dikişi, yelpaze çizgisi, tırtıl tabanı, yıldız yaması, krampon tırnakları, yay, kanatlar, zırh, neon şeritler, mücevher, kristaller, şimşek, melek kanatları...
Her model TEK MESH + palet dokusu (lib.py), adı shoe_<id> (Config.Items[].id). Birim 1 stud, ön +Y, orijin tabanın ortası; ~3.9 stud uzun (oyunda ShoeScale ile küçülür).
    blender -b -P tools/blender/shoes.py [-- oldsneakers canvas ...]
Çıktı: assets/blender/fbx/shoe_<id>.fbx, textures/shoe_<id>_palette.png, previews/shoes_lineup.png, blend/shoes_all.blend, models.json + src/shared/ModelInfo.luau güncellenir.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
import common as c  # noqa: E402
from lib import Model, darker, lighter, mix, record_manifest  # noqa: E402

WHITE = (250, 250, 252)
DARK = (46, 46, 56)
GRAY = (150, 156, 170)
GOLD = (255, 205, 60)
Y_MIN, Y_MAX = -1.78, 1.78  # üst kısmın boyuna sınırları


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


class Ctx:
    """Bir ayakkabının ölçü işlevleri (üst kısım kesitleri) ve parametreleri."""

    def __init__(self, spec):
        self.spec = spec
        self.sole_h = spec.get("sl", 0.42)
        self.hs = spec.get("hs", 1.0)
        self.ws = spec.get("ws", 1.0)
        self.lift = spec.get("lift", 0.0)  # tabanı yerden kaldıran ek (yay gibi)
        self.top = self.lift + self.sole_h  # tabanın üst yüzü

    def width_at(self, y):
        s = (y - Y_MIN) / (Y_MAX - Y_MIN)
        base = (0.58 + 0.2 * smoothstep(0.0, 0.55, s)) * self.ws
        heel_round = math.sqrt(max(0.0, 1 - ((0.16 - min(s, 0.16)) / 0.16) ** 2))
        toe_round = math.sqrt(max(0.0, 1 - ((max(s, 0.7) - 0.7) / 0.3) ** 2))
        return base * heel_round * toe_round

    def height_at(self, y):
        s = (y - Y_MIN) / (Y_MAX - Y_MIN)
        base = (0.7 + 0.95 * (1 - smoothstep(0.0, 0.8, s))) * (1 + (self.hs - 1) * (1 - smoothstep(0.0, 0.85, s)))
        heel_round = math.sqrt(max(0.0, 1 - ((0.1 - min(s, 0.1)) / 0.1) ** 2))
        toe_round = math.sqrt(max(0.0, 1 - ((max(s, 0.78) - 0.78) / 0.22) ** 2))
        return base * max(heel_round, 0.0) ** 0.6 * toe_round ** 0.8

    def surface_z(self, y):
        return self.top + self.height_at(y)


def slab(m, ctx, z0, z1, rgb, name, bevel=None):
    """Taban levhası: yuvarlatılmış uçlu, topuğa doğru daralan, burnu hafif kalkık."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, (z0 + z1) / 2))
    obj = bpy.context.active_object
    obj.scale = (1.5 * ctx.ws, 3.9, z1 - z0)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.subdivide(number_cuts=6)
    bpy.ops.object.mode_set(mode="OBJECT")
    half = 0.75 * ctx.ws
    for vertex in obj.data.vertices:
        x, y, z = vertex.co
        xn = max(-1.0, min(1.0, x / half))
        arc = math.sqrt(max(0.0, 1 - 0.96 * xn * xn))
        if y > 0.7:
            y = 0.7 + (y - 0.7) * arc
        elif y < -1.1:
            y = -1.1 + (y + 1.1) * arc
        width = 0.8 + 0.2 * smoothstep(-1.9, 0.5, y)
        nose = smoothstep(0.5, 1.95, y)
        heel = smoothstep(-1.0, -1.95, y)
        vertex.co.y = y
        vertex.co.x = x * width * (1.0 - 0.45 * nose * nose) * (1.0 - 0.12 * heel * heel)
        vertex.co.z = z + ctx.spec.get("nose", 0.34) * nose * nose
    obj.name = name
    m._add(obj, rgb, bevel=bevel if bevel is not None else min(0.15, (z1 - z0) * 0.45), bevel_segments=2, name=name)
    return obj


def upper(m, ctx, rgb):
    rows, cols = 40, 18
    mesh = bpy.data.meshes.new("UpperMesh")
    bm = bmesh.new()
    grid = []
    for i in range(rows + 1):
        y = Y_MIN + (Y_MAX - Y_MIN) * i / rows
        w, h = ctx.width_at(y), ctx.height_at(y)
        ring = []
        for j in range(cols + 1):
            t = math.pi * j / cols
            cs, sn = math.cos(t), math.sin(t)
            ring.append(bm.verts.new((w * math.copysign(abs(cs) ** 0.78, cs), y, ctx.top - 0.02 + h * (sn ** 0.78))))
        grid.append(ring)
    for i in range(rows):
        for j in range(cols):
            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    for i in range(rows):
        bm.faces.new((grid[i][0], grid[i + 1][0], grid[i + 1][cols], grid[i][cols]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Upper", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    # ayak girişi oyuğu
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0, location=(0, -0.98, ctx.surface_z(-0.98) + 0.02))
    cutter = bpy.context.active_object
    cutter.scale = (0.46 * ctx.ws, 0.66, 0.6)
    bpy.context.view_layer.objects.active = obj
    boolean = obj.modifiers.new("Opening", "BOOLEAN")
    boolean.operation = "DIFFERENCE"
    boolean.object = cutter
    boolean.solver = "EXACT"
    c.apply_modifiers(obj)
    bpy.data.objects.remove(cutter, do_unlink=True)
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = 0.07
    bevel.segments = 2
    bevel.limit_method = "ANGLE"
    obj.modifiers.new("Subsurf", "SUBSURF").levels = 1
    c.apply_modifiers(obj)
    decimate = obj.modifiers.new("Decimate", "DECIMATE")
    decimate.ratio = 0.3
    c.apply_modifiers(obj)
    return m._add(obj, rgb, name="Upper")


def core(m, ctx):
    """Ortak gövde: taban, üst kısım, dil, bağcık, burun şapkası, topuk tutamağı. spec renkleri: col (üst), acc (vurgu), sole, out, lace, cap."""
    spec = ctx.spec
    col, acc = spec["col"], spec.get("acc", WHITE)
    sole_rgb, out_rgb, lace_rgb = spec.get("sole", WHITE), spec.get("out", DARK), spec.get("lace", WHITE)
    base = ctx.lift
    slab(m, ctx, base, base + 0.16, out_rgb, "Outsole")
    slab(m, ctx, base + 0.16, base + ctx.sole_h, sole_rgb, "Midsole")
    upper(m, ctx, col)
    cap = spec.get("cap", WHITE)
    if cap:
        toe_y = 1.28
        m.ball((0, toe_y, ctx.top + ctx.height_at(toe_y) * 0.46), (ctx.width_at(toe_y) * 0.9, 0.44, ctx.height_at(toe_y) * 0.56), cap, seg=22, rings=12, name="ToeCap")
    m.box((0, -0.34, ctx.surface_z(-0.34) * 0.98 + 0.2 + ctx.top * 0.0), (0.6 * ctx.ws, 0.18, 0.62 + 0.25 * (ctx.hs - 1)), spec.get("tongue", acc), bevel=0.08, rot=(-16, 0, 0), name="Tongue")
    laces = spec.get("laces", 3)
    for index in range(laces):
        y = 0.8 - 0.4 * index if laces == 3 else 0.9 - 0.34 * index
        m.cyl((0, y, ctx.surface_z(y) * 0.995), 0.075, ctx.width_at(y) * 1.5, lace_rgb, rot=(0, 90, 0), verts=10, name="Lace")
    m.box((0, -1.66, ctx.top + ctx.height_at(-1.6) * 0.82), (0.5 * ctx.ws, 0.2, 0.55 + 0.25 * (ctx.hs - 1)), spec.get("tab", acc), bevel=0.08, name="HeelTab")


# ------------------------------------------------------------------ ayakkabıya özgü ekler
def side(m, ctx, y, frac=0.82):
    """Üst kısmın yanında (x ekseninde) bir noktanın x'i ve z'si."""
    return ctx.width_at(y) * frac, ctx.top + ctx.height_at(y) * 0.55


def sides(fn):
    for s in (-1, 1):
        fn(s)


def e_canvas(m, ctx):
    acc = ctx.spec["acc"]
    for s in (-1, 1):
        for y in (0.35, 0.05, -0.25):  # yan gözlekler
            x, z = side(m, ctx, y, 1.0)
            m.cyl((x * 0.97 * s, y, ctx.top + ctx.height_at(y) * 0.72), 0.07, 0.06, (200, 205, 215), rot=(0, 90, 0), verts=8, name="Eyelet")


def e_runner(m, ctx):
    acc = ctx.spec["acc"]
    for s in (-1, 1):  # yan 'swoosh' çizgisi
        x0 = ctx.width_at(0.1) * 0.92
        pts = [(x0 * s, -0.9, ctx.top + 0.55), (x0 * s * 1.0, -0.2, ctx.top + 0.4), (x0 * s, 0.6, ctx.top + 0.5), (x0 * s * 0.9, 1.1, ctx.top + 0.78)]
        m.tube(pts, 0.1, acc, name="Swoosh", taper=True)
    m.box((0, -1.55, ctx.top + 0.25), (0.9 * ctx.ws, 0.6, 0.2), acc, bevel=0.06, name="HeelCounter")


def e_trail(m, ctx):
    brown = (120, 82, 50)
    for y in (-1.45, -0.75, -0.05, 0.65, 1.3):  # tırtıl tabanı blokları
        for s in (-1, 1):
            m.box((0.5 * s * ctx.ws, y, 0.0), (0.4, 0.42, 0.22), (60, 45, 38), bevel=0.05, name="Lug")
    m.torus((0, -0.98, ctx.surface_z(-0.98) - 0.05), 0.5 * ctx.ws, 0.1, brown, major_seg=20, minor_seg=6, rot=(0, 0, 0), name="Collar")


def e_hightop(m, ctx):
    acc = ctx.spec["acc"]
    x, z = side(m, ctx, -0.98, 1.0)
    for s in (-1, 1):
        m.star((x * 1.05 * s, -1.0, ctx.top + ctx.height_at(-1.0) * 0.55), 0.38, acc, thickness=0.08, rot=(0, 0, -90 * s), points=5, name="StarPatch")
    m.torus((0, -0.98, ctx.surface_z(-0.98) - 0.02), 0.5 * ctx.ws, 0.11, ctx.spec["acc"], major_seg=20, minor_seg=6, name="Collar")


def e_cleats(m, ctx):
    for y in (-1.3, -0.5, 0.4, 1.2):
        for s in (-1, 1):
            m.cone((0.5 * ctx.ws * s, y, -0.12), 0.13, 0.06, 0.3, WHITE, rot=(180, 0, 0), verts=8, name="Stud")
    for s in (-1, 1):  # yan çizgi
        x, z = side(m, ctx, 0.0, 1.0)
        m.box((ctx.width_at(0.2) * 0.98 * s, 0.1, ctx.top + 0.5), (0.05, 1.7, 0.16), ctx.spec["acc"], bevel=0.02, rot=(0, 0, 0), name="SideStripe")


def e_jump(m, ctx):
    gray, acc = (170, 176, 190), ctx.spec["acc"]
    for index in range(5):  # yay: üst üste halkalar
        r = 0.55 - 0.03 * (index % 2)
        m.torus((0, 0.0, 0.08 + 0.16 * index), r * ctx.ws, 0.06, gray if index % 2 else acc, major_seg=20, minor_seg=6, name="Spring")
    m.cyl((0, 0, 0.04), 0.7 * ctx.ws, 0.08, gray, verts=18, name="SpringBase")


def e_speed(m, ctx):
    acc = ctx.spec["acc"]
    for s in (-1, 1):  # topukta kanatlar (yan düzlemde ince bıçaklar, arkaya ve yukarı)
        for index, splay in enumerate((18, 0, -18)):
            m.cone((0.7 * ctx.ws * s, -1.5, ctx.top + 0.85), 0.34, 0.03, 1.5 - 0.15 * abs(index - 1), WHITE if index != 1 else acc, rot=(70, 0, splay * s), verts=4, scale=(0.3, 1, 1), name="Wing")
    for s in (-1, 1):  # şimşek
        zx = ctx.width_at(0.1) * 0.97 * s
        yellow = (255, 240, 90)
        m.box((zx, 0.45, ctx.top + 0.68), (0.05, 0.45, 0.12), yellow, bevel=0.01, rot=(0, 0, 0), name="Bolt")
        m.box((zx, 0.2, ctx.top + 0.52), (0.05, 0.45, 0.12), yellow, bevel=0.01, rot=(-45, 0, 0), name="Bolt")
        m.box((zx, -0.05, ctx.top + 0.36), (0.05, 0.4, 0.12), yellow, bevel=0.01, rot=(35, 0, 0), name="Bolt")


def e_power(m, ctx):
    metal, gold = (170, 176, 190), GOLD
    toe_y = 1.35
    m.ball((0, toe_y, ctx.top + ctx.height_at(toe_y) * 0.45), (ctx.width_at(toe_y) * 0.98, 0.55, ctx.height_at(toe_y) * 0.62), metal, seg=22, rings=12, name="MetalToe")
    for index, y in enumerate((-0.3, -1.1)):
        m.box((0, y, ctx.top + ctx.height_at(y) * 0.95), (ctx.width_at(y) * 2.15, 0.24, 0.2), (60, 40, 40), bevel=0.05, name="Strap")
        m.box((0, y + 0.02, ctx.top + ctx.height_at(y) * 0.95 + 0.0), (0.26, 0.28, 0.26), gold, bevel=0.04, name="Buckle")


def e_titan(m, ctx):
    metal, rivet = (190, 198, 215), (230, 235, 245)
    toe_y = 1.3
    m.box((0, toe_y, ctx.top + ctx.height_at(toe_y) * 0.55), (ctx.width_at(toe_y) * 1.9, 0.9, ctx.height_at(toe_y) * 0.95), metal, bevel=0.14, segments=3, name="ToePlate")
    for s in (-1, 1):  # bilek zırhı levhaları
        m.box((ctx.width_at(-0.9) * 1.0 * s, -0.95, ctx.top + ctx.height_at(-0.95) * 0.5), (0.12, 0.95, ctx.height_at(-0.95) * 0.55), metal, bevel=0.05, name="ShinPlate")
        for y in (-1.4, -0.5):
            m.ball((ctx.width_at(y) * 1.1 * s, y, ctx.top + ctx.height_at(y) * 0.55), (0.09, 0.09, 0.09), rivet, seg=8, rings=5, name="Rivet")
    m.box((0, -1.78, ctx.top + ctx.height_at(-1.7) * 0.6), (ctx.width_at(-1.6) * 1.5, 0.18, ctx.height_at(-1.7) * 0.8), metal, bevel=0.07, name="HeelPlate")


def e_neon(m, ctx):
    glow1, glow2 = (80, 255, 255), (255, 240, 90)
    for s in (-1, 1):
        m.box((0.8 * ctx.ws * s, 0.0, ctx.sole_h * 0.5), (0.06, 3.4, 0.12), glow1, bevel=0.02, name="NeonStrip")
        m.box((ctx.width_at(0.2) * 0.99 * s, 0.2, ctx.top + 0.34), (0.05, 1.6, 0.1), glow2, bevel=0.02, name="NeonStripe")
        m.box((ctx.width_at(0.2) * 0.99 * s, 0.2, ctx.top + 0.58), (0.05, 1.3, 0.1), glow1, bevel=0.02, name="NeonStripe")


def e_golden(m, ctx):
    gem = (80, 190, 255)
    m.ball((0, -0.3, ctx.surface_z(-0.3) + 0.42), (0.17, 0.17, 0.17), gem, seg=10, rings=8, name="Gem")
    for s in (-1, 1):
        m.cone((0.28 * s, -1.65, ctx.top + ctx.height_at(-1.6) + 0.12), 0.13, 0.02, 0.4, GOLD, rot=(0, 0, 45), verts=4, name="HeelCrown")
    m.cone((0, -1.65, ctx.top + ctx.height_at(-1.6) + 0.2), 0.14, 0.02, 0.5, GOLD, rot=(0, 0, 45), verts=4, name="HeelCrown")


def e_crystal(m, ctx):
    shard, tip = (200, 245, 255), (255, 255, 255)
    for x, y, h, tilt in ((0, 1.15, 0.75, 0), (-0.3, 0.95, 0.55, 14), (0.3, 0.95, 0.55, -14)):
        m.cone((x, y, ctx.surface_z(y) + h / 2 - 0.08), 0.17, 0.02, h, shard, rot=(0, tilt, 0), verts=6, name="Crystal")
    for index, (x, y, h, tilt) in enumerate(((0, -1.7, 1.1, 0), (-0.35, -1.55, 0.8, 18), (0.35, -1.55, 0.8, -18))):
        m.cone((x, y, ctx.top + ctx.height_at(y) + h / 2 - 0.1), 0.2, 0.02, h, shard if index else tip, rot=(0, tilt, 0), verts=6, name="Crystal")
    for s in (-1, 1):
        m.cone((0.86 * ctx.ws * s, 0.0, ctx.top + 0.3), 0.14, 0.02, 0.55, shard, rot=(0, 90 * s, 0), verts=6, name="CrystalSide")


def e_thunder(m, ctx):
    yellow = (255, 235, 70)
    for s in (-1, 1):  # büyük yan şimşek
        zx = ctx.width_at(0.0) * 1.0 * s
        base_z = ctx.top + 1.1
        m.box((zx, 0.45, base_z), (0.06, 0.7, 0.2), yellow, bevel=0.02, rot=(-30, 0, 0), name="Bolt")
        m.box((zx, 0.05, base_z - 0.38), (0.06, 0.7, 0.2), yellow, bevel=0.02, rot=(30, 0, 0), name="Bolt")
        m.box((zx, -0.4, base_z - 0.76), (0.06, 0.6, 0.2), yellow, bevel=0.02, rot=(-30, 0, 0), name="Bolt")
    for index in range(10):  # tabanda diken sırası
        ang = 2 * math.pi * index / 10
        m.cone((math.sin(ang) * 0.84 * ctx.ws, math.cos(ang) * 1.85, 0.2), 0.12, 0.02, 0.42, yellow, rot=(0, 0, 0), verts=4, name="SoleSpike")


def e_radiant(m, ctx):
    white, gold = (255, 255, 255), (255, 232, 120)
    for s in (-1, 1):  # melek kanatları: yassı tüy konikleri
        for index, (length, ang, zoff) in enumerate(((1.7, 20, 0.75), (1.45, 5, 0.55), (1.2, -12, 0.35), (0.95, -28, 0.15))):
            m.cone((ctx.width_at(-0.9) * 0.9 * s + 0.12 * s, -1.0 - 0.1 * index, ctx.top + ctx.height_at(-1.0) * 0.6 + zoff), 0.36, 0.03, length * 1.15, white if index % 2 == 0 else gold, rot=(0, 90 * s - ang * s, 0), verts=5, scale=(1, 0.2, 1), name="Wing")
    m.torus((0, -0.95, ctx.surface_z(-0.95) + 0.5), 0.72 * ctx.ws, 0.1, gold, major_seg=26, minor_seg=8, name="Halo")
    m.star((0.0, 0.9, ctx.surface_z(0.9) + 0.5), 0.2, white, thickness=0.06, rot=(90, 0, 0), name="Sparkle")
    m.star((-0.45, 0.4, ctx.surface_z(0.4) + 0.65), 0.15, gold, thickness=0.06, rot=(90, 0, 0), name="Sparkle")


SHOES = [
    ("oldsneakers", dict(col=(170, 255, 70), acc=WHITE), None),
    ("canvas", dict(col=(120, 170, 255), acc=(255, 120, 130), sl=0.38, nose=0.2, sole=(255, 120, 130), out=WHITE, laces=3), e_canvas),
    ("running", dict(col=(255, 140, 60), acc=WHITE, sl=0.58, sole=(255, 235, 200), nose=0.42, ws=0.95), e_runner),
    ("trail", dict(col=(0, 230, 170), acc=(120, 82, 50), hs=1.3, sl=0.5, out=(60, 45, 38), sole=(190, 170, 140), lace=(120, 82, 50), cap=(110, 78, 52), laces=4), e_trail),
    ("hightops", dict(col=(255, 70, 160), acc=WHITE, hs=1.7, laces=4, sl=0.42), e_hightop),
    ("cleats", dict(col=(60, 220, 90), acc=WHITE, sl=0.3, sole=(40, 40, 48), out=(40, 40, 48), nose=0.18, cap=None, lace=WHITE), e_cleats),
    ("jump", dict(col=(255, 230, 60), acc=(255, 120, 60), lift=0.78, sole=WHITE), e_jump),
    ("speed", dict(col=(60, 200, 255), acc=(255, 255, 255), sl=0.42, ws=0.92, nose=0.4, cap=(255, 255, 255)), e_speed),
    ("power", dict(col=(255, 70, 70), acc=(60, 40, 40), hs=1.45, sl=0.6, ws=1.08, cap=None, lace=(60, 40, 40), out=(50, 40, 44), sole=(110, 100, 110)), e_power),
    ("titan", dict(col=(40, 80, 255), acc=(190, 198, 215), hs=1.55, sl=0.66, ws=1.12, cap=None, sole=(120, 130, 160), out=(40, 44, 70), lace=(190, 198, 215)), e_titan),
    ("neon", dict(col=(255, 60, 230), acc=(80, 255, 255), sl=0.5, sole=(30, 30, 50), out=(30, 30, 50), lace=(80, 255, 255), cap=(255, 150, 240)), e_neon),
    ("golden", dict(col=(255, 200, 40), acc=(255, 232, 130), sl=0.46, lace=(255, 232, 130), cap=(255, 232, 130), tongue=(255, 232, 130)), e_golden),
    ("crystal", dict(col=(150, 240, 255), acc=(230, 250, 255), sl=0.46, sole=(230, 250, 255), lace=(230, 250, 255), cap=(220, 248, 255)), e_crystal),
    ("thunder", dict(col=(170, 90, 255), acc=(255, 235, 70), hs=1.4, sl=0.58, lace=(255, 235, 70), cap=None, sole=(60, 40, 90), out=(40, 30, 60)), e_thunder),
    ("radiant", dict(col=(255, 255, 140), acc=(255, 232, 120), sl=0.5, sole=(255, 248, 215), out=(255, 232, 120), lace=(255, 255, 255), cap=(255, 255, 255), tongue=(255, 232, 120)), e_radiant),
]


def build(m, spec, extra):
    ctx = Ctx(spec)
    core(m, ctx)
    if extra:
        extra(m, ctx)


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    textures = os.path.join(c.OUT, "textures")
    models = []
    for shoe_id, spec, extra in SHOES:
        if wanted and shoe_id not in wanted:
            continue
        model = Model("shoe_" + shoe_id)
        build(model, spec, extra)
        obj = model.finish(textures)
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "shoe_" + shoe_id + ".fbx"))
        print("MODEL", shoe_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    cols = min(5, len(models))
    spacing = 6.4
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * spacing, row * spacing * 1.0, 0)
        obj.rotation_euler = (0, 0, math.radians(32))  # önizlemede 3/4 görünüm için hafif döndür (dışa aktarılan dosyalar etkilenmez)
    rows = (len(models) + cols - 1) // cols
    center = (0, (rows - 1) * spacing * 0.5, 0.8)
    c.add_floor((205, 214, 240), size=90)
    c.add_lights(center=center, distance=18)
    c.render_view(os.path.join(c.OUT, "previews", "shoes_lineup.png"), center=center, distance=(18 + cols * 4.4 + rows * 3.0) * 0.9, azimuth_deg=0, elevation_deg=38, lens=42)
    c.save_blend(os.path.join(c.OUT, "blend", "shoes_all.blend"))


if __name__ == "__main__":
    main()
