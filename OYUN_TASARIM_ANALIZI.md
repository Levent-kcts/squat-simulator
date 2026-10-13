# +1 Squat Evolution: Smash Walls: tasarım analizi (oyun teorisi ve davranış tasarımı)

Tarih: 2026-10-13. Kaynak: oyunun mevcut hâli (Config.luau, simulate.py), playtest geri bildirimi, sıralama panosundaki gerçek oyuncu verisi (çoğu oyuncu 100-1.600 kasta bırakmış).
Bu belge bir YOL HARİTASIDIR: neyin neden işlemediğini ve sırayla neyi yapmak gerektiğini söyler. Rakamlar `tools/simulate.py` ve elle hesaptandır; kesin doğruluk için Analytics > Funnels (aşağıda) ile doğrulanmalı.

## 1. Özet

**Güçlü yanlar:** net çekirdek fikir (squat yap, güçlen, duvar kır), her şey görsel ve tatmin edici (duvar kırılması, boyut büyümesi), katmanlı koleksiyon (pet, ayakkabı, skin, iz, aura, index), kısa+uzun hedef karışımı (görevler, hediyeler, çark, rebirth), çocuklara uygun (kan/şiddet yok, kısıtlı hesap kontrolü).

**En büyük sorun:** oyun ilk 2-3 dakikada hızlı, sonra bir "sessiz bölgeye" giriyor ve oyuncuyu elinde tutacak ödül anı yok. Elle tıklayan oyuncu 2,5. dakikada 1.000 kasa (level 18/25) ulaşıyor; sonraki level başına 500-1.200 kas gerekiyor ve ilk rebirth ~10. dakikada. Bu arada ilk pet bile ~6. dakikaya kalıyordu. Oyuncular tam burada bırakıyor.

**(2026-10-13 sonrası: oyun kısaltıldı, ilk rebirth çok hızlı; yeni oyuncu görevleri ve rehber turu eklendi, bkz. CLAUDE.md.)**

**Bu turda yapılanlar (retention):** başlangıç Win'i ('Squat 30 times' görevinin ödülü, Quests'ten CLAIM; ilk pet 1. dakikada), 10 dakika ücretsiz Auto Click, level 6/12/18/22/25 ödülleri, ilk rebirth'e kadar hedef şeridi + rehber çizgisi, daha gösterişli yumurta açılışı, ilk oyun hunisi analitiği.

## 2. Oyun teorisi gözüyle: oyun "çözülmüş" bir oyun

Oyunda neredeyse hiç **anlamlı karar** yok. Her seçimde baskın strateji (dominant strategy) belli:

| Karar | En iyi seçim | Sonuç |
|---|---|---|
| Hangi ayakkabı? | Hep en pahalısı (damage hep artıyor) | Karar yok, sadece bekleme |
| Hangi skin? | Hep en pahalısı (bonus hep artıyor) | Aynı |
| Hangi antrenman pedi? | Açık olan en yüksek çarpan | Aynı |
| Hangi pet takılı? | "Equip Best" | Aynı (bu düğme var bile) |
| Ne zaman rebirth? | Level sınırına gelince hemen | Aynı |

Karar yokluğu şu anlama gelir: oyuncu zihinsel olarak "oynamıyor", sadece zaman geçiriyor. Bu çocuk oyuncu için sorun değil ama 2-3 saat sonra sıkılma sebebi. **Önerilen çare (orta vadede):** gerçek takaslar (trade-off) eklemek:
- Pet türleri farklı bonus versin (biri kas, biri Win, biri yumurta şansı); takım seçimi anlamlı olsun. Mevcut `Config.Pets` hepsi sadece kas çarpanı.
- Rebirth'te küçük bir **yetenek puanı** seç (ör. "tıklama +%10" ya da "Win +%10" ya da "yumurta şansı"). Her rebirth farklı kombinasyon.
- Ayakkabılara özel etki (kıvılcım, çift vuruş şansı) ve düşük ihtimalli "kritik vuruş" (aktif oyuna beceri ekler).

