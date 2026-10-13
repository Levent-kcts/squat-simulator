# +1 Squat Evolution: Smash Walls: tasarım incelemesi (oyun teorisi, davranış tasarımı, harita ve ışık)

Tarih: 2026-10-13 (ikinci tam inceleme; ilk sürümdeki yapılan işler çıkarıldı, kalan ve YENİ bulgular var).
Bu belge bir YOL HARİTASIDIR: oyunun neden tuttuğunu/tutmadığını, neyin düzeltilmesi gerektiğini ve hangi sırayla ne yapılacağını söyler. Hiçbir şey otomatik değişmedi: her madde sahibinin onayını bekler.

## 0. Nasıl inceledim, neyi göremedim

İncelenen: `Config.luau` (ekonomi, ödüller, yumurtalar, görevler), `tools/simulate.py` çıktısı (22 saatlik Auto Click'li oyuncu), sıralama panosu / isim etiketi / yumurta / görev kodları, `tools/perfcount.py` (2.150 parça, 64 ışık: bütçe iyi), `tools/preflight.py` (HAZIR), 8 gerçek ekran görüntüsü (`assets/cover/UPLOAD`: lobi, yumurta standı, raflar, antrenman, kapak sanatı).
Göremediklerim ve sınırlar: oyunu Studio'da OYNAMADIM; koridorun (duvarların olduğu uzun yol) güncel bir ekran görüntüsü yok, o yüzden koridor için fikirler "tahmin"dir; gerçek oyuncu verisi (Analytics, D1/D7) yok, rakamlar simülasyondan; ekran görüntüleri 2026-10-10 tarihli (sonraki değişiklikler yok). Önizleme görselleri fotoğraf düzenlemesiyle yapılmış YAKLAŞIK taklitlerdir, Roblox'ta ışık farklı hesaplanır.

## 1. Tek bakışta durum

**Güçlü:** net çekirdek fikir (squat > güçlen > duvar kır), her şey görsel ve tatmin edici, katmanlı koleksiyon (pet, ayakkabı, skin, iz, aura, index), kısa+uzun hedef karışımı, ilk dakikalar artık sıkı (ilk rebirth ~2 dk, ilk pet 1. dakikada, rehber turu, görev zinciri), yumurta açılışı gösterişli (5 "dum" + "puf", nadirlik artık şansa göre), çocuk güvenliği ve ücretli rastgele ürün kuralları kodda.

**Zayıf (bu incelemenin bulguları, ayrıntı aşağıda):**

| # | Bulgu | Kanıt | Önem |
|---|---|---|---|
| B1 | LEG MUSCLE sıralama panosu rebirth'te çöküyor: sıralama GÜNCEL kasa bakıyor, rebirth kası sıfırlıyor. Panoda üst sıradaki oyuncu rebirth yaparsa panodan düşer (rebirth'i cezalandıran bir ödül sistemi). | `server/Leaderboards.luau` BOARDS[1].statName = Leg Muscle; rebirth `muscle = 0` | Yüksek, küçük iş |
| B2 | Statü sinyali rebirth'te siliniyor: isim etiketi "Lv.N + güncel kas" gösteriyor, rebirth'ten hemen sonra 40 rebirth'lik oyuncu ile yeni oyuncu AYNI görünüyor. | `client/OverheadTags.luau` | Yüksek, küçük iş |
| B3 | Lobi tek tonlu: duvar, zemin, tavan, raflar aynı lavanta-mavi; kapak sanatı ise şeker rengi gökkuşağı. İlk izlenim sözünü tutmuyor. Işık düz: karşıtlık ve odak yok. Ortadaki geniş zemin (~70 x 88 stud) boş, sadece spawn pedi var. | ekran görüntüleri; `Config.Lighting`, `EnvironmentService` renkleri | Yüksek (ilk izlenim) |
| B4 | İlk rebirth'ten sonra oyuncuyu yönlendiren/hedef veren hiçbir şey yok (hedef şeridi ve rehber susuyor); uzun vadeli hedef listesi yok (başarım, rozet). | CLAUDE.md: deneyimli oyuncuda yönerge gizli | Yüksek (D3-D7) |
| B5 | Geç oyunda döngü "yumurta aç, birleştir"e dönüşüyor ve Win'in harcama KARARI kalmıyor: tüm ayakkabı/skin/iz/aura ~0,98 milyon Win; 20. aşamanın TEK seferi 1.048.575 Win; en pahalı yumurta 50.000 Win'de sabit (sefer başına 21 Galaxy yumurtası). Sınır para değil zaman oluyor. | simulate.py: r20'de devir başına 2,9 milyon Win | Orta-yüksek |
| B6 | Oyunun sonu ~8 saat (20. aşama, r23) ve "WORLDS: COMING SOON" bir söz: içerik takvimi yoksa ilk oyuncu grubu 1-2 hafta içinde duvara çarpar. 18 gün sonra Cadılar Bayramı (31 Ekim): hazır bir sezonluk etkinlik fırsatı. | Config.Wall, WorldsGate | Yüksek (D14-D30) |
| B7 | Gerçek karar yokluğu: her seçimde baskın strateji belli (en pahalı ayakkabı, Equip Best, hemen rebirth). | tablo 2 | Orta (derinlik) |
| B8 | Sosyal kanıt yok: nadir pet çıkınca kimse duymuyor, rebirth duyurulmuyor; duvarlar özel olduğu için oyuncular birbirini fazla görmüyor (arkadaş bonusu ve davet var, iyi). | kod: yayın/duyuru yok | Orta |
| B9 | Bildirim/rozet yok: Roblox'un oyuncuyu GERİ ÇAĞIRAN iki bedava aracı (deneyim bildirimi opt-in, rozetler) kullanılmıyor. | kod: BadgeService / ExperienceNotificationService yok | Yüksek, ucuz |
| B10 | Kitle: oyun 16+ (yaş doğrulamalı) açık; Kids onayı için 60 günde 250 "highly engaged" oyuncu gerek. Yani az sayıda 16+ ziyaretçinin dönüşümü hayati: B4, B8, B9 doğrudan bunu etkiler. | README YAYIN DURUMU | Bağlam |

