"""Lobi KUŞ BAKIŞI PLANI (SVG; Chrome ile PNG'ye çevrilir): mevcut yerleşim + ÖNERİLEN renk bölgeleri, merkez etkinlik alanı ve ışık havuzları (2026-10-13 tasarım incelemesi).
Sadece karar yardımcısıdır, oyunda hiçbir şey değiştirmez. Konumlar Config.Lobby / Training / Eggs ayarlarından (stud).
Çalıştırma:
    py tools/preview/lobby_plan.py assets/preview/lobi_plan.svg
    "C:/Program Files/Google/Chrome/Application/chrome.exe" --headless --screenshot=<MUTLAK>/lobi_plan.png --window-size=1500,900 file:///<MUTLAK>/lobi_plan.svg
Eksenler: oyuncu koridora (ÜST) bakarken sol = x -62 (raflar), sağ = x +96 (antrenman); ALT = arka duvar (yumurtalar). Roblox'ta +Z aşağı çizilir (üstten bakışta).
"""
import sys

out = sys.argv[1] if len(sys.argv) > 1 else "lobi_plan.svg"

S = 6.0  # px / stud
X0, Z0 = 60, 70  # (-62, -65) köşesinin tuval konumu
W, H = 158, 130


def px(x):
    return X0 + (x + 62) * S


def pz(z):
    return Z0 + (z + 65) * S


parts = []


def rect(x1, z1, x2, z2, fill, stroke="none", opacity=1.0, rx=3, sw=2, dash=""):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    parts.append(
        f'<rect x="{px(x1):.1f}" y="{pz(z1):.1f}" width="{(x2 - x1) * S:.1f}" height="{(z2 - z1) * S:.1f}" rx="{rx}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{sw}"{d}/>'
    )


def circle(x, z, r, fill, stroke="none", opacity=1.0, sw=2, dash=""):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    parts.append(f'<circle cx="{px(x):.1f}" cy="{pz(z):.1f}" r="{r * S:.1f}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{sw}"{d}/>')


def text(x, z, content, size=15, fill="#2a2f55", weight="600", anchor="middle", dy=0):
    parts.append(f'<text x="{px(x):.1f}" y="{pz(z) + dy:.1f}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" font-family="Segoe UI, Arial, sans-serif">{content}</text>')


def arrow(x1, z1, x2, z2, color="#888", sw=3):
    parts.append(
        f'<line x1="{px(x1):.1f}" y1="{pz(z1):.1f}" x2="{px(x2):.1f}" y2="{pz(z2):.1f}" stroke="{color}" stroke-width="{sw}" stroke-dasharray="9 7" marker-end="url(#arr)" opacity="0.8"/>'
    )


# --- zemin (mevcut: tek ton lavanta) ---
rect(-62, -65, 96, 65, "#c9cdee", "#59608f", 1, 4, sw=4)

# --- ÖNERİLEN renk bölgeleri (duvar boyunca pastel bantlar) ---
rect(-62, -63, -38, -12.5, "#ffe9a8", opacity=0.75)  # ayakkabı: krem-sarı
rect(-62, -12.5, -38, 38, "#f6b4e2", opacity=0.75)  # skin: pembe
rect(31.5, -63, 96, 29, "#ffc9a6", opacity=0.7)  # antrenman: şeftali-turuncu
rect(-27, 29, 27, 65, "#b9ecd2", opacity=0.75)  # yumurta standı: nane
rect(-62, 40, -40, 65, "#cfd2f4", opacity=0.9)  # sıralama panosu köşesi (mevcut serin ton)

# --- ÖNERİLEN: ışık havuzları (sıcak nokta ışık; mevcut 64 ışık bütçesi içinde yeniden dağıtım) ---
for x, z, r in [(0, 49, 13), (46, 45, 12), (-50, 13, 11), (-50, -38, 11), (64, -17, 16), (0, 62, 7)]:
    circle(x, z, r, "#fff3b0", "none", 0.28)

# --- mevcut yapılar ---
rect(-62, -63, -38, -12.5, "none", "#a8832a", 1, 3, sw=2.5)
text(-50, -38, "AYAKKABI RAFI", 13, "#7a5a10")
rect(-62, -12.5, -38, 38, "none", "#b0489c", 1, 3, sw=2.5)
text(-50, 13, "SKİN RAFI", 13, "#8a2f78")
rect(-27, 29, 27, 65, "none", "#2f8f64", 1, 3, sw=2.5)
text(0, 49, "YUMURTA STANDI (3 kat + teras)", 13, "#1d6b48")
text(0, 58.6, "WORLDS KEMERİ · COMING SOON", 12, "#2b8fb3", weight="700")
rect(-9, 61, 9, 65, "#7fd8ff", "#2b8fb3", 0.9, 6, sw=2)
rect(31.5, -63, 96, 29, "none", "#c3702d", 1, 3, sw=2.5)
text(64, -58.2, "ANTRENMAN ALANI (10 ped, 3 kat)", 14, "#8a4a14", weight="700")
for row, (zc, n) in enumerate([(-45, 4), (-22, 3), (2, 3)]):
    for i in range(n):
        rect(40 + row * 6, zc - 8 + i * 0 + 0, 40 + row * 6, zc - 8, "none")
