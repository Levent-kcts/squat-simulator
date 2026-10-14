# Prompt - YUMURTA PANELI (client/EggShop pet sansi paneli)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/EggShop.luau` (635 satir) - YALNIZ pede basinca acilan panel (cerceve, kartlar, E/R/T dugmeleri) ve etiketler; Reveal.luau (acilis animasyonu) bu gorevde YOK.
**Vurgu rengi**: primary (sari); kart renkleri nadirlik renkleri

## Mevcut sorunlar
- Kalin konturlu panel; 5 pet karti + 3 dugme ve ipucu satiri karisik; nadirlik renkleri guzel ama zemin gurultulu.

## Hedef gorunum
Modal olmayan, uzaklasinca kapanan orta boy panel: ustte yumurta adi + fiyat cipi, 5 pet karti yatay (`safePetIcon`, nadirlik rengi serit, '%50' sans, '+N' carpan), altta 3 esit dugme: 'E OPEN' (`primary`), 'R AUTO' (`secondary`), 'T x1/x3/x10' (`secondary`); tus harfi kucuk klavye cipi. Win yetmezse Open `warn` 'Get Wins'. Kisitli hesapta (Training Egg) kartlarda sans yerine '25/50' ve 'NEXT' cipi, baslikta '(Training)'.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Pass kurallari: Auto/Multi ucretli ama NORMAL gorunur ve FIYAT YAZMAZ; fiyat yalniz R'ye / kilitli carpana gelen T'ye / kilitli carpanla E'ye basinca gorunur. Panelde fiyat rozeti, 4. dugme, Shop karti YOK. T imleci x1>x3>x10 gezer ama kilitli carpan SECILMEZ (EggRules.step).
- Kart tiklayinca 'AUTO-DELETE' X isareti ve ipucu satiri ('Tap a pet to mark it with an X...'); 'Auto Open' ve 'Multi Open' yazilari (eggpasstest metin arar).
- Oznitelikler `AutoDeletePets`, `EggLuck`, `OwnedPets`, `PaidRandomRestricted`, `PetCapacity`, `TrainingEggs`; sans yuzdeleri GERCEK ve toplam 100 (Luck iksiriyle guncellenir) - ucretli rastgele politikasi.
- Yumurta etiketleri iki ayri kucuk kutu (isim ustte, fiyat pedin ustunde); tek buyuk iki satirli etikete donme.

## Icerik / metin iyilestirmeleri
Ipucu satiri kisa 'Tap a pet to auto-delete it'. Kapasite dolu: 'Pet bag full - open Pets'.

## Kabul olcutleri
- Sans yuzdeleri her zaman gorunur, toplam 100; kilitli ozelligin fiyati dugmeye basmadan GORUNMEZ.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: eggtest, eggpasstest, trainingeggtest, clienttest, worldsgatetest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
