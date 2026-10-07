"""Günlük çarkın hazır yüzünü (daire şeklinde, şeffaf köşeli PNG) üretir: assets/icons/wheel.png.
Kullanım (proje klasöründe): python tools/make_wheel_image.py
Dilim renkleri Config.luau'daki Wheel.Prizes[].color değerlerinden okunur (8 dilim, 1. dilim üstte, saat yönünde). Resim sadece ZEMİNDİR: simge/ad/yüzde yazıları oyunda üstüne çizilir.
Neden var: çarkın yüzü normalde arayüz nesneleriyle (shared/WheelFace: dik üçgenler + CanvasGroup) çizilir; bazı yerlerde (SurfaceGui) CanvasGroup daireye kırpmaz. Hazır resim kullanılırsa
her yerde tam yuvarlak ve pürüzsüz görünür. Resmi Roblox'a yükleyip Image ID'sini Config.Icons.WheelFace'e yazınca hem lobideki çark hem E ile açılan arayüz bunu kullanır.
Sadece standart kütüphane kullanır (PIL gerekmez)."""
import math
import os
import re
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZE = 1024
RADIUS = SIZE / 2 - 2


def prize_colors():
    with open(os.path.join(ROOT, "src", "shared", "Config.luau"), encoding="utf-8") as handle:
        source = handle.read()
    start = source.index("Wheel = {")
    block = source[start : start + 4000]
    prizes = block[block.index("Prizes = {") :]
    colors = re.findall(r"color = Color3\.fromRGB\((\d+), (\d+), (\d+)\)", prizes)[:8]
    if len(colors) != 8:
        raise SystemExit(f"8 dilim rengi bulunamadı ({len(colors)})")
    return [tuple(int(v) for v in rgb) for rgb in colors]


def render(colors):
    pixels = bytearray()
    slice_angle = math.pi / 4
    for y in range(SIZE):
        pixels.append(0)  # PNG satır filtresi: yok
        dy = y + 0.5 - SIZE / 2
        for x in range(SIZE):
            dx = x + 0.5 - SIZE / 2
            radius = math.hypot(dx, dy)
            edge = RADIUS - radius + 0.5  # daire kenarı: 1 pikselden az kadar yumuşatma
            if edge <= 0:
                pixels += b"\x00\x00\x00\x00"
                continue
            theta = math.atan2(dx, -dy) % (2 * math.pi)  # yukarıdan saat yönünde
            index = min(int(theta / slice_angle), 7)
            red, green, blue = colors[index]
            # Ayırıcı çizgi: dilim sınırına (kat x 45 derece) olan uzaklık (piksel)
            offset = theta % slice_angle
            distance = radius * math.sin(min(offset, slice_angle - offset))
            line = max(0.0, min(1.0, 1.0 - (distance - 4.0) / 1.4)) * 0.7
            red = red + (255 - red) * line
            green = green + (255 - green) * line
            blue = blue + (255 - blue) * line
            alpha = int(255 * max(0.0, min(1.0, edge)))
            pixels += bytes((int(red), int(green), int(blue), alpha))
    return bytes(pixels)


def write_png(path, raw):
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)  # 8 bit, RGBA
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", header))
        handle.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        handle.write(chunk(b"IEND", b""))


def main():
    out = os.path.join(ROOT, "assets", "icons", "wheel.png")
    write_png(out, render(prize_colors()))
    print(f"yazıldı: {out} ({os.path.getsize(out) // 1024} KB)")


if __name__ == "__main__":
    main()
