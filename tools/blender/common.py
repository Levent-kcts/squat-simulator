"""Ortak Blender yardımcıları (Squat Simulator modelleri). Blender'ın kendi Python'unda çalışır:
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/<betik>.py
Birimler: 1 Blender birimi = 1 stud (Roblox'ta içe aktarırken ölçek 1 kalsın). Eksenler: modelin ÖNÜ Blender'ın +Y yönüdür; FBX dışa aktarımında
(-Z ileri, Y yukarı) Roblox'un 'ileri' (-Z) yönüne denk gelir. Model orijini: tabanın ortası (ayak/zemin z = 0).
Renk rolü: parça adları (Upper, Sole, Fur, Eyes...) kodla yeniden boyanabilsin diye sabittir; Blender'daki renkler sadece önizleme içindir.
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "blender")


def srgb(c):
    """0-255 sRGB renk -> Blender'ın doğrusal RGBA'sı."""
    def lin(v):
        v = v / 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (lin(c[0]), lin(c[1]), lin(c[2]), 1.0)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    return scene


_mats = {}


def material(name, color, rough=0.35, spec=0.5, emit=0.0, coat=0.0):
    """Oyuncak plastiği gibi parlak malzeme. color: (r, g, b) 0-255."""
    key = (name, tuple(color), rough, coat)
    if key in _mats:
        return _mats[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb(color)
    bsdf.inputs["Roughness"].default_value = rough
    for socket_name, value in (("Specular IOR Level", spec), ("Coat Weight", coat), ("Coat Roughness", 0.15)):
        if socket_name in bsdf.inputs:
            bsdf.inputs[socket_name].default_value = value
    if emit > 0 and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = srgb(color)
        bsdf.inputs["Emission Strength"].default_value = emit
    mat.diffuse_color = srgb(color)
    _mats[key] = mat
    return mat


def finish(obj, name, mat, bevel=0.0, bevel_segments=3, subdiv=0, smooth=True):
    """Nesneyi adlandırır, malzemeyi atar, isteğe bağlı pah + alt bölme ekler (hepsi dışa aktarırken uygulanır)."""
    obj.name = name
    obj.data.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = bevel_segments
        mod.limit_method = "ANGLE"
    if subdiv > 0:
        mod = obj.modifiers.new("Subsurf", "SUBSURF")
        mod.levels = subdiv
        mod.render_levels = subdiv
    return obj


def apply_modifiers(obj):
    bpy.context.view_layer.objects.active = obj
    for obj_ in bpy.context.selected_objects:
        obj_.select_set(False)
    obj.select_set(True)
    for mod in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=mod.name)
        except RuntimeError:
            obj.modifiers.remove(mod)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def sphere(name, loc, scale, mat, segments=32, rings=16, **kw):
    """Ölçeklenmiş küre (elipsoid). scale: yarıçaplar (x, y, z)."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=loc)
    obj = bpy.context.active_object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, **kw)


def rounded_box(name, loc, size, mat, bevel=0.1, segments=4, **kw):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, bevel=bevel, bevel_segments=segments, **kw)


def cylinder(name, loc, radius, depth, mat, rotation=(0, 0, 0), vertices=24, **kw):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.active_object
    return finish(obj, name, mat, **kw)


def cone(name, loc, radius1, radius2, depth, mat, rotation=(0, 0, 0), vertices=24, **kw):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.active_object
    return finish(obj, name, mat, **kw)


def join(objs, name, mat=None):
    """Nesneleri tek bir nesnede birleştirir (modifierlar uygulanır); isim ve malzeme verilir."""
    for obj in objs:
        apply_modifiers(obj)
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    if mat is not None:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def tube(name, points, radius, mat, taper=True, resolution=12, **kw):
    """Noktalardan geçen yumuşak boru (kuyruk, bıyık...). points: [(x, y, z), ...]."""
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = resolution
    curve.bevel_depth = radius
    curve.bevel_resolution = 4
    curve.use_fill_caps = True
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, co in zip(spline.bezier_points, points):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    if taper:
        for index, point in enumerate(spline.bezier_points):
            point.radius = 1.0 - 0.45 * index / max(1, len(points) - 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.active_object
    return finish(obj, name, mat, **kw)


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# ---------------------------------------------------------------- sahne, ışık, önizleme
def setup_render(resolution=900, samples=48, background=(228, 236, 255)):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    cycles = scene.cycles
    cycles.samples = samples
    cycles.use_denoising = True
    cycles.device = "CPU"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        if any(d.type == "OPTIX" for d in prefs.devices):
            for device in prefs.devices:
                device.use = device.type == "OPTIX"
            cycles.device = "GPU"
    except Exception:
        pass
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb(background)
    bg.inputs["Strength"].default_value = 0.7
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    return scene


def add_lights(center=(0, 0, 1), distance=9):
    cx, cy, cz = center
    for name, loc, energy, size in (
        ("Key", (cx + distance * 0.8, cy - distance * 0.7, cz + distance * 0.9), 260, 5),
        ("Fill", (cx - distance * 0.9, cy - distance * 0.4, cz + distance * 0.4), 110, 6),
        ("Rim", (cx - distance * 0.2, cy + distance, cz + distance * 0.6), 150, 4),
    ):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.size = size
        obj = bpy.data.objects.new(name, data)
        obj.location = loc
        bpy.context.collection.objects.link(obj)
        direction = Vector(center) - Vector(loc)
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def add_floor(color=(236, 242, 255), size=40):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, -0.001))
    obj = bpy.context.active_object
    obj.name = "PreviewFloor"
    obj.data.materials.append(material("Floor", color, rough=0.9, spec=0.1))
    return obj


def render_view(path, center, distance, azimuth_deg=-35, elevation_deg=22, lens=60):
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = lens
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    az, el = math.radians(azimuth_deg), math.radians(elevation_deg)
    cx, cy, cz = center
    # azimuth 0 = tam önden (modelin +Y tarafından) bakış; eksi değerler kamerayı -X tarafına kaydırır
    cam.location = (cx + distance * math.sin(az) * math.cos(el), cy + distance * math.cos(az) * math.cos(el), cz + distance * math.sin(el))
    direction = Vector(center) - Vector(cam.location)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)


def export_fbx(objs, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for obj in bpy.context.selected_objects:
        obj.select_set(False)
    for obj in objs:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_scale_options="FBX_SCALE_ALL",
        global_scale=1.0,
        axis_forward="-Z",
        axis_up="Y",
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="COPY",
        embed_textures=True,  # palet dokusu FBX'in içine gömülür (Roblox içe aktarırken tek dosya yeter)
    )


def save_blend(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path)


def tri_count(obj):
    """Dışa aktarılacak (modifierlar uygulanmış) üçgen sayısı."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh = obj.evaluated_get(depsgraph).to_mesh()
    count = sum(len(poly.vertices) - 2 for poly in mesh.polygons)
    obj.evaluated_get(depsgraph).to_mesh_clear()
    return count


def argv_after_dashes():
    return sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
