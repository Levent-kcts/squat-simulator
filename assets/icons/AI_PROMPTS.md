# Squat Simulator: simge görselleri için yapay zekâ promptları

Referans üslup: `assets/icons/reference/game-icon-set.png` (sahibin verdiği "game-icon-set" görseli; AI aracına EKLE).
Gelen görselleri `assets/icons/new/` klasörüne koy (ya da sohbete at). Dosya adları aşağıdaki gibi olsun.
Claude arka planı temizler, 512x512'ye küçültür, oyuna bağlar; sonra Studio'da Image olarak yüklenir ve ID'ler Config.Icons'a yazılır.

## 1) ANA ÜSLUP PROMPTU (her görselde ilk bu, sonra konu satırı)

```
Single game UI icon for a mobile Roblox simulator game, in the exact style of the attached reference sheet: 2D hand-painted cartoon vector look, chunky rounded shapes, soft smooth gradients (lighter at the top-left, darker at the bottom-right), a thin outline in a darker tone of the object's own color (never pure black), glossy white highlight streaks, a few small soft sparkle accents, rich saturated candy colors, toy-like and playful. NOT a 3D render, NOT realistic, NOT pixel art, NOT flat minimal. Exactly one object, centered, filling about 80% of a square 1:1 canvas (1024x1024), fully isolated on a TRANSPARENT background (if transparency is not possible: a plain pure white background, no floor, no ground shadow, no frame, no border, no badge or circle behind it). Light comes from the top-left. Absolutely no text, letters, numbers or watermark anywhere. Keep the same style, outline weight, lighting and level of detail as every other icon in this set.
```

## 2) KONU SATIRLARI (dosya adı → konu)

Shop ve Win:

- `trophy.png`: A shiny golden champion trophy cup with two curved handles and a big cream-colored star on the cup, standing on a small violet-blue square plinth with a blank gold nameplate (no text). Warm gold gradients from yellow to orange. Meaning: the "Wins" currency.
- `shop_vip.png`: A royal golden crown with three tall points, round ball tips (a pink-red ruby ball on the middle point, white pearls on the side points), a wide band set with one big red ruby in the center, two blue sapphires and two tiny green emeralds, small sparkles. Meaning: VIP pass.
- `shop_petspace.png`: A chunky cute red adventure backpack seen from the front, dark teal carry handle on top, darker red top flap, two yellow straps with white buckles, two side pockets, and a front pocket with a round white badge showing a red pet paw print. Meaning: more pet slots.
- `shop_winpack.png`: A plump orange-tan cloth money sack tied with a brown rope (two rope ends hanging), a small golden trophy cup sticking out of the open mouth, a round gold medallion with an orange star on its belly, two shiny gold coins with stars resting at its base. Meaning: small pack of Wins.
- `shop_winpack_big.png`: An open wooden treasure chest with gold-plated bands and a gold keyhole lock, overflowing with a heap of gold coins, colorful gems (red, green, blue, purple) and a large golden trophy cup rising from the pile, sparkles around. Clearly bigger and richer than the money sack. Meaning: mega pack of Wins.

İksirler (hepsi aynı şişe şekli ve boyutu; referanstaki şişeler gibi):

Ortak şişe: A round-bottom glass potion flask with a short neck, thick glass with a soft lavender tint and a glossy highlight, a wooden cork, a rope wrapped around the neck with a hanging round parchment tag that shows a small symbol (no text), and liquid with a wavy surface and a few bubbles inside.

- `potion_luck.png`: [ortak şişe] bright green liquid, a four-leaf clover on the tag. Meaning: 2x egg luck.
- `potion_muscle.png`: [ortak şişe] red-orange liquid, a dumbbell on the tag. Meaning: 2x leg muscle.
- `potion_wins.png`: [ortak şişe] golden-yellow liquid, a small gold trophy on the tag. Meaning: 2x Wins.
- `potion_rainbow.png`: [ortak şişe] liquid in smooth rainbow bands (red, orange, yellow, green, blue, purple), a few extra sparkles, a gold star on the tag. Meaning: all three boosts at once.
- `potion_auto.png`: [ortak şişe] glowing electric-blue liquid with a few cyan sparkles, a white mouse cursor arrow with three small yellow click rays around its tip on the tag. Meaning: free Auto Click for 30 minutes (Auto Click Potion, 2026-10-13; oyunda Config.Icons.Potions.auto, JOBS tablosuna 'potion_auto' satırı ekle, 'potions' ortak ölçek grubu).

Power Hour (2026-10-16; oyunda Config.Icons.PowerHour, sol alttaki rozet + ekrandan geçen simge; JOBS tablosuna 'powerhour' satırı ekle). BU SİMGEDE YAZI VAR: ana üsluptaki 'no text' cümlesi yerine aşağıdaki tam promptu kullan:

- `powerhour.png`: (tam prompt sohbette verildi; şimşek toy brick'lerden, sağ altta 'x2' rozeti)

Ek (şu an emoji; istersen yaptır):

- `quests.png`: A rolled parchment quest scroll tied with a red ribbon and a red wax seal, a tiny green check mark on it. Meaning: daily quests.
- `index.png`: A thick closed storybook with blue leather cover, gold corners, and a big golden paw print on the cover, a red ribbon bookmark hanging out. Meaning: pet collection index.
- `stats.png`: Three rising colorful bars (green, yellow, orange) of a bar chart with a small upward arrow above them. Meaning: statistics.
- `jackpot.png`: One big sparkling cyan-blue diamond with clean facets and a bright highlight, small sparkles. Meaning: wheel jackpot prize.
- `pet.png`: A cute pink pet paw print (one big pad and four toe beans) on a rounded gold-rimmed badge shape. Meaning: wheel pet prize.

## 3) İPUÇLARI

- Önce referans görseli ekleyip ANA ÜSLUP promptunu yapıştır, aynı sohbetten sırayla konu satırlarını gönder (üslup tutarlı kalır). Her konu için 3-4 seçenek üretip en iyisini seç.
- Aracın şeffaf arka planı yoksa beyaz arka planlı olsun, Claude keser. Gölge, zemin, çerçeve, daire olmasın.
- Yazı/rakam olmasın (oyun yazıyı kendisi basar). Kare (1:1) ve en az 1024x1024 iste.
- Menü simgeleri (Shop, Rebirth, Settings, Backpack, Pets, Gifts, Trails, Auras, Click, bacak) sahibin kendi görselleridir, yeniden yaptırmaya gerek yok.
