"""Roblox türleriyle derin denetim: luau-lsp (gerçek Roblox API tür tanımları) + Selene (Luau linter'ı).
check.py'nin yakalayamadığı şeyleri bulur: yanlış Roblox özellik/metod adı, yanlış argüman sayısı, tür uyuşmazlığı,
kullanılmayan değişken, eskimiş API. Kullanım (proje klasöründe): python tools/typecheck.py [--strict]
Araçlar Rokit ile kurulu (rokit.toml: luau-lsp, selene, rojo). luau-lsp Türkçe karakterli yolu (Masaüstü) açamadığı için
src geçici ASCII klasöre kopyalanıp orada denetlenir. Roblox tür tanımı %USERPROFILE%/.luau/globalTypes.d.luau'ya bir kez
indirilir (--update ile yenilenir). Varsayılan: sadece rapor (çıkış 0); --strict: sorun varsa çıkış 1.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TYPES_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"
TYPES = os.path.join(os.path.expanduser("~"), ".luau", "globalTypes.d.luau")
ROKIT_BIN = os.path.join(os.path.expanduser("~"), ".rokit", "bin")
LINE = re.compile(r"src[\\/](\S+) \[[^\]]*\]\((\d+),(\d+)\): (\w+): (.*)")


def tool(name):
    path = os.path.join(ROKIT_BIN, name + ".exe")
    return path if os.path.exists(path) else name


def run(args, cwd):
    return subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=cwd)


def ensure_types(update):
    if update or not os.path.exists(TYPES):
        os.makedirs(os.path.dirname(TYPES), exist_ok=True)
        print("Roblox tür tanımları indiriliyor...")
        urllib.request.urlretrieve(TYPES_URL, TYPES)


def luau_lsp():
    work = tempfile.mkdtemp(prefix="squat_types_")
    try:
        shutil.copytree(os.path.join(ROOT, "src"), os.path.join(work, "src"))
        for name in ("default.project.json", "rokit.toml"):
            shutil.copy(os.path.join(ROOT, name), work)
        made = run([tool("rojo"), "sourcemap", "default.project.json", "-o", "sourcemap.json"], work)
        if made.returncode != 0:
            return [f"[rojo sourcemap hatası] {made.stderr.strip()}"]
        result = run([tool("luau-lsp"), "analyze", f"--definitions={TYPES}", "--sourcemap=sourcemap.json",
                      "--no-strict-dm-types", "src"], work)
        problems = []
        for line in (result.stdout + result.stderr).splitlines():
            match = LINE.search(line)
            if match:
                path, row, col, kind, text = match.groups()
                problems.append(f"src/{path.replace(chr(92), '/')}:{row}:{col} [{kind}] {text[:200]}")
        return sorted(set(problems))
    finally:
        shutil.rmtree(work, ignore_errors=True)


def selene():
    if not os.path.exists(os.path.join(ROOT, "roblox.yml")):
        run([tool("selene"), "generate-roblox-std"], ROOT)
    result = run([tool("selene"), "src", "--display-style", "quiet"], ROOT)
    return [line for line in result.stdout.splitlines() if re.search(r"(error|warning)\[", line)]


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ensure_types("--update" in sys.argv)
    types = luau_lsp()
    lints = selene()
    print("== luau-lsp (Roblox türleri) ==")
    for line in types:
        print(line)
    print("== selene ==")
    for line in lints:
        print(line)
    print(f"luau-lsp {len(types)} sorun, selene {len(lints)} sorun")
    sys.exit(1 if "--strict" in sys.argv and (types or lints) else 0)
