"""Game pass SİMGELERİ (512x512): Coach Prism, Coach Shadow, Autoclick, VIP, Auto Open, Multi Open.
Oyunun kendi Blender modelleri (koçlar, yumurtalar) ve simgeleri (taç, imleç) + renkli arka plan + yazı. Sahibi Creator Hub'da her pass'in 'Icon' alanına yükler.
Çalıştırma (MUTLAK çıktı klasörü verilmeli):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/passicons.py -- <klasör> [preview|final]
Çıktı: pass_<ad>.png (512x512, RGB) + sheet.png (hepsi yan yana önizleme). 3B katman (model + yazı) saydam arka planla çekilir, arka plan/parıltı/gölge numpy ile eklenir.
Not: Blender piksel verisi alttan yukarı sıralıdır; resimler Non-Color okunur/yazılır (renk kayması olmasın).
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as c  # noqa: E402

args = c.argv_after_dashes()
OUT_DIR = args[0] if args else os.path.join(c.OUT, "previews")
MODE = args[1] if len(args) > 1 else "final"
BLEND = os.path.join(c.OUT, "blend")
ICONS = os.path.join(os.path.dirname(c.OUT), "icons")
SIZE = 512
FRAME = 10.0  # ortografik kare genişliği (dünya birimi): 1 birim = 51.2 piksel
PPU = SIZE / FRAME
TEXT_WIDTH = 8.8
SAMPLES = 90 if MODE == "final" else 24
FONT = "C:/Windows/Fonts/ariblk.ttf"

# ad, (üst renk, alt renk), parıltı rengi, yazı satırları [(yazı, boy, renk)], içerik
SPECS = [
    {"name": "coach_prism", "bg": ((150, 225, 255), (120, 95, 245)), "glow": (255, 255, 255), "lines": [("COACH", 0.95, (240, 240, 250)), ("PRISM", 1.9, (255, 214, 40))],
     "model": ("coaches_all", ["coach_prism"], 8.0, 6.0, [(0, 0.0)], 8)},
    {"name": "coach_shadow", "bg": ((95, 40, 160), (14, 4, 40)), "glow": (190, 90, 255), "lines": [("COACH", 0.95, (225, 195, 255)), ("SHADOW", 1.9, (255, 214, 40))],
     "model": ("coaches_all", ["coach_shadow"], 8.0, 6.0, [(0, 0.0)], 8)},
    {"name": "autoclick", "bg": ((255, 214, 70), (255, 120, 35)), "glow": (255, 255, 200), "lines": [("AUTO", 1.7, (240, 240, 250)), ("CLICK", 1.7, (240, 240, 250))],
     "flat": ("click.png", 0.9)},
    {"name": "vip", "bg": ((255, 130, 205), (160, 35, 145)), "glow": (255, 220, 250), "lines": [("VIP", 2.6, (255, 214, 40))],
     "flat": ("shop_vip.png", 1.0)},
    {"name": "auto_open", "bg": ((90, 225, 205), (25, 105, 185)), "glow": (200, 255, 245), "lines": [("AUTO", 1.7, (240, 240, 250)), ("OPEN", 1.7, (255, 214, 40))],
     "model": ("eggs_all", ["egg_galaxy"], 6.4, 5.4, [(0, 0.0)], 0), "ring": True},
    {"name": "multi_open", "bg": ((135, 165, 255), (85, 55, 205)), "glow": (230, 225, 255), "lines": [("MULTI", 1.7, (240, 240, 250)), ("OPEN", 1.7, (255, 214, 40))],
     "model": ("eggs_all", ["egg_desert", "egg_forest", "egg_starter"], 5.4, 9.0, [(-3.1, 0.0), (3.1, 0.0), (0.0, 0.6)], 0)},
]


# ------------------------------------------------------------------ 3B katman (model + yazı), saydam arka plan
def build_text(lines):
    """Satırları alttan yukarı doğru yerleştirmek için nesneleri üretir; her satır TEXT_WIDTH'e sığacak şekilde küçülür. Dönüş: (nesneler, yükseklik)."""
    font = bpy.data.fonts.load(FONT)
    gap = 0.22
    rows = []
    for body, size, color in lines:
        curve = bpy.data.curves.new("T", "FONT")
        curve.body = body
        curve.font = font
        curve.size = size
        curve.align_x = "CENTER"
        curve.align_y = "CENTER"
        curve.extrude = 0.12
        curve.bevel_depth = 0.03
        curve.bevel_resolution = 2
        probe = bpy.data.objects.new("probe", curve)
        bpy.context.scene.collection.objects.link(probe)
        bpy.context.view_layer.update()
        width = probe.dimensions.x
        height = probe.dimensions.y
        shrink = min(1.0, (TEXT_WIDTH - 0.5) / max(width, 0.001))
        rows.append((curve, shrink, size * 0.74 * shrink, color))
        bpy.data.objects.remove(probe)
    total = sum(r[2] for r in rows) + gap * (len(rows) - 1)
    return rows, total, gap


