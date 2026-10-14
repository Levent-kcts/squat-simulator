# Prompt - WHAT'S NEW karti

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/WhatsNewCard.luau` (179 satir).
**Vurgu rengi**: info (mavi)

## Mevcut sorunlar
- Satir kutulari ve GOT IT dugmesi kalin konturlu; baslik vurgusu zayif.

## Hedef gorunum
Ortada kucuk modal (`fadeScaleIn`): 'WHAT'S NEW' + surum cipi, 3-5 madde satiri (kucuk ikon cipi + tek satir metin), altta tam genislik `primary` 'GOT IT!'. Sakin giris, ekran ortasinda uzun yazi yok.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar: `WhatsNewCard`, `GotItButton`, `Line_*` (adet = #Config.WhatsNew.Lines); oznitelikler `WhatsNewSeen`, `TutorialDone`, `DataLoaded`; show() karti `Visible=true` yapar; Settings'ten yeniden acilir, geri donen oyuncuya bir kez gorunur.

## Icerik / metin iyilestirmeleri
Maddeler kisa, fayda odakli ('New: Daily rewards!').

## Kabul olcutleri
- Tek bakista okunur; 'GOT IT!' belirgin.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: whatsnewcardtest, whatsnewtest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
