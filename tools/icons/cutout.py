"""Yapay zekâdan gelen simge görsellerini (beyaz arka planlı JPG, assets/icons/new/) oyuna hazır şeffaf PNG'ye çevirir.
Blender'ın Python'unda çalışır (numpy hazır):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/icons/cutout.py            (hepsi)
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/icons/cutout.py -- trophy  (seçilen)
Adımlar: 2048 -> 1024 küçült, kenardan başlayan taşırma ile beyaz arka planı bul (delik: kulp içi gibi kapalı beyazlar 'holes' işaretliyse onlar da gider),
kenarı 1 piksel daralt + yumuşat, nesnenin sınırlarına kırp, kareye tamamla (%6 boşluk), 512x512'ye küçült (önceden çarpılmış alfa: beyaz kenar halesi olmaz).
Çıktı: assets/icons/<ad>.png. Önizleme: python tools/icons/sheet.py
"""
import os
import sys
from collections import deque

import bpy
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets", "icons", "new")
OUT = os.path.join(ROOT, "assets", "icons")

# çıktı adı: (kaynak dosya, delik ayarı, ortak ölçek grubu)
# delik ayarı: None = kapalı beyaz bölgeleri koru (rozet, inci, parlama gibi nesne parçaları), {'min': alan, 'top': oran} = kulp içi gibi kapalı BOŞLUKLARI sil
# (min: en az bu piksel alanı, 'top': verilirse yalnızca nesnenin üst %oran bölümündeki delikler; parlamalar küçük kaldığı için min ile elenir)
JOBS = {
    "shop_vip": ("Gemini_Generated_Image_15n63x15n63x15n6 (1).jpg", False, None),
    "shop_petspace": ("Gemini_Generated_Image_15n63x15n63x15n6 (2).jpg", {"min": 600, "top": 0.2}, None),
    "shop_winpack": ("Gemini_Generated_Image_15n63x15n63x15n6 (3).jpg", {"min": 450, "top": 0.2}, None),
    "shop_winpack_big": ("Gemini_Generated_Image_15n63x15n63x15n6 (4).jpg", False, None),
    "potion_luck": ("Gemini_Generated_Image_15n63x15n63x15n6 (5).jpg", False, "potions"),
    "potion_muscle": ("Gemini_Generated_Image_15n63x15n63x15n6 (6).jpg", False, "potions"),
    "potion_wins": ("Gemini_Generated_Image_15n63x15n63x15n6 (7).jpg", False, "potions"),
    "potion_rainbow": ("Gemini_Generated_Image_15n63x15n63x15n6 (8).jpg", False, "potions"),
    "quests": ("Gemini_Generated_Image_15n63x15n63x15n6 (9).jpg", False, None),
    "trophy": ("Gemini_Generated_Image_15n63x15n63x15n6.jpg", {"min": 4000}, None),
    "stats": ("Gemini_Generated_Image_ahpjimahpjimahpj (1).jpg", False, None),
    "jackpot": ("Gemini_Generated_Image_ahpjimahpjimahpj (2).jpg", False, None),
    "pet": ("Gemini_Generated_Image_ahpjimahpjimahpj (3).jpg", False, None),
    "index": ("Gemini_Generated_Image_ahpjimahpjimahpj.jpg", False, None),
}

WORK = 1024
FINAL = 512
MIN_CHANNEL = 0.925  # bu değerin üstündeki ve renksiz pikseller arka plan adayıdır
MAX_SPREAD = 0.075
PAD = 0.06
HOLE_MIN_AREA = 600


def load_rgb(path):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = "Non-Color"  # ham değerler (0-1), renk dönüşümü yok
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    arr = buf.reshape(h, w, 4)[:, :, :3]
    f = w // WORK
    return arr.reshape(WORK, f, WORK, f, 3).mean(axis=(1, 3))


def flood(candidate, seeds):
    """Aday maske üzerinde 4 komşulukla taşırma; seeds: başlangıç indeksleri. Döner: ulaşılan maske."""
    h, w = candidate.shape
    flat = candidate.ravel()
    seen = np.zeros(h * w, dtype=bool)
    queue = deque()
    for idx in seeds:
        if flat[idx] and not seen[idx]:
            seen[idx] = True
            queue.append(idx)
    size = h * w
    while queue:
        idx = queue.popleft()
        x = idx % w
        if x > 0 and flat[idx - 1] and not seen[idx - 1]:
            seen[idx - 1] = True
            queue.append(idx - 1)
        if x < w - 1 and flat[idx + 1] and not seen[idx + 1]:
            seen[idx + 1] = True
            queue.append(idx + 1)
        if idx >= w and flat[idx - w] and not seen[idx - w]:
            seen[idx - w] = True
            queue.append(idx - w)
        if idx + w < size and flat[idx + w] and not seen[idx + w]:
            seen[idx + w] = True
            queue.append(idx + w)
    return seen.reshape(h, w)


