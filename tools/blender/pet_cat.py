"""ÖRNEK 3: Cat (ilk pet). Tombul, iri başlı, kocaman gözlü sevimli kedi (arayüzdeki pet yüzü simgesiyle aynı havada).
Parçalar (kodla yeniden boyanır): Fur (pet rengi: gövde, baş, kulaklar, ayaklar, kuyruk), Muzzle (açık renk burun çevresi), InnerEar, Cheeks, Nose (pembe),
Eyes (koyu), Shine (göz parıltısı, beyaz), Paws (açık ön patiler), Whiskers (bıyık).
Boyut: yaklaşık 2.3 stud yüksek, orijin ayakların altı, ön +Y. Pet takip ederken kodla ölçeklenir (birleşme boyu Config.PetFusion.Scale).
Çalıştır: blender -b -P tools/blender/pet_cat.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402

NAME = "pet_cat"
FUR = (255, 190, 120)  # Config.Pets[1].color
CREAM = (255, 240, 220)
DARK = (70, 36, 48)
PINK = (255, 150, 175)

c.reset()
c.setup_render()

fur_mat = c.material("Fur", FUR, rough=0.5, coat=0.15)
objs = {"Fur": []}

# ---- Gövde, baş, ayaklar, kuyruk, kulaklar (hepsi Fur)
objs["Fur"].append(c.sphere("Body", (0, -0.12, 0.78), (0.64, 0.72, 0.66), fur_mat, subdiv=0))
objs["Fur"].append(c.sphere("Head", (0, 0.1, 1.6), (0.98, 0.84, 0.8), fur_mat))
for side in (-1, 1):
    objs["Fur"].append(c.sphere("BackFoot", (0.4 * side, -0.22, 0.17), (0.24, 0.32, 0.17), fur_mat, segments=14, rings=8))
    ear = c.cone("Ear", (0.58 * side, 0.02, 2.3), 0.36, 0.07, 0.62, fur_mat, rotation=(math.radians(-8), math.radians(20 * side), 0), bevel=0.04, bevel_segments=3, subdiv=1)
    objs["Fur"].append(ear)
objs["Fur"].append(c.tube("Tail", [(0.0, -0.72, 0.42), (0.0, -1.22, 0.5), (0.14, -1.5, 0.95), (0.4, -1.42, 1.45)], 0.17, fur_mat))
objs["Fur"].append(c.sphere("TailTip", (0.4, -1.42, 1.47), (0.1, 0.1, 0.1), fur_mat, segments=16, rings=8))
fur = c.join(objs["Fur"], "Fur", fur_mat)

# ---- Yüz ve detaylar
inner = []
for side in (-1, 1):
    inner.append(c.cone("InnerEar", (0.58 * side, 0.14, 2.26), 0.22, 0.04, 0.44, c.material("InnerEar", PINK), rotation=(math.radians(-8), math.radians(20 * side), 0), vertices=12))
inner_ear = c.join(inner, "InnerEar", c.material("InnerEar", PINK, rough=0.5))

muzzle = c.sphere("Muzzle", (0, 0.78, 1.34), (0.36, 0.24, 0.24), c.material("Muzzle", CREAM, rough=0.5), segments=14, rings=8)
nose = c.sphere("Nose", (0, 0.97, 1.44), (0.1, 0.07, 0.07), c.material("Nose", PINK, rough=0.3), segments=14, rings=8)

eyes, shine, cheeks = [], [], []
for side in (-1, 1):
    eyes.append(c.sphere("Eye", (0.37 * side, 0.82, 1.68), (0.15, 0.09, 0.22), c.material("Eyes", DARK, rough=0.15), segments=14, rings=8))
    shine.append(c.sphere("ShineA", (0.33 * side, 0.9, 1.78), (0.055, 0.04, 0.065), c.material("Shine", (255, 255, 255), rough=0.1, emit=0.6), segments=14, rings=8))
    shine.append(c.sphere("ShineB", (0.41 * side, 0.9, 1.6), (0.028, 0.03, 0.03), c.material("Shine", (255, 255, 255), rough=0.1, emit=0.6), segments=14, rings=8))
    cheek = c.sphere("Cheek", (0.66 * side, 0.58, 1.38), (0.17, 0.07, 0.11), c.material("Cheeks", PINK, rough=0.6), segments=14, rings=8)
    cheek.rotation_euler = (0, math.radians(-25 * side), 0)
    cheeks.append(cheek)
eyes_obj = c.join(eyes, "Eyes", c.material("Eyes", DARK, rough=0.15))
shine_obj = c.join(shine, "Shine", c.material("Shine", (255, 255, 255), rough=0.1, emit=0.6))
cheeks_obj = c.join(cheeks, "Cheeks", c.material("Cheeks", PINK, rough=0.6))

# Ön patiler
paw_mat = c.material("Paws", CREAM, rough=0.55)
paws = [c.sphere("Paw", (0.27 * side, 0.4, 0.16), (0.17, 0.21, 0.14), paw_mat, segments=14, rings=8) for side in (-1, 1)]
paws_obj = c.join(paws, "Paws", paw_mat)

# Bıyıklar (koyu, ince)
whisker_mat = c.material("Whiskers", (95, 70, 70), rough=0.5)
whiskers = []
for side in (-1, 1):
    for index, angle in enumerate((-16, 0, 16)):
        whisker = c.cylinder("Whisker", (0.74 * side, 0.74, 1.4 + 0.03 * index), 0.02, 0.5, whisker_mat, rotation=(0, math.radians(90), math.radians(angle * side)), vertices=8)
        whiskers.append(whisker)
whiskers_obj = c.join(whiskers, "Whiskers", whisker_mat)

objects = [fur, inner_ear, muzzle, nose, eyes_obj, shine_obj, cheeks_obj, paws_obj, whiskers_obj]

# ---- Önizleme + dışa aktarım
c.add_floor((205, 214, 240))
c.add_lights(center=(0, 0, 1.2), distance=8)
c.render_view(os.path.join(c.OUT, "previews", NAME + "_front.png"), center=(0, 0, 1.2), distance=8.5, azimuth_deg=-28, elevation_deg=12, lens=70)
c.render_view(os.path.join(c.OUT, "previews", NAME + "_back.png"), center=(0, 0, 1.2), distance=8.5, azimuth_deg=-150, elevation_deg=14, lens=70)
c.export_fbx(objects, os.path.join(c.OUT, "fbx", NAME + ".fbx"))
c.save_blend(os.path.join(c.OUT, "blend", NAME + ".blend"))
print("TAMAM", NAME, [(o.name, c.tri_count(o)) for o in objects], "toplam üçgen:", sum(c.tri_count(o) for o in objects))
