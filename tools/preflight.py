"""Yayın öncesi kontrol (preflight): oyunu yayınlamadan hemen önce proje klasöründe çalıştır.
    python tools/preflight.py            tüm kontroller (internet gerekir: Roblox varlıkları ve game pass'ler çevrimiçi doğrulanır)
    python tools/preflight.py --offline  internet kontrollerini atlar
Kontroller: git temiz mi, DEV paneli kapalı mı, kayıt adı, ürün/pass kimlikleri dolu mu, robux_ids.txt eksiksiz mi, Rojo projesi derleniyor mu,
check.py + mocktest.py geçiyor mu, Config'teki simge/ses/müzik kimlikleri Roblox'ta var mı (doğru türde), game pass'ler SATIŞTA mı ve fiyatı Config ile aynı mı.
Çıkış kodu 0 = hazır (uyarılar olabilir), 1 = en az bir engel var. Studio ayarları (API erişimi, R15, yayın) buradan KONTROL EDİLEMEZ: README 'YAYIN KONTROL LİSTESİ'.
"""
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
OFFLINE = "--offline" in sys.argv
results = []  # (durum, ad, ayrıntı)


def report(status, name, detail=""):
    results.append((status, name, detail))
    mark = {"ok": "TAMAM", "warn": "UYARI", "fail": "ENGEL"}[status]
    print(f"[{mark}] {name}" + (f": {detail}" if detail else ""))


def read(rel):
    return io.open(os.path.join(ROOT, rel), encoding="utf-8").read()


def run(cmd, timeout=600):
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)


def get_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(request, timeout=15))


config = read("src/shared/Config.luau")
code_lines = [line for line in config.splitlines() if not line.strip().startswith("--")]
code = "\n".join(code_lines)

# 1) git
git = run(["git", "status", "--porcelain"])
if git.stdout.strip():
    report("fail", "git temiz değil", f"{len(git.stdout.strip().splitlines())} değişiklik commit'lenmemiş")
else:
    log = run(["git", "log", "-1", "--format=%h %s"]).stdout.strip()
    report("ok", "git temiz", log)

# 2) DEV paneli
match = re.search(r"DevTools = \{ Enabled = (true|false)", code)
if match and match.group(1) == "false":
    report("ok", "DEV paneli yayında kapalı (Config.DevTools.Enabled = false)")
else:
    report("fail", "DEV paneli AÇIK", "Config.DevTools.Enabled = false yap")

# 3) kayıt adı
match = re.search(r'StoreName = "([^"]+)"', code)
report("ok" if match else "fail", "Kayıt adı (DataStore)", match.group(1) + " (yayından sonra ASLA değiştirme)" if match else "bulunamadı")

# 4) sıfır kimlikler
zero = re.findall(r"\b(\w*(?:[Pp]roductId|GamePassId|gamePassId)) = 0\b", code)
if zero:
    report("fail", "Kimliği 0 kalan ürün/pass var", ", ".join(sorted(set(zero))))
else:
    report("ok", "Tüm ürün ve game pass kimlikleri Config'te dolu")

empty = [line.strip() for line in read("robux_ids.txt").splitlines() if re.match(r"^\w[\w:]*=\s*$", line)]
if empty:
    report("fail", "robux_ids.txt'te boş kimlik var", ", ".join(empty))
else:
    report("ok", "robux_ids.txt eksiksiz")

empty_icons = re.findall(r"^\s*(\w+) = \"\",", re.search(r"\tIcons = \{.*?\n\t\},", code, re.S).group(0), re.M) if re.search(r"\tIcons = \{.*?\n\t\},", code, re.S) else []
empty_icons = [name for name in empty_icons if name != "WheelFace"]  # WheelFace bilerek boş: çarkın yüzü kodla çizilir (hazır resim isteğe bağlı)
if empty_icons:
    report("warn", "Simge kimliği boş (emoji yedeği kullanılır)", ", ".join(empty_icons))
else:
    report("ok", "Config.Icons'taki bütün simgeler dolu")

# 5) Rojo derlemesi
rojo = shutil.which("rojo")
if rojo:
    temp = tempfile.mkdtemp(prefix="preflight_")
    try:
        build = run([rojo, "build", "default.project.json", "-o", os.path.join(temp, "game.rbxlx")])
        size = os.path.getsize(os.path.join(temp, "game.rbxlx")) // 1024 if os.path.exists(os.path.join(temp, "game.rbxlx")) else 0
        if build.returncode == 0:
            report("ok", "Rojo projesi derleniyor", f"{size} KB")
        else:
            report("fail", "Rojo derlenemedi", (build.stderr or build.stdout).strip()[-300:])
    finally:
        shutil.rmtree(temp, ignore_errors=True)
