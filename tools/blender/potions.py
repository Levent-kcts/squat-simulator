"""İksir görselleri (PNG, şeffaf arka plan): sahibinin referansındaki gibi yuvarlak taş şişe, büyük camlı pencerede köpüren renkli sıvı, metal yaka, mantar ve halat.
Dört iksir: luck (yeşil, yonca rozeti), muscle (kırmızı-turuncu, dambıl rozeti), wins (altın sarısı, altın madalyon rozeti), rainbow (gökkuşağı sıvı, yıldız rozeti).
Çalıştırma:
    blender -b -P tools/blender/potions.py             (dördü)
    blender -b -P tools/blender/potions.py -- luck     (seçilen)
Çıktı: assets/icons/potion_<id>.png (512x512, şeffaf), assets/blender/previews/potions_sheet.png (4'ü yan yana; sadece bakmak için)
Studio'ya yükleme: sahibi PNG'leri Image olarak yükler, ID'ler Config.Icons.Potions'a yazılır (client/UIStyle.potionIcon görseli kullanır, boşken kodla çizilen şişe).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402
import common as c  # noqa: E402

ICONS = os.path.join(c.ROOT, "assets", "icons")

POTIONS = [
    # id, sıvı rengi, rozet
    ("luck", (70, 235, 60), "clover"),
    ("muscle", (255, 70, 50), "dumbbell"),
    ("wins", (255, 200, 40), "coin"),
    ("rainbow", None, "star"),
]


# ------------------------------------------------------------------ malzemeler
def mat(name, color, rough=0.4, metal=0.0, emit=0.0, coat=0.0, bump=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = c.srgb(color)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = c.srgb(color)
        bsdf.inputs["Emission Strength"].default_value = emit
    if bump > 0:
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 18
        bump_node = nodes.new("ShaderNodeBump")
        bump_node.inputs["Strength"].default_value = bump
        links.new(noise.outputs["Fac"], bump_node.inputs["Height"])
        links.new(bump_node.outputs["Normal"], bsdf.inputs["Normal"])
    return material


def rainbow_material():
    material = bpy.data.materials.new("RainbowLiquid")
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.15
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 1.0
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    mapping = nodes.new("ShaderNodeMapRange")
    mapping.inputs["From Min"].default_value = -0.9
    mapping.inputs["From Max"].default_value = 0.1
    ramp = nodes.new("ShaderNodeValToRGB")
    colors = [(255, 80, 90), (255, 160, 50), (255, 235, 70), (80, 220, 110), (70, 160, 255), (170, 90, 255)]
    elements = ramp.color_ramp.elements
    elements[0].position = 0.0
    elements[0].color = c.srgb(colors[5])
    elements[1].position = 1.0
    elements[1].color = c.srgb(colors[0])
    for index in range(1, 5):
        element = elements.new(index / 5)
        element.color = c.srgb(colors[5 - index])
    links.new(coord.outputs["Object"], sep.inputs["Vector"])
    links.new(sep.outputs["Z"], mapping.inputs["Value"])
    links.new(mapping.outputs["Result"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = 0.5
    return material


# ------------------------------------------------------------------ geometri yardımcıları
def sphere(name, loc, radius, material, scale=(1, 1, 1), segments=48, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius, location=loc)
    obj = bpy.context.active_object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.name = name
    obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def cylinder(name, loc, radius, depth, material, r2=None, vertices=48, bevel=0.0):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=r2, depth=depth, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(material)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 4
    return obj


def boolean(target, other, operation):
    mod = target.modifiers.new("Bool", "BOOLEAN")
    mod.object = other
    mod.operation = operation
    mod.solver = "EXACT"
    c.apply_modifiers(target)


def tube(name, points, radius, material):
    obj = c.tube(name, points, radius, material, taper=False, resolution=8)
    return obj


# ------------------------------------------------------------------ rozetler (şişenin ön sol üstünde, altın çerçeveli)
def star_object(name, outer, inner, points, depth, material):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    verts = []
    for i in range(points * 2):
        angle = math.pi / 2 + math.pi * i / points
        radius = outer if i % 2 == 0 else inner
        verts.append(bm.verts.new((math.cos(angle) * radius, math.sin(angle) * radius, -depth / 2)))
    face = bm.faces.new(verts)
    result = bmesh.ops.extrude_face_region(bm, geom=[face])
    top = [v for v in result["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, 0, depth), verts=top)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj


def badge(kind, base, normal, gold, disc_mat, symbol_mat, accent_mat):
    """Kürenin yüzeyine yaslanan yuvarlak rozet: beyaz disk + altın halka + sembol. Parçalar yerel eksende (z = dışa) kurulur, bir Empty'ye bağlanıp normale çevrilir."""
    normal = Vector(normal).normalized()
    holder = bpy.data.objects.new("Badge", None)
    bpy.context.collection.objects.link(holder)
    holder.location = base
    holder.rotation_euler = Vector((0, 0, 1)).rotation_difference(normal).to_euler()
    holder.scale = (1.3, 1.3, 1.3) # küçük simgede de okunsun

    def attach(obj, loc, rot=(0, 0, 0)):
        obj.parent = holder
        obj.location = loc
        obj.rotation_euler = rot
        return obj

    attach(cylinder("BadgeDisc", (0, 0, 0), 0.24, 0.06, disc_mat), (0, 0, 0))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.24, minor_radius=0.04, major_segments=40, minor_segments=10)
    rim = bpy.context.active_object
    rim.data.materials.append(gold)
    attach(rim, (0, 0, 0.025))
    lift = 0.06
    if kind == "clover":
        for dx, dy in ((0.075, 0), (-0.075, 0), (0, 0.075), (0, -0.075)):
            attach(sphere("Leaf", (0, 0, 0), 0.085, symbol_mat, scale=(1, 1, 0.4), segments=20, rings=12), (dx, dy + 0.02, lift))
        stem = cylinder("Stem", (0, 0, 0), 0.02, 0.17, symbol_mat, vertices=12)
        attach(stem, (0.05, -0.12, lift), (0, math.radians(90), math.radians(-30)))
    elif kind == "dumbbell":
        attach(cylinder("Bar", (0, 0, 0), 0.028, 0.36, symbol_mat, vertices=16), (0, 0, lift), (0, math.radians(90), 0))
        for side in (-1, 1):
            attach(cylinder("PlateBig", (0, 0, 0), 0.1, 0.07, symbol_mat, vertices=24), (side * 0.12, 0, lift), (0, math.radians(90), 0))
            attach(cylinder("PlateSmall", (0, 0, 0), 0.075, 0.07, symbol_mat, vertices=24), (side * 0.19, 0, lift), (0, math.radians(90), 0))
    elif kind == "coin":
        attach(cylinder("Coin", (0, 0, 0), 0.17, 0.05, symbol_mat, vertices=40, bevel=0.012), (0, 0, lift))
        attach(star_object("CoinStar", 0.11, 0.05, 5, 0.04, accent_mat), (0, 0, lift + 0.03))
    elif kind == "star":
        attach(star_object("Star", 0.19, 0.085, 5, 0.06, symbol_mat), (0, 0, lift + 0.01))
    return holder


