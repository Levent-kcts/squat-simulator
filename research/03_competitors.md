# 03 — Rakip ve İlham Kaynağı Analizi (güç / spor salonu / yumruk / duvar kırma / "+1" tıklama simülatörleri)

Hazırlayan: rakip analisti (salt-okunur araştırma; oyun koduna dokunulmadı). Tarih: 2026-10-14.
Hedef oyun: "+1 Squat Evolution: Smash Walls" (canlı: 2026-10-11, şimdilik 16+ etiketli, ~16 oyuncu).

> Güven etiketleri bu belgede şöyle kullanılır:
> **[K]** = Roblox'un kendi herkese açık uç noktalarından (anlık, doğrudan) alınan veri.
> **[O]** = üçüncü taraf takipçi (RoWatcher vb.) ya da birden çok kaynakla tutarlı bilgi.
> **[D]** = düşük güven: çıkarım, tek kaynak, SEO/"bedava Robux" sitesi ya da oyun açıklamasından yorum.

---

## 0. Yönetici özeti (en önemli 10 çıkarım)

1. **Önce keşfedilebilirlik.** Rakiplerin hepsi (BW, ME, KE, Mog, Stone Skipping...) "Minimal/Mild" (her yaş) etiketli. Bizim "16+" olmamız bir tasarım sorunu değil, Roblox'un **Audience Reach** kuralı: yeni oyun önce "deneme aşamasında" yalnızca yaşı doğrulanmış 16+ kullanıcılara açılır; 9-15 yaş (Select) ve 5-8 (Kids) kitlesine geçmek için hesap şartları + ücret/abonelik + **60 günde 250 benzersiz "yüksek etkileşimli, yaşı doğrulanmış" oyuncu** gerekir (resmi doküman, bkz. §7-0). 16 oyuncu bu yüzden normal; bunu çözmeden mekanik eklemek erken. Ayrıca anonim Roblox arama API'sinde oyunumuzu (tam adıyla ya da "squat", "smash walls" ile) **bulamadım** [K] — 16+ kısıtı ya da indeks gecikmesiyle uyumlu, kesin neden doğrulanmadı.
2. **"+1" türü bir viral-patlama türüdür, ömrü kısadır.** İncelediğim 8 oyunun (çoğu "+1") zirveden bugüne CCU oranı ortalama ~%5-6 (medyan ~%4,5): ME %0,5, Boulder %1,6, AW+1 %3, Long Arm %4, MTS %5, Mog %6, BW %10, Arm %15. Yani 2-5 ayda %85-99 düşüş (anlık CCU gün saatine göre ±%50 oynar). Ömrü uzatan tek şey **yeni dünya/güncelleme ritmi** (KE: açılıştan en fazla ~20 gün sonra başlığında `[W3]` var).
3. **En yakın rakip: "+1 Muscle to Break Walls"** (BW; 89,7 M ziyaret, 69,5K beğeni, %97,2; zirve ~32K Temmuz 2026; şimdi ~3,2K). Çekirdek döngü bizimle aynı ruhta (ağırlık → güç → duvar → Win → aura/ağırlık satın al). Ama **içerik sığ** (yalnızca 5 rozet, aura + ağırlık + "treadmill" cosmetic passes, sosyal yok) — bizim derinliğimiz çok daha fazla. Onların kazandığı şey **ilk dakika hızı**: "Welcome" rozetinin %52'si "First Rebirth" almış [K, rozet sayaçları].
4. **En sıcak formül şu an "+1 güç + yumurta/hazine + çevrimdışı gelir" hibriti**: "+1 Strength for Eggs" (zirve 33K, 12 Eylül'de açıldı), "+1 Lift Rock for Treasure" (20K), "+1 Strength to Grow Your Arm" (24K; duvar + brainrot), "Kick a Lucky Block" (1,9 milyar ziyaret). Bizim petlerimiz yalnızca çarpan; pasif gelir üreten pet katmanı yok.
5. **Dünya numarası pazarlamadır**: başlıklarda `[W3]`, `[W4]`, `[W5]`; ikonda kırmızı şerit "WORLD 3" / "OFFLINE STRENGTH" / "Power Rings". Rakipler yeni içeriği ikon + ad üzerinde ilan ediyor. Bizim "Worlds: coming soon" kemerimiz var ama hiçbir şey yok.
6. **Fiyat noktası: kolaylık passes'leri çok ucuz** (Auto Click 25-49 R$, Auto Rebirth 5-49 R$, x2 Wins 10-149 R$); bizde Auto Click 149, Auto Open 199, Multi Open 249. Rakiplerin neredeyse hepsinde olan **Auto Rebirth, kalıcı x2 Wins, +Pet Equip** bizde yok.
7. **Rozet (badge) kullanmıyoruz** (kodda BadgeService yok); rakiplerde 1-54 rozet var, hepsinde "Welcome" rozeti.
8. **Küçük sunucu** yeni hitlerde standart (5-12 oyuncu; BW 12, KE 8, SE 5). 16 CCU'da büyük sunucu = herkes yalnız. (Place ayarı: Max Players; kontrol et.)
9. **Bizim gerçek farkımız:** görünür "evrim" (6 kas aşaması + boy/genişlik ölçeği), bacak/duvar tekmesi animasyonu + temalı 100 duvar, oyuncu başına duvar, rehber turu + görev zinciri (rakiplerde böyle bir şey kanıtı yok), mobil performans modu, ücretli-rastgele politikasına uyum. Pazarlamada "evrim"i ve "duvar kırmayı" öne çıkar; thumbnail'imiz ("BEGINNER → LEGEND") zaten türün kazanan biçimiyle uyumlu.
10. **Zamanlı fırsat:** Cadılar Bayramı (31 Ekim, 17 gün). ML, GL, GS, birçok "+1" oyunu 🎃 ikon/ad/etkinliğiyle yürüyor. Sahibin onayını bekleyen "Halloween etkinliği" fikri (OYUN_TASARIM_ANALIZI.md) küçük ölçekte hemen yapılabilir.

---

## 1. Yöntem ve veri kalitesi (dürüst notlar)

- **Birincil veri:** Roblox'un kimlik doğrulaması gerektirmeyen herkese açık uç noktaları (hesap açılmadı, giriş yapılmadı, satın alma/yorum yapılmadı):
  `apis.roblox.com/search-api/omni-search` (anlık CCU + oy sayıları), `games.roblox.com/v1/games` (ziyaret, oluşturma/güncelleme tarihi, favori, max oyuncu), `apis.roblox.com/game-passes/v1/universes/{id}/game-passes` (pass adı/fiyatı), `badges.roblox.com/v1/universes/{id}/badges` (rozet adı + verilme sayısı), `thumbnails.roblox.com` (görseller). Sorgu zamanı: 2026-10-14.
- **İkincil veri:** RoWatcher (zirve CCU + ay; yuvarlak sayılar, ay hassasiyeti), allthings.how/earnaldo/games.gg rehberleri (kalitesi karışık; "earnaldo" bir "bedava Robux" bloğu → **[D]**).
- **Sınırlar:**
  - **CCU anlıktır** ve gün saatine göre 2-3 kat oynar; zirveler RoWatcher'dan ay düzeyinde. "Şimdi/zirve" oranları kabadır.
  - **Oyunları oynayamadım.** Çekirdek döngü/ilerleme bilgisi oyun açıklaması, pass listesi, rozet adları ve rehberlerden çıkarım (D). Onboarding'i (ilk 60 sn) doğrudan gözlemleyemedim.
  - **Yorumlar/Reddit/YouTube/DevForum şikayetleri okunamadı** (arama motoru anlamlı Reddit/YouTube sonucu vermedi; Roblox oyun sayfası tarayıcıda açılamadı; Sportskeeda gibi güncelleme notu siteleri botlara kapalı). "Zayıflıklar" bölümleri bu yüzden **veriden çıkarım** (oy oranı, düşüş eğrisi, pass tasarımı) ve açıkça (D) etiketli.
  - RoWatcher'da "Strongest Punch Simulator" için zirve "278 (Nisan 2026)" yazıyor; bu takipçinin pencere sınırı, oyunun gerçek tarihsel zirvesi değil (416 M ziyaret var) → dikkate alma.
  - Pass fiyatları API'den **o anki** liste fiyatı; indirim/bundle görünmez. "Not for sale" olanlar kaldırılmış/kapalı.

---

## 2. Pazar fotoğrafı (2026-10-14 anlık)

### 2.1 İncelenen oyunlar

| Kısaltma | Oyun | Yapımcı | Oluşturma | Son güncelleme | CCU şimdi | Zirve CCU (ay) | Ziyaret | Beğeni | Oy oranı | Max oyuncu |
|---|---|---|---|---|---|---|---|---|---|---|
| **BW** | 💪 +1 Muscle to Break Walls | Man Face Muscles | 2026-05-11 | 10-05 | 3,25K | ~32K (Tem 2026) | 89,7 M | 69,5K | %97,2 | 12 |
| **ME** | +1 Muscle Evolution | Need More Cement | 2026-05-30 | 10-05 | 0,2K | ~39K (Ağu) | 60,9 M | 243K | %98,8 | 10 |
| **KE** | [⛩️W3] +1 Karate Evolution | Taynx Games | 2026-09-24 | 10-14 | 16,9K | ~17K (şimdi) | 2,56 M | 8,6K | %98,7 | 8 |
| **SE** | +1 Strength for Eggs | Crazay ASMR | 2026-09-12 | 10-12 | 5,5K | ~33K (Eki) | 22,3 M | 26K | %97,3 | 5 |
| **LR** | +1 Lift Rock for Treasure | ErEr Games | 2026-09-12 | 10-13 | 9,2K | ~20K (Eki) | 6,4 M | 14,9K | %96,2 | 6 |
| **ARM** | 💪 +1 Strength to Grow Your Arm！ | Core X Games | 2026-06-12 | 10-14 | 3,7K | ~24K (Eyl) | 34,0 M | 44,6K | %96,3 | 6 |
| **MOG** | [🎃] +1 Mog Evolution | Navoj Mog | 2026-08-30 | 10-11 | 2,4K | ~42K (Eyl) | 40,1 M | 315K | %98,0 | 12 |
| **PB** | [W5💪] +1 Muscle to Push Boulder | Doolittle! | 2026-06-01 | 10-11 | 0,49K | ~30K (Ağu) | 25,1 M | 63,7K | %98,7 | 10 |
| **AW+1** | [💪🏻]+1 Muscle to Arm Wrestle | Beast Lifters | 2026-04-11 | 09-12 | 1,1K | ~35K (May) | 87,5 M | 115K | %97,8 | 24 |
| **SO** | [W3] +1 Soldier Evolution | Malroh x Spil | 2026-08-23 | 10-14 | 1,5K | ~7K (Eki) | 2,8 M | 24,3K | %97,7 | 12 |
| **SB** | +1 Sword Blast Evolution | Swordwave Legends | 2026-07-28 | 10-13 | 3,4K | ~5K (Eki) | 2,5 M | 2,8K | %90,0 | 8 |
| **STC** | [☢️UPD] Smash the City | Kabooom Crew | 2026-09-26 | 10-13 | 10,3K | ~10K | 5,2 M | 12,3K | %90,0 | 6 |
| **SS** | +1 Stone Skipping | Meow Labs | 2026-09-05 | 10-12 | 43,1K | ~162K (Eki) | 40,4 M | 60,4K | %96,7 | 10 |
| **KALB** | [🍁] Kick a Lucky Block | No More Flops | 2026-04-07 | 10-12 | 11,1K | ~1,7 M (May) | 1,92 MİLYAR | 1,30 M | %95,0 | 5 |
| **TAP** | [NEW] Tap Simulator: Reborn | Cursor Makers | 2026-08-04 | 10-14 | 10,9K | ~11K (şimdi) | 1,3 M | 2,9K | %95,4 | 10 |
| **ML** | 🎃 Muscle Legends | Muscle Legends Studio | 2019-08-09 | 10-13 | 5,1K | ~82K (Ağu 2026) | 2,31 MİLYAR | 1,17 M | %88,3 | 20 |
| **GL** | [UPD 5] Gym League | 1v2 Studios | 2024-05-10 | 10-14 | 1,3K | ~41K (Tem 2025) | 832 M | 1,11 M | %96,5 | 8 |
| **GS** | Gym Star Simulator 🏋️ | Gym Simulator Club | 2024-08-20 | 10-09 | 6,4K | ~32K (Nis 2025) | 722 M | 256K | %92,5 | 16 |
| **SP** | 👑 STRONGEST PUNCH SIMULATOR | SUPER SAVAGE MODE | 2021-05-28 | 10-13 | 29 | (takipçi verisi eksik) | 416 M | 278K | %91,8 | 55 |
| **AW** | Arm Wrestle Simulator | Kubo Games | 2023-04-14 | 10-13 | 1,7K | ~23K (Eki 2024) | 1,32 MİLYAR | 1,24 M | %94,9 | 9 |
| **MTS** | [AURAS!] Muscle Transform Simulator | Castaway Studios | 2025-09-08 | 06-16 | 1,3K | ~26K (Mar 2026) | 113 M | 77K | %95,3 | 10 |
| — | Train to Fight | Boxing Fighters Legend | 2025-02-08 | 2026-02-26 | 0,96K | ? | 194,7 M | 133K | %91,4 | 20 |

Kaynaklar: [K] `games.roblox.com/v1/games`, `omni-search`; zirveler [O] RoWatcher `rowatcher.com/games/{universeId}`. (BW=10152905521, ME=10246386961, KE=10767814721, SE=10766138478, LR=10766135603, ARM=10310999762, MOG=10764479526, PB=10256263771, AW+1=10020612607, SO=10757704931, SB=10584891443, STC=10768176407, SS=10765298801, KALB=10004244222, TAP=10629695169, ML=1268927906, GL=5972059550, GS=6443367640, SP=2621357931, AW=4582358979, MTS=8669550197.)

### 2.2 Yaşam eğrisi: zirveden bugüne

| Oyun | Zirve | Şimdi | Şimdi/Zirve | Geçen süre (açılıştan) |
|---|---|---|---|---|
| ME | 39K | 0,2K | **%0,5** | ~4,5 ay |
| PB | 30K | 0,49K | **%1,6** | ~4,5 ay |
| AW+1 | 35K | 1,1K | **%3** | ~6 ay |
| LongArm (Long Arm Toy Escape) | 24K | 1,0K | %4 | ~2 ay |
| MTS | 26K | 1,3K | %5 | ~13 ay |
| MOG | 42K | 2,4K | %6 | ~1,5 ay |
| BW | 32K | 3,25K | %10 | ~5 ay |
| ARM | 24K | 3,7K | %15 | ~4 ay |
| (eski oyunlar) ML | 82K | 5,1K | %6 | 7 yıl |
| (eski) GS | 32K | 6,4K | %20 | 2 yıl |
| (eski) GL | 41K | 1,3K | %3 | 2,4 yıl |

Okuma: (a) "+1" oyunları 1-3. ayda tepe yapıp %85-99 düşüyor; (b) eski çekirdek oyunlar ~%3-20 seviyesinde sabitleniyor; (c) *şu an yükselişte* olan oyunlar (KE, SS, SE, LR, TAP, STC) hep son 3-6 haftada açılmış. Yeni hitler "bir sonraki dalga"dır; biz dalga arasındayız. (Gün saatine göre ±%50 hata payı.)

### 2.3 Türün genel kalıbı

- Tür etiketi: Roblox "Simulation > **Incremental Simulator**" (Bloxodes), `genre: All`. [O]
- **"+1 X Evolution" ailesi:** "evolution" araması 40+ oyun döndürüyor (ME, KE, MOG, Soldier, Sword Blast, Super Saiyan, Phonk, Motorcycle, Katana, Spider, Princess...). [K]
- **Küçük sunucu normu:** yeni hitlerde Max Players 5-12 (SE 5, LR 6, ARM 6, STC 6, KE 8, SB 8, BW 12). Özel (VIP) sunucu BW/ME/KE'de kapalı (`createVipServersAllowed:false`) [K].
- **Güncelleme ritmi:** AW Sim ve AW+1 açıklamalarında "her Cumartesi güncelleme" [O]; KE 24 Eylül'de açıldı ve 14 Ekim'de başlığında **[W3]** var (açılıştan en fazla ~20 gün, 2 yeni dünya) [K tarihleri, D yorum]; SO ~7 haftada W3. ML/GL/GS/AW Sim son 5 gün içinde güncellendi [K].

---

## 3. Rakip profilleri

### 3.1 BW — "+1 Muscle to Break Walls" (en yakın rakip) [K/O, çoğu çıkarım]
- **Çekirdek döngü:** ağırlık kaldır (squat/lift animasyonu) → güç (strength) → **duvarları kır** → Win → daha iyi ağırlık + **aura çarpanları** + rebirth. Açıklama: "lift weights... break walls to earn wins... buy better weights, auras for multipliers". Rehberler (D): pet + "treadmill" (cosmetic passes) + bölgeler.
- **İlerleme:** bölge/zone açma, rebirth (kalıcı çarpan). Dünya sayısı bilinmiyor (D).
- **Rozetler (funnel kanıtı) [K]:** Welcome 41,8 M → 100 Strength 36,4 M (%87) → First Win 33,7 M (%81) → 1000 Strength 31,8 M (%76) → **First Rebirth 21,9 M (%52)**. Yani oyuncuların yarısından fazlası ilk rebirth'e ulaşıyor: ilk dakikalar çok kısa/ödüllü.
- **Sosyal:** 12 kişilik sunucu, özel sunucu yok, sıralama dışında sosyal yok (D). Kod sistemi yok (D, earnaldo).
- **Para kazanma [K]:** Hacker Treadmill 1499 R$, Golden Treadmill 299, Golden Dumbbell 67, 67 Treadmill 29, OP Auto Clicker 37, Speed Boost 37, **Auto Rebirth 19**, **x2 Wins 79**, x2 Strength (satıştan kaldırılmış). Ucuz kolaylıklar + tek bir "balina" cosmetic.
- **Görsel:** düz Roblox "Bacon" avatarı, yeşil baseplate, lego-benzeri koyu ağırlıklar; çok basit. İkonda kırmızı alt şerit "OFFLINE STRENGTH" (son özellik ilanı).
- **Güncelleme:** son 10-05; 5 ayda tek yapımcı grubu (Update Testing Place var).
- **Neden büyüdü (D):** ilk dakika hızı, %97 oy oranı, thumbnail'de "1 → 6.700 → 99.999" üç panelli duvar kırma ilerlemesi, tür dalgası. Doğrudan pazarlama kanıtı yok.
- **Zayıflıklar (D, çıkarım):** 5 rozet = sığ hedefler; sosyal yok; ~%90 düşüş; x2 Strength'in satıştan kalkması ekonomi sorununa işaret edebilir.

### 3.2 ME — "+1 Muscle Evolution" (isim ikizimiz) [K/O]
- **Döngü:** tıkla → hasar/güç; yumruk torbalarında antrenman; düşmanları/aşamaları geç; **Win ile "Evolution" aç** (daha yüksek tıklama başı hasar); rebirth. Açıklama + allthings.how.
- **Rebirth [O, allthings.how]:** yumuşak sıfırlama (Damage, Level, Wins, Evolutions silinir); Damage çarpanı x2, x3, x4, x5, x6, x7 (R1-R6) ve **Level üst sınırı** (26 → 32 → 43 → 48 → 60 → 72); 20'den fazla rebirth; **Robux'lu "Skip Rebirth"**. **Bizimle neredeyse aynı yapı** (tam sayı çarpanlar, level üst sınırı, SKIP). Dünyalar: Rebirth 2 sonrası **Backrooms**, Rebirth 3 sonrası **King of the Hill** kapısı.
- **Para [K]:** VIP 249, x2 Wins 149, OP Auto Clicker 49, Triple Hatch 299, x2 Health 219, +3 Pets Equip 299, x2 Items Drop 199, x2 Luck 189, Auto-Open **19**, Pet Storage +150 99 / +500 349. Kod sistemi var (Trading, Yeti, Cement, SpecialPet...) [O].
- **Görsel:** muscular Roblox avatar arkadan, "+7 / -6" kapılar; ikonda **gizemli "?" yumurta** tutan kaslı karakter ve "+1"ler.
- **Başarı:** 243K beğeni, **%98,8**, 1,3 M favori; zirve ~39K Ağustos → şimdi 0,2K.
- **Zayıflık (D):** ağır sıfırlama (Wins + Evolutions silinir) ve hızlı içerik tükenmesi; 10-05'ten beri güncelleme yok.

### 3.3 KE — "[⛩️W3] +1 Karate Evolution" (şu an yükselen) [K/O]
- **Döngü:** "Spirit" için antrenman, gi yükselt, **ustaları (master) yen**, Win ile kuşak (belt) atla, rebirth. Açıklama.
- **Hız:** 24 Eylül'de açıldı → 14 Ekim'de **16,9K CCU = zirve**, 2,56 M ziyaret, **254K favori** (favori/ziyaret çok yüksek), %98,7. Son 24 saatte 564K yeni "Welcome" rozeti (toplam 1,03 M) → yeni oyuncu akışı hızla artıyor [K].
- **Para [K] (33 pass!):** **x999 Gold Dojo 999 R$**, x99 Radioactive Dojo 249, VIP 99, **Starter Pack 14 / Pro Pack 99 (her dünya için ayrı: [W2], [W3])**, Auto Click 25, OP Auto Strike 39, Auto Rebirth 49, "[LIMITED]" kozmetikler (Immortal Inferno 599, Emerald Dragon Guardian 699, Dragon Rider 699, Phoenix Legend Belt 249), 8 trail (14-299), Lightning Dash 19, Live Dragon Sash 499.
- **Görsel/thumbnail:** üç kuşak resmi (+1 / 67K / 999T) yan yana, her biri farklı arka planda (yeşil çim / sakura / lav-mor); ikonda ahşap duvarı delen yumruk, "+1" yağmuru ve kırmızı bant **"WORLD 3"**.
- **Başarı nedeni (D):** (1) ≤20 günde 3 dünya, (2) başlık/ikon "W3" duyuruları, (3) çok ucuz giriş pass'leri ve dünya başına başlangıç paketi, (4) "kuşak" kimliği (tanınır ilerleme), (5) görsel olarak duvar kırma temalı. Duvar kırma + "+1" Karate'de de çalışıyor — bizim fantezimizin doğrulaması.
- **Zayıflık (D):** tek rozet ("Welcome"), sosyal yok, VIP sunucu kapalı.

### 3.4 SE — "+1 Strength for Eggs" (duvar yumruklama + yumurta hibriti) [K/O]
- **Döngü:** güç kazan → yeni alanları aç → **yumurta kır, hayvanlar nakit getirsin (çevrimdışıyken de)** → hayvanları yükselt, üssünü genişlet; rebirth nakdi katlar. Grup + beğeni için bedava hayvan ödülü (açıklama).
- **Hız:** 12 Eylül'de açıldı; zirve ~33K (Ekim), 22,3 M ziyaret, **1,17 M favori**.
- **Thumbnail:** kırmızı tuğla duvarı yumruklayan kaslı avatar + "+1" kas simgeleri + sağda parlayan **"DRAGON EGG FROST"** yumurtası. Yani **bizim iki ana şeyimizi (duvar kırma + yumurta)** tek karede veriyorlar.
- **Para [K]:** x2 Strength 199, x2 Egg Growth Speed 280, V.I.P. 149, x2 Money 160.
- **Zayıflık (D):** düşük oy sayısı/ziyaret oranı (26K beğeni / 22 M ziyaret), ilk dalga bitmek üzere (33K → 6K).

### 3.5 ML — "🎃 Muscle Legends" (OG, 2019) [K/O]
- **Döngü:** antrenman (strength/durability/agility), yeni gym'ler aç, **oyuncularla dövüş (Brawl)**, pet topla, yeni hareketler (Moves), arenalar. Günlük "Fortune Spin"; grup sandığı +1 daily spin (açıklama).
- **Rozet funnel [K]:** "Rookie Lifter" 214,6 M → 2.500 Strength 66,6 M (%31) → 1 Rebirth 33,4 M (%15,5) → 5 Rebirth 12,8 M → 100 Rebirth 1,04 M (%0,5). Brawl: ilk galibiyet 42,6 M (%20) → 150 galibiyet 225K. Gym'ler: Frost 28,7 M → Mythical 12,0 M → Eternal 6,0 M → Legends 4,1 M → Industrial 378K.
- **Para [K]:** +3 Pet Slots 799, Auto Lift 499, +2 Pet Slots 499, x2 Rep Time 499, x2 Strength 349, x2 Durability 299, x2 Agility 299, +20/+60 Capacity 99/289, x2 Gems 249. (Pahalı çizgi: 99-799.)
- **Görsel:** karanlık, parlayan sarı kontur ("Muscle Legends" logolu), Halloween: balkabağı başlı dev adam, sarı şimşek, barbell; kendine özgü sanat yönü.
- **Güncelleme:** zirve ~82K Ağustos 2026 (7 yıllık oyun için dikkat çekici); en son 10-13. En düşük oy oranı (%88,3; 155K "beğenmedi") — nedeni doğrulanamadı; PvP/pay-to-win/exploit şikayetleri olası ama (D).
- **Zayıflık (D):** %88,3 oy oranı, karmaşık (3 stat), eski görsel dil; yeni oyuncu için yoğun.

### 3.6 GL — "Gym League" [K/O]
- **Döngü:** vücut geliştirme sim'i: kas fiziği, **yarışmalar (competitions)**, kas grupları antrenmanı, **vücut (body) ve aura reroll**, yeni gym'ler. Açıklamada "Great RESET" ve haftalık güncellemeye dönüş duyurusu (D, neyi sıfırladığı bilinmiyor).
- **Rozetler [K]:** 54 rozet, hepsi vücut/dünya ismi ("Shredded" 36 M → Tan, Slate, Concrete, Rock, Metal, Shiny, Steel, Armored, Alien, Diamond, Water, Magma, Plasma, Sun... "Absolute Zero" 378). Yani **vücut koleksiyonu = ana hedef** (bizim "evrim" fantezisine en yakın ana akım rakip). Welcome 136,8 M.
- **Para [K] (25 pass):** Cosmic Weights 1499, Mutated Genes 750 (+%200 kas, "Mutated" unvanı), Auto Train 450, **VIP 262 (+%50 kas, x1,5 para, VIP tag/unvan)**, Muscle Man 300 (+%100 kas, unvan), Gigachad Trainer 499, Triple Open 200, Instant Spin 150, Lucky 525, Hero/Temple Training Contract 599... **Pass'lere unvan (title) eklemek** standart.
- **Sosyal:** (Sportskeeda başlıkları, [D]) güncellemeler: Prison Gym, Sisyphus mini oyunu (U9), event+mini oyun (U10), Trainers + **özel sunucular** (U11), Arm Wrestle mini oyunu + Trainer rework (U12), v12.5'te **günlük/haftalık/aylık sıralama**.
- **Görsel:** Halloween ikonu (hapishane üniformalı, alev + mor aura, balkabaklı karanlık salon).
- **Başarı/Zayıflık:** %96,5 oy oranı ve 1,1 M beğeni, ama zirveden %97 düşüş (2025-Temmuz zirve) → içerik tüketilince oyuncu gidiyor (D).

### 3.7 GS — "Gym Star Simulator" [K/O]
- **Döngü:** antrenman → güç, **trainer'lar (yetenekli, takılabilir)**, pet'ler (yumurta, **crafting: 10 pet birleştir**), dünyalar/gym'ler (Modern, Space, Deep Ocean, Zoo, Ancient, Pyramid, Highschool, Ice Giants, Anime; "World 6" güncellemesi), **yarışmalar**, rebirth, aura sistemi, pet index. Cross-platform.
- **Rozet funnel [K]:** Welcome 48,8 M → 2 saat oyun 5,7 M (%11,8) → ilk yarışma galibiyeti 3,06 M (%6,3) → 25 pet 1,27 M (%2,6) → 20 aura 7,5K.
- **Para [K] (50 pass!):** VIP 399, Double Power 499, Rock (trainer) 699, **Steelman 6.999 / SAM 6.999 (trainer yetenek passes)**, +1 Trainer Equip 499, +2 Pets Equipped 199, +2 Extra Hatch 299, +2 Bonus Hatch 499, Lucky Aura 399 / 599 / 799, Fast Roll 399, +100 Pet Slots 99 (x4 sürüm), Diamond Skin 99, Rich Skin 49, **"[Gift]" sürümleri** (hediye edilebilir pass), event pass'leri (Christmas, Easter, Summer Camp). Balina fiyatları 6.999 R$.
- **Başarı:** 722 M ziyaret, 7,0 M favori; ama oy oranı %92,5.
- **Güncelleme:** her 2-4 haftada bir "Update N" (dünya, event, pet) — (D, Sportskeeda başlıklarından).

### 3.8 SP — "Strongest Punch Simulator" (+ "No Limit" kopyası) [K/O]
- **Döngü:** arazi/duvarlar boyunca yumruk at (patlama alanı), dünya sınırına ulaş, **daha yüksek dünyalara ışınlan**, güç-up'ları, mitik pet besle/evrimleştir, **kahraman/kötü karakter** (itibar sistemi; güçlü kahramana hasar yansır). Duvar kırma türünün atası (Punch Wall / Break Wall serisi).
- **Durum:** 416 M ziyaret ve 278K beğeniye karşın **CCU 29** (2026-10-14). Yapımcı güncellemeye devam ediyor (10-13).
- **Para [K]:** yalnızca 3 pass: X2 Orb 500, **Hero Hunter Pass 1.000 (hedeflenen kahramanları avla = PvP baskısı)**, X2 Walk Speed 250.
- **Ders (D):** PvP-baskı pass'i + dünya/itibar sürtünmesi eskimiş; yeni "+1" oyunlar aynı duvar kırma fantezisini çok daha sade verdi. Bizim "oyuncu başına duvar, sıfır baskı" yaklaşımı tam tersi.

### 3.9 ARM — "+1 Strength to Grow Your Arm！" (duvar kır + brainrot) [K/O]
- **Döngü:** ağırlık kaldır → sağ kolun büyür → duvarları kırarak yeni alanlar aç → **gizli brainrot'ları bul/üsse getir** → coin ile daha güçlü ağırlık. 24K zirve (Eylül), şimdi 3,7K.
- **Para [K]:** VIP 599, OneClickCollect 99, Money2X 349, +1 Pet Equip 399, **MutationLuck2X 349, BrainrotLuck2X 349, Tattoolucky x2 349**, Power2X (satıştan kaldırılmış). → "mutasyon" ve "luck" pass'leri standart.
- **Thumbnail:** küçük avatar → devasa mavi kol → yeşil **mekanik kol** (3 aşamalı büyüme + oklar). Bizim "evrim" fantezisinin aynısı; kol/mekanik tema ile.

### 3.10 AW+1 / AW — Arm Wrestle ailesi [K/O]
- **Arm Wrestle Simulator (Kubo Games, 2023):** PvP bilek güreşi, pet'ler (Gold/Void makinesi, shiny), gym'ler, bosslardan anahtar, rebirth; **her Cumartesi güncelleme**; 1,32 MİLYAR ziyaret, zirve ~23K (Ekim 2024), şimdi 1,7K, %94,9.
- **Pass'leri [K] aşırı ucuz:** **Auto Open Eggs 3 R$, Triple Open Eggs 5 R$, Auto Rebirth 5, Double Wins 10, x8 Hatching 99, Auto Clicker 29, VIP 219** (x3 antrenman kazancı, günlük Win Pack, sohbet etiketi), Premium Rewards 399. Çok pass ama 3-20 R$ (düşük bariyer → yüksek dönüşüm, düşük ARPPU).
- **[💪🏻]+1 Muscle to Arm Wrestle (Beast Lifters, 2026):** adım at + dumbbell + bilek güreşi düşmanlar + rebirth, **"Cumartesi haftalık güncelleme"**; zirve 35K (Mayıs). **Gym Zone passes: Golden Gym Zone 399 (25x kas), Viper Gym Zone 149 (10x), VIP 99, Magic Egg 529** — bizim koç pedlerimizle aynı kalıp (zone çarpan pass'i).

### 3.11 SO / SB — Soldier & Sword Blast Evolution (boss + prestij jetonu) [K/O]
- **SO:** tıkla → güç → silahları yükselt → zombi aşamalarını geç, **mini boss ve dünya boss'ları**, **Endless dalgalar (Tokens)**, pet yumurtası, rebirth; **[W3]**; "Autoplay" (askerin kendi koşması; satıştan kaldırılmış).
  **Pass [K]:** **DIVINE Target 699 (250x güç)**, Galaxy Target 199 (100x), VIP Target 99 (25x), Auto Rebirth 160, +2 Pets 149, 2nd Ability Slot 199, x2 Wins 79, Triple Hatch 99, x2 Egg Luck 79, Fast Hatch 39. → **"hedef/ped çarpanı" pass'leri 99-699** (bizim Coach Prism 199 / Shadow 299 aynı bölgede, alt uçta).
- **SB:** tıkla → güç → dalgaları yen → Win → daha iyi kılıç; **rebirth "Mastery" verir ve Mastery çarpan alır (prestij para birimi)**; çevrimdışı Win. Zirve 5K. Pass yok (muhtemelen dev product; [D]).

### 3.12 STC — "Smash the City" (yıkım + takım) [K/O]
- **Döngü:** silah seç (50+, 7 kategori: füze, nükleer, kasırga, kara delik, meteor), 11 harita (Downtown, Tokyo, Moon...), **yıkımla coin (%25/50/75/95 yıkım bonusu)**, arkadaşlarla takım. 26 Eylül'de açıldı; 10,3K CCU (zirve), 5,2 M ziyaret, %90.
- **Pass [K] 14 adet:** No cooldown 799, Mega Power 499, Black Hole 199, Moon Fall 299, **Map Builder 999**, Army 99, Void Nuke 499, Sharknado 299, Sun 299, Supernova 399, 2x Coins 249...
- **Ders:** "kırma tatmini" tek başına 10K CCU yapabiliyor (yıkım fiziği + ışık/patlama); bizim duvar kırma anı (Juice.brickChunks, wallHit) bu tatmin hattında.

### 3.13 MOG — "+1 Mog Evolution" [K/O]
- Her tık "Appeal"; çekiç "Bonesmash"'e yükselt; Win ile "ascend"; **sıralamada en üstteki "True Adam" unvanı kazanır**. Zirve 42K Eylül'de, 315K beğeni %98. **Pass yok** (API boş; gelir muhtemelen developer product, D).
- **Thumbnail:** üzgün kırmızı yüz | kendinden emin yeşil yüz (önce/sonra). **Unvan + sıralama = kimlik** mekaniği.

### 3.14 Tür dışı ama "ne kazanıyor" göstergeleri
- **"+1 Stone Skipping"** (43K şimdi, zirve **162K Ekim**, 5 Eylül'de açıldı): +1 skill → daha uzağa taş; bölgeler, taş çeşitleri, pet, rebirth. Pass'leri **Admin Training Zone 599, Golden Zone 249, Koi Zone 99 (antrenman bölgesi çarpanı pass'i)**, Auto Rebirth 149, Auto Wins 25, +1/+3/+6 Pets 69/195/499, Hatch +3/+8/+16 25/145/299.
- **"Kick a Lucky Block"** (1,92 mil. ziyaret, zirve 1,7 M May): tekme gücü (ağırlıkla çalışılır; pass açıklaması "x2 Kick Power for each squat") → uzağa tekmele → daha nadir brainrot → plot'unda para üret; tsunamiden kaç. Rebirth 1.000 Kick Power'da; **Rebirth Skip 99 R$**; VIP 729; x2 Cash 399; x2 Mutation Luck 265; Auto Kick 99 [K/O]. **"Squat + kick" fantezisi bu devin içinde de var** (rehberlerden, D).
- **"Steal An Egg"**: 1,46 M CCU, 8 mil. ziyaret (25 Temmuz'da açıldı); yumurta çal, nadir pet, **mutasyon**. 2026'nın baskın formülü: yumurta + koleksiyon + pasif gelir + mutasyon.
- **"+1 Speed Keyboard Escape"**: 76K CCU, 6,4 mil. ziyaret (Ocak 2026). "+1 Aura Per Click": 3,4K (402K beğeni).

---

## 4. Pass/fiyat karşılaştırması (R$, [K])

| Özellik | BW | ME | KE | AW | AW+1 | SO | SS | ML | GL | GS | **Biz** |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Auto Click/Train | 37 | 49 | 25 / 39 | 29 | — | — | — | 499 | 450 | — | **149** |
| Auto Rebirth | **19** | — | 49 | **5** | — | 160 | 149 | — | — | — | **YOK** |
| Kalıcı x2 Wins | **79** | 149 | — | 10 | — | 79 | — | — | — | — | **YOK** (VIP pedi + iksir) |
| Kalıcı x2 Güç | (kaldırıldı) | — | — | 10-12 | — | — | — | 349 | 300 (+%100) | 499 | **YOK** (iksir/paket) |
| VIP | — | 249 | 99 | 219 | 99 | 99 (Target) | — | — | 262 | 399 | **149** |
| Auto Open (yumurta) | — | **19** | — | **3** | — | — | — | — | — | — | **199** |
| Triple/Multi Open | — | 299 | — | 5 / x8 99 | — | 99 | 25-299 | — | 200 | 299-499 | **249** (x3 + x10) |
| +Pet Equip | — | 299 (+3) | — | — | — | 149 (+2) | 69-499 | 499-799 | — | 199 | **YOK** |
| Antrenman bölgesi çarpanı | — | — | 249 / **999** | — | 149 / 399 | 99 / 199 / **699** | 99 / 249 / 599 | — | 599 (yalnız Hero/Temple gym +%25) | — | **199 (x250) / 299 (x999)** |
| Başlangıç paketi | — | — | **14 / 99, dünya başına** | — | — | — | — | — | — | — | **YOK** |

Okuma: (1) kolaylık passes'leri 3-49 R$ → "dürtü satın alma"; bizde 149-249. (2) Bölge/ped çarpanı pass'leri 99-999 R$ aralığında; bizim x999 Shadow'u **299** (rakipte 999). (3) Rakiplerin hepsinde ücretli "Auto Rebirth" var; bizde Rebirth sadece SKIP. (4) Ödül/kod odaklı oyunlar (ML/GS/GL) çok pahalı uçlar taşıyor (1.499-6.999 R$); sahibin "150 R$'yi geçmesin" kuralı bunlarla çelişir — dikkat.

### 4.1 Funnel referansları (rozet sayaçları, [K]; "Welcome"/ilk rozete oran)
| Oyun | Ara adım | Oran |
|---|---|---|
| BW | 100 Strength | %87 |
| BW | First Win | %81 |
| BW | 1000 Strength | %76 |
| BW | **First Rebirth** | **%52** |
| ML | 1 Rebirth | %15,5 |
| ML | 100 Rebirth | %0,5 |
| GS | 2 saat oyun | %11,8 |
| GS | 25 pet | %2,6 |

Bizim hedefimiz: Config.Funnel'daki `FirstRebirth / Joined` oranı. BW'nin %52'si, ilk rebirth'in çok erken (dakikalar içinde) olduğunu gösteriyor. Bizde Auto Click'siz ilk rebirth ~5,5 dk (CLAUDE.md); eşit tempoyu korumak önemli.

---

## 5. Özellik boşluğu matrisi (rakiplerde var / bizde yok)

Önem: **Y** = yüksek, **O** = orta, **D** = düşük. "Kanıt" sütununda hangi rakip ve güven.

| # | Özellik | Rakiplerde (kanıt) | Bizde | Önem |
|---|---|---|---|---|
| 1 | **2. / 3. dünya** (yeni harita + yeni duvar/yumurta/pet seti; başlıkta `[W3]`) | ME (Backrooms R2, KotH R3 [O]), KE (W3, açılıştan ≤20 gün [K]), SO W3, PB W5, GS 9 gym + World 6, ML 5+ gym [K], SP, AW | **Yok** ("Worlds: coming soon" kemeri) | **Y** |
| 2 | **Auto Rebirth pass** | BW 19, KE 49, AW 5, SO 160, SS 149, KALB rebirth skip 99 [K] | Yok (yalnız SKIP) | **Y** |
| 3 | **Kalıcı x2 Wins / x2 Güç pass** | BW 79, ME 149, SO 79, PB 149, AW 10, ML 349, SE 199, LR 3-1.249 [K] | Yok | **Y** |
| 4 | **+Pet Equip / pet slotu pass** | ME +3 299, SO +2 149, SS 69-499, ML 499-799, GS +2 199 [K] | Yok (3 sabit; sadece Pet Space ürünü) | **Y** |
| 5 | **Rozetler (badges)** | BW 5, KE 1, ML 18, GL 54, GS 20 [K] | **Yok** (BadgeService yok) | **Y** (kolay) |
| 6 | **Başlangıç paketi / dünya paketi (14-99 R$)** | KE Starter 14 / Pro 99 per world [K] | Yok | O |
| 7 | **Unvan/ünvan etiketi** (VIP, Mutated, Muscle Man, "True Adam") | GL pass'lerinde [K], MOG sıralamada [O], AW VIP chat tag [K] | Yok (OverheadTags sadece isim) | O |
| 8 | **Günlük/haftalık/aylık sıralama** | GL v12.5 [D, Sportskeeda başlığı], MOG [O] | Sadece ömür boyu (kas, rebirth) | O |
| 9 | **PvP / yarışma / arena** | ML Brawl (42,6 M ilk galibiyet), GL/GS competitions, AW PvP, SP kahraman | Yok (bilerek; çocuk güvenliği) | O |
| 10 | **Boss / dünya boss'u / Endless dalga** | SO mini+dünya boss + Endless, KE ustalar, AW boss anahtarları [K/O] | Yok (sadece "Boss pet") | O |
| 11 | **Mini oyunlar** (Sisyphus, Arm Wrestle, Crossover, Prison Gym) | GL U9-U12, GS Crossover [D] | Yok | D-O |
| 12 | **Mutasyon / shiny / altın pet** | Steal An Egg, KALB/ARM MutationLuck passes, AW Gold/Void, SP evolve [K/O] | Yok (birleştirme var, mutasyon yok) | O |
| 13 | **Pasif gelir veren pet/hayvan + üs/plot** | SE (hayvanlar nakit), KALB (brainrot plot), ARM (brainrot üs) [K/O] | Yok (pet = çarpan; çevrimdışı kazanç var ama oran 0,02) | **Y** (trend) |
| 14 | **Prestij para birimi** (Mastery, tokens) | SB (Mastery), SO (Tokens), ME [O] | Yok (rebirth = +1 çarpan + level üst sınırı) | O |
| 15 | **Trainer/koç takma (yetenek)** | GS/GL (yetenekli, takılabilir; passes 499-6.999) [K] | Koçlar = zemin çarpanı (takılamaz) | O |
| 16 | **Etkinlik (event) ve sezonluk içerik** | ML 🎃, GL Halloween, GS Halloween pets, ME/MOG `[🎃]` [K/O] | Yok | **Y** (zamanlı) |
| 17 | **Grup ödülü / grup sandığı** | ML (grup sandığı +1 spin), SE (grup + beğeni için hayvan), GL (grup + beğeni ödülü) [O] | Yok | O (uyarı §7-4) |
| 18 | **Haftalık güncelleme ritmi + ikon bandı** | AW, AW+1 "her Cumartesi" [O]; BW/KE/ARM ikon bandı [K] | Yok (yeni) | **Y** |
| 19 | **Özel (VIP) sunucu** | GL (U11) [D]; BW/ME/KE kapalı [K] | ? (kontrol et) | D |
| 20 | **Kodlar** | ML, GS, GL, ME [O]; BW yok | Yok (**sahibi reddetti**) | — |
| 21 | **Ticaret (trading)** | TAP "coming soon"; niş oyunlarda yok [K] | Yok | — (önerilmez) |
| 22 | **Küçük sunucu (Max Players 5-12)** | BW 12, KE 8, SE 5... [K] | ? (kontrol et) | **Y** (16 CCU'da) |

---

## 6. Bizim daha iyi/farklı yaptıklarımız ve pazarlamada vurgulanacak farklar

(Rakip oyunlarda **kanıt bulamadıklarım** "rakipte yok" değil, "gözlemlenmedi" demektir.)

**Gerçek farklar (kodumuzdan, CLAUDE.md + rakip verisi):**
1. **Görünür evrim fantezisi:** 6 kas aşaması (popo/uyluk/baldır ayrı), boy + genişlik ölçeği (x0,9 → x2,2), kıyafet/şort uyumu, kas rengi ten rengine uyum. Rakiplerin çoğu sayı gösteriyor; GL ve ARM görsel büyümeyi öne çıkarıyor, ama bizim "bacak" odaklı kas modelimiz ayırt edici. *Ad ("Evolution") ve ikon ("+999", kaslı bacaklar) bunu zaten söylüyor.*
2. **Duvar kırma deneyimi:** 100 duvar, 20 tema (Paper → Blackhole; gerçek 3B malzeme, parçacık, Juice kırıntı, duvar geri sekmesi), **tekme temas anında hasar** — ses/görüntü eşzamanlı. BW'de ve KE'de duvar kırma var ama temaları ve fiziği sade görünüyor (thumbnail/ikon gözlemi, D). STC (yıkım) gösteriyor ki "kırma tatmini" tek başına 10K CCU yapabilir.
3. **Oyuncu başına duvar:** sıra beklemek/çalma/kavga yok; mobil yük düşük (WallClient pencere). Rakiplerde sunucu paylaşımlı olabilir (D).
4. **Rehber turu + görev zinciri:** ok, halka, balon, NEW PLAYER görev zinciri, ödülü Quests'ten alma. Rakiplerde böyle bir onboarding kanıtı bulamadım (rozet listeleri sığ: BW 5, KE 1) [D].
5. **Derin ama okunur ekonomi:** tam sayı çarpanlar (x1...x22; ME ile aynı mantık), 10 koç pedi (rebirth'le açılan), 15 ayakkabı, 15 skin, 6 yumurta/30 pet (%50/30/13/5/2 gösterilir), pet birleştirme → Boss, Pet Index +%10. Rakip "+1" oyunlarının çoğundan çok daha derin.
6. **Sosyal-ama-güvenli:** arkadaş bonusu (+%10/kişi, 5'e kadar), sıralama panoları, çocuk güvenliği (PvP yok, soygun yok, sohbet gerektiren özellik yok).
7. **Politika uyumu:** ücretli rastgele ürünlerde gerçek yüzdeler görünür; PolicyService kısıtlı hesaplarda yumurta/Luck iksiri kapalı. Rakiplerde "Luck" pass'leri/"Magic Egg" pass'leri bolca var — Roblox politikası sertleşirse bizim avantajımız.
8. **Mobil performans modu, dokunma filtresi (kaydırma ≠ tıklama), yükleme ekranı gerçek ilerleme çubuğuyla.**
9. **Çevrimdışı kazanç + günlük çark + oyun süresi ödülleri + görevler** (rakiplerin yalnız bir kısmı var).
10. **Fiyat politikası temiz** (sahibi ≤150 kuralı; fakat §4'e bakın: bazı kolaylıklar pazara göre pahalı).

**Pazarlamada öne çıkarılacak 5 slogan/odak:**
- "Watch your legs grow: Beginner → Legend" (mevcut kapak).
- "Smash 100 walls — Paper to Blackhole" (tema ilerlemesi; KE/BW tek tema).
- "Your walls, your pace" (oyuncu başına duvar; kimse çalmaz/bozmaz).
- "Hatch, merge, boss pets" (5 nadirlik + birleştirme).
- "Play with friends: up to +50% power" (arkadaş bonusu; Roblox sosyal sinyali).

**Zayıf yönlerimiz (dürüst):** tek dünya (oyunun sonu ~8 saat), Auto Rebirth/x2 Wins gibi pazar standardı pass'lerin eksikliği, rozet yok, sosyal içerik az, küçük/yeni kitle, 16+ kilidi, açıklama uzun ve özellik listesi (rakipler 2-4 cümle + "Like & Favorite"), "Evolution" adı 40+ başka oyunla çakışıyor (ME 243K beğeniyle aramada önde).

---

## 7. "Rakipleri geçme" önerileri

### 7-0. ÖN KOŞUL (mekanik değil, ama her şeyden önce): Audience Reach / yaş kilidi
- **Durum:** oyun "16+" ("Ages 16+ and trusted friends") ve ~16 oyuncu; rakiplerin hepsi Minimal/Mild.
- **Resmi kural (create.roblox.com/docs/production/publishing/kids-and-select):** Kids (5-8) ve Select (9-15) için: hesap iyi durumda + yaş doğrulaması (yüz tahmini ya da kimlik) + **2 adımlı doğrulama** + tam **Maturity & Compliance anketi** + **tek seferlik iade edilebilir yayın ücreti *ya da* 2 ay kesintisiz aktif Roblox Plus/Premium aboneliği** (yalnızca "tüm yaşlara" yayınlarken/güncellerken). Ardından **değerlendirme:** önce 16+ deneme aşaması, **60 gün içinde 250 benzersiz "yüksek etkileşimli, yaşı doğrulanmış" oyuncu** ("highly engaged" = son 60 günde Roblox'ta herhangi bir yerde satın alma yapmış, hesabı yerleşik, oyunda süre geçirmiş; oyun içinde harcama şart değil). **Hızlandırılmış inceleme:** 50.000 R$ iade edilebilir ücret (pratik değil). İlerleme Creator Hub > **Audience Reach** panosunda. DevForum personel yanıtı eşiği 500 olarak veriyor; **resmi doküman 250** diyor (doküman daha güncel görünüyor).
- **Pratik adımlar:** (1) Audience Reach panosunda hangi şartın eksik olduğuna bak (ID/2SV/ücret/abonelik/anket); (2) yaşı doğrulanmış ve son 60 günde Robux harcamış tanıdıkları (arkadaş, akraba, Discord) oyuna 5+ dk sokmak 250 eşiğine sayılır; (3) bu sürede içerik/pazarlamayı 16+ ve yetişkin kitleye (TikTok/YouTube Shorts "evrim/kas" videoları) yönelt; (4) ücret yerine abonelik daha ucuz olabilir (iade ücreti 90 gün sonra iade).
- **Risk/uyarı:** "250 benzersiz oyuncu" sayacını yapay yükseltmek (alt hesap, bot) kurallara aykırıdır ve hesabı riske atar.
- **Etki:** Yüksek (görünürlük sıçraması; diğer her şeyin ön şartı). **Efor:** S (idari). Kaynak: [resmi doküman], [DevForum tartışması].

### Önerilen 10 mekanik/özellik (etki × efor sıralı; hepsi CLAUDE.md kurallarıyla çatışmaları gözetilerek)

**Sahibin reddettikleri (tekrar önermiyorum):** günlük giriş ödülü, promosyon kodları, lobi görev panosu, göz alan ışık/bloom, tek tek stack'lenen pet kartları, vb.

| # | Öneri | Gerekçe (rakip kanıtı) | Beklenen etki | Efor | Riskler |
|---|---|---|---|---|---|
| **1** | **Dünya 2 (Worlds kemeri açılır)**: yeni harita katı, yeni 5 aşamalı duvar teması seti, yeni yumurta/pet seti, yeni koç. Rebirth N ile açılır (ME: R2/R3). Başlık/ikonda `[W2]` + kırmızı "WORLD 2" bandı. | KE ≤20 günde W3; SO, PB W5; GS 9 gym; ML 5+ gym; ikon bandı CTR tekniği; bizim "oyunun sonu ~8 sa" = içerik tükenir | **Çok yüksek** (retention + pazarlama olayı) | **L** (Config.Worlds + WallService/Layout çok-dünya genellemesi; tools/simulate.py ile denge; yeni model/tema) | Denge (yeni dünya çarpan ölçeği); bakım yükü; yeni dünya yoksa "coming soon" kemeri hayal kırıklığı |
| **2** | **Pass paketi yenileme**: Auto Rebirth (~49), x2 Wins (~79-99), +1/+2 Pet Equip (149/249 istisna), Auto Click fiyatını 149 → ~59-79 dene, **Starter Pack** (bir kerelik ~25-49: 1 iksir + Win). Hepsi sahibin ≤150 kuralı içinde (Pet Equip istisna gerekebilir). | §4: rakiplerin hepsinde Auto Rebirth; x2 Wins 79-149; dürtü fiyatı 19-79 | **Yüksek** (dönüşüm) | **S** (Config.Shop/AutoClick + Purchases + client ShopPanel; ID'ler robux_ids.txt pipeline) | "Pay-to-win" algısı; tempo bozulur: `tools/simulate.py` ile x2 Wins/+pet equip etkisini ölç; sahibin "gereksiz ucuz olmasın" kuralı (min 25) |
| **3** | **Cadılar Bayramı mini etkinliği (17 gün)**: sınırlı süreli "Pumpkin" duvar teması + 🎃 ad/ikon etiketi + sınırlı iz/aura (Win ile, ücretsiz kazanılır), lobi dekoru. | ML/GL/GS ve birçok "+1" 🎃; sahibi onayı bekleyen fikir (OYUN_TASARIM_ANALIZI.md) | Yüksek (kısa vadeli) | **S-M** (WallService.Themes ek aşama, LobbyDetail, Config.Trails/Auras) | Sahibin onayı; abartılı ışık yok (efektleri kıs); FOMO baskısı (çocuk güvenliği): her şey oyunla kazanılabilir, Robux yok |
| **4** | **Rozetler + Roblox Grubu + sosyal bağlantılar + Max Players ayarı**: BadgeService ile Welcome, 100/1K/1M güç, First Wall, First Rebirth, Stage 5/10/15/20, Pet Index; Creator Hub'da sosyal bağlantılar (YouTube/Discord). Max Players 10-12. | Rakiplerde rozet var (BW 5 → 41,8 M kişi aldı); 16 CCU'da küçük sunucu = canlı hissi; ML/GL/SE grup ödülü | Orta-yüksek | **S** (server + BadgeService; Creator Hub'da rozet oluştur) | **Beğeni/favori karşılığı ödül verme** (politika belirsiz, D); grup ödülü "kod" sayılmasın diye sahibin onayı; rozet kimlikleri elle girilir |
| **5** | **Unvanlar + günlük/haftalık sıralama**: oyuncunun kafası üstünde ve sıralamada unvan (ör. "Paper Breaker" → "Blackhole Crusher": en yüksek kırılan aşama; VIP/pass unvanı); haftalık "En çok kırılan duvar / en çok güç kazanılan" panosu (OrderedDataStore, hafta anahtarı). Haftalık birincilere o haftaya özel unvan/iz. | GL (unvanlı pass'ler), MOG ("True Adam"), GL günlük/haftalık sıralama; 16 CCU'da bile "sıfırlanan" pano rekabeti taze tutar | Orta | **S-M** (OverheadTags + Leaderboards + yeni OrderedDataStore) | Düşük kitlede panolar boş görünebilir (tüm sunuculardan toplu veri kullan); "günlük giriş ödülü" gibi görülmesin (ödül giriş değil başarı); sahtecilik (kas doğrulaması sunucuda) |
| **6** | **Evolution Forms ("Form-Up" anı)**: her kas aşaması eşiğinde (Legs.StageLevels) adlı bir form (Rookie → Lifter → Beast → Titan → Colossus → Legend), kısa **ekran flaşı + halka patlaması + ses** (büyük yazı yok: sahibi "ekranı sade tut" demişti), alt çubukta form adı, Index'te "Evolution" sekmesi (siluet → açıldı). TikTok/Short için fotoğraf pozu (idle). | Adımız "Evolution"; GL'de vücut koleksiyonu ana hedef (54 rozet); ME "Evolution" Win'le alınır; ARM/KE "3 aşamalı büyüme" thumbnail'i; klip yapılabilir an = organik trafik | Orta-yüksek | **M** (LegGrowth + Juice + Config.Legs/Forms + Index) | Görsel dengeler; yazı/ışık abartısı yok; boy/kapı sınırı (2,2x) korunmalı |
| **7** | **Pet Seferleri (Expeditions)**: takılı olmayan petleri 1/4/8 saatlik sefere gönder → Win/iksir (rastgele değil, boyutla ölçeklenir; Boss pet daha çok); çevrimdışıyken de çalışır. Opsiyonel ücretli "+1 sefer slotu" (rastgele DEĞİL). | 2026 hitlerinin ortak katmanı: hayvan/brainrot pasif gelir (SE, KALB, ARM, Steal An Egg); bizde pet = sadece çarpan | Yüksek (retention, pet değerini artırır, pet slot satışını destekler) | **M** (PetsPanel + PlayerStats + OfflinePanel mantığı; sunucu süresi os.time ile) | Win enflasyonu (ayakkabı/skin fiyatları): simulate.py; "geri dön" zamanlayıcısı baskısı: giriş serisi değil, birikimli; sahibi sandıkları sevmedi (lobide yeni 3B nesne yok, sadece panel) |
| **8** | **Rebirth Mastery**: her rebirth'te "Mastery" jetonu; 8-10 kalıcı düğüm (+tıklama gücü %, +Win %, +çevrimdışı tavanı, +1 pet equip, +Auto Click hızı…); RebirthPanel'de. | SB: rebirth = Mastery harcanır; SO Tokens; ME rebirth derinliği; bizde rebirth yalnız +1 çarpan | Orta-yüksek (rebirth döngüsünü anlamlı kılar) | **M** (Progression + PlayerStats + RebirthPanel + simulate.py) | Çarpan tam sayı ilkesi (sahibi): düğümler +N/x2 olarak, yüzde yerine kademeli; mevcut tempoya etkisi; karmaşıklık (çocuklar için kısa metin) |
| **9** | **Sunucu "Boss Duvarı"**: lobide periyodik (örn. 8 dk) dev duvar; sunucudaki herkes tekmeyle vurur, can sunucudaki oyuncu sayısıyla ölçeklenir; katkıya göre kademeli ödül (Win, iksir, Index sandığı değil—rastgele değil). Sahibin yanıtını bekleyen "Boss Wall" fikriyle aynı. | SO boss'lar (mini + dünya), KE "ustalar", GS/GL yarışmalar; ortak an = sosyal çıpa | Orta | **M** (WallService'e istisna: paylaşımlı sunucu nesnesi; istemci gösterir; CLAUDE.md "sunucuda duvar Part'ı oluşturma" kuralı → boss için can sunucuda, görsel istemcide) | Düşük CCU'da etkinlik boş kalır (tek oyuncuda da bitirilebilir tasarım); kamera/ışık abartısı; mobil performans |
| **10** | **Flex Yarışması (şiddetsiz "pozlama")**: lobide 4-8 kişilik 60 sn tur; zamanlama mini oyunu + "form puanı" (kas aşaması + level); kazanana Win, herkese küçük ödül; kimse kimseyi vurmaz/soymaz; yetersiz oyuncuda **NPC "Gym Rat"** doldurur. | ML/GL/GS/AW'de yarışma/PvP ana döngü (ML 42,6 M ilk Brawl galibiyeti); çocuk güvenli PvP alternatifi | Orta | **M-L** (yeni sunucu modülü + UI + animasyon; zamanlamayı sunucuda doğrula) | Matchmaking boş (NPC çözer); hile (sunucuda doğrula); sohbet gerektirmez; sınırlı süreli "puan" için sahibi onayı |

**Sıralı uygulama önerisi:** Hafta 0 → #7-0 (Audience Reach) + #4 (rozet/Max Players) + #2 (pass'ler) + ikon bandı/ad tagi; Hafta 1 → #3 (Halloween, 31 Ekim'e kadar); Hafta 2-3 → #5 (unvan + haftalık pano) + #6 (Form-Up); Hafta 3-8 → #1 (Dünya 2) + #8 (Mastery) + #7 (Seferler); sonra #9, #10.

**Şimdilik önerilmeyenler:** (a) Ticaret (niş oyunlarda yok; Roblox "IsPaidItemTradingAllowed" gerekli; çocuk güvenliği), (b) PvP hasar/soygun (çocuk güvenliği; SP dersi), (c) "beğeni karşılığı ödül" (politika belirsiz), (d) mutasyon/shiny pet **ücretli lucky pass'iyle** (ücretli-rastgele politikası; ARM/KALB/ML'de yaygın ama bizim ilke: yüzdeler görünür + kısıtlı hesaplarda kapalı; yapılacaksa ücretsiz ve yüzdeli).

---

## 8. İsimlendirme, anahtar kelime ve thumbnail gözlemleri (kopyalama değil, betimleme)

### 8.1 Oyun adı kalıpları [K]
- **Kalıp: "+1 <Ad/Güç> <fiil/Evolution>"**: "+1 Muscle to Break Walls", "+1 Muscle Evolution", "+1 Karate Evolution", "+1 Strength to Grow Your Arm！", "+1 Strength for Eggs", "+1 Lift Rock for Treasure". Arama sonuçları ("evolution" 40+ oyun) bu etiketin tür sinyali olduğunu gösteriyor.
- **Başlık etiketleri:** `[W3]`/`[W4]`/`[W5]` (dünya sayısı), `[UPD]`/`[UPD 5]`, `[NEW]`, `[2X]`/`[5X]`, `[AURAS!]`, ve **emoji öneki** (💪, ⛩️, 🎃, 🍁 mevsim emojisi). ML "🎃 Muscle Legends", MOG "[🎃] +1 Mog Evolution" — mevsimsel emoji başlıkta standart. Max 50 karakter sınırı.
- **Bizim adımız** ("+1 Squat Evolution: Smash Walls", 31 karakter) kalıba çok iyi uyuyor ("+1", "Evolution", "Smash Walls" ayrı küçük kümeler); ama **anonim aramada bulunmadı** (§0.1) ve "Muscle Evolution" 243K beğeniyle aranan terimlerde önde. Öneri: Audience Reach açılınca "squat" + "smash walls" kelimelerini açıklamanın ilk satırlarında tut; ad etiketi olarak `[W2]` / `🎃` kullan.
- **Açıklamalar kısa** (2-4 cümle) ve çoğu "Like & Favorite" ile biter. Bizimki 887 karakter, emoji başlıklı özellik listesi; mobilde ilk 2-3 satır görünür → **ilk satırı** ("Click to squat and kick your way to the BIGGEST LEG MUSCLES ever! 💪") koru, listeyi kısalt.
- **Genre:** rakiplerde `All` + "Incremental Simulator" alt türü; Creator Hub'da genre/ alt tür bilgisini kontrol et.

### 8.2 Thumbnail / ikon kalıpları [K, ~24 görsel incelendi: 16 thumbnail + 8 ikon]
- **Üç panelli / önce-sonra "büyüme" kompozisyonu en yaygın kazanan:**
  - BW 2. görsel: üç panel (mavi → yeşil → kırmızı duvar), karakter küçülükten kasa doğru büyür, üstte kas simgesi + **1 / 6.700 / 99.999**; arka planda deliğe dönüşen duvar.
  - KE: üç kuşak (kahverengi/beyaz/siyah-alevli) üç ortamda, sayılar **1 / 67K / 999T**.
  - LR: iki panel "1" (ter içinde, küçük kaya) → "999M $978Qa Celestial" (parlayan gezegen ödülü).
  - ARM: küçük avatar → mavi dev kol → yeşil mekanik kol (oklarla).
  - MOG: kırmızı üzgün yüz | yeşil kendinden emin yüz.
  Bizim kapağımız ("BEGINNER → LEGEND", kırmızı ok, tuğla duvarlar, +1/+999 yazıları) **bu kalıba çok uyuyor** ✔. Eksik: BW'deki gibi **kırılan duvarın deliği/kırıntısı** ve **büyük sayı bandı**; ve SE'deki gibi bir **ödül göstergesi** (ör. "BOSS PET" ya da "BLACKHOLE WALL" etiketi).
- **İkonlar:** kırmızı/turuncu **alt bant** ile son özellik ilanı: BW "OFFLINE STRENGTH", KE "WORLD 3", ARM "Power Rings". ME: kaslı karakter + **"?" gizemli yumurta** + "+1"ler. GL/ML: mevsimsel Halloween ikonu (balkabaklı/hapishane üniformalı kas, alev/yıldırım). GS: karın kası yakın plan, yeşil parlama, "+100" sayıları. STC: patlayan şehir silueti.
  → **Öneri:** ikonda küçük bir bant yer aç (örn. "NEW: WORLD 2" ya da "🎃 EVENT") ve her güncellemede değiştir; ikon 512×512'de "+999" + kaslı bacaklar zaten tür diline uygun.
- **Ortak görsel dil:** Roblox standart "bacon-saçlı" avatar, parlak doygun renk, kalın beyaz/siyah kontur sayılar, 1-2 kelime metin; fotogerçekçi değil. ML ve GL bunun dışında "koyu, sinematik" sanat yönü kullanıyor (eski oyunlar); yeni "+1" hitler parlak/çocuksu.
- **Küçük sunucu (5-12) ve "rastgele eşleşme"** üzerinden oyuncu sayısını canlı gösteriyor: 16 CCU'da bile sunucu doluluğu daha çekici.

### 8.3 Başlıkta/ikonda yapmamamız gerekenler
- Rakip marka/isim (ör. "Muscle Legends", "Gym League") kullanma; "Evolution"ı korurken "+1 Muscle Evolution"dan ayrışmak için "Squat" + "Smash Walls" kombinasyonu bizi ayırıyor.
- Aşırı parlak/bloom ışık efektli thumbnail (sahibi reddetti; ayrıca kapakta flaş yerine renk ve kontrast kullan).

---

## 9. Ek notlar ve sonraki adımlar

- **Veri tazeleme:** `omni-search` ve `games.roblox.com` uç noktaları anonim çalışıyor; haftalık "rakip nabzı" için betik yazılabilir (CCU, güncelleme tarihi, pass fiyatları). KE (W3), SS, SE, LR, TAP **önümüzdeki 2 hafta** izlenmeli: düşüş eğrisi (2-3 hafta içinde %50+ kayıp) bu belgenin "ömür" tezini sınar.
- **Bilinmeyenler (araştırma sınırı):** (1) rakiplerin ilk 60 sn onboarding'i, (2) gerçek şikayet/yorum içeriği, (3) developer product fiyatları (API vermedi), (4) rakip gelirleri (hiçbir kaynak yok), (5) bizim oyunumuzun anonim aramada neden görünmediği.
- **Bu belgeyi besleyecek ucuz doğrulamalar (sahibi yapabilir):** Creator Hub > Audience Reach ekran görüntüsü; oyunun "Max Players" ve "Private Servers" ayarı; giriş yapmış 16+ ve 13-15 hesapla "Squat Evolution" araması; rakip oyunlarda ilk 5 dakikayı oynayıp süre ölçme.

---

## Kaynaklar (URL'ler)

**Roblox herkese açık uç noktaları [K] (sorgu: 2026-10-14):**
- Arama/CCU/oy: `https://apis.roblox.com/search-api/omni-search?searchQuery=muscle%20walls&sessionId=abc&pageType=all` (ayrıca `squat`, `smash walls`, `punch simulator`, `squat evolution`, `gym`, `%2B1%20strength`, `kick wall`, `lift weights`)
- Oyun künyesi: `https://games.roblox.com/v1/games?universeIds=10152905521,10246386961,10767814721,...` (üstteki tablodaki universeId'ler)
- Pass'ler: `https://apis.roblox.com/game-passes/v1/universes/10152905521/game-passes?passView=Full&pageSize=50` (ve diğer universeId'ler)
- Rozetler: `https://badges.roblox.com/v1/universes/10152905521/badges?limit=100&sortOrder=Asc` (BW), `.../6443367640/badges` (GS), `.../5972059550/badges` (GL), `.../1268927906/badges` (ML), `.../10767814721/badges` (KE)
- Grup oyunları: `https://games.roblox.com/v2/groups/588183356/games?accessFilter=2&limit=50`, `.../462340796/...`, `.../1014647963/...`
- Thumbnail/ikon: `https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds=...`, `https://thumbnails.roblox.com/v1/games/icons?universeIds=...`
- Yer→evren: `https://apis.roblox.com/universes/v1/places/10152905521/universe`

**Roblox resmi doküman/forum:**
- https://create.roblox.com/docs/production/publishing/kids-and-select (resmi: Kids/Select şartları, 250 oyuncu eşiği, 50.000 R$ hızlandırma)
- https://create.roblox.com/docs/en-us/production/promotion/content-maturity (etiketler ve kitle)
- https://devforum.roblox.com/t/experience-limited-to-ages-16-and-trusted-friends-despite-having-minimal-content-rating/4758340 (personel yanıtı; 1.000 R$ ücret + 500 oyuncu iddiası; resmi dokümanla 250 farkı var)

**Üçüncü taraf takipçiler [O]:**
- https://rowatcher.com/games/10152905521/1-muscle-to-break-walls (BW), `https://rowatcher.com/games/{universeId}` (ME, KE, SE, LR, ARM, MOG, PB, AW+1, SO, SB, STC, SS, KALB, TAP, ML, GL, GS, SP, AW, MTS, 10700505394)
- https://bloxodes.com/stats/games/1-smash-walls-escape-10389413214
- https://rowatcher.com/news/the-simulation-takeover-why-casual-sims-rule-roblox-in-2026 (genel simülatör eğilimleri; tek kaynak, sayılar doğrulanamaz [D])

**Rehber/makaleler [D-O]:**
- https://allthings.how/1-muscle-evolution-rebirth-requirements-perks-and-how-to-reset/ (ME rebirth tablosu, Backrooms/KotH, Skip Rebirth) [O]
- https://earnaldo.com/blog/1-muscle-to-break-walls-free-robux-guide (BW rehberi; "bedava Robux" sitesi, **düşük güven**) [D]
- https://findingdulcinea.com/kick-a-lucky-block-beginner-guide/ ve https://games.gg/it/roblox/guides/guida-per-principianti-a-kick-a-lucky-block-consigli-per-progredire-velocemente/ (KALB döngüsü; makine çevirisi, [D])
- Arama sonucu başlıkları (sayfaya erişilemedi, [D]): https://sportskeeda.com/roblox-news/gym-league-update-12-arm-wrestle-minigame-trainer-rework , https://www.sportskeeda.com/roblox-news/news-gym-league-update-11-trainers-private-servers , https://sportskeeda.com/roblox-news/gym-star-simulator-update-8-world-6-halloween-pets

**Yerel (kendi) referanslar:** `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun\CLAUDE.md`, `assets/cover/UPLOAD/ANA_KAPAK_beginner_legend_1920x1080.png`, `assets/cover/UPLOAD/00_SIMGE_512x512.png`, `assets/cover/UPLOAD/OYUN_ADI_VE_ACIKLAMA.txt`, `src/shared/Config.luau` (pass ve ürün fiyatları).
