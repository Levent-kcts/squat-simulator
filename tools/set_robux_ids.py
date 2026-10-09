"""Robux ürün kimliklerini (Developer Product / game pass ID) Config.luau'ya yazar.
Kullanım (proje klasöründe):
    python tools/set_robux_ids.py --init           robux_ids.txt (boş şablon) ve ROBUX_URUNLERI.md (Creator Hub'da açılacak ürünler tablosu) üretir
    python tools/set_robux_ids.py robux_ids.txt    dosyadaki 'anahtar=ID' satırlarını Config.luau'ya yazar (boş ID'ler atlanır, ID 0 kalır)
Anahtarlar: shop:<id> (Shop ürünleri), potion:<id> (iksirler), trail:<id>, aura:<id>, skip (Rebirth SKIP), double (Offline DOUBLE IT!), vip (VIP game pass), autoclick (Auto Click game pass),
eggauto / eggtriple / eggmulti (yumurta paneli game pass'leri: Auto Open, Triple Open x3, Multi Open x10; fiyatları 150'yi geçer, bunlar kuralın istisnasıdır).
Yazmadan önce: ID'ler sayı olmalı, aynı ID iki yerde kullanılamaz (Purchases.init uyarı verir); VIP game pass ID'si çevrimiçi doğrulanmaya çalışılır (olmazsa uyarı).
Config.luau'daki fiyatlar (robux = ...) sadece arayüzde GÖSTERİLEN fiyattır; asıl fiyatı Creator Hub'daki ürün belirler: tabloyu aynı fiyatlarla aç.
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG = os.path.join(ROOT, "src", "shared", "Config.luau")

SHOP_DETAILS = {
    "petSpace25": "Adds 25 pet slots to your Pets bag.",
    "power1k": "Instantly gives 1,000 squats worth of leg muscle.",
    "power10k": "Instantly gives 10,000 squats worth of leg muscle.",
    "power100k": "Instantly gives 100,000 squats worth of leg muscle.",
    "winsSmall": "Instantly gives the Wins you earn for clearing stage 8.",
    "winsBig": "Instantly gives the Wins you earn for clearing stage 12.",
}
POTION_NAMES = {"luck": "Luck Potion", "muscle": "Muscle Potion", "wins": "Wins Potion", "rainbow": "Rainbow Potion"}
POTION_DETAILS = {
    "luck": "2x egg luck: rare pets hatch more often.",
    "muscle": "2x leg muscle from every squat.",
    "wins": "Doubles every Win you earn.",
    "rainbow": "Counts as ALL potions: 2x luck, 2x muscle and 2x Wins.",
}


def block(text, name):
    """`\\tname = {` ... eşleşen `}` bloğunun (başlangıç, bitiş) konumları."""
    start = text.index(f"\t{name} = {{")
    depth, i = 0, text.index("{", start)
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return start, j + 1
    raise ValueError(name)


def read_products():
    """Config'ten ürünler: [(anahtar, ad, açıklama, fiyat, tür)]."""
    text = io.open(CONFIG, encoding="utf-8").read()
    items = []
    shop_start, shop_end = block(text, "Shop")
    shop = text[shop_start:shop_end]
    for m in re.finditer(r'\{ id = "(\w+)", name = "([^"]+)", detail = "([^"]*)".*?robux = (\d+), productId = (\d+)', shop):
        items.append((f"shop:{m.group(1)}", m.group(2), SHOP_DETAILS.get(m.group(1), m.group(3)), int(m.group(4)), "Developer Product"))
    for m in re.finditer(r'\{ id = "(\w+)", potion = "(\w+)", minutes = (\d+), robux = (\d+), productId = (\d+)', shop):
        name = f"{POTION_NAMES[m.group(2)]} ({m.group(3)} min)"
        items.append((f"potion:{m.group(1)}", name, POTION_DETAILS[m.group(2)] + f" Lasts {m.group(3)} minutes.", int(m.group(4)), "Developer Product"))
    for kind, label in (("Trails", "trail"), ("Auras", "aura")):
        start, end = block(text, kind)
        for m in re.finditer(r'\{ id = "(\w+)", name = "([^"]+)".*?robuxPrice = (\d+), robuxProductId = (\d+)', text[start:end]):
            detail = "Unlocks this trail forever: leaves a colored trail and makes you run faster." if label == "trail" else "Unlocks this aura forever: multiplies your leg muscle gain."
            items.append((f"{label}:{m.group(1)}", m.group(2), detail, int(m.group(3)), "Developer Product"))
    skip = int(re.search(r"SkipRobuxPrice = (\d+)", text).group(1))
    double = int(re.search(r"DoubleRobux = (\d+)", text).group(1))
    items.append(("skip", "Rebirth Skip", "Skip the level requirement and rebirth right now.", skip, "Developer Product"))
    items.append(("double", "Double Offline Earnings", "Doubles the offline earnings waiting for you.", double, "Developer Product"))
    vip = int(re.search(r"VipRobux = (\d+)", text).group(1))
    items.append(("vip", "VIP", "VIP pad: the Win button gives 2x Wins every stage. Permanent.", vip, "Game Pass"))
    auto = int(re.search(r"AutoClick = \{[^}]*Robux = (\d+)", text).group(1))
    items.append(("autoclick", "Auto Click", "Auto Click: your character squats and kicks for you, up to 10 clicks per second. Permanent.", auto, "Game Pass"))
    # Yumurta paneli game pass'leri (Config.EggPasses)
    egg_details = {
        "auto": "Auto Open: eggs open automatically, hands-free. Permanent.",
        "triple": "Triple Open: hatch 3 eggs at once. Permanent.",
        "multi": "Multi Open: hatch 10 eggs at once. Permanent.",
    }
    for m in re.finditer(r'\{ id = "(auto|triple|multi)", name = "([^"]+)", GamePassId = \d+, Robux = (\d+)', text):
        items.append((f"egg{m.group(1)}", m.group(2), egg_details[m.group(1)], int(m.group(3)), "Game Pass"))
    return items


