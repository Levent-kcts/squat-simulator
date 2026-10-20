"""Dünya 2 (Uzay) modelleri için ortak yardımcılar: önizleme ızgarası (ortografik kamera), hilal şekli ve ölçü kaydı (lib.record_manifest)."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

import common as c  # noqa: E402
from lib import record_manifest  # noqa: E402

def record(obj):
    """Ölçüyü Dünya 1 modelleriyle AYNI yere yazar (assets/blender/models.json + src/shared/ModelInfo.luau; lib.record_manifest)."""
    return record_manifest(obj)


def crescent(m, center, size, rgb, thickness=0.1, rot=(0, 0, 0), name="Moon", steps=12):
    """Düz hilal (ay), XZ düzleminde, yüzü +Y'ye bakar; açık (oyuk) tarafı +X'e bakar (rot ile döndür)."""
    R, r, d = size, size * 0.82, size * 0.5
    xi = (R * R - r * r + d * d) / (2 * d)
    zi = math.sqrt(max(0.0, R * R - xi * xi))
    a1 = math.atan2(zi, xi)
    pts = []
    for i in range(steps + 1):  # dış yay: üst kesişimden sola dolaşıp alt kesişime
        a = a1 + (2 * math.pi - 2 * a1) * i / steps
        pts.append((math.cos(a) * R, math.sin(a) * R))
    b_top = math.atan2(zi, xi - d)
    b_bot = 2 * math.pi - b_top
    for i in range(1, steps):  # iç yay: alttan üste, iç dairenin sol tarafından
        b = b_bot - (b_bot - b_top) * i / steps
        pts.append((d + math.cos(b) * r, math.sin(b) * r))
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    verts = [bm.verts.new((x, 0, z)) for x, z in pts]
    face = bm.faces.new(verts)
    result = bmesh.ops.extrude_face_region(bm, geom=[face])
    extruded = [v for v in result["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, thickness, 0), verts=extruded)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = center
    obj.rotation_euler = tuple(math.radians(a) for a in rot)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return m._add(obj, rgb, name=name)


def render_grid(models, path, cols, spacing=(4.4, 5.2), height=1.0, elevation=30, resolution=1800, background=(228, 236, 255), floor=(205, 214, 240), rotate=0.0, margin=1.25, obj_height=3.6):
    """Modelleri soldan sağa, satır satır dizip ortografik kamerayla önden-yukarıdan çeker (hepsi kareye sığar)."""
    rows = (len(models) + cols - 1) // cols
    sx, sy = spacing
    for index, obj in enumerate(models):
        col, row = index % cols, index // cols
        obj.location = (-(col - (cols - 1) / 2) * sx, row * sy, 0)  # kamera önden (+Y'den) bakar, +X solda görünür: x ters; ilk satır en uzakta = resmin üstünde
        obj.rotation_euler = (0, 0, math.radians(rotate))
    scene = bpy.context.scene
    width = cols * sx
    depth = rows * sy * math.sin(math.radians(elevation)) + obj_height * math.cos(math.radians(elevation))
    res_x = resolution[0] if isinstance(resolution, (tuple, list)) else resolution
    res_y = int(res_x * depth / width)  # resim oranı ızgaraya uyar (boş kenar kalmasın)
    scene.render.resolution_x, scene.render.resolution_y = res_x, res_y
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = c.srgb(background)
    c.add_floor(floor, size=200)
    center = Vector((0, (rows - 1) * sy / 2, height))
    c.add_lights(center=tuple(center), distance=max(16, rows * sy))
    cam_data = bpy.data.cameras.new("GridCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(width, depth) * margin  # ortho_scale büyük kenara uygulanır
    cam_data.clip_end = 500
    cam = bpy.data.objects.new("GridCam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    el = math.radians(elevation)
    cam.location = center + Vector((0, math.cos(el), math.sin(el))) * 120
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
