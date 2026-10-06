"""Mantık testi (mock Roblox): oyunun Luau kodunu Roblox'suz, resmi `luau.exe` ile ÇALIŞTIRIR.
Kullanım (proje klasöründe): python tools/mocktest.py

Ne yapar: src/shared, src/server ve src/client'taki ilgili modülleri geçici bir klasöre kopyalar (require yolları dosyaya çevrilir, Roblox globalleri
tools/mocktest/stubs.luau ve cstubs.luau'daki taklitlerle değiştirilir) ve tools/mocktest/tests/*.luau testlerini koşturur:
  ptest / ptest2  PlayerStats: giriş, eğitim, skin/ayakkabı, yumurta, pet birleştirme, günlük görevler, tüm DEV komutları, kayıt
  hubtest/envtest Hub, EnvironmentService ve WallService.init (koridorun tamamı) hatasız kuruluyor mu
  shoetest        ayakkabı parlaklık/iz kademeleri
  ctest           QuestPanel, FusionPanel, WallClient (20 tema deseni, yakınlık döngüsü) ve Juice efektleri (pcall'sız)
YAKALAR: Luau mantık hataları (nil indeksleme, yanlış değişken/alan, çökme). YAKALAMAZ: Roblox özellik/enum adı yanlışları ve görünüm; onlar Studio'da görülür.
luau.exe: %USERPROFILE%/.luau/luau.exe (luau-analyze ile aynı zip, https://github.com/luau-lang/luau/releases).
"""
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOCK = os.path.join(ROOT, "tools", "mocktest")
LUAU = os.path.join(os.path.expanduser("~"), ".luau", "luau.exe")

SERVER_PRELUDE = (
    'local S = require("./stubs")\n'
    "local Color3, Vector3, Vector2, Enum, Random, Instance, task, warn, game, workspace = "
    "S.Color3, S.Vector3, S.Vector2, S.Enum, S.Random, S.Instance, S.task, S.warn, S.game, S.workspace\n"
    "local UDim2, UDim, CFrame, NumberSequence, NumberSequenceKeypoint, ColorSequence, NumberRange, TweenInfo = "
    "S.UDim2, S.UDim, S.CFrame, S.NumberSequence, S.NumberSequenceKeypoint, S.ColorSequence, S.NumberRange, S.TweenInfo\n"
)
CLIENT_PRELUDE = SERVER_PRELUDE.replace('require("./stubs")', 'require("../cstubs")')

SHARED = ["Config", "Layout", "Catalog", "Format", "Progression", "ShoeModel"]
SERVER = ["PlayerStats", "Build", "Hub", "EnvironmentService", "WallService"]
CLIENT = ["UIStyle", "PanelManager", "WallClient", "QuestPanel", "FusionPanel", "Juice"]


def convert(source):
    """Roblox'a özgü require biçimlerini dosya yoluna çevirir."""
    source = re.sub(r"pcall\(require, script\.Parent\.(\w+)\)", r'pcall(require, "./\1")', source)
    source = re.sub(r"require\(script\.Parent\.(\w+)\)", r'require("./\1")', source)
    source = re.sub(r'require\(Shared:WaitForChild\("(\w+)"\)\)', r'require("./\1")', source)
    source = re.sub(r'require\(ReplicatedStorage:WaitForChild\("Shared"\):WaitForChild\("(\w+)"\)\)', r'require("./\1")', source)
    return source


def write(path, text):
    with io.open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(text)


def build(target):
    os.makedirs(os.path.join(target, "c"), exist_ok=True)
    for name in ("stubs.luau", "cstubs.luau"):
        shutil.copy(os.path.join(MOCK, name), os.path.join(target, name))
    for folder, names, prelude, subdir in (
        ("shared", SHARED, SERVER_PRELUDE, ""),
        ("server", SERVER, SERVER_PRELUDE, ""),
        ("shared", SHARED, CLIENT_PRELUDE, "c"),
        ("client", CLIENT, CLIENT_PRELUDE, "c"),
    ):
        for name in names:
            with io.open(os.path.join(ROOT, "src", folder, name + ".luau"), encoding="utf-8") as handle:
                write(os.path.join(target, subdir, name + ".luau"), prelude + convert(handle.read()))
    tests = os.path.join(MOCK, "tests")
    for name in os.listdir(tests):
        destination = os.path.join(target, "c" if name == "ctest.luau" else "", name)
        shutil.copy(os.path.join(tests, name), destination)


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if not os.path.exists(LUAU):
        print(f"[uyarı] luau.exe bulunamadı: {LUAU}")
        return 2
    target = tempfile.mkdtemp(prefix="mocktest_")
    failed = 0
    try:
        build(target)
        for name in sorted(os.listdir(os.path.join(MOCK, "tests"))):
            cwd = os.path.join(target, "c") if name == "ctest.luau" else target
            result = subprocess.run([LUAU, name], capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=cwd, timeout=120)
            output = result.stdout + result.stderr
            bad = result.returncode != 0 or re.search(r"ERROR|WARN\b|attempt to|stacktrace|Error opening|failures:\s+[1-9]", output)
            print(f"{'HATA ' if bad else 'tamam'}  {name}")
            if bad:
                failed += 1
                for line in output.splitlines():
                    if re.search(r"ERROR|WARN\b|attempt to|stacktrace|Error opening|failures:", line):
                        print("      " + line[:220])
    finally:
        shutil.rmtree(target, ignore_errors=True)
    print(f"{failed} test başarısız")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
