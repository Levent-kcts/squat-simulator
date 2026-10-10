"""Oyun sayfası KAPAK görseli (1920x1080) ve SİMGE (512x512): oyunun kendi Blender modelleriyle (kaslı kahraman, koçlar, petler, yumurtalar) lego tuğla duvarın önünde.
Çalıştırma (MUTLAK çıktı klasörü verilmeli):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/cover.py -- <klasör> [preview|final]
    preview: 640x360 hızlı taslak (cover_preview.png); final: cover.png (1920x1080) + icon.png (512x512)
Sahne: kahraman +Y yönüne (kameraya) bakar, kamera +Y tarafındadır; ekranın SAĞI dünya -X yönüdür (place() bunu çevirir).
Model kaynakları assets/blender/blend/*.blend (pets_all, eggs_all, coaches_all, muscles_all); kaslar oyundaki gibi bacak parçalarının merkezine oturur.
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as c  # noqa: E402

args = c.argv_after_dashes()
OUT_DIR = args[0] if args else os.path.join(c.OUT, "previews")
MODE = args[1] if len(args) > 1 else "preview"
BLEND = os.path.join(c.OUT, "blend")
random.seed(11)

SKIN = (240, 190, 140)
SHORTS = (28, 28, 38)


# ------------------------------------------------------------------ yardımcılar
def mat(name, color, rough=0.35, spec=0.5, emit=0.0, coat=0.0):
    return c.material(name, color, rough=rough, spec=spec, emit=emit, coat=coat)


def place(obj, screen_x, y, z, rot_z=0.0, scale=1.0):
    """Ekran koordinatıyla yerleştirir: screen_x > 0 ekranın SAĞI (dünya -X). rot_z: ek dönüş (rad)."""
    obj.location = (-screen_x, y, z)
    obj.rotation_euler = (0, 0, rot_z)
    obj.scale = (scale, scale, scale)


def load(blend_name, names):
    """Bir .blend dosyasından adı verilen nesneleri kopya olarak yükler ve sahneye ekler. {ad: nesne}"""
    with bpy.data.libraries.load(os.path.join(BLEND, blend_name + ".blend"), link=False) as (src, dst):
        dst.objects = [n for n in names if n in src.objects]
    result = {}
    for obj in dst.objects:
        if obj is not None:
            bpy.context.scene.collection.objects.link(obj)
            result[obj.name] = obj
    return result


def empty(name, loc, parent=None, rot=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "PLAIN_AXES"
    bpy.context.scene.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = rot
    if parent:
        obj.parent = parent
    return obj


def attach(obj, parent, loc=(0, 0, 0), rot=(0, 0, 0)):
    obj.parent = parent
    obj.location = loc
    obj.rotation_euler = rot
    return obj


def set_material(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = True


# ------------------------------------------------------------------ sahne
scene = c.reset()
if MODE == "final":
    scene_res = (1920, 1080, 160)
else:
    scene_res = (640, 360, 28)
c.setup_render(resolution=scene_res[1], samples=scene_res[2], background=(120, 110, 225))
scene.render.resolution_x, scene.render.resolution_y = scene_res[0], scene_res[1]

# Dünya: üstte koyu indigo, altta açık lavanta (gökyüzü/salon havası)
world = scene.world
nodes, links = world.node_tree.nodes, world.node_tree.links
bg = nodes["Background"]
coord = nodes.new("ShaderNodeTexCoord")
gradient = nodes.new("ShaderNodeTexGradient")
ramp = nodes.new("ShaderNodeValToRGB")
mapping = nodes.new("ShaderNodeMapping")
mapping.inputs["Rotation"].default_value = (math.radians(-90), 0, 0)
links.new(coord.outputs["Generated"], mapping.inputs["Vector"])
links.new(mapping.outputs["Vector"], gradient.inputs["Vector"])
links.new(gradient.outputs["Fac"], ramp.inputs["Fac"])
ramp.color_ramp.elements[0].color = c.srgb((205, 205, 255))
ramp.color_ramp.elements[1].color = c.srgb((95, 80, 210))
links.new(ramp.outputs["Color"], bg.inputs["Color"])
bg.inputs["Strength"].default_value = 0.9

# Zemin: lego plakası (studlu)
floor = c.rounded_box("Floor", (0, 0, -0.25), (70, 40, 0.5), mat("FloorBase", (150, 168, 238), rough=0.5, spec=0.4, coat=0.3), bevel=0.02)
stud_mat = mat("Stud", (160, 178, 245), rough=0.45, spec=0.5, coat=0.3)
bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.32, depth=0.22, location=(-23.5, -12.5, 0.1))
stud = bpy.context.active_object
stud.name = "Stud"
set_material(stud, stud_mat)
for axis, count in ((0, 48), (1, 26)):
    array = stud.modifiers.new(f"Array{axis}", "ARRAY")
    array.use_relative_offset = False
    array.use_constant_offset = True
    array.constant_offset_displace = (1.0 if axis == 0 else 0.0, 1.0 if axis == 1 else 0.0, 0.0)
    array.count = count
# Studların yarısı bir ton koyu: dama etkisi için bir de koyu levha çifti yerine yumuşak lekeler
for index in range(7):
    patch = c.rounded_box(f"Patch{index}", (random.uniform(-16, 16), random.uniform(-6, 12), 0.01), (random.uniform(5, 9), random.uniform(4, 7), 0.04), mat("Patch", (140, 156, 232), rough=0.6, spec=0.2), bevel=0.01)

# ------------------------------------------------------------------ arka duvar (lego tuğlalar)
BRICKS = [mat(f"Brick{i}", color, rough=0.3, spec=0.6, coat=0.6) for i, color in enumerate(((205, 108, 66), (222, 128, 74), (190, 92, 60), (236, 150, 84)))]
shared_meshes = []
for index, material in enumerate(BRICKS):
    brick = c.rounded_box(f"BrickBase{index}", (0, -100, -100), (1.94, 0.94, 0.94), material, bevel=0.07, segments=3)
    shared_meshes.append(brick)
# Tuğla çıkıntıları (stud) için küçük silindir: her tuğlaya iki tane (ayrı nesne, ortak mesh)
bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.27, depth=0.14, location=(0, -100, -100))
brick_stud = bpy.context.active_object
brick_stud.name = "BrickStud"
set_material(brick_stud, BRICKS[1])

WALL_Y = -5.5
for row in range(0, 14):
    offset = 1.0 if row % 2 else 0.0
    for col in range(-9, 10):
        x = col * 2.0 + offset
        if abs(x) > 19:
            continue
        base = shared_meshes[(row * 7 + col * 3) % 4]
        obj = bpy.data.objects.new("Wall", base.data)
        bpy.context.scene.collection.objects.link(obj)
        obj.location = (x, WALL_Y, 0.47 + row * 0.96)
        if row == 13:  # en üst sıra: studlar
            for s in (-0.5, 0.5):
                st = bpy.data.objects.new("WStud", brick_stud.data)
                bpy.context.scene.collection.objects.link(st)
                st.location = (x + s, WALL_Y, 0.47 + row * 0.96 + 0.52)

# Hale: kahramanın arkasında sıcak ışık dairesi (alfa degradeli yassı düzlem)
halo_mat = bpy.data.materials.new("Halo")
halo_mat.use_nodes = True
tree = halo_mat.node_tree
for node in list(tree.nodes):
    tree.nodes.remove(node)
out = tree.nodes.new("ShaderNodeOutputMaterial")
mix = tree.nodes.new("ShaderNodeMixShader")
transparent = tree.nodes.new("ShaderNodeBsdfTransparent")
emission = tree.nodes.new("ShaderNodeEmission")
emission.inputs["Color"].default_value = c.srgb((255, 214, 120))
emission.inputs["Strength"].default_value = 4.5
tc = tree.nodes.new("ShaderNodeTexCoord")
sub = tree.nodes.new("ShaderNodeVectorMath")
sub.operation = "SUBTRACT"
sub.inputs[1].default_value = (0.5, 0.5, 0.0)
length = tree.nodes.new("ShaderNodeVectorMath")
length.operation = "LENGTH"
invert = tree.nodes.new("ShaderNodeMath")
invert.operation = "MULTIPLY"
invert.inputs[1].default_value = 2.0
one_minus = tree.nodes.new("ShaderNodeMath")
one_minus.operation = "SUBTRACT"
one_minus.inputs[0].default_value = 1.0
clamp = tree.nodes.new("ShaderNodeMath")
clamp.operation = "POWER"
clamp.inputs[1].default_value = 1.6
clamp.use_clamp = True
tree.links.new(tc.outputs["UV"], sub.inputs[0])
tree.links.new(sub.outputs["Vector"], length.inputs[0])
tree.links.new(length.outputs["Value"], invert.inputs[0])
tree.links.new(invert.outputs["Value"], one_minus.inputs[1])
one_minus.use_clamp = True
tree.links.new(one_minus.outputs["Value"], clamp.inputs[0])
tree.links.new(clamp.outputs["Value"], mix.inputs["Fac"])
tree.links.new(transparent.outputs["BSDF"], mix.inputs[1])
tree.links.new(emission.outputs["Emission"], mix.inputs[2])
tree.links.new(mix.outputs["Shader"], out.inputs["Surface"])
bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, WALL_Y + 0.62, 4.6), rotation=(math.radians(90), 0, 0))
halo = bpy.context.active_object
halo.name = "HaloPlane"
halo.scale = (17, 17, 1)
halo.data.materials.append(halo_mat)

# ------------------------------------------------------------------ KAHRAMAN (kaslı bacaklı, çift pazı pozunda)
skin = mat("Skin", SKIN, rough=0.42, spec=0.5, coat=0.15)
muscle_skin = mat("MuscleSkin", (232, 170, 118), rough=0.38, spec=0.55, coat=0.25)
shirt = mat("Shirt", (70, 120, 235), rough=0.4, spec=0.5, coat=0.3)
shorts_mat = mat("Shorts", SHORTS, rough=0.5, spec=0.3)
hair_mat = mat("Hair", (32, 26, 30), rough=0.35, spec=0.5, coat=0.3)
black = mat("Black", (20, 20, 26), rough=0.3, spec=0.6)
white = mat("White", (255, 255, 255), rough=0.2, spec=0.6)
shoe_mat = mat("Shoe", (255, 235, 40), rough=0.25, spec=0.6, emit=0.6, coat=0.5)
sole_mat = mat("Sole", (255, 255, 255), rough=0.3, spec=0.5)

hero = empty("Hero", (0, 0, 0))
muscles = load("muscles_all", ["muscle_s6_thigh", "muscle_s6_calf", "muscle_s6_glute"])

HIP_Z = 2.45
UPPER, LOWER = 1.217, 1.193


def leg(side):
    """side: +1 (dünya +X = kahramanın sağı) ya da -1. Dönüş: kalça pivotu."""
    hip = empty(f"Hip{side}", (1.12 * side, 0.0, HIP_Z), hero, rot=(0, math.radians(-8 * side), 0))
    hip.scale = (1.5, 1.5, 1.08)  # KALIN bacaklar: oyunun ana fikri 'koca bacak kasları'; kaslar ve ayakkabı da birlikte büyür
    upper = c.rounded_box(f"Upper{side}", (0, 0, 0), (0.98, 0.98, UPPER), skin, bevel=0.1)
    attach(upper, hip, (0, 0, -UPPER / 2))
    thigh = muscles["muscle_s6_thigh"].copy()
    thigh.data = muscles["muscle_s6_thigh"].data
    bpy.context.scene.collection.objects.link(thigh)
    attach(thigh, hip, (0, 0, -UPPER / 2))
    glute = muscles["muscle_s6_glute"].copy()
    glute.data = muscles["muscle_s6_glute"].data
    bpy.context.scene.collection.objects.link(glute)
    attach(glute, hip, (0, 0, -UPPER / 2))
    knee = empty(f"Knee{side}", (0, 0, -UPPER), hip)
    lower = c.rounded_box(f"Lower{side}", (0, 0, 0), (0.96, 0.96, LOWER), skin, bevel=0.1)
    attach(lower, knee, (0, 0, -LOWER / 2))
    calf = muscles["muscle_s6_calf"].copy()
    calf.data = muscles["muscle_s6_calf"].data
    bpy.context.scene.collection.objects.link(calf)
    attach(calf, knee, (0, 0, -LOWER / 2))
    # Parlak sarı ayakkabı + beyaz taban
    shoe = c.rounded_box(f"Shoe{side}", (0, 0, 0), (1.12, 1.55, 0.52), shoe_mat, bevel=0.16)
    attach(shoe, knee, (0, 0.2, -LOWER - 0.05))
    sole = c.rounded_box(f"Sole{side}", (0, 0, 0), (1.18, 1.62, 0.16), sole_mat, bevel=0.06)
    attach(sole, knee, (0, 0.2, -LOWER - 0.28))
    return hip


for side in (1, -1):
    leg(side)
# Muscles'ın orijinal nesneleri sahneden kaldır (kopyaları kullanıldı)
for name in ("muscle_s6_thigh", "muscle_s6_calf", "muscle_s6_glute"):
    obj = muscles[name]
    bpy.data.objects.remove(obj)
for obj in list(bpy.data.objects):
    if obj.type == "MESH" and obj.data.name.startswith("muscle_s6_"):
        name = obj.data.name
        set_material(obj, shorts_mat if "glute" in name else muscle_skin)
        obj.hide_render = False  # kaynak .blend'de kaslar gizli (önizleme düzeni): kopyalar da gizli geliyordu
        obj.hide_viewport = False

# Gövde: şort + mavi atlet
pelvis = c.rounded_box("Pelvis", (0, 0, 0), (3.5, 1.45, 1.0), shorts_mat, bevel=0.16)
attach(pelvis, hero, (0, 0, 2.62))
torso = c.rounded_box("Torso", (0, 0, 0), (2.25, 1.12, 1.75), shirt, bevel=0.22)
attach(torso, hero, (0, 0, 3.78))
# Omuz kasları
for side in (1, -1):
    delt = c.sphere(f"Delt{side}", (0, 0, 0), (0.78, 0.7, 0.78), skin)
    attach(delt, hero, (1.52 * side, 0, 4.45))

# Kollar: çift pazı pozu (üst kol yana, ön kol yukarı)
def arm(side):
    shoulder = empty(f"Shoulder{side}", (1.55 * side, 0, 4.42), hero, rot=(0, math.radians(-90 * side), 0))
    upper_arm = c.rounded_box(f"UpperArm{side}", (0, 0, 0), (0.92, 0.92, 1.25), skin, bevel=0.1)
    attach(upper_arm, shoulder, (0, 0, -0.62))
    biceps = c.sphere(f"Biceps{side}", (0, 0, 0), (0.62, 0.66, 0.66), skin)
    attach(biceps, shoulder, (0, 0, -0.95))  # kolun ucunda, yukarı bükülünce pazı olur
    elbow = empty(f"Elbow{side}", (0, 0, -1.25), shoulder, rot=(0, math.radians(-90 * side), 0))
    forearm = c.rounded_box(f"Forearm{side}", (0, 0, 0), (0.88, 0.88, 1.15), skin, bevel=0.1)
    attach(forearm, elbow, (0, 0, -0.57))
    fist = c.sphere(f"Fist{side}", (0, 0, 0), (0.62, 0.62, 0.62), skin)
    attach(fist, elbow, (0, 0, -1.25))
    return shoulder


for side in (1, -1):
    arm(side)

# Baş: yumuşak kutu + saç + yüz
head_pivot = empty("HeadPivot", (0, 0, 5.1), hero, rot=(0, 0, math.radians(-12)))
head = c.rounded_box("Head", (0, 0, 0), (1.95, 1.7, 1.8), skin, bevel=0.4, segments=6)
attach(head, head_pivot, (0, 0, 0.78))
hair = c.rounded_box("Hair", (0, 0, 0), (2.04, 1.78, 0.78), hair_mat, bevel=0.28, segments=5)
attach(hair, head_pivot, (0, -0.05, 1.52))
for side in (-1, 1):
    eye = c.sphere(f"Eye{side}", (0, 0, 0), (0.2, 0.12, 0.3), black)
    attach(eye, head_pivot, (0.45 * side, 0.86, 0.86))
    shine = c.sphere(f"Shine{side}", (0, 0, 0), (0.075, 0.05, 0.09), white)
    attach(shine, head_pivot, (0.45 * side + 0.06, 0.95, 0.96))
    brow = c.rounded_box(f"Brow{side}", (0, 0, 0), (0.62, 0.12, 0.15), black, bevel=0.05)
    attach(brow, head_pivot, (0.47 * side, 0.88, 1.28), rot=(0, 0, math.radians(-20 * side)))
smile = c.rounded_box("Smile", (0, 0, 0), (0.8, 0.1, 0.26), black, bevel=0.09)
attach(smile, head_pivot, (0, 0.88, 0.4))
tooth = c.rounded_box("Teeth", (0, 0, 0), (0.66, 0.08, 0.13), white, bevel=0.04)
attach(tooth, head_pivot, (0, 0.93, 0.46))
for side in (-1, 1):
    cheek = c.sphere(f"Cheek{side}", (0, 0, 0), (0.22, 0.06, 0.13), mat("Cheek", (255, 140, 130), rough=0.6, spec=0.2))
    attach(cheek, head_pivot, (0.72 * side, 0.84, 0.58))

# ------------------------------------------------------------------ yan figürler: koçlar, petler, yumurtalar (hepsi +Y'ye, kameraya bakar)
coaches = load("coaches_all", ["coach_shadow", "coach_prism"])
place(coaches["coach_shadow"], 7.4, -2.6, 0, rot_z=math.radians(-8), scale=0.95)
place(coaches["coach_prism"], -7.4, -2.6, 0, rot_z=math.radians(8), scale=0.95)

pets = load("pets_all", ["pet_dragon", "pet_cat", "pet_phoenix", "pet_unicorn"])
place(pets["pet_unicorn"], -5.4, 2.0, 0, rot_z=math.radians(14), scale=0.82)
place(pets["pet_cat"], -3.7, 4.7, 0, rot_z=math.radians(18), scale=0.78)
place(pets["pet_phoenix"], 5.4, 2.0, 0, rot_z=math.radians(-12), scale=0.82)
place(pets["pet_dragon"], 3.7, 4.7, 0, rot_z=math.radians(-18), scale=0.78)

eggs = load("eggs_all", ["egg_starter", "egg_galaxy"])
place(eggs["egg_galaxy"], -6.3, 5.0, 0, rot_z=math.radians(10), scale=0.4)
place(eggs["egg_starter"], 6.3, 5.0, 0, rot_z=math.radians(-10), scale=0.44)

# ------------------------------------------------------------------ uçuşan tuğlalar ve parıltılar
glitter_mat = mat("Glitter", (255, 245, 190), emit=6.0)
flying = []
tries = 0
while len(flying) < (46 if MODE == "final" else 24) and tries < 800:
    tries += 1
    x = random.uniform(-11, 11)
    z = random.uniform(0.8, 9.6)
    y = random.uniform(-3.8, 6.0)
    # kahramanın siluetine ve başlık alanına binmesin
    if abs(x) < 4.4 and z < 7.4 and y > -3.5:
        continue
    if z > 7.2 and abs(x) < 9.5:
        continue
    if 3.4 < abs(x) < 9.5 and z < 6.6 and y > -3.2:
        continue
    base = shared_meshes[random.randint(0, 3)]
    obj = bpy.data.objects.new("Flying", base.data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = (x, y, z)
    obj.rotation_euler = (random.uniform(0, 6.28), random.uniform(0, 6.28), random.uniform(0, 6.28))
    s = random.uniform(0.55, 1.0)
    obj.scale = (s, s, s)
    flying.append(obj)
for _ in range(70 if MODE == "final" else 30):
    gx, gy, gz = random.uniform(-10, 10), random.uniform(-4, 3), random.uniform(0.5, 9.5)
    if abs(gx) < 4.4 and gz < 7.4:
        continue
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.06, 0.13), location=(gx, gy, gz))
    spark = bpy.context.active_object
    spark.name = "Glitter"
    spark.data.materials.append(glitter_mat)

# Tuğla kaynakları ve gizli referans nesneleri görünmesin
for obj in shared_meshes + [brick_stud]:
    obj.hide_render = True
    obj.hide_viewport = True

# ------------------------------------------------------------------ BAŞLIK
font = bpy.data.fonts.load("C:/Windows/Fonts/ariblk.ttf")


def text_object(name, body, size, material, extrude, offset=0.0):
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = body
    curve.font = font
    curve.size = size
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.extrude = extrude
    curve.offset = offset
    curve.bevel_depth = 0.04
    curve.bevel_resolution = 3
    obj = bpy.data.objects.new(name, curve)
    bpy.context.scene.collection.objects.link(obj)
    obj.rotation_euler = (math.radians(90), 0, math.radians(180))  # kameraya (+Y) okunur yönde
    obj.data.materials.append(material)
    return obj


title_mat = mat("Title", (255, 214, 40), rough=0.25, spec=0.6, emit=0.35, coat=0.8)
outline_mat = mat("TitleOutline", (18, 12, 28), rough=0.5, spec=0.2)
TITLE_Z = 8.5
title = text_object("Title", "SQUAT SIMULATOR", 1.5, title_mat, 0.28)
title.location = (0, -1.0, TITLE_Z)
outline = text_object("TitleOutline", "SQUAT SIMULATOR", 1.5, outline_mat, 0.6)
outline.scale = (1.05, 1.0, 1.24)  # 'offset' özelliği ince bir çizgi hatası (başlığın altında dikey çubuk) bırakıyordu: kalın kontur ölçekle yapılır
outline.location = (0, -1.55, TITLE_Z - 0.1)
# ------------------------------------------------------------------ ışık
sun = bpy.data.lights.new("Key", "AREA")
sun.energy = 1700
sun.size = 12
key = bpy.data.objects.new("Key", sun)
bpy.context.scene.collection.objects.link(key)
key.location = (-6, 13, 11)
key.rotation_euler = (Vector((0, 0, 3.2)) - key.location).to_track_quat("-Z", "Y").to_euler()
fill = bpy.data.lights.new("Fill", "AREA")
fill.energy = 800
fill.size = 14
fill.color = (0.75, 0.82, 1.0)
fill_obj = bpy.data.objects.new("Fill", fill)
bpy.context.scene.collection.objects.link(fill_obj)
fill_obj.location = (9, 12, 5)
fill_obj.rotation_euler = (Vector((0, 0, 3.2)) - fill_obj.location).to_track_quat("-Z", "Y").to_euler()
rim = bpy.data.lights.new("Rim", "AREA")
rim.energy = 1500
rim.size = 8
rim.color = (0.9, 0.55, 1.0)
rim_obj = bpy.data.objects.new("Rim", rim)
bpy.context.scene.collection.objects.link(rim_obj)
rim_obj.location = (0, -9, 9)
rim_obj.rotation_euler = (Vector((0, 0, 3.4)) - rim_obj.location).to_track_quat("-Z", "Y").to_euler()


# ------------------------------------------------------------------ kamera ve çıktı
def render(camera_loc, target, lens, path, resolution):
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = lens
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = camera_loc
    cam.rotation_euler = (Vector(target) - Vector(camera_loc)).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("yazıldı:", path)


os.makedirs(OUT_DIR, exist_ok=True)
if MODE == "final":
    render((0, 17.5, 2.6), (0, 0, 3.9), 32, os.path.join(OUT_DIR, "cover.png"), (1920, 1080))
    # Simge: kahramanın üst gövdesi ve pazıları, başlıksız
    title.hide_render = outline.hide_render = True
    scene.cycles.samples = 140
    render((0, 11.5, 4.5), (0, 0, 4.2), 38, os.path.join(OUT_DIR, "icon.png"), (512, 512))
else:
    render((0, 17.5, 2.6), (0, 0, 3.9), 32, os.path.join(OUT_DIR, "cover_preview.png"), (960, 540))
