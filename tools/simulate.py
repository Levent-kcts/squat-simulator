"""Denge simülasyonu: aktif (Auto Click açık) bir oyuncunun ilerleyişini Config.luau'daki sayılarla taklit eder.
Kullanım (proje klasöründe): python tools/simulate.py [saat] [anahtar=değer ...]
Örnek: python tools/simulate.py 12 growth=1.09 level_mult=0.1
Çıktı: rebirth zamanları, zonlar, çarpanlar. Sayıları değiştirmeden önce/sonra kıyaslamak içindir; gerçek oyuncu davranışı farklı olabilir.
TIKLAMA HIZI (2026-10-09'dan beri): her tıklama kası ANINDA verir. Auto Click açıkken saniyede Config.AutoClick.PerSecond (10) tıklama, elle en çok Config.ClickLimit.PerSecond (12),
Auto Click KAPALI ve antrenman pedindeyken pedin kendi otomatik squat'ı hareket başına bir tıklama (~2/sn). Varsayılan oyuncu Auto Click'li (cps = AutoClick.PerSecond);
`cps=2` pasif ped oyuncusu, `cps=12` elle hızlı tıklayan. Duvar seferinde tekme hareket başına bir kez kas verir. `boost=1.3` ortalama iksir/2x güçlendirme etkisi (zaman ortalaması) demektir.
HARCAMA (2026-10-09): oyuncu önce en iyi ayakkabıyı (Win'in %60'ına kadar; duvar hasarı), sonra yumurtayı (Win'in yarısını geçmeyen en pahalı) ve skini alır, aura'yı fiyatı yetince alır (`spend=old` eski sıra: ayakkabıyı neredeyse hiç almazdı,
`shoe_share=`, `egg_share=`). Çıktının son satırları aşama KİLOMETRE TAŞLARIDIR (5/10/15/20. aşamaya ilk ulaşılan zaman ve rebirth sayısı): 20. aşama = oyunun sonu.
Hedef (aktif oyuncu = Auto Click'li): oyunun sonu (20. aşama) günde 1 saat oynayan için 10-15 günde, yani ~10-14 saat; 5. aşama ~5-8 dk, 10. ~1 sa, 15. ~5 sa, 20. ~10 sa; 1. rebirth ~5 dk, 5. ~1.4 sa, 20. ~10 sa.
Denge denemeleri için ek geçersiz kılmalar (2026-10-13 tam sayı çarpan dengelemesi): `hp_scale=` (aşama tabanı canlarını katlar), `hp1=`/`hp2=`/`hp3=` (ilk üç aşamanın tabanı), `pet_scale=` (pet çarpanlarını katlar), `rebirth=old` (eski rebirth: Win/ayakkabı/skin sıfırlanır).
`max_hits=` oyuncunun bir aşamayı kırmak için katlanacağı en çok tekme sayısıdır (varsayılan 40: sınırdaki duvar başına ~8 tekme); küçük değer duvarları 'zayıf' hissettirir.
"""
import math
import random
import re
import sys

import os
CONFIG_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src", "shared", "Config.luau")
SRC = open(CONFIG_PATH, encoding="utf-8").read()


def block(name):
    """Config.luau içindeki `name = {` ... eşleşen `}` bloğunun metnini verir."""
    start = SRC.index(f"\t{name} = {{")
    depth, i = 0, SRC.index("{", start)
    for j in range(i, len(SRC)):
        if SRC[j] == "{":
            depth += 1
        elif SRC[j] == "}":
            depth -= 1
            if depth == 0:
                return SRC[i : j + 1]
    raise ValueError(name)


def num(text, key, default=None):
    m = re.search(rf"\b{key} = ([\d\._eE+-]+)", text)
    return float(m.group(1)) if m else default


# --- Config'ten okunanlar
LEVEL = block("Level")
REBIRTH = block("Rebirth")
BASE_TAPS = num(LEVEL, "BaseTaps")
TAPS_PER_LEVEL = 0
GROWTH = num(LEVEL, "GrowthPerLevel")  # varsa üstel büyüme
TAPS_AT_LEVEL10 = num(LEVEL, "TapsAtLevel10", 22)
CONFIG_POWER = num(LEVEL, "CostPower")  # kuvvet yasası (varsayılan maliyet modeli)
BASE_MAX_LEVEL = num(LEVEL, "BaseMaxLevel")
MAX_LEVEL_PER_REBIRTH = num(LEVEL, "MaxLevelPerRebirth")
LEVEL_MULT = num(LEVEL, "MultiplierPerLevel")
REBIRTH_MULT = num(REBIRTH, "MultiplierPerRebirth")

