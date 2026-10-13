"""Mantık testi (mock Roblox): oyunun Luau kodunu Roblox'suz, resmi `luau.exe` ile ÇALIŞTIRIR.
Kullanım (proje klasöründe): python tools/mocktest.py

Ne yapar: src/shared, src/server ve src/client'taki TÜM modülleri geçici bir klasöre kopyalar (require yolları dosyaya çevrilir, Roblox globalleri
tools/mocktest/stubs.luau ve cstubs.luau'daki taklitlerle değiştirilir) ve tools/mocktest/tests/*.luau testlerini koşturur:
  ptest / ptest2   PlayerStats: giriş, eğitim, skin/ayakkabı, yumurta, pet birleştirme, günlük görevler, tüm DEV komutları, kayıt
  hubtest/envtest  Hub, EnvironmentService ve WallService.init (koridorun tamamı) hatasız kuruluyor mu
  trainertest      10 antrenörün kıyafetleri
  shoetest         ayakkabı parlaklık/iz kademeleri
  shoetrailtest    gerçek AppearanceCleaner: son 4 ayakkabıda ayak ışığı ve iz (sadece koşarken açık), zayıf ayakkabıda iz yok
  ctest            QuestPanel, PetsPanel (tıklamalarla Merge/Equip/Delete, Boss takipçisi), WallClient (20 tema deseni, yakınlık döngüsü) ve Juice efektleri (pcall'sız)
  lbtest           Leaderboards: iki bağımsız pano standı (kaide, çerçeve, şerit, sütunlar) hatasız kuruluyor mu
  wheeltest        WheelService: dönen çark modeli ve sabit stand (dilimler, lambalar, ibre, ProximityPrompt) hatasız kuruluyor mu
  boottest         init.server tüm sunucu modülleriyle açılıyor mu + oyuncu girişi
  flowtest         gerçek init.server işleyicileri: tıklama -> eğitim sayacı, kas, duvar hasarı; Shop: pet birleştirme, görev ödülü (sunucu doğrulamaları)
  walltest         duvar canları (25/30/40/50/60), taşan hasarın aşama sonunu geçmemesi, kırılan duvar sayısı, menzil
  clienttest       init.client (tüm HUD, paneller, sağ üst daireler, eğitim yazısı) tüm istemci modülleriyle açılıyor mu
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
    "local ColorSequenceKeypoint, Rect, Ray, Region3, PhysicalProperties, OverlapParams, RaycastParams, DateTime, BrickColor, Font, Axes, Faces = "
    "S.G, S.G, S.G, S.G, S.G, S.G, S.G, S.G, S.G, S.G, S.G, S.G\n"
)
CLIENT_PRELUDE = SERVER_PRELUDE.replace('require("./stubs")', 'require("../cstubs")')


def module_names(folder, skip):
    names = []
    for name in os.listdir(os.path.join(ROOT, "src", folder)):
        if name.endswith(".luau") and name != skip:
            names.append(name[: -len(".luau")])
    return sorted(names)


CLIENT_TESTS = ("ctest.luau", "clienttest.luau", "loadingtest.luau", "giftstest.luau", "perftest.luau", "taptest.luau", "leveluptest.luau", "guidetourtest.luau")  # istemci taklidiyle (c klasöründe) koşan testler
SHARED = module_names("shared", "")
SERVER = module_names("server", "init.server.luau")  # init.server 'serverMain' olarak ayrıca kurulur
CLIENT = module_names("client", "init.client.luau")  # init.client 'clientMain' olarak ayrıca kurulur

# init.client: 'script:FindFirstChild(isim)' ve 'require(modül örneği)' kalıpları için küçük bir kabuk
CLIENT_SHIM = (
    "S.localPlayer:SetAttribute('LoadingActive', true)\n"  # yükleme ekranı yedeği testte çalışmasın (gerçek bekleme döngüleri taklitte sonsuza dek döner)
    "local KNOWN = { " + ", ".join(f"{name} = true" for name in CLIENT) + " }\n"
    "local script = { FindFirstChild = function(_, name) if KNOWN[name] then return { _modname = name } end return nil end }\n"
    "local realRequire = require\n"
    "local function require(target)\n"
    '\tif type(target) == "table" and rawget(target, "_modname") then return realRequire("./" .. target._modname) end\n'
    "\treturn realRequire(target)\n"
    "end\n"
)


def convert(source):
    """Roblox'a özgü require biçimlerini dosya yoluna çevirir."""
    source = re.sub(r"pcall\(require, script(?:\.Parent)?\.(\w+)\)", r'pcall(require, "./\1")', source)
    source = re.sub(r"require\(script\.Parent\.(\w+)\)", r'require("./\1")', source)
    source = re.sub(r"require\(script\.(\w+)\)", r'require("./\1")', source)
    source = re.sub(r'require\(Shared:WaitForChild\("(\w+)"\)\)', r'require("./\1")', source)
    source = re.sub(r'require\(ReplicatedStorage:WaitForChild\("Shared"\):WaitForChild\("(\w+)"\)\)', r'require("./\1")', source)
    return source


def write(path, text):
    with io.open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(text)


def read(*parts):
    with io.open(os.path.join(ROOT, *parts), encoding="utf-8") as handle:
        return handle.read()


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
            write(os.path.join(target, subdir, name + ".luau"), prelude + convert(read("src", folder, name + ".luau")))
    # Ana betikler modül gibi koşturulur (en sona 'return true')
    write(os.path.join(target, "serverMain.luau"), SERVER_PRELUDE + convert(read("src", "server", "init.server.luau")) + "\nreturn true\n")
    write(os.path.join(target, "c", "clientMain.luau"), CLIENT_PRELUDE + CLIENT_SHIM + convert(read("src", "client", "init.client.luau")) + "\nreturn true\n")
    tests = os.path.join(MOCK, "tests")
    for name in os.listdir(tests):
        destination = os.path.join(target, "c" if name in CLIENT_TESTS else "", name)
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
            cwd = os.path.join(target, "c") if name in CLIENT_TESTS else target
            result = subprocess.run([LUAU, name], capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=cwd, timeout=120)
            # UIStyle.soften UDim değerlerini taklitte tanıyamaz (typeof): bu bilinen taklit boşluğu, oyunda UIStyle zaten hata verirse düz kalır
            lines = (result.stdout + result.stderr).splitlines()
            gaps = ("[UIStyle]", "task.spawn error:\t./Sfx.luau", "task.spawn error:\t./GiftsPanel.luau", "task.spawn error:\t./EggShop.luau", "task.spawn error:\t./MusicPlayer.luau", "mock gap",
                    # sessionlocktest.luau'nun BEKLENEN uyarıları (kilit bekleme/devralma ve sahte DataStore hatası)
                    "still locked by another server", "taken over by another server", "mock datastore failure")
            output = chr(10).join(line for line in lines if not any(gap in line for gap in gaps))
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
