# Robux ürünleri: Creator Hub'da açılacaklar

Her satır için Creator Hub'da (create.roblox.com) oyunun > **Para Kazanma (Monetization) > Geliştirici Ürünleri (Developer Products)** sayfasında bir ürün aç (VIP için **Geçişler / Passes**).
Ad, açıklama ve **fiyat** tabloda yazdığı gibi olsun (oyundaki gösterilen fiyatla aynı olmalı; yumurta pass'leri hariç hiçbir fiyat 150 Robux'u geçmez; eggauto/eggtriple/eggten bilerek daha pahalıdır). Açınca ürünün ID'sini `robux_ids.txt` dosyasında ilgili satıra yaz
(ya da bana yapıştır), sonra `python tools/set_robux_ids.py robux_ids.txt` Config'e işler. Oyun Studio'da yayınlanmış olmalı, ürünler o oyuna (deneyime) ait olmalı.

Toplam: 36 ürün (31 Developer Product + 5 Game Pass).

| # | Anahtar | Tür | Ad | Fiyat (Robux) | Açıklama |
|---|---|---|---|---|---|
| 1 | `shop:petSpace25` | Developer Product | Pet Space | 49 | Adds 25 pet slots to your Pets bag. |
| 2 | `shop:power1k` | Developer Product | +1K Power | 15 | Instantly gives 1,000 squats worth of leg muscle. |
| 3 | `shop:power10k` | Developer Product | +10K Power | 49 | Instantly gives 10,000 squats worth of leg muscle. |
| 4 | `shop:power100k` | Developer Product | +100K Power | 149 | Instantly gives 100,000 squats worth of leg muscle. |
| 5 | `shop:winsSmall` | Developer Product | Win Pack | 25 | Instantly gives the Wins you earn for clearing stage 8. |
| 6 | `shop:winsBig` | Developer Product | Mega Win Pack | 99 | Instantly gives the Wins you earn for clearing stage 12. |
| 7 | `potion:luck15` | Developer Product | Luck Potion (15 min) | 29 | 2x egg luck: rare pets hatch more often. Lasts 15 minutes. |
| 8 | `potion:luck60` | Developer Product | Luck Potion (60 min) | 89 | 2x egg luck: rare pets hatch more often. Lasts 60 minutes. |
| 9 | `potion:muscle15` | Developer Product | Muscle Potion (15 min) | 19 | 2x leg muscle from every squat. Lasts 15 minutes. |
| 10 | `potion:muscle60` | Developer Product | Muscle Potion (60 min) | 59 | 2x leg muscle from every squat. Lasts 60 minutes. |
| 11 | `potion:wins15` | Developer Product | Wins Potion (15 min) | 19 | Doubles every Win you earn. Lasts 15 minutes. |
| 12 | `potion:wins60` | Developer Product | Wins Potion (60 min) | 59 | Doubles every Win you earn. Lasts 60 minutes. |
| 13 | `potion:rainbow15` | Developer Product | Rainbow Potion (15 min) | 49 | Counts as ALL potions: 2x luck, 2x muscle and 2x Wins. Lasts 15 minutes. |
| 14 | `potion:rainbow60` | Developer Product | Rainbow Potion (60 min) | 149 | Counts as ALL potions: 2x luck, 2x muscle and 2x Wins. Lasts 60 minutes. |
| 15 | `trail:red` | Developer Product | Red Trail | 9 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 16 | `trail:orange` | Developer Product | Orange Trail | 19 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 17 | `trail:yellow` | Developer Product | Yellow Trail | 29 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 18 | `trail:green` | Developer Product | Green Trail | 39 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 19 | `trail:cyan` | Developer Product | Cyan Trail | 59 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 20 | `trail:blue` | Developer Product | Blue Trail | 79 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 21 | `trail:purple` | Developer Product | Purple Trail | 99 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 22 | `trail:pink` | Developer Product | Pink Trail | 129 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 23 | `trail:rainbow` | Developer Product | Rainbow Trail | 149 | Unlocks this trail forever: leaves a colored trail and makes you run faster. |
| 24 | `aura:red` | Developer Product | Red Aura | 19 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 25 | `aura:green` | Developer Product | Green Aura | 39 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 26 | `aura:blue` | Developer Product | Blue Aura | 59 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 27 | `aura:purple` | Developer Product | Purple Aura | 89 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 28 | `aura:gold` | Developer Product | Gold Aura | 119 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 29 | `aura:rainbow` | Developer Product | Rainbow Aura | 149 | Unlocks this aura forever: multiplies your leg muscle gain. |
| 30 | `skip` | Developer Product | Rebirth Skip | 99 | Skip the level requirement and rebirth right now. |
| 31 | `double` | Developer Product | Double Offline Earnings | 19 | Doubles the offline earnings waiting for you. |
| 32 | `vip` | Game Pass | VIP | 99 | VIP pad: the Win button gives 2x Wins every stage. Permanent. |
| 33 | `autoclick` | Game Pass | Auto Click | 99 | Auto Click: your character squats and kicks for you, up to 10 clicks per second. Permanent. |
| 34 | `eggauto` | Game Pass | Auto Open | 199 | Auto Open: eggs open automatically, hands-free. Permanent. |
| 35 | `eggtriple` | Game Pass | Triple Open | 179 | Triple Open: hatch 3 eggs at once. Permanent. |
| 36 | `eggten` | Game Pass | Mega Open | 249 | Mega Open: hatch 10 eggs at once. Permanent. |

Not: en önemli ürünler (ilk açılacaklar): Pet Space, +1K / +10K / +100K Power, Win Pack, Mega Win Pack, iksirler, VIP. İz ve aura ürünleri sonra eklenebilir; ID'si boş olan ürün oyunda 'coming soon' der ve hata vermez.
