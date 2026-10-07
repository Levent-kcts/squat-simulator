"""Birden çok modeli TEK FBX'te toplar (Studio'ya tek seferde aktarmak için): her model ayrı bir nesnedir (adı = model adı), yan yana dizilir.
    blender -b -P tools/blender/pack.py -- test     (cat + starter yumurta: ilk deneme)
    blender -b -P tools/blender/pack.py -- pets     (13 pet)
    blender -b -P tools/blender/pack.py -- eggs     (6 yumurta)
    blender -b -P tools/blender/pack.py -- cat dog egg_starter ...   (seçilenler: pet_<id> / egg_<id> ya da çıplak id)
Çıktı: assets/blender/fbx/pack_<ad>.fbx. Studio'da içe aktarınca bir Model oluşur, içinde her model bir MeshPart (adı pet_cat, egg_starter...).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402
from lib import Model, record_manifest  # noqa: E402
import pets  # noqa: E402
import eggs  # noqa: E402

PRESETS = {
    "test": ["pet_cat", "egg_starter"],
    "pets": ["pet_" + pet_id for pet_id, _, _ in pets.PETS],
    "eggs": ["egg_" + egg_id for egg_id, _ in eggs.EGGS],
}


def main():
    args = c.argv_after_dashes() or ["test"]
    label = args[0] if len(args) == 1 and args[0] in PRESETS else "custom"
    names = PRESETS[args[0]] if label != "custom" else args
    builders = {}
    for pet_id, builder, color in pets.PETS:
        builders["pet_" + pet_id] = lambda m, builder=builder, color=color: builder(m, color)
    for egg_id, builder in eggs.EGGS:
        builders["egg_" + egg_id] = builder
    c.reset()
    textures = os.path.join(c.OUT, "textures")
    objects = []
    for name in names:
        key = name if name in builders else ("pet_" + name if "pet_" + name in builders else "egg_" + name)
        model = Model(key)
        builders[key](model)
        obj = model.finish(textures)
        record_manifest(obj)
        objects.append(obj)
    for index, obj in enumerate(objects):  # yan yana diz (dışa aktarma konumları sadece düzen içindir; oyun yeniden konumlandırır)
        obj.location = (index * 9.0, 0, 0)
    out = os.path.join(c.OUT, "fbx", f"pack_{label}.fbx")
    c.export_fbx(objects, out)
    print("PACK", out, [(o.name, c.tri_count(o)) for o in objects])


if __name__ == "__main__":
    main()
