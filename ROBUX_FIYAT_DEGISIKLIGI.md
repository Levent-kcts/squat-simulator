# Robux fiyat indirimi 2 (2026-10-22): iz ve aura ürünleri, Creator Hub'da güncellenecek

**DURUM: OYUNDA (Config.luau) YAPILDI, Creator Hub'da BEKLİYOR.** Sahibi 'iz ve aura Robux fiyatlarını orta bir adımla düşür, simülatör değerlerine kadar değil, yarı yolda' dedi.
Neden: hızlı oyun dengesiyle (2026-10-20) Win ödülleri x2 oldu ve oyun kısaldı; tools/simulate.py 'Robux değeri' (Win ile almanın oyun süresi x dakika başı kur) üst iz/auraları çok daha ucuz gösteriyor
(ör. Rainbow Aura 28, Rainbow Legend 21). Yeni fiyat = eski fiyatla simülatör değerinin yaklaşık ORTASI, tam sayı, aile içinde artan sırada; en az 9 R$ kalır. pricetest (Win paketi sepeti en çok x1.3, artan sıra) geçti.
Creator Hub > oyun > Monetization (Para Kazanma) > Developer Products > ürün > Price. Ürün kimlikleri ve adları DEĞİŞMEDİ, sadece fiyat. Güncellenene kadar Roblox'un satın alma penceresindeki (gerçek) fiyat geçerlidir.

| Tür | Ürün | Product ID | Eski | YENİ |
|---|---|---|---|---|
| Trail | Brick Dust | 3717469051 | 9 | **9** | (aynı)
| Trail | Sweat Drops | 3717469165 | 12 | **10** |
| Trail | Protein Powder | 3717469247 | 15 | **12** |
| Trail | Brick Confetti | 3717469350 | 19 | **14** |
| Trail | Pet Paws | 3717469457 | 22 | **15** |
| Trail | Win Trophies | 3717469540 | 25 | **18** |
| Trail | Muscle Power | 3717469639 | 29 | **21** |
| Trail | Kick Sparks | 3717469790 | 35 | **25** |
| Trail | Rainbow Legend | 3717470574 | 45 | **33** |
| Aura | Red Aura | 3717470773 | 9 | **9** | (aynı)
| Aura | Green Aura | 3717470881 | 12 | **10** |
| Aura | Blue Aura | 3717470983 | 15 | **12** |
| Aura | Purple Aura | 3717471055 | 25 | **17** |
| Aura | Gold Aura | 3717471158 | 49 | **33** |
| Aura | Rainbow Aura | 3717471243 | 85 | **55** |

Değişecek ürün sayısı: 13 (Brick Dust ve Red Aura zaten 9).

---

# Robux fiyat indirimi (2026-10-14): Creator Hub'da güncellenecekler

**DURUM (2026-10-16): YAPILDI.** Sahibi tam yetki verdi; Claude Creator Hub'da 6 game pass + 33 Developer Product'ın fiyatını ve 9 iz ürününün adını değiştirdi, iki liste sayfasından tek tek doğrulandı (hepsi aşağıdaki YENİ değerlerde). Oyunda gösterilen fiyatlar (Config.luau) ile Roblox'taki gerçek fiyatlar artık aynı. Kullanılmayan eski 'VIP' Developer Product'ı (3717471559) 2026-10-17'de SATIŞTAN KALDIRILDI (Roblox ürün silmeye izin vermez; VIP game pass'tir). Developer Product GÖRSELLERİ: 6 game pass'in görseli zaten vardı; 34 Developer Product'ın görseli 2026-10-17'de Claude tarafından Claude in Chrome ile YÜKLENDİ ve her ürün sayfasından tek tek doğrulandı (kaynaklar `assets/cover/UPLOAD/URUN_GORSELLERI/`: izler ve auralar ortak Trails/Auras simgesi, +Power ve Double Offline bacak kası simgesi; Roblox moderasyonundan sonra satın alma penceresinde görünür). Starter Pack ürünü de OLUŞTURULDU ve oyuna bağlandı (ID 3718993924, 49 R$, Managed pricing kapalı).

Sahibi 14 Ekim 2026'da "fiyatları düşürelim, her şeyin" dedi (rakipler çok ucuz: +1 Muscle to Break Walls'ta Auto Click 37, Auto Rebirth 19, x2 Wins 79 R$).
Oyundaki GÖSTERİLEN fiyatlar (Config.luau) güncellendi; **gerçek fiyatı Creator Hub'daki ürün belirler**, bu yüzden aşağıdaki ürünlerin fiyatını orada da değiştirmelisin.
Güncelleyene kadar oyunda yazan fiyat ile Roblox'un satın alma penceresindeki fiyat farklı görünür (Roblox'un gösterdiği gerçek fiyat geçerli olur).

