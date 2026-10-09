"""Robux'lu antrenman pedlerinin (Coach Prism x250, Coach Shadow x999) FİYAT DAYANAĞI: pedi erken açmak oyunun sonunu (20. aşama) ne kadar öne çeker?
Kullanım: python tools/padsim.py   (tools/simulate.py'nin oyuncu modelini kullanır; Config.Training.Areas'taki pedlere bir 'rebirth N'de açılan x mult bölgesi' ekler)
Fiyat = kazanılan süre x dakika başı Robux (Win'in Robux değeri gibi 0.45-0.6 R$/dk; Config.WinValue). 2026-10-10 sonucu: normalde 10.2 sa; Prism en baştan 2.7 sa, Shadow en baştan 1.6 sa
(yaklaşık 7.5 / 8.6 saat kazanç = ~200-270 / ~235-310 R$) => Prism 199, Shadow 299 (Config.Training.Areas robux alanı; pricetest 150 < fiyat <= 400 denetler).
Not: Shadow robuxOnly olduğu için simulate.py bölgeleri onu ZATEN dışlar; burada elle eklenir.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.argv = ["simulate.py", "14"]
import simulate as sim  # noqa: E402

base = list(sim.ZONES)


def run(zones, label, hours=14):
    sim.ZONES = zones
    p, _log, cap = sim.run(hours)

    def at(stage):
        m = p.milestones.get(stage)
        return f"{m[0] / 3600:.2f} sa (r{m[1]})" if m else "ulaşılmadı"

    print(f"{label}: ilk cap {cap / 60:.1f} dk; aşama 5 {at(5)}; 10 {at(10)}; 15 {at(15)}; 20 {at(20)}")


if __name__ == "__main__":
    run(base, "Normal (pad yok)")
    run(base + [(0, 250)], "Prism x250 en baştan")
    run(base + [(0, 999)], "Shadow x999 en baştan")
    for rebirth in (3, 8, 16):
        run(base + [(rebirth, 250)], f"Prism x250 r{rebirth}'den")
        run(base + [(rebirth, 999)], f"Shadow x999 r{rebirth}'den")
