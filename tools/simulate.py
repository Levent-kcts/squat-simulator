"""Denge simülasyonu: aktif (Auto Click açık) bir oyuncunun ilerleyişini Config.luau'daki sayılarla taklit eder.
Kullanım (proje klasöründe): python tools/simulate.py [saat] [anahtar=değer ...]
Örnek: python tools/simulate.py 12 growth=1.09 level_mult=0.1
Çıktı: rebirth zamanları, zonlar, çarpanlar. Sayıları değiştirmeden önce/sonra kıyaslamak içindir; gerçek oyuncu davranışı farklı olabilir.
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
SKINS = [(num(l, "price"), num(l, "mult")) for l in block("Skins").splitlines() if "price =" in l]
PETS = {m.group(1): float(m.group(2)) for m in re.finditer(r'id = "(\w+)", name = "[^"]+", mult = ([\d\.]+)', block("Pets"))}
AURAS = [(num(l, "winPrice"), num(l, "mult")) for l in block("Auras").splitlines() if "winPrice =" in l]

EGGS = []
for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", price = (\d+),.*?pets = \{(.*?)\} \}', block("Eggs"), re.S):
    pets = [(p.group(1), float(p.group(2))) for p in re.finditer(r'id = "(\w+)", weight = (\d+)', m.group(3))]
    EGGS.append((float(m.group(2)), pets))

TRAINING = block("Training")
ZONES = [(num(l, "rebirths", 0), num(l, "mult")) for l in TRAINING.splitlines() if "mult =" in l and "id =" in l]

WALL = block("Wall")
GROUP_HEALTH = [float(x) for x in re.search(r"GroupHealth = \{([^}]*)\}", WALL).group(1).split(",") if x.strip()]
HEALTH_GROWTH = num(WALL, "HealthGrowthAfter")
REWARD_GROWTH = num(WALL, "RewardGrowth")
STAGE_COUNT = int(num(WALL, "Count") // num(WALL, "GroupSize"))
SPACING = num(WALL, "Spacing")
BUTTON_GAP = num(WALL, "ButtonGap")

MOVE = {"Kick": 0.4, "Squat": 0.5}

# komut satırından geçersiz kılmalar
args = sys.argv[1:]
HOURS = float(args[0]) if args and "=" not in args[0] else 12.0
OVERRIDES = dict(a.split("=") for a in args if "=" in a)
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
        self.skin = 1.0
        self.level = 1
        self.progress = 0.0
        self._pet_cache_len = -1
        self.last_stage = 0
        self.last_won = 0
        self.earned = 0.0
        self._pet_cache = 1.0

    def cap(self):
        return BASE_MAX_LEVEL + self.rebirths * MAX_LEVEL_PER_REBIRTH

    def pet_mult(self):
        key = (len(self.pets), self.pets[0] if self.pets else 0, self.pets[2] if len(self.pets) > 2 else 0)
        if self._pet_cache_len != key:
            self._pet_cache_len = key
            self._pet_cache = 1 + sum(sorted(self.pets, reverse=True)[:3])
        return self._pet_cache

    def gain(self):
        level_mult = 1 + LEVEL_MULT * (self.level - 1)
        rebirth_mult = 1 + REBIRTH_MULT * self.rebirths
        return max(1, math.floor(self.pet_mult() * level_mult * rebirth_mult * self.aura * self.skin))

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

    def spend(self):
        """Win'leri sırayla harca: aura (kalıcı) > yumurta > skin > ayakkabı. Her turda bir şey alınır, alınamayana kadar devam."""
        for _ in range(500):
            bought = False
            # aura: kalıcı, ucuzsa al
            for price, mult in AURAS:
                if mult > self.aura and price <= self.wins:
                    self.wins -= price
                    self.aura = mult
                    bought = True
                    break
            if bought:
                continue
            # yumurta: Win'in yarısını geçmeyen en pahalı yumurta
            eggs = [e for e in EGGS if e[0] <= self.wins * 0.5]
            if eggs:
                price, pool = eggs[-1]
                self.wins -= price
                total = sum(w for _, w in pool)
                roll = rng.random() * total
                for pet_id, weight in pool:
                    roll -= weight
                    if roll <= 0:
                        self.pets.append(PETS[pet_id])
                        break
                else:
                    self.pets.append(PETS[pool[-1][0]])
                self.pets = sorted(self.pets, reverse=True)[:50]
                continue
            skins = [s for s in SKINS if s[1] > self.skin and s[0] <= self.wins * 0.5]
            if skins:
                price, mult = skins[-1]
                self.wins -= price
                self.skin = mult
                continue
            shoes = [s for s in ITEMS if s[1] > self.shoe and s[0] <= self.wins * 0.5]
            if shoes:
                price, damage = shoes[-1]
                self.wins -= price
                self.shoe = damage
                continue
            break

    def rebirth(self):
        self.rebirths += 1
        self.muscle = 0.0
        self.wins = 0.0
        self.shoe = 1.0
        self.skin = 1.0
        self.level = 1
        self.progress = 0.0

    def wall_trip(self):
        """Duvarlara bir sefer: spawn'dan koşar, gücün yettiği en yüksek aşamaya kadar vurur, Win pedine basar. Süre ve kazancı uygular."""
        damage = self.muscle * self.shoe
        stage = 0
        trip_time = 4.0  # lobiden ilk duvara yürüme
        hits_total = 0
        for s in range(1, STAGE_COUNT + 1):
            total_hp = 5 * stage_hp(s)
            hits = max(1, math.ceil(total_hp / max(damage, 1)))
            if hits > 12:
                break
            stage = s
            hits_total += hits
            trip_time += (4 * SPACING + BUTTON_GAP) / 16 + hits * MOVE["Kick"]
        self.last_stage = stage
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
        p.add_muscle(p.gain() * p.zone() * step / MOVE["Squat"])
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
    print(f"İlk level sınırına (20) ulaşma: {fmt(first_cap) if first_cap else 'yok'}")
    print("rebirth | zaman     | bölge | pet   | aura | skin | ayakkabı | kas (rebirth anı) | aşama | sefer Win | kalan Win | devirde kazanılan Win")
    for t, r, zone, pm, aura, wins, muscle, shoe, skin, stage, won, earned in log:
        if r <= 12 or r % 5 == 0:
            print(f"{r:7d} | {fmt(t)} | x{zone:<5g} | x{pm:<5.1f}| x{aura:<3g} | x{skin:<3g} | x{shoe:<6g} | {muscle:15,.0f}   | {stage:5d} | {won:9,.0f} | {wins:9,.0f} | {earned:,.0f}")
    print(f"{HOURS:g} saat sonunda: {p.rebirths} rebirth, pet çarpanı x{p.pet_mult():.1f}, aura x{p.aura}, bölge x{p.zone():g}")
