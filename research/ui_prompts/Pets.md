# Prompt - PETS (envanter, takim, birlestirme)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/PetsPanel.luau` (961 satir - en buyuk panel; kucuk adimlarla ilerle, her adimdan sonra check.py).
**Vurgu rengi**: magic (mor)

## Mevcut sorunlar
- Yari saydam siyah pencere + kalin cerceve; ayrinti kutusu, Pet Team satiri ve kart izgarasi ayri dillerde; nadirlik cerceveleri gurultulu.

## Hedef gorunum
Genis (640) iki bolgeli pencere: SOL ayrinti karti (buyuk pet gorseli, ad, nadirlik cipi, '+N Pet Multiplier when equipped', Equip/Unequip `success`/`secondary`, Merge 'Normal (2/3)' `primary` + ilerleme cubugu), SAG ust 'PET TEAM' satiri (takili petler kartlardan BELIRGIN buyuk: TEAM_SLOT korunur), altinda kart izgarasi. Kart: radius 14, nadirlik rengi (Config.Rarities) 2 px alt serit/cerceve, takili kopyada tek 'E' rozeti, secili kart vurgu cerceve. Baslikta cip '12/50' (cantasi + beyaz +), `ghost` ikon dugmeleri: Equip Best, Unequip All, cop kutusu. Silme modunda secili kart kirmizi cerceve + X.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar: `BuyPetSpace` (cantanin beyaz +'si Shop'u acar), `DeleteButton`, `TrashButton` (cocugu `TrashIcon` = sahibin gri cop kutusu ikonu / Config.Icons.Trash; emoji'ye donme), `EquippedPets`, `OwnedPets`, `PetCapacity`, `PetMultiplier`, `PanelOpen`.
- Kartlar YIGILMAZ (xN yok), 'More +' dugmesi YOK, Fusion paneli YOK; cift tik (0.4 sn) tak/cikar, tek tik secer; '+%N Leg Muscle' yalniz takili petlerde.
- Pet simgesi: `safePetIcon`/`petModelIcon` (lite=true liste kartlarinda; 3B ViewportFrame sayisini artirma). Birlestirme mantigi Catalog.AllPets.
- ctest: `DeleteButton` tiklaninca silme, `TrashButton` modu, `BuyPetSpace` Shop'u acar.

## Icerik / metin iyilestirmeleri
Bos envanter ipucu 'Hatch eggs at the back wall!'. Birlestirme dugmesi sayac gosterir ('Merge 2/3').

## Kabul olcutleri
- 50 pet kartinda kaydirma akici (kart basina <=1 stroke, listede 3B yok); Team satiri kartlardan belirgin buyuk; nadirlik renk-kodu bir bakista okunur.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: ctest, clienttest, raritytest, giftstest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
