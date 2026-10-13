"""Lobi renk/ışık ÖNİZLEMESİ (2026-10-13, sahibi 'haritayı ışıklandırabiliriz, güzelce kontrol et' dedi): gerçek Studio ekran görüntüsünü alır, ÖNERİLEN renk bölgelerini ve ışık ayarını
fotoğraf düzenlemesiyle taklit eder ve yan yana ('ŞİMDİ' | 'ÖNERİLEN') kaydeder. SADECE KARAR YARDIMCISIDIR: oyunda hiçbir şey değişmez; Studio'daki gerçek sonuç az farklı olur (Roblox ışığı ayrı hesaplar).
Çalıştırma (Blender'ın kendi Python'u numpy ve bpy içerir; çıktı yolu MUTLAK olmalı):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/preview/lobby_grade_preview.py -- <girdi.png> <çıktı.png> <profil>
profil: 'egg' (yumurta standı: sol çark = sıcak şeftali, orta kemer serin kalır, sağ pano = gül), 'shelves' (skin rafı pembe, ayakkabı rafı sarı-krem).
Taklit edilen Roblox ayarları: ColorCorrection (Saturation ~+0.25, Contrast ~+0.12, TintColor sıcak), daha sıcak Ambient, duvar rengi bölgeleri (EnvironmentService WALL_COLOR / LobbyDetail), köşe karartması (tam ekran radyal degrade Frame).
"""
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1 :]
src, dst, profile = args[0], args[1], args[2]


def load(path):
    image = bpy.data.images.load(path)
    image.colorspace_settings.name = "Non-Color"  # ham değerler (dönüşüm yok)
    width, height = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(height, width, 4)
    return pixels[::-1, :, :3].copy()  # Blender alttan başlar: üstten başlayan sıraya çevir


def save(rgb, path):
    height, width = rgb.shape[:2]
    out = bpy.data.images.new("preview", width, height, alpha=False)
    out.colorspace_settings.name = "Non-Color"
    flat = np.ones((height, width, 4), dtype=np.float32)
    flat[:, :, :3] = np.clip(rgb, 0, 1)[::-1]
    out.pixels = flat.ravel()
    out.filepath_raw = path
    if path.lower().endswith((".jpg", ".jpeg")):  # JPEG: ~10 kat küçük dosya (depoya girebilsin)
        out.file_format = "JPEG"
        bpy.context.scene.render.image_settings.quality = 88
    else:
        out.file_format = "PNG"
    out.save()


def rgb_to_hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maxc = rgb.max(-1)
    minc = rgb.min(-1)
    delta = maxc - minc
    value = maxc
    sat = np.where(maxc > 1e-6, delta / np.maximum(maxc, 1e-6), 0)
    safe = np.maximum(delta, 1e-6)
    hue = np.where(maxc == r, ((g - b) / safe) % 6, np.where(maxc == g, (b - r) / safe + 2, (r - g) / safe + 4)) / 6
    hue = np.where(delta < 1e-6, 0, hue)
    return hue % 1.0, sat, value


def hsv_to_rgb(hue, sat, value):
    h6 = (hue % 1.0) * 6
    i = np.floor(h6).astype(int) % 6
    f = h6 - np.floor(h6)
    p = value * (1 - sat)
    q = value * (1 - f * sat)
    t = value * (1 - (1 - f) * sat)
    choices_r = [value, q, p, p, t, value]
    choices_g = [t, value, value, q, p, p]
    choices_b = [p, p, t, value, value, q]
    r = np.choose(i, choices_r)
    g = np.choose(i, choices_g)
    b = np.choose(i, choices_b)
    return np.stack([r, g, b], -1)


def smooth(x, low, high):
    t = np.clip((x - low) / (high - low), 0, 1)
    return t * t * (3 - 2 * t)


def luma_of(rgb):
    return (rgb * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True)


