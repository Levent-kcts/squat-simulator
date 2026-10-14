# Prompt - HUD (sol butonlar, alt level cubugu, sag ust daireler, FREE REWARD, sayaclar)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/init.client.luau` (YALNIZCA HUD gorunum satirlari; 1364 satir), `src/client/RightHud.luau` (466), gerekirse `BoostHud.luau`, `PowerHourHud.luau`, `FeedHud.luau`.
**Vurgu rengi**: her sol dugme kendi rengi; cerceve dili ortak

## Mevcut sorunlar
- Sol 2x3(+) kare dugmeler: koyu zemin + renkli gradyan cerceve (calisiyor) ama kalin siyah dis cizgi/`addOutlinedIcon` agir; sayaclar ve alt level cubugu eski koyu gri + kirmizi-pembe gradyan; sag ust daireler siyah, FREE REWARD / FRIEND BONUS kutulari ayri dilde.

## Hedef gorunum
Sol menu: ayni 2 sutun izgara, her dugme yumusak koyu kart (radius 16) + ince acik cerceve + ikon (sahibin gorselleri, `Config.Icons`) + altinda GothamBold 12 etiket; renk SADECE ikon arkasindaki yumusak tonlu daire/gradyan ve etiket vurgusunda. Hazir bildirimleri (Rebirth nabzi, Gifts/Daily rozeti) korunur. Wins/Rebirth sayaclari: hap cip (ikon + sayi `countTo`, GothamBlack). Alt level cubugu: ince (14 px), cukur zemin, vurgu gradyan dolgu, ortada 'Lv 12  420/900' GothamBold, 'MAX' durumu; level atlayinca %7 buyume (mevcut). Sag ust daireler: koyu kart daire + ince cerceve + sari sayi stili korunur. FREE REWARD / FRIEND BONUS yumusak kart-cip dilinde. Auto Click: `success`/`secondary` hap, 'ONLY R$' rozeti `primary` cip.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- CLAUDE.md'deki 'SOL HUD', 'SAG UST DAIRELER', 'ZINDEX', 'ARAYUZ OLCEGI', 'UST CUBUK PAYI', 'BUYUYUP KUCULEN DUGMELER ORTADAN OLCEKLENIR' maddelerini oku ve uy: `StatsGui > Root` (RootScale), `CornerGui > CornerRoot`, `makeSquareButton(pos, emoji, etiket, {renk1,renk2}, imageId)` kalibi, GRID_PITCH 90, `UIStyle.anchorCenter` nabiz oncesi, Shop `PotionBadge`/`Core` ve Gifts rozeti ayni olcu (28 px), `UpgradeBadge`, `Disc` (sag ust dairenin cocugu; rehber halkasi bunu sarar), `WinsChip`, `PlusButton`, `LoginBadge`, `SpookyButton`, `AutoClickButton`, `Quick_*`, `RightHud`.
- clienttest arar: BackpackButton, GiftsButton, IndexButton, PetsButton, QuestsButton, RebirthButton, SettingsButton, ShopButton, StatsButton, PlusButton, PotionBadge, UpgradeBadge: HEPSI kalmali. Config.UI.Phone (telefon yerlesimi), Performance.mobile kaydirmalari bozulmaz.
- Reddedilenler: isinlanma dugmeleri, tek 'Sounds' dugmesi, ust ilerleme seridi, Quests dairesinde kirmizi rozet, lobi 3B sandik, ekran ortasi yazi, level up yazisi. Kas yazisi 28 punto, kazanc 20, toast 22 ve ustte (0.2): buyutme.

## Icerik / metin iyilestirmeleri
Etiketler: Shop, Rebirth, Settings, Backpack, Pets, Gifts, Daily, (Spooky). Sayilar Format ile.

## Kabul olcutleri
- Telefon (375x812) ve masaustunde sol HUD, alt bar ve sag ust birbirine/Roblox kontrollerine binmez; rehber turu halka/ok hedefleri dogru yerde (guidetourtest).
- Ekran eskisinden daha SADE gorunur (daha az kontur, daha az doygun renk).
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: clienttest, guidetourtest, shopbadgetest, perftest, taptest, powerhourhudtest, feedtest, leveluptest, objectivetest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
