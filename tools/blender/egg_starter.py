"""ÖRNEK 2: Starter Egg (ilk yumurta). Parlak oyuncak plastiği gibi yumurta kabuğu + üstünde yuvarlak benekler.
Parçalar (kodla yeniden boyanır): Shell (yumurta rengi), Spots (aksan rengi: Config.Eggs[].accent).
Boyut: yaklaşık 4.8 stud geniş x 6.2 stud yüksek (şimdiki kod yumurtasıyla aynı); orijin tabanın ortası, ön +Y.
Çalıştır: blender -b -P tools/blender/egg_starter.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
import common as c  # noqa: E402
from mathutils import Vector  # noqa: E402

NAME = "egg_starter"
SHELL_COLOR = (90, 190, 255)  # Config.Eggs[1].color
SPOT_COLOR = (255, 220, 60)  # Config.Eggs[1].accent
RADIUS_X = 2.4
HEIGHT = 6.2

c.reset()
c.setup_render()


def egg_point(theta, phi):
    """Yumurta yüzeyindeki nokta: theta enlem (0 = alt, pi = üst), phi boylam (0 = ön +Y yönü). Üst taraf daralır."""
    z = -math.cos(theta)  # -1 alt, +1 üst
    ring = math.sin(theta) * RADIUS_X * (1.0 - 0.17 * z)
    x = ring * math.sin(phi)
    y = ring * math.cos(phi)
    return Vector((x, y, HEIGHT / 2 + z * HEIGHT / 2))


# ---- Kabuk
mesh = bpy.data.meshes.new("ShellMesh")
bm = bmesh.new()
rings, segs = 28, 48
grid = []
for i in range(rings + 1):
    theta = math.pi * i / rings
    ring = []
    for j in range(segs):
        ring.append(bm.verts.new(egg_point(theta, 2 * math.pi * j / segs)))
    grid.append(ring)
for i in range(rings):
    for j in range(segs):
        a, b = grid[i][j], grid[i][(j + 1) % segs]
        d, e = grid[i + 1][j], grid[i + 1][(j + 1) % segs]
        bm.faces.new((a, b, e, d))
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh)
bm.free()
shell = bpy.data.objects.new("Shell", mesh)
bpy.context.collection.objects.link(shell)
c.finish(shell, "Shell", c.material("Shell", SHELL_COLOR, rough=0.22, coat=0.6), subdiv=0)

# ---- Benekler: yüzeye hafif gömülü, yüzeye paralel yassı elipsoitler (ön yarıda dağınık)
spot_mat = c.material("Spots", SPOT_COLOR, rough=0.3, coat=0.4)
layout = [
    # (boylam derece, enlem derece, yarıçap)
    (-8, 78, 0.72), (38, 100, 0.52), (-48, 108, 0.46), (-20, 124, 0.40),
    (16, 54, 0.42), (-62, 66, 0.36), (58, 70, 0.34), (4, 146, 0.30),
    (-100, 92, 0.30), (92, 96, 0.30), (30, 128, 0.26), (-34, 46, 0.26),
]
spots = []
for index, (phi_deg, theta_deg, radius) in enumerate(layout):
    phi, theta = math.radians(phi_deg), math.radians(theta_deg)
    position = egg_point(theta, phi)
    # yüzey normali: sonlu farklarla
    du = (egg_point(theta + 0.01, phi) - egg_point(theta - 0.01, phi))
    dv = (egg_point(theta, phi + 0.01) - egg_point(theta, phi - 0.01))
    normal = dv.cross(du).normalized()
    if normal.dot(position - Vector((0, 0, HEIGHT / 2))) < 0:
        normal = -normal
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=7, radius=1.0, location=position - normal * 0.02)
    spot = bpy.context.active_object
    spot.scale = (radius, radius, 0.13)
    spot.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    spots.append(spot)
spots_obj = c.join(spots, "Spots", spot_mat)

objects = [shell, spots_obj]

# ---- Önizleme + dışa aktarım
c.add_floor((205, 214, 240))
c.add_lights(center=(0, 0, 3.0), distance=14)
c.render_view(os.path.join(c.OUT, "previews", NAME + "_front.png"), center=(0, 0, 3.0), distance=15, azimuth_deg=-25, elevation_deg=14)
c.export_fbx(objects, os.path.join(c.OUT, "fbx", NAME + ".fbx"))
c.save_blend(os.path.join(c.OUT, "blend", NAME + ".blend"))
print("TAMAM", NAME, [(o.name, c.tri_count(o)) for o in objects], "toplam üçgen:", sum(c.tri_count(o) for o in objects))