def place_text(rows, gap, top_z):
    """top_z: ilk satırın üst kenarı. Yazı + 14 yönlü koyu kontur (kontur AYRI curve verisi kullanır: malzeme paylaşılırsa yazı rengine boyanır)."""
    fill_cache = {}
    z = top_z
    outline_mat = c.material("Outline", (24, 12, 44), rough=0.6, spec=0.1)
    for curve, shrink, height, color in rows:
        centre = z - height / 2
        key = tuple(color)
        if key not in fill_cache:
            bright = sum(color) / 3 > 200 and min(color) > 200
            fill_cache[key] = c.material("Fill" + str(key), color, rough=0.35, spec=0.4, emit=0.12 if bright else 0.5, coat=0.5)
        outline_curve = curve.copy()
        outline_curve.materials.clear()
        outline_curve.materials.append(outline_mat)
        reach = 0.085 + 0.02 * height
        for k in range(14):
            angle = k / 14 * math.tau
            outline = bpy.data.objects.new("Out", outline_curve)
            bpy.context.scene.collection.objects.link(outline)
            outline.rotation_euler = (math.radians(90), 0, math.radians(180))
            outline.scale = (shrink, shrink, 1.0)
            outline.location = (math.cos(angle) * reach, -0.35, centre + math.sin(angle) * reach)
        face = bpy.data.objects.new("Face", curve)
        bpy.context.scene.collection.objects.link(face)
        face.rotation_euler = (math.radians(90), 0, math.radians(180))
        face.scale = (shrink, shrink, 1.0)
        face.location = (0, 0.0, centre)
        curve.materials.clear()
        curve.materials.append(fill_cache[key])
        z -= height + gap


def load_models(blend_name, names):
    with bpy.data.libraries.load(os.path.join(BLEND, blend_name + ".blend"), link=False) as (src, dst):
        dst.objects = [n for n in names if n in src.objects]
    result = {}
    for obj in dst.objects:
        if obj is not None:
            bpy.context.scene.collection.objects.link(obj)
            result[obj.name] = obj
    return [result[n] for n in names if n in result]


