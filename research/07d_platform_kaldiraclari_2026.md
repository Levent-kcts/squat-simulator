# 07d - Platform Kaldıraçları (Haziran-Ekim 2026): yeni ve küçük bir oyun nasıl keşfedilir?

Tarih: 2026-10-20. Salt araştırma (hesap işlemi, harcama, paylaşım YOK).
Oyun: "+1 Squat Evolution: Smash Walls" (universeId 10769004038, placeId 110682495880484). Durum: 18 toplam ziyaret, 0 CCU, yalnız yaş-kontrollü 16+.
Bu dosya `research/02_discovery_growth.md`'nin (2026-10-14) DEVAMIDIR; orada yazılanlar (RFY sinyalleri, 28 günlük pencere, thumbnail personalization, Moments'ın genel tanımı, reklam CPP kıyasları, yapma listesi) burada TEKRARLANMAZ, sadece yeni bulgu ve düzeltmeler var.

Etiketler:
- **[D]** Doğrulandı: resmi kaynak (create.roblox.com dokümanı, DevForum Roblox personeli duyurusu, Roblox newsroom / IR).
- **[K]** Topluluk raporu (DevForum yanıtı, X paylaşımı): gerçek deneyim, doğrulanmamış, tek örnek.
- **[T]** Tahmin / çıkarım / üçüncü taraf blog: yön gösterir, kesin değil.

---

## 0. En önemli 8 yeni bulgu (02'den sonra)

