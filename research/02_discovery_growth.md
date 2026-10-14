# 02 - Keşif (Discovery) ve Büyüme Araştırması: "+1 Squat Evolution: Smash Walls"

Tarih: 2026-10-14. Hazırlayan: büyüme araştırmacısı (salt okunur araştırma; oyun koduna dokunulmadı).
Kapsam: Roblox'un yeni ve küçük bir oyunu bugün nasıl keşfettirdiği, 16+ kapısı, Ads Manager, ücretsiz kanallar, sayfa optimizasyonu ve 14 günlük plan.

Güven etiketleri (her önemli bilginin yanında):
- **[R]** Roblox resmi sayfası (create.roblox.com, devforum "Announcements", about.roblox.com).
- **[F]** DevForum kullanıcı mesajı / topluluk raporu (gerçek deneyim ama resmi değil, çoğu zaman çelişkili).
- **[3]** Üçüncü taraf / satış yapan ajans (BLOXG, Rolearn vb.): yön gösterir, kesin sayı sayılmaz.
- **[?]** Doğrulanamadı / kaynaklar çelişiyor.

İşaretler: 💰 = para harcar. ⚠ ONAY = sahibinin açık onayı gerekir (para, hesap, yayın, dış mesaj, kod değişikliği).

---

## 0. Tek paragraf özet (en önemli 8 bulgu)

1. **Roblox'un kendi tarifine göre öneri sistemi (Recommended For You, RFY) küçük oyunu cezalandırmıyor**: sinyaller kişi başına ORTALAMA'dır (toplam değil), yeni oyunun "çok düşük minimum oyun sayısıyla" aday havuzuna girmesi yeter, zayıf başlangıç için ceza yoktur, algoritma yeni kitleleri sürekli dener. Ama sinyaller SADECE Home'daki RFY'den ORGANİK gelen oyunculardan ölçülür; reklam, arkadaş, arama, paylaşım linki trafiği sıralamaya sayılmaz. [R] https://create.roblox.com/docs/discovery , https://create.roblox.com/docs/discovery-faq
2. **16+ kapısı yapısal bir tavan**: yeni oyun önce yalnızca yaş-kontrollü 16+ kullanıcıya açılır; daha geniş kitle için "60 günde 250 benzersiz oyun, 'highly engaged' (HEP) oyunculardan" gerekir. HEP = hesap yaşı + oyunda geçirilen süre + SON 60 GÜNDE Roblox'ta herhangi bir yerde asgari harcama yapmış olmak. Yani harcama yapmamış arkadaşlar/sınıf arkadaşları sayaca girmez. [R] https://create.roblox.com/docs/production/publishing/kids-and-select
3. **Eşik düşüyor**: 500 -> 250 (19 Ağustos 2026, devforum resmi duyuru). Kasım'da 100'e inecek denmiş ama bu SADECE sosyal medya/haber kaynaklarında (RTC/Bloxy News/üçüncü taraf), resmi dokümanda hâlâ 250 yazıyor [?]. Sayaç 60 günlük KAYAN pencere, yani şimdi kazanılan HEP'ler Kasım'daki daha düşük eşiğe de sayılır.
4. **Reklamla HEP kazanmak güvenilmez**: forumda "5.400 ziyaret -> 0 sayılan", "6.000 ziyaret -> 5", "10.000 -> 15" gibi raporlar var; Engagement hedefi (beta) bu iş için yapıldı ama raporlar karışık ("250+ oyun geldi, sayaç 165") [F]. Roblox'un kendi dokümanı: daha pahalı CPP, 3-5 günde anlamlı sonuç, hedefe ulaşınca elle durdur. [R]
5. **Önce kapıların gerçekten açık olduğunu doğrula** (bedava, 15 dk): tam Maturity & Compliance anketi (sadece 1. soru değil), ID doğrulama, 2FA, Plus/Premium (2 ay) ya da 1.000 Robux ücret, "Beta mode" KAPALI, "Exclude from recommendations" KAPALI, gizlilik Public. "Content May Vary" etiketi + sadece 1. soru = Kids/Select değerlendirmesine HİÇ girmez. [R]
6. **Retention her şeyin önünde**: RFY'nin en önemli 4 sinyali: play-through rate (PTR), first-play bounce rate (ilk oturumda 60 sn ve 61-180 sn altında çıkış), play days (D1 / D2-7 / D8-28), playtime (kişi/gün 60 dk ile sınırlı). Hepsi onboarding ve ilk 3 dakikayla ilgili. [R]
7. **Ücretsiz en yüksek getirili 3 iş**: (a) sayfaya gerçek oynanış VİDEOSU (RFY'de otomatik oynatma testlerinde oynama süresinde +%39'a kadar; Roblox testi), (b) 3-5 FARKLI küçük resim ile "Thumbnail Personalization" (ortalama +%8,5 ila +%12 qPTR; Roblox verisi), (c) tek bir Share Link ile her dış kanalı ayrı ölçmek. [R]
8. **Yapmayın**: görüntüleme/ziyaret botu, beğeni/favori karşılığı ödül (gri-yüksek risk), yanıltıcı küçük resim/video, oyun içinde Discord/URL yazmak, "ücretsiz Robux" başlıkları, anahtar kelime doldurma, promosyon-kodu (sahibi zaten reddetmiş, CLAUDE.md).

---

## 1. Roblox keşif sistemi: gerçekten ne çalışıyor? (2026 durumu)

### 1.1 Resmi sinyal listesi (RFY = Home'daki "Recommended For You")  [R]
Kaynak: https://create.roblox.com/docs/discovery ve https://create.roblox.com/docs/discovery-faq ; 15 Haziran 2026 duyurusu: https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575