def grade(rgb, zones, horizon):
    """zones: [(x_orta, genişlik, pastel_renk, güç)] duvar bölgeleri; horizon: görüntünün üstten oranı, bunun altı zemin.
    Renk bölgesi ton DEĞİŞTİRMEZ, parlaklığı (luma) koruyup pastel bir renge boyar: tuğla derzleri ve gölgeler olduğu gibi kalır (gökkuşağı karışımı olmaz)."""
    height, width = rgb.shape[:2]
    ys, xs = np.mgrid[0:height, 0:width]
    xs = xs / width
    ys = ys / height
    hue, sat, val = rgb_to_hsv(rgb)
    luma = luma_of(rgb)

    # 1) Mavi-lavanta duvar/zemin pikselleri (ton 0.55-0.80, doygunluk > 0.07); eşyalar (farklı ton) korunur
    periwinkle = smooth(hue, 0.55, 0.60) * (1 - smooth(hue, 0.76, 0.82)) * smooth(sat, 0.05, 0.14)
    wall = periwinkle * (1 - smooth(ys, horizon - 0.04, horizon + 0.04))
    out = rgb.copy()
    for center, spread, tint, strength in zones:
        weight = (np.exp(-(((xs - center) / spread) ** 2)) * wall * strength)[..., None]
        tint = np.array(tint, dtype=np.float32) / 255
        colored = tint / float(luma_of(tint)[0]) * luma * 1.04  # aynı parlaklıkta, hedef renk
        out = out * (1 - weight) + colored * weight
    # zemin: dama plakaları hafif sıcak lavanta-gül'e kayar (ton farkı korunur)
    floor = (periwinkle * smooth(ys, horizon - 0.02, horizon + 0.06))[..., None]
    floor_tint = np.array([236, 196, 232], dtype=np.float32) / 255
    out = out * (1 - floor * 0.28) + (floor_tint / float(luma_of(floor_tint)[0]) * luma) * floor * 0.28

    # 2) ColorCorrection benzeri: hafif doygunluk, kontrast, sıcak ışık / soğuk gölge
    luma = luma_of(out)
    out = luma + (out - luma) * 1.18
    out = 0.5 + (out - 0.5) * 1.10
    highlight = smooth(luma, 0.55, 0.9)
    shadow = 1 - smooth(luma, 0.2, 0.55)
    out = out * (1 + highlight * np.array([0.04, 0.01, -0.05]))  # sıcak parlak alanlar
    out = out * (1 + shadow * np.array([-0.04, -0.03, 0.02]))  # derin gölgeler biraz soğuk/derin
    out = out * 0.98

    # 3) Köşe karartması (tam ekran radyal degrade Frame ile yapılır): dikkat merkeze toplanır
    dx = (xs - 0.5) * 1.15
    dy = (ys - 0.5)
    dist = np.sqrt(dx * dx + dy * dy)
    vignette = 1 - 0.24 * smooth(dist, 0.42, 0.85)
    return np.clip(out * vignette[..., None], 0, 1)


PEACH = (255, 206, 168)
ROSE = (255, 178, 208)
CREAM = (255, 232, 168)
PINK = (246, 168, 226)
MINT = (176, 236, 206)
PROFILES = {
    # (x_orta, yayılım, pastel renk, güç): sol çark = şeftali, orta kemer serin kalır, sağ pano = gül
    "egg": ([(0.10, 0.16, PEACH, 0.85), (0.90, 0.13, ROSE, 0.8)], 0.62),
    "shelves": ([(0.22, 0.24, PINK, 0.8), (0.78, 0.24, CREAM, 0.8)], 0.70),
}

before = load(src)
zones, horizon = PROFILES[profile]
after = grade(before, zones, horizon)

# yan yana: ŞİMDİ | ÖNERİLEN (ortada ince beyaz ayraç)
gap = np.ones((before.shape[0], 8, 3), dtype=np.float32)
combined = np.concatenate([before, gap, after], axis=1)
save(combined, dst)
print("yazıldı:", dst, combined.shape)
