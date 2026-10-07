"""ÖRNEK 1: Old Sneakers (ilk ayakkabı). Yumuşak, tombul, oyuncak gibi spor ayakkabı.
Parçalar (kodla yeniden boyanır): Upper (ayakkabı rengi), Sole (beyaz taban), Trim (beyaz bağcık, burun şapkası, dil, topuk tutamağı).
Üst kısım, boyuna kesitlerden (yarım süper-elips) oluşan bir 'loft' yüzeydir; ayak girişi bir elipsoit ile boolean olarak oyulur, sonra pah ve alt bölme ile yumuşatılır.
Çalıştır: blender -b -P tools/blender/shoe_old_sneakers.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
import common as c  # noqa: E402

NAME = "shoe_oldsneakers"
UPPER_COLOR = (170, 255, 70)  # Config.Items[1].color (önizleme rengi)
WHITE = (250, 250, 252)

c.reset()
c.setup_render()

SOLE_TOP = 0.4  # tabanın üst yüzü (z)
Y_MIN, Y_MAX = -1.78, 1.78  # üst kısmın boyuna sınırları


def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def width_at(y):
    s = (y - Y_MIN) / (Y_MAX - Y_MIN)
    base = 0.58 + 0.2 * smoothstep(0.0, 0.55, s)
    heel_round = math.sqrt(max(0.0, 1 - ((0.16 - min(s, 0.16)) / 0.16) ** 2))
    toe_round = math.sqrt(max(0.0, 1 - ((max(s, 0.7) - 0.7) / 0.3) ** 2))
    return base * heel_round * toe_round


def height_at(y):
    s = (y - Y_MIN) / (Y_MAX - Y_MIN)
    base = 0.7 + 0.95 * (1 - smoothstep(0.0, 0.8, s))  # topukta/bilekte yüksek, burunda alçak
    heel_round = math.sqrt(max(0.0, 1 - ((0.1 - min(s, 0.1)) / 0.1) ** 2))
    toe_round = math.sqrt(max(0.0, 1 - ((max(s, 0.78) - 0.78) / 0.22) ** 2))
    return base * max(heel_round, 0.0) ** 0.6 * toe_round ** 0.8


def build_upper():
    rows, cols = 44, 20
    mesh = bpy.data.meshes.new("UpperMesh")
    bm = bmesh.new()
    grid = []
    for i in range(rows + 1):
        y = Y_MIN + (Y_MAX - Y_MIN) * i / rows
        w, h = width_at(y), height_at(y)
        ring = []
        for j in range(cols + 1):
            t = math.pi * j / cols
            cs, sn = math.cos(t), math.sin(t)
            x = w * math.copysign(abs(cs) ** 0.78, cs)
            z = SOLE_TOP - 0.02 + h * (sn ** 0.78)
            ring.append(bm.verts.new((x, y, z)))
        grid.append(ring)
    for i in range(rows):
        for j in range(cols):
            bm.faces.new((grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j]))
    for i in range(rows):  # alt kapak
        bm.faces.new((grid[i][0], grid[i + 1][0], grid[i + 1][cols], grid[i][cols]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Upper", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


# ---- Taban
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, SOLE_TOP / 2))
sole = bpy.context.active_object
sole.scale = (1.5, 3.9, SOLE_TOP)
bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.subdivide(number_cuts=9)
bpy.ops.object.mode_set(mode="OBJECT")
for vertex in sole.data.vertices:
    x, y, z = vertex.co
    # Plan görünümde uçları yuvarla: düz uç kenarı elips yayına çekilir (burun geniş yay, topuk daha dar yay)
    xn = max(-1.0, min(1.0, x / 0.75))
    arc = math.sqrt(max(0.0, 1 - 0.96 * xn * xn))
    if y > 0.7:
        y = 0.7 + (y - 0.7) * arc
    elif y < -1.1:
        y = -1.1 + (y + 1.1) * arc
    vertex.co.y = y
    width = 0.8 + 0.2 * smoothstep(-1.9, 0.5, y)
    nose = smoothstep(0.5, 1.95, y)
    heel = smoothstep(-1.0, -1.95, y)
    vertex.co.x = x * width * (1.0 - 0.45 * nose * nose) * (1.0 - 0.12 * heel * heel)
    vertex.co.z = z + 0.34 * nose * nose
sole_mat = c.material("Sole", WHITE, rough=0.45)
c.finish(sole, "Sole", sole_mat, bevel=0.17, bevel_segments=4)

# ---- Üst kısım + ayak girişi oyuğu
upper = build_upper()
upper_mat = c.material("Upper", UPPER_COLOR, rough=0.38, coat=0.4)
c.finish(upper, "Upper", upper_mat)
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1.0, location=(0, -0.98, SOLE_TOP + height_at(-0.98) + 0.02))
cutter = bpy.context.active_object
cutter.scale = (0.46, 0.66, 0.6)
bool_mod = upper.modifiers.new("Opening", "BOOLEAN")
bool_mod.operation = "DIFFERENCE"
bool_mod.object = cutter
bool_mod.solver = "EXACT"
c.apply_modifiers(upper)
bpy.data.objects.remove(cutter, do_unlink=True)
bevel = upper.modifiers.new("Bevel", "BEVEL")
bevel.width = 0.07
bevel.segments = 2
bevel.limit_method = "ANGLE"
sub = upper.modifiers.new("Subsurf", "SUBSURF")
sub.levels = 1
sub.render_levels = 1
c.apply_modifiers(upper)

# ---- Detaylar (Trim): burun şapkası, dil, bağcıklar, topuk tutamağı
trim_mat = c.material("Trim", WHITE, rough=0.5)
parts = []
toe_y = 1.28
parts.append(c.sphere("ToeCap", (0, toe_y, SOLE_TOP + height_at(toe_y) * 0.46), (width_at(toe_y) * 0.9, 0.44, height_at(toe_y) * 0.56), trim_mat, segments=30, rings=15))
tongue = c.rounded_box("Tongue", (0, -0.34, SOLE_TOP + height_at(-0.34) * 0.98 + 0.2), (0.6, 0.18, 0.62), trim_mat, bevel=0.08, segments=2)
tongue.rotation_euler = (math.radians(-16), 0, 0)
parts.append(tongue)
for index, y in enumerate((0.0, 0.36, 0.72)):
    z = SOLE_TOP + height_at(y) * 0.95
    lace = c.cylinder(f"Lace{index}", (0, y, z), 0.08, width_at(y) * 1.5, trim_mat, rotation=(0, math.radians(90), 0), vertices=10)
    parts.append(lace)
parts.append(c.rounded_box("HeelTab", (0, -1.66, SOLE_TOP + height_at(-1.6) * 0.82), (0.5, 0.2, 0.6), trim_mat, bevel=0.08, segments=2))
trim = c.join(parts, "Trim", trim_mat)

objects = [sole, upper, trim]

# ---- Önizleme + dışa aktarım
c.add_floor((205, 214, 240))
c.add_lights(center=(0, 0, 1.0), distance=9)
c.render_view(os.path.join(c.OUT, "previews", NAME + "_front.png"), center=(0, 0, 0.95), distance=9.5, azimuth_deg=-38, elevation_deg=20)
c.render_view(os.path.join(c.OUT, "previews", NAME + "_side.png"), center=(0, 0, 0.95), distance=9.5, azimuth_deg=-88, elevation_deg=8)
c.export_fbx(objects, os.path.join(c.OUT, "fbx", NAME + ".fbx"))
c.save_blend(os.path.join(c.OUT, "blend", NAME + ".blend"))
print("TAMAM", NAME, [(o.name, c.tri_count(o)) for o in objects], "toplam üçgen:", sum(c.tri_count(o) for o in objects))
