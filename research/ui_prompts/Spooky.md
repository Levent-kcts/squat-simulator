# Prompt - SPOOKY GYM etkinlik penceresi

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/SpookyPanel.luau` (296 satir); `SpookyButton` init.client'ta (dokunma).
**Vurgu rengi**: warn (turuncu) + magic (mor) etkinlik temasi

## Mevcut sorunlar
- Candy sayaci, kilometre tasi kutulari ve magaza satirlari ayri kutularda; kalin kontur.

## Hedef gorunum
Orta-genis pencere (etkinlik: koyu mor-kahve zemin, turuncu vurgu; yalniz bu panelde panel rengine mor ton): baslikta 'SPOOKY GYM' + geri sayim cipi (`EndsLabel`) + Candy cipi (`CandyLabel`). Ust: kilometre tasi seridi (`Milestone_*`, ilerleme cubugu uzerinde dugumler; alinabilir = CLAIM nabiz). Alt: magaza satirlari (`EventItem_*`): ikon, ad, etki, 'Candy N' alim dugmesi (`primary`, yetmezse `disabled`; deterministik, rastgele YOK).

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar: `SpookyPanel`, `Milestone_*` (adet = #Config.Event.Milestones), `EventItem_*` (adet = #Config.Event.Items), `BuyButton`, `ClaimButton`, `Content`, `CandyLabel`, `EndsLabel`; oznitelikler Candy, CandyTotal, EventClaimed, EventBought, EventPerks, SeasonActive, SeasonEnds, EquippedTrail. Etkinlik bitince pencere/dugme gizlenir.
- Etkinlik magazasi DETERMINISTIK (rastgele/Robux yok).

## Icerik / metin iyilestirmeleri
Kalan sure '2d 14h'; urun etkileri tek satir.

## Kabul olcutleri
- Etkinlik kimligi belli ama bilesenler digerleriyle ayni dilde.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: spookypaneltest, seasoneventtest, eventdecortest, clienttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
