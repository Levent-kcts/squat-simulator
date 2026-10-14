# 04 - Retention + Monetization Oyun Kitabi (Roblox simulator, 2025-2026)

Hazirlayan: araştırma ajanı (salt okunur web araştırması; oyun koduna dokunulmadı)
Tarih: 2026-10-14 (Çarşamba). Oyun: "+1 Squat Evolution: Smash Walls" (canlı: 2026-10-11, 14 günde ~16 oyuncu).

> Bu belge Türkçedir; oyun içi metin önerileri İngilizce bırakıldı. Her iddianın yanında kanıt güveni rozeti var. Rozetler aşağıda.

---

## 0. Önce dürüst durum tespiti (en önemli 6 madde)

1. **n = 16 ile retention/monetization "optimize edilemez".** 100 yeni oyunculuk bir kohortta bile D1 ölçümünün %95 güven aralığı yaklaşık ±7 puandır (p=%15 için SE = √(0.15·0.85/100) = 3.6 puan). 16 oyuncuda D1 "%12 mi %25 mi" ayırt edilemez. Bu yüzden bu belgedeki "beklenen etki" sütunları HİPOTEZDİR, ölçülmüş sonuç değil. Şu an en değerli iş: **keşfedilebilirlik + ilk dakika hunisi + ölçüm altyapısı**. (Bölüm 9)
2. **Roblox'un resmi öneri algoritması (Recommended For You, RFY) Haziran 2026'dan beri 28 günlük pencereye bakıyor** ve kişi başı ortalama ile çalışıyor; küçük oyunlar "az oyuncu" yüzünden cezalandırılmıyor, zayıf başlangıç için ceza yok. Sinyaller: oynama günleri (play days), oynama süresi (günlük 60 dk ile sınırlı), ilk-oyun bounce (60 sn altı ve 61-180 sn), **arkadaşla bilinçli birlikte oynama günleri (co-play)**, **harcama günleri** ve **kişi başı Robux**. Yani "tek seferlik büyük satın alma" yerine "çok sayıda gün oynama, arkadaşla gelme, farklı günlerde küçük harcama" ödüllendiriliyor. [RESMİ]
3. **Gerçekçi D1/D7/D30 referansı:** GameAnalytics 2026 (500+ oyun, 1M+ MAU): medyan D1 %10.3 / D7 %1.6 / D30 %0.5; p75-p90 D1 %12.9-15.9; p99 D1 %22.2 / D7 %9.1 / D30 %4.7. İnternette dolaşan "%20 D1 iyi, %40 mükemmel" ve BLOXG'un "simulator %32/14/6.2" tabloları örneklem yanlılığı/pazarlama içeriyor, GameAnalytics bunları açıkça şişirilmiş buluyor. Hedef: **D1 >= %15 "iyi", >= %20 "çok iyi"**. [ÖLÇÜM] + [ŞÜPHELİ]
4. **Politika tarafı bizde büyük ölçüde hazır** (PaidRandomPolicy, oran gösterimi, Luck iksiri dinamik oranı). Ama iki açık var: (a) kısıtlı hesaplar (UK/BR/AU/NL/BE) için yumurta tamamen kapalı = ana döngü yok -> Roblox'un önerdiği "sabit sırayla açılan yumurta" yolu yok, (b) "çarpılı pet anında silinir, yumurta ücreti alınır" gri alan. (Bölüm 2.8)
5. **Kimsenin kanıtlamadığı şeyler çok:** "arkadaş edinen 3x D30", "haftalık live-ops +%30 D1", "limitli teklif dönüşümü 2x" gibi rakamlar ajans/blog pazarlamasıdır; kaynaksızdır. Bu belge bunları ayrı etiketledi, plan buna dayanmıyor.
6. **Sahibin kuralları korundu:** reddedilenler (günlük giriş ödülü, promosyon kodu, lobi görev panosu, bloom/göz alıcı ışık, üst ilerleme çubuğu) önerilmedi. Sahibin cevabını beklediği fikirler (Boss Wall, Goals sekmesi, rozet, bildirim izni, Halloween etkinliği, ünvanlar, renk bölgeleri) ve "Robux işleri en sona" kuralı backlog'da **ONAY** ve **ROBUX-AŞAMASI** etiketiyle işaretlendi.

### Kanıt güveni rozetleri
- **[RESMİ]** Roblox Creator Hub dokümanı / Roblox DevForum duyurusu / Roblox newsroom / SEC dosyası
- **[ÖLÇÜM]** Büyük örneklemli, metodu belli üçüncü taraf ölçüm (GameAnalytics)
- **[VAKA]** Belgelenmiş ama tek vaka/gazete/wiki (doğrulanabilir, genellenemez)
- **[ANEKDOT]** Forum yorumu, tek geliştirici gözlemi, hayran wiki'si
- **[ŞÜPHELİ]** Kaynaksız / pazarlama amaçlı / iç tutarsızlık içeren rakamlar

---

## 1. Retention: benchmark'lar ve hangi sistem neyi oynatır

### 1.1 Benchmark tablosu (kimin rakamına güvenilir?)

| Kaynak | D1 | D7 | D30 | Not / güven |
|---|---|---|---|---|
| GameAnalytics 2026 Roblox raporu, medyan oyun (500+ oyun, 1M+ MAU, Ağu 2025-Tem 2026) | %10.3 | %1.6 | %0.5 | [ÖLÇÜM] Büyük, olgun oyunlar; yeni/küçük oyunlar farklı olabilir. p25: 8.4/1.0/0.3 |
| GameAnalytics p75-p90 (rapor "gerçekçi tırmanış" diyor) | %12.9-15.9 | - | - | [ÖLÇÜM] |
| GameAnalytics p99 | %22.2 | %9.1 | %4.7 | [ÖLÇÜM] "Üstün D30 neredeyse hep büyük IP ya da kalıcı ilerleme derinliği olan oyunlarda" |
| BLOXG "Simulator" | %32 | %14 | %6.2 | [ŞÜPHELİ] 850 "tanıtılan" oyun, metod/örneklem açıklanmamış, satış sayfası |
| rolearn.dev "Simulator iyi/mükemmel" | %35/50 | %18/28 | - | [ŞÜPHELİ] kaynaksız, iç tutarsızlık (kendi örneği 4x diyor, 1.6x çıkıyor) |
| Roblox'un kendi dokümanı | rakam yok | rakam yok | rakam yok | [RESMİ] "benzer oyunlara göre" yüzdelik (50-90. yüzdelik) gösterir, sadece günlük >= 100 DAU olan oyunlar için |

Diğer GameAnalytics sayıları (oyunun beklentilerini kalibre etmek için): oyun seansı medyanı 9.8 dk (p95 16.6); oyuncu başına günlük oyun süresi medyanı 22.4 dk; oyuncuların %3.80'i bir yıl içinde bir şey harcamış; harcayan oyuncunun yıllık medyan harcaması 0.81 dolar (p90 8.88, p95 20.31, p99 86.36); oyun ARPPU medyanı 0.70 (p90 2.33, p99 55.31). "D1 FTUE, D7 ilerleme, D30 sosyal" bir yapımcıdan alıntı. [ÖLÇÜM]

Kaynaklar: https://www.gameanalytics.com/reports/2026-roblox-report , https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox , https://bloxg.com/statistics/roblox-retention-benchmarks , https://rolearn.dev/guidance/first-week-retention-optimization/

**Yorum:** Simulator'a özgü, güvenilir, açık bir D1/D7/D30 tablosu bulamadım. Elinizdeki en iyi karşılaştırma aracı Creator Hub > Analytics > Retention ve Acquisition > Home Recommendations ekranları (>= 100 DAU olunca benzer-oyun yüzdelikleri de gelir). https://create.roblox.com/docs/production/analytics/retention

### 1.2 Roblox'un resmi retention reçetesi (dokümandan)
- **D1'i yükselt:** çekirdek döngü net, eğlence ~5 dakika içinde, kısa onboarding, cihaz/performans testi. **D7'yi yükselt:** kısa ve uzun hedefli ilerleme sistemi, oyuncuların hangi seviyeye ulaştığını izle, tempoyu ayarla. **D30'u yükselt:** **küçük içerik güncellemeleri 2-4 haftada bir, büyük özellik güncellemeleri 2-3 ayda bir**, sosyal özellikler (ticaret, parti, lonca, PvP, turnuva, **liderlik tabloları**). [RESMİ] https://create.roblox.com/docs/production/analytics/retention
- **Onboarding:** ilk dakikalarda çekirdek döngüyü yaptırarak öğret, ilerleme eşiklerini düşük tut, onboarding sonunda "sevinç anı" (ödül/animasyon/efekt) ve kısa/orta/uzun hedefleri göster; tutorial adımlarını Experiments ile A/B test et. [RESMİ] https://create.roblox.com/docs/production/game-design/onboarding
- **LiveOps:** içerik temposu haftalıktan aylığa (ekip kapasitesine göre); sezonluk/sınırlı etkinlikler; büyük güncellemeler (sosyal sistemler, koleksiyon, rekabet) aylar sürebilir; ekibi yakma. [RESMİ] https://create.roblox.com/docs/production/game-design/liveops-essentials

### 1.3 Roblox keşif algoritması (RFY) ve bizim için anlamı
| Sinyal (kişi başı ortalama; sadece Home'daki RFY'den ORGANİK gelenler sayılır) | Kademe | Bizim için ne demek |
|---|---|---|
| Play-through rate, **first-play bounce** (60 sn altı ve 61-180 sn), **play days**, **playtime** (günde en fazla 60 dk sayılır) | "Most important" | İlk 3 dakika (hunimiz) + günlük dönüş nedeni. Günde 60 dk üstü ödüllendirilmez: oyunun 8 saati 1 saat/gün = 8 oyun günü eder. |
| **Intentional co-play days** (arkadaşla davet/katılma/özel sunucu yoluyla birlikte oynanan gün), qualified play sessions, **spend days**, Robux spent | "Important" | Arkadaş getirme ve **farklı günlerde küçük harcama** (aylık abonelik/küçük paketler) tek büyük satın almadan değerli olabilir. |