else:
    report("warn", "rojo bulunamadı (derleme denenmedi)")

# 6) sözdizimi ve mantık testleri
check = run([sys.executable, "tools/check.py"])
report("ok" if check.returncode == 0 and " 0 sorun" in check.stdout else "fail", "check.py (luau-analyze)", check.stdout.strip().splitlines()[-1] if check.stdout.strip() else "çıktı yok")
mock = run([sys.executable, "tools/mocktest.py"])
last = mock.stdout.strip().splitlines()[-1] if mock.stdout.strip() else ""
report("ok" if mock.returncode == 0 and last.startswith("0 test") else "fail", "mocktest.py (mantık testleri)", last)

# 7) Roblox'ta doğrulama
if OFFLINE:
    report("warn", "Çevrimiçi kontroller atlandı (--offline)")
else:
    try:
        groups = {}
        for name, kinds in (("Icons", (1,)), ("Sounds", (3,)), ("Music", (3,))):
            block = re.search(rf"\t{name} = \{{.*?\n\t\}},", code, re.S)
            ids = sorted(set(re.findall(r"rbxassetid://(\d{9,})|\b(\d{12,})\b", block.group(0)))) if block else []
            flat = sorted({a or b for a, b in ids})
            groups[name] = (flat, kinds)
        for name, (ids, kinds) in groups.items():
            bad = []
            for asset in ids:
                try:
                    details = get_json(f"https://economy.roblox.com/v2/assets/{asset}/details")
                    if details.get("AssetTypeId") not in kinds:
                        bad.append(f"{asset} (tür {details.get('AssetTypeId')})")
                except Exception as error:  # noqa: BLE001
                    bad.append(f"{asset} ({error})")
            report("fail" if bad else "ok", f"Roblox varlıkları: {name} ({len(ids)} adet)", ", ".join(bad) if bad else "hepsi var, doğru türde")

        # game pass'ler: satışta mı, fiyat Config ile aynı mı
        passes = {}
        for match in re.finditer(r"(?:VipGamePassId = (\d+))|(?:AutoClick = \{[^\n]*?GamePassId = (\d+)[^\n]*?Robux = (\d+))|(?:id = \"(\w+)\", name = \"([^\"]+)\", GamePassId = (\d+), Robux = (\d+))|(?:id = \"(rainbow|black)\", name = [^\n]*?robux = (\d+), gamePassId = (\d+))", code):
            if match.group(1):
                passes[int(match.group(1))] = int(re.search(r"VipRobux = (\d+)", code).group(1))
            elif match.group(2):
                passes[int(match.group(2))] = int(match.group(3))
            elif match.group(6):
                passes[int(match.group(6))] = int(match.group(7))
            elif match.group(10):
                passes[int(match.group(10))] = int(match.group(9))
        problems = []
        for pass_id, price in sorted(passes.items()):
            try:
                info = get_json(f"https://apis.roblox.com/game-passes/v1/game-passes/{pass_id}/product-info")
                if not info.get("IsForSale"):
                    problems.append(f"{info.get('Name')} ({pass_id}) SATIŞTA DEĞİL")
                elif info.get("PriceInRobux") != price:
                    problems.append(f"{info.get('Name')}: Roblox'ta {info.get('PriceInRobux')} R$, Config'te {price} R$")
                elif not info.get("IconImageAssetId"):
                    problems.append(f"{info.get('Name')}: simgesi yok")
            except Exception as error:  # noqa: BLE001
                problems.append(f"{pass_id}: {error}")
        report("fail" if problems else "ok", f"Game pass'ler ({len(passes)} adet): satışta ve fiyat doğru", "; ".join(problems) if problems else "hepsi satışta, fiyatlar Config ile aynı, simgeleri var")
        report("warn", "Developer Product fiyatları okunamaz (Roblox giriş ister)", "Creator Hub'da elle kontrol et: ROBUX_URUNLERI.md ve ROBUX_SON_DEGISIKLIK.md")
    except Exception as error:  # noqa: BLE001
        report("warn", "Çevrimiçi kontrol yapılamadı", str(error))

fails = sum(1 for status, _, _ in results if status == "fail")
warns = sum(1 for status, _, _ in results if status == "warn")
print(f"\nSonuç: {'HAZIR' if fails == 0 else 'ENGEL VAR'} ({fails} engel, {warns} uyarı)")
sys.exit(1 if fails else 0)
