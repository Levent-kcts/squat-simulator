"""Simge önizlemesi: assets/icons altındaki oyun simgelerini kart renkleri üstünde yan yana gösterir (sadece bakmak için).
    python tools/icons/sheet.py   ->   assets/blender/previews/icons_sheet.png
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / "assets" / "icons"
OUT = ROOT / "assets" / "blender" / "previews" / "icons_sheet.png"
CHROME = [r"C:\Program Files\Google\Chrome\Application\chrome.exe", r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]
TILES = [
    ("trophy", "#6a5cff"), ("shop_vip", "#ff50c8"), ("shop_petspace", "#eb4646"), ("shop_winpack", "#46d25a"), ("shop_winpack_big", "#be5aff"),
    ("potion_luck", "#38404f"), ("potion_muscle", "#38404f"), ("potion_wins", "#38404f"), ("potion_rainbow", "#38404f"), ("quests", "#2d6cdf"),
    ("stats", "#2d6cdf"), ("jackpot", "#2d6cdf"), ("pet", "#2d6cdf"), ("index", "#2d6cdf"),
]


def main():
    cells = "".join(
        f'<div style="background:{color};border-radius:18px;padding:6px"><img src="{(ICONS / (name + ".png")).as_uri()}" width="230" height="230"></div>'
        for name, color in TILES
        if (ICONS / (name + ".png")).exists()
    )
    html = ICONS / "_sheet.html"
    html.write_text(
        '<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#20242e}.g{display:grid;grid-template-columns:repeat(5,246px);gap:10px;padding:10px;width:1290px}</style></head>'
        f'<body><div class="g">{cells}</div></body></html>',
        encoding="utf-8",
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if OUT.exists():
        OUT.unlink()
    chrome = next(p for p in CHROME if Path(p).exists())
    subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--default-background-color=00000000", "--window-size=1310,820", f"--screenshot={OUT}", html.as_uri()], capture_output=True, timeout=90)
    html.unlink()
    print("SHEET", OUT)


if __name__ == "__main__":
    main()