# antrenman pedleri (basitleştirilmiş şeritler)
for row, depth in enumerate([(32, 52), (52, 72), (72, 94)]):
    rect(depth[0], -54, depth[1] - 3, 20, "#ffffff", "#c3702d", 0.35, 3, sw=1.5, dash="4 4")
rect(-62 + 8, 43, -62 + 22, 63, "#9aa1cf", "#4f5688", 0.9, 3, sw=2)
text(-48, 54, "SIRALAMA", 11, "#2a2f55")
circle(46, 45, 9.5, "#ffd96a", "#c79a10", 0.9, sw=3)
text(46, 46, "ÇARK", 12, "#7a5a10")
rect(56, 33, 96, 65, "#ced1f1", "#8a90c4", 0.55, 3, sw=1.5, dash="5 5")
text(76, 50, "lego kuleler (boş köşe)", 11, "#555c8f", "500")
rect(-16, -65, 16, -60, "#2a2f55", "#2a2f55", 1, 0)
text(0, -62.2, "KORİDOR (100 duvar) ↑", 12, "#ffffff", weight="700")
circle(0, 0, 3.3, "#fafafa", "#555", 1, sw=2)
text(7.5, 1, "spawn", 11, "#333", weight="700", anchor="start")

# yol kenarları (x = ±16, koridor ağzından yumurta standına)
parts.append(f'<line x1="{px(-16)}" y1="{pz(-60)}" x2="{px(-16)}" y2="{pz(29)}" stroke="#7279b3" stroke-width="3"/>')
parts.append(f'<line x1="{px(16)}" y1="{pz(-60)}" x2="{px(16)}" y2="{pz(29)}" stroke="#7279b3" stroke-width="3"/>')

# --- ÖNERİLEN: merkez etkinlik alanı (şimdi BOŞ zemin) ---
circle(0, 6, 17, "#ffd7ee", "#e0248f", 0.55, sw=3.5, dash="10 7")
circle(0, 6, 9, "#ffffff", "#e0248f", 0.35, sw=2)
text(0, 11, "MERKEZ ALANI", 15, "#a0126a", weight="800")
text(0, 15.5, "sunucu boss duvarı / etkinlik", 11, "#a0126a", "600")
text(0, 19.5, "(şimdi boş zemin)", 11, "#a0126a", "500")

# --- akış okları (tipik oyuncu rotası) ---
arrow(0, -3, 0, 28, "#2d9b6b")
arrow(-4, -4, -36, -30, "#b8861b")
arrow(4, -4, 40, -22, "#c3702d")
arrow(6, 6, 44, 38, "#c79a10")
arrow(0, -8, 0, -58, "#2a2f55")

parts.insert(
    0,
    '<defs><marker id="arr" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#555"/></marker></defs>',
)

# --- açıklama (sağ taraf) ---
legend_x = X0 + W * S + 40
items = [
    ("#ffe9a8", "Ayakkabı duvarı: krem-sarı"),
    ("#f6b4e2", "Skin duvarı: pembe"),
    ("#ffc9a6", "Antrenman duvarı: şeftali-turuncu"),
    ("#b9ecd2", "Yumurta standı: nane"),
    ("#ffd7ee", "Merkez etkinlik alanı (yeni)"),
    ("#fff3b0", "Sıcak ışık havuzu (yeni, 6 nokta)"),
]
legend = ['<text x="%d" y="%d" font-size="18" font-weight="800" fill="#2a2f55" font-family="Segoe UI, Arial, sans-serif">ÖNERİLEN</text>' % (legend_x, Z0 + 14)]
for i, (color, label) in enumerate(items):
    y = Z0 + 44 + i * 34
    legend.append(f'<rect x="{legend_x}" y="{y - 16}" width="26" height="22" rx="4" fill="{color}" stroke="#777" stroke-width="1"/>')
    legend.append(f'<text x="{legend_x + 38}" y="{y}" font-size="15" fill="#2a2f55" font-family="Segoe UI, Arial, sans-serif">{label}</text>')
legend.append(f'<text x="{legend_x}" y="{Z0 + 270}" font-size="14" fill="#555" font-family="Segoe UI, Arial, sans-serif">Oklar: tipik rota (spawn → yumurta,</text>')
legend.append(f'<text x="{legend_x}" y="{Z0 + 290}" font-size="14" fill="#555" font-family="Segoe UI, Arial, sans-serif">raflar, antrenman, çark, koridor).</text>')
legend.append(f'<text x="{legend_x}" y="{Z0 + 322}" font-size="14" fill="#555" font-family="Segoe UI, Arial, sans-serif">Salon 158 x 130 stud, tavan 36.</text>')
legend.append(f'<text x="{legend_x}" y="{Z0 + 342}" font-size="14" fill="#555" font-family="Segoe UI, Arial, sans-serif">Zemin şimdi tek ton lavanta.</text>')

svg = (
    '<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="900" viewBox="0 0 1500 900">'
    '<rect width="1500" height="900" fill="#f4f5fb"/>'
    '<text x="60" y="42" font-size="24" font-weight="800" fill="#2a2f55" font-family="Segoe UI, Arial, sans-serif">Lobi kuş bakışı: mevcut yerleşim + önerilen renk bölgeleri, merkez alan ve ışık</text>'
    + "".join(parts)
    + "".join(legend)
    + "</svg>"
)
with open(out, "w", encoding="utf-8") as handle:
    handle.write(svg)
print("yazıldı:", out)
