"""Oyun görselleri (Shop, Win kupası, iksirler): referans 'game icon set' üslubunda 2B çizim (yumuşak degrade, koyu tonlu ince kenar, parlak vurgu, hafif gölge).
Her görsel kodla SVG olarak çizilir (assets/icons/svg/<ad>.svg), sonra masaüstündeki Chrome'un headless modu ile şeffaf PNG'ye çevrilir (assets/icons/<ad>.png, 512x512).
Çalıştırma (proje klasöründe):
    python tools/icons/make_icons.py            (hepsi)
    python tools/icons/make_icons.py trophy vip (seçilen)
    python tools/icons/make_icons.py --sheet    (hepsini yan yana önizleme: assets/blender/previews/icons_sheet.png, sadece bakmak için)
Adlar: trophy (Win kupası), shop_vip, shop_petspace, shop_winpack, shop_winpack_big, potion_luck, potion_muscle, potion_wins, potion_rainbow.
Studio'ya yükleme: sahibi PNG'leri Image olarak yükler, ID'ler Config.Icons alanlarına yazılır (boşken emoji / kodla çizilen şişe görünür).
"""
import math
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / "assets" / "icons"
SVG_DIR = ICONS / "svg"
CHROME_PATHS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]


# ------------------------------------------------------------------ yardımcılar
def lin(gid, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def rad(gid, stops, cx=0.4, cy=0.35, r=0.75):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{s}</radialGradient>'


def star_points(cx, cy, outer, inner, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        ang = math.radians(rot + 180 / n * i)
        r = outer if i % 2 == 0 else inner
        pts.append(f"{cx + math.cos(ang) * r:.1f},{cy + math.sin(ang) * r:.1f}")
    return " ".join(pts)


def sparkle(cx, cy, size, color="#fff6b0", opacity=0.95):
    s = size
    d = f"M{cx} {cy - s} Q{cx + s * 0.18} {cy - s * 0.18} {cx + s} {cy} Q{cx + s * 0.18} {cy + s * 0.18} {cx} {cy + s} Q{cx - s * 0.18} {cy + s * 0.18} {cx - s} {cy} Q{cx - s * 0.18} {cy - s * 0.18} {cx} {cy - s} Z"
    return f'<path d="{d}" fill="{color}" fill-opacity="{opacity}"/>'


def gloss(d, width=13, opacity=0.6):
    return f'<path d="{d}" fill="none" stroke="#fff" stroke-opacity="{opacity}" stroke-width="{width}" stroke-linecap="round"/>'


GOLD = [(0, "#fff58a"), (0.4, "#ffcb2e"), (1, "#ee8410")]
GOLD_EDGE = "#b4600a"


def common_defs():
    """Bütün görsellerde kullanılan altın degradeleri ve gölge süzgeci."""
    return (
        lin("gold", GOLD, 0, 0, 1, 1)
        + lin("goldV", GOLD, 0, 0, 0, 1)
        + lin("goldLight", [(0, "#fffbb0"), (1, "#ffd23c")], 0, 0, 0, 1)
        + '<filter id="sh" x="-15%" y="-15%" width="130%" height="140%"><feDropShadow dx="0" dy="9" stdDeviation="7" flood-color="#1b0b3a" flood-opacity=".30"/></filter>'
    )


def svg(defs, body):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'
        f"<defs>{common_defs()}{defs}</defs>"
        f'<g filter="url(#sh)" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'
    )


def cup(star_size=1.0):
    """Altın kupa kadehi (yerel eksen: x ortada, kenar y = 0, yükseklik ~ 224). Kulplar dahil. #gold / #goldLight tanımlı olmalı."""
    handle = (
        '<path d="M-98 28 C-178 12 -176 134 -78 152" fill="none" stroke="%s" stroke-width="32"/>'
        '<path d="M-98 28 C-178 12 -176 134 -78 152" fill="none" stroke="#ffc22a" stroke-width="18"/>'
        '<path d="M-98 24 C-164 12 -160 118 -84 138" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="5"/>'
    ) % GOLD_EDGE
    handles = f"<g>{handle}</g><g transform=\"scale(-1,1)\">{handle}</g>"
    body = (
        f'<path d="M-106 0 H106 C106 100 84 190 0 224 C-84 190 -106 100 -106 0 Z" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="7"/>'
        f'<ellipse cx="0" cy="0" rx="106" ry="22" fill="url(#goldLight)" stroke="{GOLD_EDGE}" stroke-width="7"/>'
        '<ellipse cx="0" cy="3" rx="91" ry="14" fill="#e98a12"/>'
        '<ellipse cx="-8" cy="1" rx="60" ry="7" fill="#ffd25a" fill-opacity=".7"/>'
        f'<polygon points="{star_points(0, 96, 46 * star_size, 20 * star_size)}" fill="url(#goldLight)" stroke="{GOLD_EDGE}" stroke-width="5"/>'
        + gloss("M-76 40 C-80 96 -64 142 -36 178", 13, 0.62)
    )
    return handles + body


# ------------------------------------------------------------------ KUPA (Win)
def icon_trophy():
    defs = lin("plinth", [(0, "#a58bff"), (1, "#5d3fd6")], 0, 0, 0, 1)
    body = (
        # kaide
        f'<rect x="146" y="428" width="220" height="62" rx="16" fill="url(#plinth)" stroke="#34208f" stroke-width="7"/>'
        f'<rect x="184" y="386" width="144" height="54" rx="12" fill="url(#plinth)" stroke="#34208f" stroke-width="7"/>'
        f'<rect x="208" y="448" width="96" height="26" rx="7" fill="url(#goldLight)" stroke="{GOLD_EDGE}" stroke-width="5"/>'
        + gloss("M168 446 H186", 7, 0.55)
        # sap
        + f'<path d="M232 330 H280 L286 390 H226 Z" fill="url(#goldV)" stroke="{GOLD_EDGE}" stroke-width="7"/>'
        + f'<ellipse cx="256" cy="388" rx="64" ry="17" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="7"/>'
        + f'<ellipse cx="256" cy="342" rx="34" ry="12" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="6"/>'
        # kadeh
        + '<g transform="translate(256 96)">' + cup() + "</g>"
        + sparkle(96, 96, 22) + sparkle(430, 150, 15)
    )
    return svg(defs, body)


# ------------------------------------------------------------------ TAÇ (VIP)
def icon_vip():
    defs = (
        rad("ruby", [(0, "#ff9ab8"), (0.45, "#ff3c6e"), (1, "#c10d44")], 0.35, 0.3, 0.8)
        + rad("sapphire", [(0, "#b6ecff"), (0.5, "#3fa7ff"), (1, "#1768c9")], 0.35, 0.3, 0.8)
        + rad("emerald", [(0, "#c6ffd2"), (0.5, "#35d36b"), (1, "#0f8a3e")], 0.35, 0.3, 0.8)
        + rad("pearl", [(0, "#ffffff"), (0.6, "#ffe9f4"), (1, "#e3b6d4")], 0.35, 0.3, 0.8)
    )
    body = (
        # taç gövdesi: 3 büyük uç
        f'<path d="M112 350 L84 156 L186 244 L256 102 L326 244 L428 156 L400 350 Z" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="8"/>'
        # içte açık ton (vurgu)
        '<path d="M126 340 L102 190 L190 266 L256 132" fill="none" stroke="#fff" stroke-opacity=".38" stroke-width="10"/>'
        # alt bant
        f'<rect x="100" y="334" width="312" height="92" rx="26" fill="url(#goldV)" stroke="{GOLD_EDGE}" stroke-width="8"/>'
        f'<rect x="116" y="346" width="280" height="22" rx="11" fill="#fff" fill-opacity=".35"/>'
        # uçlardaki toplar
        f'<circle cx="84" cy="142" r="27" fill="url(#pearl)" stroke="#b3569a" stroke-width="6"/>'
        f'<circle cx="256" cy="86" r="31" fill="url(#ruby)" stroke="#8e0a33" stroke-width="6"/>'
        f'<circle cx="428" cy="142" r="27" fill="url(#pearl)" stroke="#b3569a" stroke-width="6"/>'
        # taşlar
        f'<ellipse cx="256" cy="386" rx="40" ry="34" fill="url(#ruby)" stroke="#8e0a33" stroke-width="6"/>'
        f'<ellipse cx="170" cy="386" rx="24" ry="21" fill="url(#sapphire)" stroke="#0e4a9c" stroke-width="5"/>'
        f'<ellipse cx="342" cy="386" rx="24" ry="21" fill="url(#sapphire)" stroke="#0e4a9c" stroke-width="5"/>'
        f'<ellipse cx="116" cy="386" rx="12" ry="11" fill="url(#emerald)" stroke="#0a6a2e" stroke-width="4"/>'
        f'<ellipse cx="396" cy="386" rx="12" ry="11" fill="url(#emerald)" stroke="#0a6a2e" stroke-width="4"/>'
        + '<ellipse cx="243" cy="372" rx="12" ry="8" fill="#fff" fill-opacity=".75"/>'
        + '<ellipse cx="162" cy="378" rx="7" ry="5" fill="#fff" fill-opacity=".75"/>'
        + '<ellipse cx="334" cy="378" rx="7" ry="5" fill="#fff" fill-opacity=".75"/>'
        + sparkle(60, 250, 18) + sparkle(452, 270, 14)
    )
    return svg(defs, body)


# ------------------------------------------------------------------ SIRT ÇANTASI (Pet Space)
def icon_petspace():
    defs = (
        lin("redBody", [(0, "#ff8070"), (1, "#d63a48")], 0, 0, 1, 1)
        + lin("redDark", [(0, "#e8505a"), (1, "#a82840")], 0, 0, 1, 1)
        + lin("strap", [(0, "#fff08a"), (1, "#f4b218")], 0, 0, 0, 1)
        + lin("pawBg", [(0, "#ffffff"), (1, "#ffe0e6")], 0, 0, 0, 1)
    )
    paw = (
        '<ellipse cx="256" cy="388" rx="24" ry="19" fill="#e23c63"/>'
        '<ellipse cx="216" cy="356" rx="9" ry="12" fill="#e23c63" transform="rotate(-24 216 356)"/>'
        '<ellipse cx="242" cy="340" rx="9.5" ry="13" fill="#e23c63" transform="rotate(-8 242 340)"/>'
        '<ellipse cx="270" cy="340" rx="9.5" ry="13" fill="#e23c63" transform="rotate(8 270 340)"/>'
        '<ellipse cx="296" cy="356" rx="9" ry="12" fill="#e23c63" transform="rotate(24 296 356)"/>'
    )
    body = (
        # sap
        '<path d="M204 112 C204 30 308 30 308 112" fill="none" stroke="#1d3547" stroke-width="30"/>'
        '<path d="M204 112 C204 30 308 30 308 112" fill="none" stroke="#3d6680" stroke-width="16"/>'
        # yan ceplar
        '<rect x="62" y="290" width="76" height="126" rx="30" fill="url(#redDark)" stroke="#7a1a2c" stroke-width="7"/>'
        '<rect x="374" y="290" width="76" height="126" rx="30" fill="url(#redDark)" stroke="#7a1a2c" stroke-width="7"/>'
        # gövde
        '<rect x="104" y="116" width="304" height="342" rx="74" fill="url(#redBody)" stroke="#7a1a2c" stroke-width="8"/>'
        # kapak
        '<path d="M92 176 Q92 98 170 98 H342 Q420 98 420 176 V204 Q420 268 346 268 H166 Q92 268 92 204 Z" fill="url(#redDark)" stroke="#7a1a2c" stroke-width="8"/>'
        + gloss("M124 150 Q126 122 168 120 H236", 11, 0.5)
        # kayışlar
        + '<rect x="166" y="236" width="38" height="108" rx="10" fill="url(#strap)" stroke="#a8700a" stroke-width="6"/>'
        '<rect x="308" y="236" width="38" height="108" rx="10" fill="url(#strap)" stroke="#a8700a" stroke-width="6"/>'
        '<rect x="160" y="300" width="50" height="26" rx="8" fill="#fff" stroke="#9a8aa6" stroke-width="5"/>'
        '<rect x="302" y="300" width="50" height="26" rx="8" fill="#fff" stroke="#9a8aa6" stroke-width="5"/>'
        # ön cep + pati rozeti
        + '<rect x="144" y="318" width="224" height="132" rx="38" fill="url(#redBody)" stroke="#7a1a2c" stroke-width="8"/>'
        '<circle cx="256" cy="372" r="52" fill="url(#pawBg)" stroke="#c93a56" stroke-width="6"/>'
        + paw
        + gloss("M128 316 V384", 11, 0.5)
        + sparkle(444, 112, 18) + sparkle(76, 250, 13)
    )
    return svg(defs, body)


# ------------------------------------------------------------------ ÇUVAL (Win Pack)
def icon_winpack():
    defs = (
        lin("sack", [(0, "#ffd37a"), (1, "#e48a2c")], 0.1, 0, 0.9, 1)
        + lin("sackFrill", [(0, "#ffcf6a"), (1, "#eb9a34")], 0, 0, 0, 1)
        + lin("rope", [(0, "#b8743a"), (1, "#7e4a1e")], 0, 0, 0, 1)
    )
    coin = lambda x, y, rot: (  # noqa: E731  ayakta altın para
        f'<g transform="translate({x} {y}) rotate({rot})">'
        f'<ellipse cx="0" cy="5" rx="42" ry="40" fill="#c97712"/>'
        f'<ellipse cx="0" cy="0" rx="42" ry="40" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="6"/>'
        f'<ellipse cx="0" cy="0" rx="28" ry="26" fill="none" stroke="{GOLD_EDGE}" stroke-opacity=".55" stroke-width="5"/>'
        f'<polygon points="{star_points(0, 0, 17, 8)}" fill="#fff6b0" stroke="{GOLD_EDGE}" stroke-opacity=".6" stroke-width="3"/>'
        '<path d="M-26 -22 Q-34 -4 -26 14" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="7"/>'
        "</g>"
    )
    body = (
        # ağız: dış halka (kumaş) + koyu iç, içinden çıkan kupa, sonra önde kumaş dudağı
        '<ellipse cx="256" cy="148" rx="124" ry="32" fill="url(#sackFrill)" stroke="#9a4f0e" stroke-width="7"/>'
        '<ellipse cx="256" cy="146" rx="100" ry="21" fill="#7a3f12" stroke="#5a2d0c" stroke-width="5"/>'
        + '<g transform="translate(256 38) scale(.5)">' + cup(0.9) + "</g>"
        # çuval gövdesi (boyun ağzın altından başlar)
        + '<path d="M150 160 C100 230 70 300 100 380 C124 446 190 474 256 474 C322 474 388 446 412 380 C442 300 412 230 362 160 C340 190 300 204 256 204 C212 204 172 190 150 160 Z" fill="url(#sack)" stroke="#9a4f0e" stroke-width="8"/>'
        + gloss("M130 308 C124 348 138 392 174 424", 14, 0.45)
        # ön kumaş dudağı (kupanın alt ucunu kapatır)
        + '<path d="M132 148 A124 32 0 0 0 380 148 L356 146 A100 21 0 0 1 156 146 Z" fill="url(#sackFrill)" stroke="#9a4f0e" stroke-width="7"/>'
        # ip ve düğüm
        + '<path d="M176 184 C212 208 300 208 336 184" fill="none" stroke="#5d3210" stroke-width="22"/>'
        '<path d="M176 184 C212 208 300 208 336 184" fill="none" stroke="url(#rope)" stroke-width="12"/>'
        '<path d="M262 204 C286 224 304 244 298 270" fill="none" stroke="#5d3210" stroke-width="16"/>'
        '<path d="M262 204 C286 224 304 244 298 270" fill="none" stroke="url(#rope)" stroke-width="8"/>'
        '<path d="M250 204 C238 228 224 244 228 272" fill="none" stroke="#5d3210" stroke-width="16"/>'
        '<path d="M250 204 C238 228 224 244 228 272" fill="none" stroke="url(#rope)" stroke-width="8"/>'
        # madalyon
        + f'<circle cx="256" cy="344" r="64" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="7"/>'
        f'<circle cx="256" cy="344" r="48" fill="#fff0a0" stroke="{GOLD_EDGE}" stroke-opacity=".6" stroke-width="5"/>'
        f'<polygon points="{star_points(256, 346, 38, 17)}" fill="#f28a14" stroke="#b4600a" stroke-width="5"/>'
        + gloss("M214 306 Q226 292 244 288", 8, 0.7)
        # para
        + coin(96, 440, -14) + coin(420, 436, 14)
        + sparkle(446, 150, 18) + sparkle(70, 200, 14)
    )
    return svg(defs, body)


# ------------------------------------------------------------------ SANDIK (Mega Win Pack)
def icon_winpack_big():
    defs = (
        lin("wood", [(0, "#c47d44"), (1, "#8a4a22")], 0, 0, 0, 1)
        + lin("lidIn", [(0, "#8a5230"), (1, "#4a2810")], 0, 0, 0, 1)
        + rad("ruby", [(0, "#ff9ab8"), (0.5, "#ff3c6e"), (1, "#c10d44")])
        + rad("sapphire", [(0, "#b6ecff"), (0.5, "#3fa7ff"), (1, "#1768c9")])
        + rad("emerald", [(0, "#c6ffd2"), (0.5, "#35d36b"), (1, "#0f8a3e")])
        + rad("amethyst", [(0, "#ebd0ff"), (0.5, "#b465ff"), (1, "#6b24c4")])
    )
    coin = lambda x, y, rot, s=1.0: (  # noqa: E731
        f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
        f'<ellipse cx="0" cy="4" rx="26" ry="17" fill="#c97712"/>'
        f'<ellipse cx="0" cy="0" rx="26" ry="17" fill="url(#gold)" stroke="{GOLD_EDGE}" stroke-width="4"/>'
        f'<ellipse cx="0" cy="0" rx="16" ry="10" fill="none" stroke="{GOLD_EDGE}" stroke-opacity=".5" stroke-width="3"/>'
        "</g>"
    )
    gem = lambda x, y, fill, edge, s=1.0, rot=0: (  # noqa: E731
        f'<g transform="translate({x} {y}) rotate({rot}) scale({s})">'
        f'<polygon points="0,-24 20,-8 14,20 -14,20 -20,-8" fill="url(#{fill})" stroke="{edge}" stroke-width="4"/>'
        '<polygon points="0,-24 -20,-8 -4,-4" fill="#fff" fill-opacity=".45"/>'
        "</g>"
    )
    body = (
        # kapak içi (açık kapak, arkada)
        '<path d="M94 308 L112 126 Q256 84 400 126 L418 308 Z" fill="url(#lidIn)" stroke="#3a1e0a" stroke-width="8"/>'
        '<path d="M112 126 Q256 84 400 126" fill="none" stroke="#b4600a" stroke-width="22"/>'
        '<path d="M112 126 Q256 84 400 126" fill="none" stroke="url(#goldV)" stroke-width="12"/>'
        + "".join(f'<path d="M{x} 138 V300" stroke="#2e1606" stroke-opacity=".3" stroke-width="5"/>' for x in (190, 256, 322))
        # altın yığını ve kupa
        + '<g transform="translate(256 62) scale(.6)">' + cup(0.9) + "</g>"
        + '<path d="M84 316 C98 240 166 206 256 204 C346 206 414 240 428 316 Z" fill="url(#goldV)" stroke="#b4600a" stroke-width="8"/>'
        + coin(150, 250, -18) + coin(212, 226, 10) + coin(300, 224, -8) + coin(362, 252, 16) + coin(256, 252, 4, 1.15)
        + gem(138, 268, "ruby", "#8e0a33", 0.85, -12) + gem(378, 266, "sapphire", "#0e4a9c", 0.85, 12)
        + gem(196, 262, "emerald", "#0a6a2e", 0.7, 8) + gem(320, 258, "amethyst", "#45128f", 0.75, -8)
        # sandık gövdesi
        + '<rect x="68" y="306" width="376" height="156" rx="24" fill="url(#wood)" stroke="#4a2410" stroke-width="8"/>'
        + "".join(f'<path d="M{x} 322 V450" stroke="#4a2410" stroke-opacity=".28" stroke-width="4"/>' for x in (150, 214, 298, 362))
        + '<rect x="62" y="296" width="388" height="32" rx="14" fill="url(#goldV)" stroke="#b4600a" stroke-width="7"/>'
        + '<rect x="96" y="306" width="46" height="158" rx="10" fill="url(#goldV)" stroke="#b4600a" stroke-width="7"/>'
        '<rect x="370" y="306" width="46" height="158" rx="10" fill="url(#goldV)" stroke="#b4600a" stroke-width="7"/>'
        # kilit
        + '<rect x="222" y="314" width="68" height="88" rx="16" fill="url(#gold)" stroke="#b4600a" stroke-width="7"/>'
        '<circle cx="256" cy="350" r="12" fill="#5a2d0c"/><path d="M256 354 L248 380 H264 Z" fill="#5a2d0c"/>'
        + gloss("M88 340 V400", 9, 0.4)
        + sparkle(64, 150, 20) + sparkle(452, 188, 16) + sparkle(420, 62, 13)
    )
    return svg(defs, body)


# ------------------------------------------------------------------ İKSİRLER
def potion_symbol(kind, cx, cy):
    if kind == "clover":
        leaves = "".join(f'<circle cx="{cx + dx}" cy="{cy + dy}" r="14" fill="#36c24f" stroke="#17782f" stroke-width="4"/>' for dx, dy in ((-12, -13), (12, -13), (-12, 12), (12, 12)))
        return (
            f'<path d="M{cx + 4} {cy + 8} Q{cx + 12} {cy + 24} {cx + 22} {cy + 30}" fill="none" stroke="#17782f" stroke-width="5"/>'
            + leaves
            + f'<circle cx="{cx}" cy="{cy}" r="7" fill="#9af58a"/>'
        )
    if kind == "dumbbell":
        return (
            f'<rect x="{cx - 28}" y="{cy - 5}" width="56" height="10" rx="4" fill="#8a90ac" stroke="#2a2e44" stroke-width="3"/>'
            f'<rect x="{cx - 37}" y="{cy - 21}" width="16" height="42" rx="6" fill="#5a6080" stroke="#2a2e44" stroke-width="4"/>'
            f'<rect x="{cx + 21}" y="{cy - 21}" width="16" height="42" rx="6" fill="#5a6080" stroke="#2a2e44" stroke-width="4"/>'
            f'<rect x="{cx - 47}" y="{cy - 14}" width="11" height="28" rx="5" fill="#7a82a4" stroke="#2a2e44" stroke-width="4"/>'
            f'<rect x="{cx + 36}" y="{cy - 14}" width="11" height="28" rx="5" fill="#7a82a4" stroke="#2a2e44" stroke-width="4"/>'
        )
    if kind == "trophy":
        return (
            f'<g transform="translate({cx} {cy - 22}) scale(.2)">' + cup(0.9) + "</g>"
            f'<rect x="{cx - 4}" y="{cy + 22}" width="8" height="8" fill="#ffc22a" stroke="{GOLD_EDGE}" stroke-width="3"/>'
            f'<rect x="{cx - 14}" y="{cy + 28}" width="28" height="9" rx="3" fill="#8e6bff" stroke="#34208f" stroke-width="3"/>'
        )
    # star
    return f'<polygon points="{star_points(cx, cy + 2, 36, 16)}" fill="url(#goldLight)" stroke="{GOLD_EDGE}" stroke-width="5"/>'


def icon_potion(pid):
    liquids = {
        "luck": [(0, "#b6ff7a"), (0.5, "#43d94a"), (1, "#16902f")],
        "muscle": [(0, "#ffb070"), (0.5, "#ff5a30"), (1, "#c91c24")],
        "wins": [(0, "#fff58a"), (0.5, "#ffcb2e"), (1, "#e8820c")],
        "rainbow": [(0, "#ff7aa8"), (0.2, "#ffb03a"), (0.4, "#ffe84a"), (0.6, "#5be07a"), (0.8, "#4aa8ff"), (1, "#a35aff")],
    }
    symbols = {"luck": "clover", "muscle": "dumbbell", "wins": "trophy", "rainbow": "star"}
    defs = (
        lin("liquid", liquids[pid], 0, 0, 0, 1)
        + lin("glass", [(0, "#f4f0ff"), (1, "#c9bff7")], 0, 0, 1, 1)
        + lin("cork", [(0, "#d99a58"), (1, "#a8693a")], 0, 0, 0, 1)
        + lin("tag", [(0, "#fffbe2"), (1, "#f6e3ac")], 0, 0, 1, 1)
        + lin("ring", [(0, "#d9d2ff"), (1, "#9b8de0")], 0, 0, 0, 1)
        + '<clipPath id="clipBody"><path d="M210 168 V200 C128 226 84 286 84 350 C84 434 154 490 256 490 C358 490 428 434 428 350 C428 286 384 226 302 200 V168 Z"/></clipPath>'
    )
    body_path = "M210 168 V200 C128 226 84 286 84 350 C84 434 154 490 256 490 C358 490 428 434 428 350 C428 286 384 226 302 200 V168 Z"
    wave = "M60 330 C110 300 150 354 200 330 C250 306 290 354 340 330 C390 306 420 340 460 322"
    body = (
        # cam gövde
        f'<path d="{body_path}" fill="url(#glass)" fill-opacity=".92"/>'
        # sıvı
        f'<g clip-path="url(#clipBody)"><path d="{wave} V520 H60 Z" fill="url(#liquid)"/>'
        f'<path d="{wave}" fill="none" stroke="#fff" stroke-opacity=".55" stroke-width="8"/>'
        '<circle cx="168" cy="400" r="15" fill="#fff" fill-opacity=".28" stroke="#fff" stroke-opacity=".8" stroke-width="4"/>'
        '<circle cx="214" cy="440" r="8" fill="#fff" fill-opacity=".28" stroke="#fff" stroke-opacity=".8" stroke-width="3"/>'
        '<circle cx="322" cy="382" r="10" fill="#fff" fill-opacity=".28" stroke="#fff" stroke-opacity=".8" stroke-width="3"/>'
        '<circle cx="290" cy="446" r="16" fill="#fff" fill-opacity=".28" stroke="#fff" stroke-opacity=".8" stroke-width="4"/></g>'
        # kenar çizgisi + cam parlaması
        f'<path d="{body_path}" fill="none" stroke="#4a3d9a" stroke-width="9"/>'
        + gloss("M118 316 C112 348 118 380 132 408", 14, 0.72)
        + '<circle cx="124" cy="282" r="7" fill="#fff" fill-opacity=".8"/>'
        # boyun halkası ve mantar
        + '<rect x="196" y="140" width="120" height="34" rx="14" fill="url(#ring)" stroke="#4a3d9a" stroke-width="7"/>'
        '<path d="M214 136 L220 52 Q256 36 292 52 L298 136 Z" fill="url(#cork)" stroke="#5a3415" stroke-width="7"/>'
        '<path d="M232 76 H280 M230 104 H282" stroke="#5a3415" stroke-opacity=".3" stroke-width="5"/>'
        '<ellipse cx="256" cy="50" rx="37" ry="12" fill="#e8b27a" stroke="#5a3415" stroke-width="6"/>'
        # ip
        + '<path d="M200 152 Q256 176 312 152" fill="none" stroke="#4a2810" stroke-width="16"/>'
        '<path d="M200 152 Q256 176 312 152" fill="none" stroke="#b8743a" stroke-width="8"/>'
        '<path d="M306 160 C352 170 384 192 398 214" fill="none" stroke="#4a2810" stroke-width="12"/>'
        '<path d="M306 160 C352 170 384 192 398 214" fill="none" stroke="#b8743a" stroke-width="6"/>'
        # etiket (sağda asılı)
        + '<circle cx="404" cy="268" r="52" fill="url(#tag)" stroke="#a8803c" stroke-width="7"/>'
        '<circle cx="404" cy="224" r="6" fill="#a8803c"/>'
        + potion_symbol(symbols[pid], 404, 272)
        + sparkle(70, 120, 18) + sparkle(448, 120, 13)
    )
    return svg(defs, body)


ICONS_BUILD = {
    "trophy": icon_trophy,
    "shop_vip": icon_vip,
    "shop_petspace": icon_petspace,
    "shop_winpack": icon_winpack,
    "shop_winpack_big": icon_winpack_big,
    "potion_luck": lambda: icon_potion("luck"),
    "potion_muscle": lambda: icon_potion("muscle"),
    "potion_wins": lambda: icon_potion("wins"),
    "potion_rainbow": lambda: icon_potion("rainbow"),
}


# ------------------------------------------------------------------ PNG üretimi (Chrome headless, şeffaf arka plan)
def chrome_path():
    for path in CHROME_PATHS:
        if os.path.exists(path):
            return path
    raise SystemExit("Chrome/Edge bulunamadı: tools/icons/make_icons.py içindeki CHROME_PATHS'e yolu ekle")


def screenshot(html_path, out_path, width, height):
    cmd = [
        chrome_path(), "--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000",
        f"--window-size={width},{height}", f"--screenshot={out_path}", html_path.as_uri(),
    ]
    subprocess.run(cmd, capture_output=True, text=True, timeout=90)
    if not out_path.exists():
        raise SystemExit(f"PNG üretilemedi: {out_path}")


def render(name):
    SVG_DIR.mkdir(parents=True, exist_ok=True)
    svg_path = SVG_DIR / f"{name}.svg"
    svg_path.write_text(ICONS_BUILD[name](), encoding="utf-8")
    html = SVG_DIR / f"_{name}.html"
    html.write_text(
        '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:transparent}img{display:block}</style></head>'
        f'<body><img src="{svg_path.name}" width="512" height="512"></body></html>',
        encoding="utf-8",
    )
    out = ICONS / f"{name}.png"
    if out.exists():
        out.unlink()
    screenshot(html, out, 512, 512)
    html.unlink()
    print("ICON", name, out)


def sheet():
    """Hepsini kart renkleri üstünde yan yana gösteren önizleme (sadece bakmak için)."""
    tiles = [
        ("trophy", "#6a5cff"), ("shop_vip", "#ff50c8"), ("shop_petspace", "#eb4646"), ("shop_winpack", "#46d25a"), ("shop_winpack_big", "#be5aff"),
        ("potion_luck", "#38404f"), ("potion_muscle", "#38404f"), ("potion_wins", "#38404f"), ("potion_rainbow", "#38404f"),
    ]
    cells = "".join(f'<div style="background:{color};border-radius:18px;padding:6px"><img src="../{name}.png" width="230" height="230"></div>' for name, color in tiles)
    html = SVG_DIR / "_sheet.html"
    html.write_text(
        '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#20242e}.g{display:grid;grid-template-columns:repeat(5,246px);gap:10px;padding:10px;width:1290px}</style></head>'
        f'<body><div class="g">{cells}</div></body></html>',
        encoding="utf-8",
    )
    out = ROOT / "assets" / "blender" / "previews" / "icons_sheet.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()
    screenshot(html, out, 1310, 540)
    html.unlink()
    print("SHEET", out)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    names = args or list(ICONS_BUILD)
    for name in names:
        render(name)
    if "--sheet" in sys.argv:
        sheet()


if __name__ == "__main__":
    main()