## 3. Davranış tasarımı kavramları ve oyundaki karşılığı

| Kavram | Oyundaki durum | Eylem |
|---|---|---|
| **Endowed progress (başlangıç avantajı)**: yarı dolu ilerleme, sıfırdan başlamaktan çok daha motive eder | Eskiden 0 Win, 0 pet ile başlıyordu | YAPILDI: 8 Win + ilk pet + ilk skin hemen |
| **Goal-gradient (hedefe yaklaştıkça hızlanma)** | Level çubuğu var ama hedef (rebirth) görünür değildi | YAPILDI: üst şerit "Goal: reach level 25 to REBIRTH! (N/25)" |
| **Variable ratio ödül** (slot makinesi etkisi, yumurta açma) | Pet şansları 50/30/13/5/2: iyi ama açılış sönüktü | YAPILDI: açılışta parıltı, dönen kartlar, nadirlik başlığı. Sıradaki: nadir pet = daha havalı model (Blender) |
| **Kayıptan kaçınma (loss aversion)** | Rebirth ayakkabı, skin, Win'leri sıfırlıyordu ve kırmızı uyarı yazıyordu: ilk rebirth ceza gibiydi | ÇÖZÜLDÜ (2026-10-13): rebirth sadece level ve kası sıfırlar, ekran 'ne kalır' diye anlatır; bkz. 4.2 |
| **Zeigarnik etkisi (yarım kalan iş akılda kalır)** | Görevler, hediye sayacı, Pet Index 3/30 var | İyi. Index tamamlama ödülü ekle (karar bekliyor) |
| **Randevu mekaniği (appointment)** | Free Reward sayacı (40 dk tur), günlük çark | İyi; süreler uzun, kısaltma önerisi (karar bekliyor) |
| **Sosyal kanıt / statü** | Sıralama panosu sadece ilk 10; gerçek oyuncu çoğu orada yok | Arkadaş sıralaması ve "senin sıran" göster |
| **Çapalama (anchoring)** | Win Pack 59 R$, Mega 149 R$; Power düğmeleri 25/75/149 | İyi; "en popüler" etiketi ekle |
| **Sahiplik etkisi (endowment)** | Auto Click doğrudan satılıyordu | YAPILDI: 10 dk ücretsiz deneme: sahiplik hissi dönüşümü artırır |
| **Akış (flow): zorluk ve beceri dengesi** | İlk 2,5 dk fazla kolay, sonra fazla yavaş | Bkz. 4.1 |

## 4. Geliştirilmesi gereken yerler (öncelik sırasıyla)

### 4.1 Orta oyun sessizliği (en yüksek etki)
Level maliyeti kuvvet yasasıyla büyüyor (2026-10-13'te tam sayı çarpanlara geçince ^4,9 → ^8 oldu: level 20 → ~4,7K, level 24 → ~22K kas; level çarpanı da level'a eşit olduğu için kazanç aynı oranda arttı). Yine de level başına süre dakikalarla ölçülüyor ve ekranda değişen tek şey bir sayı.
- YAPILDI: level 6/12/18/22/25 ödülleri (Win, iksir, pet).
- Sıradaki: **aralık ödülleri**: her 100/250/500 duvar hasarı gibi. Ya da "Golden Brick": duvarın üstünde ara sıra beliren altın tuğla, tıklayana bonus (aktif oyunu ödüllendirir).
- Maliyet eğrisini yumuşatmak (CostPower 4,9 → ~4,3): ilk 20 level çok hızlı, sonrası daha az sert. Önce `tools/simulate.py` ile tempo ölç; rebirth süreleri kayacağı için denge dosyalarını (CLAUDE.md "DENGE HEDEFİ") birlikte güncelle.

