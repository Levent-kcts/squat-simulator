# 06 - Modern arayuz arastirmasi ve onerilen tasarim sistemi

Tarih: 2026-10-14. Amac: sahibinin "cok yapay ve kotu duruyor" dedigi arayuzu (kalin siyah cerceveli duz kutular, her yerde FredokaOne, kaba renkler) modern, tutarli ve telefonda rahat bir sisteme cevirmek. Kod yazilmadi; bu dosya bulgu + spesifikasyon, ajan promptlari `research/ui_prompts/` altinda.

## 1. Arastirma durumu ve guvenilirlik

Web aramasi bu konuda zayif sonuc verdi (Roblox UI tasarimi cogunlukla Discord/YouTube/DevForum uzerinden konusuluyor; Pet Simulator 99, Grow a Garden, Muscle Legends vb. icin yazili tasarim analizi yok). Dogrulanabilen kaynaklar:

- Roblox UI en iyi uygulamalari ozeti: https://www.creation.dev/blog/roblox-ui-design-best-practices (44x44 px en kucuk dokunma hedefi; tek ya da iki font ailesi, baslik GothamBold, govde GothamMedium; en cok 3 renk: ana, notr, uyari; buton basma geri bildirimi ~0.1 sn; menu gecisleri 0.2-0.3 sn; sayilar ~0.5 sn'de sayarak degissin; Quad/Back easing; ayni anda cok sey animasyonlama; menuler tek tek acilsin, kapat dugmesi hep ayni kosede; 5'ten fazla bolum varsa sekme).
- Piyasadaki simulator UI paketleri (BuiltByBit "Modern Cartoon Simulator UI", "Cartoony UI Kit 25+ Frames", "Stud UI Pack", itch.io "Roblox Simulator Store UI"): https://builtbybit.com/resources/modern-cartoon-simulator-ui.109159/ , https://builtbybit.com/resources/cartoony-ui-kit-25-frames.117327/ , https://builtbybit.com/resources/stud-ui-pack.105141/ . Ortak nokta: parlak, pastel/doygun ama TEK bir koyu ya da acik taban uzerinde; iyi hiyerarsi; kontrol listesi olarak faydali (Daily Rewards, Rebirth, Index, Leaderboard, Quest, Spin Wheel, Shop kadrajlari 25 kare paketinde ayni dilde).
- Trend ozeti: https://www.creation.dev/learn/what-roblox-game-mechanics-are-trending-2026 (mobil-oncelikli, idle dongu; buyuk dokunma hedefleri).
- UIStroke / ApplyStrokeMode / gradient stroke: https://create.roblox.com/docs/en-us/reference/engine/classes/UIStroke.md , https://create.roblox.com/docs/en-us/reference/engine/enums/ApplyStrokeMode.md . Hover/click tween ve UIGradient.Offset ile parlama taramasi: https://devforum.roblox.com/t/uigradient-animation/2637300

Asagidaki "gozlem" maddeleri benim genel bilgimdir (Pet Simulator 99, Grow a Garden, Bubble Gum Simulator Infinity, Muscle Legends, Gym League, Blox Fruits ekranlari uzerinden); dogrudan kaynakli degildir, bu yuzden "trend gozlemi" diye etiketlendi. Sahibinin onceki "referans oyun" ekran goruntuleri (assets/ altinda) ile karsilastirilip sahibe gosterilmeli.

## 2. Iki trend, ayirimi

