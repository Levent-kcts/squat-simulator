import sys
sys.argv = ["simulate.py", "300"]
import simulate as S

TARGET_R = [1, 2, 3, 5, 8, 10, 12, 17, 24, 32, 45]

def fmt(t):
    if t < 3600: return f"{t/60:.0f}m"
    if t < 86400: return f"{t/3600:.1f}h"
    return f"{t/86400:.1f}d"

def trial(growth, level_mult, rebirth_mult, per_rebirth, hours=24*12):
    S.GROWTH, S.LEVEL_MULT, S.REBIRTH_MULT, S.MAX_LEVEL_PER_REBIRTH = growth, level_mult, rebirth_mult, per_rebirth
    p, log, first = S.run(hours)
    times = {r: t for t, r, *_ in log}
    row = " ".join(f"r{r}:{fmt(times[r]) if r in times else '--'}" for r in TARGET_R)
    return row

if __name__ == "__main__":
    for g in (1.05, 1.07, 1.09):
        for lm in (0.1, 0.25):
            for per in (10, 15):
                print(f"g={g} lvlmult={lm} +lvl/rebirth={per}: {trial(g, lm, 0.5, per)}")
