# Prompt - REBIRTH onay ekrani

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/RebirthPanel.luau` (244 satir).
**Vurgu rengi**: hot (pembe)

## Mevcut sorunlar
- Onay ekraninda once/sonra carpan, max level, uyari, level cubugu, Rebirth ve 'SKIP?' dugmeleri kalin konturlu kutularda; uyari ile bilgi ayni agirlikta, dugme yazilari hizasiz.

## Hedef gorunum
Orta (460) modal: baslik 'REBIRTH' (pembe ikon cipi). Ortada iki buyuk kutu 'NOW x3 -> NEXT x4' (yeni deger vurgu rengi + hafif pop); altinda 'Max level 22 -> 32'; level cubugu `progressBar`. Uyari tek ince `warn` seritli kart (mevcut metni koru/kisalt). Alt: buyuk `hot` Rebirth dugmesi (hazirsa nabiz, `anchorCenter`), yanda kucuk `secondary` 'SKIP?' (Robux). Hazir degilse Rebirth `disabled` + ne kadar kaldigi ipucu.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Rebirth mantigi, onay akisi, Robux SKIP cagrisi, `PanelManager` kaydi; hazir olma oznitelikleri; sol menu Rebirth dugmesi nabzi init.client'ta.
- GuideTour 'rebirth' adimi ve Objective hedefi bu pencereyi acmaya yonlendirir: tetikleyici/Name degismesin.
- 'REBIRTH!' ekran ustu basligi Juice'tadir; FredokaOne yalniz bu pencerede dev 'REBIRTH' vurgusu istenirse izinli (marka ani).

## Icerik / metin iyilestirmeleri
Once/sonra carpanlar tamsayi (Format.multiplier); tek uyari satiri; SKIP aciklamasi tek satir.

## Kabul olcutleri
- Once/sonra farki 2 saniyede okunur; tehlikeli eylem (Rebirth) pembe, iptal/kapat ghost.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: clienttest, retentiontest, starterquesttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