Önceki turdan DURUM (tekrar önerme): başlangıç Win'i artık Quests'ten CLAIM (sessiz değil), ücretsiz Auto Click denemesi kaldırıldı (yerine ilk rebirth görevinin Auto Click Potion ödülü), level kilometre taşı ödülleri tamamen KALDIRILDI (sahibi istedi), rebirth sadece level+kası sıfırlar, Index tamamlama ödülü ve Free Reward kısaltması yapıldı, yumurta animasyonu ve sesleri onaylandı, pet nadirliği şansa göre. Sahibi daha önce şunları REDDETTİ, önermiyorum: günlük giriş ödülü, promosyon kodları (CODES), lobide görev panosu, pet birleştirme makinesi, üst ilerleme şeridi, 3B sandık, parlayan "sıradaki hedef" pedi, bloom/göz alan tavan ışığı, ışınlanma butonları.

## 2. Oyun teorisi gözüyle okuma

| Kavram | Oyundaki durum | Sonuç |
|---|---|---|
| **Ödül tarifeleri** (pekiştirme) | Sabit oran (duvar > aşama ödülü), DEĞİŞKEN oran (yumurta, çark, jackpot), sabit aralık (çark günde 1, playtime ödülü ~27 dk, görevler günlük) | Eksik olan: **değişken aralık** (rastgele zamanda gelen olay). Oyuncuyu "bir şey olabilir" diye oyunda tutan en güçlü tarife; şu an HİÇ yok > bkz. Boss olayı |
| **Öz-belirleme kuramı** (yeterlilik, özerklik, ilişki) | Yeterlilik güçlü (sayılar büyüyor, vücut büyüyor); özerklik zayıf (karar yok, B7); ilişki zayıf (B8) | Sürekli oynama (retention) için üçü de gerekir; en ucuz eklenecek ilişki: duyuru + ünvan, en etkili: ortak olay |
| **Bartle oyuncu tipleri** | Başarı odaklı ve koleksiyoncu çok iyi karşılanıyor; KEŞFEDEN ve SOSYAL oyuncu için neredeyse hiçbir şey yok | Sosyal: boss olayı/ünvan; kaşif: lobide gizli lego tuğla (bkz. 4.9) |
| **Hooked modeli** (tetik, eylem, değişken ödül, yatırım) | Eylem + ödül + yatırım (pet/koleksiyon) iyi; DIŞ TETİK (geri çağırma) yok | Bildirim opt-in + etkinlik takvimi + rozet |
| **Hedefe yaklaşma / Zeigarnik** | İlk rebirth'e kadar harika (görev zinciri, çubuk); sonrası boş (B4) | Başarım/hedefler sekmesi |
| **Doruk-son kuralı** | Oturum sonunda en iyi an çoğu kez kaçıyor: oyuncu çıkarken bir "yüksek" yok | Rebirth "EVOLUTION" töreni, çıkışta "bir sonraki hedef" |
| **Kayıptan kaçınma** | Rebirth sadece level+kası sıfırlıyor (iyi), AMA sıralama ve etiket rebirth'te düşüyor (B1, B2) | Düzelt: ömür boyu güç + rebirth ünvanı |
| **Kıtlık / sınırlı süre** | Yok (hiçbir şey kaçırılmıyor) | Sezonluk etkinlik (kıtlık ama baskısız: geri sayım yazısı yok, "kaçırırsan kaybedersin" demeden) |
| **Pozitif dışsallık** (ağ etkisi) | Arkadaş bonusu +%10/kişi (en çok 5) + davet düğmesi: iyi tasarım | Aynı mantığı ortak olaya taşı |

