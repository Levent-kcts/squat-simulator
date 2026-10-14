# Prompt - SHOP (Robux urunleri, Win paketleri, iksirler)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/ShopPanel.luau` (466 satir). Acan dugme init.client'ta (dokunma).
**Vurgu rengi**: primary (sari)

## Mevcut sorunlar
- Kalin siyah kontur + FredokaOne; sekme/kart renkleri dagnik, fiyat dugmeleri ile `USE xN` dugmeleri ayni agirlikta.
- Kart ici hiyerarsi zayif (ikon, ad, etki, fiyat ayni kalinlikta); Win paketlerinin 'deger' hissi yok.

## Hedef gorunum
Genis (640) pencere: baslik cubugu (ikon `Config.Icons.Shop`, 'SHOP', sagda Win bakiyesi cipi), altinda hap sekme cubugu (PACKS & MORE / POTIONS / mevcut diger bolumler; secili sekme sari dolgu). Icerik `UIGridLayout` kart izgarasi (telefonda 2 sutun, masaustunde 3-4). Kart: ustte ikon/iksir sisesi (mevcut `potionIcon`), ad GothamBold, etki satiri textDim, altta tam genislik fiyat dugmesi (`primary`; sahip ise `secondary` 'OWNED'; 'coming soon' ise `disabled`). En iyi deger icin kose seridi (BEST VALUE). USE dugmesi `success`. 'Get Wins' durumu `warn`.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Rozetler: `PotionBadge` (kirmizi yuvarlak, ic cocugu `Core`, 28 px, siyah 2 px cerceve, nabiz SADECE Core Size) ve `UpgradeBadge` AYNI kalir (shopbadgetest + clienttest). `ShopPanel.init`'in 3. parametresi shopButton ve rozet mantigi degismez.
- `Buy_*` kartlari, `BadgeText`, `Icon` adlari; oznitelikler `PotionItems`, `HasAutoClick`, `StarterPackOwned`, `PaidRandomRestricted` (kisitli hesapta Luck/Rainbow SATILMAZ - kosulu bozma), `DataLoaded`.
- Shop RemoteFunction cagrilari, `PanelManager` kaydi; EggShop'un `hooks.openShop('packs')` / `toggle(section)` yolu.
- Shop'a yumurta pass karti EKLEME. Fiyatlar Config'ten (pricetest).

## Icerik / metin iyilestirmeleri
Kart basliklari kisa ('Win Pack', 'Luck Potion 15m'); etki tek satir ('2x egg luck for 15 min'); fiyat dugmesinde sadece 'R$ 49'. Sekme adlari buyuk harf. Bos durum tek satir ipucu.

## Kabul olcutleri
- Hangi urun/fiyat/sahiplik durumu bir bakista net; 360 genislikte tasma yok.
- Sekme degisince kaydirma basa doner; kart basina <=1 UIStroke.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: shopbadgetest, clienttest, starterpacktest, pricetest, autopotiontest, autopasstest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
