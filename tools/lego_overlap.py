"""Lobi sag arka kosesindeki lego kuleleri/parcalari ile gunluk cark kaidesinin PLAN UZERINDE kesisip kesismedigini denetler
(sahibi 'kesismesin' dedi). Konumlar src/server/EnvironmentService.luau'daki tower()/brick() cagrilariyla AYNI tutulmalidir;
cark konumu Config.Lobby.WheelX/Z ile. Calistir: python tools/lego_overlap.py  (en az 1.5 stud bosluk beklenir)."""
import math

# --- parça tanımları: (ad, cx, cz, yaw, sx, sz) ; yaw: CFrame.Angles(0,yaw,0): yerel X -> (cos, -sin)
def obb(name, cx, cz, yaw, sx, sz):
    return (name, cx, cz, yaw, sx / 2, sz / 2)

def corners(o):
    _, cx, cz, yaw, hx, hz = o
    ux, uz = math.cos(yaw), -math.sin(yaw)
    vx, vz = math.sin(yaw), math.cos(yaw)
    return [(cx + a * hx * ux + b * hz * vx, cz + a * hx * uz + b * hz * vz) for a in (-1, 1) for b in (-1, 1)]

def axes(o):
    yaw = o[3]
    return [(math.cos(yaw), -math.sin(yaw)), (math.sin(yaw), math.cos(yaw))]

def gap(a, b):
    """negatif = kesişir (en az nüfuz), pozitif = en küçük ayrım (SAT ekseni boyunca)"""
    best = -1e9
    for ax in axes(a) + axes(b):
        pa = [p[0] * ax[0] + p[1] * ax[1] for p in corners(a)]
        pb = [p[0] * ax[0] + p[1] * ax[1] for p in corners(b)]
        g = max(min(pa) - max(pb), min(pb) - max(pa))
        best = max(best, g)
    return best

def tower(name, cx, cz, layers, wobble):
    out = []
    for layer in range(1, layers + 1):
        yaw = math.pi / 2 if layer % 2 == 0 else 0
        out.append(obb(f"{name}#{layer}", cx + wobble * (layer % 2), cz, yaw, 8, 4))
    return out

def brick(name, cx, cz, yaw):
    return [obb(name, cx, cz, yaw, 4, 4)]

def wheel(wx, wz, fx=0, fz=0):
    ring = 4.6 * 1.45
    pillar_x = ring + 1.6
    width = 2 * (pillar_x + 1.8)
    yaw = math.atan2(-(fx - wx), -(fz - wz))
    ux, uz = math.cos(yaw), -math.sin(yaw)
    vx, vz = math.sin(yaw), math.cos(yaw)
    # kaide: yerel z -2.6..3.0 (merkez 0.2, derinlik 5.6)
    cx = wx + 0.2 * vx
    cz = wz + 0.2 * vz
    return [obb("WHEEL", cx, cz, yaw, width, 5.6)]

def build(wx, wz, towers, bricks):
    items = []
    for t in towers:
        items += tower(*t)
    for b in bricks:
        items += brick(*b)
    return items


WIDTH_RIGHT = 96
W = WIDTH_RIGHT
WHEEL = (46, 45)
OLD_T = [("oT1", W - 13, 56, 5, 0.5), ("oT2", W - 24, 60, 3, -0.4), ("oT3", W - 9, 44, 2, 0.3)]
OLD_B = [("oB1", W - 20, 47, 0.5), ("oB2", W - 29, 52, -0.3), ("oB3", W - 6, 37, 0.2)]
NEW_T = [("nT1", 62, 59, 4, -0.3), ("nT2", 51.5, 60, 3, 0.4), ("nT3", 42.5, 60, 2, -0.2), ("nT4", 66, 41, 2, 0.2)]
NEW_B = [("nB1", 61, 48, 0.3), ("nB2", 59, 37, -0.25), ("nB3", 53.5, 50, 0.4)]

if __name__ == "__main__":
    items = build(0, 0, OLD_T + NEW_T, OLD_B + NEW_B) + wheel(*WHEEL)
    worst = 1e9
    bad = 0
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            a, b = items[i], items[j]
            if a[0].split("#")[0] == b[0].split("#")[0]:
                continue
            g = gap(a, b)
            worst = min(worst, g)
            if g < 0:
                bad += 1
                print("KESISIR", round(g, 2), a[0], b[0])
    for t in OLD_T + NEW_T:
        for it in tower(*t[:1], *t[1:3], t[3], t[4]):
            for (x, z) in corners(it):
                if z > 64.5:
                    print("ARKA DUVARA GIRER", t[0])
                    bad += 1
                    break
    print("kesisen cift:", bad, "| en kucuk bosluk:", round(worst, 2), "stud (eski parcalar arasi 0.64 normal)")