1. **HEP eşiği Kasım'da 100'e iniyor: artık RESMİ.** 02'de "[?] sadece sosyal medya" diye yazılmıştı; RDC26 resmi özet duyurusu "Highly Engaged Player threshold 250'den 100'e, bu Kasım" diyor. [D] (RDC26: What We Announced). Doküman sayfası bugün hâlâ 250 yazıyor; geçiş tarihi gün olarak verilmedi [D]. Fall Roadmap'te ayrıca "Relaxed Kids & Select requirements (Late 2026): daha düşük etkileşim ve inceleme şartı" maddesi var [D].
2. **Sayaç saatlik değerlendiriliyor, Audience Reach'te "gerçek zamanlı" izlenebiliyor** [D] (kids-and-select dokümanı: "evaluated hourly"; 12-18 Ekim recap yanıtlarında da "HEP sayıları artık saatlik güncelleniyor" [K]). Yani 02'deki "günlerce 0'da kalıyor" şikâyetleri büyük ölçüde eski dönem.
3. **Yayın akışı sadeleşti (12 Ekim 2026, kademeli yayılım):** tek soruyla 16+ yayın, "Playtest" sekmesi (eski Private/Limited yerine), **10 erken test kullanıcısı** davet (benzer yaşta arkadaş ya da güvenilir arkadaş; filigranlı önizleme). [D] (publish dokümanı; RDC26 özeti) Bizim için anlamı: 16 yaş altı arkadaşlar da test edebilir ama bu oynamalar HEP sayılmaz [T].
4. **Deneyim bildirimleri için en az 100 ziyaret şartı var; bizde 18 ziyaret.** Opt-in istemi (NotifOptIn) koddaki haliyle zararsız ama şu an bildirim GÖNDERİLEMEZ; ayrıca koddan gerçek bildirim gönderme hiç yok (CLAUDE.md "henüz YOK"). [D] (experience-notifications). Fall Roadmap: "Developer Push Notification Support (Late 2026)" [D].
5. **Off-Platform Featuring gönderimi artık en az 7 gün önce** (02'de 14 gün yazıyordu; doküman 7 gün diyor) ve seçim ölçütleri açıkça "DAU büyümesi, oyun süresi, retention, monetizasyon" [D]. 0 CCU'lu oyun için seçilme olasılığı çok düşük [T]. Etkinliklerin Charts'taki "Trending Events in Experiences" sırasına girmesi için **en az 1.000 RSVP** gerekir [D]: bizim için ulaşılmaz.
6. **Creator Rewards (Daily Engagement) küçük oyuna da otomatik işler**: Active Spender (60 günde >= 9,99 USD harcamış) bir kullanıcı günün ilk 3 oyunundan biri olarak bizimkini >= 10 dk oynarsa 5 Robux [D]. Audience Expansion (%35 pay, Share Link/doğrudan link/isim aramasıyla gelen yeni kullanıcı) ise **60 gün ortalama >= 100 DAU** ister [D]: şimdilik yok.
7. **Ads Manager (2 Ekim RDC özeti):** Engagement hedefi resmi dokümanda duruyor ("oturumları Kids/Select HEP eşiğine sayılan yaş-kontrollü HEP'lere ulaşır", CPP daha yüksek, 3-5 günde ilerleme yoksa onboarding'i düzelt, hedefe ulaşınca kendiliğinden DURMAZ) [D]. Kredi alım minimumu 1 kredi; kartla ilk yükleme 5 USD (kullanılmayan iade); kart 18+, Robux->kredi 13+ ve geri alınamaz [D]. Earnings hedefi sadece para kazandıran oyunlara (ARPU >= 6 Robux örneği) [D]. Sponsored kutularda oynanış videosu "önümüzdeki haftalarda" [D]. Roblox "yüksek retention'lı oyunlar daha iyi reklam dağıtımı alır" diyor [D], yani zayıf retention'la reklam pahalılaşır.
8. **Yeni oyunlar gerçekten öne çıkabiliyor:** Ağustos 2026'da saat bazında ilk 100 oyunun %28'i, ilk 1.000'in %33'ü son 90 günde çıkmış [D] (RDC26). Ayrıca "Play on the Web (Late 2026)": YouTube/X/Discord linkine tıklayan Chrome'da kurulumsuz oynayacak [D] - dış linklerin dönüşümü artabilir, 16+ yaş kontrolü yine geçerli olacaktır [T].

---

## 1. "Highly engaged player" (HEP): tanım, görünürlük, hızlandırma

### 1.1 Resmi tanım (değişmedi) [D]
- "Hesap kıdemi, oyunda oynama süresi ve platform harcaması" şartlarını karşılayan oyuncu. Harcama: son 60 günde Roblox'ta HERHANGİ bir yerde asgari satın alma + aynı pencerede bizim oyunda zaman geçirmiş olmak; oyunumuzda harcaması gerekmez; ücretsiz oyunlar sayılır. Asgari tutar/süre/kıdem sayıları YAYINLANMADI.
- Eşik: 60 günde 250 benzersiz oyun (yaş-kontrollü HEP). Kasım'da 100 (RDC26) [D]. Bakım eşiği 25 [D] (02'de var).
- İlerleme: Creator Hub > Audience Reach, saatlik değerlendirme [D].
- Hızlandırma resmi olarak sadece: "16+ yaş-kontrollü kullanıcılarla etkileşimi artırmak", Expedited review (50.000 Robux, iade edilebilir; öğrenci için gerçekçi değil), Ads Manager Engagement hedefi [D].
- Yayın ücreti 1.000 Robux; doküman bir yerde "uygun olduktan 90 gün sonra otomatik iade", başka yerde "60 gün 25 HEP tutarsa iade" diyor (iki sayfa çelişkili, 02'de de not edilmişti) [D][?].

### 1.2 Geliştiricilerin 16+ kapısını geçiş raporları (Ağu-Ekim 2026)
| Rapor | Yöntem | Sonuç | Etiket |
|---|---|---|---|
| X'te bir geliştirici (Ağu 2026) | Engagement kampanyası, 36 kredi | "3 günde 250 HEP" | [K] |
| DevForum (Eyl 2026) | Engagement kampanyası | ~1 USD / 1.000 gösterim, sadece ~20 HEP; "uygunluk ~500 USD tutar" tahmini | [K] |
| DevForum (eski 500 eşiği) | ~4 gün reklam, "berbat istatistikli" oyun | Geçti | [K] |
| DevForum | Engagement, 250+ oyun | Sayaç ~165'te kaldı | [K] |
| DevForum (Eyl 2026) | Sosyal medya + geliştirici çevresi | "Birkaç ay pazarlama" | [K] |
- Sonuç: aralık çok geniş (3 gün - aylar); en büyük değişken oyunun Engagement kitlesindeki tutunması ve bütçe [T]. 0 CCU ve 18 ziyaretle ilk 100 HEP'in organik gelmesi bekleme değil, aktif kaynak gerektirir [T].
- Kasım'da eşik 100 olunca 60 günlük kayan pencerede biriken HEP'ler sayılır (pencere mantığı resmi; eşik geçişinin geriye dönük sayımı ayrıca belirtilmedi) [D][T].

### 1.3 Bizim için pratik okuma [T]
- 18 ziyaret içinden kaç HEP sayıldığına sahibi Audience Reach'te bakmalı (saatlik). 0 ise beklenen: ziyaretçiler büyük ihtimalle aile/arkadaş/test.
- Kasım'daki 100 eşiği, küçük bir Engagement testinin (bkz. 3) maliyetini yarıya ve daha aşağıya çeker; harcama kararını eşik resmen 100 olduktan sonraya ertelemek mantıklı.

---

## 2. Keşif yüzeyleri: küçük yeni oyun neyi gerçekten kullanabilir?

| Yüzey | Durum (Ekim 2026) | Küçük oyun için gerçekçilik | Etiket |
|---|---|---|---|
| Home RFY (28 gün retention modeli) | Değişmedi (02). 12 Ekim'den itibaren yeni ölçüm hattı: gösterim/oyun artar, PTR biraz düşer, performans değişikliği değil | YÜKSEK: tek otomatik yüzey; organik RFY oyuncusu lazım | [D] |
| Charts (Up-and-Coming, Trending) | DAU eşikli, kişiselleştirilmemiş | Şimdilik YOK | [D]/[T] |
| Today's Picks | Doküman sadece Marketplace (avatar eşyaları) için başvuru programı anlatıyor; oyunlar için açık başvuru bulunamadı | YOK | [D] |
| Standout Games | Ücretsiz anket, "yenilikçi" ister | DÜŞÜK (02'de var) | [D] |
| Search | Fall Roadmap: Search landing page ve dinamik filtreler Late 2026'ya ertelendi; isim koruma ve "promotional text" Late 2026 | ORTA: isim/açıklama ilk cümlesi | [D] |
| Moments | 16+ kademeli yayılım (02); Captures API var; oyunda CaptureService kullanımı YOK | ORTA, ücretsiz, kitlemizle örtüşüyor | [D]/[T] |
| Experience Events | Detay sayfasında Events bölümü, "Notify Me", grup sayfası Events sekmesi, gelen kutusu + push bildirimi; Charts sırası >= 1.000 RSVP | ORTA (sayfa içi), Charts YOK | [D] |
| Update announcements (Events & Updates) | 60 karakter, 3 günde bir; takipçilere gider; Views/Visit rate/Unfollow analitiği | ORTA: oyunu "follow" eden azsa etkisi az | [D] |
| Experience Notifications | >= 100 ziyaret şartı, 13+ opt-in, günde 1/kullanıcı, spam sistemi erişimi etkileşime göre ayarlar | ŞİMDİ YOK (18 ziyaret); 100'den sonra D1-D7 dönüş aracı | [D] |
| Push bildirim (geliştirici) | Late 2026 | İleride | [D] |
| "Friends are playing" / co-play | RFY'de ikinci kademe sinyal (02); RightHud'da PromptGameInvite zaten var | Var | [D] |
| Off-Platform Featuring | >= 7 gün önce gönderim, public, 7-30 gün; seçim DAU/retention'a bakar | ÇOK DÜŞÜK | [D] |
| Creator Rewards | Daily Engagement otomatik (5 Robux); Audience Expansion >= 100 DAU | Gelir değil, sinyal; önemsiz | [D] |
| Game items on Home | Late 2026: pass/dev product'lar oyuna girmeden Home'da görünecek | İleride; Auto Click / Starter Pack için vitrin | [D] |
| Free pass trials | Late 2026: pass bir oturum ücretsiz denenebilecek | İleride; Auto Click pass'i için doğal uyum | [D] |

---

## 3. Ads Manager / Sponsored 2026: küçük bütçe ne zaman değer?

### 3.1 Resmi kurallar (Ekim 2026) [D]
- Hedefler: Plays, Engagement (HEP için), Earnings (monetizasyon eşiği olan oyunlar). Kitleler: All, New, Recent, Lapsed (son ikisi asgari oyuncu sayısı ister).
- Gelişmiş hedefleme: konum, yaş, cinsiyet, tür, cihaz. Yaş seçenekleri 16-17 içermiyor (02'deki hata raporu sürüyor [K]); kitle/tür/cinsiyet hedefleme seçilirse reklam sadece kişiselleştirilmiş reklamı kabul eden 18+ kullanıcıya gider (02'de kaynaklı) [D].
- **Reklamın oyunun 16+ uygunluğunu otomatik gözetip gözetmediği resmi dokümanda YAZMIYOR** [D]. RDC özeti 13 yaş altına da Sponsored kutu gösterildiğini söylüyor (kişisel veri hedeflemesi yok) [D]. Yani Plays hedefli bir reklam teorik olarak oyuna giremeyecek kullanıcılara da gösterilebilir; bu doğrulanmadı [T]. Engagement hedefi tanım gereği yaş-kontrollü HEP'leri seçtiği için 16+ oyunda daha az israflı olmalı [T].
- Öğrenme dönemi ilk 24 saat (RDC özeti: duraklatma 24-48 saati yeniden başlatır); kullanılmayan kredi kampanya bitince iade; sahte trafik iadesi bitişten 16 gün sonra.
- Reklam trafiği RFY sıralama sinyaline sayılmaz (02, discovery FAQ) [D]. Bazı geliştiriciler reklamdan sonra Home performansının düştüğünü bildiriyor; Roblox yanıt vermedi [K]. Açıklama: RFY'de görmüş oyuncu "Continue"ya geçer (02) [D].
- Artımlılık (incrementality): 21 Plays kampanyasında medyan +%14 oyun oturumu, +%10 D7 tutulan kullanıcı [D] (büyük oyun örneği, küçük oyuna genellenemez [T]).

### 3.2 Küçük geliştirici maliyet raporları
- Engagement: ~1 USD / 1.000 gösterim, ~20 HEP [K]; 36 kredi ile 250 HEP [K]; 10 kredi / 2 gün: 13 bin gösterim, CTR %2,36, ~200 oyun (02) [K].
- Plays CPP kıyası ~0,0073-0,008 USD/oyun (Roblox, 2025, büyük örneklem; 02) [D]. Kendi kampanyamız (Engagement, 4,74 kredi, 38 tıklama) karar vermeye yetmez (02).

### 3.3 Karar kuralı (20-100 USD için) [T]
- 20 USD: Kasım'da eşik 100 olduktan sonra TEK Engagement testi, geniş hedefleme (yaş/tür/cinsiyet yok), 5 gün, günlük sabit; durdurma kuralı: 3. günün sonunda Audience Reach'te HEP artışı <= 5 ise dur. Ölçü: kredi başına HEP.
- 50-100 USD: sadece 20 USD testinde kredi başına >= 2-3 HEP görülürse ve reklam kohortunda D1 >= %15 ise (Analytics > Retention > Source). Aksi halde para onboarding/içerik sorunudur.
- Plays hedefi 16+ oyunda HEP için verimsiz olabilir (yaş uyumsuz gösterim riski + HEP harcama şartı) [T]; Kids/Select açıldıktan SONRA Plays mantıklıdır.
- Hiçbir harcama sahibinin açık onayı olmadan yapılmaz; "auto-reload" Engagement'ta hedefe gelince durmadığı için dikkatle kullanılmalı [D].

---

## 4. Ücretsiz programlar

| Program | Durum | Bizim için | Etiket |
|---|---|---|---|
| Standout Games başvurusu | Açık, anket | 30 dk, düşük olasılık | [D] |
| Off-Platform Featuring | Açık, >= 7 gün önce | Bir sonraki etkinlik (Aralık/Kış) için; DAU şartı fiilen eler | [D]/[T] |
| Roblox Inspire Challenge (72 saatlik jam) | 31 Tem - 3 Ağu 2026, BİTTİ; program sayfası açık | Sonraki tura göz kulak | [D] |
| Jumpstart / Incubator | Mart 2026 duyurusu (02); sürekli başvuru | Düşük olasılık | [D] |
| Accelerator | 2026 için açık çağrı bulunamadı | - | [T] |
| Today's Picks | Sadece Marketplace (avatar eşyası) | Uygulanamaz | [D] |
| Talent Hub | İşe alım/iş ilanı alanı; keşif programı değil | Keşif etkisi yok | [T] |
| DevForum "Creations Feedback / Cool Creations" | Geri bildirim/vitrin kategorisi; yazma için forum güven seviyesi gerekebilir | Geri bildirim aracı, HEP getirmez | [T] |
| Creator Rewards | Otomatik | Ek iş yok | [D] |

---

## 5. Topluluk (Communities), sosyal linkler, dış link kuralları

- **Community Announcements** (Mayıs-Ağu 2026): duyuru yayınlarken "tüm üyelere bildirim gönder" seçilebilir, üyeler otomatik abonedir (çıkabilir), **7 günde bir yayın bildirimi**; anketler (polls), zengin metin forum, rol-kısıtlı forum (16+ yaş-kontrollü), Community Analytics (ziyaret, üye, katılma, churn) ve duyuru analitiği (erişim, bildirim CTR) [D]. Küçük oyun için: oyuna bağlı bir Community, haftalık "geri gel" kanalıdır; ama üye sayısı 0'dan başlar [T].
- Topluluk sahipliği 17 Haziran 2026'dan beri topluluk seviyesinde (255 rütbesi yeni topluluklarda yok) [D]. Roller/izinler Community ve Creator Hub grupları arasında birleşti (5 Ekim) [D].
- Grup sayfasında Events sekmesi; adminler etkinliği About'ta öne çıkarabilir [D].
- Group Reward kodu oyunda hazır (Config.Group Id = 0, pasif). Topluluk açılınca Id girilir; "gruba katıl = ödül" forumda kabul görüyor ama resmi onay yok (02) [K].
- **Sosyal linkler**: oyun sayfasında en çok 3; yalnız yaş-kontrollü kullanıcılar görür; oyun İÇİNDE sosyal link paylaşımı kaldırıldı, `PolicyService:GetExternalLinkReferences` boş liste döndürecek şekilde emekliye ayrılıyor [D] (Age Check Requirement to Chat duyurusu). Oyun içinde Discord/URL yazmak yasak (02) [D].
- Discord: Roblox'un Discord'a özel bir entegrasyon kuralı yok; dış link yalnız sayfa sosyal linkleri ve oyun dışı kanallardır [T]. "Play on the Web" geldiğinde Discord/YouTube linkleri doğrudan tarayıcıda oyun açacak [D].
- Oyuna özel Quick Words (Ekim 2026): 3 kategori x 3-10 hazır sohbet ifadesi, incelemeye tabi [D]. Sohbet sosyal hissi verir ama keşfe doğrudan etkisi yok [T].

---

## 6. Kaçırıyor olabileceğimiz ayarlar (kontrol listesi)

Creator Hub (sahibi yapar):
1. **Audience Reach**: HEP sayısı, durum, gereksinimler (saatlik) [D].
2. **Exclude from recommendations KAPALI** (Audience > Advanced Settings), Public, Playtest/beta modu kapalı [D].
3. **Genre + Subgenre** seçili mi (Simulation / uygun alt tür) [D].
4. **Açıklamanın ilk cümlesi** oyunu özetliyor ve "simulator, squat, leg day, gym, pets, rebirth" gibi anahtar sözcükleri tekrarsız içeriyor mu [D].
5. **Otomatik çeviri: isim ve açıklama** (Localization > Settings > "Use Translated Content" + Languages'da diller; Türkçe dahil 18 dil; kota karakter x dil) [D]. Oyun içi metin için Automatic Text Capture ayrı ayardır [D]. Koddaki arayüz metinleri AutoLocalize'a bağlı (varsayılan açık) ama `LocalizationService` kullanımı yok [T: kodda grep].
6. **Maturity**: tek soru ("yaş-kısıtlı içerik yok") = Content May Vary = 16+; Kids/Select hedefi için TAM anket şart [D]. Oyunda şiddet yok; dürüst tam anket muhtemelen Minimal/Mild verir [T]. Ücretli rastgele ürün (yumurta) anket sorusu olarak dürüstçe işaretlenmeli [T].
7. **Kids/Select ön şartları**: 2FA, yaş/ID doğrulama, 2 ay Plus/Premium ya da 1.000 Robux iade edilebilir ücret [D]. Ücret ödemek erişim vermez ama eşik dolunca bekleme olmaz [D].
8. **Experience Event**: kendi ayrı küçük resmiyle (oyun küçük resmi değil) [D]; Spooky etkinliği zaten kayıtlı.
9. **Notification string'leri** (Creator Dashboard'da) 100 ziyaretten sonra oluşturulmalı [D].
10. **Sosyal linkler** (en çok 3) + oyuna bağlı Community [D].
11. **Erken test kullanıcıları** (10 kişi, Playtest sekmesi) yeni güncellemeleri yayından önce denetmek için [D].
12. Sunucu boyutu / özel sunucu fiyatı / ses sohbeti: keşif sinyali olarak resmi bir etkisi belgelenmedi [T]. Özel sunucu (ücretsiz ya da düşük) "intentional co-play" sinyalini besleyebilir (özel sunucu, co-play tanımında geçiyor; 02) [D]/[T]. Oyun tek kişilik duvarlıdır, büyük sunucu boyutu gerekmez [T].
13. Desteklenen cihazlar: telefon/tablet/PC/konsol açık mı; mobil kitle en büyük kitle [T].

Oyun içi (Claude kodda yapabilir, sahibinin onayıyla):
- Moments için CaptureService klip istemi (rebirth/evrim anı) - kodda YOK.
- Gerçek bildirim gönderme (OpenCloud createUserNotification: çark hazır, Power Hour başladı) - kodda YOK; 100 ziyaret sonrası.
- Event katılımı ölçümü: GameJoinContext'te etkinlik kimliği [D] - basit analitik olayı.

---

## Öncelikli 12 aksiyon

| # | Aksiyon | Kim | Efor | Beklenen etki |
|---|---|---|---|---|
| 1 | Audience Reach ekran görüntüsü: HEP sayısı, eksik gereksinimler; Exclude from recommendations KAPALI, Public, Genre/Subgenre dolu doğrula | Sahibi (Creator Hub) | 10 dk | Yüksek (gizli bir kapı kapalıysa her şey boşa) |
| 2 | Kids/Select ön şartlarını şimdiden bitir: 2FA, ID/yaş doğrulama, TAM olgunluk anketi (dürüst) ; ücret/Plus kararını sahibi verir | Sahibi | 30 dk (+ 1.000 Robux iade edilebilir, ONAY) | Yüksek: Kasım'da 100 HEP'e ulaşınca bekleme olmaz |
| 3 | Otomatik çeviri: isim + açıklama için "Use Translated Content" ve dilleri aç; Automatic Text Capture'ı aç | Sahibi | 15 dk | Orta: TR/ES/PT/ID kullanıcılarının arama ve PTR'si |
| 4 | Açıklamanın ilk cümlesini anahtar sözcüklerle yeniden yaz (tekrarsız) | Claude metni hazırlar, sahibi yapıştırır | 15 dk | Orta (arama) |
| 5 | Moments: rebirth / "EVOLVED" anında CaptureService ile klip kaydetme istemi | Claude (kod) + sahibi Studio testi; anket güncellemesi gerekebilir | 2-4 sa | Orta, ücretsiz, 16+ kitleyle örtüşen tek kullanıcı-üretimi yüzey [T] |
| 6 | Oyuna bağlı Community aç, Config.Group Id'yi gir (grup ödülü zaten yazılı), sayfaya Community + 2 sosyal link ekle | Sahibi (hesap) + Claude (Id satırı) | 30 dk | Orta: 7 günde bir tüm üyelere bildirim kanalı |
| 7 | Kasım'da eşik 100 olunca TEK Engagement testi: ~20 USD, geniş hedefleme, 5 gün, 3. gün HEP <= 5 ise dur | Sahibi (ONAY, para) | 20 dk kurulum | Yüksek belirsizlik; kapıyı açabilecek tek hızlı yol |
| 8 | Engagement testinden ÖNCE ilk 3 dakika/funnel kontrolü (Analytics > Funnels: Config.Funnel adımları) ve en büyük kayıp adımı düzelt | Claude (kod) + sahibi (veri okuma) | 2-6 sa | Yüksek: Roblox "3-5 günde ilerleme yoksa onboarding'i düzelt" diyor [D] |
| 9 | 100 ziyareti geçince notification string'leri oluştur; Claude OpenCloud ile 1-2 kişisel bildirim (çark hazır, Power Hour) ekler | Sahibi (string) + Claude (kod) | 3-5 sa | Orta: D2-7/D8-28 geri dönüşü (RFY sinyali) |
| 10 | Her güncellemede Events & Updates'te somut 60 karakterlik duyuru (3 günde bir sınırı), etkinliğe ayrı küçük resim | Claude metni yazar, sahibi yayınlar | 10 dk/güncelleme | Düşük-orta (takipçi az) |
| 11 | Erken test kullanıcılarını (10 kişi) kullanarak her güncellemeyi yayından önce denet; kırık ilk deneyim first-play bounce'u artırır | Sahibi | 15 dk | Düşük-orta (kalite koruması) |
| 12 | Late 2026 özelliklerine hazırlık notu: free pass trials (Auto Click pass), Home'da pass/ürün vitrini (Starter Pack görseli), Play on the Web (dış linkler); çıktıklarında açılacak ayar listesi | Claude (plan + kod hazırlığı) | 1 sa | İleride orta |

Yapılmaması gerekenler 02 bölüm 4.7'de; burada değişen yok.

---

## Kaynaklar

Resmi [D]:
- https://devforum.roblox.com/t/rdc26-what-we-announced/4865880 (HEP 100 Kasım, erken test, tek soru, push bildirim, Play on the Web, %28/%33 yeni oyun)
- https://devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208
- https://devforum.roblox.com/t/highly-engaged-player-threshold-drops-to-250/4820164 (yanıtlar: sayfa 7)
- https://create.roblox.com/docs/production/publishing/kids-and-select
- https://create.roblox.com/docs/production/publishing/publish-experiences-and-places
- https://devforum.roblox.com/t/weekly-recap-october-12-18-2026/4938638
- https://devforum.roblox.com/t/weekly-recap-october-5-october-9-2026/4924062
- https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122
- https://devforum.roblox.com/t/create-your-game-specific-quick-words/4932108
- https://devforum.roblox.com/t/ads-manager-rdc-recap-earnings-roas-reporting-incrementality/4909790
- https://create.roblox.com/docs/production/promotion/ads-manager
- https://create.roblox.com/docs/creator-rewards
- https://create.roblox.com/docs/production/promotion/experience-events
- https://create.roblox.com/docs/production/promotion/experience-notifications
- https://create.roblox.com/docs/production/localization/automatic-translations
- https://create.roblox.com/docs/creator-programs/todays-picks-marketplace
- https://create.roblox.com/docs/creator-programs/inspire
- https://devforum.roblox.com/t/roblox-inspire-2026-challenge/4751288
- https://devforum.roblox.com/t/new-tools-to-engage-your-communities-on-roblox-polls-analytics-support-tickets-and-more/4657552
- https://devforum.roblox.com/t/community-ownership-is-now-managed-at-the-community-level/4687884
- https://devforum.roblox.com/t/age-check-requirement-to-chat-now-live-globally/4226101
- https://about.roblox.com/newsroom/2026/09/rdc-2026-the-world-needs-more-play
- https://ir.roblox.com/news/news-details/2026/Roblox-Unveils-New-Ways-to-Play-Build-and-Grow-at-the-Roblox-Developers-Conference-RDC/default.aspx

Topluluk [K]:
- https://x.com/script_ing/status/2090174015512150070 (36 kredi / 3 gün / 250 HEP iddiası)
- https://devforum.roblox.com/t/highly-engaged-player-threshold-drops-to-250/4820164?page=7
- https://devforum.roblox.com/t/events-section-missing-on-experience-page-in-web-browsers-shows-in-the-roblox-app/4924180

Üçüncü taraf [T]:
- https://gamineai.com/blog/stop-treating-roblox-early-tester-invites-as-your-public-launch-2026
- https://www.gamebusiness.jp/article/2026/10/13/28297.html
- https://bloxnetwork.org/news/article/roblox-lowers-highly-engaged-player-requirement-to-250
