# Prompt - OFFLINE EARNINGS penceresi

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/OfflinePanel.luau` (283 satir).
**Vurgu rengi**: success (yesil) / primary

## Mevcut sorunlar
- Giriste cikan kazanc penceresi: kas simgesi, Claim, 'DOUBLE IT!' (Robux), X; kalin kontur, dugme agirliklari ayni.

## Hedef gorunum
Ortada kucuk modal (`fadeScaleIn`): ustte 'WELCOME BACK', buyuk kas ikonu, '+12.4K Leg Muscle' (`countTo`) ve 'You were away 3h 12m'. Alt: tam genislik `success` CLAIM; ikincil `primary` 'DOUBLE IT! R$ 29' (daha kucuk). Kapat X ghost. Ekrani kaplamayan sade olcu.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Oznitelikler `OfflineEarnings`, `OfflinePending`, `OfflineSeconds`, `DataLoaded`; `Price` adi; CLAIM ile alinir, Robux DOUBLE IT sunucuda. Config.Offline sinirlari.

## Icerik / metin iyilestirmeleri
Sure '3h 12m'; ikinci dugme tek satir.

## Kabul olcutleri
- Hemen CLAIM edilebilir; DOUBLE IT agresif/clickbait degil, ikincil.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: clienttest, retentiontest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
