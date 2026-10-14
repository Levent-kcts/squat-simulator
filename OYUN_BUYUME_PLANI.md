# +1 Squat Evolution: BÜYÜME PLANI (2026-10-14)

Sahibi 14 Ekim 2026'da 'araştır, planla, tam yetkiyle uygula, oyunu popüler yap' dedi (14 günde ~16 oyuncu, yatırılan para ve reklam sonuç vermedi).
Bu belge kalıcı iş planıdır: 5 araştırma raporunu (`research/01..05_*.md`) ve tasarım incelemesini (`OYUN_TASARIM_ANALIZI.md`) birleştirir.
SAHİBİNİN yapacakları: `SAHIBI_YAPACAK_LISTE.md`. Her sprintin durumu en altta.

## 0. Dürüst çerçeve (ajanlar, sayılar)

- Popülerlik garantisi yok. Patlayan oyunların çoğu (Escape Tsunami, Speed Keyboard, Grow a Garden 2) zirveden %90+ düştü; kalıcı olanlar haftalık içerik verenler (research/01).
- **Asıl darboğaz özellik değil, dağıtım ve 16+ kapısı** (üç ajan birbirinden bağımsız aynı sonuca vardı). Yeni oyun önce sadece yaş-doğrulamalı 16+ oyuncuya açılır; Kids/Select için 60 günde 250 "highly engaged" oyuncu gerekir (hesap yaşı + oyunda süre + son 60 günde Roblox'ta herhangi bir harcama). Oyunumuz tam adıyla aramada bile çıkmıyor (14 Ekim'de denendi).
- Roblox önerisi (Recommended For You) küçük oyunu cezalandırmaz; ortalama sinyallere bakar: oynama oranı, **ilk 60/180 saniyede çıkış**, **D1 / D2-7 / D8-28 geri dönüş**, süre (günde en çok 60 dk), ikinci kademe: arkadaşla birlikte oynama, harcama. Reklam, arama ve link trafiği bu sinyallere sayılmaz.
- Reklam bu aşamada israf: reklamla gelenin "highly engaged" sayılma oranı forumlarda çok düşük (6.000 ziyaretten 5, 10.000'den 15 gibi). Karar: **yeni reklam yok**.
- Kitle: yaş-doğrulamalı, Roblox'ta para harcayan, 16+. Bu kitle derin ilerleme, koleksiyon, statü, klip paylaşımı sever; 13 altı çocuk oyuna giremez (pazarlama buna göre: gym/leg-day mizahı, genç yetişkin).
- Rakip tür (+1 ... Evolution, +1 ... for Eggs) çok sıcak: +1 Stone Skipping bir ayda 160 bin zirve, +1 Karate Evolution [W3] 17 bin, doğrudan rakip +1 Muscle to Break Walls 3,2 bin (pass'leri çok ucuz: Auto Click 37, Auto Rebirth 19, x2 Wins 79 R$). Rakiplerin ortak katmanı: **dünya numarası + etkinlik etiketi başlıkta, her hafta güncelleme, yumurta/pet, pasif/çevrimdışı gelir, rozet/unvan/başlangıç paketi**.

## 1. Strateji (üç katman)

1. **Kapıyı aç (sahibi, bedava):** Audience Reach denetimi, video, küçük resimler, Share Link, açıklama (SAHIBI_YAPACAK_LISTE.md).
2. **Gelen az sayıda 16+ oyuncuyu tut (ben, kod):** ilk dakika, geri dönüş sebepleri, yaşayan dünya hissi (küçük nüfusta çapraz sunucu duyuruları), statü ve klip anları, etkinlik ve dünya içeriği. Ölçüt: D1, ilk dakika çıkışı, "highly engaged" sayacı.
3. **Dışarıdan doğru kitleyi getir (sahibi + ben, içerik):** 14 günlük sıfır bütçeli video takvimi, mikro yaratıcılar, hazır görsel/prompt paketi (research/05). Her dış kanalın ayrı Share Link'i.

Kural: küçük n'de (16 oyuncu) D1 gibi oranlara bakarak karar verme (±7 puan belirsizlik); davranışı izle, oyuncu görüşmesi ve kayıt daha değerli.

## 2. Sprint planı (cumartesi yayın günü: 17, 24, 31 Ekim; 7, 14, 21, 28 Kasım; 5 Aralık)

### Sprint 1 (yayın: Cmt 17 Ekim): "yaşayan dünya + geri dönüş + uyumluluk"
| # | İş | Neden | Zor. |
|---|---|---|---|
| 1.1 | **Çapraz sunucu duyuru akışı** (Legendary/Mythic yumurta, rebirth eşikleri, aşama bitirme): sunucular arası MessagingService | Küçük nüfusta oyunun "dolu" görünmesi + sosyal kanıt + klip yemi (research/01-04) | S |
| 1.2 | **Friend Referral ödülü** (`GetJoinData().ReferredByPlayerId`): davetli >= 10 dk oynayınca iki tarafa Robux'suz ödül, tek seferlik, davetçi sınırı 3 | Resmi davet sistemi; birlikte oynama RFY sinyali (research/02, 04) | S-M |
| 1.3 | **Kısıtlı hesaplar için "Training Egg" yolu**: sabit sıralı, önceden gösterilen sonuç | UK/AU/NL/BE/BR gibi hesaplarda yumurta tamamen kapalı: 16+ havuzunun bir kısmı için ana döngü ölü (research/04) | M |
| 1.4 | **Ölçüm olayları**: Win kaynak/gider (`LogEconomyEvent`), özel olaylar (arkadaşla katıldı, Mythic hatch) | Hangi adımda oyuncu düşüyor; ekonomi sağlığı | S |
| 1.5 | **What's New kartı + güncelleme günlüğü**: sürüm başına bir kez, küçük, kapatılabilir | Haftalık ritim algısı, geri dönenlere yenilik (research/04) | S |
| 1.6 | **Harita ve ışık geçişi**: bölge duvar renkleri, sıcak ışık, vinyet, merkez halka (OYUN_TASARIM_ANALIZI.md 3.2; önizleme `assets/preview/`) | İlk izlenim, kapak sanatıyla tutarlılık, daha iyi ekran görüntüsü/klip | S |

### Sprint 2 (yayın: Cmt 24 Ekim): "Halloween Lite + evrim anları"
| # | İş | Neden | Zor. |
|---|---|---|---|
| 2.1 | **Spooky Gym (24 Ekim-8 Kasım)**: duvar kırınca kazanılan **Candy** (satılmaz), 5 ürünlük deterministik mağaza (iz, aura, skin, unvan, rozet), Candy panosu, ortak hedef, lobi süsü | PS99/GAG etkinlik şablonu; neredeyse tüm üst oyunlar Halloween yapıyor (research/01, 04) | M |
| 2.2 | **Evrim anı ("Form-Up")**: yeni kas aşamasında sade ama sinematik kısa an (ekranı kapatmayan), klip dostu | Oyunun ayırt edici görseli, kısa video kancası (research/03, 05) | M |
| 2.3 | **Power Hour**: her 30 dk'da 5 dk, sunucu çapında x2 kas, küçük üst sayaç (UTC saatine bağlı, tüm sunucular senkron) | Küçük nüfusta anlık canlılık, "şimdi oyna" sebebi | S |
| 2.4 | **Experience Event kaydı** (sahibi) + etkinlik duyuru metni (60 karakter) | Ücretsiz keşif yüzeyi | S |

### Sprint 3 (yayın: Cmt 31 Ekim / 7 Kasım): "derinlik ve geri çağırma"
| # | İş | Zor. |
|---|---|---|
| 3.1 | **Mastery ağacı** (Win ile kalıcı deterministik yükseltmeler): geç oyunda Win'e anlam, +6-10 saat | M-L |
| 3.2 | **Hall of Fame + haftalık pano** | S-M |
| 3.3 | **Bildirim izni** (`ExperienceNotificationService`): ilk rebirth'ten sonra bir kez, tek kişisel bildirim ("çarkın hazır") | S-M |
| 3.4 | **Capture/Moments istemi** (Mythic hatch, rebirth, yeni vücut aşaması; API adları doğrulanır, anket güncellemesi sahibine) | S-M |

### Sprint 4 (Kasım): "Dünya 2 alfa" (Worlds kemeri açılır; başlıkta [W2])
Aynı çerçeve, yeni 20 tema, yeni yumurtalar, yeni ayakkabı/koç kademeleri, rebirth ile açılan kapı. En büyük iş; denge `tools/simulate.py` ile. Ayrıntı sprint 3 sonunda.

### Robux kalemleri (sahibi ürünü açınca aktif olur, kod pasif hazır): başlangıç paketi 49 R$, etkinlik paketi 99 R$, Event Booster 39 R$, özel sunucu 99 R$, (isteğe bağlı) abonelik. 150 R$ kuralı korunur. Ürün listesi ve metinler research/04 bölüm 7.

## 3. Bilinçli olarak YAPILMAYANLAR
Başkasından çalma/PvP baskını, ticaret, beğeni/favori karşılığı ödül, ücretli rastgele yeni ürün (mutasyon), sahte kıtlık ve "BUY NOW" dili, video akışı + izleme ödülü, bot, reklam harcaması. SAHİBİNİN reddettikleri tekrar önerilmez: günlük giriş ödülü, promosyon kodları, lobi görev panosu, bloom/göz alan ışık, üst ilerleme çubuğu, ışınlanma butonları.

## 4. Başarı ölçütleri (14 Ekim'den 14 gün sonra bak)
- Audience Reach'te "highly engaged" sayacı ve hızı. - Analytics > Acquisition: kaynak başına oyuncu ve D1/D7 (Share Link'ler). - Home Recommendations: ilk 60/180 sn çıkışı, play days. - Funnel (Config.Funnel) en büyük düşüş adımı. - Çapraz sunucu akışını gören oyuncuların yumurta açma oranı (önce/sonra).

## 5. Durum
(her sprint bitince güncellenir)
- 2026-10-14: araştırma tamam (5 rapor), plan yazıldı, sahibi listesi verildi. Sprint 1 başladı.
- 2026-10-14: **1.1 çapraz sunucu duyuru akışı YAPILDI** (GlobalFeed + FeedHud, testli).
- 2026-10-14: **1.2 Friend Referral ödülü kodlandı** (server/Referrals, PlayerStats.onLoaded kancası, Config.Referral); referraltest.luau ile testli.
- 2026-10-14: sahibi Audience Reach'i paylaştı: kimlik, 2FA, anket, ücret TAMAM; eksik olan tek şey 250 highly engaged (şu an 1). Sahibi kod/günlük ödülü onayladı ve fiyat indirimi + 'hepsini ekle' dedi.
- 2026-10-14: **fiyat indirimi YAPILDI** (ROBUX_FIYAT_DEGISIKLIGI.md), **promosyon kodları YAPILDI** (Config.Codes, Settings > Redeem code, codestest).
- 2026-10-14: **günlük giriş ödülü YAPILDI** (sol menü Daily düğmesi, 7 gün, nazik seri, logintest + loginpaneltest).
- 2026-10-14: **Başlangıç Paketi kodlandı** (49 R$ tek seferlik; ürün ID'si sahibinde bekliyor).
- 2026-10-14: **rozetler (9, pasif: id bekliyor) ve rütbe unvanları YAPILDI** (badgetest).
- 2026-10-14: **1.3 kısıtlı hesaplar için sabit sıralı Eğitim Yumurtası YAPILDI** (trainingeggtest).
- 2026-10-14: **2.3 Power Hour YAPILDI** (her 30 dk'da 5 dk x2 kas, UTC senkron, üst sayaç; powerhourtest, powerhourhudtest).
