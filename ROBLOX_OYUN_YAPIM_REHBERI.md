# Roblox Oyun Yapım Rehberi

Bu rehber "+1 Squat Evolution: Smash Walls" projesinden (4-22 Ekim 2026, 375+ commit) çıkarılmış derslerden oluşur. Yeni bir Roblox oyununa başlarken bu dosyayı yeni proje klasörüne kopyala ve Claude'a ilk mesajda okut. Her başlık, bu projede bir kez yaşanmış, zaman kaybettirmiş ya da işe yaramış bir şeyden gelir.

> Kısa özet: kodu Claude yazar (Rojo + Luau). Her değişiklikten sonra otomatik denetim ve test çalışır, sonra GitHub'a gönderilir. Sahibi Studio'da dener ve yayınlar. Asıl iş oyunu yapmak değil, insanların oyunu bulmasını ve geri gelmesini sağlamaktır.

---

## 0. Bu dosya nasıl kullanılır

1. Yeni proje klasörünü aç: `Masaüstü/<OyunAdi>`. Yolda Türkçe karakter OLMASIN (bkz. §5.10).
2. Bu dosyayı klasöre kopyala ve Claude'a şunu söyle: "ROBLOX_OYUN_YAPIM_REHBERI.md'yi oku, §1'deki araçları kur, §2'deki iskeleti kur."
3. Yeni oyunun tarifini (§12'deki soru listesine göre) ayrı bir `OYUN_TARIFI.md` dosyasına yaz. Claude her oturumda onu ve `CLAUDE.md` dosyasını okusun.

---

## 1. Kurulacak araçlar (hepsi ücretsiz)

| Araç | Ne için | Nasıl kurulur / not |
|---|---|---|
| **Roblox Studio** | Oyunu çalıştırmak, test, yayın | roblox.com/create. Arayüz Türkçe olabilir: Claude elle yapılacak adımları Türkçe menü adlarıyla anlatmalı (§9). |
| **Git** + **GitHub** (özel depo) | Yedek ve geri dönüş | `winget install Git.Git`; GitHub'da ÖZEL depo aç. Yerel dal `master`, uzak dal `main` olabilir (`git push origin master:main`). |
| **Rokit** | Roblox araç zinciri yöneticisi | github.com/rojo-rbx/rokit. Proje kökünde `rokit.toml`. |
| **Rojo 7.7.x** (Rokit ile) | Kodu dosyalardan Studio'ya senkronlar | `rokit add rojo-rbx/rojo@7.7.1`. Studio'daki Rojo eklentisinin sürümü AYNI olmalı. Port 34872. |
| selene, StyLua, lune, wally, luau-lsp (Rokit ile) | Linter, biçimleyici, Roblox türleriyle tür denetimi | `rokit add kampfkarren/selene` vb. StyLua'yı eski koda TOPLU uygulama: diff patlar. |
| **luau-analyze** + **luau.exe** | Sözdizimi denetimi + kodu Roblox'suz çalıştırıp test etmek | github.com/luau-lang/luau sürümlerinden `luau-windows.zip`, `%USERPROFILE%\.luau\` içine aç. |
| **Python** (`py` başlatıcısı) | Denetim, test, simülasyon, kurgu betikleri | Bu makinede `python` YOK, `py` kullan. |
| **VS Code** + eklentiler (Luau LSP, Selene, StyLua, Rojo) | İsteğe bağlı kod görüntüleme | winget |
| **Blender 5.x** | 3B modeller, şeffaf 2B resim çekimi, ses üretimi (Python'u ile) | blender.org. Komut satırından `blender -b -P betik.py -- <MUTLAK yol>`. |
| **ffmpeg** | Ekran kaydı (gdigrab), video kurgusu | BtbN "ffmpeg-master-latest-win64-gpl" zip'i, örn. `C:/Users/leven/tools_dl/`. |
| **OBS Studio**, **CapCut** | Video çekimi ve elle kurgu | winget. NVIDIA kartta OBS'de NVENC 1080p60. |
| **Google Chrome** + **Claude in Chrome** eklentisi | Claude'un Creator Hub, Gemini, Roblox sitesinde iş yapması | Sahibi Chrome'da kendi hesaplarıyla giriş yapar. Claude ŞİFRE GİRMEZ. |
| **Gemini** (web) | Simge, kapak ve küçük resim çizimi | Sahibin hesabı. Claude promptu yazar ve Chrome'dan üretir, indirir. |
| **Roblox Studio MCP** (resmi) | Claude'un Studio'da Play'e basması, Output okuması, ekran görüntüsü alması, Lua çalıştırması | Proje kökünde `.mcp.json` (§2). Studio'da BİR KEZ: Assistant (sağ üst parıltı simgesi) > `…` > Ayarlar > MCP Sunucuları > "Enable Studio as MCP server". Sonra Studio ve Claude yeniden başlatılır. |
| **graphify** (isteğe bağlı) | Büyük kod tabanında bilgi grafiği | `uv tool install graphifyy`. Proje büyüyünce faydalı. |
| Studio eklentileri | Rojo (zorunlu), UI Labs (isteğe bağlı) | F3X / Archimedes sahibinin hesabıyla Araç Kutusu'ndan. Moon Animator ücretli, gerek yok. |

**Kurulmayanlar ve nedeni:**
- Topluluk Studio MCP'leri: resmi olan yetiyor, ayrıca güvenilmez.
- DaVinci Resolve: kayıt formu istiyor.

---

## 2. Proje iskeleti (ilk gün kurulacak)

```
OyunAdi/
  CLAUDE.md            # Claude'un her oturumda okuduğu KURALLAR (oyun kuralları, mimari, sahibin kararları)
  README.md            # DEVİR DOSYASI: nasıl çalıştırılır, durum, yapılacaklar, yapılanlar
  OYUN_TARIFI.md       # sahibinin oyun tarifi (bu rehberin §12'sine göre)
  default.project.json # Rojo eşlemesi
  rokit.toml  selene.toml  .mcp.json  .gitignore
  src/
    loading/           -> ReplicatedFirst.Loading   (yükleme ekranı başlatıcısı)
    shared/            -> ReplicatedStorage.Shared  (Config, Layout, Progression, Catalog, Format)
    server/            -> ServerScriptService.Server (init.server.luau + modüller)
    client/            -> StarterPlayerScripts.Client (init.client.luau + modüller)
  tools/
    check.py           # luau-analyze + yapı denetimi (her değişiklikten sonra)
    mocktest.py + mocktest/  # Roblox taklitleriyle Luau mantık testleri
    typecheck.py       # luau-lsp (gerçek Roblox türleri) + Selene
    simulate.py        # ekonomi/tempo simülasyonu
    preflight.py       # yayın öncesi otomatik kontrol
    studio_mcp.py      # MCP araçları oturumda yüklü değilse Bash'ten Studio'ya bağlanır
    blender/ icons/ sounds/ animations/  # varlık üreticileri
  assets/              # üretilen modeller, simgeler, sesler, kapaklar, pazarlama
  research/            # pazar araştırmaları
```

`.mcp.json` dosyası:

```json
{ "mcpServers": { "Roblox_Studio": { "command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"] } } }
```

**Mimari ilkeleri:**
- **Tüm denge sayıları tek yerdedir:** `shared/Config.luau` (fiyat, can, şans, süre, kimlikler). Koda sayı gömme.
- **Ortak hesaplar `shared/` içindedir** (Layout, Progression). Sunucu ve istemci aynı fonksiyonu kullanır.
- **Görsel her şey kodla üretilir** (lobi, duvarlar, raflar). Studio'da elle model yerleştirme. Tek istisna Blender modelleridir; onlar `ReplicatedStorage.GameModels` altında durur.
- **İsteğe bağlı modüller korumalı yüklenir:** `safeInit(loadOptional(...))` ya da `pcall` (efekt, ses, rehber, etiket). Biri hata verirse oyun çalışmaya devam eder. Bu proje birçok kez bununla kurtuldu.
- **Sunucuya ait şeyler:** para, skor, hasar, satın alma, çark sonucu, yumurta sonucu HER ZAMAN sunucuda hesaplanır. İstemci sadece ister ve gösterir.
- **Oyuncuya özel dünya parçaları istemcide kurulur.** Bu projede her oyuncunun kendi duvarları vardı: sunucu sadece canı tuttu, Part'ları her oyuncu kendi ekranında kurdu.
- **Test paneli (DEV):** Studio'da her zaman açık. Canlı oyunda `Config.DevTools.Enabled = false`, yetki kontrolü sunucuda. Ekran görüntüsü modu (H tuşu, sadece sahip için) oyun sayfası görselleri için çok işe yaradı.

---

## 3. Her değişiklikten sonra (zorunlu döngü)

1. `py tools/check.py` sonucu **0 sorun** olmalı. `rojo build` Luau sözdizimini DENETLEMEZ: Config'e kaçan bir `},` yüzünden sunucu hiç açılmadı, ekran boş kaldı.
2. `py tools/mocktest.py` sonucu **0 başarısız** olmalı. Yeni modül ya da akış eklenince `tools/mocktest/tests/` altına test yaz.
3. Roblox API'si kullanan değişiklikten sonra `py tools/typecheck.py` çalıştır. Yeni bulgulara bak.
4. Studio MCP bağlıysa Claude kendisi doğrular:
   - Play'e basar (`start_stop_play`).
   - Output'ta hata arar (`get_console_output`).
   - Görünümü kontrol eder (`screen_capture`).
5. CLAUDE.md'yi (kural ya da karar değiştiyse) ve README.md'yi (durum ya da yapılacaklar) güncelle. Eskiyen satırları SİL.
6. Commit at, sonra `git push`. Commit mesajı kısa ve Türkçe olsun.
7. Sahibine iki şey söyle:
   - "Studio'da şuna bak" (somut test adımları);
   - ayar gerekirse hangi Config sabitini değiştireceği.

**Testlerin yakalayamadıkları:** görünüm, Roblox özellik ve enum adları, gerçek dokunmatik. Bunlar ya Studio'da (sahibi ya da MCP) ya da typecheck ile görülür.

---

## 4. Veri ve kayıt güvenliği (bozulursa oyuncu ilerlemesi gider)

- **Kayıt yüklenemezse o oturumda KAYDETME.** Yoksa eski ilerleme boş veriyle ezilir.
- **`Config.Save.StoreName` YAYINDAN SONRA ASLA değişmez:** değişirse herkesin kaydı sıfırlanır. Test verisi canlıya karışmasın diye yayından hemen önce bir kez yeni ada geçilir (`_v2`).
- **Oturum kilidi** kayıtta `Lock = {id, t}` olarak tutulur. Oyuncu hızla sunucu değiştirince eski sunucu yeni ilerlemeyi ezmesin diye:
  - taze kilit varsa girişte en çok 24 sn beklenir;
  - 120 sn'den eski kilit devralınır;
  - kilidi kaybeden sunucu o oyuncu için kaydetmeyi bırakır.
- **Kayıt denemeleri:** çıkış ve kapanış kaydı 4 kez, anlık kayıt 3 kez dener. Otomatik kayıt 30 sn'de bir, önemli olaydan sonra da en az 10 sn arayla yapılır.
- **Robux satın alma (ProcessReceipt):** ödül KAYDA GEÇMEDEN Roblox'a "verildi" denmez. Aynı makbuz ikinci kez ödül vermez.
- **Remote hız sınırı:** RemoteFunction ve RemoteEvent'lere jeton kovası hız sınırı konur (tıklama 12/sn, Shop vb.).
- **Çekim modu:** Studio testleri GERÇEK kayda yazar. Video çekiminde ya da DEV ile sıfırlama yaparken `Config.Save.StudioReadOnly = true` olur (Studio kaydı okur, yazmaz). Bitince false yapılır. Bu proje bir kez unuttu ve sahibin gerçek kaydı değişti.
- **Studio'da kayıt için:** oyun yayınlanmış olmalı ve Oyun Ayarları > Güvenlik > "Studio'nun API Hizmetlerine Erişimini Etkinleştir" açık olmalı.

---

## 5. Teknik dersler (her biri bu projede saatler aldı)

1. **Yeni avatar eklemleri:** yeni avatarlarda eklem `AnimationConstraint` olabilir; `C0` salt okunurdur, `Attachment0.CFrame` değiştirilir. Gerçek animasyon için KeyframeSequence (rbxmx) Python ile üretilip Studio'ya içe aktarılır, "Roblox'a kaydet" ile ID alınır ve Animator ile oynatılır. Kodla çizilen yedek animasyon dursun.
2. **Karakter boyu:** sadece Humanoid ölçek değerleriyle (BodyHeightScale vb.) değişir. Parçaları elle ölçekleme, kıyafetler bozulur. Ölçek değişince animasyon kesilmesin; eklem konumu her karede okunur.
3. **Mat malzeme rengi:** bu avatarda mat malzemenin rengi ekranda değişmedi, `Neon` çalıştı. Renk denemesinde önce bunu bil.
4. **Z-fighting:** aynı düzlemde üst üste binen iki yüz titrer. Parçalar tam yüzden birleşmeli, ince çıkıntılar 0.35'i geçmemeli. Studlu yüzeye 0.4'ten ince parça koyma, studlar delip geçer.
5. **Rojo bazen bir ModuleScript'i Studio'da oluşturmuyor.** Belirtisi "E'ye basınca bir şey olmuyor". Çözüm: modülün adını değiştir. Teşhis için Rojo'nun canlı API'si (`http://localhost:34872/api/rojo`) ile Studio'daki ağaç karşılaştırılır.
6. **`default.project.json` değişince** `rojo serve` yeniden başlatılır. ReplicatedFirst senkronlanmazsa yükleme ekranı görünmez.
7. **Üst çubuk payı:** Roblox'un üst çubuğu (~58 px) normal ScreenGui'de boş bırakılır. Gerçek köşeye ya da tam ekran karartmaya `IgnoreGuiInset = true` olan ayrı bir ScreenGui gerekir.
8. **ZIndex:** ana HUD'da `ZIndexBehavior = Sibling` kullanılır; Global'de yüksek ZIndex'li bir rozet açık pencerenin üstüne çıkıyordu. Karartma ile içeriğin sırasını ZIndex belirler, oluşturma sırasına güvenme.
9. **Ortadan ölçekleme:** nabız atan ya da basınca küçülen düğmede AnchorPoint (0.5, 0.5) olmalı, yoksa köşeden büyür. Layout içindeki nesneyi sabit boyutlu bir tutucunun içine koy.
10. **Türkçe karakterli yol:** luau-lsp `Masaüstü` gibi Türkçe karakterli yolu açamıyor; araçlara göreli yol ver ya da ASCII yola kopyala. Yeni projede yolda Türkçe karakter kullanma.
11. **Shell ve kodlama tuzakları:**
    - Bash heredoc içinde `\\n` tek `\n`'e dönüşebiliyor. Ters eğik çizgili dosyaları Write/Edit aracıyla yaz.
    - Türkçe metni Python'a stdin ile verme, dosyaya yazıp çalıştır.
12. **BillboardGui:** stud ölçekli etiketler yakınlaşınca ekranı kaplıyor. Piksel boyutlu yap ve uzaklığa göre küçült (LabelScaler).
13. **Kırpma hataları:**
    - SurfaceGui içindeki CanvasGroup daireye kırpmıyor.
    - Döndürülmüş çerçevede ClipsDescendants kırpmıyor.
    - Çözüm: önceden çizilmiş resim kullan ya da örtü parçaları koy.
14. **Dokulu MeshPart:** `Color` dokuyla çarpılmaz, model gri kalır. Kodla boyanacak modeller DOKUSUZ dışa aktarılır.
15. **Blender içe aktarımı:**
    - Birim 1 stud olmalı.
    - Studio'nun 3B içe aktarıcısı modelin önünü +Z'ye koyar; kodda çevirme ayarı tutulur.
    - Yeni sürümü içe aktarmadan önce aynı adlı eski modeli sil.
16. **Telefon dokunuşu:** dokunuş parmak kalkınca ve sadece kısa (≤0.6 sn) ile hareketsizse (≤14 px) tıklama sayılır. Yoksa kamera kaydırma da "tıklama" olur.
17. **Performans:**
    - Her karede çalışan döngü yazma (en az 0.1 sn aralık bırak).
    - Telefonda hafif mod: gölge, hale ve uzun listelerde 3B simge kapalı.
    - Uzaktaki ışık ve parçacığı kapat.
    - Yalnız görünen duvarların süsü açık kalsın.
    - Bütçe sayacı: `tools/perfcount.py`.
18. **StreamingEnabled:** uzak dünyanın parçaları istemciye gelmez. Uzaktaki bir parçayı sırayla bekleyen istemci kodu donar; ayrı iş parçacığında bekle.
19. **Tekme/hasar zamanlaması:** hasar ve ses "ayak değdiği anda" gelmeli, hareket bitince değil, yoksa gecikmeli hissettirir. Ses istemcide çalınır, ağ gecikmesi olmaz.
20. **Hata ayıklama:**
    - Studio'nun log dosyası `%LOCALAPPDATA%\Roblox\logs` (en yeni Studio dosyası; `Error`, `Expected` ara).
    - Log'da script çıktısı yoksa açılış hatalarını ekrana yazdır.
    - Önce sahibine hangi sürüme baktığını sor: Studio mu, yayındaki oyun mu?
21. **Çift yayın:** arka arkaya iki yayın `NewerVersionCreated` hatası verir. Bir kez yayınla.

---

## 6. Oyun tasarımı dersleri

**Asıl sorun özellik değil, bulunabilirlik ve geri dönüş.**
- 14 günde 16 oyuncu oldu. Oyun yaşı doğrulanmış 16+ oyunculara kilitli kaldı.
- Kilidi açmak için 60 günde 250 "highly engaged player" (HEP) gerekiyor; Kasım 2026'da eşik 100'e iniyor.
- Roblox önerisi ilk 60-180 saniyedeki çıkışa ve D1 / D7 / D28 geri dönüşüne bakar.
- Ölçülen değerler: yeni oyuncunun ortalama oturumu 0.92 dk, D1 %1.9. İlk dakikalar her şeyden önemli.

**İlk dakikalar:**
- İlk 30 tıklama bir görev olsun ("Click to squat 0/30"), ardından tek bir hedef zinciri gelsin: pet, skin, duvar, ayakkabı, level, rebirth.
- Üst şerit, yol çizgisi ve rehber kartı AYNI hedefi okur (tek `Objective` modülü). Bu projede iki ayrı yer farklı şey söyledi ve sahibi bunu yakaladı.
- Görev ödülü sessizce verilmez: oyuncu Quests'e yönlendirilir ve CLAIM ile kendisi alır.
- Hızlı ok turu oyuncu "Next"e basana kadar kalır. Pencere açıkken rehber kartı çıkmaz.
- İlk pet 1. dakikada çıksın. İlk rebirth hızlı olsun (Auto Click'le ~2 dk, elle ~5 dk).

**Tutan kalıplar (rakiplerde standart):**
- Promosyon kodları (açıklamada duyurulur, hesap başına bir kez).
- Nazik günlük giriş ödülü (seri kopmaz).
- Günlük görevler, günlük çark, oyun süresi hediyeleri.
- Rozetler ve unvanlar, sıralama panosu (ömür boyu toplam).
- Çevrimdışı kazanç, arkadaş bonusu, Pet Index bonusu.
- Sezon etkinliği (deterministik mağaza).
- Her gün aynı saatte "Power Hour" (Roblox zirvesi Cumartesi ~19:00 UTC).
- Çapraz sunucu duyuru akışı (oyunu dolu gösterir).
- Ödülsüz favori istemi, Moments klip istemi.
- Başlangıç paketi (tek seferlik, ucuz).

**Ekonomi:**
- Çarpanlar TAM SAYI olsun (x1.5 yok, en küçük x2); ekranda hep tam sayı görünsün.
- Bir aşamanın ödülü, önceki aşamayı iki kez yapmaktan fazla olsun.
- Tempo `simulate.py` ile ölçülür, sonra ayarlanır. Ayarda en etkili sabit duvar canı büyüme katsayısıdır.
- "Aşama ~40 vuruşta kırılsın" hedefi duvara güç hissi verdi (12 vuruşta "duvarlar çok zayıf" denmişti).
- Tıklama hızı değişirse tıklamayla ölçülen tüm ödüller birlikte ölçeklenir.
- Hedef tempo: aktif oyuncu oyunu ~8-10 saatte bitirir, sonra yeni dünya gelir.
- Rebirth sadece level ve ana gücü sıfırlasın; eşyalar ve para kalsın. Her şeyin sıfırlanması ceza gibi hissettirdi.

**Robux fiyatları:**
- Rakipler 19-79 R$ aralığında; bu projede her şey indirildi.
- Win paketiyle "ucuz arka kapı" olmasın: paketin Win'iyle alınabilecek en pahalı sepet, paket fiyatının en çok 1.3 katı olsun.
- Fiyat kuralları bir testle (`pricetest`) denetlenir.
- Koddaki fiyat değişince Creator Hub'daki ürün fiyatı da elle değişmeli; listesi sahibine verilir.

**Ücretli rastgele ürün kuralı (yumurta, şans iksiri):**
- Gerçek yüzdeler satın almadan önce görünür.
- `PolicyService.ArePaidRandomItemsRestricted` olan hesapta rastgelelik yerine sabit sıralı "eğitim yumurtası" kullanılır.
- Yaş anketinde bu soru doğru işaretlenir.

**Çocuk güvenliği:**
- Kalça bölgesi her zaman kapalı (siyah şort).
- Gerçek ten tonları fiyat ya da güç sırasına sokulmaz; skinlerde fantezi renkler kullanılır.
- Ekranda serbest oyuncu yazısı yok; duyurularda sadece Roblox'un süzdüğü DisplayName kullanılır.

**Ekran sade kalsın:**
- Level atlamada ortada büyük yazı çıkmaz; alt bar hafif nabız atar.
- Bildirimler küçük olur ve üstte çıkar.
- Calm UI ayarı (animasyonları durdurur) ekran görüntüsü almak için gerekli.

**"Juice" (geri bildirim) katmanı:**
- Kazanç yazıları, kırılma parçaları, kamera sarsıntısı, evrim anı.
- Yumurta açılışı: sallanma, dum-dum-puf sesi, karartma.
- Duvara vurunca geri sekme.
- Hepsi sadece görseldir ve korumalı yüklenir.

---

## 7. Varlık üretimi (simge, model, ses, müzik)

- **2B arayüz simgeleri:** Claude'un kendi çizdikleri (SVG, Blender render) reddedildi. **Gemini çizer** ("game icon set" üslubu: 2B, yumuşak degrade, ince koyu kenar, parlak vurgu). Akış:
  1. Prompt dosyası hazırlanır (ana üslup + konu satırı).
  2. Gemini'de üretilir (Görüntü oluştur, 1:1).
  3. `tools/icons/cutout.py` (Blender) beyaz arka planı şeffaf 512 PNG'ye çevirir.
  4. Roblox'a yüklenir, ID `Config.Icons`'a yazılır. ID boşken emoji yedeği görünür.
- **Gemini ipuçları:**
  - Promptlar arasında ~50 sn bekle; üretim sürerken Enter gönderilmez.
  - SVG yazarsa "Use the image generation tool" de.
  - İndirme `.tmp` olarak kalırsa dosya zaten tam JPEG'dir.
- **3B modeller (Blender, başsız Python):**
  - Her model TEK mesh + 8x8 palet dokusu, 2-6K üçgen, 1 birim = 1 stud.
  - Önizleme render'ına bakmadan "bitti" denmez.
  - Üslup sahibin referansından gelir; bu projede Pet Simulator tarzı kutu petler ve beneksiz fantastik yumurtalar kullanıldı.
  - Modeller Studio'nun 3B içe aktarıcısıyla `GameModels` altına konur; model yoksa kodla çizilen yedek kalır.
- **Sesler:**
  - Creator Store'dan ada göre seçilir; Claude dinleyemez, sahibi beğenmezse ID değişir.
  - Özel sesler Blender Python ile sentezlendi (yumurta "dum/puf", yumuşak level-up, Power Hour müziği); sahibi yükledi.
  - Sürekli tekrarlanan seslerde ses yok ya da çok kısık olmalı: squat sesi "rahatsız edici ve gecikmeli" bulundu.
- **Müzik:** sözsüz, neşeli 10 parça sırayla çalar; ses kademesi kaydedilir.
- **Yükleme ve ID:**
  - Görseller Creator Hub'a toplu "decal" olarak yüklenir.
  - Decal'in içindeki asıl resim ID'si `assetdelivery.roblox.com/v1/asset/?id=<decal>` XML'inden okunur.
  - ID'nin varlığı ve türü `economy.roblox.com/v2/assets/<id>/details` ile doğrulanır.
- **Rozet görseli:** 1.5 MB'tan büyük görsel sessizce başarısız olur; 1024 JPG kullan. Günde 5 rozet ücretsiz.

---

## 8. Yayın ve büyüme

**Yayın kontrol listesi:**
- `py tools/preflight.py` çalıştır. Şunları denetler:
  - git temiz mi, DEV kapalı mı, kayıt adı doğru mu;
  - ürün ve pass ID'leri, game pass'lerin satışta olup olmadığı ve fiyatları;
  - check, mocktest ve Roblox varlıkları.
- Studio ayarları: Dosya > Roblox'ta yayınla. Oyun Ayarları > Güvenlik > API erişimi açık. Avatar R15.
- Yaş/olgunluk anketi kodu yayınladıktan SONRA doldurulur. Bu oyunda sonuç "Minimal" çıktı.
- 1.000 R$ iade edilebilir yayın/Kids&Select ücreti var. 16+ kilidi süreye değil HEP sayısına bakar.

**Oyun sayfası:**
- Başlıkta sezon etiketi: `[🎃]`, sonra `[🌍W2]`.
- Açıklama kalıbı: emojili madde listesi, "Like + Favorite", "NEW CODE: ...".
- Simge: Gemini çizimi. Önce/sonra dönüşüm kapağı en iyi sonucu verdi.
- 4-5 küçük resim: oyun içi H modunda çekilmiş ve Gemini çizimi karışık.
- 15-30 sn video.
- Otomatik çeviri açık; küçük sunucu boyutu (10).
- Her kanal için ayrı Share Link. Roblox filtresi kampanya adında "Discord" kelimesini reddeder.

**Video çekimi (bu projede çalışan tarif):**
- Studio "Test et" modunda, tam ekran, sağ paneller kapalı.
- Arayüz H ile gizlenir.
- Kamera komut çubuğundan ya da MCP `execute_luau` ile Scriptable kameraya alınır (dönen ya da yandan takip eden kamera).
- Sahneler zamanlı bir betikle oynatılır (DevCommand RemoteEvent'iyle).
- Kayıt ffmpeg gdigrab ile alınır, oyun alanının ofseti ölçülür, fare kadrajdan çıkarılır.
- Çekim sırasında Claude penceresi küçültülür, yoksa kayda girer.
- 9:16 kurgu: oyun ortada, arkada bulanık büyütülmüş kopyası, üstte ve altta büyük yazı.

**Büyüme kuralları:**
- Önce retention, sonra trafik. Retention'ı zayıf oyuna reklamla gelen trafik birkaç günde çöker.
- Haftalık sabit güncelleme saati koy (Cumartesi 19:00 UTC).
- Yeni dünya ~14 günde bir gelsin.
- Kapı açılmadan en uygun ücretsiz kanal Roblox Moments'tır.
- Reklam yalnız eşik düşünce: tek ~20 USD test, 3. günde HEP artışı ≤5 ise durdur.
- YouTuber'lara e-posta yalnız kapı açılınca (şablonlar `research/07c`).
- Topluluk gönderilerinde (DevForum, Reddit) aynı metni her yere yapıştırma.

**Ölçüm:**
- AnalyticsService ile ilk oyun hunisi adımları (Joined, Clicked30, FirstPet ... FirstRebirth) ölçülür.
- Ekonomi kaynakları ve giderleri ile özel olaylar da gönderilir.
- Reklamdan ÖNCE huni okunur ve en büyük kayıp düzeltilir.

---

## 9. Sahibi ile çalışma kuralları

- **Dil:** sohbet Türkçe, oyun içi bütün yazılar İngilizce, kod yorumları Türkçe.
- **Kim ne yapar:** sahibi Roblox deneyimi olmayan bir IT öğrencisi. Kodu Claude yazar; sahibi Studio'da dener, ekran görüntüsü ve Output hatası yollar.
- **Elle Studio adımları:** numaralı ve TÜRKÇE menü adlarıyla anlatılır:
  - Dosya > Roblox'ta yayınla, Deneyim Ayarları;
  - Pencere > Çıkış (Output), Gezgin (Explorer), Özellikler, Varlık Yöneticisi;
  - Test > Test Oturumunu Başlat.
  - Rojo eklentisinin arayüzü İngilizce kalır.
- **Referans görsel:** sahibi başka bir oyunun ekran görüntüsünü yollar. Ölçü karakter boyuna oranlanarak alınır (karakter ~5.3 stud), tahmin edilmez. Arayüz yalnız TAM EKRAN görüntüsünden değerlendirilir.
- **Belirsiz istek:** yorum yapıp yapmadan önce sor. Örnek: "skin" sahibi için duvar görünümüydü; "sol taraftaki boşluk" yanlış tahmin edildi.
- **Reddedilenler:** reddedilen bir şey (kalabalık arayüz, bloom ışık, 3B ödül sandığı, "modernleştirilmiş" tema...) CLAUDE.md'ye yazılır ve tekrar önerilmez. Sahibi bir şeyi sonradan onaylarsa o da yazılır.
- **Yetki sınırları** (tam yetki verilse bile):
  - Claude şifre girmez, hesap açmaz, para ya da Robux harcamaz.
  - Sahibin kişisel sosyal hesaplarında paylaşım yapmaz.
  - Yayını sahibi yapar ya da açıkça onaylar.
- **Yedek:** her büyük turdan önce git etiketiyle yedek alınır (`git tag yedek-<tarih>`). Geri dönüş `git revert` ile yapılır.
- **README.md devir dosyasıdır.** Oturum sıfırlanınca devamlılık buradan sağlanır; her anlamlı değişiklikten sonra güncellenir.
- **İş sırası (bu projede işe yarayan):**
  1. Çekirdek oyun.
  2. Sahibinin Studio testi ve denge.
  3. Blender modelleri.
  4. Robux ürünleri. Kod baştan hazır olur, ID 0 iken etkisizdir.
  5. Yayın ve büyüme.

---

## 10. Bu projeden yeniden kullanılabilecek hazır parçalar

Kaynak: `RobloxOyun/src` (GitHub: Levent-kcts/squat-simulator). Yeni oyuna kopyalanabilir ya da örnek alınabilir:

| Parça | Dosya |
|---|---|
| Kayıt, oturum kilidi, profil, DEV komutları | `server/PlayerStats.luau`, `server/DevTools.luau`, `client/DevPanel.luau` |
| Robux makbuz işleme, game pass sahipliği | `server/Purchases.luau`, `server/AutoClickPass.luau`, `server/AreaPasses.luau` |
| Yükleme ekranı (gerçek ilerleme çubuğu) | `shared/LoadingScreen.luau`, `loading/Loading.client.luau` |
| Pencere yöneticisi, yumuşak arayüz, konuşma balonu | `client/PanelManager.luau`, `client/UIStyle.luau`, `client/SpeechBubble.luau` |
| Rehber turu, tek hedef, görevler | `client/GuideTour.luau`, `client/Objective.luau`, `client/QuestPanel.luau` |
| Yumurta, pet, birleştirme, açılış animasyonu | `server/EggShop.luau`, `client/Reveal.luau`, `client/PetsPanel.luau`, `shared/Catalog.luau` |
| Kodlar, günlük giriş, çark, hediyeler, çevrimdışı kazanç | `PlayerStats.redeemCode / claimLogin / spinWheel`, `client/LoginPanel`, `WheelPanel`, `GiftsPanel`, `OfflinePanel` |
| Çapraz sunucu duyuru, arkadaş daveti, rozet, analitik | `server/GlobalFeed.luau`, `server/Referrals.luau`, `server/Badges.luau`, `server/Analytics.luau` |
| Ücretli rastgele ürün politikası | `server/PaidRandomPolicy.luau` |
| Telefon dokunuşu, performans modu, etiket ölçekleyici | `client/TapFilter.luau`, `client/Performance.luau`, `client/LabelScaler.luau` |
| Efekt ve ses katmanı | `client/Juice.luau`, `client/Sfx.luau`, `client/MusicPlayer.luau` |
| Araçlar | `tools/check.py`, `mocktest.py` + `mocktest/`, `typecheck.py`, `simulate.py`, `preflight.py`, `studio_mcp.py`, `tools/blender/*`, `tools/icons/cutout.py`, `tools/sounds/*` |
| Araştırma (pazar, rakip, büyüme) | `research/01..07*.md`, `OYUN_TASARIM_ANALIZI.md` |

---

## 11. Bu projede yapılan en pahalı hatalar (tekrarlama)

1. **Arayüzü baştan "modernleştirmek":** sahibi beğenmedi, hepsi geri alındı. Onaylanmış görünümü sormadan değiştirme.
2. **Studio testinde gerçek kayda yazmak** (çekim modunu unutmak).
3. **Sözdizimini denetlemeden göndermek** (boş ekran).
4. **Belirsiz isteği tahminle yapmak:** "duvara COMING SOON yaz" denince yanlış duvara yazıldı; ayakkabıyı sabit bonusa çevirmek de geri alındı.
5. **Ödülü ve durumu birden fazla yerde hesaplamak:** üst şerit ve rehber kartı farklı hedef söyledi.
6. **Duvar önüne ödül pedi koymak:** tekme atan oyuncu kazara pede basıyordu.
7. **Reklama erken para harcamak:** 3.466 gösterimde 38 tıklama geldi, oyuncu gelmedi.
8. **Ses ve ışıkta abartmak:** bloom ışık, parlak tavan panelleri, sürekli çalan sesler hep kısıldı.

---

## 12. Yeni oyunun prompt'unda cevaplanması gereken sorular

Sahibi yeni oyunu anlatırken şunlar netleşmeli. Cevaplanmayanları Claude sormalı.

**Kimlik ve çekirdek:**
1. Oyunun adı (çalışma adı), türü (simülatör / tycoon / obby / tower defense / RPG...), referans oyun(lar) ve linkleri.
2. Çekirdek döngü tek cümleyle (ör. "tıkla, güçlen, duvar kır, Win kazan, eşya al, rebirth").
3. Oyuncu ilk 60 saniyede ne yapar? İlk 5 dakikada ne kazanır?
4. Kontroller: tıklama mı, yürüme mi, araç mı? Telefon öncelikli mi?

**İlerleme ve ekonomi:**
5. Para birimleri, güç kaynakları ve çarpanlar.
6. Rebirth / prestij olacak mı, neyi sıfırlar?
7. Hedef oyun süresi (oyunun sonu kaç saatte?) ve dünya / bölge sayısı.

**İçerik:**
8. Koleksiyonlar: pet, eşya, skin, iz, aura... Kaç tane, hangi temalarda?
9. Harita: lobi düzeni, bölgeler, tema, ışık (aydınlık / karanlık), renk paleti.

**Görsel ve ses:**
10. Arayüz üslubu: referans ekran görüntüsü, yazı tipi, kenar kalınlığı, renkler.
11. Karakter: R15 mi, özel avatar mı, büyüme / değişim var mı? Çocuklara uygunluk kuralları.
12. Ses ve müzik tarzı.

**Sosyal ve para:**
13. Sosyal: çok oyunculu etkileşim, ticaret, sıralama, arkadaş bonusu, grup.
14. Para kazanma: hangi Robux ürünleri ve pass'ler, fiyat aralığı, başlangıç paketi. Robux işleri en sona mı?
15. Hedef kitle ve yaş. Ücretli rastgele ürün olacak mı?

**Süreç:**
16. Yayın tarihi hedefi, sezon etkinliği, güncelleme ritmi.
17. Neler kesinlikle İSTENMİYOR?
18. Claude'un yetkisi:
    - Studio MCP ile kendisi test edebilir mi?
    - Creator Hub'da iş yapabilir mi?
    - Gemini'yi kullanabilir mi?
    - Yayını kim yapar?
19. 3B modeller Blender'da mı, Creator Store'dan mı, Roblox'un yapay zekâ üretiminden mi gelecek?
20. Bu rehberden hangi hazır parçalar (§10) yeni oyuna taşınacak?

---

*Son güncelleme: 2026-10-22. Kaynaklar: bu projenin CLAUDE.md, README.md, Claude hafıza notları, research/ raporları ve git geçmişi.*