### 4.2 Rebirth: ilk rebirth ödül değil ceza gibi hissettirebilirdi (ÇÖZÜLDÜ: 2026-10-13)
**Sahibinin kararı:** rebirth artık SADECE level ve bacak kasını sıfırlar; Win, ayakkabı, skin, pet, iz ve aura kalır. Tempo `tools/simulate.py` ile ölçüldü: oyunun sonu ve rebirth süreleri %1-2 değişti (denge bozulmadı). Rebirth ekranındaki kırmızı uyarı 'You KEEP Wins, shoes, skins & pets!' diye değişti. Aşağıdaki eski çözüm önerileri artık gereksiz; tarihî not olarak duruyor.

Rebirth bacak kası, Win, ayakkabı VE skinleri sıfırlıyor. İlk rebirth ~5-10. dakikada: oyuncu yeni aldığı skin ve ayakkabıyı kaybediyor. Kayıptan kaçınma yüzünden "rebirth yapmam, kaybederim" diyip duran oyuncu olur.
- Rebirth ekranı "ne kaybedersin" yerine **"ne kazanırsın ve ne kalır"** diye çerçevelensin: kalıcı çarpan, yeni ped, daha yüksek level sınırı; petler, iz, aura korunur.
- İlk rebirth için **başlangıç paketi**: Win ve ayakkabılar sıfırlansa da ilk 5 dakikada hızla geri alınabilir (ucuz ilk ayakkabılar zaten var); ilk rebirth'te kısa bir "2x Win" iksiri hediye.
- Skinleri rebirth'te KORUMAK (sadece görsel + küçük sabit bonus) düşünülebilir (sahibinin kararı: önceki kural "skinler de sıfırlanır").

### 4.3 Aktif oyun mu, boşta oyun mu?
Auto Click ile oyun tamamen "idle". Elle oynayanın yapacağı tek şey tık. Başarılı simülatörler ikisini dengeler:
- Aktif oyuncuya ödül: kritik vuruş, kombo çarpanı (ardışık tık hızına göre), Golden Brick.
- Boşta oyuncuya ödül: çevrimdışı kazanç (VAR), antrenman pedleri (VAR).
Şu an sadece iki uç var, aradaki "beceri" yok.

### 4.4 Sosyal döngü zayıf
- Duvarlar oyuncuya özel, yani başkasıyla etkileşim neredeyse yok. Arkadaş bonusu (+%10/arkadaş) güzel, ama oyuncu arkadaşını nasıl getirecek? Davet ödülü ("arkadaş davet et, ikiniz de X Win") ekle.
- Sıralama panosu sadece zirve. Oyuncu kendini zirvede göremiyorsa motivasyon düşer: "arkadaşların arasında kaçıncısın" göster (karar bekliyor: günlük/haftalık/aylık sıralama).
- Ortak etkinlik: haftalık "boss duvarı" (tüm sunucu ortak hasar verir, ortak ödül). Çocuklara uygun, rekabetçi değil işbirlikçi.

### 4.5 İçerik tavanı ve güncelleme ritmi
Oyunun sonu 20. aşama ≈ 10-14 saat. "WORLDS COMING SOON" bir söz; ilk haftada yeni içerik gelmezse oyuncu geri dönme sebebi bulamaz.
- Haftalık küçük güncelleme ritmi (yeni pet, ayakkabı, kod). Roblox öneri algoritması güncel oyunları öne çıkarır.
- Kısa vadede **promosyon kodları** (Discord/sosyal medya duyurusu) ve **rozetler** ekle.

### 4.6 Ödül ve değer algısı
- Yumurta: nadir pet daha havalı/tatlı görünmeli (Blender ile model detayı, efekt, boy); şu an "nadir = sadece daha yüksek çarpan".
- İz görünümleri oyunla ilgisiz (E4 geri bildirimi): kas/tuğla/protein temalı iz (tuğla tozu, terleme damlası) ekle.
- Pet çarpanı + fusion ile güç çok hızlı büyür; Boss pet'e ulaşmak oyuncuya "başardım" hissi versin (özel animasyon, ses).