ITEMS = [(num(l, "price"), num(l, "damage")) for l in block("Items").splitlines() if "price =" in l]
SKINS = [(num(l, "price"), num(l, "bonus")) for l in block("Skins").splitlines() if "price =" in l]
PETS = {m.group(1): float(m.group(2)) for m in re.finditer(r'id = "(\w+)", name = "[^"]+", mult = ([\d\.]+)', block("Pets"))}
AURAS = [(num(l, "winPrice"), num(l, "mult")) for l in block("Auras").splitlines() if "winPrice =" in l]
# Fiyat merdiveni çıktısı için (id, fiyat): iz ve aura'lar
TRAIL_PRICES = [(re.search(r'id = "(\w+)"', l).group(1), num(l, "winPrice")) for l in block("Trails").splitlines() if "winPrice =" in l]
AURA_PRICES = [(re.search(r'id = "(\w+)"', l).group(1), num(l, "winPrice")) for l in block("Auras").splitlines() if "winPrice =" in l]
TRAIL_ROBUX = {re.search(r'id = "(\w+)"', l).group(1): num(l, "robuxPrice") for l in block("Trails").splitlines() if "winPrice =" in l}
AURA_ROBUX = {re.search(r'id = "(\w+)"', l).group(1): num(l, "robuxPrice") for l in block("Auras").splitlines() if "winPrice =" in l}
WIN_VALUE = block("WinValue")  # Win'in Robux değeri: dakika başı kur ve taban

# Pet birleştirme (Config.PetFusion): Cost aynı pet (aynı çarpan ve boy) tek bir üst boya dönüşür, çarpan PowerFactor katına çıkar
FUSION = block("PetFusion")
FUSION_COST = int(num(FUSION, "Cost", 3))
FUSION_MAX = int(num(FUSION, "MaxTier", 4))
FUSION_FACTOR = num(FUSION, "PowerFactor", 3.3)

EGGS = []
for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", price = (\d+),.*?pets = \{(.*?)\} \}', block("Eggs"), re.S):
    pets = [(p.group(1), float(p.group(2))) for p in re.finditer(r'id = "(\w+)", weight = (\d+)', m.group(3))]
    EGGS.append((float(m.group(2)), pets))

TRAINING = block("Training")
ZONES = [(num(l, "rebirths", 0), num(l, "mult")) for l in TRAINING.splitlines() if "mult =" in l and "id =" in l and "robuxOnly" not in l]  # robuxOnly (Coach Shadow) pedi rebirth ile açılmaz: simülasyona girmez