def background_mask(rgb, holes):
    lo = rgb.min(axis=2)
    spread = rgb.max(axis=2) - lo
    candidate = (lo >= MIN_CHANNEL) & (spread <= MAX_SPREAD)
    h, w = candidate.shape
    border = [x for x in range(w)] + [(h - 1) * w + x for x in range(w)] + [y * w for y in range(h)] + [y * w + w - 1 for y in range(h)]
    bg = flood(candidate, border)
    if holes:
        rest = candidate & ~bg
        visited = np.zeros_like(rest)
        ys, xs = np.nonzero(~bg)
        top_limit = None
        if "top" in holes:
            top_limit = ys.max() - (ys.max() - ys.min()) * holes["top"]  # Blender satırları alttan üste sayılır: üst kısım büyük satır numarasıdır
        ys, xs = np.nonzero(rest)
        for y, x in zip(ys, xs):
            if visited[y, x]:
                continue
            comp = flood(rest & ~visited, [y * w + x])
            visited |= comp
            area = int(comp.sum())
            if area < 300:
                continue
            cy = np.nonzero(comp)[0].mean()
            take = area >= holes.get("min", HOLE_MIN_AREA) and (top_limit is None or cy >= top_limit)
            print("  hole", area, "cy", int(cy), "REMOVED" if take else "kept")
            if take:
                bg |= comp
    return bg


def erode(mask):
    out = mask.copy()
    out[1:, :] &= mask[:-1, :]
    out[:-1, :] &= mask[1:, :]
    out[:, 1:] &= mask[:, :-1]
    out[:, :-1] &= mask[:, 1:]
    return out


def blur3(a):
    p = np.pad(a, 1, mode="edge")
    return sum(p[dy:dy + a.shape[0], dx:dx + a.shape[1]] for dy in range(3) for dx in range(3)) / 9.0


def cutout(rgb, holes):
    bg = background_mask(rgb, holes)
    alpha = erode(~bg).astype(np.float32)
    alpha = blur3(alpha)
    alpha = np.clip((alpha - 0.2) / 0.6, 0, 1)  # yumuşatılmış kenarı biraz keskinleştir
    return alpha


def bbox(alpha):
    ys, xs = np.nonzero(alpha > 0.08)
    return xs.min(), xs.max() + 1, ys.min(), ys.max() + 1


def render_square(rgb, alpha, cx, cy, side):
    """Merkez (cx, cy), kenar 'side' olan kareyi (taşan yerler şeffaf) FINAL x FINAL'a önceden çarpılmış alfa ile küçültür."""
    x0 = int(round(cx - side / 2))
    y0 = int(round(cy - side / 2))
    side = int(round(side))
    canvas = np.zeros((side, side, 4), dtype=np.float32)
    sx0, sy0 = max(x0, 0), max(y0, 0)
    sx1, sy1 = min(x0 + side, WORK), min(y0 + side, WORK)
    dx0, dy0 = sx0 - x0, sy0 - y0
    region_rgb = rgb[sy0:sy1, sx0:sx1]
    region_a = alpha[sy0:sy1, sx0:sx1]
    canvas[dy0:dy0 + (sy1 - sy0), dx0:dx0 + (sx1 - sx0), :3] = region_rgb * region_a[:, :, None]
    canvas[dy0:dy0 + (sy1 - sy0), dx0:dx0 + (sx1 - sx0), 3] = region_a
    # alan ortalaması ile küçült (çıktı koordinatından kaynak aralığına): önce kareyi FINAL'ın tam katına getirmek için indeks tabanlı örnekleme
    idx = (np.arange(FINAL + 1) * side / FINAL)
    out = np.zeros((FINAL, FINAL, 4), dtype=np.float32)
    # önce satırlar, sonra sütunlar için kutu ortalaması (kümülatif toplam)
    cum = np.zeros((side + 1, side + 1, 4), dtype=np.float64)
    cum[1:, 1:] = canvas.cumsum(0).cumsum(1)
    lo = np.floor(idx).astype(int)
    hi = np.minimum(np.ceil(idx).astype(int), side)
    # basit: her çıktı pikseli için [lo, hi) kutusu
    for j in range(FINAL):
        y1, y2 = lo[j], max(hi[j + 1], lo[j] + 1)
        for_row = (cum[y2, :, :] - cum[y1, :, :])
        x1 = lo[:-1]
        x2 = np.maximum(hi[1:], lo[:-1] + 1)
        box = for_row[x2, :] - for_row[x1, :]
        area = (y2 - y1) * (x2 - x1)
        out[j] = (box / area[:, None]).astype(np.float32)
    a = out[:, :, 3:4]
    color = np.where(a > 1e-4, out[:, :, :3] / np.maximum(a, 1e-4), 0.0)
    return np.concatenate([np.clip(color, 0, 1), a], axis=2)


def save_png(arr, path):
    img = bpy.data.images.new("out", FINAL, FINAL, alpha=True, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    img.alpha_mode = "STRAIGHT"
    img.pixels.foreach_set(arr.reshape(-1).astype(np.float32))
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def main():
    argv = sys.argv
    wanted = argv[argv.index("--") + 1:] if "--" in argv else []
    data = {}
    for name, (src, holes, group) in JOBS.items():
        if wanted and name not in wanted and not (group and any(JOBS[w][2] == group for w in wanted if w in JOBS)):
            continue
        rgb = load_rgb(os.path.join(SRC, src))
        alpha = cutout(rgb, holes)
        x0, x1, y0, y1 = bbox(alpha)
        data[name] = (rgb, alpha, (x0 + x1) / 2, (y0 + y1) / 2, max(x1 - x0, y1 - y0), group)
        print("CUT", name, "bbox", x0, x1, y0, y1)
    group_side = {}
    for name, (_, _, _, _, side, group) in data.items():
        if group:
            group_side[group] = max(group_side.get(group, 0), side)
    for name, (rgb, alpha, cx, cy, side, group) in data.items():
        use = group_side[group] if group else side
        arr = render_square(rgb, alpha, cx, cy, use * (1 + PAD * 2))
        save_png(arr, os.path.join(OUT, f"{name}.png"))
        print("ICON", name)


main()