İki aşama: **Retrieval** (kullanıcıya uygun aday alt kümesi; ilgi, retention, monetizasyon) ve **Ranking** (kişiye özel sıralama; kullanıcının Home'unda yaklaşık 100 oyuna iner).

**En önemli sinyaller (sırayla):**
| Sinyal | Anlamı | Bizim için not |
|---|---|---|
| Play-through rate (PTR) | RFY'de oyunu görenlerin ne kadarı oynuyor | Küçük resim, ikon, başlık, açıklama |
| First-play bounce rate (NEGATİF) | İlk oturumda <60 sn ve 61-180 sn çıkış oranı | Yükleme ekranı, ilk 30 sn, hesap/cihaz çökmesi |
| Play days per user | Kişi başı oynanan benzersiz gün: D1, D2-7, D8-28 ayrı | Dönüş sebebi (rebirth, çark, görev) |
| Playtime per user | Kişi başı süre; **kişi/oyun/gün 60 dk ile sınırlı** | 60 dk üstü ek fayda yok |

**Önemli (ikinci kademe):** intentional co-play days (arkadaşla katılma, davet, özel sunucu), qualified play sessions, spend days, Robux spent per user.

Diğer resmi gerçekler:
- Pencereler 7 günden **28 güne** çıktı (15 Haziran 2026): D1 / D2-7 / D8-28. Eski "qualified PTR" kaldırıldı, yerine PTR + first-play bounce geldi. [R]
- Sinyaller kişi başı **ortalama** (toplam değil): "küçük ama bağlı oyunlar dezavantajlı olmasın". [R]
- Sadece RFY'den organik gelenler sayılır; reklam, arama, arkadaş, teleport, bildirim, paylaşım linki trafiği sıralama sinyaline katılmaz. [R]
- Soğuk başlangıç (cold start): yeni oyun 28 gün beklemez, ilk sinyaller hemen kullanılır; retrieval için "çok düşük asgari oyun sayısı" yeter; algoritma yeni kitleleri sürekli dener (explore), iyi tepki veren benzer kitlelere genişler (expand); erken zayıf sonuç için "ceza yok", onboarding düzeltilince tekrar denenir. [R] (FAQ)
- "Dalgalanma normaldir": impression artınca PTR geçici düşer. RFY'de görmüş oyuncu sonra "Continue" sırasına geçer, bu da yeni RFY adayı sayısını azaltır (reklam/kampanya sonrası düşüş normal). [R]
- Home'a etki eden 4 faktör: kendi güncellemelerin, Roblox/algoritma değişiklikleri, toplam trafik ve mevsim (cumartesi tepe, hafta içi düşük; yaz/okul/tatil), rekabet. [R]
- Mart 2026: RFY'ye "deep play-through rate" ve "7 gün qualified play sessions" sinyalleri eklendi; "Not interested" geri bildirimi entegre ediliyor; formül kişiye göre dinamik, tek global formül yok. [R] https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571
- RDC26 (Eylül 2026): "keşif yaş-duyarlı oluyor", ilk 28 gün performansına bakıyor. [R] https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play

**Resmi listede OLMAYANLAR** (kanıt yok, dürüst olun):
- CCU, beğeni oranı, favori sayısı: resmi RFY sinyal listesinde yok. FAQ "likes, favorites, CCU" konusunda sessiz. Arama sıralaması için resmi ağırlık yok; ikinci el alıntı "kullanıcı hesabı/aktivitesi, sorgu ve içerik alaka, kalite, performans, popülerlik" [?]. Üçüncü taraf "CCU %30-35" gibi ağırlıklar uyduruk tahmindir [3], kullanmayın.
- Hâlâ iyi bir beğeni oranı, sayfada görünen sosyal kanıt olarak PTR'yi dolaylı etkileyebilir (varsayım, [?]).

### 1.2 Sorts: Up-and-Coming / Top Trending / Popular (Discover -> "Charts")
- Charts sayfası (eski Discover) KİŞİSELLEŞTİRİLMEMİŞTİR: herkese aynı, istatistiğe dayalı; kalite adımında güvenlik filtreleri ve **DAU eşikleri** var. [R, 2024] https://devforum.roblox.com/t/testing-an-enhanced-discover-page-top-charts-and-new-sorts/2954676
- Up-and-Coming = hızlı büyüyen yeni çıkışlar, Top Trending = son haftada oyuncu sayısı en çok artanlar (üçüncü taraf tanımı [3]); Roblox'un 2026 resmi formülü yayınlanmadı [?].
- **Sonuç:** 16 oyunculu bir oyun için Charts 14 günlük hedef DEĞİL; DAU eşiğini geçmeden görünmez. Kısa vadede tek gerçekçi yüzey: RFY (16+ havuzu), Search, Friends, Moments.
- Yeni Home sortları (Standout Games, Live Events, Sponsored). "Standout Games" kürasyon: "yenilikçi" oyunlar; "popüler bir oyunun kopyası/reskin'i zor satış" der. Başvuru ücretsiz anket. [R] https://create.roblox.com/docs/creator-programs/standout-games (bizim oyun klasik simülatör kalıbında; olasılık düşük ama maliyet 30 dk).

### 1.3 Roblox Moments (YENİ, tam 16+ havuzumuzla örtüşüyor)
- Yeni uygulama ana ekranında "Moments" sekmesi: oyuncu klipleri (30 sn'ye kadar), her klipte "Join" düğmesi. Temmuz 2026 Roblox yazısına göre yaş-kontrollü 16+ kullanıcılara açık, 28 Temmuz 2026'dan itibaren kademeli yayılım (Kanada, Yeni Zelanda, Singapur, ardından küresel; ABD'de tam). [R] https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all
- Yaratıcılar için **Video Captures API**: oyun içinde özel anlarda (rebirth, dev boyuta ulaşma) oyuncuya klip kaydettirme istemi gösterebilirsiniz; ilerleyen dönem "Upload API" ve "Recommendation API" vaat edildi. [R] https://devforum.roblox.com/t/roblox-moments-a-new-era-of-user-generated-discovery-for-experiences-and-gameplay-is-here/3919813
- Not: paylaşım/akış özellikleri anket sorularını etkiler (3 yeni soru); kod değişikliği gerektirir => ⚠ ONAY ve anketi güncelle. Oyunumuzun görsel vurucu anı (karakter büyüyor, duvar patlıyor) klip için çok uygun; 16+ havuzu içinde ücretsiz bir keşif yüzeyi olabilir. Etki büyüklüğü bilinmiyor [?].

### 1.4 Platformda hedef kitle büyüklüğü
- Roblox'a göre Ocak 2026 sonunda günlük aktif kullanıcıların (144 M) ~%45'i yaş kontrolünden geçmiş; yaş kontrollülerin %35'i <13, %38'i 13-17, %27'si 18+. 16+ payı bu verilerden türetilemez. [R] https://about.roblox.com/newsroom/2026/02/moving-beyond-self-reported-age
- Sonraki dönem için "%51/%57 yaş-kontrollü" gibi sayılar yalnızca ikincil kaynakta [?].
- Çıkarım: 16+ yaş-kontrollü ve ayrıca harcama yapmış HEP havuzu, platformun küçük bir dilimi. Bu yüzden bu aşamada büyük sayılar beklemeyin; **kalite (D1/ilk oturum) ve doğru kitle** asıl iştir.

---

## 2. Yeni oyun olgunluk/yaş kapısı: neden 16+ ve nasıl açılır

### 2.1 Kural özeti (resmi)  [R]
Kaynaklar: https://create.roblox.com/docs/production/publishing/kids-and-select , https://create.roblox.com/docs/production/promotion/content-maturity , https://create.roblox.com/docs/production/publishing/publish-experiences-and-places

- Neden: Roblox, 16 yaş altı hesaplar için ayrı "Kids (5-8)" ve "Select (9-15)" hesap türleri kurdu (19 Mayıs 2026 NZ/NL/AU/ID, 16 Haziran 2026 küresel). 16 yaş altına açılan her oyun bir **değerlendirme (evaluation)** sürecinden geçmek zorunda. Değerlendirilmemiş oyun sadece **yaş-kontrollü 16+** (ve "trusted friends") için açıktır.
- 16+ yolu (bedava, değerlendirme yok): hesap iyi durumda ve >= 2 günlük, yaş doğrulama (yüz tahmini ya da kimlik), olgunluk anketinin ilk sorusu. İlk soru "yaş-kısıtlı içerik var mı?"; "Hayır" => **Content May Vary** (sadece 16+). Tüm anketi doldurmak daha kesin bir etiket verir.
- Etiketlere göre varsayılan erişim: Minimal/Mild => Kids + Select; Moderate => Select + 16+; Content May Vary => yalnız 16+ (9-15 yaşta ebeveyn "izinli oyunlar"dan tek tek açabilir); Restricted => 18+. "Minimal" bir yaratıcı ayarı değil, anket çıktısıdır (ebeveyn kaydırıcısında da aynı adlı kademe var).
- 16 yaş altı yolu (hepsi gerekli):
  1. Hesap iyi durumda;
  2. Yaş doğrulama: <18 yüz tahmini, 18+ resmi kimlik;
  3. 2 adımlı doğrulama (2FA);
  4. TAM anket ve Minimal/Mild/Moderate (9+) etiketi;
  5. Ücret ya da abonelik: ardışık 2 ay Roblox Plus/Premium VEYA oyun başına tek seferlik iade edilebilir **1.000 Robux** yayın ücreti (Creator Hub > Audience > Reach > "Pay");
  6. **Değerlendirme**: 16+ deneme aşaması, etkileşim analizi (bot ayıklama), güvenlik incelemesi, ve eşik: **son 60 günde yaş-kontrollü HEP'lerden 250 benzersiz oyun**. Metrik saatlik değerlendiriliyor; ilerleme "Audience Reach" panosunda.
- Ücret/abonelik tek başına kapıyı açmaz: "ödemek anında erişim vermez". [R]

### 2.2 "Highly engaged player" (HEP) tam olarak ne?  [R]+[F]
- Resmi tanım: hesap kıdemi + oyunda geçen süre + platform harcaması gereksinimlerini karşılayan kullanıcı. **Platform harcaması**: son 60 günde Roblox'ta herhangi bir yerde asgari tutarda satın alma yapmış ve bu pencerede oyunda zaman geçirmiş olmak; oyunda harcama gerekmez, ücretsiz oyunlar da sayılır. Kriterler zamanla değişir. Asgari tutar/süre/kıdem sayıları YAYINLANMADI. [R]
- "Realtime Multimodal Moderation" sistemi hesap yaşı, oyun geçmişi, harcama gibi sinyallerle etkileşimin gerçek olduğunu doğruluyor. [R]
- DevForum'da bir geliştirici, personelden "harcama yapmış oyuncular sayılır, sadece Robux harcayanlar değil" doğrulamasını aktardı (28 Mayıs 2026) [F]: https://devforum.roblox.com/t/highly-engaged-players-not-counting-up/4644386
- Karıştırmayın: Creator Rewards'taki "Active Spender" (60 günde >= 9,99 USD) başka bir program tanımı; HEP eşiği açıkça yayınlanmadı. [R: https://create.roblox.com/docs/creator-rewards] HEP için 9,99 USD varsaymak doğrulanamaz [?].
- Sayaç davranışı (forum raporları): bazen günlerce 0'da kalır; 24 saat içinde güncellenir, Temmuz'da "grafik günlük güncelleniyor" denmiş; bazıları "RFY'den gelenler sayılır, reklam/dış link sayılmaz" varsayıyor (RESMİ DEĞİL) [F]. 500'e ulaşıp "Reach more players" yazısı günlerce kalan oldu; destek "site hatası, bekleyin" dedi. [F] https://devforum.roblox.com/t/my-reach-is-still-stuck-at-16-despite-reaching-500-highly-engaged-players/4727508
- Gözlenen oran: bir obby geliştirici 10-20 bin ziyarette 500 HEP'e ulaştı (%2,5-5), ama büyük kısmı reklam bittikten sonra Home önerileriyle geldi; "büyük ölçüde şans" diyor. [F] https://devforum.roblox.com/t/on-avg-how-many-visits-to-reach-500-highly-engaged-players/4726971
- Bir başka rapor: 2.232 oyuncu (484'ü 16+ yaş-doğrulamalı) ve 0 sayılan HEP. [F]

### 2.3 Eşik zaman çizelgesi
| Tarih | Olay | Kaynak |
|---|---|---|
| 19 May / 16 Haz 2026 | Kids/Select lansmanı; giriş eşiği 500 HEP/60 gün; bakım eşiği (katalogda kalmak) 100 | [R] devforum 4630944, 4685717 |
| 6 Tem 2026 | HEP tanımı gevşetildi (yeni oyun girişi +%33 tahmini) | [R] devforum recap 4730771 |
| 16 Tem 2026 | Bakım eşiği 100 -> 25 | [R] devforum 4820164 |
| 19 Ağu 2026 | **Giriş eşiği 500 -> 250** | [R] https://devforum.roblox.com/t/highly-engaged-player-threshold-drops-to-250/4820164 |
| 11 Eyl 2026 | "250 -> 100, Kasım'a kadar" paylaşımı (RTC/Bloxy News hesapları) | [?] https://x.com/Bloxy_News/status/2098519640951705762 (resmi doküman henüz 250) |

### 2.4 Neyi hızlandırır? (ve neyi hızlandırmaz)
- 16+ yaş-kontrollü kullanıcıyla gerçek etkileşim: "16+ kullanıcılarla artan etkileşim ilerlemeyi hızlandırır" (resmi doküman).
- **Expedited review** (hızlandırılmış inceleme): oyun başına tek sefer iade edilebilir ücret; doküman 50.000 Robux, Haziran duyurusu 100.000 Robux diyor (çelişki [?]); 48 saat; HEP şartını aşar ama içerik standartları aynı. Öğrenci bütçesi için gerçekçi değil, ÖNERMİYORUM (💰 ⚠ ONAY, kilitli bakiye, 90 gün).
- Engagement hedefli reklam (bkz. 3. bölüm): Roblox "doğrudan yol" diyor, sonuçlar karışık.
- Beta modu açıksa öneri sistemi oyunu İZLEMEZ ("Home Recommendations sistemi tarafından izlenmemeli") [R]: https://devforum.roblox.com/t/a-new-way-to-test-before-launch-experience-betas/4144485 . Beta modunun HEP sayacını engellediğine dair rapor [F] (https://devforum.roblox.com/t/audience-reach-confusion/4643900).
- "Exclude from recommendations" (Audience > Advanced Settings) açıksa RFY'den çıkarılırsınız [R: publish-experiences-and-places].

### 2.5 İçerik anketi sonucu erişimi değiştirir mi?
- Evet, ama yalnızca içerik doğruysa: oyunda şiddet/korku/kaba mizah yoksa dürüst cevap "Minimal/Mild" olacaktır ve Kids+Select kapısını açar. Cevaplar EN YOĞUN içeriğe göre verilmeli; yanlış beyan moderasyon ve etiket kaldırma riski taşır. [R]
- Etiket tek başına erişim vermez; değerlendirme şart. "Content May Vary" kalmak 16+ tavanını kalıcı yapar.
- Oyundaki ücretli rastgele ürün (yumurta) politikası ve Kids/Select ilişkisi bu araştırmada ayrıca doğrulanmadı [?]; oyunun mevcut PaidRandomPolicy geçidi (CLAUDE.md) var.
- Yaratıcının kimlik doğrulaması Kids/Select yolu için zorunlu; sosyal link eklemek için de 16+ doğrulama şart. [R]
- 9-15 yaşındaki bir oyuncu, ebeveyni "İzinli oyunlar (Approved Experience)" ile tek tek oyunu açarsa 16+ oyuna girebilir [R: Content Maturity FAQ https://en.help.roblox.com/hc/en-us/articles/8863284850196-Content-Maturity-FAQ]. Bu oyuncuların HEP'e sayılıp sayılmadığı belirsiz [?].
- "Trusted friends" (güvenilir bağlantı) yaratıcının 16 yaş altı gerçek arkadaşlarının oynamasına izin vermesi gerekir ama pek çok hata raporu var [F].

---

## 3. Ads Manager: küçük bütçeyle strateji

### 3.1 Mevcut resmi özellikler  [R]
Kaynak: https://create.roblox.com/docs/production/promotion/ads-manager
- Reklam türü: Home ve Search'te "sponsored" oyun küçük resmi.
- Hedefler: **Plays** (oturum başlatma ihtimali yüksekler), **Earnings** (sınırlı; Robux harcayanlar), **Engagement** (beta; Kids/Select eşiğine sayılan yaş-kontrollü HEP'ler; daha yüksek CPP; hedefe gelince elle durdur). Eski adlarla Maximize Plays / Acquire New Users / Drive Retention / Reactivate var.
- Teklif: SADECE otomatik (bid cap kaldırıldı).
- Bütçe: günlük veya yaşam boyu (lifetime). Kampanya minimumu 10 kredi (Kasım 2025 duyurusu: kredi SATIN ALMA minimumu 10'dan 1'e indi; kampanya başlatma için 10 kredi şartı kaldı).
- Yayınlandıktan sonra sadece ad ve bütçe miktarı değişir (hedef, kitle, zaman, bütçe türü, yaratıcılar sabit).
- Öğrenme dönemi: ~ilk 24 saat ("Learning"); duraklatırsanız süre sıfırlanır [R: https://devforum.roblox.com/t/ads-manager-ui-targeting-enhancements/4333400]. Engagement kampanyası "genelde 3-5 gün" gerektirir.
- Raporlama gecikmesi 48 saate kadar; Plays/earnings reklamdan sonra 30 güne kadar atfedilebilir; sahtekarlık/invalid traffic iadesi bitişten 14 gün sonra analiz, 16. günde iade. Kullanılmayan krediler kampanya bitince iade edilir.
- Yaratıcılar: 16:9 etiketli en çok 10 küçük resim; 16:9 "tahmini %57 qPTR artışı" (Roblox iddiası). Search 1:1 varsayılan küçük resmi çeker.
- Kredi fiyatı: 1 kredi = 263 Robux (RDC25 sonrası; öncesi 285) [R: https://devforum.roblox.com/t/ads-for-creators-rdc-recap-and-what%E2%80%99s-next/3929106]. USD karşılığı kartla ödemede "1 kredi = 1 USD" gibi anılıyor ama resmi teyit yok [?]. Kredi kartı 18+ ister, Robux ile dönüştürme 13+.
- Hedefleme: cihaz, ülke, cinsiyet, tür, yaş. **Kitle/tür/cinsiyet hedeflemesi seçilirse reklam sadece kişiselleştirilmiş reklamı kabul etmiş 18+ kullanıcıya gösterilir**; tüm uygun kullanıcılara ulaşmak için hedefleme eklemeyin. Personel: dar hedefleme maliyeti artırır; geniş öneriliyor. [R] https://devforum.roblox.com/t/ads-manager-ui-targeting-enhancements/4333400
- **16+ oyun için yaş hedefleme sorunu**: seçenekler Tüm yaşlar / 13-17 / 18-24 / 25+; 16-17 yok, 13-17 seçilince 14-15 yaşlılar da girer (oynayamaz). 31 Ağustos 2026 bug raporu, personel yanıtı yok. [F] https://devforum.roblox.com/t/adsrobloxcom-pages-audience-targeting-doesnt-let-you-select-16-age-range/4842256
  Roblox'un reklam sistemi "oyunun erişilebilir kitlesi dışındakilere reklam göstermemeyi" otomatik yapıyor mu? Bulunamadı [?]. Sahibi, Ads Manager'da kampanya detayından "Plays" ve "yaş dağılımı"na bakarak gözlemlemeli (aşağıda).

### 3.2 Referans sayılar (hepsini şüpheyle okuyun)
| Ne | Değer | Güven |
|---|---|---|
| Roblox'un CPP kıyası, Maximize Plays | 0,0073 USD (11 Kas 2025); 0,008 (Ağu 2025) | [R] https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863 |
| Acquire New Users | 0,0187 USD | [R] aynı |
| Drive Retention / Reactivate | 0,0113 / 0,011 | [R] aynı |
| Engagement hedefi için resmi CPP | YOK ("daha yüksek") | [R] |
| Topluluk: "~8 USD / 1.000 oyun" (Maximize Plays) | tutarlı | [F] |
| Reklam CTR "iyi" eşikleri | >=%1 yeterli, <%0,3 yaratıcı sorunu; tecrübeli bir geliştirici >%4 hedefler | [F] (forum: https://devforum.roblox.com/t/how-much-money-should-i-spent-to-get-into-the-algorithm/4551439) |
| BLOXG: sponsored CTR ort. %1,2; CPC 0,25 USD; CPP 0,45 USD | metodolojisi belirsiz | [3] |
| Engagement beta örneği (Eyl 2026 forum): 10 kredi / 2 gün: 13 bin gösterim, CTR %2,36, ~200 oyun, sayılan HEP bilinmiyor | [F] https://devforum.roblox.com/t/what-is-the-best-ad-strategy-to-reach-500-highly-engaged-players-for-an-under-16-multiplayer-focused-game/4806311 |
| Engagement bug (17-19 Haz 2026): tıklama var, "oyun" 0 görünüyor, sonra "düzeltildi" | [F] https://devforum.roblox.com/t/new-engagement-campaigns-for-ads-manager-suspiciously-have-0-plays/4686589 |

### 3.3 Bizim kampanyanın okunuşu (ölçü, yorum değil)
Gözlenen: 3.466 gösterim, 38 tıklama, CTR %1,1, 4,74 kredi.
- CPM ≈ 4,74 / 3,466 = **1,37 kredi / 1.000 gösterim**; CPC ≈ 4,74 / 38 = **0,125 kredi / tıklama**.
- Roblox'un Maximize Plays kıyası olan ~0,0073-0,008 USD/oyun ile kıyaslarsak (1 kredi ≈ 1 USD varsayımıyla; bu eşdeğerlik resmi olarak teyitli değil [?]), bizim tıklama başı maliyetimiz ~15-17 kat yüksek. Bu beklenen bir fark: Engagement hedefi daha dar ve pahalı bir kitleyi hedefler (resmi dokümanın dediği gibi), "tıklama" da "oyun" da değil. (CPC ≠ CPP; çıkarım, [?]).
- CTR %1,1: topluluk ölçütlerinin alt-orta bandı (>=%1 "yeter", >%4 "iyi"). Yani küçük resim/başlık "felaket" değil ama kıyaslanabilir yükseltme payı var.
- **38 tıklama ama toplam ~16 oyuncu**: tıklayanların hepsi oyuna girmemiş olabilir. Olası nedenler (hipotez, hepsi doğrulanabilir): (a) 16 yaş altı/yaşı doğrulanmamış tıklayanlar oyuna giremedi, (b) uzun yükleme/çökme, (c) atfetme gecikmesi (Plays/CPP/Playtime "pending" = normal; 48 saat gecikme + 30 gün atıf penceresi), (d) HEP şartı. Teşhis: Analytics > Acquisition > "Sponsored ads" satırı (Users with plays, conversion rate) ve Retention > Breakdown: Source.
- 4,74 kredi ile hiçbir sonuç çıkarılamaz: Roblox 3-5 gün veri ister, geliştiriciler 5-7 gün/10-27 kredi tavsiye ediyor [F].

### 3.4 Hangi hedef? (karar tablosu)
| Hedef | Ne zaman | Notlar |
|---|---|---|
| Plays (Maximize Plays) | Yeni lansman, küçük bütçe (Roblox'un resmî önerisi), ucuz trafik + retention ölçümü | Reklam oyuncuları algoritma oyuncularından %20-30 kötü performans gösterebilir [F]; HEP sayılma oranı düşük raporlanıyor [F] |
| Engagement (beta) | Sadece HEP sayacını itmek için; ayrı bütçe | "Engagement reklamları berbat, tek tek oyuncu getiriyor" yorumu [F]; ama Roblox'un tek HEP-odaklı aracı |
| Earnings | Monetizasyon kanıtlıyken | Bizde erken |
| Drive Retention / Reactivate | Son 30 gün / 30-180 gün oyuncular | 16 oyuncuda kitle çok küçük (Recent >= 10.000 oyuncu şartı var) [R] |

### 3.5 Ne zaman reklam israf, ne zaman değerli?
- Reklam büyütür, kurtarmaz: retention zayıfsa reklam "çamaşır makinesi" olur [F]. Büyük oyunlardan ölçülmüş Roblox benchmark'ı: medyan D1 %10,3, D7 %1,6, D30 %0,5; tepe %1: D1 %22,2, D7 %9,1, D30 %4,7; medyan oturum 9,8 dk [3 ama güvenilir: GameAnalytics 2026, >=1M MAU olan 500+ oyun, bu örnek olgun oyunları öne çıkarır, tür kırılımı yok] https://www.gameanalytics.com/reports/2026-roblox-report . Simülatör için "D1 %32/%35" gibi tür rakamları satıcı tablolarından geliyor ve terfi edilmiş (promoted) oyun örneğidir; hedef olarak kullanmayın [3].
- Pratik eşik (benim sentezim, [?]): reklam harcamaya ancak **>= 50 yeni oyuncuda D1 >= %15-20 ve ortalama oturum >= 10 dk** görünce başlayın. Bunun altında önce ilk-dakika deneyimi.
- İyi haber: oyunumuz çok oyunculu değil (duvarlar oyuncuya özel), "boş sunucu" sorunu (tek tek gelen reklam trafiğinin boş sunucudan kaçması [F]) bizi az etkiler.

### 3.6 Somut öneriler
**A) ~0 ek bütçe (şu anki durum):**
1. Hiç kredi eklemeyin; "auto top-up (Robux -> kredi)" açıksa KAPATIN (Engagement kampanyası hedefe gelince kendiliğinden durmaz). ⚠ Kontrol sahibine ait.
2. Mevcut kampanyayı 3-5 gün veri alana kadar bırakın (öğrenme sıfırlanmasın), HEP sayacındaki değişimi (Audience > Reach) ve Acquisition > Sponsored ads'i not alın. Veri yetersiz/boş kalırsa kampanyayı durdurun; kullanılmayan kredi iade edilir [R].
3. Reklamdan beklentiyi sıfırlayın: 4,74 kredilik veri ile karar verilemez.

**B) Küçük bütçe (örnek 10-30 kredi):**
1. Önce ücretsiz hazırlık: video + 3-5 küçük resim + ilk dakika düzeltmeleri (bölüm 5-6).
2. Tek temiz test: **Plays**, GENİŞ hedefleme (kitle/tür/cinsiyet yok), 5-7 gün, toplam 10-15 kredi; 3-5 dürüst 16:9 yaratıcı (otomatik dağıtım). Başarı ölçütleri: CTR >= %1, CPP kıyası, reklam kohortunda D1, ve **HEP sayacındaki artış / kredi**.
3. Karar kuralı: 10-15 kredi sonunda HEP +5'ten az ve D1 < %10 ise DURUN; harcamayı Kasım eşik düşüşü + organik/içerik çalışmasına bırakın. (+5 eşiği benim varsayımım, [?])
4. Engagement'ı ikinci test olarak, ancak Plays testi sonucu HEP'e dönüşmüyorsa deneyin; Roblox personeli Plays bütçesini Engagement'a "taşımayın, ayrı yatırım" diyor. [R]
5. Zamanlama: hafta sonu CCU/tepe trafiği için Perşembe-Cuma başlatın (resmi: Cumartesi tepe; "başlangıç saati artık çok önemli değil, hafta sonu daha çok CCU" [F]).
6. 💰 ⚠ ONAY: her kredi harcaması; kredi kartı 18+.

---

## 4. Ücretsiz/ucuz büyüme kanalları (2025-2026)

Genel uyarı: bu bölümdeki "işe yarıyor" iddialarının çoğu satıcı/ajans içeriğidir [3]; bağımsız ölçüm yok. Hepsini küçük deneyle ve Share Link ölçümüyle test edin.

### 4.0 Hedef kitle gerçeği
- Oyun şu an yalnız yaş-kontrollü 16+. Roblox YouTuber/TikTok izleyicisinin büyük kısmı çocuk (<13/<16) ve bu kişiler oyuna GİREMEZ; yani yanlış kitleye gösterilen klip, tıklama olsa bile boşa gider ve "kullanılamaz" hayal kırıklığı yaratır.
- İdeal kitle: 16-25 yaş, Roblox'ta para harcayan, "gym / leg day / grind" mizahı seven kişiler. Kısa video açıklamasında "16+ (yaş kontrolü gerekir)" yazın (yanıltmamak için).
- Türkiye durumu: 18 Haziran 2026'da Türkiye'de Roblox yasağının kalktığı haberleri çıktı, Wikipedia ise haberin yanlış olduğunu ve yasağın sürdüğünü yazıyor; kaynaklar çelişiyor [?]. Analytics > Demographics (ülke/yaş) bu 16 oyuncunun kim olduğunu gösterir; Türkiye'ye kampanya yapmadan önce buna bakın.

### 4.1 Kısa video (TikTok / YouTube Shorts / Reels)
- Roblox resmi dokümanı bile "sosyal hesap, düzenli güncelleme, topluluk, yaratıcı/influencer ortaklığı" ve **Share Link ile kanal karşılaştırması** öneriyor. [R] https://create.roblox.com/docs/production/analytics/acquisition
- Oyunumuzun güçlü görsel kancası: karakterin gözle görülür büyümesi ("küçük -> dev"), duvar patlaması, "gün 1 vs gün 100". İlk 1 sn'de dönüşüm/sonuç, 15-20 sn, altyazılı, sessiz izlemeye uygun.
- Kural: ekranda gösterdiğiniz şey oyunda GERÇEKTEN olmalı (yanıltıcı görüntü hem Roblox küçük resim/video kurallarına hem de kitle güvenine aykırı).
- Ölçüm: her platform için ayrı Share Link (aşağıda); "izlenme" değil D7/oyun süresi/qualified play'e bakın.
- Sıklık iddiaları ("günde 3 video = 4x ziyaret") satıcı iddiasıdır [3]; test edin: 2 hafta, 10-14 klip, 3-5 farklı kanca.
- Bağlantı kısıtı: TikTok biyografi linki eşiği doğrulanmadı [?]; kısa linki yorum/biyografide kontrol edin.

### 4.2 Mikro-influencer / YouTuber tohumlama
- Bütçe aralıkları satıcı kaynaklı [3]: mikro (1-50K) video başı ~20-200 USD, orta 200-2.000 USD; Roblox'a özel "adanmış video" 500-25.000 USD iddiası. Küçük kanallar (1-10K) bazen ücretsiz oynar. DevForum'dan deneyimli iki geliştirici: 1-10K abonelik arası kanallara DM/e-posta ile ulaşın, oyun tam ve hatasız olsun, ödeme yapacaksanız **takip linkiyle performansa bağlı** ödeyin, büyük peşin ödeme yapmayın. [F] https://devforum.roblox.com/t/how-to-successfully-grow-your-game-ft-senseideveloper-vikinglaw-promoting-and-advertising-your-game/2535279
- Biz için özel: 16+ kitlesi olan, yetişkin/genç yetişkin izleyicili küçük yaratıcıları arayın; takipçi sayısı yerine izleyici yaşı ipuçlarına (yorumlar, içerik tonu) bakın.
- Güvenlik/uyum: ilk iletişim kanalı olarak yaratıcının herkese açık iş e-postası ya da sosyal profilidir; çocuk yaştaki kişilere özel mesajla ulaşmayın. Ücretli içerik açıklanmalı (#reklam / sponsored); Kıbrıs/AB tüketici kuralları [?] genel bilgidir, doğrulanmadı.
- 💰 ⚠ ONAY: herhangi bir ödeme. Ücretsiz tohumlama (anahtar yok, kod yok): erken erişim, geliştirici ile doğrudan hat, yaratıcıya özel küçük bir kozmetik **[kod değişikliği gerektirir, ⚠ ONAY; promosyon kodu sahibi tarafından reddedilmişti, önermiyorum]**.

**E-posta şablonu (EN, ~100 kelime):**
> Subject: A leg-day Roblox sim for 16+ (age-checked) viewers - quick question
> Hi [Name], I watched your [specific video] - loved [specific detail]. I'm a student dev and I made "+1 Squat Evolution: Smash Walls": tap squats, your avatar visibly grows from tiny to huge, and you kick through 100 themed walls. It's free; note it's currently 16+ (age-checked) only, so it fits an older audience. I'm not asking for a paid deal - just whether you'd like a look, and I'm happy to answer any questions or take feedback. Here is a tracked link: [Share Link]. Thanks for your time! - [Name]

**TR kısa sürüm:** "Merhaba [Ad], [video]'nu çok beğendim. Öğrenci geliştiriciyim; 'Squat Evolution' adlı, squat yaptıkça karakterin gözle görülür büyüdüğü ücretsiz bir oyun yaptım. Şu an yalnız yaş-kontrollü 16+ oyuncuya açık, bu yüzden daha büyük izleyiciye uygun. Ücretli iş teklifi değil; bir göz atmak ister misin? Takip linki: [link]"

### 4.3 Roblox Groups / Topluluk (Community)
- Gruba katılma karşılığı oyun içi ödül: DevForum'da yaygın görüş "izinli; grup, kendi kendini tanıtmanın uygun kanalıdır" ve `Player:IsInGroup()` ile kontrol edilir; **resmi onay yok**. [F] https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286 , https://devforum.roblox.com/t/boundaries-of-in-game-rewards/3051700
- Beğeni/favori karşılığı ödül: forum çoğunluğu "yasak / yasak sayılır" (beğeni API'den görülemediği için de ödül şartı yapılamaz); Roblox'tan ilgili metin bulunamadı. Güvenli taraf: ödül KARŞILIĞI değil, "Beğendiniz mi? 👍" gibi nötr hatırlatma [F][?]. Sahibi isterse ödülsüz hatırlatma düşünebilir.
- Roblox Topluluk Standartları "Repetitive and Misleading Content": başlık/metadata dahil aldatıcı içerik, keşfi/etkileşimi artırmak için yasak. Bot kullanımı "Disruptive Content" altında yasak; platform dışına yönlendirme yasak. [R] https://about.roblox.com/community-standards

### 4.4 Discord topluluğu ve sosyal linkler
- Oyun sayfasına en çok **3** sosyal link eklenir (Discord, YouTube, Twitch, Twitter/X, Facebook, Guilded, Roblox topluluğu); **sadece yaş-doğrulanmış 16+ kullanıcı görür**; yaratıcının da 16+ doğrulanmış olması şart. (Haziran 2026'dan itibaren 16 yaş altı kullanıcılar bu linkleri göremez.) [R] https://create.roblox.com/docs/production/promotion/social-media-links
- **Oyun içinde URL / Discord daveti yazmak YASAK**; sadece "oyun sayfamızdaki bağlantılara bakın" denebilir. [R] aynı sayfa
- Discord'un tek başına büyüme getirdiğine dair bağımsız veri bulunamadı; RPG türü Discord'da, korku TikTok'ta güçlü iddiası [3]. Küçük bir sunucu (duyuru + geri bildirim + 'LFG') yeterli; yönetim yükü sahibine ait. ⚠ ONAY (hesap oluşturma ve yönetme sahibine ait).

### 4.5 Reddit ve DevForum
(Kurallar sürekli değişir; ÖZEL OLARAK gönderi atmadan önce kenar çubuğundaki kuralı okuyun. Aşağıdaki özet ikincil toplayıcıdan, kuralların okunduğu 4-13 Ekim 2026 tarihleriyle.)
- r/roblox: tanıtım sadece sabitlenmiş/haftalık ayrılmış başlıkta, kendi gönderi olarak değil [3] https://threadfox.vip/rules/for/games
- r/robloxgamedev: "doğrudan reklam yasak"; r/RobloxDevelopers: "spam yapma"; r/playmygame: oyuna doğrudan link şartı; r/indiegames: görüntü/GIF/video şart; r/IndieDev: tanıtım kuralı belirtilmemiş (sessizlik izin değildir) [3].
- DevForum'da "Creations Feedback / Showcase" kategorileri geri bildirim için uygundur; bunlar tanıtım değil geri bildirim isteği olarak yazılmalı. Erişim için DevForum üyeliği ve güven seviyesi gerekebilir [?].
- Beklenti: bu kanallar HEP'e (harcama yapan 16+ oyuncu) dönüşüm açısından düşük verimli; asıl değerleri geri bildirim ve ilk oyuncu bulmak.

### 4.6 Çapraz tanıtım, etkinlikler, güncelleme duyurusu
- **Experience Events (Events & Updates, ücretsiz)**: Creator Hub > Engagement > Events & Updates > Create Event; küçük resim, kategori, başlık/alt başlık/açıklama; en çok 10 aktif/yaklaşan etkinlik; oyuncular "Notify me" ile etkinlik başlayınca bildirim alır; detay sayfasında hemen görünür. [R] https://create.roblox.com/docs/production/promotion/experience-events
- **Off-Platform Featuring** (App Store/Google Play etkinlik kartları): zamanlı etkinlik/önemli güncelleme için; gönderim en az **14 gün önce** (bir arama sonucu 7 gün diyor; çelişki [?]); etkinlik herkese açık olmalı, en çok 30 gün; seçim Roblox pazarlama ekibinde; 16+ oyunun uygun olup olmadığı belirtilmemiş [?]. [R] https://devforum.roblox.com/t/introducing-off-platform-featuring-for-creator-events/4142230 . Cadılar Bayramı (31 Ekim) için 14 gün kuralıyla son gönderim ~17 Ekim: etkinlik içeriği (kod) o tarihe yetişmeyebilir ve kabul beklentisi düşük; pratikte Aralık/yılbaşı gibi sonraki bir etkinlik için plan yapmak daha gerçekçi. Maliyeti sıfır, ancak etkinlik içeriği (kod) ⚠ ONAY.
- **Deneyim bildirimleri (Experience Notifications)**: oyunun en az 100 ziyareti olmalı, moderasyonda olmamalı; sadece opt-in 13+ kullanıcıya; kullanıcı başına oyun başına günde 1; `PromptOptIn()` ile izin istenir (30 günde 1 kez gösterilir); analitik >= 100 gösterimden sonra. Aldatıcı taktik yasak. [R] https://create.roblox.com/docs/production/promotion/experience-notifications . Kod değişikliği gerekir, daha önce "bildirim izni" fikri sahibinin cevabını bekliyordu (OYUN_TASARIM_ANALIZI.md) => ⚠ ONAY.
- **Davet/co-play**: RFY "intentional co-play days" sinyali (arkadaşla katılma, davet, özel sunucu) ikinci kademe önemli. [R] Davet düğmesi zaten var; ek iş gerekmez. (Genel API notu: `SocialService:PromptGameInvite` arkadaş listesi bazen geç yükleniyor [F].)
- **Güncelleme ritmi**: Roblox "küçük güncelleme 2-4 haftada bir, büyük özellik 2-3 ayda bir" öneriyor [R: https://create.roblox.com/docs/production/analytics/retention]; küçük resmi yeni içerikle yenileyin (Roblox personeli). Cumartesi trafiği yüksek, güncellemeyi Perşembe-Cuma çıkarmak mantıklı (çıkarım).
- **Showcase/etkinlik programları**: RDC26 (10-12 Eylül) bitti, Innovation Awards adaylıkları bitti, Developer Challenge jam'i (72 saat, 1-5 kişi) kapalı ama tekrar edebilir; **Roblox Jumpstart** "ilk özgün oyununu çıkarmaya çalışan küçük takımlar" için sürekli başvuruya açık, başvuru create.roblox.com/build üzerinden; öğrenci/tek kişi uygunluğu belirtilmemiş [?], "yenilikçi (novel)" şartı bizim oyun için zayıf. Düşük olasılıklı bedava bilet. [R] https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs

### 4.7 POLİTİKAYA AYKIRI / YASAK / YÜKSEK RİSK (yapma listesi)
| Eylem | Durum | Kaynak |
|---|---|---|
| Bot/otomasyonla ziyaret, oturum süresi, beğeni, favori şişirme (view-botting) | Yasak. Creator Rewards için açıkça: bot, otomasyon, tarayıcı eklentisi, teleport manipülasyonu yasak; ceza: ödüller silinir, programdan çıkarılma, hesap kapatma. Roblox "sahte aktiviteyi izleyip yok sayar". Topluluk Standartları'nda bot = "disruptive". | [R] https://create.roblox.com/docs/creator-rewards , https://about.roblox.com/community-standards |
| Mevcut kullanıcılara alternatif hesap açtırma | "Kesinlikle yasak" (Creator Rewards) | [R] |
| Beğeni/favori karşılığı ödül ("beğen = ödül") | Resmî metin yok; forumda yasak/yasak sayılıyor; Hesap/oyun riski | [F][?] |
| Yanıltıcı küçük resim / video / başlık (olmayan mekanik, abartılmış görsel, sahte ödül vaadi) | Keşifte ceza: azaltılmış öneri/arama, panelde banner | [R] https://create.roblox.com/docs/discovery , thumbnails sayfası |
| Para/ödül öne çıkaran başlık ("Robux! Play now!") | Cezalı | [R] discovery sayfası |
| Anahtar kelime doldurma, tekrar eden sözcük, aşırı emoji | Demotion riski | [R] publish sayfası |
| Başka oyunun adını/görselini/dosyasını kopyalamak | Özgün olmayan oyunlar geri plana atılır | [R] |
| Oyun içinde URL, Discord daveti, e-posta yazmak | Yasak | [R] social-media-links |
| Spam (sohbette/DM'de tekrarlı reklam) | Yasak | [R] Community Standards |
| 13 yaş altına yönelik reklamla ilgili ödül mekanizması | Yasak | [R] Advertising Standards (özet, sayfaya doğrudan erişilemedi) |

---

## 5. Oyun sayfası optimizasyonu

### 5.1 Başlık / açıklama / tür  [R] https://create.roblox.com/docs/production/publishing/publish-experiences-and-places
- Adı sık değiştirmeyin (eski adla bulunabilirlik düşer). Oyun adı zaten "+1 Squat Evolution: Smash Walls".
- Açıklamanın İLK cümlesi oyunu özetlesin ve ilgili anahtar kelimeleri içersin (tekrarsız): ör. gym/squat/leg day simulator, kas gelişimi, duvar kırma, evcil hayvan, yumurta, rebirth. "Simulator" kelimesi başlıktan çıktığı için (CLAUDE.md: önce "Squat Simulator") açıklamanın ilk cümlesinde yer almasını düşünün [öneri, ⚠ ONAY].
- Tür (Genre) ve alt tür ayarlayın (ayrı Genres sayfası bulunamadı; panelde listeyi doğrulayın [?]). Tür/etiket ranking faktörü DEĞİL, algoritma davranıştan öğrenir (FAQ); ama yanlış tür bounce yaratır.
- Tag sistemi dokümanda yok [R].
- Semantik arama: doğal dil sorguları ("food games") destekleniyor (resmi). Arama ağırlıkları yayınlanmadı [?].

### 5.2 İkon ve küçük resimler  [R]
Kaynaklar: https://create.roblox.com/docs/production/publishing/experience-icons , https://create.roblox.com/docs/production/publishing/thumbnails
- **İkon**: kare, en az 512x512; bazı yerlerde ~150x150 gösterilir, küçük boyutta test edin; belirgin ve alakalı; yüksek kontrast.
- **Küçük resim**: 16:9, ideal 1920x1080; jpg/gif/png/tga/bmp; alt kısmı boş bırakın (oyuncu sayısı kapatır); en çok 10 görsel/video; kişiselleştirme için <3 MB.
- **Thumbnail Personalization** (ücretsiz, dahili A/B benzeri): Creator Dashboard > Configurations > Places > Thumbnails > "Home Page" sekmesi; 2-5 aktif küçük resim seçin; algoritma çok kollu bandit ile grup başına kazananı seçer, ortalama +%8,5 qPTR (Roblox sayfası) / +%12 (personel yazısı); en az 7 gün veya sonraki güncellemeye kadar değiştirmeyin; birbirine çok benzer varyant koymayın; YANILTMAYIN. Tabloda Impressions / Qualified Plays / QPTR görünür. [R] https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689
- **Video**: Place > Videos; ayda 3 yükleme kotası (reddedilen de sayılır); onaylanınca detay sayfasında ilk sırada çıkar, Home'a da çıkabilir. Gerçek oyun görüntüsü; kamera açıları, hafif renk düzeltme, logo, oyun içi UI yazısı, katalogdan müzik OK; ses/anlatım, sözlü müzik, tanıtım yazısı/iddia, gerçek hayat görüntüsü, abartılmış grafik YASAK. Roblox testleri: RFY'de video önizleme, videolu oyunlarda oynama süresi +%39'a kadar (Mayıs-Temmuz 2026 testi), Standout'ta +%47 kaliteli oyun. [R] https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571
- Dört farklı motivasyonla 5 küçük resim önerisi (hepsi gerçek oyun görüntüsü, az yazı): (1) Dönüşüm "minik -> dev kaslı", (2) Duvar patlatma "100 duvar", (3) Evcil hayvanlar/yumurta, (4) Arkadaş bonusu/kalabalık, (5) Rebirth/Auto Click ilerleme. Hepsinde güçlü kontrast ve okunur küçük metin.
- "Misleading" için dikkat: Küçük resimde olmayan öğe (ör. ödül, olmayan boss) YASAK; mevcut çoğu ödül ve ögeleri gerçek ekran görüntüsüyle sınırlayın.

### 5.3 Analytics'i okuma rehberi
Kaynaklar: https://create.roblox.com/docs/production/analytics , https://create.roblox.com/docs/production/analytics/acquisition , https://create.roblox.com/docs/production/analytics/retention
- **Acquisition**: kaynaklar = Home recommendations, Continue play, Today's/Standout Picks, Home other, Friends, Search, Charts; Reklam = Sponsored ads, Search ads, Portal ads; Teleport; Other (dış linkler). Her kaynak için: Users with plays, conversion rate, D7 retention, 7D playtime/user, 30D payer conversion, 30D revenue/user. **Share Links** sekmesi: her linkin Link Visits'i, qualified-play kullanıcıları, D7, süre.
- **Home Recommendations** sekmesi (Analytics > Acquisition): PTR, bounce, play days, playtime, vb. ve "benzer oyunlar" kıyası. Benchmark puan kartı >= 100 DAU ister; kıyaslar algoritmayı etkilemez. [R]
- **Retention**: D1/D7/D30; Breakdown > Source seçerek dış link vs Home vs reklam kohortlarının retention'ını ayırın. [R] https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157
- **Funnels**: Roblox'un funnel olaylarıyla onboarding adımları. Oyunda zaten `Config.Funnel` (Joined, Clicked30, FirstWall, FirstPet, FirstSkin, Level12, FirstRebirth) AnalyticsService funnel olayları gönderiyor: hangi adımda en çok oyuncu kaybettiğinizi bu gösterir (yeni kod gerekmez).
- **Demographics**: ülke/yaş (16 oyuncunun kim olduğunu gösterir) [R doc listesinde adı geçmiyor, panelde var olduğunu doğrulayın [?]].
- **12 Ekim 2026 ölçüm değişikliği**: Home/Search/Charts gösterim, tıklama ve oyun sayıları artabilir, PTR hafif düşebilir; bu performans değişikliği DEĞİL; öncesi-sonrası kıyaslarken dikkat. [R] https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122
- **Teşhis ağacı** (resmi mantığın uyarlaması):
  1. Home Recommendations'ta gösterim (impression) neredeyse 0 mı? -> dağıtım/uygunluk sorunu (Beta modu, Exclude from recommendations, 16+ havuzunun küçüklüğü, çok yeni). Yapılacak: kapıları kontrol, bekle, içerik/dış trafikle veri biriktir.
  2. Gösterim var, PTR düşük mü? -> ikon/küçük resim/başlık/açıklama; personalization.
  3. PTR iyi, first-play bounce yüksek mi? -> yükleme ekranı süresi (oyunda en az 3 sn, en çok 30 sn), cihaz performansı, ilk 30 sn, hatalar.
  4. D1 iyi, D2-7/D8-28 düşük mü? -> ilerleme/geri dönüş nedenleri (rebirth, çark, görev). Bu zaten oyunun içeriği.

---

## 6. 14 günlük öncelikli büyüme planı (bizim durumumuz: 0 bütçe, 16+ kapısı, ~16 oyuncu)

Prensip: (1) kapıları aç, (2) gelen az sayıda 16+ oyuncunun ilk dakikasını/retention'ını iyileştir, (3) ücretsiz yüzeyleri doldur (video, küçük resim, event), (4) küçük ve ölçülebilir dış deneyler yap, (5) para ancak veri varsa. Kasım'daki muhtemel eşik düşüşü (100 HEP, [?]) için sayaç kayan 60 günlük olduğundan şimdi biriken HEP boşa gitmez.

| Gün | İş | Maliyet | Onay | Başarı ölçütü |
|---|---|---|---|---|
| 1 | **Kapı denetimi**: Audience > Reach (ekran görüntüsü; gereksinim listesi, HEP sayacı), tam anket yapıldı mı ve etiket ne, ID doğrulama, 2FA, Plus/ücret durumu; Experience Settings: Public, Beta mode KAPALI, "Exclude from recommendations" KAPALI; Ads Manager: auto top-up KAPALI | 0 | Sahibi yapar | Hepsi "tamam" ya da net eksik listesi |
| 1 | Analytics ilk bakış: Acquisition kaynakları, Retention > Source, Demographics (ülke/yaş), funnel (Config.Funnel adımları) | 0 | - | Kayıp noktası ve kitle tablosu |
| 2 | Küçük resimler: 3-5 farklı, dürüst 16:9 + yeni ikon kontrolü; Thumbnail Personalization AÇ (>= 2 aktif) | 0 | ⚠ (içerik üretimi) | Home Page sekmesi tablosu doluyor |
| 2 | 15-30 sn **gerçek oynanış videosu** yükle (Place > Videos; anlatım/yazı yok; "tap -> büyü -> duvar") | 0 | - | Video onayı |
| 2 | Açıklamanın ilk cümlesini ve anahtar kelimeleri düzelt; sosyal link (Discord/YouTube/TikTok) ekle (16+ doğrulama) | 0 | ⚠ (metin kararı) | Sayfa güncel |
| 3 | Her platform için **ayrı Share Link** üret (TikTok, YouTube, Discord, Reddit, arkadaş) | 0 | - | Link Visits ölçülür |
| 3-6 | **10-14 kısa klip** üret/yayınla (TikTok + Shorts, 16+ vurgusu); 3-5 farklı kanca test et | 0 (zaman) | ⚠ (sosyal hesap açma/yayın sahibi yapar) | Klip başına Link Visits ve D7 |
| 3-7 | 20 mikro yaratıcıya (1-30K) kişiye özel e-posta/DM; ücretsiz | 0 | ⚠ (dış mesaj sahibinden) | Yanıt oranı, ilk 1-2 video |
| 4 | Discord sunucusu (basit) + Roblox topluluğu/gruba yönlendirme | 0 | ⚠ (hesap oluşturma) | Üye sayısı, geri bildirim |
| 4-8 | DevForum Creations Feedback / uygun subreddit kuralına göre geri bildirim iste (tanıtım DEĞİL) | 0 | ⚠ (yayın) | Kullanılabilir geri bildirim |
| 5 | İlk deneyim iyileştirmesi hazırla (kod): ilk 3 dk, yükleme süresi, ilk Win/pet deneyimi; funnel'daki en büyük kayıp adım | 0 | ⚠ ONAY (kod değişikliği; bu rapor kodu değiştirmez) | D1, first-play bounce |
| 6 | Experience Event oluştur (Events & Updates); Off-Platform Featuring için 14 gün kuralı nedeniyle Cadılar Bayramı büyük olasılıkla kaçar (son gönderim ~17 Ekim), Aralık/yılbaşı etkinliği için takvim kur | 0 | ⚠ ONAY (içerik) | Etkinlik sayfası yayında |
| 7 | **Ara değerlendirme**: Home Recommendations sekmesi (gösterim var mı?), PTR, bounce, D1 by source, HEP sayacı | 0 | - | Teşhis ağacı kararı |
| 8-9 | Standout Games başvurusu (anket + gameplay videosu); Jumpstart başvurusu (opsiyonel) | 0 | ⚠ (başvuru) | Başvuru gönderildi |
| 8-10 | (İsteğe bağlı) Moments için Video Captures API planı (rebirth anında klip istemi) - anket güncellemesi gerekir | 0 | ⚠ ONAY (kod+anket) | Planlandı |
| 10-12 | İkinci kısa video turu: en iyi kancaya yatırım; yaratıcı yanıtlarını takip | 0 | - | Share Link verileri |
| 12 | Küçük güncelleme Perşembe-Cuma (duyuru: Experience Event + sosyal hesaplar) | 0 | ⚠ ONAY | Cumartesi trafiği |
| 14 | **Karar noktası**: D1 >= %15-20 (>= 50 yeni oyuncuda)? HEP sayacı hızı? Kasım eşik düşüşü resmileşti mi? -> bütçe varsa tek test (bölüm 3.6-B), yoksa 14 gün daha organik/içerik | 💰 (sadece onaylanırsa) | ⚠ ONAY | Karar kaydı |

Para harcayan HİÇBİR adımı kendiliğinden öneriyorum: sadece Gün 14 sonrası 💰 isteğe bağlı reklam testi.

---

## 7. En değerli 10 öneri (öncelik sırasıyla)
1. Kapıları doğrula (anket TAM mı, Beta/Exclude kapalı mı, Public mı, 2FA/ID/Plus-ücret tamam mı) - 15 dk, bedava, en büyük hata riski.
2. Ek reklam bütçesi yok: auto top-up'ı kapat, mevcut Engagement kampanyasına 3-5 gün tanı, HEP sayacına etkisini ölç; 4,74 kredilik veriyle karar verilmez.
3. Ücretsiz gerçek oynanış videosu yükle (RFY'de oynama süresi +%39'a kadar test sonucu).
4. 3-5 farklı dürüst küçük resim + Thumbnail Personalization (7 gün dokunma).
5. Her dış kanal için ayrı Share Link; Retention > Source ile D1/D7'yi kaynaklara göre karşılaştır.
6. İlk dakika/first-play bounce ve D1 (funnel'daki en büyük kayıp adım): reklamdan ve influencer'dan önce.
7. 16+ ve harcama yapan kitleyi hedefleyen kısa videolar; açıklamada "16+ (yaş kontrolü)" yaz; mikro yaratıcıya ücretsiz tohumlama.
8. Kasım'daki muhtemel 100 HEP eşiğini bekle (resmî teyit yok [?]): şimdiki HEP'ler 60 gün kayan pencerede sayılır; pahalı HEP-avı yok.
9. Experience Event + Off-Platform Featuring (>= 14 gün önce) ve Standout/Jumpstart başvuruları (düşük olasılık, bedava).
10. Yapmayın listesine sadık kal: bot, beğeni karşılığı ödül, yanıltıcı görsel, oyun içinde Discord/URL, "ücretsiz Robux" başlığı, promosyon kodu.

---

## 8. Doğrulanamayan / çelişkili noktalar
- Eşiğin Kasım'da 100 olması (sadece sosyal medya/haber, resmi doküman 250).
- HEP'in tam tanımı: asgari harcama miktarı, kıdem ve oynama süresi sayıları yayınlanmadı; reklam/dış link oyuncularının sayılıp sayılmadığı resmi olarak belirtilmedi (forumda "sayılmıyor" varsayımı).
- Yayın ücreti iadesi: doküman bir yerde "90 gün sonra" (uygun hale geldikten), başka yerde "60 gün boyunca 25 HEP"; Expedited ücret: 50.000 vs 100.000 Robux.
- Off-Platform Featuring gönderim süresi: 14 gün vs 7 gün; 16+ oyunun uygunluğu belirsiz.
- Ads Manager: 16+ oyun için ücretli reklamın uygun olmayan kitleyi otomatik filtreleyip filtrelemediği; Engagement hedefinin gerçek maliyet/sayılma oranı; 1 kredi = 1 USD karşılığı.
- Up-and-Coming / Top Trending resmi formülü; arama sıralaması ağırlıkları; beğeni/favori etkisi.
- Türkiye'de Roblox erişim durumu (Haziran 2026 haberleri çelişiyor).
- Tür bazlı (simülatör) D1/D7 hedefleri: bağımsız ve güvenilir veri bulunamadı; GameAnalytics tür kırılımı vermiyor.
- Moments'ın 16+ oyunlara getireceği trafik büyüklüğü; Video Captures API'nin ayrıntıları (yaş, anket güncelleme) uygulamadan önce resmi dokümanda doğrulanmalı.
- TikTok/YouTube Shorts'ta "işe yarayan" tüm rakamlar ajans/satıcı kaynaklı.
- Reddit kuralları ikincil toplayıcıdan (okunma tarihleri 26 Eylül-13 Ekim 2026), doğrudan Reddit'e bu araştırmada erişilemedi.

---

## 9. Kaynak listesi (URL)
Resmi (create.roblox.com / about.roblox.com):
- https://create.roblox.com/docs/discovery
- https://create.roblox.com/docs/discovery-faq
- https://create.roblox.com/docs/production/publishing/kids-and-select
- https://create.roblox.com/docs/production/promotion/content-maturity
- https://create.roblox.com/docs/production/publishing/publish-experiences-and-places
- https://create.roblox.com/docs/production/promotion/ads-manager
- https://create.roblox.com/docs/production/publishing/thumbnails
- https://create.roblox.com/docs/production/publishing/experience-icons
- https://create.roblox.com/docs/production/analytics
- https://create.roblox.com/docs/production/analytics/acquisition
- https://create.roblox.com/docs/production/analytics/retention
- https://create.roblox.com/docs/production/promotion/social-media-links
- https://create.roblox.com/docs/production/promotion/experience-events
- https://create.roblox.com/docs/production/promotion/experience-notifications
- https://create.roblox.com/docs/production/promotion/share-links
- https://create.roblox.com/docs/creator-programs/standout-games
- https://create.roblox.com/docs/creator-programs/creator-events
- https://create.roblox.com/docs/creator-rewards
- https://about.roblox.com/community-standards
- https://about.roblox.com/newsroom/2026/02/moving-beyond-self-reported-age
- https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available
- https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- https://about.roblox.com/newsroom/2026/07/moments-new-homepage-unlocks-gaming-for-all
- https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play
- https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs
- https://en.help.roblox.com/hc/en-us/articles/8863284850196-Content-Maturity-FAQ

DevForum resmi duyurular:
- https://devforum.roblox.com/t/highly-engaged-player-threshold-drops-to-250/4820164
- https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717
- https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944
- https://devforum.roblox.com/t/weekly-recap-july-6-10-33-more-games-entering-kids-select/4730771
- https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571
- https://devforum.roblox.com/t/boost-your-discovery-with-the-improved-recommended-for-you-algorithm-and-analytics-for-creators/3587441
- https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122
- https://devforum.roblox.com/t/ads-manager-updates-home-search-combined-new-benchmarks-and-sunsetting-the-classic-flow/4084863
- https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159
- https://devforum.roblox.com/t/ads-manager-ui-targeting-enhancements/4333400
- https://devforum.roblox.com/t/ads-for-creators-rdc-recap-and-what%E2%80%99s-next/3929106
- https://devforum.roblox.com/t/a-new-way-to-test-before-launch-experience-betas/4144485
- https://devforum.roblox.com/t/introducing-off-platform-featuring-for-creator-events/4142230
- https://devforum.roblox.com/t/roblox-moments-a-new-era-of-user-generated-discovery-for-experiences-and-gameplay-is-here/3919813
- https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689
- https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157
- https://devforum.roblox.com/t/testing-an-enhanced-discover-page-top-charts-and-new-sorts/2954676

DevForum topluluk raporları [F]:
- https://devforum.roblox.com/t/highly-engaged-players-not-counting-up/4644386
- https://devforum.roblox.com/t/audience-reach-confusion/4643900
- https://devforum.roblox.com/t/on-avg-how-many-visits-to-reach-500-highly-engaged-players/4726971
- https://devforum.roblox.com/t/what-is-the-best-ad-strategy-to-reach-500-highly-engaged-players-for-an-under-16-multiplayer-focused-game/4806311
- https://devforum.roblox.com/t/new-engagement-campaigns-for-ads-manager-suspiciously-have-0-plays/4686589
- https://devforum.roblox.com/t/engagement-goal-not-being-available-in-ads-manager-despite-game-not-being-eligible-for-roblox-select-and-kids/4691342
- https://devforum.roblox.com/t/how-much-money-should-i-spent-to-get-into-the-algorithm/4551439
- https://devforum.roblox.com/t/adsrobloxcom-pages-audience-targeting-doesnt-let-you-select-16-age-range/4842256
- https://devforum.roblox.com/t/my-reach-is-still-stuck-at-16-despite-reaching-500-highly-engaged-players/4727508
- https://devforum.roblox.com/t/how-to-successfully-grow-your-game-ft-senseideveloper-vikinglaw-promoting-and-advertising-your-game/2535279
- https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286
- https://devforum.roblox.com/t/boundaries-of-in-game-rewards/3051700
- https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969

Üçüncü taraf [3]:
- https://www.gameanalytics.com/reports/2026-roblox-report
- https://threadfox.vip/rules/for/games
- https://zehn-studio26.com/news/roblox-kids-and-select-publishing-requirements/
- https://x.com/Bloxy_News/status/2098519640951705762
- https://bloxg.com/statistics/roblox-advertising-benchmarks (satıcı; metodoloji belirsiz)
