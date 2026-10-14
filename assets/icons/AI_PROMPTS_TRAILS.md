# Trail (iz) simgeleri: SIFIRDAN yapay zekâ promptları

Neden: trail kartları şimdiye kadar oyundaki hazır simgeleri (tuğla, pati, kupa, bacak kası) yeniden kullanıyordu; hepsi birbirine benziyordu. Her iz için kendine ÖZEL bir simge çiziliyor.
Referans: `assets/icons/reference/game-icon-set.png` (AI aracına EKLE). Gelen görselleri `assets/icons/new/` içine koy (dosya adları aşağıdaki gibi); Claude arka planı temizler (`tools/icons/cutout.py` JOBS tablosuna `trail_*` satırları), sen Studio'ya yüklersin, ID'ler `Config.Trails[].icon` yerine yeni `Config.Icons.Trail_<id>` anahtarlarına yazılır.

## 1) ANA ÜSLUP PROMPTU (her görselde ilk bu)

```
Single game UI icon for a mobile Roblox simulator game, in the exact style of the attached reference sheet: 2D hand-painted cartoon vector look, chunky rounded shapes, soft smooth gradients (lighter at the top-left, darker at the bottom-right), a thin outline in a darker tone of the object's own color (never pure black), glossy white highlight streaks, a few small soft sparkle accents, rich saturated candy colors, toy-like and playful. NOT a 3D render, NOT realistic, NOT pixel art, NOT flat minimal. The icon shows a MOTION TRAIL: the main object at the front (right side) with a curved, tapering, glowing streak of its own particles flowing behind it to the left, so it clearly reads as "a trail effect". Exactly one composition, centered, filling about 80% of a square 1:1 canvas (1024x1024), fully isolated on a TRANSPARENT background (if transparency is not possible: plain pure white, no floor, no shadow, no frame, no badge or circle behind). Light from the top-left. Absolutely no text, letters, numbers or watermark. Same outline weight, lighting and detail level as every other icon in this set.
```

## 2) KONU SATIRLARI (dosya adı: konu)

- `trail_red.png` (Brick Dust): A chunky red-orange toy brick (2x2, four studs) with a swirl of crumbling brick dust and tiny brick fragments streaming behind it, warm terracotta and coral tones.
- `trail_orange.png` (Sweat Drops): A big glossy blue water drop with a determined little shine, with a stream of smaller sweat droplets and a few splash dots flying behind it, cyan to deep blue gradient.
- `trail_yellow.png` (Protein Powder): A small tub of protein powder with a scoop (blank label, no text), a golden-cream powder cloud puffing behind it with tiny gold sparkles, soft yellow and cream tones.
- `trail_green.png` (Brick Confetti): Four tumbling colored toy bricks (red, yellow, green, blue) as a confetti burst with a rainbow-ish ribbon of small bricks and stars trailing behind, bright candy colors.
- `trail_cyan.png` (Pet Paws): A chubby round cartoon paw print (one big pad and four toe beans) in turquoise, with a line of three smaller fading paw prints walking away behind it, little hearts as sparkles.
- `trail_blue.png` (Win Trophies): A shiny small golden trophy cup flying forward, with a spray of gold coins, tiny stars and a golden glow streak behind it, gold to orange gradient with a hint of blue-violet shadow.
- `trail_purple.png` (Muscle Power): A flexed cartoon bicep arm in violet-tinted skin-neutral fantasy color (purple energy aura, NOT a realistic skin tone), with crackling purple energy bolts and power rings streaming behind, glowing violet and magenta.
- `trail_pink.png` (Kick Sparks): A sneaker mid-kick with a pink-white impact star on its toe, a fan of pink and orange sparks and small flame licks flying behind, hot pink to orange gradient.
- `trail_rainbow.png` (Rainbow Legend): A glowing white-gold legendary star with small wings, a wide flowing rainbow ribbon (red, orange, yellow, green, blue, purple) streaming behind it with sparkles and tiny hearts, the richest and most detailed icon of the set.
- `trail_pumpkin.png` (Pumpkin Patch, Halloween event trail): A cute carved jack-o-lantern pumpkin with a glowing yellow smile, with orange embers, purple ghost-smoke wisps and tiny stars trailing behind, orange and purple palette.

Hepsinde aynı kamera açısı, aynı kontur kalınlığı ve ses/boyut dengesi olsun; iz akışı SOLA doğru (nesne sağda). Gelince bana söyle, kartlara bağlarım.
