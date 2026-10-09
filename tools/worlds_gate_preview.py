"""Worlds geçidinin ve yumurta standının (3 kat + teras) ÖN GÖRÜNÜŞ ve YAN KESİT önizlemesi (SVG; Chrome ile PNG'ye çevrilebilir).
src/server/WorldsGate.luau ve EggShop/Shelf ölçülerinin aynısını çizer; Luau kodunu çalıştırmaz, bu yüzden WorldsGate.luau'daki
sayılar (taş sayısı, kalınlık) değişirse burayı da güncelle. Kullanım:
    python tools/worlds_gate_preview.py out.svg
"""
import math
import sys

# Config.Worlds
ARCH_WIDTH, ARCH_STRAIGHT, FRAME, TERRACE_H, TERRACE_D = 12, 8, 2.2, 6.4, 14
ARC_STONES, GLOW_SLABS = 15, 16
# EggShop LAYOUT
LANES = [11, 11, TERRACE_D]
TIERS = [0.4, 3.4, TERRACE_H]
SHELF_LENGTH = 12.5 * 3 + 6
RAMP_W = 5
CEILING = 36

R = ARCH_WIDTH / 2
SCALE = 14


def poly(points, fill, stroke="#33406a", sw=0.5):
    pts = " ".join(f"{x * SCALE:.1f},{y * SCALE:.1f}" for x, y in points)
    return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'


def rect(cx, cy, w, h, fill, rot=0.0, stroke="#33406a"):
    corners = []
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        x, y = sx * w / 2, sy * h / 2
        corners.append((cx + x * math.cos(rot) - y * math.sin(rot), cy + x * math.sin(rot) + y * math.cos(rot)))
    return poly(corners, fill, stroke)


def front_view():
    """Y yukarı: svg'de y ters çevrilir. Orijin: duvar ortası, zemin."""
    out = []
    flip = lambda x, y: (x, CEILING - y)
    shapes = []
    # duvar
    shapes.append(poly([flip(-24, 0), flip(24, 0), flip(24, CEILING), flip(-24, CEILING)], "#9aa6d8", "#7482b8"))
    # teras ve katlar (önden: tüm şeritler tam genişlikte)
    for i, h in enumerate(TIERS):
        shapes.append(poly([flip(-SHELF_LENGTH / 2, 0), flip(SHELF_LENGTH / 2, 0), flip(SHELF_LENGTH / 2, h), flip(-SHELF_LENGTH / 2, h)], "#8c96cd" if i < 2 else "#7f8ac4"))
    base = 0.2 + TERRACE_H
    # parlayan yüz
    glow = [flip(-R, base), flip(R, base)]
    pts = [flip(-R, base), flip(R, base), flip(R, base + ARCH_STRAIGHT)]
    for k in range(0, 33):
        a = k * math.pi / 32
        pts.append(flip(R * math.cos(a), base + ARCH_STRAIGHT + R * math.sin(a)))
    pts.append(flip(-R, base + ARCH_STRAIGHT))
    shapes.append(poly(pts, "#d7e8ff", "#d7e8ff"))
    # yan sütunlar
    courses = max(2, int(ARCH_STRAIGHT / 2 + 0.5))
    ch = ARCH_STRAIGHT / courses
    for side in (-1, 1):
        for c in range(1, courses + 1):
            x, y = flip(side * (R + FRAME / 2), base + (c - 0.5) * ch)
            shapes.append(rect(x, y, FRAME, ch, "#eef2fc" if c % 2 else "#d4dbee"))
    # kemer taşları
    L = math.pi * (R + FRAME) / ARC_STONES * 1.08
    for i in range(1, ARC_STONES + 1):
        a = (i - 0.5) * math.pi / ARC_STONES
        ring = R + FRAME / 2
        x, y = flip(ring * math.cos(a), base + ARCH_STRAIGHT + ring * math.sin(a))
        shapes.append(rect(x, y, L, FRAME, "#eef2fc" if i % 2 else "#d4dbee", rot=-(a - math.pi / 2)))
    x, y = flip(0, base + ARCH_STRAIGHT + R + FRAME * 0.6)
    shapes.append(rect(x, y, FRAME * 0.9, FRAME * 1.2, "#eef2fc"))
    # yazılar
    top = base + ARCH_STRAIGHT + R + FRAME
    tx, ty = flip(0, top + 3.6)
    shapes.append(f'<text x="{tx * SCALE}" y="{ty * SCALE + 14}" font-size="44" font-family="Arial Black" font-weight="900" fill="#00cdff" stroke="#141932" stroke-width="3" text-anchor="middle" paint-order="stroke">WORLDS</text>')
    sx, sy = flip(0, base + ARCH_STRAIGHT + 1.2)
    shapes.append(f'<text x="{sx * SCALE}" y="{sy * SCALE + 10}" font-size="26" font-family="Arial Black" fill="#ffbe28" stroke="#462300" stroke-width="3" text-anchor="middle" paint-order="stroke">COMING SOON</text>')
    # PET EGGS tabelaları
    for sx_ in (-15, 15):
        px, py_ = flip(sx_, 19)
        shapes.append(rect(px, py_, 12, 4.5, "#ff6ebe"))
        shapes.append(f'<text x="{px * SCALE}" y="{py_ * SCALE + 8}" font-size="24" font-family="Arial Black" fill="#fff" stroke="#281900" stroke-width="2" text-anchor="middle" paint-order="stroke">PET EGGS</text>')
    # yumurtalar (2. kat x = -12.5, 0, 12.5, 1. kat aynı: önden üst üste)
    for x_ in (-12.5, 0, 12.5):
        ex, ey = flip(x_, 3.4 + 1 + 3.3 + 2.8)
        shapes.append(f'<ellipse cx="{ex * SCALE}" cy="{ey * SCALE}" rx="{2.4 * SCALE}" ry="{3.1 * SCALE}" fill="#5bbf7a" stroke="#1f6b3a" stroke-width="1.5"/>')
    return shapes, 48 * SCALE, CEILING * SCALE


