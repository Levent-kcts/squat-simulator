# Squat Simulator (Roblox)

Oyunun adı "Squat Simulator" (bundan sonra). Rojo ile yönetilen basit bir Roblox simülatör oyunu. Kod yalnızca Luau, `src/` altında.

## Oyun kuralları
- Ekranın herhangi bir yerine tıklamak bacak kasını artırır (UI butonlarına tıklamak sayılmaz).
- Tıklama başı bacak kası kazancı = Config.MusclePerClick x (1 + takılı petlerin çarpanları) x level çarpanı x rebirth çarpanı x aura x takılı skinin çarpanı. AYAKKABI KAZANCI ETKİLEMEZ.
- Duvara hasar = toplam bacak kası x takılı ayakkabının 'damage' çarpanı (ayakkabı yoksa x1). Ayakkabılar sadece hasar çarpanıdır.
- LEVEL, TOPLAM BACAK KASINDAN hesaplanır (Progression.levelFromMuscle): level 1'den 2'ye 10 kas, level 10'dan 11'e 22 kas gerekir (Config.Level), toplamlar birikerek ilerler. Çubuk o level içinde kazanılan kası gösterir. Rebirth kası sıfırladığı için level de 1 olur. Level'ı doğrudan set etme; PlayerStats.syncLevel kasa göre ayarlar.
  Level, rebirth sayısına bağlı üst sınıra (20 + 10 x rebirth) kadar çıkar. Sınırda alttaki bar 'MAX' yazar; rebirth yapmadan level atlanamaz.
  REBIRTH (sol taraftaki Rebirth butonu onay ekranı açar: önce/sonra çarpan ve max level, uyarı, level çubuğu, Rebirth ve Robux'lu 'SKIP?' butonu; client/RebirthPanel): level 1'e, bacak kası ve TÜM Win'ler 0'a döner, duvarlar baştan kurulur; ayakkabılar da sıfırlanır (petler, iz ve aura korunur);
  kalıcı çarpan kazanılır (Config.Rebirth). Alt çubuk artık duvar değil LEVEL ilerlemesini gösterir.
- Hasar = oyuncunun toplam bacak kası. Hasar, oyuncunun kendi ilk sağlam duvarına gider (yakında olmalı).
- 100 duvar tek sıra halinde ard arda dizilir (20 aşama x 5 duvar), en düşük canlıdan başlanır
  (aynı gruptaki duvarların canı eşit: 25, 250, 3000, sonra x12). Hasar duvarlara sırayla uygulanır, taşan hasar sonraki duvara geçer
  ama her 5'li aşamanın sonunu geçmez.
- DUVARLAR HER OYUNCUYA ÖZELDİR. Sunucu canları oyuncu başına tutar (WallService), duvar parçalarını her
  oyuncu kendi ekranında oluşturur (client/WallClient). Diğer oyuncular senin duvarlarını görmez, seni duvarın
  içinden geçerken görür. Sunucuda duvar Part'ı oluşturma!
- Her aşamadan sonra boşlukta küçük sarı Win butonu(ları) vardır (Config.WinButtons, şimdilik sol tarafta bir
  tane, SOLDA pembe VIP pedi (SAĞDA normal sarı ped): etiketi 2 katı ödülü yazar ('+2 Wins', '2x WINS' yazısı YOK), yan duvarda VIP tabelası YOK; her aşama sonunda koridor Config.Wall.ChamberExtra kadar her yana genişleyen bir odaya açılır (WallService: ChamberSide/Cap/Floor/Roof blokları); game pass'i olmayan oyuncu pede basınca Robux satın alma penceresi açılır (WallService, MarketplaceService:PromptGamePassPurchase, 8 sn aralıkla; Config.VipGamePassId = 0 iken 'coming soon' mesajı)). Basınca aşamanın ödülü verilir, tur başa sarar ve oyuncu başlangıç
  alanına ışınlanır. Basmayan, yanından geçip devam eder.
- Ödül: 1, 3, 7, 15, 31 ... (Config.Wall.RewardGrowth). Bir aşamanın ödülü, bir önceki aşamayı 2 kez
  yapmanın ödülünden hep fazladır; bu kuralı bozma.
- 100. duvar kırılıp Win'e basılmazsa 15 sn sonra tur kendiliğinden başa sarar.
- Bir tıklama bir hareket başlatır; hareket sürerken (Config.MoveDuration) yeni tıklamalar yok sayılır (sunucu da zorlar)
  ve bacak kası + hasar hareket BİTTİĞİNDE bir kez verilir. Hızlı tıklamanın faydası yoktur. Hareket: ilk sağlam duvarın önündeyse (Config.Wall.HitRange, duvar ön yüzüne yatay mesafe)
  tekme, uzaktaysa squat. Hareketler `client/Moves.luau` içinde Motor6D C0 ile kodla oynatılır (animasyon asset'i yok);
  sunucu diğer oyunculara `MoveEvent` ile haber verir.
- KARAKTER BÜYÜMESİ (server/LegGrowth): level arttıkça boy ve genişlik büyür (Humanoid BodyHeightScale/BodyWidthScale/BodyDepthScale,
  Roblox'un kendi ölçeği; kıyafetler uyar). Level 1'de ince (x0.9 genişlik), Config.Body.MaxLevel'de (1000) en büyük boyutta (x2.0 genişlik,
  x2.2 boy; koridora/kapıya sığacak şekilde) DURUR; artış eğrisi başta hızlıdır (GrowthCurve). Sonrası görünmez, sadece çarpanlarla güçlenme
  devam eder. Rebirth'te level 1'e döndüğü için karakter küçülür.
  KASLAR: oyun başında HİÇ kas yoktur (sadece şort). Config.Legs.StageLevels (5, 20, 100, 250, 500, 1000) levellerinde yuvarlak kas parçaları
  (popo, ön/arka uyluk, baldır) belirir ve irileşir; son eşikte durur. Bacak parçalarını elle ÖLÇEKLEME. Moves.luau ölçek değişirse veya
  oyuncu havadaysa hareketi bırakır; havadayken tıklama hareket başlatmaz (bacak sallanması karakteri döndürüp bozuyordu).
- Win para birimidir: Lobideki ayakkabı raflarından (postamentin üstüne basarak) kalıcı ayakkabı alınır. Sahip olunan bir ayakkabının postamentine basınca o takılır (ucuz/zayıf olanlar da kullanılır, en güçlüsü otomatik değil;
  PlayerStats.buyItem alırsa takar, sahipse takar, zaten takılıysa sessiz kalır); takılı ayakkabı duvar hasar çarpanını belirler. Yumurtalar lobinin ARKA duvarındadır (kırılan duvarların tam karşısı): 6 yumurta, her birinin fiyatı ve pet havuzu farklıdır (Config.Eggs); yumurtaya yaklaşınca bir panel açılır (pet çarpanları ve çıkma şansları); E = aç, R = otomatik aç, T = bir seferde 1/3/10 aç (Config.EggMultiOptions). Açma isteği sunucuda doğrulanır (yakınlık, Win). Panelde bir pet kartının üstüne gelince kart kararır, tıklayınca çarpı (X) konur: çarpılı pet yumurtadan çıkınca envantere girmeden anında silinir (yumurta ücreti yine alınır; işaret kaydedilir, PlayerStats.toggleAutoDelete). Çıkan pet 'Pets' menüsünde listelenir.
- ANTRENMAN: sağ duvarda 4 + 3 + 3 = 10 büyük ped (Config.Training.RowCounts / Areas: id, name, mult, rebirths, color). Oyuncu pede GİRİNCE (TrainingArea sunucuda 0.2 sn'de bir konuma bakar) açıksa sunucu `TrainingArea`/`AreaMultiplier` özniteliklerini ayarlar, istemci bunu görünce kendiliğinden tıklar (otomatik squat), tıklama işleyicisi hareketi 'Squat' yapar ve `PlayerStats.addMuscle(player, area.mult)` kazancı pedin çarpanıyla çarpar. Pedler SADECE rebirth ile açılır (rebirths = N: N rebirth'te açık, 0 ücretsiz; Win ile satın alma YOK, sahibi istemedi). Açık mı kararını HER ZAMAN sunucu verir (PlayerStats.isAreaUnlocked). Pedlerde antrenör yer tutucusu var ve her antrenörün bir ismi var (Config.Training.Areas[].trainer, etiketlerde görünür); özel antrenörler sonra eklenecek. Üst basamaklara çıktıkça ped, şerit ve antrenör büyür (Config.Training.RowPadSizes/RowDepths/TrainerScales; Shelf'te rowPadSizes/laneDepths/rowLength). Alan koridor tarafına kaydırıldı (TrainingShelfZ = -12), sağ duvarın arka ucu (z > 23) yeni şeyler için BOŞ bırakıldı.
- SKIN: ayakkabı rafının yanında, tamamen aynı standda (server/Shelf) 15 skin rengi; postamente basınca Win ile alınır (PlayerStats.buySkin, ayakkabı gibi: alınca
  hemen takılır, sahip olunana basınca takılır, istenen skin seçilebilir), karakter ve kaslar o renge boyanır (AppearanceCleaner.paint, LegGrowth); oyuncunun gömleği KALIR, sadece ten rengi değişir
  (Config.Appearance.HideShirtWithSkin = true yapılırsa gömlek dokusu da gizlenir; skin kalkınca asıl renkler geri gelir), çarpan bacak kası kazancına girer (Config.Skins mult). Rebirth ayakkabı gibi skinleri de sıfırlar.
  Sadece fantezi renkler kullan: gerçek ten tonlarını fiyat/güç sıralamasına sokma.
- Bacak kası, Win, eşyalar, skinler ve petler DataStore ile kaydedilir: 30 sn'de bir otomatik, ayrıca Win/satın alma/pet
  sonrası (en az 10 sn arayla) ve oyuncu çıkarken. Studio'da kayıt için oyun yayınlanmış ve API erişimi açık olmalı.
- Lobi düzeni (124x130, spawn tam ortada; referans fotoğraflara göre küçültüldü: yumurtalar da Shelf standında, antrenman pedi 9 stud, ayakkabı/skin rafları fotoğraflardan ölçülü olduğu için değişmedi): ÖN duvar koridor (kırılan duvarlar), ARKA duvar yumurtalar, SOL duvar (duvarlara bakarken sol) iki raf: ayakkabılar (Config.Lobby.ShoeShelfZ) ve skinler (SkinShelfZ) yan yana, koridor girişi ucuna yaslı; sol duvarın arka ucu (yumurta tarafındaki sol köşe, z > 41) YENİ ŞEYLER İÇİN BOŞ BIRAKILDI (sahibi sonra dolduracak), SAĞ duvar antrenman alanı (aşağıdaki ANTRENMAN kuralı).
- Ortam: kapalı, aydınlık, lego çıkıntılı pastel salon + koridor. Kırılan duvarlar canlı şeker renkli (Plastic).
  HUD referans oyundan esinli: üstte hedef şeridi, sol üstte Rebirth/Win sayaçları, solda 2x3 kare buton (Shop [yakında], Rebirth, Sounds, Backpack, Pets, Gifts). Backpack > Trails ve Auras; Gifts > Playtime Rewards. Sağ altta küçük ışınlanma simgeleri (Eggs, Shoes, Walls, Home; hedefler sunucuda sabit: init.server TELEPORTS). Altta level çubuğu ve Auto Click. Lobi `EnvironmentService`'te.
- Koridor kapalıdır (tavan var). Yan duvarlar ve tavan her aşamada farklı renktir; yeni renk Win butonundan sonra başlar.

## Yapı
- `src/shared/Config.luau`: tüm denge ayarları (can, fiyat, pet şansı, kayıt ayarı).
- `src/shared/Layout.luau`: koridor düzeni, duvar canı, renk, aşama ödülü hesapları (sunucu+istemci ortak).
- `src/shared/Progression.luau`: level/rebirth hesapları (gereken tap, üst sınır, çarpanlar, bacak aşaması).
- `src/server/DevTools.luau` + `client/DevPanel.luau`: test paneli (sol üstte DEV butonu: level, rebirth, Win, kas, ayakkabı, skin, duvar atlatma). Sadece Studio veya oyun sahibi; Config.DevTools.Enabled ile kapatılır. Yetki kontrolü SUNUCUDA.
- `src/server/AppearanceCleaner.luau`: oyuncunun kendi skini (ten, gömlek) KALIR ama pantolon herkeste aynı mavidir (Config.Appearance.StandardPants/PantsColor, kaslar da bu renkte); üstteki katmanlı kıyafet ve aksesuarlar (çanta, şapka, eşofman katmanı) kaldırılır, saç/yüz kalır (Config.Appearance). Popo kası her aşamada vardır (küçükten başlar). Bacaklar ve kaslar oyuncunun ten rengindedir; herkese siyah şort/boxer eklenir (LegGrowth.buildShorts, Config.Appearance.Shorts): çocukların oynadığı oyunda kalça bölgesi kas ne kadar büyürse büyüsün kapalı kalmalıdır, bu şortu KALDIRMA.
- `client/CosmeticPanel.luau`: Trails ve Auras menüleri (genel, options ile). `server/AuraService.luau`: aura efekti (Config.Auras; mult bacak kası kazancını çarpar). `client/PetsPanel.luau`: pet envanteri (takma/çıkarma, Equip Best, Unequip All, çöp kutusu; takılı pet sayısı sunucuda, PlayerStats.equipped). `client/GiftsPanel.luau`: oyun süresi ödülleri (Config.GiftRewards, oturum başına; kas/Win/pet/2x süreli güçlendirme). `client/RebirthPanel.luau`: rebirth onay ekranı.
- `src/server/TrailService.luau`: iz (trail) efektleri. Win ile alınır, takılı iz arkada renkli iz bırakır ve yürüme hızını artırır (Config.Trails, BaseWalkSpeed); Robux butonu henüz yer tutucu (robuxProductId = 0).
- `src/server/LegGrowth.luau`: level ilerledikçe bacakları kalınlaştırır.
- Takılı ayakkabı (EquippedShoe) karakterde PARÇA EKLEMEZ (sahibi dışarıdan eklenen parçaları beğenmedi): AppearanceCleaner.applyShoes iki ayak parçasını (R15 LeftFoot/RightFoot) ayakkabının renginde ve NEON malzemeyle boyar; TÜM ayakkabılar neondur (Config.Items renkleri canlı seçildi) ve parlaklık güçle artar (ShoeModel.tier = Config.Items sırası, ShoeModel.neonColor yoğunluk %55-%87, Config.MaxGlowShoeId = Neon Kicks'ten sonra artmaz, ayaktaki PointLight 'ShoeGlow' parlaklığı/menzili kademeyle büyür; rafta postament ışığı da). Config.Items zayıftan güçlüye sıralı kalmalı. Mat malzeme denendi ama bu avatarda ekranda renk değişmedi (Color doğru yazılsa da; BodyColors/doku/UsePartColor/ikinci parça denendi, neden bulunamadı), bu yüzden Neon şart. Skin boyaması önce, ayakkabı sonra uygulanır; her boyamada asıl renklerden başlanır (AppearanceCleaner.paint). `shared/ShoeModel.luau` sadece raftaki ayakkabı modelidir (parçalar da neon).
- `src/shared/Catalog.luau`, `Format.luau`: id ile eşya/pet bulma, sayı biçimlendirme.
- `src/server/init.server.luau`: spawn alanı, tıklama olayı, mağaza RemoteFunction'ı.
- `src/server/PlayerStats.luau`: leaderstats, kayıt/yükleme, eşya ve pet mantığı.
- `src/server/EggShop.luau` + `client/EggShop.luau`: arka duvardaki 6 yumurta: ayakkabı/skinle aynı Shelf standı (2 şerit, 3 + 3), ped önde küçük, yumurta pedin arkasında; etiketler iki satır (isim, fiyat), pet şansları yaklaşınca açılan panelde. `server/TrainingArea.luau`: sağ duvardaki antrenman alanı (10 büyük ped, Shelf ile kurulur, pede girmeyi 0.2 sn'de bir kontrol eder, kilit/satın alma/otomatik squat). `client/TrainingClient.luau`: ped etiketleri ve kilit görünümü. `server/Mannequin.luau`: ortak manken (skin mankeni + yer tutucu antrenör).
- `src/server/Shelf.luau`: ortak raf/stand kurucusu (3 basamaklı şerit, kenar çıkıntıları, uçlarda çentikli rampa, postamentler, başlık, Touched ile satın alma); raf yerel eksenli kurulur (frame), duvara göre döndürülebilir. `ShoeShop.luau` (15 ayakkabı) ve `SkinShop.luau` (15 skin, renkli manken) sadece eşya modelini ve satın alma fonksiyonunu verir.
- `src/client/ShelfClient.luau`: raf etiketleri (isim, güç çarpanı, fiyat/durum satırları) ve postament renkleri (sarı kullanılan / yeşil sahip / kırmızı değil), ortaktır; `client/ShoeShop.luau` ve `SkinShop.luau` ona ayar verir.
- `src/server/EnvironmentService.luau`, `Build.luau`: lobi, ışıklandırma, ortak parça yardımcıları.
- `src/server/WallService.luau`: oyuncu başına can takibi, hasar, Win butonları, zemin/yan duvarlar.
- `src/client/init.client.luau`: HUD ve tıklama girişi. `WallClient.luau`: oyuncuya özel duvarlar ve can göstergesi. `Shop.luau`: mağaza arayüzü. `PetFollowers.luau`: pet görselleri.

## Kurallar
- README.md proje devir dosyasıdır. Her anlamlı değişiklikten sonra (yeni özellik, değişen kural, yeni karar, bulunan hata, yapılacaklar listesi) README.md'yi GÜNCELLE: yeni şeyleri ekle, artık geçerli olmayanları çıkar. Oturum sıfırlanınca devamlılık buradan sağlanır.
- Para/skor/hasar/satın alma gibi her şey sunucuda hesaplanır. İstemciye asla güvenme.
- Kayıt yüklenemezse o oturumda KAYDETME (eski ilerleme silinmesin). Bu mantığı bozma.
- `Config.Save.StoreName` değişirse herkesin kaydı sıfırlanır.
- Görsel nesneler (duvar, buton, spawn) kodla üretilir, Studio'da elle model gerekmez.
- Değişiklikten sonra Studio'da test et: `rojo serve` açık olmalı.
- `rojo build` Luau sözdizimini DENETLEMEZ (Config'e fazladan `},` kaçınca sunucu hiç başlamadı, ekran boş kaldı). Her değişiklikten sonra proje klasöründe `python tools/check.py` çalıştır: resmi `luau-analyze` (kurulu: `%USERPROFILE%/.luau/luau-analyze.exe`, sahibi indirmeye izin verdi) + yapı denetleyicisi (`tools/luacheck.py`). 0 sorun çıkmadan 'bitti' deme. Roblox'un tür tanımları olmadığı için Roblox globalleri süzülür; Studio'ya özgü hataları (yanlış özellik adı gibi) yakalayamaz.
