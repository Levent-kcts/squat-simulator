"""Bacak kasları (seviye atladıkça büyüyen 6 aşama): server/LegGrowth'taki küre kasların yerine geçen Blender modelleri.
Her aşama için üç mesh vardır: muscle_s<N>_thigh (ön uyluk lobları + arka uyluk), muscle_s<N>_glute (popo, oyunda şort renginde boyanır) ve muscle_s<N>_calf (baldır).
Meshler R15 BACAK PARÇASININ MERKEZİNDE ve ona göre ölçeklidir (referans: UpperLeg 1 x 1.217 x 1, LowerLeg 1 x 1.193 x 1 stud; x = genişlik, y = ön/arka derinlik (ön +Y), z = boy).
Oyunda LegGrowth, gerçek bacak parçasının ölçüsünün bu referansa oranıyla (boyuta göre) ölçekler ve bacağa kaynaklar. Mesh iki bacakta da aynıdır (sağ-sol simetrik tasarım).
RENK: meshlerde DOKU YOK (düz malzeme); oyunda MeshPart.Color ten rengiyle / şort rengiyle verilir. Roblox dokulu MeshPart'ta Color'ı dokuyla çarpmaz (Studio'da gri kaslar çıktı), bu yüzden dokulu yapma.
Çalıştırma:
    blender -b -P tools/blender/muscles.py            (6 aşama, önizleme tenli çizilir)
Çıktı: assets/blender/fbx/muscle_s<N>_thigh|glute|calf.fbx, previews/muscles_*.png, blend/muscles_all.blend, models.json + shared/ModelInfo.luau
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
from lib import Model, record_manifest  # noqa: E402

STAGES = 6
UPPER = (1.0, 1.0, 1.217)  # referans UpperLeg (x, y, z) stud
LOWER = (1.0, 1.0, 1.193)

SHORTS = (24, 24, 30)  # önizlemede popo rengi (oyunda LegGrowth SHORTS_COLOR verir)


def ell(m, x, y, z, rx, ry, rz, seg=16, rings=10, name="Muscle"):
    m.ball((x, y, z), (rx, ry, rz), (255, 255, 255), seg=seg, rings=rings, name=name)


# ------------------------------------------------------------------ uyluk (popo hariç)
# Sahibi iki kez 'kas bacağın üzerinde durmuyor, dışarı taşıyor' dedi: kaslar bacağa YAPIŞIK, sığ kabartılar olmalı. Bacak yarı derinliği 0.5; en iri
# aşamada bile ön/arka uç (reach) yüzün sadece ~0.3 ötesindedir. Loblar büyük yarıçaplı ve merkeze yakındır (yüzeyden yumuşak çıkar, balon gibi yapışmaz).
def thigh(m, s):
    """s = 1..6. Uyluk merkezi orijin; ön +Y. F: ön uç, B: arka uç."""
    p = s - 1
    F = 0.57 + 0.04 * p
    B = 0.56 + 0.04 * p
    # çekirdek: bacak kutusunun köşelerini yumuşatır, genişlik aşamayla az artar
    ell(m, 0, 0, -0.02, 0.53 + 0.006 * s, 0.52 + 0.004 * s, 0.65, name="Core")
    # ön uyluk: ortada rectus + iki yanda vastus lobları
    ay = 0.32 + 0.01 * s
    for side in (-1, 1):
        ell(m, 0.24 * side, F - ay, -0.06, 0.3, ay, 0.5, name="Vastus")
    by = 0.3 + 0.01 * s
    ell(m, 0, F + 0.01 - by, 0.04, 0.2, by, 0.5, name="Rectus")
    if s >= 3:  # diz üstünde damla kas
        for side in (-1, 1):
            ell(m, 0.23 * side, F - 0.2, -0.36, 0.18, 0.22, 0.3, name="Teardrop")
    if s >= 4:  # yan dış kas süpürmesi
        for side in (-1, 1):
            ell(m, 0.4 * side, 0.08, 0.02, 0.17, 0.3, 0.42, name="Sweep")
    # arka uyluk: iki loblu hamstring
    cy = 0.32 + 0.01 * s
    for side in (-1, 1):
        ell(m, 0.2 * side, -(B - cy), -0.1, 0.28, cy, 0.46, name="Hamstring")


# ------------------------------------------------------------------ popo (ayrı mesh: oyunda şort renginde boyanır)
def glute(m, s):
    G = 0.58 + 0.04 * (s - 1)
    gy = 0.34 + 0.01 * s
    ell(m, 0, -(G - gy), 0.3, 0.55 + 0.01 * s, gy, 0.26 + 0.01 * s, name="Glute")


# ------------------------------------------------------------------ baldır
def calf(m, s):
    """Baldır merkezi orijin; ön +Y. Bc: arka uç."""
    Bc = 0.56 + 0.04 * (s - 1)
    ell(m, 0, 0, 0, 0.53 + 0.006 * s, 0.53 + 0.004 * s, 0.63, name="Core")  # yüzleri bacak kutusunun yüzüne (0.5) denk gelmesin, yoksa yüzeyde leke gibi görünür
    cy = 0.3 + 0.01 * s
    for side in (-1, 1):  # gastrocnemius: iki baş
        ell(m, 0.2 * side, -(Bc - cy), 0.16, 0.26, cy, 0.38, name="Gastroc")
    sy = 0.28 + 0.01 * s
    ell(m, 0, -(Bc - 0.06 - sy), -0.16, 0.34, sy, 0.38, name="Soleus")
    if s >= 3:  # kaval kemiği önünde kas
        reach = 0.53 + 0.012 * s
        ell(m, 0, reach - 0.2, 0.04, 0.17, 0.2, 0.42, name="Shin")


MODELS = []
for stage in range(1, STAGES + 1):
    MODELS.append((f"muscle_s{stage}_thigh", thigh, stage))
    MODELS.append((f"muscle_s{stage}_glute", glute, stage))
    MODELS.append((f"muscle_s{stage}_calf", calf, stage))


def build_all(wanted=None):
    textures = os.path.join(c.OUT, "textures")
    objects = []
    for name, builder, stage in MODELS:
        if wanted and name not in wanted:
            continue
        model = Model(name)
        builder(model, stage)
        obj = model.finish(textures, textured=False)
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", name + ".fbx"))
        print("MODEL", name, "üçgen:", c.tri_count(obj))
        objects.append(obj)
    return objects


# ------------------------------------------------------------------ önizleme (sahte R15 bacağı üstünde, ten rengiyle)
SKIN = (232, 176, 130)


def tint(obj, rgb):
    """Önizleme için malzemeyi ten rengine boyar (oyunda MeshPart.Color verir; dışa aktarılan FBX'te renk önemsizdir)."""
    mat = obj.data.materials[0]
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = c.srgb(rgb)


def dummy_leg(x0, tint_mat, shoe_mat, dark_mat):
    """Sahte R15 bacağı: ayak, alt bacak, üst bacak, şort tüpü; kas merkezleri üst bacak z=2.11 ve alt bacak z=0.9."""
    for side in (-1, 1):
        x = x0 + 0.5 * side
        c.rounded_box("DFoot", (x, 0.1, 0.15), (1.0, 1.15, 0.3), shoe_mat, bevel=0.06)
        c.rounded_box("DLower", (x, 0, 0.9), (1.0, 1.0, 1.193), tint_mat, bevel=0.05)
        c.rounded_box("DUpper", (x, 0, 2.11), (1.0, 1.0, 1.217), tint_mat, bevel=0.05)
        c.cylinder("DShorts", (x, 0, 2.46), 0.535, 0.75, dark_mat, vertices=20)
    c.rounded_box("DHip", (x0, 0, 2.92), (2.0, 1.0, 0.4), dark_mat, bevel=0.05)


def preview(objects):
    by_name = {o.name: o for o in objects}
    tint_mat = c.material("DummySkin", SKIN, rough=0.5, spec=0.3)
    shoe_mat = c.material("DummyShoe", (60, 70, 120), rough=0.5, spec=0.3)
    dark_mat = c.material("DummyShorts", (22, 22, 28), rough=0.8, spec=0.1)
    spacing = 3.6
    for index in range(STAGES):
        stage = index + 1
        x0 = (index - (STAGES - 1) / 2) * spacing
        dummy_leg(x0, tint_mat, shoe_mat, dark_mat)
        for part, z in (("thigh", 2.11), ("glute", 2.11), ("calf", 0.9)):
            obj = by_name.get(f"muscle_s{stage}_{part}")
            if obj is None:
                continue
            for side in (-1, 1):
                copy = obj.copy()
                copy.data = obj.data
                bpy.context.collection.objects.link(copy)
                copy.location = (x0 + 0.5 * side, 0, z)
            obj.hide_render = True  # orijindeki asıl nesne sadece kaynaktır
    return spacing


def by_name_of(objects):
    return {o.name: o for o in objects}


def rot_x_about(obj, pivot, angle):
    """Nesneyi pivot (y, z) çevresinde X ekseninde döndürür (squat önizlemesi: uyluk öne devrilir)."""
    import math

    dy, dz = obj.location.y - pivot[0], obj.location.z - pivot[1]
    ca, sa = math.cos(angle), math.sin(angle)
    obj.location.y = pivot[0] + dy * ca - dz * sa
    obj.location.z = pivot[1] + dy * sa + dz * ca
    obj.rotation_euler.x += angle


def squat_preview(by_name):
    """Squat pozunda (uyluk yatay, baldır dikey) yandan görünüm: kas bacağın üzerinde mi duruyor, sarkıyor mu?"""
    import math

    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.name != "PreviewFloor":
            obj.hide_render = True
    tint_mat = c.material("DummySkin", SKIN, rough=0.5, spec=0.3)
    shoe_mat = c.material("DummyShoe", (60, 70, 120), rough=0.5, spec=0.3)
    dark_mat = c.material("DummyShorts", (22, 22, 28), rough=0.8, spec=0.1)
    hip = (0.0, 2.72)  # (y, z): üst bacağın üstü
    stages = (1, 3, 6)
    for index, stage in enumerate(stages):
        y0 = (index - (len(stages) - 1) / 2) * 6.0  # satırlar Y boyunca dizilir, kamera +X'ten bakar
        x = 0.0
        chain_upper, chain_lower = [], []
        chain_lower.append(c.rounded_box("DFoot", (x, y0 + 0.1, 0.15), (1.0, 1.15, 0.3), shoe_mat, bevel=0.06))
        chain_lower.append(c.rounded_box("DLower", (x, y0, 0.9), (1.0, 1.0, 1.193), tint_mat, bevel=0.05))
        chain_upper.append(c.rounded_box("DUpper", (x, y0, 2.11), (1.0, 1.0, 1.217), tint_mat, bevel=0.05))
        chain_upper.append(c.cylinder("DShorts", (x, y0, 2.46), 0.535, 0.75, dark_mat, vertices=20))
        for part, z, chain in (("thigh", 2.11, chain_upper), ("glute", 2.11, chain_upper), ("calf", 0.9, chain_lower)):
            src = by_name.get(f"muscle_s{stage}_{part}")
            copy = src.copy()
            copy.data = src.data
            bpy.context.collection.objects.link(copy)
            copy.hide_render = False
            copy.location = (x, y0, z)
            chain.append(copy)
        c.rounded_box("DHip", (x, y0, 2.92), (2.0, 1.0, 0.4), dark_mat, bevel=0.05)
        # uyluk zinciri kalça çevresinde 90 derece öne devrilir; baldır zinciri dizle birlikte öne ve yukarı taşınır (dikey kalır)
        for obj in chain_upper:
            rot_x_about(obj, (y0, hip[1]), math.radians(90))
        for obj in chain_lower:
            obj.location.y += 1.217
            obj.location.z += 1.2235
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1800, 900
    c.render_view(os.path.join(c.OUT, "previews", "muscles_squat.png"), center=(0, 0, 1.9), distance=26, azimuth_deg=90, elevation_deg=8, lens=50)


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    objects = build_all(wanted)
    for obj in objects:
        tint(obj, SHORTS if "_glute" in obj.name else SKIN)
    spacing = preview(objects)
    c.add_floor((205, 214, 240), size=90)
    center = (0, 0, 1.9)
    c.add_lights(center=center, distance=14)
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = 1800, 900
    dist = 8 + STAGES * spacing * 1.15
    c.render_view(os.path.join(c.OUT, "previews", "muscles_front.png"), center=center, distance=dist, azimuth_deg=0, elevation_deg=8, lens=50)
    c.render_view(os.path.join(c.OUT, "previews", "muscles_3q.png"), center=center, distance=dist, azimuth_deg=-38, elevation_deg=14, lens=50)
    c.render_view(os.path.join(c.OUT, "previews", "muscles_back.png"), center=center, distance=dist, azimuth_deg=160, elevation_deg=14, lens=50)
    # yan görünüm: kamera yandan, dizilim derinlikte kalır; bu yüzden bir kez daha yandan bakan satır için dizilimi X'ten Y'ye çevir
    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.name != "PreviewFloor":
            obj.location = (obj.location.y, -obj.location.x, obj.location.z)
            obj.rotation_euler = (0, 0, 0)
    c.render_view(os.path.join(c.OUT, "previews", "muscles_side.png"), center=center, distance=dist, azimuth_deg=90, elevation_deg=8, lens=50)
    squat_preview(by_name_of(objects))
    c.save_blend(os.path.join(c.OUT, "blend", "muscles_all.blend"))


if __name__ == "__main__":
    main()