def add_lights():
    for name, energy, size, color, loc in (
        ("Key", 1700, 12, (1, 1, 1), (-6, 13, 11)),
        ("Fill", 900, 14, (0.75, 0.82, 1.0), (9, 12, 5)),
        ("Rim", 1300, 8, (1.0, 0.8, 1.0), (0, -9, 9)),
    ):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.size = size
        light.color = color
        obj = bpy.data.objects.new(name, light)
        bpy.context.scene.collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (Vector((0, 0, 3.5)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_layer(spec, path):
    """Model + yazıyı saydam arka planla çeker. Dönüş: (model alanının piksel kutusu (üst, alt), yüksekliği)."""
    c._mats.clear()
    scene = c.reset()
    c.setup_render(resolution=SIZE, samples=SAMPLES, background=(255, 255, 255))
    scene.render.resolution_x = scene.render.resolution_y = SIZE
    scene.render.film_transparent = True
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    add_lights()

    rows, text_height, gap = build_text(spec["lines"])
    model_height = FRAME - 0.5 - 0.5 - 0.4 - text_height  # üst boşluk, alt boşluk, model-yazı aralığı
    top_z = model_height + 0.5  # kare üst kenarı (model tabanı z = 0)
    cam_z = top_z - FRAME / 2

    if "model" in spec:
        blend_name, names, target_h, max_w, offsets, _ = spec["model"]
        objs = load_models(blend_name, names)
        scale_h = min(target_h, model_height)
        for index, obj in enumerate(objs):
            bpy.context.view_layer.update()
            dims = obj.dimensions
            scale = (scale_h * (1.0 if len(objs) == 1 else (0.74 if index < 2 else 1.0))) / max(dims.z, 0.001)
            if len(objs) > 1:
                scale = min(scale, 3.4 / max(dims.x, 0.001)) if index < 2 else min(scale, 4.4 / max(dims.x, 0.001))
            else:
                scale = min(scale, max_w / max(dims.x, 0.001))
            obj.scale = (scale, scale, scale)
            offset_x, offset_y = offsets[index]
            obj.location = (-offset_x, offset_y, 0)
            obj.rotation_euler = (0, 0, math.radians(0 if len(objs) == 1 else (16 if index == 0 else (-16 if index == 1 else 0))))
        # Tabanı z = 0'a ve yatayda ortaya oturt (kaynak orijin taban ortasıdır; yine de sınır kutusuna bak)
        bpy.context.view_layer.update()

    text_top = -0.3
    place_text(rows, gap, text_top)

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = FRAME
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (0, 30, cam_z)
    cam.rotation_euler = (Vector((0, 0, cam_z)) - Vector(cam.location)).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    bpy.ops.render.render(write_still=True)
    # Model alanı: üstten 0.5 birim aşağıdan başlar, model_height kadar sürer
    return (0.5 * PPU, (0.5 + model_height) * PPU), model_height


# ------------------------------------------------------------------ 2B katmanlar (numpy)
def read_image(path):
    image = bpy.data.images.load(path)
    image.colorspace_settings.name = "Non-Color"
    image.alpha_mode = "STRAIGHT"
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return np.flipud(data.reshape(h, w, 4))


def write_image(path, array):
    h, w = array.shape[:2]
    image = bpy.data.images.new("out", w, h, alpha=False)
    image.colorspace_settings.name = "Non-Color"
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(array[..., :3], 0, 1)
    image.pixels.foreach_set(np.flipud(rgba).ravel())
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def box_blur(a, radius):
    """3 geçişli kutu bulanıklığı (gölge için); a: HxW."""
    out = a.astype(np.float64)
    size = 2 * radius + 1
    for _ in range(3):
        for axis in (0, 1):
            pad = [(0, 0), (0, 0)]
            pad[axis] = (radius, radius)
            padded = np.pad(out, pad, mode="edge")
            cum = np.cumsum(padded, axis=axis)
            zero_shape = list(cum.shape)
            zero_shape[axis] = 1
            cum = np.concatenate([np.zeros(zero_shape), cum], axis=axis)
            count = a.shape[axis]
            hi = np.take(cum, np.arange(size, size + count), axis=axis)
            lo = np.take(cum, np.arange(0, count), axis=axis)
            out = (hi - lo) / size
    return out.astype(np.float32)


def lerp_color(c0, c1, t):
    c0 = np.array(c0, dtype=np.float32) / 255
    c1 = np.array(c1, dtype=np.float32) / 255
    return c0 * (1 - t)[..., None] + c1 * t[..., None]


def background(spec):
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
    top, bottom = spec["bg"]
    base = lerp_color(top, bottom, ys / (SIZE - 1))
    # lego studları: hafif parlak yuvarlaklar
    step = 64
    cy, cx = (ys % step) - step / 2, (xs % step) - step / 2
    row = (ys // step).astype(int)
    cx = ((xs + (row % 2) * step / 2) % step) - step / 2
    stud = np.clip(1.0 - (np.sqrt(cx**2 + cy**2) - 17.0), 0, 1)
    base = base + (stud * 0.07)[..., None]
    # merkezde parıltı
    glow = np.array(spec["glow"], dtype=np.float32) / 255
    d2 = ((xs - SIZE / 2) ** 2 + (ys - SIZE * 0.42) ** 2) / (SIZE * 0.38) ** 2
    base = base + glow * np.exp(-d2)[..., None] * 0.42
    # köşelerde hafif koyulaşma
    v = np.clip(((xs - SIZE / 2) ** 2 + (ys - SIZE / 2) ** 2) / (SIZE * 0.78) ** 2, 0, 1)
    base = base * (1 - 0.28 * v)[..., None]
    return np.clip(base, 0, 1)


def over(base, layer_rgb, layer_a):
    return base * (1 - layer_a[..., None]) + layer_rgb * layer_a[..., None]


def shadow_of(alpha, dx=0, dy=7, radius=7, strength=0.38):
    shifted = np.zeros_like(alpha)
    h, w = alpha.shape
    ys0, ys1 = max(0, dy), min(h, h + dy)
    xs0, xs1 = max(0, dx), min(w, w + dx)
    shifted[ys0:ys1, xs0:xs1] = alpha[ys0 - dy : ys1 - dy, xs0 - dx : xs1 - dx]
    return box_blur(shifted, radius) * strength


def draw_ring(center, radius, thickness):
    """Egg etrafında iki dairesel ok (beyaz): [alfa HxW]."""
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
    dx, dy = xs - center[0], ys - center[1]
    r = np.sqrt(dx * dx + dy * dy)
    ang = (np.degrees(np.arctan2(dy, dx)) + 360) % 360
    band = np.clip(thickness / 2 + 1.0 - np.abs(r - radius), 0, 1)
    alpha = np.zeros_like(r)
    for start in (20, 200):
        end = start + 130
        in_arc = ((ang >= start) & (ang <= end)).astype(np.float32)
        alpha = np.maximum(alpha, band * in_arc)
        # ok başı: bitiş açısında teğet yönünde üçgen
        a = math.radians(end)
        tip = np.array([center[0] + radius * math.cos(a) - math.sin(a) * thickness * 1.6, center[1] + radius * math.sin(a) + math.cos(a) * thickness * 1.6])
        base1 = np.array([center[0] + (radius + thickness * 1.5) * math.cos(a), center[1] + (radius + thickness * 1.5) * math.sin(a)])
        base2 = np.array([center[0] + (radius - thickness * 1.5) * math.cos(a), center[1] + (radius - thickness * 1.5) * math.sin(a)])
        # barisentrik içerde mi
        def sign(p, q, s):
            return (p[0] - s[0]) * (q[1] - s[1]) - (q[0] - s[0]) * (p[1] - s[1])

        d1 = sign((xs, ys), base1, base2)
        d2 = sign((xs, ys), base2, tip)
        d3 = sign((xs, ys), tip, base1)
        inside = ~(((d1 < 0) | (d2 < 0) | (d3 < 0)) & ((d1 > 0) | (d2 > 0) | (d3 > 0)))
        alpha = np.maximum(alpha, inside.astype(np.float32))
    return alpha


def sparkle(alpha, cx, cy, size):
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
    dx, dy = np.abs(xs - cx) / size, np.abs(ys - cy) / size
    shape = np.clip(1.0 - (np.sqrt(dx) + np.sqrt(dy)) * 1.0, 0, 1)
    return np.maximum(alpha, np.clip(shape * 3.0, 0, 1))


def compose(spec, layer_path, region, out_path):
    base = background(spec)
    top_px, bottom_px = region
    mid = (top_px + bottom_px) / 2

    # 2B içerik (taç, imleç) ya da yumurta halkası: modelin arkasında
    if "flat" in spec:
        file_name, scale = spec["flat"]
        icon = read_image(os.path.join(ICONS, file_name))
        ih, iw = icon.shape[:2]
        target = (bottom_px - top_px) * 1.02 * scale
        factor = target / max(ih, iw)
        # en yakın komşu yerine bilineer: Blender image.scale kullanmadan basit örnekleme
        new_h, new_w = int(ih * factor), int(iw * factor)
        ys = np.clip((np.arange(new_h) / factor).astype(int), 0, ih - 1)
        xs = np.clip((np.arange(new_w) / factor).astype(int), 0, iw - 1)
        small = icon[ys][:, xs]
        # küçültmede çizgi kirliliğini azaltmak için hafif kutu ortalaması
        canvas_rgb = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
        canvas_a = np.zeros((SIZE, SIZE), dtype=np.float32)
        y0 = int(mid - new_h / 2)
        x0 = int(SIZE / 2 - new_w / 2)
        canvas_rgb[y0 : y0 + new_h, x0 : x0 + new_w] = small[..., :3]
        canvas_a[y0 : y0 + new_h, x0 : x0 + new_w] = small[..., 3]
        base = over(base, np.zeros(3, dtype=np.float32), shadow_of(canvas_a, 0, 8, 8, 0.4))
        base = over(base, canvas_rgb, canvas_a)
    if spec.get("ring"):
        ring = draw_ring((SIZE / 2, mid), (bottom_px - top_px) * 0.43, 20)
        base = over(base, np.zeros(3, dtype=np.float32), shadow_of(ring, 0, 6, 6, 0.35))
        base = over(base, np.array([1.0, 1.0, 1.0], dtype=np.float32), ring * 0.95)

    layer = read_image(layer_path)
    rgb, alpha = layer[..., :3], layer[..., 3]
    base = over(base, np.zeros(3, dtype=np.float32), shadow_of(alpha, 0, 7, 7, 0.4))
    base = over(base, rgb, alpha)

    # parıltılar
    spark = np.zeros((SIZE, SIZE), dtype=np.float32)
    for cx, cy, size in ((62, 74, 26), (452, 118, 20), (78, 250, 14), (440, 285, 12), (404, 52, 11)):
        spark = sparkle(spark, cx, cy, size)
    base = over(base, np.array([1.0, 1.0, 0.92], dtype=np.float32), spark * 0.9)
    write_image(out_path, base)
    print("yazıldı:", out_path)
    return base


os.makedirs(OUT_DIR, exist_ok=True)
results = []
for spec in SPECS:
    layer_path = os.path.join(OUT_DIR, f"_layer_{spec['name']}.png")
    region, model_h = render_layer(spec, layer_path)
    out_path = os.path.join(OUT_DIR, f"pass_{spec['name']}.png")
    results.append(compose(spec, layer_path, region, out_path))

# Önizleme: 3 x 2 sayfa (görünüm kontrolü için)
sheet = np.ones((SIZE * 2 + 30, SIZE * 3 + 40, 3), dtype=np.float32) * 0.95
for index, image in enumerate(results):
    row, col = divmod(index, 3)
    sheet[10 + row * (SIZE + 10) : 10 + row * (SIZE + 10) + SIZE, 10 + col * (SIZE + 10) : 10 + col * (SIZE + 10) + SIZE] = image
write_image(os.path.join(OUT_DIR, "sheet.png"), sheet)
print("tamam")