### 4.7 Para kazanma (monetizasyon) ve etik
- Çocuk kitlesi: baskı yaratan geri sayım, "son şans" metni, sürekli satın alma çağrısı YAPMA. Oyuncuya "alırsam şunu kazanırım" göster, "almazsan kaybedersin" demeyin.
- Ücretli rastgele ürünler (yumurta, Luck iksiri): şanslar görünür ve kısıtlı hesapta kapalı (YAPILDI). Pity sistemi / ücretli spin eklemeden önce Roblox'un "paid random items" kuralını yeniden oku (CLAUDE.md).
- Fiyat kademesi: 25/75/149 R$ Power düğmeleri ve 59/149 Win paketleri tutarlı; "Best value" etiketi eklenebilir.
- Auto Click 149 R$ (150 sınırında). Ücretsiz deneme sonrası dönüşüm oranını ölç; gerekirse fiyatı/yarım-gün denemesini ayarla.

### 4.8 Keşfedilebilirlik (büyüme)
Oyuncu gelmezse hiçbir tasarım işe yaramaz. İlk haftada: sosyal medya kısa videoları, Discord, **Engagement** reklam kampanyası (yaş doğrulamalı oyuncular Kids onay sayacına girer). Ayrıntı: README "YAYIN DURUMU".

## 5. Ölçüm planı (Analytics)

İlk oyun hunisi artık Roblox'a gönderiliyor (`Config.Funnel`, her adım oyuncu başına bir kez):

1. Joined (oyuna girdi)
2. Clicked30 (eğitim: 30 tık)
3. FirstWall (ilk duvarı kırdı)
4. FirstPet (ilk pet)
5. FirstSkin (ilk skin)
6. Level12 (level 12'ye ulaştı; ~1-2 dk)
7. FirstRebirth (ilk rebirth)

Creator Hub > Analytics > **Funnels** (ya da "Onboarding") sayfasında her adımdaki kaybı görürsün. Yorum:
- 1 → 2 arasında büyük kayıp: oyun açılışı/yükleme/kontrol sorunu.
- 2 → 3: duvara yönlendirme yetersiz.
- 3 → 4: ilk pet yönlendirmesi çalışmıyor (rehber çizgisi, yumurta paneli).
- 6 → 7: orta oyun sessizliği (4.1) ve rebirth korkusu (4.2).
Ayrıca **D1 retention** (ertesi gün dönüş) ve **ortalama oturum süresi**. İlk 100 oyuncudan sonra sayıları karşılaştır: hedefler (tahmin, ölçümle doğrula): ilk oturum >= 10 dk, D1 >= %20-25.

## 6. Önerilen sıra (bu hafta)

| # | İş | Etki | Çaba |
|---|---|---|---|
| 1 | Bu turdaki retention değişikliklerini yayınla, funnel'ı izle | Çok yüksek | Bitti |
| 2 | Promosyon kodları + rozetler | Yüksek (büyüme) | Orta |
| 3 | ~~Rebirth ekranını yeniden çerçevele~~ YAPILDI (sadece level ve kas sıfırlanır) | Yüksek | Bitti |
| 4 | Free Reward sürelerini ~%30 kısalt | Orta | Çok küçük |
| 5 | Golden Brick (aktif oyun ödülü) + kritik vuruş | Orta-yüksek | Orta |
| 6 | Index tamamlama ödülü, davet ödülü | Orta | Küçük |
| 7 | Pet türlerine farklı bonuslar, rebirth yetenek puanı | Yüksek (derinlik) | Büyük |
| 8 | Arkadaş sıralaması, haftalık boss duvarı | Orta (sosyal) | Büyük |
| 9 | İz/pet görsel yenilemesi (Blender) | Orta | Büyük |

Not: 3-7 arası maddeler oyunun yapısını (CLAUDE.md'deki sahibi kararları: rebirth sıfırlaması, pet sistemi) değiştirebildiği için uygulamadan önce sahibine sorulmalı.