WALL = block("Wall")
GROUP_HEALTH = [float(x) for x in re.search(r"GroupHealth = \{([^}]*)\}", WALL).group(1).split(",") if x.strip()]
HEALTH_GROWTH = num(WALL, "HealthGrowthAfter")
_steps = re.search(r"GroupHealthSteps = \{([^}]*)\}", WALL)
GROUP_STEPS = [float(x) for x in _steps.group(1).split(",") if x.strip()] if _steps else [1.0] * 5
REWARD_GROWTH = num(WALL, "RewardGrowth")
STAGE_COUNT = int(num(WALL, "Count") // num(WALL, "GroupSize"))
SPACING = num(WALL, "Spacing")
BUTTON_GAP = num(WALL, "ButtonGap")

MOVE = {"Kick": 0.4, "Squat": 0.5}
CPS_DEFAULT = num(block("AutoClick"), "PerSecond", 10)

# komut satırından geçersiz kılmalar
args = sys.argv[1:]
HOURS = float(args[0]) if args and "=" not in args[0] else 12.0
OVERRIDES = dict(a.split("=") for a in args if "=" in a)
MAX_HITS = float(OVERRIDES.get("max_hits", 40))  # oyuncunun bir aşama (5 duvar) için katlanacağı en çok tekme sayısı (duvar başına ~8): sınırdaki duvarın 'zorluğu'; eskiden 12 idi, duvarlar 1 tekmede düşüyordu
SPEND_STRATEGY = OVERRIDES.get("spend", "new")
SHOE_SHARE = float(OVERRIDES.get("shoe_share", 0.6))  # ayakkabıya harcanabilecek Win oranı
EGG_SHARE = float(OVERRIDES.get("egg_share", 0.5))
CPS = float(OVERRIDES.get("cps", CPS_DEFAULT))  # saniyedeki tıklama sayısı (bkz. dosya başı)
BOOST = float(OVERRIDES.get("boost", 1.0))  # iksir / 2x güçlendirme zaman ortalaması
if "fusion_factor" in OVERRIDES:
    FUSION_FACTOR = float(OVERRIDES["fusion_factor"])
if "t10" in OVERRIDES:
    TAPS_AT_LEVEL10 = float(OVERRIDES["t10"])
if "base_max" in OVERRIDES:
    BASE_MAX_LEVEL = float(OVERRIDES["base_max"])
if "growth" in OVERRIDES:
    GROWTH = float(OVERRIDES["growth"])
if "level_mult" in OVERRIDES:
    LEVEL_MULT = float(OVERRIDES["level_mult"])
if "rebirth_mult" in OVERRIDES:
    REBIRTH_MULT = float(OVERRIDES["rebirth_mult"])
if "levels_per_rebirth" in OVERRIDES:
    MAX_LEVEL_PER_REBIRTH = float(OVERRIDES["levels_per_rebirth"])
if "hp_growth" in OVERRIDES:
    HEALTH_GROWTH = float(OVERRIDES["hp_growth"])
if "hp_scale" in OVERRIDES:  # aşama tabanı canlarını (GroupHealth) bu kadar katla (2026-10-13 tam sayı çarpan dengelemesi)
    GROUP_HEALTH = [x * float(OVERRIDES["hp_scale"]) for x in GROUP_HEALTH]
for _index in (1, 2, 3):  # hp1 / hp2 / hp3: aşama tabanı canlarını tek tek belirle (ilk üç aşama: Config.Wall.GroupHealth)
    if f"hp{_index}" in OVERRIDES and len(GROUP_HEALTH) >= _index:
        GROUP_HEALTH[_index - 1] = float(OVERRIDES[f"hp{_index}"])
if "pet_scale" in OVERRIDES:  # pet çarpanlarını bu kadar katla (deneme amaçlı)
    PETS = {k: v * float(OVERRIDES["pet_scale"]) for k, v in PETS.items()}
if "price_scale" in OVERRIDES:
    scale = float(OVERRIDES["price_scale"])
    ITEMS = [(p * scale, d) for p, d in ITEMS]
    SKINS = [(p * scale, m) for p, m in SKINS]
    AURAS = [(p * scale, m) for p, m in AURAS]
    EGGS = [(p * scale, pets) for p, pets in EGGS]


POLY_P = float(OVERRIDES["poly"]) if "poly" in OVERRIDES else CONFIG_POWER


def taps_needed(level):
    if POLY_P:
        # kuvvet yasası: level 1 = 10, level 10 = 22 (sahibinin verdiği iki nokta), büyüme üstü p
        return max(1, round(BASE_TAPS + (TAPS_AT_LEVEL10 - BASE_TAPS) / 9 ** POLY_P * (level - 1) ** POLY_P))
    if GROWTH:
        return max(1, round(BASE_TAPS * GROWTH ** (level - 1)))
    return math.floor(BASE_TAPS + (level - 1) * TAPS_PER_LEVEL + 0.5)


def stage_hp(stage):
    if stage <= len(GROUP_HEALTH):
        return GROUP_HEALTH[stage - 1]
    return GROUP_HEALTH[-1] * HEALTH_GROWTH ** (stage - len(GROUP_HEALTH))


def reward(stage):
    r = 0
    for _ in range(stage):
        r = math.floor(r * REWARD_GROWTH) + 1
    return r


rng = random.Random(7)


class Player:
    def __init__(self):
        self.t = 0.0
        self.muscle = 0.0
        self.wins = 0.0
        self.rebirths = 0
        self.pets = []
        self.aura = 1.0
        self.shoe = 1.0
        self.skin = 0.0  # takılı skinin SABİT bonusu (tıklama başı eklenir)
        self.level = 1
        self.progress = 0.0
        self._pet_cache_len = -1
        self.last_stage = 0
        self.last_won = 0
        self.earned = 0.0
        self._pet_cache = 1.0
        self.best_stage = 0
        self.last_hits = 0  # ulaşılan en yüksek aşamayı kırmak için gereken tekme (5 duvar toplam)
        self.next_hits = 0
        self.fronts = {}  # rebirth -> (aşama, o aşama için tekme, sonraki aşama için tekme)
        self.milestones = {}  # aşama -> (ilk ulaşma zamanı sn, o anki rebirth sayısı)

    def cap(self):
        return BASE_MAX_LEVEL + self.rebirths * MAX_LEVEL_PER_REBIRTH

    def pet_mult(self):
        key = (len(self.pets), self.pets[0][0] if self.pets else 0, self.pets[2][0] if len(self.pets) > 2 else 0)
        if self._pet_cache_len != key:
            self._pet_cache_len = key
            self._pet_cache = 1 + sum(mult for mult, _ in sorted(self.pets, reverse=True)[:3])
        return self._pet_cache

    def gain(self):
        level_mult = 1 + LEVEL_MULT * (self.level - 1)
        rebirth_mult = 1 + REBIRTH_MULT * self.rebirths
        return max(1, math.floor(self.pet_mult() * level_mult * rebirth_mult * self.aura + self.skin))

    def zone(self):
        return max(m for r, m in ZONES if r <= self.rebirths)

    def add_muscle(self, amount):
        """Toplam kas artar; level çubuğu (progress) dolunca level atlanır (üst sınırda durur). Artımlı: her çağrıda baştan hesaplanmaz."""
        self.muscle += amount
        cap = self.cap()
        if self.level >= cap:
            return
        self.progress += amount
        while self.level < cap:
            need = taps_needed(self.level)
            if self.progress < need:
                break
            self.progress -= need
            self.level += 1
        if self.level >= cap:
            self.progress = 0

    def buy_egg(self):
        eggs = [e for e in EGGS if e[0] <= self.wins * EGG_SHARE]
        if not eggs:
            return False
        price, pool = eggs[-1]
        self.wins -= price
        total = sum(w for _, w in pool)
        roll = rng.random() * total
        for pet_id, weight in pool:
            roll -= weight
            if roll <= 0:
                self.pets.append((PETS[pet_id], 1))
                break
        else:
            self.pets.append((PETS[pool[-1][0]], 1))
        self.fuse_pets()
        self.pets = sorted(self.pets, reverse=True)[:50]
        return True

    def spend(self):
        """Win'leri harca. Strateji 'new' (varsayılan): aura (kalıcı) > en iyi ayakkabı (Win'in %60'ına kadar; duvar hasarı, rebirth'te sıfırlanır) > yumurta (Win'in yarısını geçmeyen en pahalı; pet kalıcı) > skin.
        Strateji 'old' (spend=old): eski sıra aura > yumurta > skin > ayakkabı (ayakkabıyı hemen hemen hiç almazdı: gerçekçi değil)."""
        for _ in range(500):
            bought = False
            for price, mult in AURAS:
                if mult > self.aura and price <= self.wins:
                    self.wins -= price
                    self.aura = mult
                    bought = True
                    break
            if bought:
                continue
            if SPEND_STRATEGY == "new":
                shoes = [x for x in ITEMS if x[1] > self.shoe and x[0] <= self.wins * SHOE_SHARE]
                if shoes:
                    price, damage = shoes[-1]
                    self.wins -= price
                    self.shoe = damage
                    continue
            if self.buy_egg():
                continue
            skins = [x for x in SKINS if x[1] > self.skin and x[0] <= self.wins * 0.5]
            if skins:
                price, bonus = skins[-1]
                self.wins -= price
                self.skin = bonus
                continue
            if SPEND_STRATEGY != "new":
                shoes = [x for x in ITEMS if x[1] > self.shoe and x[0] <= self.wins * 0.5]
                if shoes:
                    price, damage = shoes[-1]
                    self.wins -= price
                    self.shoe = damage
                    continue
            break

    def fuse_pets(self):
        """Elde aynı (çarpan, boy) petten FUSION_COST tane varsa birleştirir (oyuncu fırsat buldukça birleştirir diye iyimser: hemen). fusion=0 ile kapatılır."""
        if not int(OVERRIDES.get("fusion", 1)):
            return
        changed = True
        while changed:
            changed = False
            counts = {}
            for pet in self.pets:
                counts[pet] = counts.get(pet, 0) + 1
            for (mult, tier), n in sorted(counts.items()):
                if n >= FUSION_COST and tier < FUSION_MAX:
                    for _ in range(FUSION_COST):
                        self.pets.remove((mult, tier))
                    self.pets.append((mult * FUSION_FACTOR, tier + 1))
                    changed = True
                    break
        self._pet_cache_len = -1

    def rebirth(self):
        """2026-10-13: rebirth SADECE level ve bacak kasını sıfırlar; Win, ayakkabı ve skin KALIR (sahibi istedi). Eski davranış: rebirth=old"""
        self.rebirths += 1
        self.muscle = 0.0
        if OVERRIDES.get("rebirth") == "old":
            self.wins = 0.0
            self.shoe = 1.0
            self.skin = 0.0
        self.level = 1
        self.progress = 0.0

    def wall_trip(self):
        """Duvarlara bir sefer: spawn'dan koşar, gücün yettiği en yüksek aşamaya kadar vurur, Win pedine basar. Süre ve kazancı uygular."""
        damage = self.muscle * self.shoe
        stage = 0
        self.last_hits = 0
        self.next_hits = 0
        trip_time = 4.0  # lobiden ilk duvara yürüme
        hits_total = 0
        for s in range(1, STAGE_COUNT + 1):
            total_hp = sum(GROUP_STEPS) * stage_hp(s)  # aşamadaki 5 duvarın toplam canı (duvarlar kendi içinde de artar)
            hits = max(1, math.ceil(total_hp / max(damage, 1)))
            if hits > MAX_HITS:
                self.next_hits = hits  # ulaşılamayan sonraki aşama için gereken tekme
                break
            stage = s
            self.last_hits = hits
            hits_total += hits
            trip_time += (4 * SPACING + BUTTON_GAP) / 16 + hits * MOVE["Kick"]
        self.last_stage = stage
        for milestone in range(self.best_stage + 1, stage + 1):
            self.milestones[milestone] = (self.t, self.rebirths)
        self.best_stage = max(self.best_stage, stage)
        if stage == 0:
            self.last_won = 0
            return 0.0, 0.0
        self.t += trip_time
        # vuruşlar da kas kazandırır (tıklama başı kazanç, bölge çarpanı yok)
        for _ in range(int(hits_total)):
            self.add_muscle(self.gain())
        won = reward(stage)
        self.last_won = won
        self.wins += won
        self.earned += won
        return trip_time, won


def run(hours):
    """Oyuncu: bölgede antrenman yapar, aralıkla duvar seferine çıkar (Win kazan + harca), seviye sınırına gelince son bir seferden sonra rebirth."""
    p = Player()
    horizon = hours * 3600
    log = []
    first_cap = None
    since_trip = 0.0
    trip_every = float(OVERRIDES.get("trip_every", 90))
    while p.t < horizon:
        # Zaman adımı: başta ince (level hızlı atlıyor), sonra kalınlaşır (hız için)
        step = 1 if p.t < 600 else (5 if p.t < 3600 else 20)
        p.add_muscle(p.gain() * p.zone() * step * CPS * BOOST)
        p.t += step
        since_trip += step
        at_cap = p.level >= p.cap()
        if since_trip >= trip_every or (at_cap and since_trip >= 20):
            p.wall_trip()
            p.spend()
            since_trip = 0.0
        if at_cap:
            if first_cap is None:
                first_cap = p.t
            p.fronts[p.rebirths + 1] = (p.last_stage, p.last_hits, p.next_hits)
            log.append((p.t, p.rebirths + 1, p.zone(), p.pet_mult(), p.aura, p.wins, p.muscle, p.shoe, p.skin, p.last_stage, p.last_won, p.earned))
            p.earned = 0.0
            p.rebirth()
    return p, log, first_cap


def fmt(seconds):
    if seconds < 3600:
        return f"{seconds / 60:5.1f} dk"
    if seconds < 86400:
        return f"{seconds / 3600:5.2f} sa"
    return f"{seconds / 86400:5.2f} gün"


if __name__ == "__main__":
    p, log, first_cap = run(HOURS)
    print(f"Seviye maliyeti: {'kuvvet yasası ^%.2f' % POLY_P if POLY_P else ('x%.3f üstel' % GROWTH if GROWTH else 'doğrusal')}, level çarpanı +{LEVEL_MULT}/level, rebirth +{REBIRTH_MULT}, rebirth başına +{MAX_LEVEL_PER_REBIRTH:.0f} level sınırı")
    print(f"Tıklama hızı: {CPS:g}/sn, güçlendirme x{BOOST:g}")
    print(f"İlk level sınırına ({BASE_MAX_LEVEL:g}) ulaşma: {fmt(first_cap) if first_cap else 'yok'}")
    print("rebirth | zaman     | bölge | pet   | aura | skin | ayakkabı | kas (rebirth anı) | aşama | sefer Win | kalan Win | devirde kazanılan Win")
    for t, r, zone, pm, aura, wins, muscle, shoe, skin, stage, won, earned in log:
        if r <= 12 or r % 5 == 0:
            print(f"{r:7d} | {fmt(t)} | x{zone:<5g} | x{pm:<5.1f}| x{aura:<3g} | +{skin:<5g} | x{shoe:<6g} | {muscle:15,.0f}   | {stage:5d} | {won:9,.0f} | {wins:9,.0f} | {earned:,.0f}")
    print("Sınırdaki duvar (rebirth anı: aşama, o aşamayı kırmak için tekme [5 duvar, duvar başına ~/5], sonraki aşama için tekme): " + "; ".join(f"r{r}: S{st}, {h}, {nh:,.0f}" for r, (st, h, nh) in sorted(p.fronts.items()) if r in (1, 3, 5, 8, 12, 16, 20, 25)))
    print("Aşama kilometre taşları (ilk ulaşılan zaman, rebirth sayısı): " + ", ".join(f"{s}: {fmt(t).strip()} (r{r})" for s, (t, r) in sorted(p.milestones.items()) if s % 5 == 0 or s == STAGE_COUNT))
    print(f"{HOURS:g} saat sonunda: {p.rebirths} rebirth, pet çarpanı x{p.pet_mult():.1f}, aura x{p.aura}, bölge x{p.zone():g}")

    # Fiyat merdiveni: bir fiyatı TEK sefer ödülüyle karşılayan ilk aşama ve oraya ilk ulaşma zamanı (biriktirerek daha erken de alınabilir)
    def ladder(name, prices):
        parts = []
        for item_id, price in prices:
            stage = next((s for s in range(1, STAGE_COUNT + 1) if reward(s) >= price), None)
            when = fmt(p.milestones[stage][0]).strip() if stage in p.milestones else "ulaşılmadı"
            parts.append(f"{item_id} {price:,.0f} (aşama {stage}, {when})")
        print(f"{name}: " + "; ".join(parts))

    ladder("Fiyat merdiveni, izler", TRAIL_PRICES)
    ladder("Fiyat merdiveni, aura'lar", AURA_PRICES)

    # Win'in Robux değeri: onu kazanma süresi (dk) x dakika başı kur (en az Floor); yanında Config'teki gerçek Robux fiyatı. Fark büyükse (ya da süre değiştiyse) fiyatları yeniden yuvarla
    def robux_value(name, prices, robux, rate_key):
        rate, floor = num(WIN_VALUE, rate_key), num(WIN_VALUE, "Floor")
        parts = []
        for item_id, price in prices:
            stage = next((s for s in range(1, STAGE_COUNT + 1) if reward(s) >= price), None)
            minutes = p.milestones[stage][0] / 60 if stage in p.milestones else float("nan")
            parts.append(f"{item_id} {max(floor, minutes * rate):.0f} (şimdi {robux[item_id]:.0f})")
        print(f"Robux değeri, {name}: " + "; ".join(parts))

    robux_value("izler", TRAIL_PRICES, TRAIL_ROBUX, "RobuxPerMinuteTrail")
    robux_value("aura'lar", AURA_PRICES, AURA_ROBUX, "RobuxPerMinuteAura")
