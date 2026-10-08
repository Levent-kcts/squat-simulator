"""Ayakkabıların KARAKTERDE nasıl duracağının önizlemesi (oyuna aktarılmaz, sadece bakmak için).
R15 bacaklarını kutularla taklit eder (UpperLeg 1 x 1.217 x 1, LowerLeg 1 x 1.193 x 1, Foot 1 x 0.3 x 1) ve ayakkabı modellerini oyundaki gibi oturtur:
ölçek = (WEAR.sx * genişlik, WEAR.sl * derinlik, WEAR.sh * boy) (src/shared/Config.luau > Models.ShoeWear ile AYNI sayılar), ayakkabının ayak giriş merkezi bacak merkezine gelir.
    blender -b -P tools/blender/shoe_wear_preview.py -- lineup        (15 ayakkabı, başlangıç boyu)
    blender -b -P tools/blender/shoe_wear_preview.py -- close         (4 ayakkabı yakından, başlangıç boyu)
    blender -b -P tools/blender/shoe_wear_preview.py -- max           (son büyüme evresi: genişlik x2.0, boy x2.2)
    blender -b -P tools/blender/shoe_wear_preview.py -- side          (yandan bakış, başlangıç boyu)
    blender -b -P tools/blender/shoe_wear_preview.py -- lineup oldsneakers radiant   (yalnızca seçilenler)
Çıktı: assets/blender/previews/wear_<mod>.png
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import common as c  # noqa: E402

BLEND = os.path.join(c.OUT, "blend", "shoes_all.blend")
IDS = ["oldsneakers", "canvas", "running", "trail", "hightops", "cleats", "jump", "speed", "power", "titan", "neon", "golden", "crystal", "thunder", "radiant"]
SKIN = (255, 214, 170)
SHORTS = (24, 24, 30)
SHIRT = (80, 160, 255)


def read_wear():
    """Config.luau'daki Models.ShoeWear sayılarını okur (tek gerçek kaynak orası)."""
    text = open(os.path.join(c.ROOT, "src", "shared", "Config.luau"), encoding="utf-8").read()
    block = re.search(r"ShoeWear = \{(.*?)\n\t\t\},", text, re.S)
    values = {}
    for key, num in re.findall(r"(\w+) = (-?[0-9.]+)", block.group(1)):
        values[key] = float(num)
    return values


WEAR = read_wear()


def box(name, center, size, rgb):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.name = name
    obj.data.materials.append(c.material(name, rgb, rough=0.5))
    return obj


def load_shoe(shoe_id):
    name = "shoe_" + shoe_id
    if name not in bpy.data.objects:
        bpy.ops.wm.append(filepath=os.path.join(BLEND, "Object", name), directory=os.path.join(BLEND, "Object") + os.sep, filename=name)
    source = bpy.data.objects[name]
    source.hide_render = True
    source.hide_viewport = True
    return source


def character(shoe_id, x0, y0, w, h, torso=False):
    """Bir karakterin alt gövdesi (isteğe bağlı gövde) ve iki ayakkabı. w: genişlik/derinlik ölçeği, h: boy ölçeği."""
    foot_h = 0.3 * h
    lower_h, upper_h = 1.193 * h, 1.217 * h
    for side in (-1, 1):
        cx = x0 + 0.5 * w * side
        box("Foot", (cx, y0, foot_h / 2), (w, w, foot_h), SKIN).hide_render = True  # ayak gizli (ayakkabı örter)
        box("LowerLeg", (cx, y0, foot_h + lower_h / 2), (w, w, lower_h), SKIN)
        box("UpperLeg", (cx, y0, foot_h + lower_h + upper_h / 2), (w, w, upper_h), SKIN)
        box("Shorts", (cx, y0, foot_h + lower_h + upper_h * 0.7), (w * 1.07, w * 1.07, upper_h * 0.62), SHORTS)
        source = load_shoe(shoe_id)
        shoe = source.copy()
        shoe.data = source.data
        bpy.context.collection.objects.link(shoe)
        shoe.hide_render = False
        shoe.hide_viewport = False
        shoe.scale = (WEAR["sx"] * w, WEAR["sl"] * w, WEAR["sh"] * h)
        shoe.location = (cx, y0 - WEAR["opening"] * WEAR["sl"] * w, 0)  # ayak giriş merkezi bacak merkezinde (ön = +Y)
    if torso:
        base = foot_h + lower_h + upper_h
        box("LowerTorso", (x0, y0, base + 0.2 * h), (2 * w, w, 0.4 * h), SHORTS)
        box("UpperTorso", (x0, y0, base + 0.4 * h + 0.8 * h), (2 * w, w, 1.6 * h), SHIRT)


