"""Yukleme ekrani icin AGIRLIK BARI (barbell) resmi: seffaf arka planli 1024x512 PNG (assets/loading/barbell.png). Boyanmaz, oldugu gibi gosterilir.
Krom mil, tirtikli tutma yerleri, iki yanda koyu lacivert plakalar (sari halka suslu), krom kelepce ve uc kapaklari. Onden-sagdan, hafif yukaridan ortografik gorunum.
Calistir: blender -b -P tools/loading/make_barbell.py -- <MUTLAK yol>/assets/loading/barbell.png   (gorece yol Blender'in kendi klasorune yazilir!)
Birim: 1 = 1 cm. Toplam boy ~124, plaka capi 48 (kisa mil: simge olarak okunur, gercek barbelden daha tombul)."""
import math
import sys

import bpy

out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "barbell.png"

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def material(name, color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


CHROME = material("Chrome", (0.88, 0.89, 0.92), 1.0, 0.18)
STEEL = material("DarkSteel", (0.34, 0.35, 0.40), 0.6, 0.55)
PLATE = material("Plate", (0.11, 0.12, 0.19), 0.0, 0.7)
PLATE_RIM = material("PlateRim", (0.22, 0.24, 0.38), 0.0, 0.7)
GOLD = material("Gold", (1.0, 0.76, 0.10), 0.0, 0.6)
GOLD.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.7, 0.1, 1)  # sari halka karanlikta da parlak okunsun
GOLD.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.6
for mat in (PLATE, PLATE_RIM, GOLD):  # plakalar mat plastik gibi: gokyuzunu yansitip solmasin
    mat.node_tree.nodes["Principled BSDF"].inputs["Specular IOR Level"].default_value = 0.0


def smooth(obj, bevel_width=0.0, segments=3):
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if bevel_width > 0:
        bevel = obj.modifiers.new("Bevel", "BEVEL")
        bevel.width = bevel_width
        bevel.segments = segments
        bevel.limit_method = "ANGLE"
        normals = obj.modifiers.new("Normals", "WEIGHTED_NORMAL")
        normals.keep_sharp = True


def cylinder(x, radius, length, mat, bevel=0.0):
    """X ekseni boyunca silindir: merkez x, boy length."""
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=length, vertices=64, location=(x, 0, 0), rotation=(0, math.pi / 2, 0))
    obj = bpy.context.object
    obj.data.materials.append(mat)
    smooth(obj, bevel)
    return obj


def torus(x, major, minor, mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=96, minor_segments=16, location=(x, 0, 0), rotation=(0, math.pi / 2, 0))
    obj = bpy.context.object
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


# Mil: ortada krom, iki yanda koyu tirtikli tutma bolgesi; kollar (sleeve) plakalari tasir (simge olarak tombul: gercek barbelden kalin)
cylinder(0, 2.1, 76, CHROME, 0.25)
for side in (-1, 1):
    cylinder(side * 21, 2.3, 18, STEEL, 0.2)  # tutma yeri
    cylinder(side * 49, 3.4, 34, CHROME, 0.3)  # kol
    cylinder(side * 67, 3.9, 3, CHROME, 0.5)  # uc kapagi
    # Plakalar: buyuk (r 24, kalin) ve kucuk (r 18). Her plakanin HER IKI yuzunde kabarik halka ve sari susleme halkasi (kamera hangi yuzu gorurse gorsun ayni ozen)
    for x_from, x_to, radius in ((38, 47, 24), (48, 54, 18)):
        mid = side * (x_from + x_to) / 2
        cylinder(mid, radius, x_to - x_from, PLATE, 0.9)
        for face_x in (x_from, x_to):
            torus(side * face_x, radius - 2.4, 1.0, PLATE_RIM)
            torus(side * face_x, radius * 0.56, 0.85, GOLD)
        cylinder(mid, 5.6, (x_to - x_from) + 1.6, CHROME, 0.35)  # gobek kapagi
    cylinder(side * 58, 4.8, 4, CHROME, 0.45)  # kelepce


# Isik: yukari-soldan ana isik + yumusak dolgu; gokyuzu dokusu kromun yansimasi icin (arka plan seffaf kalir)
bpy.ops.object.light_add(type="SUN", location=(-40, -60, 90))
sun = bpy.context.object
sun.data.energy = 4.6
sun.rotation_euler = (math.radians(45), 0, math.radians(-35))
bpy.ops.object.light_add(type="SUN", location=(60, 50, 40))
fill = bpy.context.object
fill.data.energy = 1.2
fill.rotation_euler = (math.radians(70), 0, math.radians(150))
world = bpy.data.worlds.new("World")
world.use_nodes = True
nodes = world.node_tree.nodes
links = world.node_tree.links
bg = nodes["Background"]
sky = nodes.new("ShaderNodeTexSky")
sky.sky_type = "SINGLE_SCATTERING"
sky.sun_elevation = math.radians(35)
sky.sun_rotation = math.radians(200)
sky.sun_disc = False  # gokyuzunun parlak gunes diski plakalarda dev yansima yapip kararmayi bozuyordu
sat = nodes.new("ShaderNodeHueSaturation")
sat.inputs["Saturation"].default_value = 0.15
links.new(sky.outputs["Color"], sat.inputs["Color"])
links.new(sat.outputs["Color"], bg.inputs["Color"])
bg.inputs["Strength"].default_value = 0.12
scene.world = world

# Kamera: ortografik, sagdan-onden ve hafif yukaridan
bpy.ops.object.empty_add(location=(0, 0, 0))
target = bpy.context.object
bpy.ops.object.camera_add()
cam = bpy.context.object
az, el, dist = math.radians(20), math.radians(18), 300
cam.location = (dist * math.sin(az) * math.cos(el) * 0.0 + dist * math.sin(az) * math.cos(el), -dist * math.cos(az) * math.cos(el), dist * math.sin(el))
track = cam.constraints.new("TRACK_TO")
track.target = target
track.track_axis = "TRACK_NEGATIVE_Z"
track.up_axis = "UP_Y"
cam.data.type = "ORTHO"
cam.data.ortho_scale = 150
scene.camera = cam

scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1024
scene.render.resolution_y = 512
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Standard"
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("yazildi:", out)