**Akış (flow):** ilk 2 dk çok iyi; r1-r5 (23 dk) her 2-5 dk'da rebirth: sık küçük zafer. r10'dan sonra devir ~25 dk; bu aralıkta ekranda değişen tek şey sayı. Orta oyun sessizliği tam burada (Auto Click'li oyuncu r10-r23, ~1,3 > 8 sa). Rakamlar (simulate.py): r1 2 dk, r5 23 dk, r10 1,3 sa, r20 5,6 sa, 20. aşama 8,2 sa (r23), r40 ~21 sa.

## 3. Harita ve ışık

### 3.1 Bulgular
- **Boyut/yükseklik sorun değil:** lobi 158 x 130 x 36, koridor 32 geniş x 24 yüksek: basık değil. Sorun BOYUT değil RENK ve ODAK.
- **Tek ton:** duvar (150,160,215), zemin plakaları (176,184,228 / 148,157,211), raflar da aynı aileden. Nesneler (yumurta, ayakkabı) parlıyor ama arka plan hepsini aynı griye boğuyor; kapak sanatındaki "şeker" duygusu oyunda yok.
- **Düz ışık:** Ambient 172,175,196 + Brightness 2 + hafif ColorCorrection: her yer eşit aydınlık, gölge/derinlik yok; "hero" noktaların (yumurta, kemer, çark, antrenman) çevresinde ışık havuzu yok. (Sahibi bloom ve göz alan tavan ışığını reddetti: aşağıdaki öneri parlaklık ARTIRMAZ, renk ve karşıtlık ekler.)
- **Orta alan ölü:** sol raflar (x -38) ile antrenman alanı (x 31,5) arasındaki ~70 x 88 stud'luk zemin boş; oyuncu spawn'da doğuyor ve hemen dağılıyor, lobide "buluşma yeri" yok.
- **Korridor:** göremedim (güncel ekran görüntüsü yok). Aşama başına renk değişiyor; bu iyi. Eğer koridor da tek tonsa aynı bölge-renk kuralı uygulanabilir.

### 3.2 Öneriler (hepsi görünüm; mantığa dokunmaz)
1. **Duvar rengi bölgeleri (ucuz):** her bölgenin arkasındaki duvar bandı farklı PASTEL bir renk: ayakkabı = krem-sarı, skin = pembe, antrenman = şeftali-turuncu, yumurta standı = nane, sıralama köşesi = serin lavanta kalsın, Worlds kemeri serin kalsın (sahibi 'çok parlak' demişti). `EnvironmentService.WALL_COLOR` ve `LobbyDetail` derz renkleri bölgeye göre seçilir; performans maliyeti yok. SOL/SAĞ yan değişimi YOK (sahibi istemedi).
2. **Işık = renk + karşıtlık (parlaklık değil):** `Config.Lighting.Color` doygunluk 0,10 > ~0,25, kontrast 0,06 > ~0,12, hafif sıcak TintColor; Ambient biraz daha sıcak-nötr; ışık panelleri aynı kalır (göz almıyor). **6 sıcak nokta ışık** (yumurta standı, çark, iki raf, antrenman, kemer) ışık BÜTÇESİNİ aşmadan: mevcut 64 ışığın içinde dağıtım; mobil `Performance.low` kuralı aynen geçerli.
3. **Köşe karartması (vinyet):** tam ekran saydam radyal degrade Frame (çok ucuz), dikkati merkeze toplar.
4. **Zemin:** dama plakalarının açık tonu bölgeye göre çok hafif sıcağa kayar (spawn çevresi şeftali-lavanta); yol kenarları (x = ±16) kalır.
5. **Merkez alan (ölü alanı doldur):** zemine büyük bir halka/mozaik deseni + ortada küçük podyum; şimdilik görsel, sonra "Boss olayı" arenası (4.2). Böylece lobinin KALBİ olur, oyuncu spawn'da toplanır ve birbirini görür.
6. **Kemer ve çark:** kemerin üstünde "COMING SOON" yerine sayaç/ilerleme çubuğu ("World 2: %40") sahibinin güncelleme takvimine bağlı olarak (4.7) dönüş sebebi olur.
7. **Koridor (göremeden):** aşama başı "STAGE N" tabelaları ve Win odası var; ek olarak "senin en iyi aşaman" işareti ve arkadan geçen diğer oyuncu hayaletleri (duvarlar özel ama oyuncular birbirini görüyor) sosyal his verir; gerçek koridor görüntüsü gelirse somutlaştırırım.

### 3.3 Önizleme (yaklaşık, ekran görüntüsü üzerinde)
- `assets/preview/lobi_yumurta_onizleme.jpg`: solda ŞİMDİ, sağda ÖNERİLEN (şeftali çark duvarı, gül sıralama duvarı, serin kemer; sıcak ışık + vinyet).
- `assets/preview/lobi_raflar_onizleme.jpg`: skin rafı pembe, ayakkabı rafı krem-sarı duvar.
- `assets/preview/lobi_plan.png`: kuş bakışı plan (renk bölgeleri, ölü merkez alan, ışık havuzları, tipik rota).
Üreticiler: `tools/preview/lobby_grade_preview.py` (Blender Python), `tools/preview/lobby_plan.py` (SVG > Chrome). Beğenmezsen renkleri/kuvvetleri tek satırdan değiştirip yeniden üretirim; beğenirsen Studio'ya aynı değerlerle uygularım ve ekran görüntüsüyle birlikte ince ayar yaparız.

## 4. Geliştirme fikirleri (öncelik sırasıyla, her biri oyun teorisi gerekçesiyle)

Etki: ne kadar oyuncuyu geri getirir/tutar. Çaba: S = bir tur, M = birkaç tur, L = büyük. Hepsi sahibinin onayını bekler.

### Önce düzelt (küçük ve mantık hatası gibi)
**4.1 Ömür boyu güç panosu + rebirth ünvanı (B1, B2) | Etki yüksek | Çaba S**
- LEG MUSCLE panosunu "TOTAL POWER" yap: profilde ömür boyu kazanılan kası ('LifetimeMuscle', kayıtlı; eski kayıtlarda başlangıç = güncel kas) tut, pano onu sıralasın. Böylece rebirth sıralamayı DÜŞÜRMEZ, tersine ilerleme yukarı taşır.
- İsim etiketi: "Lv.N" yerine KALICI statü: `★12 Titan` (rebirth sayısı + ünvan) ve altında ad; ünvanlar rebirth aralıklarına göre (örn. Rookie 0, Trainee 1, Athlete 3, Brawler 6, Champion 10, Titan 15, Legend 25). Ünvan yumurta/aşama gibi görünür başarıdır (statü sinyali); bedava (Win/Robux istemez). Güç yazısı "ömür boyu" ya da kısaltılmış kalır.

### Dönüş sebebi (D1-D7-D30)
**4.2 Merkez alanda SUNUCU BOSS DUVARI (değişken aralık + ortak hedef + sosyal) | Etki çok yüksek | Çaba M-L**
- Her ~12-20 dk rastgele bir anda (değişken aralık!) lobinin merkezinde dev bir "Boss Wall" belirir: kısa bir ses + üstte küçük bildirim ("BOSS WALL in 10 s!"), zeminde halka. Sunucudaki herkes yanına gelip tekmeler; ortak can havuzu, katılan herkesin hasarı toplanır; 60-90 sn'de kırılmazsa kaçar (kimse cezalanmaz).
- Can = sunucudaki oyuncuların "tipik hasarı" x katılan sayısı x ~40 tekme; yani yeni ve eski oyuncu birlikte kırar (güçlü oyuncu "taşıyıcı" değil, hasar oranı ödül EŞİĞİ için sayılır, pay için DEĞİL: bedavacı sorunu yok, kimse sömürülmez).
- Ödül (katılan herkese): aşamaya göre Win, Luck/Muscle iksiri şansı, nadiren pet. Kırılışı özel parçacık ve ekran sarsıntısı.
- Neden: (a) lobinin ölü merkezini kullanıyor, (b) duvarlar özel olduğu için olmayan ORTAK an, (c) "ne zaman çıkacak?" merakı oyuncuyu bekletir (değişken aralık), (d) yeni gelen oyuncu ilk dakikalarda kalabalık ve hareket görür (sosyal kanıt), (e) arkadaş bonusuyla aynı pozitif dışsallık.
- DİKKAT: CLAUDE.md'deki "duvarlar HER OYUNCUYA ÖZELDİR, sunucuda Part oluşturma" kuralı kişisel duvarlar içindir; Boss Wall bilerek ORTAK tek bir model olurdu: bu istisnayı sahibi onaylamalı. Performans: tek model + istemci parçacıkları, bütçeyi etkilemez.

**4.3 Roblox rozetleri + Hedefler (Goals) sekmesi (B4, B9) | Etki yüksek | Çaba M**
- Quests penceresine üçüncü sekme **GOALS** (NEW PLAYER | DAILY | GOALS): ömür boyu kademeli hedefler ("100 / 1.000 / 10.000 duvar kır", "Rebirth 5 / 10 / 25", "50 yumurta aç", "Legendary pet", "5 pet birleştir", "Index 15/30", "Win Pad 100 kez"), her kademede ödül: iksir, Win, pet slotu, ünvan; çerçeve zaten var (NEW PLAYER sekmesi gibi, CLAIM akışı hazır). Rebirth sonrası "boş ekran" sorununu çözer.
- Aynı kilometre taşları için **Roblox rozeti** (BadgeService): oyuncunun profilinde görünür (bedava reklam, statü, "tamamlama" hissi). 6-8 rozet yeter (Welcome, First Rebirth, Stage 10, Stage 20, Legendary Pet, Mythic Pet, 10 Rebirth, Boss Slayer). Not: rozet OLUŞTURMA Roblox'ta küçük Robux maliyetli olabilir (sahibi Creator Hub'da yapar); kodu ben yazarım.

