# Prompt - QUESTS (Daily + New Player sekmeleri)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/QuestPanel.luau` (549 satir).
**Vurgu rengi**: info (mavi)

## Mevcut sorunlar
- Iki sekme (DAILY / NEW PLAYER), ilerleme cubuklari ve CLAIM dugmeleri kalin konturlu; alinmayi bekleyen odul vurgusu kaba; satirlar gurultulu.

## Hedef gorunum
Orta pencere, hap sekme cubugu (`Tab_*`; alinabilir odul varsa sekmede yesil nokta). Satir karti: solda gorev ikon cipi, ortada ad GothamBold + `progressBar` ('2/3'), sagda odul cipi ve CLAIM (`success`, hazirsa nabiz). Biten+alinan: sonuk + tik. Bonus satiri (3 gorev bitince): altin cerceveli kart. Alinmayi bekleyen yeni oyuncu odulu: satir success tonlu + CLAIM altin cerceve (mevcut vurgu mantigi korunur, gorunum yumusar).

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- `Tab_*`, `StarterList`, `Starter_<id>` (ctest: `Starter_squat` icindeki TextButton'a tiklayarak CLAIM), `Stroke` adi, `QuestData`/`StarterState`/`HasAutoClick` oznitelikleri. Pencere alinmayi bekleyen odul varken NEW PLAYER sekmesinde ve o satira kaydirilarak acilir (kurali bozma).
- Sag ust 📜 dairesinde kirmizi rozet YOK (sari sayi). Odul alinca Sfx jingle (okSfx).

## Icerik / metin iyilestirmeleri
Gorev adlari Config metinleri; odul cipi sadece ikon + deger.

## Kabul olcutleri
- Alinabilir / surmekte / bitti 1 saniyede okunur; satir basina <=1 stroke.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: ctest, starterquesttest, objectivetest, guidetourtest, retentiontest, clienttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
