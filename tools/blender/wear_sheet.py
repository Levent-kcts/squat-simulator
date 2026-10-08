"""shoe_wear_preview.py -- shots çıktısını (assets/blender/previews/wear/) iki önizleme sayfasına dizer (sadece bakmak için):
    python tools/blender/wear_sheet.py   ->   assets/blender/previews/wear_sheet_34.png (3/4 görünüm), wear_sheet_side.png (yan görünüm)
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHOTS = ROOT / "assets" / "blender" / "previews" / "wear"
OUT = ROOT / "assets" / "blender" / "previews"
IDS = ["oldsneakers", "canvas", "running", "trail", "hightops", "cleats", "jump", "speed", "power", "titan", "neon", "golden", "crystal", "thunder", "radiant"]
CHROME = [r"C:\Program Files\Google\Chrome\Application\chrome.exe", r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"]


def sheet(kind):
    cells = "".join(
        f'<div style="position:relative"><img src="{(SHOTS / f"{i}_{kind}.png").as_uri()}" width="300" height="300">'
        f'<div style="position:absolute;left:6px;top:4px;background:#000a;color:#fff;font:bold 16px sans-serif;padding:2px 8px;border-radius:6px">{i}</div></div>'
        for i in IDS
    )
    html = OUT / "_wear_sheet.html"
    html.write_text(f'<!doctype html><html><body style="margin:0;background:#888"><div style="display:grid;grid-template-columns:repeat(5,300px);gap:4px;padding:4px;width:1520px">{cells}</div></body></html>', encoding="utf-8")
    out = OUT / f"wear_sheet_{kind}.png"
    if out.exists():
        out.unlink()
    chrome = next(p for p in CHROME if Path(p).exists())
    subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--window-size=1530,934", f"--screenshot={out}", html.as_uri()], capture_output=True, timeout=120)
    html.unlink()
    print("SHEET", out)


if __name__ == "__main__":
    sheet("34")
    sheet("side")