**4.4 Deneyim bildirimi izni (geri çağırma) | Etki yüksek | Çaba S (kod) + sahibi (Open Cloud)**
- `ExperienceNotificationService:PromptOptIn()`: ilk rebirth'ten sonra BİR KEZ Roblox'un kendi penceresiyle "bildirim al?" sorulur. İzin veren oyuncuya çark hazır/etkinlik/yeni dünya için bildirim gönderilebilir (Open Cloud ile; sahibi tarafında bir kerelik kurulum). D7 ve D30 için en ucuz geri çağırma yolu. Tamamen izne bağlı, baskı yok.

**4.5 Sezonluk etkinlik çerçevesi: önce CADILAR BAYRAMI (31 Ekim, 18 gün sonra) | Etki yüksek | Çaba M**
- `Config.Events` (başlangıç/bitiş UTC): etkinlik süresince lobi süsü değişir (turuncu-mor ton, balkabakları: renk bölgeleri sistemi 3.2'yi yeniden kullanır), 'Spooky Egg' (SADECE etkinlikte, Win ile; 5 sınırlı pet: hayalet, yarasa vb.; havuz 50/30/13/5/2 kuralına uyar), etkinlik görevi, çarkta etkinlik dilimi. Etkinlik biter, pet kalır (kıtlık = sadece o dönemde alınabilir).
- Neden: kıtlık + yenilik; Roblox ana sayfa algoritması güncel oyunları öne çıkarır; oyuncuya geri dönme sebebi; aynı çerçeve Noel/Yılbaşı için tekrar kullanılır. Ücretli rastgele ürün kuralı: etkinlik yumurtası Win ile alınır, yüzdeler görünür, kısıtlı hesapta kapalı (aynı kapı).

### Oyuncuyu tut (oturum uzunluğu)
**4.6 Win harcama yerleri ve gerçek kararlar (B5, B7) | Etki orta-yüksek | Çaba M**
- **Pet slotları:** takılı pet sayısı 3'te sabit (MaxEquippedPets). 4. ve 5. slot kalıcı, yalnızca Win ile (örn. 250K ve 5M; bugün satılmıyor, Robux ürünleriyle çakışmaz). Çarpan hesabı (3 pet toplamı) ve simulate.py güncellenir; ek slot geç oyunda egg grind'a anlam verir.
- **Gym Upgrades (kalıcı, Win ile 6-8 basamak):** yürüme hızı, kazanç yazıları/QoL, yumurta animasyon hızı, "Lucky Charm" (en çok +%5 şans: iksirle çakışmasın diye tavanlı), antrenman pedi süresi gibi. Karar: sınırlı Win'i hangisine koymalı? (gerçek takas).
- **Pahalı yumurtalar:** Galaxy 50K sabit kalırsa 20. aşamada anlamsızlaşır; Worlds ile gelecek yumurtaları 10x-100x pahalı ve daha iyi şanslı planla.
- **Pet rolleri (orta vadede):** hepsi sadece kas çarpanı; bir kısmı Win bonusu, bir kısmı yumurta şansı versin: "Equip Best" artık tek doğru cevap olmaz (karar). Büyük iş: denge yeniden ölçülür.

**4.7 İçerik takvimi (B6) | Etki çok yüksek | Çaba L**
- "Günde 1 saat, 10-15 günde bitir" hedefi yüzünden ilk grup en geç 10. gün bitiş duvarına çarpar. İKİNCİ DÜNYA için asgari plan: aynı koridor çerçevesi, 20 yeni tema, 6 yeni yumurta (daha pahalı/güçlü), yeni ayakkabı/skin seti, çarpanlar ~x10 yukarıdan, Worlds kemeri açılır. Çerçeve hazır olduğu için "yeni içerik" büyük ölçüde Config + tema + model işi.
- Haftalık ritim: her hafta küçük bir güncelleme (yeni pet/etkinlik); Roblox "yeni güncellenmiş" oyunları daha çok gösterir.

**4.8 Sosyal kanıt ve gösteriş (B8) | Etki orta | Çaba S-M**
- **Nadir pet duyurusu:** artık nadirlik şansa göre olduğu için Legendary (%5) ve Mythic (%2) anlamlı: sunucuya küçük üst bildirim ("Ali hatched a MYTHIC Titan!") + açan oyuncuda altın efekt. Duyuru ücretsiz sosyal kanıt, merak ve istek yaratır.
- **Rebirth/ünvan duyurusu:** "Zeynep reached ★10 Champion!" (sadece eşik rebirth'lerde, spam olmasın).
- **Gösteriş:** küçük emote ("flex" pozu) ya da basit el sallama; lobi merkezi (3.2.5) ve podyum bu sahneyi taşır.

**4.9 Keşif ve sürpriz (kaşif oyuncu) | Etki orta | Çaba S-M**
- Lobide gizli **Altın Tuğla**lar (günde 3-5 tane, farklı yerlerde; bulana küçük ödül); oyuncu lobiyi gezer, raflara/köşelere bakar. Kıtlıksız, baskısız. (Aktif oyuna ödül için eski "Golden Brick on the wall" fikri de aynı sistemle birleşir.)

**4.10 Geç oyun toplu yumurta deneyimi (B5 devamı) | Etki orta | Çaba S**
- Geç oyun = x10 / otomatik yumurta (tek animasyon atlanıyor). Çoklu açılışta en iyi pet büyük kart olsun, diğerleri hızlı şerit; Mythic/Legendary çıkınca o tek kart patlasın. Böylece "spam E" tatmin edici kalır ve yumurta açma animasyonu yatırımı boşa gitmez.

### Başka
**4.11 Rebirth "EVOLUTION" töreni | Etki orta | Çaba S-M:** oyunun adı "Evolution"; rebirth'te kısa, ekranı kapatmayan (sahibi büyük ortada yazı istemiyor) bir sahne: karakter ışıkla parlar, yeni ünvan altın kayan şerit olarak üstte belirir. Doruk-son kuralı: oturumun en iyi anı.
**4.12 Başlangıç paketi (tek seferlik, 49 R$ civarı) | Etki orta (gelir) | Çaba S:** Pet Space + Rainbow potion + özel bir kozmetik; geri sayım ve baskı yazısı YOK. Sadece Robux fiyat tavanı (150) ve kısıtlı hesap kuralları korunur.
**4.13 Ölçüm:** Analytics Funnels (Joined > FirstRebirth) + özel olaylar: ilk gün oturum sayısı, ilk rebirth'ten sonraki 10 dk'da oyuncu kaybı (B4), ilk Boss olayına katılım. Hedef (tahmin): ilk oturum >= 10 dk, D1 >= %20-25, D7 >= %8-10.

## 5. Önerilen sıra

| # | İş | Etki | Çaba | Neden bu sırada |
|---|---|---|---|---|
| 1 | 4.1 Ömür boyu güç panosu + rebirth ünvanı | Yüksek | S | Mantık hatası, risksiz, hemen düzelir |
| 2 | 3.2 Renk bölgeleri + ışık + vinyet + merkez halka (önizleme onaylanırsa) | Yüksek (ilk izlenim) | S | Ucuz, hemen görünür; Halloween süsünün temeli |
| 3 | 4.5 Etkinlik çerçevesi + Halloween (18 gün) | Yüksek | M | Zaman kritik; çerçeve sonra tekrar kullanılır |
| 4 | 4.3 Goals sekmesi + rozetler, 4.4 bildirim izni | Yüksek | M / S | Rebirth sonrası boşluğu doldurur, geri çağırır |
| 5 | 4.8 Nadir pet / rebirth duyurusu | Orta | S | Bedava sosyal kanıt |
| 6 | 4.2 Boss Wall (merkez alan) | Çok yüksek | M-L | En büyük etki, ama yeni sistem: onay + test ister |
| 7 | 4.6 Pet slotları + Gym Upgrades | Orta-yüksek | M | Win'e anlam, simulate.py ile dengelenir |
| 8 | 4.7 İkinci dünya | Çok yüksek | L | Ayrı ve uzun plan; ilk grup bitirmeden hazır olmalı |

## 6. Sahibine sorular (cevaba göre sırayı sabitlerim)
1. Önizlemedeki renk bölgeleri + sıcak ışık yönü beğenildi mi? (beğenilmezse hangi renkler?)
2. Boss Wall (ortak, merkez alanda) fikri "çok fazla" mı yoksa istenir mi? (özel duvar kuralına istisna)
3. Cadılar Bayramı etkinliği (31 Ekim) yapalım mı, süre yeter mi?
4. Rebirth ünvanları ve nametag'de "★N Ünvan" tamam mı? (Lv.N yerine geçer)
5. Bildirim izni ve rozetler için Creator Hub'da senin yapacağın küçük adımları (rozet oluşturma, Open Cloud anahtarı) yapar mısın?

## 7. Önceki analizden hâlâ geçerli ölçüm planı
Analytics > Funnels sırası (Config.Funnel): Joined > Clicked30 > FirstWall > FirstPet > FirstSkin > Level12 > FirstRebirth. 1>2 kaybı açılış/yükleme/kontrol sorunu, 2>3 duvara yönlendirme, 3>4 ilk pet yönlendirmesi, 6>7 orta oyun sessizliği ve rebirth korkusu. D1 ve ortalama oturum süresi de izlenir. Yeni adım SONA eklenir, sıra değişmez.