def write_template():
    items = read_products()
    path = os.path.join(ROOT, "robux_ids.txt")
    existing = {}  # var olan ID'ler KORUNUR (yeni ürün eklenince şablon güvenle yeniden üretilebilir)
    if os.path.exists(path):
        for raw in io.open(path, encoding="utf-8").read().splitlines():
            if "=" in raw and not raw.startswith("#"):
                name, value = raw.split("=", 1)
                existing[name.strip()] = value.strip()
    with io.open(path, "w", encoding="utf-8", newline="") as f:
        f.write("# Her satırda anahtar=ID. Boş bırakılan ürün 'coming soon' kalır. Doldurunca: python tools/set_robux_ids.py robux_ids.txt\n")
        f.write("# Developer Product ID'leri: Creator Hub > Deneyim > Para Kazanma > Geliştirici Ürünleri. Game Pass'ler (VIP, Auto Click, eggauto, eggtriple, eggmulti): Para Kazanma > Geçişler (Passes).\n")
        for key, *_ in items:
            f.write(f"{key}={existing.get(key, '')}\n")
    lines = ["# Robux ürünleri: Creator Hub'da açılacaklar", "",
             "Her satır için Creator Hub'da (create.roblox.com) oyunun > **Para Kazanma (Monetization) > Geliştirici Ürünleri (Developer Products)** sayfasında bir ürün aç (VIP için **Geçişler / Passes**).",
             "Ad, açıklama ve **fiyat** tabloda yazdığı gibi olsun (oyundaki gösterilen fiyatla aynı olmalı; yumurta pass'leri hariç hiçbir fiyat 150 Robux'u geçmez; eggauto/eggtriple/eggmulti bilerek daha pahalıdır). Açınca ürünün ID'sini `robux_ids.txt` dosyasında ilgili satıra yaz",
             "(ya da bana yapıştır), sonra `python tools/set_robux_ids.py robux_ids.txt` Config'e işler. Oyun Studio'da yayınlanmış olmalı, ürünler o oyuna (deneyime) ait olmalı.", "",
             f"Toplam: {len(items)} ürün ({sum(1 for i in items if i[4] == 'Developer Product')} Developer Product + {sum(1 for i in items if i[4] == 'Game Pass')} Game Pass).", "",
             "| # | Anahtar | Tür | Ad | Fiyat (Robux) | Açıklama |", "|---|---|---|---|---|---|"]
    for index, (key, name, detail, price, kind) in enumerate(items, 1):
        lines.append(f"| {index} | `{key}` | {kind} | {name} | {price} | {detail} |")
    lines += ["", "Not: en önemli ürünler (ilk açılacaklar): Pet Space, +1K / +10K / +100K Power, Win Pack, Mega Win Pack, iksirler, VIP. İz ve aura ürünleri sonra eklenebilir; ID'si boş olan ürün oyunda 'coming soon' der ve hata vermez.", ""]
    io.open(os.path.join(ROOT, "ROBUX_URUNLERI.md"), "w", encoding="utf-8", newline="").write("\n".join(lines))
    print(f"robux_ids.txt ve ROBUX_URUNLERI.md yazıldı ({len(items)} ürün)")