# ------------------------------------------------------------------ şişe
def build(spec):
    potion_id, liquid_color, badge_kind = spec
    shell_mat = mat("Shell", (178, 184, 198), rough=0.5, bump=0.05)
    metal_mat = mat("Metal", (205, 210, 220), rough=0.28, metal=1.0)
    cork_mat = mat("Cork", (176, 118, 66), rough=0.85, bump=0.35)
    rope_mat = mat("Rope", (150, 98, 58), rough=0.9, bump=0.3)
    gold_mat = mat("Gold", (255, 205, 70), rough=0.25, metal=1.0)
    if liquid_color is None:
        liquid_mat = rainbow_material()
    else:
        liquid_mat = mat("Liquid", liquid_color, rough=0.12, emit=0.55, coat=1.0)
    bubble_mat = mat("Bubble", tuple(min(255, int(v * 0.55 + 120)) for v in (liquid_color or (230, 200, 255))), rough=0.1, emit=0.35, coat=1.0)

    # gövde: oyuk taş küre + ön pencere
    shell = sphere("Shell", (0, 0, 0), 1.0, shell_mat, segments=64, rings=32)
    solid = shell.modifiers.new("Solidify", "SOLIDIFY")
    solid.thickness = 0.13
    solid.offset = -1
    c.apply_modifiers(shell)
    cutter = sphere("Cutter", (0, 1.25, -0.1), 0.9, shell_mat, segments=48, rings=24)
    boolean(shell, cutter, "DIFFERENCE")
    bpy.data.objects.remove(cutter)
    # pencerenin dış kenarına kabarık bir dudak (halka): kesik kenar temiz ve kalın görünür
    axis = Vector((0, 1.25, -0.1)).normalized()
    bpy.ops.mesh.primitive_torus_add(major_radius=0.7115, minor_radius=0.04, major_segments=64, minor_segments=12, location=axis * 0.7027)
    lip = bpy.context.active_object
    lip.rotation_euler = Vector((0, 0, 1)).rotation_difference(axis).to_euler()
    lip.data.materials.append(shell_mat)
    for poly in lip.data.polygons:
        poly.use_smooth = True

    # sıvı: kürenin alt kısmı, üstü düz
    liquid = sphere("Liquid", (0, 0, 0), 0.84, liquid_mat, segments=48, rings=24)
    cap = cylinder("Cap", (0, 0, -1.0), 2.0, 2.0, liquid_mat, vertices=32)  # z <= 0 bölgesini keser (üst yüzey z = 0.0)
    cap.location.z = -1.0 + 0.04
    boolean(liquid, cap, "INTERSECT")
    bpy.data.objects.remove(cap)
    # sıvı yüzeyinde dalga halkaları ve kabarcıklar
    top = 0.04
    bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.03, major_segments=40, minor_segments=8, location=(0.02, 0.1, top + 0.01))
    ring1 = bpy.context.active_object
    ring1.data.materials.append(bubble_mat)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.2, minor_radius=0.025, major_segments=32, minor_segments=8, location=(0.0, 0.1, top + 0.02))
    ring2 = bpy.context.active_object
    ring2.data.materials.append(bubble_mat)
    bubbles = []
    for x, y, r in ((-0.45, 0.35, 0.09), (0.15, 0.5, 0.06), (0.5, 0.2, 0.1), (-0.15, -0.1, 0.07), (0.3, -0.25, 0.07), (-0.5, -0.05, 0.05), (0.05, 0.28, 0.045), (0.62, 0.45, 0.05)):
        bubbles.append(sphere("Bubble", (x, y, top + r * 0.55), r, bubble_mat, segments=20, rings=12))

    # boyun grubu (eğik): taş boyun, metal yaka, mantar, halat sargısı
    root = bpy.data.objects.new("NeckRoot", None)
    bpy.context.collection.objects.link(root)
    neck = cylinder("Neck", (0, 0, 1.12), 0.34, 0.5, shell_mat, vertices=48, bevel=0.02)
    collar = cylinder("Collar", (0, 0, 1.4), 0.43, 0.2, metal_mat, vertices=48, bevel=0.04)
    collar_top = cylinder("CollarTop", (0, 0, 1.52), 0.37, 0.07, metal_mat, vertices=48, bevel=0.02)
    cork = cylinder("Cork", (0, 0, 1.78), 0.31, 0.5, cork_mat, r2=0.36, vertices=40, bevel=0.03)
    wrap_points = []
    turns, steps = 3, 60
    for i in range(steps + 1):
        angle = i / steps * turns * 2 * math.pi
        wrap_points.append((0.37 * math.cos(angle), 0.37 * math.sin(angle), 0.9 + 0.17 * i / steps))
    wrap = tube("RopeWrap", wrap_points, 0.045, rope_mat)
    for obj in (neck, collar, collar_top, cork, wrap):
        obj.parent = root
    root.rotation_euler = (0, math.radians(-24), 0)

    # sarkan halat: sağ yüzeyde aşağı iner, ucunda metal kapak
    rope_points = []
    for i in range(14):
        phi = math.radians(26 + i * 6.5)
        p = Vector((-math.sin(phi) * 0.95, 0.38, math.cos(phi))).normalized() * 1.05
        rope_points.append((p.x, p.y, p.z))
    rope = tube("RopeHang", rope_points, 0.06, rope_mat)
    end = Vector(rope_points[-1])
    tip = cylinder("RopeTip", end + Vector((-0.02, 0.01, -0.05)), 0.08, 0.13, metal_mat, vertices=24, bevel=0.015)
    tip.rotation_euler = (0, math.radians(30), 0)

    # rozet: şişenin üst sol ön tarafında (pencerenin üstünde, boyunun solunda)
    n = Vector((0.36, 0.5, 0.8)).normalized()
    base = n * 1.0
    disc_mat = mat("BadgeDisc", (250, 250, 255), rough=0.4)
    accent_mat = mat("Accent", (255, 245, 170), rough=0.25, metal=1.0)
    symbol_color = {"clover": (35, 150, 60), "dumbbell": (60, 62, 75), "coin": (255, 205, 60), "star": (255, 190, 40)}[badge_kind]
    symbol_mat = mat("Symbol", symbol_color, rough=0.3, metal=1.0 if badge_kind in ("coin", "star") else 0.0)
    badge(badge_kind, base, n, gold_mat, disc_mat, symbol_mat, accent_mat)
    return potion_id


def render_one(spec, out_path):
    c.reset()
    c.setup_render(resolution=512, samples=90)
    scene = bpy.context.scene
    scene.render.film_transparent = True
    build(spec)
    center = (0.15, 0.0, 0.35)
    c.add_lights(center=center, distance=7)
    c.render_view(out_path, center=center, distance=7.2, azimuth_deg=-16, elevation_deg=16, lens=75)


def main():
    wanted = c.argv_after_dashes()
    os.makedirs(ICONS, exist_ok=True)
    for spec in POTIONS:
        if wanted and spec[0] not in wanted:
            continue
        out = os.path.join(ICONS, f"potion_{spec[0]}.png")
        render_one(spec, out)
        print("POTION", spec[0], out)


if __name__ == "__main__":
    main()
