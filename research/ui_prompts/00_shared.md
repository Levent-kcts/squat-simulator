# 00 - ORTAK KURALLAR (tum UI ajanlari once bunu okur)

Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo, kod `src/` altinda). Oyun "+1 Squat Evolution: Smash Walls". Kod yorumlari TURKCE, oyun ici metin INGILIZCE, sohbet/rapor Turkce. Once `CLAUDE.md` ve `research/06_ui_modern.md` dosyalarini oku (tasarim sistemi orada: renk token'lari, font, yaricap, cerceve, golge, animasyon).

## Hedef
Sahibi tum arayuzu "cok yapay ve kotu duruyor" buldu: kalin siyah cerceveli duz kutular, her yerde `FredokaOne`, kaba renkler. Hedef: "Soft Dark Candy" modern sistem: koyu lacivert panel, ince acik cerceve, yumusak golge, Gotham ailesi, tek vurgu rengi, tuş hissi veren dugmeler. SADECE GORUNUM degisir; oyun mantigi, sunucu, oznitelik adlari, Remote cagrilari, hesaplar AYNI kalir.

## Calisma sirasi (onemli)
1. **Once "tasarim sistemi" ajani** `src/client/UIStyle.luau` dosyasini gunceller ve `tools/mocktest/tests/uistyletest.luau` yazar. Panel ajanlari bu bittikten SONRA baslar. Panel ajani `UIStyle.luau`'ya DOKUNMAZ (cakisma); eksik yardimci gerekirse dosyasinin icinde yerel yazar ve raporunda "UIStyle'a eklensin" diye ister.
2. Her panel ajani YALNIZ kendi promptundaki dosyayi (ve o dosyanin dogrudan testini) duzenler. `init.client.luau`'ya sadece HUD ajani dokunur.
3. Paralel calisan ajanlar birbirinin dosyasina yazmaz. git commit ATMA (sahibi/ana ajan atar), `git push` yok.

## Tasarim sistemi ajaninin UIStyle'a EKLEYECEKLERI (geriye uyumlu; mevcut fonksiyonlar silinmez/imzasi degismez: soften, round, lighten, darken, anchorCenter, headerIcon, brickSkin, petIcon, safePetIcon, petModelIcon, eggModelIcon, potionIcon)
Hepsi `pcall` ile korumali, `Performance.low` icin hafif mod (golge/gradyan/parlama yok):

- `UIStyle.Theme` tablosu: `colors` (bg, panel, panelHigh, card, cardHover, cardDeep, text, textDim, textMute, primary/success/info/magic/hot/danger/warn her biri `{base, dark, text}`), `fonts` (title = GothamBlack, bold = GothamBold, body = GothamMedium, brand = FredokaOne), `radius` (panel 20, card 14, button 12, chip 8, input 10), `space` (4/8/12/16/24), `tween` (TweenInfo'lar: press 0.08, hover 0.12, pop 0.2 Back, panelIn 0.28, panelOut 0.18, count 0.5). Hex degerleri `research/06_ui_modern.md` bolum 4.1'den birebir.
- `UIStyle.panel(parent, {name, size, accent, width, shadow=true, position})` -> pencere govdesi (radius 20, 1.5 px beyaz Transparency 0.88 `ApplyStrokeMode.Border` cerceve, `Active=true`, `ClipsDescendants`, `UISizeConstraint` + ekran %92 siniri, istege bagli Shadow kardes Frame). Dondurur `{panel, shadow}` ya da panel (tasarimci karar verir, belgele).
- `UIStyle.header(panel, {title, subtitle, icon=Config.Icons.X, emoji, accent, onClose, chip})` -> 60 px baslik cubugu: sol ikon cipi (icinde `headerIcon`), buyuk harf GothamBlack baslik, sag ghost daire X (kapat), ayirici cizgi. Dondurur `{bar, close, titleLabel}`. Close tiklamasi `onClose` cagirir.
- `UIStyle.card(parent, {size, accent, selected, name})` -> kart (radius 14, 1 px cerceve, UIPadding 12, secili ise 2 px vurgu).
- `UIStyle.button(parent, {text, kind="primary|success|secondary|danger|ghost", size="sm|md|lg", icon, name, onClick})` -> dudakli dugme (3 px koyu alt kenar, basinca UIScale/Position tween, `anchorCenter` ICERIDE cagrilir), `:SetEnabled`/`:SetText` benzeri yardimci doner ya da dugmeye `SetAttribute("Disabled")`; HER ZAMAN gercek `TextButton` olusturur (mocktest `ClassName == "TextButton"` ve ic `TextLabel` arar). Yazi `TextLabel` olarak dugmenin cocugu olabilir (mevcut testler `textsUnder(button)` ile okur).
- `UIStyle.label(parent, {text, role="title|bold|body|caption|number", color, size})`.
- `UIStyle.chip(parent, {text, accent, icon})`, `UIStyle.badge(parent, {text, color})` (sayi rozeti: mevcut 'PotionBadge'/'Gifts' rozet olculerine uygun), `UIStyle.progressBar(parent, {accent, value, text})` (dondurur `{set(value,text)}`), `UIStyle.tabs(parent, {items, accent, onSelect})`, `UIStyle.input(parent, {placeholder})`, `UIStyle.divider(parent)`.
- `UIStyle.press(btn)` (basma geri bildirimi), `UIStyle.pop(obj)` (0.2 sn UIScale 1.06 -> 1), `UIStyle.countTo(label, from, to, formatFn)` (0.5 sn sayma), `UIStyle.fadeScaleIn(frame)` / `fadeScaleOut(frame)` (ortada acilan modaller), `UIStyle.shadow(frame)`.
- `UIStyle.soften` YENI secenek: `style = "flat"` (shine kapali, strength 0.08, stroke ince beyaz) ve eski varsayilan davranis DEGISMEZ (eski cagirilar bozulmasin).
- `UIStyle.safeFont(role)` yok say: `Enum.Font` dogrudan kullan (mock `Enum` proxy'si genel; `FontFace`/`Font.new` KULLANMA, mocktest kirilabilir).
- Test: `tools/mocktest/tests/uistyletest.luau` (her yardimci kurulur, `ClassName` ve `Name` kontrolu, Performance.low yolu, hata durumunda cokmeme). mocktest klasorundeki tests'in nasil calistigi icin ctest.luau'ya bak.

## Panel ajaninin uyacagi KURALLAR
1. **Fontlar**: `Enum.Font.FredokaOne` KALDIR (panel icinde). Baslik/dugme `GothamBlack`/`GothamBold`, govde `GothamMedium` (hep `UIStyle.Theme.fonts.*`). FredokaOne sadece promptunda "marka anlari" diye acikca izin verilen yerde.
2. **Siyah kalin kontur YOK**: `UIStroke{Thickness 3-4, Color black}` yerine ince beyaz-saydam cerceve (Theme). Yazi uzerinde sadece 1-1.5 px, siyah Transparency 0.55 (Contextual) ve yalniz renkli dugme/kart uzerindeki sayilarda.
3. **Renk**: elle `Color3.fromRGB` yerine `UIStyle.Theme.colors.*`. Bir ekranda en cok 3 vurgu rengi; panel kimligi TEK vurgu rengiyle (promptta belirtilir). Nadirlik/skin/pet/iksir renkleri Config'ten gelir, degismez.
4. **Baslik**: `UIStyle.header` (60 px, panelin parcasi, ayri renkli serit YOK, kapat sag ustte ghost daire). `UIStyle.headerIcon` kurali korunur (ikon = acan menu dugmesinin ikonu; baslik yazisina emoji koyma).
5. **Pencere acma/kapama**: sol menu pencereleri `PanelManager.toggle/show/hide/isOpen` (panel.Visible ile oynama!). Ortada acilan modaller (Wheel, Offline, WhatsNew, Rebirth onayi) `UIStyle.fadeScaleIn`. `panel.Active = true` kalir.
6. **Animasyon**: `anchorCenter` OLMADAN UIScale/Size animasyonu yapma; Layout (UIListLayout/UIGridLayout) icindeki nesnede `anchorCenter` kullanma, sabit tutucu icinde ortala. Surekli animasyon en cok 3; `Performance.low`'da nabiz/parlama yok. Her karede calisan dongu ekleme (en az 0.1 sn).
7. **Mobil**: dokunma hedefi >= 44 birim, pencere genisligi `UISizeConstraint` + ekran %92; uzun listede 3B simge yok (`lite = true`); kart basina en cok 1 UIStroke + 1 UIGradient; ViewportFrame sayisini artirma.
8. **ZIndex**: ana arayuz `ZIndexBehavior.Sibling`. HUD parcasina yuksek ZIndex verme; karartma/urun sirasini ZIndex ile belirle. Shadow kardesi panelin arkasinda (ZIndex dusuk) olsun.
9. **Ekran sade**: ekranin ortasina buyuk/uzun yazi yok; bildirim ustte ve kisa; yazi yigini yok. Bilgiyi hiyerarsiyle ver (baslik > deger > ipucu).
10. **Reddedilenleri geri getirme** (CLAUDE.md): Free Reward 3B sandik, Pet Fusion paneli, Pets'te 'More +', isinlanma dugmeleri, tek 'Sounds' dugmesi, Pets kartlarinda 'xN' yigin sayaci, Shop'ta yumurta pass karti, yumurta panelinde fiyat rozeti (fiyat ancak R/T'ye basinca gorunur), Quests dairesinde kirmizi rozet (sari sayi kalir), tavan paneline bloom/parlama, Config.Wall.Themes saydamligi.
11. **Gizli sozlesmeler**: bir `Name`, `SetAttribute/GetAttribute` adi, `Remote`/`Shop:InvokeServer` cagrisi, `Config.*` anahtari DEGISTIRME. Mevcut mock testler ve GuideTour hedef bulma `Name`'e bakar (ornek: `GotIt`, `SkipGuide`, `Disc`, `Core`, `PotionBadge`, `UpgradeBadge`, `BuyPetSpace`, `SpinButton`, `DeleteButton`, `TrashButton`, `TrashIcon`, `GotItButton`, `Starter_<id>`, `LoginDay_*`, `Milestone_*`, `EventItem_*`, `Line_*`, `TrailIcon`, `RewardPet`, `Info_*`, `Quick_*`, `Buy_*`, `Tab_*`, `StarterList`, `WinsChip`, `PlusButton`, `RootScale`, `StatsGui`, `Root`, `CornerRoot`, `CornerGui`, `RightHud`, `AutoClickButton`, `LoginBadge`, `SpookyButton`, `BrickSkin` ZIndex 2...). Yeni ic parca eklersen yeni Name ver; var olani silme/yeniden adlandirma. Testler `rawget(child,"Name")`, `ClassName == "TextButton"`, `Visible`, ic `TextLabel.Text` (ornek 'Multi Open', 'Auto Open', 'Tutorial restarted') ile calisir: bu metinleri degistirme.
12. **Metin iyilestirme** serbest ama: oyun ici metin Ingilizce, kisa, eylem odakli ("Claim", "Equip", "Get Wins"), buyuk harf yalniz baslik ve ana dugmede; mevcut testlerin aradigi sabit yazilari koru.

## Dogrulama (bitti demeden)
```
cd C:\Users\leven\OneDrive\Masaüstü\RobloxOyun
py tools/check.py          # 0 sorun beklenir (luau-analyze + yapi denetleyicisi)
py tools/mocktest.py       # 0 basarisiz beklenir
```
`rojo build` Luau sozdizimini denetlemez; her duzenlemeden sonra `py tools/check.py`. Roblox ozellik/enum adi hatalarini mock yakalamaz: yalnizca bildigin gercek API adlarini kullan (UICorner.CornerRadius, UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border, UIGradient.Rotation/Color/Transparency, UIPadding, UIListLayout.Padding/SortOrder/FillDirection/HorizontalAlignment, UIGridLayout.CellSize/CellPadding, ScrollingFrame.AutomaticCanvasSize/ScrollBarThickness, TweenService:Create). Ekran goruntusu: Studio gerektirir, sahibi bakar; sen kodu ve mock'u dogrula.

## Rapor (Turkce, kisa)
Ne degisti (dosya, yeni gorunum ozeti), hangi Name/oznitelik korundu, calistirilan testler ve sonuclari, UIStyle'a eklenmesini istedigin eksik yardimci varsa listesi, sahibinin Studio'da bakacagi 3 sey.

## Kabul olcutleri (her panel icin ortak)
- `py tools/check.py` 0 sorun; `py tools/mocktest.py` 0 basarisiz.
- Panel dosyasinda `FredokaOne` kalmadi (izinli marka ani haric), `Thickness = 3|4` siyah UIStroke kalmadi.
- Tum renkler/yaricaplar/fontlar Theme'den; ayni panelin tum parcalari ayni dili konusuyor.
- Mantik/oznitelik/Remote degismedi (git diff'te sadece gorunum).