**A) Soft dark / glass (Pet Sim 99, Blox Fruits shop, Gym League tarzi)**
- Koyu mor-lacivert taban (#14172A civari), paneller %5-15 saydam ya da opak koyu; kartlar bir kademe acik.
- Ince (1-2 px) acik, dusuk opakliktaki cerceve; siyah kalin kontur YOK.
- Renk SADECE vurgu: sari/yesil/pembe buton, nadirlik cerceveleri, rozetler. Panel gri-lacivert, icerik canli.
- Tipografi: kalin geometrik sans (Gotham ailesi), buyuk harf basliklar, sayilar kalin.
- Yumusak golge, iç gradyan cok hafif. Basliklar panelin parcasi (ayri renkli serit degil).
- Artilar: gozu yormaz, ikon/pet renkleri one cikar, tutarli; telefonda okunur. Eksi: oyunun lego/sevimli kimligi biraz soguk kalabilir.

**B) Flat pastel / candy (Grow a Garden, Bubble Gum, "+1 ... Evolution" klonlari)**
- Acik ya da pastel zemin, buyuk yuvarlak koseler (16-24 px), kalin ama RENKLI (koyu tonlu) kontur, altta "dudak" (3-4 px koyu alt kenar) ile dugmeye basilabilirlik.
- Cok canli ve sevimli; cocuk kitlesine uygun. Eksi: kolay "ucuz" durur (su anki sorunumuz tam bu: siyah kontur + her yerde Fredoka + doygun gradyan).

**Oneri: A ile B'nin melezi ("soft dark + candy accents")**. Oyunun kimligi (lego, pastel salon, kucuk cocuk kitlesi) sicak ve neseli; ama panel iskeleti A gibi sakin koyu olmali ki kartlar/ikonlar parlasin. Dugmelerde B'nin "alt dudak"i korunur (tuş hissi), cerceveler ince acik. Boylece: modern + oyuna uygun + az gorsel gurultu (sahibin "ekran sade kalsin" kurali).

## 3. Mevcut durum (kod okumasindan)

- 16 panel dosyasinin HEPSI `Enum.Font.FredokaOne` (GiftsPanel'de tek `GothamMedium`). Ortak font/renk/yaricap sabiti yok; her dosya kendi `create()` yardimcisini ve kendi `Color3.fromRGB` degerlerini tasiyor.
- Kalin siyah UIStroke (3-4 px) hem panelde hem dugmede (`UIStroke{Thickness=4, Color=black}`), ustune `UIStyle.soften` (dikey gradyan + ust parlak serit) biniyor: "plastik" gorunum.
- Baslik: panelin ustunde duz renkli (mavi-gri, sari...) serit + sag ustte kirmizi kare X. Her panel farkli baslik rengi, ortak dil yok.
- `UIStyle.soften(obj,{radius,strength,shine,stroke})`, `anchorCenter`, `headerIcon`, `brickSkin`, `petIcon/safePetIcon/petModelIcon/eggModelIcon`, `potionIcon`, `lighten/darken/round` mevcut. Yeni sistem BUNLARA EK yapilir, hicbiri silinmez (cok sayida modul ve mock test cagiriyor).
- PanelManager: sol menu pencereleri soldan kayarak gelir (0.34 sn Quint). Bu kalmali.
- Performance.low (telefon): gradyan/golge/parlama azaltilabilmeli; yeni yardimcilar `Performance.low` okumali.

## 4. ONERILEN ORTAK TASARIM SISTEMI ("Soft Dark Candy")

Hepsi mevcut API'lerle (Frame, UICorner, UIStroke, UIGradient, UIPadding, UIListLayout, UIGridLayout, TweenService, Enum.Font) uygulanir. FontFace/Font.new KULLANMA (mock `Enum` proxy'si genel ama FontFace tasimaz; ayrica `.Font` yerine `.FontFace` mock testlerini kirabilir).

### 4.1 Renk token'lari (UIStyle.Theme.colors)

| Token | Hex | Kullanim |
|---|---|---|
| bg | #12142A | Karartma/arka (BackgroundTransparency 0.35 ile) |
| panel | #1B1F3B | Pencere govdesi |
| panelHigh | #232849 | Ic bolum, sekme cubugu zemini |
| card | #2A3059 | Kart / satir |
| cardHover | #343B6B | Hover / secili degil ama odakta |
| cardDeep | #181B33 | Cukur (girdi kutusu, ilerleme cubugu boslugu) |
| line | #FFFFFF @ alpha 0.10 (Transparency 0.9) | Ince cerceve, ayirici cizgi |
| text | #F5F7FF | Ana yazi |
| textDim | #A9B2DA | Ikincil yazi |
| textMute | #6F79A8 | Devre disi / ipucu |
| primary (sari) | #FFC83D, koyu alt #D9961A, yazi koyu #3A2A00| Ana CTA, Win, odul |
| success (yesil) | #3FDC85, alt #1FA85B | Claim, sahip, acik |
| info (mavi) | #4DA6FF, alt #2F78D1 | Bilgi, secili sekme |
| magic (mor) | #9B6CFF, alt #6C42D6 | Pet, Index, aura |
| hot (pembe) | #FF4D93, alt #D42B70 | Rebirth, ozel |
| danger (kirmizi) | #FF5468, alt #CC2F44 | Kapat, hata, sil |
| warn (turuncu) | #FF9B3D | Uyari, sinirli sure |
| rarity | Config.Rarities renkleri (degismez): yesil/camgobegi/mor/altin/pembe | Nadirlik |

