# Prompt 01 - TASARIM SISTEMI (UIStyle) AJANI - ONCE BU CALISIR

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/UIStyle.luau` (tek yazma yetkisi), yeni `tools/mocktest/tests/uistyletest.luau`. Baska panel dosyasina DOKUNMA.
**Vurgu rengi**: (yok - sistem)

## Mevcut sorunlar
- UIStyle yalnizca `soften` (dikey gradyan + ust parlak serit + kalin kenar) sunuyor; her panel kendi `create()` ve `Color3.fromRGB`'ini tasiyor.
- Ortak font/renk/yaricap/golge/dugme dili yok; 16 panel FredokaOne + kalin siyah kontur.

## Hedef gorunum
`research/06_ui_modern.md` bolum 4'u (renk token'lari, tipografi, geometri, cerceve/golge/gradyan, bilesenler, baslik cubugu, animasyon) UIStyle'a donustur. `00_shared.md` 'Tasarim sistemi ajaninin UIStyle'a EKLEYECEKLERI' listesindeki HER yardimciyi yaz: Theme, panel, header, card, button (primary/success/secondary/danger/ghost, sm/md/lg, dudak + basma tween, anchorCenter icerde), label, chip, badge, progressBar, tabs, input, divider, press, pop, countTo, fadeScaleIn/Out, shadow, soften(style='flat'). Performance.low'da golge/gradyan/nabiz yok. Her yardimci pcall'li; hata olursa duz gorunum. Dosya basina Turkce 'Tasarim sistemi' aciklama blogu (kullanim ornekleriyle) yaz.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Mevcut tum fonksiyon adlari ve imzalari birebir calismali: soften, round, lighten, darken, anchorCenter, headerIcon, brickSkin, petIcon, safePetIcon, petModelIcon, eggModelIcon, potionIcon (ctest 'pet_cat modeli varken ViewportFrame' vb. bunlara bakar).
- `soften` varsayilan davranisi DEGISMEZ (yeni `style='flat'` ayri secenek).
- FontFace/Font.new kullanma; mock `Enum` genel proxy.
- `Performance` modulu pcall ile yukleniyor (okPerf); ayni kalibi surdur.

## Icerik / metin iyilestirmeleri
Yardimcilarin varsayilan yazisi yok. Tum renk hex'leri 06_ui_modern.md 4.1'den birebir.

## Kabul olcutleri
- `uistyletest.luau`: her yardimci `ClassName`/`Name` ile dogrulanir; button gercek `TextButton`; header close tiklaninca onClose; Performance.low yolu; bozuk girdide cokmez.
- Mevcut tum mocktest'ler (regresyon) gecer.
- Raporda her yardimcinin imzasini ve kisa kullanim ornegini ver (panel ajanlari okuyacak).
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: uistyletest (yeni), ctest, clienttest, tum mocktest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
