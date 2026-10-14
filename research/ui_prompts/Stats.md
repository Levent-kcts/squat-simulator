# Prompt - STATS (carpan dokumu)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/StatsPanel.luau` (181 satir).
**Vurgu rengi**: info (mavi)

## Mevcut sorunlar
- Carpan dokumu duz liste; toplam vurgusu yok.

## Hedef gorunum
Dar-orta pencere: ustte buyuk 'TOTAL x48' karti (GothamBlack 36), altinda kaynak satirlari (Level, Rebirth, Aura, Pets, Skin +N, Friends %, Index %, Potions): sol ad + kucuk ikon cipi, sag deger. Aktif olmayanlar sonuk. Alt: 'Per click' ve 'Wall damage' iki kucuk karti.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Oznitelikler: `AreaMultiplier`, `DamageMultiplier`, `EquippedAura`, `FriendBonus`, `IndexBonus`, `MaxLevel`, `MuscleBoostUntil`, `PerClick`, `PetMultiplier`, `RainbowBoostUntil`, `SkinBonus`, `TotalMultiplier`. Carpan tam sayi gosterimi (Format.multiplier). Hesaba yeni bonus gelirse buraya da satir (CLAUDE.md).

## Icerik / metin iyilestirmeleri
Satir adlari kisa Ingilizce; yuzdeler '+10%'.

## Kabul olcutleri
- Toplam carpani bir bakista, nereden geldigini iki bakista anlatir.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: ctest, clienttest, formattest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