Kural: bir ekranda ayni anda en cok **uc vurgu rengi** gorunsun (sahibin "ekran sade" ilkesi + creation.dev "3 renk" onerisi). Panel kimligi renkli baslik seridiyle DEGIL, **tek bir vurgu rengi** (baslik ikon cipi + ana buton + secili sekme) ile verilir: Shop sari, Rebirth pembe, Pets mor, Gifts yesil, Quests mavi, Settings notr (info), Index mor, Daily turuncu, Spooky turuncu-mor.

### 4.2 Tipografi (UIStyle.Theme.fonts)

- **Baslik / dugme / buyuk sayi**: `Enum.Font.GothamBlack` (baslik buyuk harf, 20-24 pt), dugme yazisi `GothamBold` 16-18.
- **Govde / kart etiketi**: `Enum.Font.GothamMedium` 14-16; ikincil 12-13 `GothamMedium` renk textDim. En kucuk yazi 12 (telefonda ArayuzOlcegi zaten buyutuyor).
- **FredokaOne**: sadece marka anlari: yukleme ekrani basligi, "REBIRTH!" / yumurta "LEGENDARY!" dev basliklari, tabela/3B dunya yazilari. Paneller ve dugmeler Gotham.
- `TextScaled` yerine sabit `TextSize` + `UITextSizeConstraint`/`TextTruncate = AtEnd` tercih et (sayi tasmasini onler). Sayilar icin `Format` kullan (zaten var).
- Yazi golgesi: kalin siyah kontur yerine `UIStroke` (ApplyStrokeMode.Contextual) 1.2-1.5 px, renk siyah, Transparency 0.55; SADECE kartlarin/ikonlarin ustundeki sayilarda ve renkli dugme yazilarinda. Panel govde yazisinda stroke yok.

### 4.3 Geometri (UIStyle.Theme.radius / space)

- Koseler: pencere 20, kart 14, dugme 12 (veya hap = 999), kucuk cip/rozet 8, girdi kutusu 10, daire dugme tam yuvarlak.
- Bosluk olcegi: 4 / 8 / 12 / 16 / 24. Pencere ic kenar bosluğu 16, kart ici 12, kartlar arasi 10. UIPadding + UIListLayout/UIGridLayout ile (elle Position hesabi azalsin).
- En kucuk dokunma hedefi 44x44 (arayuz birimi, UIScale oncesi); kapat dugmesi 40x40.
- Pencere genislikleri: dar 360, orta 460, genis 640; `UISizeConstraint` + ekran %92 ust sinir (telefon).

### 4.4 Cerceve, golge, gradyan

