"""DÜNYA 2 (Uzay): 15 yeni ayakkabı (zayıftan güçlüye), shoes.py ile aynı ortak gövde (taban + loft üst + dil + bağcık + burun + topuk) ve ölçü (~3.9 stud uzun),
üstüne uzay temalı ekler: ay botu yastıkları, roket kanatçığı ve alevi, kuyruklu yıldız şeridi, nebula bulutları, plazma taban, yörünge halkası,
kuasar ışın jetleri, pulsar halkaları, yıldız patlamaları, karanlık madde tırnakları, solucan deliği diski, galaksi kanatları, yıldız ocağı zırhı, boşluk dikenleri,
Big Bang (melek kanatları + patlama + hale). Her model TEK MESH + palet dokusu, adı shoe_<id>. Dünya 1 dosyalarına ve src/'ye dokunmaz (ölçüler space_lib.record).
    blender -b -P tools/blender/shoes_space.py [-- moonboots ...]
Çıktı: assets/blender/fbx/shoe_<id>.fbx, textures/, previews/shoes_space_lineup.png, blend/shoes_space.blend
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
import shoes as SH  # noqa: E402
import space_lib as S  # noqa: E402
from lib import Model, darker, lighter, mix  # noqa: E402

WHITE, DARK, GOLD = SH.WHITE, SH.DARK, SH.GOLD
STAR = (255, 240, 130)
CYAN = (110, 240, 255)
ICE = (215, 248, 255)
MAGENTA = (255, 90, 220)
VIOLET = (170, 100, 255)
FIRE = (255, 140, 30)
FIRE_Y = (255, 225, 80)


def side_x(ctx, y, frac=1.0):
    return ctx.width_at(y) * frac


def side_star(m, ctx, y, zf, size, col, points=5):
    for s in (-1, 1):
        m.star((side_x(ctx, y, 1.02) * s, y, ctx.top + ctx.height_at(y) * zf), size, col, thickness=0.07, rot=(0, 0, -90 * s), points=points, name="SideStar")


# ------------------------------------------------------------------ ekler
def e_moon(m, ctx):
    puff = ctx.spec["acc"]
    for y in (-1.15, -0.25, 0.65):  # kapitone ay botu yastıkları: üst kısmın kesiti boyunca kabarık rulolar
        w, h = ctx.width_at(y) * 1.03, ctx.height_at(y) * 1.02
        pts = [(w * math.cos(t), y, ctx.top - 0.02 + h * math.sin(t)) for t in (0.0, 0.8, 1.57, 2.34, 3.14)]
        m.tube(pts, 0.1, puff, name="Puff", taper=False)
    for s in (-1, 1):
        S.crescent(m, (side_x(ctx, 0.2, 1.02) * s, 0.2, ctx.top + 0.5), 0.3, GOLD, thickness=0.07, rot=(0, 0, -90 * s), name="Moon")


def e_rocket(m, ctx):
    fin = ctx.spec["acc"]
    m.cone((0, -1.55, ctx.top + ctx.height_at(-1.5) + 0.25), 0.55, 0.05, 0.9, fin, rot=(0, 0, 0), verts=3, scale=(0.18, 1, 1), name="Fin")
    for s in (-1, 1):
        m.cone((0.62 * ctx.ws * s, -1.45, ctx.top + 0.35), 0.4, 0.04, 0.7, fin, rot=(0, 90 * s, 0), verts=3, scale=(1, 0.2, 1), name="SideFin")
    m.cyl((0, -1.9, ctx.top + 0.35), 0.24, 0.3, (170, 176, 190), rot=(90, 0, 0), verts=12, name="Nozzle")
    for k, (r, h, col) in enumerate(((0.2, 0.6, FIRE), (0.12, 0.85, FIRE_Y))):
        m.cone((0, -2.05 - h / 2, ctx.top + 0.35), r, 0.02, h, col, rot=(90, 0, 0), verts=8, name="Flame")
    m.cyl((0, 1.0, ctx.surface_z(1.0) - 0.05), 0.12, 0.1, (110, 200, 255), rot=(0, 0, 0), verts=10, name="Window")


def e_comet(m, ctx):
    for s in (-1, 1):
        x = side_x(ctx, 0.6, 0.98)
        pts = [(x * s, 0.9, ctx.top + 0.65), (x * s, 0.2, ctx.top + 0.58), (x * 0.98 * s, -0.6, ctx.top + 0.7), (x * 0.9 * s, -1.3, ctx.top + 0.95)]
        m.tube(pts, 0.12, ICE, name="CometTail", taper=True)
        m.ball((x * s * 1.02, 0.95, ctx.top + 0.65), (0.1, 0.2, 0.2), WHITE, seg=10, rings=6, name="CometHead")
    m.star((0, 1.3, ctx.surface_z(1.3) + 0.05), 0.22, STAR, thickness=0.07, rot=(90, 0, 0), name="ToeStar")


def e_nebula(m, ctx):
    cols = ((255, 150, 230), (130, 200, 255), (220, 170, 255))
    for s in (-1, 1):
        for k, (y, zf, r) in enumerate(((0.6, 0.45, 0.24), (0.15, 0.6, 0.3), (-0.4, 0.5, 0.26), (-0.95, 0.65, 0.22))):
            m.ball((side_x(ctx, y, 0.97) * s, y, ctx.top + ctx.height_at(y) * zf), (0.07, r, r * 0.75), cols[k % 3], seg=10, rings=5, name="Cloud")
    side_star(m, ctx, -0.2, 0.85, 0.12, STAR, points=4)


def e_plasma(m, ctx):
    glow = ctx.spec["acc"]
    for s in (-1, 1):
        m.box((0.72 * ctx.ws * s, -0.2, ctx.sole_h * 0.55), (0.08, 2.2, 0.16), glow, bevel=0.03, name="PlasmaStrip")
    for x, y, r in ((0.5, -1.2, 0.1), (-0.45, -0.6, 0.08), (0.55, 0.3, 0.09), (-0.5, 1.0, 0.07), (0.3, 1.45, 0.06)):
        m.ball((x * ctx.ws, y, ctx.sole_h * 0.4), (r, r, r), WHITE, seg=8, rings=5, name="Bubble")
    m.box((0, -1.55, ctx.top + 0.28), (0.9 * ctx.ws, 0.55, 0.18), glow, bevel=0.06, name="HeelGlow")


def e_gravity(m, ctx):
    ring = ctx.spec["acc"]
    m.torus((0, 0.0, ctx.top + 0.55), 1.15, 0.07, ring, rot=(0, 18, 0), major_seg=36, minor_seg=6, name="OrbitRing")
    m.ball((1.05, 0.45, ctx.top + 0.2), (0.2, 0.2, 0.2), (150, 210, 255), seg=12, rings=8, name="Planet")
    for y in (-1.3, -0.5, 0.4, 1.2):  # tutunma tırnakları
        for s in (-1, 1):
            m.box((0.5 * s * ctx.ws, y, -0.02), (0.36, 0.36, 0.14), (60, 50, 60), bevel=0.04, name="Grip")


def e_quasar(m, ctx):
    beam = ctx.spec["acc"]
    for s in (-1, 1):
        x = side_x(ctx, -0.2, 1.0)
        m.cyl((x * s, -0.2, ctx.top + 0.55), 0.26, 0.08, WHITE, rot=(0, 90, 0), verts=14, name="Core")
        m.cyl((x * s * 1.02, -0.2, ctx.top + 0.55), 0.14, 0.08, beam, rot=(0, 90, 0), verts=12, name="CoreGlow")
        for up in (1, -1):  # ışın jetleri (yukarı-geri ve aşağı-ileri)
            m.cone((x * s * 1.03, -0.2 - 0.35 * up, ctx.top + 0.55 + 0.42 * up), 0.08, 0.02, 0.75, beam, rot=(-40 * up if up > 0 else 180 - 40, 0, 0), verts=6, name="Jet")


def e_pulsar(m, ctx):
    pulse = ctx.spec["acc"]
    for k in range(4):  # bilekte pulsar halkaları
        y = -0.98
        z = ctx.surface_z(y) - 0.1 - 0.28 * k
        m.torus((0, y, z), 0.5 * ctx.ws + 0.06 * k, 0.06, pulse if k % 2 == 0 else WHITE, major_seg=22, minor_seg=5, name="PulseRing")
    side_star(m, ctx, 0.3, 0.55, 0.22, pulse, points=4)
    m.ball((0, 1.25, ctx.surface_z(1.25)), (0.14, 0.14, 0.14), WHITE, seg=10, rings=6, name="Beacon")


def e_nova(m, ctx):
    side_star(m, ctx, 0.25, 0.5, 0.36, FIRE_Y, points=8)
    side_star(m, ctx, 0.25, 0.5, 0.18, WHITE, points=8)
    side_star(m, ctx, -1.05, 0.65, 0.2, STAR, points=6)
    for s in (-1, 1):
        for y in (-1.5, 1.4):
            m.ball((0.72 * ctx.ws * s, y, ctx.sole_h * 0.55), (0.07, 0.07, 0.07), FIRE_Y, seg=6, rings=4, name="Spark")


def e_darkmatter(m, ctx):
    glow = ctx.spec["acc"]
    for y in (-1.45, -0.75, -0.05, 0.65, 1.3):  # parlayan tırtıl tırnakları
        for s in (-1, 1):
            m.box((0.5 * s * ctx.ws, y, 0.0), (0.42, 0.42, 0.24), (40, 30, 60), bevel=0.05, name="Lug")
            m.box((0.5 * s * ctx.ws, y, -0.08), (0.24, 0.24, 0.12), glow, bevel=0.03, name="LugGlow")
    for s in (-1, 1):
        for k, y in enumerate((0.5, -0.1, -0.7)):
            m.box((side_x(ctx, y, 0.99) * s, y, ctx.top + ctx.height_at(y) * 0.5), (0.05, 0.36, 0.1), glow, bevel=0.015, rot=(30 if k % 2 else -30, 0, 0), name="Vein")


def e_wormhole(m, ctx):
    for s in (-1, 1):
        x = side_x(ctx, -0.3, 1.03) * s
        for k, (r, col) in enumerate(((0.5, VIOLET), (0.36, CYAN), (0.22, MAGENTA))):
            m.torus((x + 0.02 * k * s, -0.3, ctx.top + 0.6), r, 0.05, col, rot=(0, 90, 0), major_seg=20, minor_seg=5, name="Portal")
        m.cyl((x, -0.3, ctx.top + 0.6), 0.14, 0.06, (14, 8, 30), rot=(0, 90, 0), verts=12, name="PortalCore")


def e_galaxy(m, ctx):
    for s in (-1, 1):  # topukta küçük parlak kanatlar
        for k, splay in enumerate((18, 0, -18)):
            m.cone((0.7 * ctx.ws * s, -1.45, ctx.top + 0.85), 0.32, 0.03, 1.35 - 0.15 * abs(k - 1), (200, 210, 255) if k != 1 else CYAN, rot=(70, 0, splay * s), verts=4, scale=(0.3, 1, 1), name="Wing")
    for y, zf, size, col in ((0.6, 0.45, 0.16, STAR), (0.0, 0.7, 0.12, WHITE), (-0.6, 0.5, 0.14, CYAN), (0.3, 0.25, 0.1, WHITE)):
        side_star(m, ctx, y, zf, size, col, points=4)
    m.torus((0, 0.4, ctx.surface_z(0.4) + 0.2), 0.3, 0.05, MAGENTA, rot=(-20, 0, 0), major_seg=18, minor_seg=5, name="Spiral")


def e_starforge(m, ctx):
    metal = (150, 150, 170)
    toe_y = 1.3
    m.box((0, toe_y, ctx.top + ctx.height_at(toe_y) * 0.55), (ctx.width_at(toe_y) * 1.9, 0.9, ctx.height_at(toe_y) * 0.95), metal, bevel=0.14, segments=3, name="ToePlate")
    m.star((0, toe_y + 0.46, ctx.top + ctx.height_at(toe_y) * 0.55), 0.24, FIRE_Y, thickness=0.06, points=5, name="ToeStar")
    for s in (-1, 1):
        m.box((ctx.width_at(-0.9) * 1.0 * s, -0.95, ctx.top + ctx.height_at(-0.95) * 0.5), (0.12, 0.95, ctx.height_at(-0.95) * 0.55), metal, bevel=0.05, name="ShinPlate")
        for k, y in enumerate((0.55, 0.05, -0.45)):  # erimiş ocak çatlakları
            m.box((side_x(ctx, y, 0.99) * s, y, ctx.top + 0.35 + 0.12 * (k % 2)), (0.05, 0.45, 0.09), FIRE if k % 2 else FIRE_Y, bevel=0.015, rot=(35 if k % 2 else -35, 0, 0), name="ForgeCrack")
    m.box((0, -1.78, ctx.top + ctx.height_at(-1.7) * 0.6), (ctx.width_at(-1.6) * 1.5, 0.18, ctx.height_at(-1.7) * 0.8), metal, bevel=0.07, name="HeelPlate")
    m.ball((0, -1.88, ctx.top + ctx.height_at(-1.7) * 0.6), (0.14, 0.08, 0.14), FIRE_Y, seg=10, rings=6, name="HeelGem")


def e_void(m, ctx):
    glow = ctx.spec["acc"]
    for index in range(10):  # tabanda diken sırası
        ang = 2 * math.pi * index / 10
        m.cone((math.sin(ang) * 0.84 * ctx.ws, math.cos(ang) * 1.85, 0.2), 0.12, 0.02, 0.42, glow, verts=4, name="SoleSpike")
    for s in (-1, 1):  # yanlarda ve topukta boynuz dikenleri
        for y, h in ((-1.0, 0.6), (-0.4, 0.45), (0.25, 0.35)):
            m.cone((side_x(ctx, y, 0.98) * s + 0.15 * s, y, ctx.top + ctx.height_at(y) * 0.75), 0.12, 0.02, h, (30, 22, 44), rot=(0, 70 * s, 0), verts=6, name="Spike")
    m.torus((0, -0.98, ctx.surface_z(-0.98) - 0.02), 0.52 * ctx.ws, 0.1, glow, major_seg=20, minor_seg=6, name="Collar")
    m.ball((0, 1.2, ctx.surface_z(1.2) + 0.02), (0.18, 0.12, 0.18), (10, 6, 18), seg=10, rings=6, name="VoidGem")
    m.torus((0, 1.2, ctx.surface_z(1.2) + 0.04), 0.22, 0.04, glow, major_seg=16, minor_seg=4, name="VoidGemRing")


def e_bigbang(m, ctx):
    gold = (255, 225, 110)
    rainbow = ((255, 90, 90), (255, 170, 60), (255, 235, 80), (90, 230, 120), (90, 180, 255), (180, 110, 255))
    for s in (-1, 1):  # melek kanatları
        for index, (length, ang, zoff) in enumerate(((1.7, 20, 0.75), (1.45, 5, 0.55), (1.2, -12, 0.35), (0.95, -28, 0.15))):
            m.cone((ctx.width_at(-0.9) * 0.9 * s + 0.12 * s, -1.0 - 0.1 * index, ctx.top + ctx.height_at(-1.0) * 0.6 + zoff), 0.36, 0.03, length * 1.15, WHITE if index % 2 == 0 else gold, rot=(0, 90 * s - ang * s, 0), verts=5, scale=(1, 0.2, 1), name="Wing")
        for k, col in enumerate(rainbow):  # yanlarda gökkuşağı şeritleri
            y = 0.85 - 0.22 * k
            m.box((side_x(ctx, y, 0.99) * s, y, ctx.top + 0.3), (0.05, 0.2, 0.12), col, bevel=0.015, name="Rainbow")
    m.torus((0, -0.95, ctx.surface_z(-0.95) + 0.55), 0.72 * ctx.ws, 0.1, gold, major_seg=26, minor_seg=8, name="Halo")
    m.star((0, 1.15, ctx.surface_z(1.15) + 0.35), 0.42, FIRE_Y, thickness=0.08, points=8, rot=(0, 0, 0), name="BangStar")
    m.star((0, 1.2, ctx.surface_z(1.15) + 0.35), 0.22, WHITE, thickness=0.08, points=8, rot=(0, 0, 0), name="BangCore")
    for x, y, z in ((0.6, 0.6, 0.65), (-0.55, 0.2, 0.8), (0.4, -0.2, 1.0)):
        m.star((x, y, ctx.surface_z(y) + z), 0.13, (255, 255, 255), thickness=0.05, rot=(90, 0, 0), name="Sparkle")


# (id, spec, ek): zayıftan güçlüye. 'col' üst rengi = oyunda ayaklara boyanacak neon renk (Config.Items Dünya 2 renkleri bununla aynı olsun).
SHOES = [
    ("moonboots", dict(col=(215, 220, 240), acc=(180, 170, 230), hs=1.6, ws=1.12, sl=0.5, sole=(150, 150, 175), out=(90, 90, 110), cap=(240, 242, 252), lace=(180, 170, 230)), e_moon),
    ("rocketkicks", dict(col=(255, 75, 70), acc=WHITE, sl=0.44, nose=0.36, cap=WHITE, sole=WHITE), e_rocket),
    ("cometrunners", dict(col=(80, 165, 255), acc=ICE, sl=0.56, ws=0.95, nose=0.42, sole=(230, 245, 255), lace=ICE), e_comet),
    ("nebulasteps", dict(col=(185, 95, 255), acc=(255, 150, 230), sl=0.46, sole=(255, 210, 245), lace=(255, 150, 230), cap=(230, 190, 255)), e_nebula),
    ("plasmasoles", dict(col=(60, 240, 160), acc=(170, 255, 90), sl=0.6, sole=(30, 50, 45), out=(30, 50, 45), lace=(170, 255, 90), cap=(190, 255, 220)), e_plasma),
    ("gravitygrips", dict(col=(255, 145, 45), acc=(255, 235, 150), hs=1.2, sl=0.5, sole=(255, 230, 190), out=(60, 50, 60), cap=(255, 200, 120)), e_gravity),
    ("quasarkicks", dict(col=(50, 220, 255), acc=(240, 120, 255), sl=0.5, ws=0.95, nose=0.4, sole=(225, 245, 255), lace=WHITE, cap=(200, 245, 255)), e_quasar),
    ("pulsarboots", dict(col=(255, 220, 50), acc=(80, 230, 255), hs=1.7, laces=4, sl=0.48, sole=(60, 60, 80), out=(40, 40, 60), lace=(80, 230, 255)), e_pulsar),
    ("novasneakers", dict(col=(255, 70, 160), acc=FIRE_Y, sl=0.5, sole=(255, 240, 200), lace=FIRE_Y, cap=(255, 170, 210)), e_nova),
    ("darkmattertreads", dict(col=(95, 60, 160), acc=(190, 110, 255), hs=1.35, sl=0.52, out=(40, 30, 60), sole=(60, 45, 90), lace=(190, 110, 255), cap=(70, 45, 120), laces=4), e_darkmatter),
    ("wormholewalkers", dict(col=(40, 200, 190), acc=VIOLET, sl=0.5, sole=(25, 40, 60), out=(20, 25, 40), lace=VIOLET, cap=(150, 245, 235)), e_wormhole),
    ("galaxygliders", dict(col=(70, 70, 225), acc=CYAN, sl=0.46, ws=0.93, nose=0.4, sole=(30, 30, 70), out=(20, 20, 50), lace=CYAN, cap=(130, 130, 255)), e_galaxy),
    ("starforge", dict(col=(255, 185, 50), acc=(150, 150, 170), hs=1.55, sl=0.66, ws=1.12, cap=None, sole=(90, 80, 90), out=(50, 44, 50), lace=(150, 150, 170)), e_starforge),
    ("voidstompers", dict(col=(45, 32, 70), acc=(200, 90, 255), hs=1.55, sl=0.62, ws=1.1, cap=None, sole=(30, 22, 44), out=(20, 14, 30), lace=(200, 90, 255), tongue=(200, 90, 255)), e_void),
    ("bigbangboots", dict(col=(255, 250, 225), acc=(255, 225, 110), sl=0.52, sole=(255, 240, 200), out=(255, 225, 110), lace=WHITE, cap=WHITE, tongue=(255, 225, 110)), e_bigbang),
]


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
        SH.build(model, spec, extra)
        obj = model.finish(textures)
        S.record(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", "shoe_" + shoe_id + ".fbx"))
        print("MODEL", shoe_id, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        models.append(obj)
    name = "shoes_space_check.png" if wanted else "shoes_space_lineup.png"
    S.render_grid(models, os.path.join(c.OUT, "previews", name), cols=min(5, len(models)), spacing=(6.0, 6.6), height=1.0, elevation=34, resolution=1800, rotate=-38, margin=1.12, obj_height=3.4)
    if not wanted:
        c.save_blend(os.path.join(c.OUT, "blend", "shoes_space.blend"))


if __name__ == "__main__":
    main()