def apply_ids(path):
    mapping = {}
    for raw in io.open(path, encoding="utf-8").read().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line or "=" not in line:
            continue
        key, value = (x.strip() for x in line.split("=", 1))
        if not value:
            continue
        if not value.isdigit() or int(value) <= 0:
            sys.exit(f"HATA: {key} için ID sayı olmalı: '{value}'")
        mapping[key] = int(value)
    valid = {key for key, *_ in read_products()}
    for key in mapping:
        if key not in valid:
            sys.exit(f"HATA: bilinmeyen anahtar: {key}")
    seen = {}
    for key, value in mapping.items():
        if key != "vip" and value in seen:  # (VIP bilerek tekrar edebilir)
            sys.exit(f"HATA: {value} ID'si iki üründe: {seen[value]} ve {key}")
        seen[value] = key

    text = io.open(CONFIG, encoding="utf-8").read()
    done = 0

    def replace_line(pattern, field, value):
        nonlocal text, done
        m = re.search(pattern, text)
        if not m:
            sys.exit(f"HATA: Config'te satır bulunamadı: {pattern}")
        line = m.group(0)
        new_line, count = re.subn(rf"\b{field} = \d+", f"{field} = {value}", line)
        if count != 1:
            sys.exit(f"HATA: {field} alanı bulunamadı: {line[:80]}")
        text = text.replace(line, new_line, 1)
        done += 1

    for key, value in mapping.items():
        if key.startswith("shop:"):
            replace_line(rf'[^\n]*\{{ id = "{key[5:]}", name = [^\n]*productId = \d+[^\n]*', "productId", value)
        elif key.startswith("potion:"):
            replace_line(rf'[^\n]*\{{ id = "{key[7:]}", potion = [^\n]*productId = \d+[^\n]*', "productId", value)
        elif key.startswith(("trail:", "aura:")):
            kind, item = key.split(":")
            start, end = block(text, "Trails" if kind == "trail" else "Auras")
            section = text[start:end]
            m = re.search(rf'[^\n]*\{{ id = "{item}", name = [^\n]*robuxProductId = \d+[^\n]*', section)
            if not m:
                sys.exit(f"HATA: {key} Config'te yok")
            new_line = re.sub(r"robuxProductId = \d+", f"robuxProductId = {value}", m.group(0), count=1)
            text = text[:start] + section.replace(m.group(0), new_line, 1) + text[end:]
            done += 1
        elif key == "skip":
            replace_line(r"[^\n]*SkipProductId = \d+[^\n]*", "SkipProductId", value)
        elif key == "double":
            replace_line(r"[^\n]*DoubleProductId = \d+[^\n]*", "DoubleProductId", value)
        elif key == "vip":
            replace_line(r"[^\n]*VipGamePassId = \d+[^\n]*", "VipGamePassId", value)
        elif key == "autoclick":
            replace_line(r"[^\n]*AutoClick = \{[^\n]*GamePassId = \d+[^\n]*", "GamePassId", value)
        elif key in ("eggauto", "eggtriple", "eggmulti"):
            replace_line(rf'[^\n]*\{{ id = "{key[3:]}", name = [^\n]*GamePassId = \d+[^\n]*', "GamePassId", value)
    io.open(CONFIG, "w", encoding="utf-8", newline="").write(text)
    print(f"{done} ID Config.luau'ya yazıldı")
    for pass_key in ("vip", "autoclick", "eggauto", "eggtriple", "eggmulti"):
        if pass_key not in mapping:
            continue
        try:
            import json
            import urllib.request

            url = f"https://apis.roblox.com/game-passes/v1/game-passes/{mapping[pass_key]}/product-info"
            data = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=15))
            print(f"{pass_key} game pass doğrulandı: {data.get('Name')} ({data.get('PriceInRobux')} Robux)")
        except Exception as error:  # noqa: BLE001
            print(f"uyarı: {pass_key} game pass çevrimiçi doğrulanamadı ({error}); ID'yi Creator Hub'dan kontrol et")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
    elif sys.argv[1] == "--init":
        write_template()
    else:
        apply_ids(sys.argv[1])