- **Cerceve**: pencere 1.5 px, `Color = beyaz`, `Transparency = 0.88`, `ApplyStrokeMode = Border`. Kart 1 px ayni. Secili/odak/CTA kart: 2 px vurgu rengi (Transparency 0). Siyah 3-4 px kontur KALDIRILIR.
- **Golge**: pencere altinda tek bir "Shadow" Frame: `Size = panel + 0,0`, `Position = (0, +8)`, siyah `BackgroundTransparency 0.72`, ayni UICorner, `ZIndex = panel.ZIndex - 1` (Sibling modunda panelin ARKASINDA kardes; ZIndex kuralina dikkat). Kartlara golge yok (gurultu/performans). Performance.low'da golge yok.
- **Gradyan**: tek yonlu, hafif: kartta `strength 0.06`, dugmede `0.12` (ust renk -> alt biraz koyu). Parlak ust serit ("Shine") panelde ve kartta KAPALI; sadece primary dugmede ve odul kartinda %50 daha silik acik kalir. Buyuk renkli gradyan zeminler (mavi-gri baslik seridi vb.) kaldirilir.
- **Dugme "dudagi"**: dugme govdesinin altinda 3 px koyu alt kenar (ayni UICorner'li ikinci Frame, `darken(color, 0.35)`), basinca govde 2 px asagi kayar (Position) ve dudak gorunmez olur; dokunsal his, B tarzi, ucuz durmaz cunku cerceve inceldi.

### 4.5 Bilesen spesifikasyonu

**Pencere (Panel)**: `Frame` panel rengi, radius 20, ince cerceve, golge; `ClipsDescendants = true`; ustte Baslik cubugu (4.6); altinda icerik `ScrollingFrame` (`ScrollBarThickness 4`, ScrollBarImageColor textMute, `AutomaticCanvasSize = Y`, `ScrollingDirection = Y`); `Active = true` (pencereye tiklamak squat baslatmasin: MEVCUT kural). PanelManager.register ile.

**Kart**: card rengi, radius 14, 1 px ince cerceve, UIPadding 12; secili: vurgu cerceve 2 px + cardHover. Alt bilgi satiri textDim 12. Fiyat/odul "cip"i: radius 8, koyu sari/yesil zemin.

**Dugme turleri** (`UIStyle.button(parent,{kind=...})`):
- `primary`: sari govde (#FFC83D -> #F0A91F), koyu yazi (#3A2A00) GothamBlack, dudak #B9760F.
- `success`: yesil, beyaz yazi.
- `secondary`: card zemini + ince cerceve + beyaz yazi (kapat, iptal, ikincil).
- `danger`: kirmizi.
- `ghost`: sadece yazi + hover arka plan (kapat X icin dairesel ghost).
- `disabled`: govde card, yazi textMute, dudak yok, `AutoButtonColor=false`, ipucu metni ("Need 120 Wins").
Boyut presetleri: sm 36, md 44, lg 52 yukseklik. Yazi kisaltilmaz (UITextSizeConstraint).

**Rozet / cip**: sayi rozeti (sag ust) = mevcut 'PotionBadge' olcusu korunur; durum cipi ("OWNED", "EQUIPPED", "NEW") radius 8, yari saydam vurgu rengi zemin + vurgu renginde yazi 11-12 GothamBold.

**Ilerleme cubugu**: cukur cardDeep, radius tam, dolgu vurgu gradyani, ince ic highlight yok; yazi cubugun UZERINDE ortada 12-13 GothamBold + hafif stroke.

**Sekme (Tabs)**: panelHigh zemin hap kapsayici (radius 12, padding 4); secili sekme vurgu dolgulu hap, digerleri ghost; 0.15 sn renk tween.

**Girdi**: cardDeep zemin, radius 10, 1 px cerceve, odakta vurgu cerceve; placeholder textMute.

**Ayirici**: 1 px beyaz Transparency 0.92.

### 4.6 Baslik cubugu

Yukseklik 60, panel renginin PARCASI (ayri renk yok), alt ayirici cizgi. Sol: 40x40 yumusak vurgu-tonlu radius 12 cip icinde mevcut `UIStyle.headerIcon` (ayni menu ikonu kurali KORUNUR). Yanda baslik GothamBlack 22 buyuk harf (UPPER), altinda istege bagli 12 textDim alt baslik (or. "Spend your Wins"). Sag: 36x36 ghost daire X (card zemini, hover danger). Kapat her pencerede AYNI konumda. Sayac/para (or. Pets "12/50") baslikta kapat dugmesinin soluna cip olarak.

### 4.7 Animasyon (UIStyle.Theme.tween)

- Panel ac/kapa: PanelManager'daki sol kayma KALIR (0.34 Quint / 0.22 Quad). Ortada acilan pencereler (Wheel, Offline, WhatsNew, Rebirth onayi): `UIScale 0.92 -> 1` + fade 0.22 sn `Back Out`, kapanis 0.15 sn `Quad In`.
- Dugme basma: 0.08 sn `UIScale 0.96` (anchorCenter SART) veya dudak kaymasi; birakinca 0.12 `Back Out` ile 1.
- Hover (yalniz fare, `UserInputService.TouchEnabled=false`): renk +%6 acik, 0.12 sn.
- Kart girisi: liste ilk acildiginda stagger YOK (performans); sadece yeni gelen/odul alinan karta 0.2 sn pop (UIScale 1.06 -> 1).
- Sayi sayma 0.5 sn Quad Out (Win, kas, Candy).
- Nabiz (hazir odul): UIScale 1 <-> 1.06, 0.7 sn Sine, SADECE `anchorCenter`li ya da sabit tutucu icinde (mevcut kural).
- Ayni anda en cok 3-4 surekli animasyon; Performance.low'da nabiz ve parlama taramasi kapali.

### 4.8 Mobil / performans

Dokunma hedefi >= 44; panel genisligi ekran %92 ile sinirli; govdede 3B ViewportFrame listesi yok (mevcut kural); UIStroke/UIGradient sayisini kart basina en cok 2 tut (kart: 1 stroke, 0-1 gradyan); golge sadece pencere ve buyuk modallarda.

## 5. Sahibinin kurallari (CLAUDE.md'den) - yeni tasarimin UYMASI gerekenler

- Ekran sade kalsin; ekranin ortasina uzun/buyuk yazi yok; bildirimler ustte ve kisa.
- Ayakkabi/skin vb. oyun mantigina dokunma; SADECE gorunum. Sunucu mantigi, ozniteliklerin adlari ve anlami degismez.
- `UIStyle.soften`, `UIStyle.anchorCenter` (nabiz/basma animasyonundan once), `UIStyle.headerIcon` (pencere ikonu = acan menu ikonu, baslik yazisina emoji koyma), `UIStyle.safePetIcon` (duz daire yok), `PanelManager.toggle/show/hide/isOpen` (panel.Visible ile oynama).
- Layout (UIListLayout/UIGridLayout) icindeki nesnelerde anchorCenter KULLANMA, sabit tutucu ic ice.
- ZIndex: StatsGui Sibling; HUD parcasina yuksek ZIndex verme, pencereleri kendi ZIndex'iyle ustte tut. Yeni golge/karartma `ZIndex` ile sirala, olusturma sirasina guvenme.
- Reddedilenler geri gelmesin: 3B Free Reward sandigi, Pet Fusion paneli, 'More +' dugmesi, isinlanma dugmeleri, tek 'Sounds' dugmesi, ekranda yazi yigini, saydam duvar temalari, Pets kartlarinda yigin ('xN') sayaci, Shop'a yumurta pass karti, yumurta panelinde fiyat rozetleri (R/T fiyati gorunmez), kirmizi rozet Quests'te (sari sayi kalir), Shop rozeti kirmizi yuvarlak kalir.
- Eski kare koseli, duz, kalin kenarli gorunume DONME; ama yeni sistem de "kalin siyah kontur" kullanmaz (sahibin yeni istegi).
- Arayuz ust katmani: yukleme ekrani DisplayOrder 1000, rehber 800, yumurta acilisi 60; bunlari bozma.
- Arayuz birimi/UIScale: Position/Size offset'leri olcekten ONCE (Config.UI); yeni parca `StatsGui > Root` altina; sag ust daireler `CornerRoot`.

## 6. Uygulama sirasi

1. "Tasarim sistemi ajani": `UIStyle`'a Theme + yardimcilari ekler (bkz. `ui_prompts/00_shared.md`), yeni `uistyletest.luau` yazar; kimseye dokunmaz.
2. Sonra panel ajanlari PARALEL (her biri kendi dosyasi). Cakisma noktasi: `init.client.luau` (sadece HUD ajani dokunur), `UIStyle.luau` (panel ajanlari DOKUNMAZ; eksik yardimci gerekirse kendi dosyasinda yerel yazar ve raporda ister).
3. Entegrasyon turu: `py tools/check.py`, `py tools/mocktest.py`, Studio'da sahibin gozu. Ekran goruntusu moduyla (H tusu) once/sonra kiyas.
