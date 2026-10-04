"""Denge parametre araması: rastgele parametre kümeleri dener, aktif oyuncunun rebirth zamanlarını hedef zamanlara en yakın olanları listeler.
Kullanım: python tools/search.py [deneme sayısı] ; hedefler aşağıdaki TARGETS (saniye)."""
import math, random, sys
count = int(sys.argv[1]) if len(sys.argv) > 1 else 150
sys.argv = ["simulate.py", "300"]
import simulate as S

TARGETS = {1: 360, 3: 1500, 5: 4300, 12: 25000, 24: 216000, 45: 780000}  # hedef rebirth zamanları (saniye)
HORIZON_H = 24 * 10
rng = random.Random(11)

def score(base_cap, poly, lm, rm, per, hp):
    S.BASE_MAX_LEVEL, S.POLY_P, S.LEVEL_MULT, S.REBIRTH_MULT, S.MAX_LEVEL_PER_REBIRTH, S.HEALTH_GROWTH = base_cap, poly, lm, rm, per, hp
    p, log, _ = S.run(HORIZON_H)
    times = {r: t for t, r, *_ in log}
    err = 0.0
    for r, target in TARGETS.items():
        t = times.get(r, HORIZON_H * 3600 * 4)
        err += abs(math.log(t / target))
    return err, times

results = []
for _ in range(count):
    params = (
        rng.choice([20, 25, 30, 40]),
        round(rng.uniform(1.2, 3.2), 2),
        rng.choice([0.05, 0.1, 0.2, 0.3]),
        rng.choice([0.25, 0.5, 1.0]),
        rng.choice([5, 6, 8, 10, 12]),
        rng.choice([4, 6, 12]),
    )
    err, times = score(*params)
    results.append((err, params, times))
results.sort(key=lambda x: x[0])
for err, params, times in results[:10]:
    row = " ".join(f"r{r}:{(times[r]/3600):.2f}h" if r in times else f"r{r}:--" for r in TARGETS)
    print(f"err={err:.2f} basecap={params[0]} poly={params[1]} lvlmult={params[2]} rebirth_mult={params[3]} per={params[4]} hp={params[5]} | {row}")
