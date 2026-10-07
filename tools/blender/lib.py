"""Kutu (küp) tarzı pet ve fantastik yumurta modelleri için ortak kütüphane (common.py'nin üstüne).
Her model TEK PARÇA ve TEK MALZEMEDEN oluşur: renkler küçük bir PALET RESMİNDEN (8x8 hücre, her hücre düz renk) gelir, her yüzün UV'si ilgili renk hücresinin ortasına konur.
Böylece Roblox'a tek MeshPart + tek küçük doku olarak yüklenir (renk malzemesi içe aktarmada kaybolsa bile renkler doğru gelir).
Birim: 1 Blender birimi = 1 stud. Modelin önü +Y, orijin tabanın ortası.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

import common as c  # noqa: E402

GRID = 8  # palet hücre sayısı (GRID x GRID), hücre başına 8 piksel


class Model:
    """Bir modelin parçalarını toplar; bitirince tek mesh + palet dokusu üretir."""

    def __init__(self, name):
        self.name = name
        self.parts = []

    # ---- ilkel parçalar (hepsi bir renk alır)
    def _add(self, obj, rgb, bevel=0.0, bevel_segments=2, subdiv=0, name="Part"):
        obj.name = name
        obj["rgb"] = tuple(rgb)
        for poly in obj.data.polygons:
            poly.use_smooth = bevel > 0 or subdiv > 0
        if bevel > 0:
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = bevel
            mod.segments = bevel_segments
            mod.limit_method = "ANGLE"
        if subdiv > 0:
            mod = obj.modifiers.new("Subsurf", "SUBSURF")
            mod.levels = subdiv
            mod.render_levels = subdiv
        self.parts.append(obj)
        return obj

    def box(self, center, size, rgb, bevel=0.05, rot=(0, 0, 0), name="Box", segments=2):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
        obj = bpy.context.active_object
        obj.scale = size
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        return self._add(obj, rgb, bevel=bevel, bevel_segments=segments, name=name)

    def ball(self, center, radii, rgb, seg=12, rings=8, rot=(0, 0, 0), name="Ball", smooth=True):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1.0, location=center)
        obj = bpy.context.active_object
        obj.scale = radii
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        part = self._add(obj, rgb, name=name)
        for poly in obj.data.polygons:
            poly.use_smooth = smooth
        return part

    def cone(self, center, r1, r2, height, rgb, rot=(0, 0, 0), verts=8, name="Cone", bevel=0.0, scale=(1, 1, 1)):
        """Koni/piramit (uç +Z'de). rot derece: X çevresinde -90 uç +Y'ye (öne), +90 arkaya, 180 aşağı; Y çevresinde +90 uç +X'e. scale: önce yerel eksende ölçeklenir (yassı kanatlar için)."""
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=height, location=center)
        obj = bpy.context.active_object
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        return self._add(obj, rgb, bevel=bevel, name=name)

    def cyl(self, center, radius, depth, rgb, rot=(0, 0, 0), verts=12, name="Cyl", bevel=0.0):
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=center)
        obj = bpy.context.active_object
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        return self._add(obj, rgb, bevel=bevel, name=name)

    def torus(self, center, major, minor, rgb, rot=(0, 0, 0), major_seg=24, minor_seg=8, name="Ring"):
        bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_seg, minor_segments=minor_seg, location=center)
        obj = bpy.context.active_object
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        part = self._add(obj, rgb, name=name)
        for poly in obj.data.polygons:
            poly.use_smooth = True
        return part

    def star(self, center, size, rgb, thickness=0.12, rot=(0, 0, 0), points=4, name="Star"):
        """Düz yıldız (points köşeli), XZ düzleminde (yüzü +Y'ye bakar), thickness kalınlığında."""
        mesh = bpy.data.meshes.new(name)
        bm = bmesh.new()
        outer, inner = size, size * 0.42
        verts = []
        for i in range(points * 2):
            angle = math.pi / 2 + math.pi * i / points
            radius = outer if i % 2 == 0 else inner
            verts.append(bm.verts.new((math.cos(angle) * radius, 0, math.sin(angle) * radius)))
        face = bm.faces.new(verts)
        result = bmesh.ops.extrude_face_region(bm, geom=[face])
        extruded = [v for v in result["geom"] if isinstance(v, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, vec=(0, thickness, 0), verts=extruded)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        obj.location = center
        obj.rotation_euler = tuple(math.radians(a) for a in rot)
        bpy.context.view_layer.objects.active = obj
        return self._add(obj, rgb, name=name)

    def tube(self, points, radius, rgb, name="Tube", taper=True):
        obj = c.tube(name, points, radius, c.material(name, rgb), taper=taper, resolution=6)
        obj.data.materials.clear()
        for poly in obj.data.polygons:
            poly.use_smooth = True
        return self._add(obj, rgb, name=name)

    # ---- bitirme: palet dokusu, UV, tek mesh
    def finish(self, folder_textures):
        colors = []
        for obj in self.parts:
            rgb = tuple(obj["rgb"])
            if rgb not in colors:
                colors.append(rgb)
        if len(colors) > GRID * GRID:
            raise RuntimeError(f"{self.name}: palet {GRID * GRID} renge sığmıyor ({len(colors)})")
        cell = 8
        size = GRID * cell
        pixels = [0.0] * (size * size * 4)
        for index, rgb in enumerate(colors):
            col, row = index % GRID, index // GRID
            encoded = (rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0, 1.0)  # PNG'ye yazılan değerler sRGB kodlu
            for py in range(cell):
                for px in range(cell):
                    base = (((row * cell + py) * size) + (col * cell + px)) * 4
                    pixels[base : base + 4] = encoded
        image = bpy.data.images.new(self.name + "_palette", size, size, alpha=False)
        image.colorspace_settings.name = "sRGB"
        image.pixels = pixels
        os.makedirs(folder_textures, exist_ok=True)
        image.filepath_raw = os.path.join(folder_textures, self.name + "_palette.png")
        image.file_format = "PNG"
        image.save()

        mat = bpy.data.materials.new(self.name + "_Material")
        mat.use_nodes = True
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        bsdf = nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.5
        for socket_name, value in (("Specular IOR Level", 0.35), ("Coat Weight", 0.15), ("Coat Roughness", 0.2)):
            if socket_name in bsdf.inputs:
                bsdf.inputs[socket_name].default_value = value
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Closest"
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

        for obj in self.parts:
            c.apply_modifiers(obj)
            rgb = tuple(obj["rgb"])
            index = colors.index(rgb)
            col, row = index % GRID, index // GRID
            uv = ((col + 0.5) / GRID, (row + 0.5) / GRID)
            mesh = obj.data
            layer = mesh.uv_layers.get("UVMap") or mesh.uv_layers.new(name="UVMap")
            for loop in layer.data:
                loop.uv = uv
        joined = c.join(self.parts, self.name)
        bpy.context.view_layer.objects.active = joined
        joined.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # orijin = dünya orijini (tabanın ortası)
        joined.data.materials.clear()
        joined.data.materials.append(mat)
        # küçük parçalarda olası çift köşeleri birleştir
        bpy.context.view_layer.objects.active = joined
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.remove_doubles(threshold=0.0005)
        bpy.ops.object.mode_set(mode="OBJECT")
        for poly in joined.data.polygons:
            poly.use_smooth = True
        joined["palette"] = colors
        return joined


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lighter(color, t=0.5):
    return mix(color, (255, 255, 255), t)


def darker(color, t=0.4):
    return mix(color, (0, 0, 0), t)


def move_object(obj, offset):
    obj.location = (obj.location[0] + offset[0], obj.location[1] + offset[1], obj.location[2] + offset[2])
    bpy.context.view_layer.update()


def export_single(obj, path):
    c.export_fbx([obj], path)


# ---------------------------------------------------------------- model bilgisi (oyun koduyla paylaşılan ölçüler)
MANIFEST_JSON = os.path.join(c.OUT, "models.json")
MANIFEST_LUA = os.path.join(c.ROOT, "src", "shared", "ModelInfo.luau")


def record_manifest(obj):
    """Modelin Roblox eksenlerindeki ölçüsünü (stud) ve orijine göre kutu merkezini kaydeder (oyun, içe aktarma ölçeğinden bağımsız doğru boyutu bundan hesaplar).
    Blender (x, y, z) -> Roblox (x, z, -y): Blender +Y (modelin önü) Roblox'ta -Z'dir. Obje dünya orijininde ve dönüşümleri uygulanmış olmalı."""
    import json

    coords = [v.co for v in obj.data.vertices]
    mins = [min(co[i] for co in coords) for i in range(3)]
    maxs = [max(co[i] for co in coords) for i in range(3)]
    size = (maxs[0] - mins[0], maxs[2] - mins[2], maxs[1] - mins[1])
    center = ((maxs[0] + mins[0]) / 2, (maxs[2] + mins[2]) / 2, -(maxs[1] + mins[1]) / 2)
    data = {}
    if os.path.exists(MANIFEST_JSON):
        with open(MANIFEST_JSON, encoding="utf-8") as handle:
            data = json.load(handle)
    data[obj.name] = {"size": [round(v, 4) for v in size], "center": [round(v, 4) for v in center]}
    os.makedirs(os.path.dirname(MANIFEST_JSON), exist_ok=True)
    with open(MANIFEST_JSON, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=1, sort_keys=True)
    lines = [
        "-- OTOMATİK ÜRETİLİR (tools/blender/lib.py, record_manifest): Blender modellerinin Roblox eksenlerindeki ölçüsü (stud) ve MODEL ORİJİNİNE (tabanın ortası) göre kutu merkezi.",
        "-- Elle düzenleme; modeli yeniden üretince güncellenir. shared/ModelLibrary bununla modeli içe aktarma ölçeğinden bağımsız doğru boyutta ve yerde kurar.",
        "return {",
    ]
    for name in sorted(data):
        entry = data[name]
        size_text = ", ".join(str(v) for v in entry["size"])
        center_text = ", ".join(str(v) for v in entry["center"])
        lines.append("\t" + name + " = { size = Vector3.new(" + size_text + "), center = Vector3.new(" + center_text + ") },")
    lines.append("}")
    with open(MANIFEST_LUA, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    return size, center
