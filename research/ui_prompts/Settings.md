# Prompt - SETTINGS (ayarlar penceresi)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/SettingsPanel.luau` (262 satir).
**Vurgu rengi**: info (mavi) / notr

## Mevcut sorunlar
- Baslik mavi-gri serit + kirmizi kare X, kalin siyah 4 px kontur; satirlar (duz kutular) ve REDEEM hapi ayri dillerde; kod kutusu kucuk (15-16 pt).

## Hedef gorunum
Dar-orta (440) pencere. Baslik notr (ikon `Config.Icons.Settings`). Ustte 'Redeem code' karti (girdi + `primary` REDEEM yan yana; durum satiri girdinin ALTINDA kucuk textDim/yesil/kirmizi). Altta `UIListLayout` ayar satirlari: sol ad GothamBold + kucuk aciklama textDim, sag modern ANAHTAR (hap 52x28, daire dugme; acik=success, kapali=cardDeep; 0.15 sn tween). Son satir: 'What's new' (`secondary`).

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar: `CodeRow`, `CodeBox`, `CodeStatus`, `RedeemButton`, `WhatsNewRow`, `WhatsNewButton`. Config.Settings listesi, oyuncu ozniteligi (false=kapali) + `PlayerStats.setSetting` Remote'u, Redeem akisi ve dakikada 6 deneme mesajlari.
- Eski tek 'Sounds' dugmesi YOK; geri ekleme.
- Pencere yuksekligi satir sayisina bagli: dinamik yap (UIListLayout + AutomaticSize).

## Icerik / metin iyilestirmeleri
Ayar adlari kisa Ingilizce (Sound effects, Music, Gain texts, Camera shake, Name tags, Guide, Server feed); her birine tek satir aciklama.

## Kabul olcutleri
- Anahtarlar animasyonlu, durum (renk + konum) belli; REDEEM mobilde >=44 yuksek.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: clienttest, codestest, whatsnewcardtest, whatsnewtest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