def side_view():
    """Yan kesit: yatay = duvardan uzaklık (sol duvar, sağ salon), düşey = yükseklik."""
    shapes = []
    total = sum(LANES)
    flip = lambda z, y: (total - z, CEILING - y)  # sol: salon (z=total), sağ: duvar (z=0)... duvar sağda
    # zemin
    shapes.append(poly([flip(total + 4, 0), flip(-1, 0), flip(-1, -1), flip(total + 4, -1)], "#7c86bd"))
    # duvar
    shapes.append(poly([flip(0, 0), flip(-1, 0), flip(-1, CEILING), flip(0, CEILING)], "#9aa6d8"))
    behind = 0
    for i in range(len(LANES) - 1, -1, -1):
        d, h = LANES[i], TIERS[i]
        z0, z1 = behind, behind + d
        shapes.append(poly([flip(z0, 0), flip(z1, 0), flip(z1, h), flip(z0, h)], "#8c96cd"))
        shapes.append(poly([flip(z1, h), flip(z1 - 1, h), flip(z1 - 1, h + 1), flip(z1, h + 1)], "#b2bae4"))  # ön kenar çıkıntısı
        behind = z1
    # eşya yükseklikleri
    base = 0.2 + TERRACE_H
    shapes.append(rect(*flip(0.8, base + ARCH_STRAIGHT / 2), 1.6, ARCH_STRAIGHT, "#d7e8ff"))
    # oyuncu (5 stud) teras önünde
    shapes.append(rect(*flip(6, base + 2.6), 1.4, 5.2, "#ff9a3c"))
    return shapes, (total + 8) * SCALE, CEILING * SCALE


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "worlds_gate_preview.svg"
    f, fw, fh = front_view()
    s, sw, sh = side_view()
    gap = 30
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{fw + sw + gap}" height="{fh}" viewBox="0 0 {fw + sw + gap} {fh}">', f'<rect width="100%" height="100%" fill="#e9edf8"/>']
    svg.append(f'<g transform="translate({fw / 2},0)">' + "".join(f) + "</g>")
    svg.append(f'<g transform="translate({fw + gap},0)">' + "".join(s) + "</g>")
    svg.append("</svg>")
    with open(out, "w", encoding="utf-8") as handle:
        handle.write("\n".join(svg))
    print("yazıldı:", out)


if __name__ == "__main__":
    main()
