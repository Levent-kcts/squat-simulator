"""Bacak kasları (seviye atladıkça büyüyen 6 aşama): server/LegGrowth'taki küre kasların yerine geçen Blender modelleri.
Her aşama için iki mesh vardır: muscle_s<N>_thigh (uyluk: ön uyluk lobları, arka uyluk, siyah şortlu popo) ve muscle_s<N>_calf (baldır).
Meshler R15 BACAK PARÇASININ MERKEZİNDE ve ona göre ölçeklidir (referans: UpperLeg 1 x 1.217 x 1, LowerLeg 1 x 1.193 x 1 stud; x = genişlik, y = ön/arka derinlik (ön +Y), z = boy).
Oyunda LegGrowth, gerçek bacak parçasının ölçüsünün bu referansa oranıyla (boyuta göre) ölçekler ve bacağa kaynaklar. Mesh iki bacakta da aynıdır (sağ-sol simetrik tasarım).
RENK: doku sadece GRİ TONLARI taşır (beyaz = ten rengi, hafif koyu tonlar kas ayrımı, çok koyu = şort rengi popo); oyunda MeshPart.Color ten rengiyle çarpılır, böylece her skinde doğru renk çıkar.
Çalıştırma:
    blender -b -P tools/blender/muscles.py            (6 aşama, önizleme tenli çizilir)
Çıktı: assets/blender/fbx/muscle_s<N>_thigh|calf.fbx, previews/muscles_front.png ve muscles_side.png, blend/muscles_all.blend, models.json + shared/ModelInfo.luau
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

W = (255, 255, 255)  # ten rengi
M = (238, 238, 242)  # biraz koyu kas karnı
D = (214, 214, 222)  # daha koyu (yan/iç kaslar)
K = (24, 24, 30)  # popo: şort rengi (çarpılsa da koyu kalır)


def ell(m, x, y, z, rx, ry, rz, rgb, seg=16, rings=10, name="Muscle"):
    m.ball((x, y, z), (rx, ry, rz), rgb, seg=seg, rings=rings, name=name)


# ------------------------------------------------------------------ uyluk
def thigh(m, s):
    """s = 1..6. Uyluk merkezi orijin; ön +Y. F: ön uç, B: arka uç, G: popo ucu (bacak derinliği 1 birim)."""
    F = 0.70 + 0.06 * (s - 1)
    B = 0.72 + 0.09 * (s - 1)
    G = B + 0.06
    # çekirdek
    ell(m, 0, 0, -0.02, 0.54 + 0.016 * s, 0.50 + 0.02 * s, 0.66, W, name="Core")
    # ön uyluk: ortada rectus + iki yanda vastus lobları
    ay = 0.24 + 0.03 * s
    for side in (-1, 1):
        ell(m, (0.25 + 0.004 * s) * side, F - ay, -0.06, 0.29 + 0.012 * s, ay, 0.48, M, name="Vastus")
    by = 0.2 + 0.035 * s
    ell(m, 0, F + 0.02 - by, 0.04, 0.2 + 0.012 * s, by, 0.5, W, name="Rectus")
    if s >= 3:  # diz üstünde damla kas
        for side in (-1, 1):
            ell(m, 0.23 * side, F - 0.18, -0.38, 0.17 + 0.01 * s, 0.18 + 0.02 * s, 0.28 + 0.01 * s, W, name="Teardrop")
    if s >= 4:  # yan dış kas süpürmesi
        for side in (-1, 1):
            ell(m, 0.44 * side, 0.12, 0.02, 0.17 + 0.01 * s, 0.22 + 0.02 * s, 0.4, D, name="Sweep")
    # arka uyluk: iki loblu hamstring
    cy = 0.24 + 0.035 * s
    for side in (-1, 1):
        ell(m, 0.2 * side, -(B - cy), -0.1, 0.25, cy, 0.46, M, name="Hamstring")
    # popo (şort renginde): kalçanın arkasında
    gy = 0.3 + 0.04 * s
    ell(m, 0, -(G - gy), 0.36, 0.56 + 0.02 * s, gy, 0.32 + 0.02 * s, K, name="Glute")


# ------------------------------------------------------------------ baldır
def calf(m, s):
    """Baldır merkezi orijin; ön +Y. Bc: arka uç."""
    Bc = 0.68 + 0.085 * (s - 1)
    ell(m, 0, 0, 0, 0.55 + 0.012 * s, 0.55 + 0.02 * s, 0.63, W, name="Core")  # yüzleri bacak kutusunun yüzüne denk gelmesin (0.5), yoksa yüzeyde leke gibi görünür
    cy = 0.22 + 0.04 * s
    for side in (-1, 1):  # gastrocnemius: iki baş
        ell(m, 0.2 * side, -(Bc - cy), 0.16, 0.24 + 0.01 * s, cy, 0.36 + 0.01 * s, M, name="Gastroc")
    ell(m, 0, -(Bc - 0.08 - (0.2 + 0.03 * s)), -0.14, 0.34, 0.2 + 0.03 * s, 0.36, W, name="Soleus")
    if s >= 3:  # kaval kemiği önünde kas (bacak yüzünün belirgin biçimde önüne çıkar, yoksa yüzeyde leke gibi kalır)
        reach = 0.54 + 0.015 * s
        ry = 0.14 + 0.015 * s
        ell(m, 0, reach - ry, 0.04, 0.17 + 0.01 * s, ry, 0.42, D, name="Shin")


MODELS = []
for stage in range(1, STAGES + 1):
    MODELS.append((f"muscle_s{stage}_thigh", thigh, stage))
    MODELS.append((f"muscle_s{stage}_calf", calf, stage))


def build_all(wanted=None):
    textures = os.path.join(c.OUT, "textures")
    objects = []
    for name, builder, stage in MODELS:
        if wanted and name not in wanted:
            continue
        model = Model(name)
        builder(model, stage)
        obj = model.finish(textures)
        record_manifest(obj)
        c.export_fbx([obj], os.path.join(c.OUT, "fbx", name + ".fbx"))
        print("MODEL", name, "üçgen:", c.tri_count(obj), "renk:", len(obj["palette"]))
        objects.append(obj)
    return objects


# ------------------------------------------------------------------ önizleme (sahte R15 bacağı üstünde, ten rengiyle)
SKIN = (232, 176, 130)


def tint_palette(obj, rgb):
    """Önizleme için palet resmini ten rengiyle çarpar (dışa aktarılan FBX beyaz paletlidir, bu sadece Blender sahnesindedir)."""
    mat = obj.data.materials[0]
    for node in mat.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image:
            image = node.image
            px = list(image.pixels)
            for i in range(0, len(px), 4):
                px[i] *= rgb[0] / 255.0
                px[i + 1] *= rgb[1] / 255.0
                px[i + 2] *= rgb[2] / 255.0
            image.pixels = px


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
        for part, z in (("thigh", 2.11), ("calf", 0.9)):
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


def main():
    wanted = c.argv_after_dashes()
    c.reset()
    c.setup_render(resolution=1500, samples=40)
    objects = build_all(wanted)
    for obj in objects:
        tint_palette(obj, SKIN)
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
    c.save_blend(os.path.join(c.OUT, "blend", "muscles_all.blend"))


if __name__ == "__main__":
    main()