def main():
    args = c.argv_after_dashes()
    mode = args[0] if args else "lineup"
    ids = [a for a in args[1:] if a in IDS] or IDS
    c.reset()
    c.setup_render(resolution=1800 if mode == "lineup" else 1500, samples=48)
    if mode == "lineup":
        cols = 5
        spacing = 4.2
        for index, shoe_id in enumerate(ids):
            col, row = index % cols, index // cols
            character(shoe_id, (col - (cols - 1) / 2) * spacing, -row * 4.4, 1.0, 1.0)
        rows = (len(ids) + cols - 1) // cols
        center = (0, -(rows - 1) * 2.2, 1.6)
        c.add_floor((205, 214, 240), size=90)
        c.add_lights(center=center, distance=12)
        c.render_view(os.path.join(c.OUT, "previews", "wear_lineup.png"), center=center, distance=19 + rows * 4, azimuth_deg=-18, elevation_deg=24, lens=48)
    elif mode == "shots":
        # her ayakkabı için iki küçük görüntü (3/4 ve yan): assets/blender/previews/wear/<id>_34.png, <id>_side.png (başlangıç boyu; 'max' ile son büyüme)
        grow = 2.0 if "max" in args else 1.0
        tall = 2.2 if "max" in args else 1.0
        out_dir = os.path.join(c.OUT, "previews", "wear")
        os.makedirs(out_dir, exist_ok=True)
        for shoe_id in ids:
            c.reset()
            c._mats.clear()  # common.material önbelleği sahne sıfırlanınca geçersiz kalır
            c.setup_render(resolution=640, samples=32)
            scene = bpy.context.scene
            scene.render.film_transparent = False
            character(shoe_id, 0, 0, grow, tall)
            center = (0, 0.5 * grow, 0.9 * tall)
            c.add_floor((205, 214, 240), size=90)
            c.add_lights(center=center, distance=9)
            tag = "_max" if "max" in args else ""
            c.render_view(os.path.join(out_dir, f"{shoe_id}_34{tag}.png"), center=center, distance=(7.5 if grow == 1.0 else 15), azimuth_deg=-38, elevation_deg=24, lens=55)
            c.render_view(os.path.join(out_dir, f"{shoe_id}_side{tag}.png"), center=center, distance=(7.5 if grow == 1.0 else 15), azimuth_deg=90, elevation_deg=6, lens=55)
            print("SHOT", shoe_id)
    elif mode == "close":
        spacing = 4.0
        shown = ids[:4]
        for index, shoe_id in enumerate(shown):
            character(shoe_id, (index - (len(shown) - 1) / 2) * spacing, 0, 1.0, 1.0)
        center = (0, 0, 0.9)
        c.add_floor((205, 214, 240), size=90)
        c.add_lights(center=center, distance=9)
        c.render_view(os.path.join(c.OUT, "previews", "wear_close.png"), center=center, distance=13.5, azimuth_deg=-28, elevation_deg=20, lens=50)
    elif mode == "max":
        spacing = 6.2
        for index, shoe_id in enumerate(ids[:4]):
            character(shoe_id, (index - (len(ids[:4]) - 1) / 2) * spacing, 0, 2.0, 2.2, torso=True)
        center = (0, 0, 3.4)
        c.add_floor((205, 214, 240), size=90)
        c.add_lights(center=center, distance=14)
        c.render_view(os.path.join(c.OUT, "previews", "wear_max.png"), center=center, distance=24, azimuth_deg=-14, elevation_deg=14, lens=42)
    else:  # side
        spacing = 4.0
        for index, shoe_id in enumerate(ids[:5]):
            character(shoe_id, 0, index * spacing, 1.0, 1.0)
        center = (0, (len(ids[:5]) - 1) * spacing / 2, 1.2)
        c.add_floor((205, 214, 240), size=90)
        c.add_lights(center=center, distance=12)
        c.render_view(os.path.join(c.OUT, "previews", "wear_side.png"), center=center, distance=20, azimuth_deg=90, elevation_deg=8, lens=48)
    print("PREVIEW", mode)


if __name__ == "__main__":
    main()