Pencere: Gün 1, Gün 2-7, Gün 8-28. Yeni oyunlar 28 gün beklemez; erken sinyaller hemen kullanılır. Zayıf başlangıçta ceza yok; algoritma yeni kullanıcılarla yeniden dener. Reklamla gelen kullanıcılar RFY sinyallerinden **hariç**. Sinyal ağırlıklarının sayısal değerleri açıklanmadı (grafik görsel). [RESMİ]
Kaynaklar: https://create.roblox.com/docs/discovery , https://create.roblox.com/docs/discovery-faq , https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox , https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575 , RDC 2026: "genç oyuncular kısa, yaşça büyükler dönüp geldikleri oyunları tercih ediyor; sıralama ilk 28 güne ve ötesine bakıyor; yeni oyuncu getirme (growth) hedefi test ediliyor" https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play

Önemli: 16+ etiketli bir oyunun kitlesi tam olarak "büyüklerin" havuzu; Roblox yaşa göre farklı optimize ediyor, bu derin/geri dönülen oyunlara (Dünya 2, günlük sistemler) lehine.

### 1.4 Hangi sistem retention'ı gerçekten oynatıyor? (kanıtlı mı, hype mı?)

| Sistem | Kanıt | Güven | Not |
|---|---|---|---|
| Hızlı çekirdek döngü, ~5 dk'da eğlence, ilk oturumda "sevinç anı" | Roblox onboarding + retention dokümanı | [RESMİ] (öneri, nedensellik ölçümü yok) | Bizde var: 30 tık > duvar > ilk pet; yumurta kırma animasyonu |
| Arkadaşla oynama | Roblox: "co-play seansları solo'dan ~1.9x uzun" (2024 Q2, korelasyon) ve RFY'de ayrı sinyal | [RESMİ] korelasyon | "Arkadaş edinen D30'u 3x" [ŞÜPHELİ] kaynaksız |
| Sık güncelleme / etkinlik | Blox Fruits Eylül 2022 güncellemesi CCU'yu bir gecede ikiledi; Grow a Garden CCU'su büyük güncellemelerle 5M > 11.7M > 16M atladı, iki etkinlik ekibi kurdu | [VAKA] | Tek oyunluk gözlem; "haftalık live-ops D1'i %30 artırır" [ŞÜPHELİ] (ajans pazarlaması) |
| Haftalık sabit güncelleme ritmi (BIG Games: her Cumartesi 5 PM GMT) | PS99 | [VAKA] | Oyuncu eleştirisi: haftalık tempo hata ve "her hafta satmaya çalışma" hissi veriyor [ANEKDOT] |
| Sezonluk etkinlik (Halloween/Noel) | PS99 Halloween 2025: 18 Ekim-20 Aralık (hayran wiki'si); GAG Ghoul Garden: 11 Ekim'de başladı, bitiş kaynaklara göre 25 Ekim ile 1 Kasım arasında (çelişkili), Candy Corn para birimi, 3 mağaza | [VAKA] | Etkinlik para birimi + etkinlik mağazası + limitli petler ortak kalıp |
| Ödül/yarış turu liderlik tabloları | Roblox D30 önerisi; PS99 Pet Games (top 100/500/5000'e kademeli Huge) | [RESMİ] öneri + [VAKA] | |
| Koleksiyon/Index, birleştirme | Adopt Me Neon/Mega Neon; BGS Mastery; PS99 Huge/Titanic statü hedefi | [VAKA] | Bizde var: Pet Index + 3'lü birleştirme |
| Çevrimdışı birikim | GAG: bitkiler çevrimdışıyken de büyür, dönene hep toplanacak şey var | [VAKA] | Bizde var: Config.Offline + OfflinePanel |
| Günlük "streak" girişi | BLOXG/rolearn öneriyor | [ŞÜPHELİ] | **Sahip reddetti** (günlük giriş ödülü); önerilmiyor |
| Promosyon kodları | Ürün hikayelerinde yaygın (Discord/Trello) | [VAKA] yaygınlık, retention kanıtı yok | **Sahip reddetti**; önerilmiyor |
| Reklam alımı | Roblox: reklamla gelenler RFY'den hariç; bir geliştirici reklamın D1'i düşürdüğünü bildirdi (%3 > %5-8 reklam kapatınca) | [ANEKDOT]/[RESMİ] | Bu ölçekte ücretli reklam öncelik DEĞİL |

---

## 2. Monetization: küçük ölçekte dönüşen şeyler

### 2.1 Fiyat noktaları - ne biliniyor, ne bilinmiyor
- **Roblox hiçbir fiyat rehberi yayınlamıyor.** Resmi "Monetization foundations" ve starter/bundle dokümanları kalitatif; sayı yok. [RESMİ] https://create.roblox.com/docs/production/game-design/monetization-foundations , https://create.roblox.com/docs/resources/feature-packages/bundles
- Üçüncü taraf rehberler (hepsi [ŞÜPHELİ]/[ANEKDOT], kaynak göstermiyor, birbiriyle çelişiyor): giriş bandı 25-100 R$ (dönüşüm %2-8), çekirdek 99-199 R$ (2x çarpan geçişleri), premium 250-750, 1000+ ~%0.5; "9 ile biten fiyat daha iyi" ile "yuvarlak fiyat daha iyi" çelişiyor. https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide , https://www.creation.dev/learn/how-to-price-game-passes-roblox , https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/
- **Tek ölçülü ipucu:** GameAnalytics "düşük fiyatlarda kademeli geçiş ve net değer" harcayan başına birkaç dolara çıkarıyor. [ÖLÇÜM] (yorum düzeyi)
- Sizin merdiveniniz (25/39/59/75/79/119/149) zaten bu bantlara oturuyor. Yeni ürünlerde "kural 150 R$ üstü yok (4 pass hariç)" korunmalı.
- **Net kazanç:** geliştirici payı %70 (pass/ürün). 49 R$ > 34 net, 99 > 69, 149 > 104, 199 > 139. DevEx standart oranı 0.0038 $/Robux (5 Eylül 2025'ten beri); **ABD'li 18+ doğrulanmış oyuncuların harcamalarında 0.0054 $/Robux (8 Haziran 2026'dan beri)**, ama oyun karakterleri %100 R15 olmalı (R6'ya geçiş yok). 149 R$'lik bir pass satışı = 104 Robux = standart oranda ~0.40 dolar, ABD 18+ oranında ~0.56 dolar. Çekime ulaşmak (30,000 Earned Robux) için ~288 adet 149 R$ satışı gerekir. [RESMİ] https://create.roblox.com/docs/production/monetization/18-plus-devex-rate
  - Oyunun R15 kullandığı CLAUDE.md'den anlaşılıyor; Creator Hub'da bu orana uygunluğun görünüp görünmediğine bakılmalı. Bedava potansiyel avantaj (16+ ve yaşı doğrulanmış kitle ABD'li 18+ içerebilir).
- **Bölgesel fiyatlandırma** pass'ler için opt-in (varsayılan kapalı); bölgeye göre en düşük %30'a kadar iner, VPN'ci en yüksek fiyatı görür; fiyatlar `GetProductInfo` ile dinamik gösterilmelidir (sert kodlanmış fiyat yanlış görünür). Bölgesel veri olmadan açmayın. [RESMİ] https://devforum.roblox.com/t/introducing-regional-pricing-for-passes/3621382
  - **Aynı gerekçe Roblox Plus için de geçerli:** Plus aboneleri 10% (ilk 2 ay) / 20% (3. aydan) indirim görür, Roblox farkı ödediği için sizin geliriniz değişmez ama ShopPanel'de sabit "R$ 149" yazıyorsa abone yanlış fiyat görür. Dokümana göre `GetProductInfoAsync` / `GetDeveloperProductsAsync` ile gösterin. [RESMİ] https://create.roblox.com/docs/production/monetization/roblox-plus

### 2.2 Starter pack
- Roblox, "Bundles" özellik paketinde starter paketi tarif ediyor: yeni oyuncuya indirimli paket, **RelativeTime** (örnek 24 saat, oturumlar arası sürer), **FixedTime** (tatil ayı gibi), **OneTime** (örneğin para bittiğinde bir kere çıkan teklif); aynı teklifin otomatik yeniden başlamasını paket zaten engelliyor (`singleUse`). Örnek paket "Save 75%" ve içindeki ürünler 49/99/149 R$. [RESMİ] https://create.roblox.com/docs/resources/feature-packages/bundles
- Bir Roblox analitik PM'i düşük ödeme dönüşümüne "starter pack / yeni oyuncu bonusu / mağazayı daha keşfedilir yap" önerdi. [RESMİ/ANEKDOT] https://devforum.roblox.com/t/super-low-payer-conversion-rate/3411035
- Endüstri uyarısı: starter pack çoğunlukla çok ucuz fiyatlanır; ilk satın alma "çıpa" olur; kısa vadeli dönüşümü değil uzun vadeli değeri ölç. (54 F2P profesyoneli anketi; %96'sı starter'ı 10 doların altında fiyatlıyor.) [VAKA/anket] https://www.deconstructoroffun.com/blog/2024/4/8/free-to-play-starter-pack-pricing-when-conversion-is-king-we-may-price-too-low
- **Bize uyarlama:** Win paketlerinin Robux değeri tutarlılığı (WinValue/pricetest) bozulmamalı. İndirimi Win'den değil **özel bir iz/ek kozmetik + iksirden** yap. İçerik deterministik olsun (rastgele öğe girerse tüm paket "ücretli rastgele ürün" olur, aşağıda 2.8).

### 2.3 2x/3x pass, VIP, kolaylık pass'leri
- Bu tür pass'lerin (2x kazanç, otomasyon) simulator'larda en çok satan kalıp olduğu yaygın söyleniyor ama **ölçülmüş veri yok**; GameAnalytics yalnızca "kademeli pass'ler ve düşük fiyatlarda net değer" diyor. PS99 örneği: Triple/Octuple Eggs ve Auto Tap/Auto Farm tipi kolaylık pass'leri ana gelir kalemi olarak anılıyor [VAKA]; Blox Fruits "çarpanlar, sıfırlama ve hız" gibi kolaylıkları satıyor [VAKA]. https://naavik.co/deep-dives/roblox-blox-fruits-brookhaven-adopt-me/ , https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire
- Sizde zaten: Auto Click 149, VIP 149, Egg Auto/Multi 199/249, Coach pad 199/299, Rebirth Skip 119, Offline double 29. Boşluk: **abonelik** ve **sezon**.

### 2.4 Abonelik (Roblox Subscriptions) - uygulanabilir mi? EVET
- **Robux fiyatlı abonelik herkese açık** (1 Nisan 2026 duyurusu): taban 49 Robux, her ay %70 pay (yerel para aboneliğinde 2. aydan itibaren %100, Robux aboneliğinde her ay %70), fiyat 60 günde bir değişir (artış için 30 gün önceden bildirim), bölgesel fiyat otomatik açık ve kapatılamaz, 5 gün tutma süresi, iade edilemez. Yerel para (USD 2.99/4.99/7.99/9.99/14.99) için kimlik/telefon doğrulaması gerekir, ilk ay %70, sonra %100; sadece Web/App Store/Google Play'de. Oyun başına en çok 50 abonelik. [RESMİ] https://create.roblox.com/docs/production/monetization/subscriptions , https://devforum.roblox.com/t/let-your-players-pay-for-subscriptions-within-experiences-in-robux/4552995
- Kurallar: aynı faydalar her platformda; tüm dönem boyunca verilmeli; ödeme sonrası ek görev şartı yok; "Bronz/Gümüş/Altın" gibi birbirini dışlayan kademeler desteklenmiyor; pass'i aboneliğe çevirmek hızlı yol. [RESMİ]
- Roblox'un kendi rakamı: abonelik ekleyen yaratıcılar için **ortalama %7 daha yüksek oyun içi harcama** (2024, Roblox'un kendi iddiası). [RESMİ/kendi beyanı] https://devforum.roblox.com/t/increased-payouts-for-subscriptions-within-experiences/2963619
- Tasarım rehberi: para paketi, öğe paketi, VIP/üyelik, sezon pass; "teslimat tutarlılığı abone tutmanın ön koşulu"; ayda bir gelen akış derin çekirdek döngüyü besler. https://create.roblox.com/docs/production/game-design/subscription-design
- **Spend-days sinyali:** aylık yenileme her ay bir "harcama günü" yazar; sık küçük harcama RFY'de değerli. [RESMİ ima, ağırlık bilinmiyor]
- Öneri: **"Squat Club" - 149 R$/ay** (bkz. Bölüm 7). Fayda tasarımı: her ay hemen verilen küçük paket (iksirler + belirli sayıda Win) + kalıcı kozmetik "Club" auralı/etiketi + biraz daha hızlı Playtime Reward turu; "günlük giriş ödülü" gibi çalışan günlük claim YAPMA (sahip reddi) - aylık paket tek seferde claim edilir.

### 2.5 Roblox Plus (Premium'un yerine, 30 Nisan 2026)
- Aylık 4.99 dolar; Premium'un üç kademesini değiştirdi. Premium Payouts / Engagement-Based Payouts **24 Temmuz 2025'te kaldırıldı**. Plus indirimini Roblox karşılıyor; **oyun içinden Plus satışı yaparsanız (`PromptRobloxSubscriptionPurchase`) yeni abone başına 3 ay boyunca ayda 250 Robux (en çok 750)**; ücretli özel sunucuda aboneden 60+ dk geçerse abone başına en çok 100 Robux. Ödül sunucuda `HasRobloxSubscription` doğrulanmadan verilmemeli. [RESMİ] https://create.roblox.com/docs/production/monetization/roblox-plus , https://www.tubefilter.com/2026/04/13/roblox-plus-creator-payouts/
- İlk 4 ayda Plus teşvikleri yaratıcılara 300 milyon Robux'tan fazla kazandırmış. [RESMİ/Roblox beyanı] https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play
- **Bize uyarlama:** Shop'ta düz, baskısız, tek bir "Get Roblox Plus (discount on every purchase)" düğmesi. Sahte aciliyet, ödül vaadi yok. Küçük ölçekte gelir küçük ama maliyet çok düşük (S). "Robux aşaması" işidir.

### 2.6 Özel sunucu (private server)
- Fiyat serbest, taban 10 Robux, 60 günde bir değişir; bölgesel fiyat açık. Plus kullanıcıları özel sunucuyu ücretsiz kullanır, siz kullanıma göre ödenirsiniz (100 Robux üst sınır/abone). Özel sunucuya katılma RFY'de "intentional co-play" sayılır. [RESMİ] https://devforum.roblox.com/t/upcoming-updates-to-private-servers-new-tools-and-new-earning-opportunities/4590482 , https://create.roblox.com/docs/discovery
- Bir tıklamalı idle oyunda tek kişilik özel sunucu bir değer katmaz. Anlamlı olması için **arkadaş bonusunun özel sunucuda da çalıştığından emin olun** ve "Squad" avantajını anlatın. Düşük öncelik.

### 2.7 Creator Rewards (eski Premium/engagement payouts) - nasıl tasarlanır?
- **Günlük etkileşim:** kullanıcı "Active Spender" (son 60 günde >= 9.99 dolar harcamış; yeni/yeniden-aktifleşen kullanıcı olmayan), oyununuzda gün içinde >= 10 dk geçirir ve oyununuz o günün ilk **3 deneyiminden** biridir > **5 Robux / kullanıcı / gün**; 10 dk ötesi ek ödül yok; 60 gün tutma süresi; kayıt gerekmiyor (24 Temmuz 2025). **Audience Expansion:** yeni/geri dönen kullanıcının ilk 60 günde ilk 100 dolarlık harcamasının %35'i, ama oyunun **60 gün boyunca ortalama >= 100 DAU** tutması, ID doğrulama ve DevEx hesabı gerekir. [RESMİ] https://create.roblox.com/docs/creator-rewards , https://create.roblox.com/docs/production/monetization/engagement-based-payouts
- Doküman çıkarımları (resmi rehber değil): oturum >= 10 dk, günün ilk 3 oyunundan biri olmak, retention. Bizde: Playtime Reward'ların 520 sn/720 sn eşikleri ve günlük çark/görevler zaten "erken açılacak neden" veriyor. **Yeni bir şey gerekmiyor**, sadece "ilk açılışta 10. dakikaya kadar bir sonraki hedef görünsün" kuralını koru.
- Küçük ölçekte para: 10 nitelikli kullanıcı/gün = 50 R$/gün ≈ 1,500 R$/ay ≈ 5.7 dolar (varsayım). Bu bir **ödül değil, taban gelir**: spender-ağırlıklı (16+/yaş doğrulamalı) kitle bu programa uygun.
- Share Link / `PromptLinkSharing` ile gelenlerin Creator Rewards'a atfedilmediğine dair Mayıs 2026 bug raporu var; Roblox cevap vermedi. Share link ölçümü için Creator Hub'daki Share Link analitiğine güven. [ANEKDOT] https://devforum.roblox.com/t/share-links-created-by-promptlinksharing-are-not-attributed-to-experience-for-creator-rewards/4622080

### 2.8 Politika matrisi: izinli / riskli
| Konu | Durum | Bizim durum |
|---|---|---|
| Yumurta, çark, sandık, **Robux'la (dolaylı: Win paketi) alınan** her rastgele ürün = "ücretli rastgele ürün" | Tüm sonuçlar + sayısal yüzde (toplam %100), satın almadan ÖNCE; ayrıntı açılır penceresi olabilir ama metin etiketli olmalı ("Details"), sadece (i) simgesi yetmez [RESMİ] | Yumurta paneli 50/30/13/5/2 gösteriyor. OK |
| Olasılığı değiştiren ürünler (Luck iksiri, pity) | Etkiyi sayısal anlat, aktifken oranları DİNAMİK güncelle [RESMİ] | Yapılmış. OK |
| Kazanılarak (Robux/para harcamadan) açılan rastgele ödüller | Oran gösterimi şart değil [RESMİ] | Günlük çark, Playtime, görev: muaf |
| `ArePaidRandomItemsRestricted` = true hesaplar (UK, BR, AU, NL, BE vb.; BR'de <18 ve doğrulanmamış 18+) | Şu alternatiflerden biri: ücretsiz kazanma yolu; **sabit sırada, önceden açıklanmış sonuçlar**; belirli sonucu beklenen değeriyle satmak; ürünü gizlemek/engellemek [RESMİ] | Şimdi "Egg hatching is not available" diyor = ana döngü kapalı. **Boşluk** (backlog #7) |
| Paketin içine rastgele öğe koymak | Tüm paket "ücretli rastgele ürün" olur [RESMİ] | Etkinlik/starter paketlerini DETERMİNİSTİK tut |
| Etkinlik para birimini Robux'la satmak ve onunla rastgele yumurta açtırmak | Dolaylı satın alma = oran gösterimi + PolicyService şart [RESMİ] | Event Candy ile **yumurta açtırma**; mağaza deterministik olsun |
| "Hiçbir fayda vermeyen" sonuç / kaybedilen ödeme | Uyumsuz örnek [RESMİ] | "Çarpılı pet anında silinir, ücret alınır" gri alan (düşük-orta risk): silinen pet Index'e keşfedilmiş sayılsın ya da küçük bir geri ödeme (Win/toz) versin |
| Ticaret (trading) | `IsPaidItemTradingAllowed` true değilse ücretli öğeler takas edilemez; Questionnaire'de beyan [RESMİ] | Ticaret yok, eklemeyin (moderasyon+exploit yükü) |
| Sahte kıtlık, otomatik yeniden başlayan geri sayım, "hep indirimde" fiyat, "BUY BEFORE IT'S GONE" dili | Kaçın; "View Item/Open Shop" gibi sakin dil önerilir; gerçek sınırlama heyecan yaratabilir [RESMİ] | Süre gerçekse göster, sayaç sıfırlama yok |
| Bildirimlerde sahte zaman baskısı, yem ödül | Yasak (deneyim bildirimleri) [RESMİ] | Bildirim için aşağıdaki kurallara uy |
| Beğeni/favori için ödül | "Promosyon/ödül" kuralı; topluluk: yapılamaz/riskli. Grup üyeliği ödülü topluluk konsensüsüyle güvenli [ANEKDOT] https://devforum.roblox.com/t/rewards-through-likingfavoritinginvites/233704 | Yapma. |
| Davet ödülü | Resmi **Friend Referral System** (`ReferredByPlayerId`), her iki tarafa ödül, tek seferlik/cooldown [RESMİ] | Bölüm 3 |
| Hediyeleştirme (pass gifting) | Roblox "şu an planlamıyoruz" dedi; pass/ürünlerin oyun dışı satışı 29 Mayıs 2026'dan beri kapalı, Robux bağışı için Transfers API var [RESMİ/ANEKDOT] https://devforum.roblox.com/t/gamepass-gifting-api-for-marketplaceservice/4525236 | Öneri yok. Ücretsiz arkadaş hediyesi (Win'siz) ayrı fikir. |

Düzenleyici çerçeve: Mayıs 2026'da Fairplay + NCOSE, Roblox'un yapay kıtlık ve şans tabanlı harcama tasarımları nedeniyle FTC'ye şikayet yaptı (karar yok). Oyun 16+ olsa bile "temiz" kalmak uzun vadede ucuz sigortadır. [ANEKDOT/haber] https://thenextweb.com/news/roblox-ftc-complaint-fairplay-ncse-child-safety

Kaynaklar: https://create.roblox.com/docs/production/monetization/paid-random-items , https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622 , https://create.roblox.com/docs/production/monetization , https://create.roblox.com/docs/production/promotion/content-maturity , https://create.roblox.com/docs/production/promotion/experience-notifications

### 2.9 Reklam/ödüllü video (not)
- Ödüllü video: 18 Şubat 2026'dan beri tüm uygun yaratıcılara açık; **ayda >= 2,000 tekil ziyaretçi** gerekir (şimdi değil). eCPM 6-12 dolar iddiası [ŞÜPHELİ]. https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278
- Sponsored Ads: reklamla gelen oyuncular RFY sinyallerinden hariç; bir geliştirici reklam açıkken D1'in %3, kapalıyken %5-8 olduğunu bildirdi (Roblox "inceleniyor" dedi). Düşük bütçe, tek-oyunculu keşif için güvenilir değil. [ANEKDOT] https://create.roblox.com/docs/discovery-faq , https://devforum.roblox.com/t/sponsored-ads-traffic-degrades-the-engagement-metrics-used-for-discovery-causing-paid-acquisition-to-harm-organic-ranking/4838351

---

## 3. Sosyal / viral mekanikler ve ölçümü

| Mekanik | Doğru yapılışı | Kanıt | Ölçüm |
|---|---|---|---|
| **Davet ödülü** | `PromptGameInvite` + **Friend Referral System**: Creator Hub > Engagement > Referral Rewards'ta banner (ikon, ad, tarih aralığı, davetçi başına limit, örn. 3); `GetJoinData().ReferredByPlayerId` ile her iki tarafa ödül (davetçiye Win/iksir, davetliye hoş geldin ödülü); davetli başına tek seferlik, davetçi için cooldown; sadece gerçekten KATILIM için ödül, davet sayısı için değil; bağlantı süresiz; Roblox arkadaşı olmayanlar da katılabilir; oyun >= 1 gün canlı olmalı | [RESMİ] https://create.roblox.com/docs/production/promotion/referral-system , https://create.roblox.com/docs/production/promotion/invite-prompts ; spam davet için uyarı alan geliştirici [ANEKDOT] | Referral ile gelen oyuncu sayısı, referral kohortunun D1/D7'si, oturum süresi |
| **Arkadaş bonusu (+%10/kişi)** | Zaten var. Birlikte gelmeyi "ilişkilendir": katılım yolu `GetJoinData` ile loglanır, bilinçli co-play gün sayısı | RFY co-play günü sinyali [RESMİ] | Custom event: "oturumda >= 1 arkadaş", "arkadaşla katıldı" |
| **Nadir drop duyurusu** | Legendary/Mythic açıldığında küçük, üstte, kısa sunucu içi toast ("Player hatched Mythic X!") + açan kişiye "Capture" isteği; Başka sunucuya yayma sonra | PSX'te Titanic için 13 Mayıs 2023'ten beri global sohbet mesajı [ANEKDOT hayran wiki'si]; PS99'da aynısı doğrulanmadı | Duyuruyu gören oyuncuların yumurta açma oranı (önce/sonra) |
| **Capture / Moments** | Roblox Captures API ile 30 sn'lik klip/ekran görüntüsü, geliştirici özel istem (prompt) tanımlayabilir ("hatch", "rebirth", "yeni vücut aşaması"); klip "Join" ile oyuna götürür; Moments 16+ yaş kontrollü kullanıcılara gösteriliyor (bizim kitle); videolar kullanıcı arayüzü ve isimleri otomatik gizler; Upload/Recommendation API'leri "yıl sonuna kadar" denmişti (geldi mi doğrulanmadı); Maturity Questionnaire'de medya paylaşımı sorusunu güncelle | [RESMİ] https://devforum.roblox.com/t/roblox-moments-a-new-era-of-user-generated-discovery-for-experiences-and-gameplay-is-here/3919813 , https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all | Moments kaynaklı katılım (GameJoinContext), klip sayısı |
| **Liderlik/Hall of Fame** | Mevcut ömür boyu kas panosu + haftalık "bu hafta kazanılan kas" + etkinlik panosu + kalıcı "Hall of Fame" (etkinlik şampiyonlarının adı ve kozmetiği); haftalık sıfırlanan pano geç gelenlere umut verir | Roblox D30 önerisi (liderlik tabloları) [RESMİ]; PS99 Pet Games kademeli ödül [VAKA] | Panoya bakan oyuncu oranı, haftalık aktif oran |
| **Ortak hedef (co-op boss alternatifi)** | Sunucular 1-3 kişi olduğu için **sunucu içi** boss anlamsız; çapraz sunucu **toplu hedef** (haftalık: "tüm oyuncuların toplam squat'ı") bir lobi tabelasında (üst çubuk DEĞİL); kilometre taşında herkese 1 saatlik küçük boost. Duvarlar kişiye özel kalır (mimari kural). | Doğrudan kanıt yok; Fisch/Sol's RNG sunucu geneli kısa etkinliklerle çalışıyor [VAKA]; co-play sinyali [RESMİ] | Hedefe katkı veren oyuncu oranı; hedef günleri D1'i |
| **Grup / lonca** | Gym League "[CLANS]" ismini taşıyor; Roblox Topluluk (Group) üyeliği ödülü topluluk konsensüsüyle güvenli; D30 için resmi öneri "lonca/parti" | [VAKA]/[ANEKDOT] | Grup üyesi D7 farkı (gözlemsel) |
| **Emote / foto noktası** | Squat/flex emote + lobide foto noktası; Capture ile birleşir; doğrudan kanıt yok (hipotez) | - | Capture tetik sayısı |
| **Roblox Deneyim Etkinliği (RSVP)** | Bölüm 4.4 | [RESMİ] | RSVP sayısı, etkinlik katılım oranı |

Mini not: Ödüllü sosyal tasarımda "meşru arkadaşla oynama" teşvik edilmeli, "ödül için sahte davet" korunmalı: referral ödülünü davetlinin >= 10 dk oynamasına bağla (Creator Rewards eşiğiyle aynı).

---

## 4. Live-ops: etkinlik şablonları, tempo, duyuru UX'i

### 4.1 Tempo (öneri; resmi + vaka karması)
- Resmi: küçük içerik 2-4 hafta, büyük özellik 2-3 ay; içerik temposu "haftalıktan aylığa" ekip kapasitesine göre. Vaka: PS99 her Cumartesi güncelliyor; GAG iki ayrı etkinlik ekibi kurdu. **Solo öğrenci geliştirici için gerçekçi:** 2 haftada bir "gerçek" güncelleme + haftalık "veri tabanlı" mini olaylar (Config tablosundan: yeni haftalık hedef, 1 saatlik boost penceresi, yeni skin rengi). Haftalık kod yazma yükü olmasın.
- Cumartesi (17, 24, 31 Ekim; 7, 14, 21, 28 Kasım; 5 Aralık) yayın günü olarak kullanılabilir. Sebep: BIG Games Cumartesi 17:00 GMT; hafta sonu oynanma zirvede (varsayım).

### 4.2 Sezonluk etkinlik şablonu (Halloween, Winter)
Gözlemlenen ortak kalıp (PS99 Halloween 2025, GAG Ghoul Garden 2025): **(a)** etkinliğe özgü para birimi (Halloween Candy / Candy Corn), **(b)** etkinlik mağazası (3 mağaza), **(c)** limitli petler/kozmetikler, **(d)** bölümlere ayrılmış yayın (GAG: 11, 18, 25 Ekim), **(e)** süre 2-8 hafta, **(f)** etkinlik paketleri (Forever Pack) satın alanlar için kalıcı. [VAKA]
Kaynaklar: https://pet-simulator.fandom.com/wiki/Halloween_Event_2025_(Pet_Simulator_99) , https://growagarden.fandom.com/wiki/Halloween_Event , https://www.biggames.io/post/pet-simulator-99-update-70

**Bizim şablon ("Etkinlik Para Birimi Döngüsü"):**
1. **Para birimi KAZANILIR, satılmaz** (Candy/Snowflake): duvar kırınca/aşama bitirince düşer. Böylece etkinlik yumurtaları/çarkı "kazanılan rastgele ödül" olarak oran gösterimi şartından muaf kalır. Robux'la Candy satmak istersen yalnız **deterministik** mağazada harcatılır.
2. **Mağaza deterministik** 4-5 ürün: iz, aura veya skin varyantı, 1 pet, 1 kapanış ödülü; orta güçlü pet (yumurta 2-3 bandı); statü kozmetikte (renk/halka), güçte değil.
3. **Liderlik panosu** + **ortak hedef**.
4. **Gerçek bitiş tarihi**, sıfırlanan sayaç yok; ürünler gelecek yıl aynı etkinlikte yine alınabilir (bunu duyur); "kaldı: N" yapay stok sayacı yok (Fisch'te eleştirildi) [ANEKDOT, Project Git raporu okunamadı].
5. **Deneyim Etkinliği** olarak yayınla (4.4).
6. **Ekran sade kalsın:** küçük üst bildirim; ortada büyük yazı yok; bloom/parlak ışık yok (sahip kuralları).

### 4.3 Winter şablonu
"Frost Gym" 5 Aralık-3 Ocak (30 gün; Roblox'un önerdiği 7-30 gün aralığının sınırı; Q4 rezervasyon zirvesi ve okul tatiliyle örtüşür). Snowflake para birimi, kış duvar teması (buz renk paleti, mevcut tema sistemi), kış paketi deterministik, **ücretsiz arkadaş hediyesi** ("Protein Shake" gönder: Robux'suz, günde N tane; co-play'i destekler - hipotez), sezon pass kapanışı. Resmi mevsimsellik: Roblox'un SEC dosyasında etkileşim Haziran-Ağustos zirve, Eylül-Kasım düşük; rezervasyonlar (harcama) Q4'te zirve. Yani Ekim-Kasım organik trafik zayıf dönem, harcama kış tatilinde artar. [RESMİ] https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm ("Halloween +%20-30" iddiası [ŞÜPHELİ])

### 4.4 Roblox Deneyim Etkinliği + RSVP + bildirim
- **Experience Events:** aynı anda en çok 10 etkinlik; kapak görseli/başlık/zaman/place seçilir; "Notify Me" ile RSVP bildirimi gelir; `GameJoinContext` ile etkinlikten gelenleri ayırt edersin; oyun içi RSVP istemi `SocialService` ile (aynı istemi döngüde gösterme). Trending için >= 1,000 RSVP (şimdi gerçekçi değil). **Off-Platform Featuring:** etkinlik >= 7 gün önce gönderilmeli, 7-30 gün sürmeli, DAU büyümesi/oynama süresi/retention/monetization performansı seçim faktörü. 24 Ekim başlangıç için son gönderim **17 Ekim**. [RESMİ] https://create.roblox.com/docs/production/promotion/experience-events
- **Güncelleme duyurusu (Experience update):** en çok 60 karakter, 3 günde bir; "bug fixes" gibi belirsiz yazma. [RESMİ] aynı sayfa.
- **Deneyim bildirimleri:** sadece opt-in 13+ kullanıcılar; kullanıcı başına günde 1; en az 100 ziyaret; metin <= 99 karakter; kişisel ve eyleme dönük olmalı ("çarkın hazır" gibi), genel reklam kötü örnek; **sahte zaman baskısı, yem ödül, yanıltıcı yasak**; opt-in istemi metni değiştirilemez, son 30 günde görenlere gösterilmez; oyunu bildirime bağlama. [RESMİ] https://create.roblox.com/docs/production/promotion/experience-notifications. **Sahibin cevabını bekleyen konu (bildirim izni): ONAY.**

### 4.5 "What's New" / güncelleme günlüğü UX'i
- Roblox'un sezon pass dokümanı: "belirgin buton, görünür sayaç, güncelleme uyarısı; alınmamış ödül için rozet ve manuel claim." [RESMİ] https://create.roblox.com/docs/production/game-design/season-pass-design
- Öneri: girişte **bir kez** (sürüm başına) küçük, kapatılabilir "What's New" kartı (3 madde, gerçek bitiş tarihleri), Settings'te yeniden açılır, rozet noktası Quests/Shop düğmesinde; Experience update mesajı (60 karakter) ile aynı metin. Ekran sade kuralı: ortada değil, üst köşede, 6 saniye sonra kendiliğinden küçülen sekme.
- Geri sayım: yalnız gerçek ve tek seferlik (etkinlik bitişi); "Deal of the day" gibi sürekli yenilenen sayaç yok. [RESMİ]
- Limitli ürün ilkeleri (Roblox'un kendi cümlelerine göre): kıtlık gerçekse yaz; çok kısa süreli indirim "adil değil"; sürekli "indirimli" fiyat sahte indirim; "randevu mekanikleri" ve erken biten eğlence Roblox oyuncuları tarafından sevilmiyor. [RESMİ] https://create.roblox.com/docs/production/monetization

---

## 5. Ekonomi sağlığı ve dünya yapısı

### 5.1 Win kaynak/gider sağlığı (idle + prestige)
- Roblox ekonomi olayları: `AnalyticsService:LogEconomyEvent` (sunucu, yayınlanmış oyun; kaynak/gider, para birimi, miktar, bakiye, işlem tipi, `itemSKU` önerilir). Kontrol: **net toplam (kaynak - gider) sıfıra yakın kalmalı; oyuncu cüzdan ortalaması (özellikle ödeyenlerde) büyüyorsa gider ekle; az harcanan para birimine gider ekle.** [RESMİ] https://create.roblox.com/docs/production/analytics/economy-events , özel olaylar https://create.roblox.com/docs/production/analytics/custom-events (100 olay sınırı, alanlarla bölümle)
- Maliyetler üstel, üretim polinom: maliyet = baz x r^sahip; AdVenture Capitalist r = 1.07; çarpanlar üretimi geri çeker; prestige "daha ileri gitme izni"dir; prestige'i ilerleme gerçekten yavaşlayınca yapmak mantıklı (kaba kural: tepe hızın %10-20'sine düşünce; tek kaynak). [VAKA/kuramsal] https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i , https://incrementalatlas.com/mechanics/incremental-games-with-prestige/ ; GDC 2015/2016 Pecorella (video/slayt erişilemedi; özet) https://www.gdcvault.com/play/1022065/Idle-Games-The-Mechanics-and
- "Reset kuralları değiştirdiğinde ilginç": sadece çarpan eklemek zayıf; reset yeni mekanik/para birimi açarsa güçlü. [ANEKDOT/kuramsal]
- **Oyunumuzdaki risk:** çarpan yığını (level x rebirth x aura x koç x pet x iksir x arkadaş x Index) çarpımsal; oyunun sonunda Win'in gideceği yer yalnızca yumurta + kozmetik. Sinkler:
  1. **Mastery ağacı** (kalıcı, Win ile): BGS Infinity'de uzun vadeli ana harcama yolu; PS99'da enchant/mastery gibi gider. Deterministik (rastgele değil) olsun, böylece Win=Robux bağı yüzünden "ücretli rastgele ürün" olmaz. [VAKA] https://bgs-infinity.fandom.com/wiki/Mastery , https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress
  2. Gelire ORANLI sinkler (sabit fiyatlar gelir büyüyünce anlamsızlaşır).
  3. Aynı kategoride yığılmada azalan verim (PS99 enchant kopyalarında %60, %38.3 ikinci/üçüncü kopya: rowatcher iddiası, [ŞÜPHELİ]).
  4. Dünya girişi/yeni bölge bedeli.
- **Zaman kapıları:** Roblox "randevu mekaniği ve erken biten eğlence" sevilmiyor diyor; bekleme süresi yerine **çaba/rebirth/Mastery kapısı** tercih et. "Rebirth Skip 119 R$" bir "beklemeyi atla" ürünü olduğu için süre kapılarını artırma.

### 5.2 8 saati 40+ saate "hızlı" taşıma - önce aritmetik
- Roblox 28 gün bakıyor. Medyan oyuncu günde ~22 dk (GameAnalytics, tüm oyunlar) > 28 günde ~10 saat. Günde 1 saat oynayan (sahibin hedef oyuncusu) 28 günde 28 saat. Yani **D30 için 40 saat şart değil: ~15-20 saatlik toplam içerik (Dünya 1: 8 sa + Dünya 2: 8-12 sa) ortalama oyuncuyu D28'e taşır; 40+ saat ağır oyuncu ve harcayanlar içindir.** [ÖLÇÜM + hesap]
- Oyunun mevcut "en çok 1 saat/gün" playtime sinyal sınırı ile uyumlu: 8 saatlik oyun ~8 oyun günüdür; 8-28. gün penceresi için içerik gerekir.
- **Sıralama uyarısı:** n=16 iken Dünya 2 ilk iş olmamalı; ama "Worlds: coming soon" kemeri sözü verdiği için en geç Aralık başında Dünya 2 alfa/teaser görünür olmalı (Bölüm 8 takvimi).

### 5.3 Dünya yapısı (aynı çerçeve, maksimum veri odaklı)
Rakipler: PS99 dünya başına ayrı jeton (servet "sıfırlanır"), evrensel elmas; BGS Infinity'de dünyalar yükseklikle açılıyor, her dünya daha güçlü yumurta havuzu getiriyor; Muscle Legends rebirth ile spor salonları açıyor (1 rebirth Frost Gym ... 150 rebirth Industrial Gym). [VAKA] https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire , https://roblox.fandom.com/wiki/Muscle_Legends_Studio/Muscle_Legends

| | Dünya 1 (mevcut) | Dünya 2 (öneri, ad geçici: "Iron Island") | Dünya 3 (sonra) |
|---|---|---|---|
| Hedef süre | ~8 sa aktif | +10-14 sa | +14-20 sa |
| Kapı | - | W1 aşama 20 bitir + rebirth >= 20 + Worlds kemerinden gir | W2 aşama 20 + rebirth >= 40 |
| Çekirdek | 20 aşama x 5 duvar, kas/level/rebirth | Aynı döngü; rebirth sayacı DEVAM eder (24-45), level üst sınırı formülü uzar, duvar canı W1 aşama-20 hasarının ~3x'inden başlar | |
| Para birimi | Win | **Seçenek A (hızlı):** Win evrensel, W2 fiyat kademeleri daha yüksek. **Seçenek B (PS99 tarzı):** W2'de dünyaya özel jeton ("Plates") ile yumurta/ekipman, Win ise meta (Mastery, iz, aura, pass). Önerilen: önce A, B sonra. | |
| Yeni veri | 20 tema, 6 yumurta/30 pet, 15 ayakkabı, 15 skin, 10 koç, 6 aura | 20 duvar teması (yeni palet, malzeme), 6 yeni yumurta/30 pet (pets_more.py hattı), 10 ayakkabı, 8 koç, 5 aura | |
| Derinlik ekleri | Pet Index, birleştirme | **Mastery ağacı** (sink), Index %'si, haftalık ortak hedef | Rank/Prestige 2. katman (Ascension) |
| Risk | - | W1 oyuncusunun çarpanı W2'yi "ezmesin": simulate.py ile aşama 1-5'in süresi hedeflenir | |

Kodlama ucuzluğu notu: duvar/tema/ödül/dünya hesabı Config+Layout tablolarından geliyor; hızlı yol "W2 = aşama 21-40" gibi birleşik sıra ve bir dünya anahtarı. En büyük iş sanat (Blender pet/yumurta/koç) ve tools/simulate.py ile denge.

---

## 6. Önceliklendirilmiş backlog (20 madde)

Etiketler: Zorluk S (<= 1 gün) / M (2-5 gün) / L (>= 1 hafta). Politika riski: Düşük / Orta / Yüksek. **ONAY** = sahibin açık onayı lazım (reddedilen listesine yakın ya da sahibin cevabını beklediği fikir). **ROBUX-AŞAMASI** = sahibin "Robux işleri en sona" kuralı kapsamında; kod hazır olabilir ama yayın/ID aşamasında yapılmalı. "Etki" sütunları HİPOTEZDİR.

| # | Ne | Neden (kanıt) | Beklenen etki | Zor. | Politika riski | Onay |
|---|---|---|---|---|---|---|
| 1 | **Ölçüm okuması + olay günlüğü**: Funnel (7 adım) ve Home Recommendations (bounce 60 sn / 61-180 sn, play days) ekranlarını oku; `LogEconomyEvent` (kaynak/gider, itemSKU) ve birkaç custom event (arkadaşla katıldı, Mythic hatch, Capture tetik) ekle | Roblox: D1 = onboarding, huniyi ölç; ekonomide net toplam izle [RESMİ] | Hangi adımda 16 kişi düşüyor sorusu cevaplanır; sonraki her kararın temeli | S | Yok | Hayır |
| 2 | **Friend Referral System** ödül banner'ı: davetçi + davetli ödülü (Win/iksir, Robux DEĞİL), davetli >= 10 dk oynarsa, davetli başına tek seferlik, davetçi limiti 3 | Roblox resmi sistem; co-play 1.9x seans (2024 Q2); RFY co-play günü sinyali [RESMİ] | Organik geliş +, co-play günü +; D1'e dolaylı | S | Düşük | Hayır (mevcut davet düğmesinin uzantısı) |
| 3 | **Nadir hatch duyurusu** (Legendary/Mythic): küçük üst toast, aynı sunucu | PSX Titanic global mesajı [ANEKDOT]; sosyal kanıt | Yumurta açma isteği +; paylaşım | S | Düşük | Hayır |
| 4 | **Capture istemleri** (Mythic hatch, rebirth, yeni vücut aşaması) + Maturity Questionnaire güncellemesi | Moments 16+ yaş kontrollü kitleye açık; klip "Join" ile oyuna götürür [RESMİ] | Organik keşif (belirsiz); düşük maliyet | S-M | Düşük-Orta (anket güncellemesi, API adları doğrulanacak) | Hayır |
| 5 | **Roblox Deneyim Etkinliği** (RSVP + `GameJoinContext`) ve Off-Platform Featuring başvurusu (son gün 17 Ekim, 24 Ekim başlangıç için) | Resmi etkinlik sistemi; 7-30 gün ideal [RESMİ] | Keşif +; ölçülebilir etkinlik kohortu | S | Düşük | Hayır (içerik #6'ya bağlı) |
| 6 | **Halloween Lite** ("Spooky Gym", 24 Ekim-8 Kasım): kazanılan Candy, 4-5 ürünlük deterministik mağaza, pano, ortak hedef | PS99/GAG şablonu [VAKA]; sahibin cevabı bekleyen fikir | Etkinlik kohortunda D1/D7 +? (hipotez 2-5 puan); geri dönüş | M | Düşük (Candy satılmaz ya da deterministik mağazada) | **ONAY** (Halloween etkinliği) |
| 7 | **Kısıtlı hesaplar için "Training Egg" yolu**: sabit sıralı, önceden gösterilen sonuçlar (veya beklenen değerli doğrudan satın alma) | Roblox'un listelediği uyumlu alternatif [RESMİ]; şimdi ana döngü kapalı | Kısıtlı bölgelerde (UK, BR, AU, NL, BE) D1'in sıfıra düşmesini önler | M | Düşük (zaten uyumluluk yolu) | Hayır; çarpılı pet silme kuralını da gözden geçir |
| 8 | **Cumartesi ritmi**: 2 haftada bir gerçek güncelleme; haftalık veri tabanlı mini olay; Experience update mesajı (60 karakter) + oyun içi What's New kartı | Roblox 2-4 hafta; PS99 haftalık; haftalık tempo eleştirisi [RESMİ/VAKA/ANEKDOT] | D7-D30 desteği; görünür canlılık | S (haftalık M) | Düşük | Hayır |
| 9 | **Bildirim izni** (`ExperienceNotificationService`) + 1 kişisel/eyleme dönük bildirim ("Your free spin is ready") | Roblox bildirim analitiği; günde 1 sınır; sahte baskı yasak [RESMİ] | D2-D7 dönüş +? (ölçülmeden söylenmez) | S-M | Düşük (dili sakin tut) | **ONAY** (sahibin cevabını bekleyen konu) |
| 10 | **Mastery ağacı** (Win ile kalıcı deterministik yükseltmeler, 5 dal x 10) | BGS Mastery; PS99 harcama yolları; ekonomi dashboard: cüzdan büyürse gider ekle [VAKA/RESMİ] | Geç oyunda Win enflasyonu kontrolü; +6-10 saat derinlik | M-L | Yok (deterministik) | Önerilir (yeni sistem) |
| 11 | **Hall of Fame + haftalık pano** | Roblox D30: liderlik tabloları; PS99 yarış ödülleri [RESMİ/VAKA] | Rekabet gerekçesi, tekrar gelme | S-M | Yok | Hayır |
| 12 | **Ortak hedef panosu** (çapraz sunucu, haftalık; lobi tabelası) | Co-play sinyali; Fisch/Sol's RNG sunucu geneli olaylar [RESMİ/VAKA]; doğrudan kanıt YOK | Az oyuncuda "yalnız değilim" etkisi (hipotez) | M | Düşük | **ONAY** (Boss Wall fikrine yakın; üst çubuk değil) |
| 13 | **Starter Pack - 49 R$**, 24 sa, ilk yumurta sonrası tek sefer; içerik: özel iz + iksirler (Win'siz indirim) | Roblox Bundles RelativeTime; PM önerisi [RESMİ] | İlk ödeme dönüşümü + (hipotez); ölçülemez bu n'de | S-M | Düşük (dürüst sayaç, tek sefer) | ROBUX-AŞAMASI + **ONAY** |
| 14 | **Roblox Plus kayıt düğmesi** + fiyatların `GetProductInfoAsync` ile gösterimi | Plus: 250 R$/ay x 3, indirim; sabit fiyat yanlış görünür [RESMİ] | Küçük ama sıfır maliyet | S | Düşük (baskısız, ödül vaadi yok) | ROBUX-AŞAMASI |
| 15 | **"Squat Club" aboneliği - 149 R$/ay** | Robux aboneliği herkese açık; +%7 harcama (Roblox beyanı); spend days sinyali [RESMİ] | Tekrarlayan gelir; harcama günü sayısı | M | Düşük (faydalar tutarlı verilmeli) | ROBUX-AŞAMASI + **ONAY** |
| 16 | **Halloween Pack - 99 R$** (deterministik: aura + iz + belirli pet + 2 iksir) | Roblox "belirli sonucu doğrudan sat" uyumlu; GAG/PS99 etkinlik paketleri [RESMİ/VAKA] | Etkinlik geliri | S | Düşük (rastgele öğe yok) | ROBUX-AŞAMASI + #6'ya bağlı |
| 17 | **Gym Season 1** (4 hafta, 10 kademe, ücretsiz + premium 149 R$ ya da abonelik) | Roblox sezon pass rehberi: 1 ay, 10 kademe, geç satın alana geçmiş ödül, el ile claim [RESMİ] | D7-D28 oynama günü +; ek gelir | L | Orta (FOMO; mevcut Quests ile örtüşme) | **ONAY** (görev yapısına yakın) + ROBUX-AŞAMASI |
| 18 | **Winter "Frost Gym"** 5 Aralık-3 Ocak | Q4 rezervasyon zirvesi; 30 günlük etkinlik [RESMİ/VAKA] | Tatil dönemi geri dönüşü | M-L | Düşük | **ONAY** |
| 19 | **Dünya 2 (alfa)**: Worlds kemerinden giriş, W2 aşama 1-5 + 6 yumurta | Dünya 8-28 gün penceresini doldurur; PS99/BGS dünya modeli [VAKA] | D14-D28 oynama günleri | L | Düşük | Önerilir (kemer "coming soon" sözü) |
| 20 | **Özel sunucu + Squad bonusu doğrulaması** (arkadaş bonusu özel sunucuda da çalışsın) | Özel sunucu katılımı = co-play sinyali; Plus özel sunucu primi [RESMİ] | Küçük | S | Düşük | ROBUX-AŞAMASI |

**Bilerek önerilmeyenler / ertelenenler:** ticaret (moderasyon, hile, `IsPaidItemTradingAllowed`), Robux'la çark/sandık satışı (ücretli rastgele ürün), "limited stock" sayaçları, beğeni/favori/takip ödülü, günlük giriş serisi (reddedildi), promosyon kodları (reddedildi), reklam alımı (RFY'den hariç, düşük bütçe), ödüllü video (>= 2,000 aylık ziyaretçi şartı), Audience Expansion (>= 100 DAU).

### Yeniden sıralanmış "ilk 12" (etki/efor, sahibin kuralları dikkate alınarak)
1 (ölçüm) > 2 (referral) > 7 (kısıtlı hesap yolu) > 5 (etkinlik kaydı) > 3 (nadir hatch) > 4 (capture) > 8 (ritim) > 6 (Halloween Lite, ONAY) > 11 (Hall of Fame) > 10 (Mastery) > 9 (bildirim, ONAY) > 19 (Dünya 2 alfa). Robux kalemleri (13-16, 20) sahibin kuralı gereği son faza; kodu hazır tutmak mümkün.

---

## 7. Yeni ürünler ve fiyatlar (150 R$ kuralı korunarak)

| Ürün | Öneri fiyat | Net (%70) | Gerekçe / not |
|---|---|---|---|
| Starter Pack (24 sa, tek sefer) | **49 R$** | 34 | Giriş bandı; Roblox bundle'ında 49/99/149 örnek fiyatları; içerik: özel iz + 2 Rainbow iksiri 15 dk; Win içermesin (WinValue tutarlılığı) |
| Event Booster (2x Candy, 60 dk) | **39 R$** | 27 | İksir ailesi 39-149 ile uyumlu; Candy sadece kazanılan |
| Halloween Pack (deterministik) | **99 R$** | 69 | Çekirdek bant; aura + iz + belirli pet + 2 iksir; gelecek yıl yeniden satışta |
| Winter Pack | **99 R$** | 69 | Aynı kalıp |
| Gym Season premium kademe | **149 R$** | 104 | Roblox: fiyat ödülün değerini yansıtmalı; geç alana geçmiş kademe ödülü |
| Squat Club (aylık) | **149 R$/ay** (taban 49) | 104/ay | Faydalar: aylık iksir + belirli Win + Club kozmetiği + biraz hızlı Playtime turu; 60 günde bir fiyat değişir |
| Özel sunucu | **99 R$** (taban 10) | 69 | Arkadaş bonusu doğrulanana kadar düşük öncelik |
| Roblox Plus düğmesi | - | 250 R$/ay x 3 / yeni abone | Baskısız, tek düğme |

Fiyat testi: Roblox Experiments (14-60 gün, 2 varyant + kontrol) var ama bu ölçekte anlamlı sonuç vermez; fiyat optimizasyonu aracı 60,000 işlem ister; bu yüzden **önce sıralı (önce/sonra) ölçüm + niteliksel geri bildirim**, A/B'yi >= 300 yeni oyuncu/kohort olunca. https://create.roblox.com/docs/production/experiments (çeviri kopyalarından okundu)

Not: 9 ile biten / yuvarlak fiyat tartışması kanıtsız; mevcut katalogla tutarlı 9'lu fiyatlar (39, 49, 99, 149) korunsun, çünkü ürünler arası karşılaştırma önemli.

---

## 8. 8 haftalık etkinlik takvimi (14 Ekim - 8 Aralık 2026)

Not: Halloween 31 Ekim = Cumartesi. Resmi kaynaklara göre sonbahar organik trafik zayıf; harcama Q4 sonunda artar. Roblox'un kendi platform Halloween etkinliğinin ("The Hollow", ~22 Ekim) doğrulanamadı.

| Hafta | Tarih | Yayın / olay | Ölçüt |
|---|---|---|---|
| 0 | Çar 14-Cum 16 Ekim | Funnel + bounce + Home Recommendations okuması (#1); `LogEconomyEvent` şemasını planla; Halloween etkinliğini ÖZEL (private) Deneyim Etkinliği olarak aç; bildirim metin taslakları (onay sonrası) | Hangi adımda kaç kişi düşüyor |
| 1 | **Cmt 17 Ekim** | Küçük güncelleme: Friend Referral banner (#2), nadir hatch toast (#3), Capture istemleri (#4), kısıtlı hesap yolu başlangıcı (#7). **Off-Platform Featuring başvurusu son gün** (24 Ekim başlangıç için). Experience update mesajı (60 karakter) | Referral katılımı; ilk 3 dk bounce |
| 2 | **Cmt 24 Ekim** | **Halloween Lite Bölüm 1** (ONAY şartıyla): Candy, mağaza (iz + skin), Hall of Fame panosu, Starter Pack (ROBUX-AŞAMASI ise sonraya) | Etkinlik katılım oranı; etkinlik kohortunun D1'i |
| 3 | **Cmt 31 Ekim** (Halloween) | Bölüm 2: yeni pet + aura, ortak hedef panosu, bir kerelik "Spooky Power Hour" (isteğe bağlı boost; punishing değil) | Ortak hedef katkı oranı |
| 4 | Cmt 7 Kasım | Etkinlik sonucu/Hall of Fame anı (etkinlik 8 Kasım biter); hata düzeltme; Dünya 2 teaser (Worlds kemeri "construction" değişimi) | Etkinlik kohortunun D7'si |
| 5 | Cmt 14 Kasım | Mastery ağacı v1 (#10) | Win sink'i ve cüzdan eğrisi |
| 6 | Cmt 21 Kasım | Haftalık pano/QoL; Kış etkinliğinin ÖZEL kaydı; Off-Platform başvurusu (5 Aralık için son gün **28 Kasım**) | |
| 7 | Cmt 28 Kasım | Dünya 2 alfa duyurusu (rebirth >= 20 olanlar) + Kış hazırlığı; (Black Friday: sadece gerçek, 48 saatlik, tek sefer bonus - sahte kıtlık yok) | |
| 8 | **Cmt 5 Aralık** | **Winter "Frost Gym"** başlangıcı (5 Aralık-3 Ocak) + Season 1 (onay şartıyla) | Kış kohortu D1/D7; harcama günleri |

Tempo kuralı: 2 haftada bir kod yayını; arada sadece Config verisi. Saat: Cumartesi 17:00 GMT (PS99 örneği, hafta sonu trafiği varsayımı).

---

## 9. Ölçüm planı (küçük n için)

- **Metrikler (RFY ile hizalı):** D1/D7/D30 (kohort), first-play bounce (60 sn/61-180 sn), play days (Gün 2-7 içinde 6 günden kaçı), seans süresi, co-play günleri (custom event: oturumda >= 1 arkadaş), spend days, payer conversion (30D), ARPPU, Win kaynak/gider net.
- **Güven aralığı kuralı:** p = 0.15, n = 100 ise +-7 puan; n = 300 ise +-4; n = 1000 ise +-2.2. n < 100'de yön değişiklikleri için karar verme; **izleme kaydı (replay) ve oyuncu görüşmesi** daha değerli.
- **Etkinlik ölçümü:** `GameJoinContext` ile etkinlik katılımcıları ayrılır; her etkinlik için TEK hedef metrik (retention ya da süre ya da gelir) önceden yaz. [VAKA/öneri]
- **Duyuru/bildirim analitiği:** Creator Hub bildirim paneli >= 100 gösterim ister.
- **Politika denetimi:** her yeni rastgele ürün için kontrol listesi (yüzde gösterimi, %100, PolicyService, alternatif yol, Questionnaire).

---

## 10. Sahibin onayına bırakılan/işaretlenen konular
- **Cevabını bekleyenler:** Halloween etkinliği (#6, #16), bildirim izni (#9), Boss Wall benzeri ortak hedef (#12), sezon/rozet benzeri kalıplar (#17), Winter (#18). Rozet/ünvan fikirleri bu belgede önerilmedi.
- **Reddedilenler (önerilmedi):** günlük giriş ödülü, promosyon kodları, lobi görev panosu, bloom/göz alıcı ışık, üst ilerleme çubuğu.
- **Robux aşaması (en sona):** #13, #14, #15, #16, #20 ve ürün listesi. "Robux fiyatı 150'yi geçmez" kuralı bunların hepsinde korundu.
- **Etiket sorusu:** Belgeler ücretli rastgele ürünlerin tek başına minimum yaş etiketi belirlemediğini söylüyor (forum yorumu "lootbox'lar min. 16" diyor, doğrulanmadı). 16+ etiketinin nedeni yalnız yumurtalarsa, keşif havuzunu büyütmek için etiketi yeniden değerlendirmek mümkün ama çocuk güvenliği ve Questionnaire sonuçlarını etkiler; sahibin kararı. [RESMİ + ANEKDOT]

---

## 11. Belirsizlikler / bilmediğimiz şeyler
- Simulator'a özgü güvenilir D1/D7/D30 yok; GameAnalytics yalnızca büyük oyunlar için.
- Fiyat noktaları için resmi/ölçülü veri yok; tüm "25/49/99/199/399 en iyi" iddiaları pazarlama/blog.
- RFY sinyal ağırlıkları yalnızca Roblox'un görsel grafiğinde; sayılar açıklanmadı.
- Abonelik dönüşüm oranı için ölçüm yok; yalnız Roblox'un "+%7 harcama" beyanı.
- Capture/Upload/Recommendation API'lerinin tam durumu (CaptureService adları) doğrulanmadı.
- 12 Ekim 2026'da Home/Search/Charts gösterim sayımının değiştiği iddiası tek ikincil kaynaktan; doğrulanmadı (tarihsel kıyasları etkileyebilir).
- PS99/Sol's RNG/Fisch'in iç retention verisi yok; hepsi dış gözlem, hayran wiki'si, haber.
- Project Git (Avustralya) "yanıltıcı Roblox monetizasyonu" raporu PDF olarak okunamadı (sıkıştırılmış akış); Fisch geri sayım eleştirisi diğer kaynaktan.
- DevEx/Audience Expansion'da sahibin hesabının uygunluğu (Kıbrıs, ID, DevEx) bilinmiyor.

---

## 12. Kaynak listesi (URL)

**Roblox resmi**
- Retention: https://create.roblox.com/docs/production/analytics/retention
- Onboarding: https://create.roblox.com/docs/production/game-design/onboarding
- LiveOps essentials: https://create.roblox.com/docs/production/game-design/liveops-essentials
- Discovery: https://create.roblox.com/docs/discovery ; FAQ: https://create.roblox.com/docs/discovery-faq
- Optimizing Discovery (Haziran 2026): https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- RFY DevForum: https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- RDC 2026: https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play
- Creator Rewards: https://create.roblox.com/docs/creator-rewards ; eski EBP: https://create.roblox.com/docs/production/monetization/engagement-based-payouts
- Ücretli rastgele ürün: https://create.roblox.com/docs/production/monetization/paid-random-items ; duyuru: https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622
- İçerik olgunluğu: https://create.roblox.com/docs/production/promotion/content-maturity
- Monetization (adil kullanım): https://create.roblox.com/docs/production/monetization
- Monetization foundations: https://create.roblox.com/docs/production/game-design/monetization-foundations
- Bundles: https://create.roblox.com/docs/resources/feature-packages/bundles
- Abonelikler: https://create.roblox.com/docs/production/monetization/subscriptions ; Robux abonelikleri: https://devforum.roblox.com/t/let-your-players-pay-for-subscriptions-within-experiences-in-robux/4552995 ; +%7: https://devforum.roblox.com/t/increased-payouts-for-subscriptions-within-experiences/2963619 ; tasarım: https://create.roblox.com/docs/production/game-design/subscription-design
- Sezon pass tasarımı: https://create.roblox.com/docs/production/game-design/season-pass-design
- Roblox Plus: https://create.roblox.com/docs/production/monetization/roblox-plus ; haber: https://www.tubefilter.com/2026/04/13/roblox-plus-creator-payouts/ ; Roblox: https://about.roblox.com/newsroom/2026/04/introducing-roblox-plus-subscription
- ABD 18+ DevEx oranı: https://create.roblox.com/docs/production/monetization/18-plus-devex-rate
- Bölgesel fiyat: https://devforum.roblox.com/t/introducing-regional-pricing-for-passes/3621382
- Özel sunucu: https://devforum.roblox.com/t/upcoming-updates-to-private-servers-new-tools-and-new-earning-opportunities/4590482
- Friend referral: https://create.roblox.com/docs/production/promotion/referral-system ; duyuru: https://devforum.roblox.com/t/announcing-the-new-friend-referral-system-for-your-experiences/3623795 ; davet istemleri: https://create.roblox.com/docs/production/promotion/invite-prompts
- Deneyim etkinlikleri: https://create.roblox.com/docs/production/promotion/experience-events ; bildirimler: https://create.roblox.com/docs/production/promotion/experience-notifications
- Moments: https://devforum.roblox.com/t/roblox-moments-a-new-era-of-user-generated-discovery-for-experiences-and-gameplay-is-here/3919813 ; https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all
- Ekonomi olayları: https://create.roblox.com/docs/production/analytics/economy-events ; özel olaylar: https://create.roblox.com/docs/production/analytics/custom-events ; Deneyler: https://create.roblox.com/docs/production/experiments
- Ads Manager: https://create.roblox.com/docs/production/promotion/ads-manager ; ödüllü video: https://devforum.roblox.com/t/rewarded-video-ads-are-now-available-to-all-ads-eligible-creators/4063278
- Jumpstart (yeni geliştirici programı): https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs
- SEC 10-K FY2025 (mevsimsellik): https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm

**Ölçüm / analiz**
- GameAnalytics 2026 Roblox raporu: https://www.gameanalytics.com/reports/2026-roblox-report ; özet: https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox

**Vaka / sektör**
- Naavik (Blox Fruits, Brookhaven, Adopt Me): https://naavik.co/deep-dives/roblox-blox-fruits-brookhaven-adopt-me/
- Big Games iç yüzü (rowatcher, kaynaksız): https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire ; PS99 ekonomisi: https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress
- PS99 Halloween 2025 (wiki): https://pet-simulator.fandom.com/wiki/Halloween_Event_2025_(Pet_Simulator_99) ; Big Games: https://www.biggames.io/post/pet-simulator-99-update-70 ; PSX Titanic: https://pet-simulator.fandom.com/wiki/Titanic_Pets_(Pet_Simulator_X)
- Grow a Garden: https://en.wikipedia.org/wiki/Grow_a_Garden ; Halloween: https://growagarden.fandom.com/wiki/Halloween_Event ; GEEIQ: https://geeiq.com/resources/blog/grow-a-garden
- Fisch etkinlikleri: https://fischipedia.org/wiki/Events ; takvim: https://allthings.how/fisch-events-schedule/
- Sol's RNG: https://sol-rng.fandom.com/wiki/Developer_Events_and_Special_Auras
- BGS Infinity Mastery: https://bgs-infinity.fandom.com/wiki/Mastery
- Muscle Legends: https://roblox.fandom.com/wiki/Muscle_Legends_Studio/Muscle_Legends ; Rolimons: https://www.rolimons.com/game/3623096087 ; Gym League: https://www.rolimons.com/game/17450551531
- Dubit: https://dubit.io/library/what-makes-a-new-roblox-game-take-off
- Zehn Studio (RFY özeti): https://zehn-studio26.com/news/recommended-for-you-retention-update/

**Fiyat / tasarım yorumları ([ŞÜPHELİ] - dikkatli oku)**
- https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide , https://www.creation.dev/learn/how-to-price-game-passes-roblox , https://rolearn.dev/guidance/roblox-gamepass-pricing-strategy-guide/ , https://rolearn.dev/guidance/first-week-retention-optimization/ , https://www.indg.vc/blog/how-to-build-a-roblox-live-ops-calendar-that-works , https://bloxg.com/statistics/roblox-retention-benchmarks , https://rolearn.dev/trend-reports/roblox-monetization-trends-devex-creator-rewards/
- Starter pack fiyat anketi (Deconstructor of Fun): https://www.deconstructoroffun.com/blog/2024/4/8/free-to-play-starter-pack-pricing-when-conversion-is-king-we-may-price-too-low

**Idle / ekonomi kuramı**
- https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i , https://www.gdcvault.com/play/1022065/Idle-Games-The-Mechanics-and , https://incrementalatlas.com/mechanics/incremental-games-with-prestige/ , https://dev.to/aguier/i-built-7-idle-games-in-30-days-what-i-learned-about-incremental-design-5d3f

**Düzenleyici / bağlam**
- FTC şikayeti: https://thenextweb.com/news/roblox-ftc-complaint-fairplay-ncse-child-safety
- Beğeni/favori ödülü: https://devforum.roblox.com/t/rewards-through-likingfavoritinginvites/233704 , https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286
- Hediyeleştirme: https://devforum.roblox.com/t/gamepass-gifting-api-for-marketplaceservice/4525236 ; Transfers API: https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396
- Reklamın RFY'ye etkisi (anekdot): https://devforum.roblox.com/t/sponsored-ads-traffic-degrades-the-engagement-metrics-used-for-discovery-causing-paid-acquisition-to-harm-organic-ranking/4838351
