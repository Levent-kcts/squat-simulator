"""Proje denetimi: tüm src/**/*.luau dosyalarını Luau'nun resmi analizcisiyle (luau-analyze) ve yapı denetleyicisiyle (luacheck.py) tarar.
Kullanım (proje klasöründe): python tools/check.py
luau-analyze burada aranır: %USERPROFILE%/.luau/luau-analyze.exe (https://github.com/luau-lang/luau/releases, luau-windows.zip).
Roblox'un kendi tür tanımları olmadığı için Roblox globalleri ("Unknown global 'Color3'" gibi) süzülür; SyntaxError ve gerçek bilinmeyen
değişkenler raporlanır.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANALYZER = os.path.join(os.path.expanduser("~"), ".luau", "luau-analyze.exe")
ROBLOX_GLOBALS = (
    "game|Instance|Enum|Vector3|Vector2|Color3|CFrame|UDim2|UDim|NumberSequence|NumberSequenceKeypoint|ColorSequence|"
    "ColorSequenceKeypoint|NumberRange|Random|script|workspace|task|warn|require|typeof|Content|TweenInfo|Rect|Font|"
    "BrickColor|Ray|Region3|os|Axes|Faces|DateTime|PhysicalProperties|OverlapParams|RaycastParams|settings|tick|time|"
    "wait|spawn|delay|shared|Vector3int16|Vector2int16|CatalogSearchParams|SharedTable"
)
IGNORE = re.compile(rf"Unknown global '({ROBLOX_GLOBALS})'")


def source_files():
    files = []
    for folder, _, names in os.walk(os.path.join(ROOT, "src")):
        for name in names:
            if name.endswith(".luau"):
                files.append(os.path.join(folder, name))
    return sorted(files)


def run_analyzer(files):
    if not os.path.exists(ANALYZER):
        print(f"[uyarı] luau-analyze bulunamadı ({ANALYZER}); sadece yapı denetimi yapılıyor.")
        return []
    # Göreli yol: klasör adındaki Türkçe karakterler (Masaüstü) komut satırında bozulmasın
    relative = [os.path.relpath(path, ROOT) for path in files]
    result = subprocess.run([ANALYZER] + relative, capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=ROOT)
    problems = []
    for line in (result.stdout + result.stderr).splitlines():
        if ("SyntaxError" in line or "TypeError" in line or "UnknownGlobal" in line) and not IGNORE.search(line):
            problems.append(line)
    return problems


def run_structure(files):
    result = subprocess.run(
        [sys.executable, os.path.join("tools", "luacheck.py")] + [os.path.relpath(path, ROOT) for path in files],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=ROOT,
    )
    return [line for line in result.stdout.splitlines() if line and not line.endswith(" sorun")]


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    files = source_files()
    problems = run_analyzer(files) + run_structure(files)
    for problem in problems:
        print(problem)
    print(f"{len(files)} dosya tarandı, {len(problems)} sorun")
    sys.exit(1 if problems else 0)
