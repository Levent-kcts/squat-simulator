"""Yukleme ekrani icin 2x2 (4 cikintili) lego tugla resmi: seffaf arka planli 512x512 PNG (assets/loading/brick.png).
Tugla BEYAZA yakin gri cizilir; oyunda ImageLabel.ImageColor3 ile her tugla farkli renge boyanir (golge/parlak vurgu korunur), yani Roblox'a SADECE BU TEK RESIM yuklenir.
Calistir: blender -b -P tools/loading/make_brick.py -- assets/loading/brick.png
Olcu: govde 4 x 4 x 2.4, 4 silindir cikinti (cap 1.3, boy 0.5) = LoadingScreen'in eski 3B tuglasiyla ayni oran (gercek 2x2 tugla)."""
import math
import sys

import bpy

out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "brick.png"

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

mat = bpy.data.materials.new("Brick")
mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.92, 0.92, 0.92, 1)
bsdf.inputs["Roughness"].default_value = 0.42


def finish(obj, bevel_width, bevel_segments):
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = bevel_width
    bevel.segments = bevel_segments
    bevel.limit_method = "ANGLE"
    for poly in obj.data.polygons:
        poly.use_smooth = True
    normals = obj.modifiers.new("Normals", "WEIGHTED_NORMAL")
    normals.keep_sharp = True


bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
body = bpy.context.object
body.scale = (4, 4, 2.4)
bpy.ops.object.transform_apply(scale=True)
finish(body, 0.16, 4)

for sx in (-1, 1):
    for sy in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=0.5, vertices=48, location=(sx, sy, 1.2 + 0.25))
        stud = bpy.context.object
        finish(stud, 0.07, 3)

# Isik: yukari-soldan ana isik, karsi yandan yumusak dolgu; dunya isigi golgeli yuzleri ac tutar (renk boyayinca cok kararmasin)
bpy.ops.object.light_add(type="SUN", location=(-6, -8, 14))
sun = bpy.context.object
sun.data.energy = 3.4
sun.rotation_euler = (math.radians(42), math.radians(0), math.radians(-38))
bpy.ops.object.light_add(type="SUN", location=(-6, 8, 6))
fill = bpy.context.object
fill.data.energy = 0.25
fill.rotation_euler = (math.radians(70), 0, math.radians(215))
world = bpy.data.worlds.new("World")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.82, 0.9, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.42
scene.world = world

# Kamera: ortografik, onden-sagdan ve hafif yukaridan (4 cikinti ve iki yan yuz gorunur)
bpy.ops.object.empty_add(location=(0, 0, 0.2))
target = bpy.context.object
bpy.ops.object.camera_add()
cam = bpy.context.object
az, el, dist = math.radians(38), math.radians(30), 30
cam.location = (dist * math.sin(az) * math.cos(el), -dist * math.cos(az) * math.cos(el), dist * math.sin(el))
track = cam.constraints.new("TRACK_TO")
track.target = target
track.track_axis = "TRACK_NEGATIVE_Z"
track.up_axis = "UP_Y"
cam.data.type = "ORTHO"
cam.data.ortho_scale = 7.6
scene.camera = cam

scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Standard"
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
print("yazildi:", out)
