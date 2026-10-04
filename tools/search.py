import math, random, sys
sys.argv = ["simulate.py", "300"]
import simulate as S

TARGETS = {1: 300, 3: 1500, 5: 4300, 12: 25000, 24: 216000, 45: 780000}  # saniye: hedef rebirth zamanları (aktif oyuncu)
HORIZON_H = 24 * 14
rng = random.Random(11)

def score(growth, lm, rm, per):
    S.GROWTH, S.LEVEL_MULT, S.REBIRTH_MULT, S.MAX_LEVEL_PER_REBIRTH = growth, lm, rm, per
    p, log, _ = S.run(HORIZON_H)
    times = {r: t for t, r, *_ in log}
    err = 0.0
    for r, target in TARGETS.items():
        t = times.get(r, HORIZON_H * 3600 * 4)
        err += abs(math.log(t / target))
    return err, times

best = []
for i in range(int(sys.argv[1]) if len(sys.argv) > 1 else 150):
    g = round(rng.uniform(1.03, 1.10), 3)
    lm = round(rng.choice([0.05, 0.1, 0.15, 0.2, 0.3, 0.5]), 2)
    rm = round(rng.choice([0.25, 0.5, 0.75, 1.0]), 2)
    per = rng.choice([6, 8, 10, 12, 15, 20])
    err, times = score(g, lm, rm, per)
    best.append((err, g, lm, rm, per, times))
best.sort(key=lambda x: x[0])
for err, g, lm, rm, per, times in best[:8]:
    row = " ".join(f"r{r}:{(times[r]/3600):.1f}h" if r in times else f"r{r}:--" for r in TARGETS)
    print(f"err={err:.2f} g={g} lvlmult={lm} rebirth_mult={rm} per={per} | {row}")