- Geliştirici ürünleri: Creator Hub > oyun > Monetization (Para Kazanma) > Developer Products > ürün > Price.
- Game pass'ler: Monetization > Passes > pass > Price.
- İz (trail) ürünlerinin **adlarını** da yeni adlarla değiştir (aşağıda ayrı tablo).
- Ürün kimlikleri (ID) DEĞİŞMEDİ; sadece fiyat/ad.
- Kural: hiçbir ürün 15 R$'nin altında değil (iz/aura 9'dan başlar); tüm fiyatlar küçülürken sıralama korundu (pahalı ürün her zaman daha güçlü).

## Game pass'ler (6)
| Pass | Eski | YENİ |
|---|---|---|
| Auto Click | 149 | **49** |
| Egg Auto Open | 199 | **59** |
| Egg Multi Open | 249 | **99** |
| VIP (2x Win pedi) | 149 | **99** |
| Coach Prism (x250 ped) | 199 | **129** |
| Coach Shadow (x999 ped) | 299 | **199** |

## Developer Product: paketler, iksirler, diğerleri (18)
| Ürün | Eski | YENİ |
|---|---|---|
| Pet Space (+25 slot) | 79 | **49** |
| +1K Power | 25 | **15** |
| +10K Power | 75 | **39** |
| +100K Power | 149 | **99** |
| Win Pack | 59 | **35** |
| Mega Win Pack | 149 | **99** |
| Luck Potion 15 dk | 49 | **29** |
| Luck Potion 60 dk | 129 | **75** |
| Muscle Potion 15 dk | 39 | **25** |
| Muscle Potion 60 dk | 99 | **59** |
| Wins Potion 15 dk | 39 | **25** |
| Wins Potion 60 dk | 99 | **59** |
| Rainbow Potion 15 dk | 79 | **49** |
| Rainbow Potion 60 dk | 149 | **99** |
| Rebirth SKIP | 119 | **59** |
| Offline DOUBLE IT | 29 | **19** |
| Gifts Unlock Next | 49 | **29** |
| Gifts Unlock All | 149 | **79** |

## Developer Product: iz (trail) ürünleri (9): AD + FİYAT
| Kimlik | Yeni ad | Eski ad | Eski fiyat | YENİ fiyat |
|---|---|---|---|---|
| trail:red | Brick Dust | Red Trail | 15 | **9** |
| trail:orange | Sweat Drops | Orange Trail | 20 | **12** |
| trail:yellow | Protein Powder | Yellow Trail | 25 | **15** |
| trail:green | Brick Confetti | Green Trail | 30 | **19** |
| trail:cyan | Pet Paws | Cyan Trail | 35 | **22** |
| trail:blue | Win Trophies | Blue Trail | 45 (ya da 40) | **25** |
| trail:purple | Muscle Power | Purple Trail | 60 (ya da 50) | **29** |
| trail:pink | Kick Sparks | Pink Trail | 75 (ya da 60) | **35** |
| trail:rainbow | Rainbow Legend | Rainbow Trail | 110 (ya da 75) | **45** |

## Developer Product: aura ürünleri (6)
| Kimlik | Ad | Eski | YENİ |
|---|---|---|---|
| aura:red | Red Aura | 15 | **9** |
| aura:green | Green Aura | 20 | **12** |
| aura:blue | Blue Aura | 25 | **15** |
| aura:purple | Purple Aura | 40 | **25** |
| aura:gold | Gold Aura | 85 | **49** |
| aura:rainbow | Rainbow Aura | 145 | **85** |

Toplam: 6 pass + 18 + 9 + 6 = 39 ürün. En çok satan 6 pass'i ve Win/iksir paketlerini önce güncelle, iz/aura'lar sonra.

## YENİ ÜRÜN: Başlangıç Paketi (Starter Pack), 49 R$
Kod hazır ama ürün YOK: Creator Hub > Monetization > Developer Products > Create: ad **Starter Pack**, fiyat **49**, açıklama `One-time Starter Pack: 2 Rainbow Potions (15 min), 1 Luck Potion (60 min) and +25 pet slots.` Ürünün ID'sini bana ver (ya da robux_ids.txt'e `shop:starterPack=ID` yazıp `python tools/set_robux_ids.py robux_ids.txt`). ID girilene kadar Shop'ta kartı görünür ama basınca 'coming soon' der. Tek seferlik: alınca kart Shop'tan kalkar, sayaç/baskı yok.

## Neden bu fiyatlar
- Rakipler 19-79 R$ bandında yardımcı pass satıyor; bizimki 149-249'du (research/03, 01).
- Giriş fiyatı (en ucuz ürün) 9-15 R$: ilk satın almanın bariyeri düşük.
- Kurallar korunuyor (pricetest): Win paketiyle alınabilecek iz/aura sepeti paket fiyatının 1,3 katını geçmez (paket yoldan almak doğrudan Robux'tan çok ucuz olmasın), 60 dk iksir dakikası ucuz, Rainbow üç tekil iksirden ucuz, Gifts "Unlock All" iksirlerin toplamından ucuz değil.
- Gelir kaybı küçük nüfusta önemsiz; amaç ilk satın almayı ve harcama günlerini (Roblox'un öneri sinyali) artırmak.
