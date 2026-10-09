-- Robux fiyat kuralı (sahibi 2026-10-09: 'ucuz olsun, en pahalı şey 150 Robux'u geçmesin') ve iksir ürünleri: her iksir ödülü (çark, Gifts, görev bonusu) bir Shop ürününe karşılık gelmeli
local Config = require("./Config")
local Catalog = require("./Catalog")

local MAX_ROBUX = 150
local prices = {}
local function add(name, value)
	table.insert(prices, { name = name, value = value })
end
for _, product in Config.Shop.Products do
	add("Shop " .. product.id, product.robux)
end
for _, sku in Config.Shop.Potions do
	add("Potion " .. sku.id, sku.robux)
end
for _, trail in Config.Trails do
	add("Trail " .. trail.id, trail.robuxPrice)
end
for _, aura in Config.Auras do
	add("Aura " .. aura.id, aura.robuxPrice)
end
add("Rebirth skip", Config.Rebirth.SkipRobuxPrice)
add("Offline double", Config.Offline.DoubleRobux)
add("Auto Click pass", Config.AutoClick.Robux)
add("VIP pass", Config.VipRobux)
add("Gift unlock all", Config.GiftUnlockAllRobux)
-- (Yumurta game pass'leri [Config.EggPasses] 150 kuralının İSTİSNASIDIR: sahibi 'bu sefer 150 sınırını geç, birazcık daha pahalı olsun' dedi; sınırları eggpasstest.luau denetler: 150 < fiyat <= 400)
add("Gift unlock next", Config.GiftUnlockNextRobux)
local highest = 0
for _, price in prices do
	assert(type(price.value) == "number" and price.value > 0, price.name .. ": fiyat sayı olmalı")
	assert(price.value <= MAX_ROBUX, `{price.name}: {price.value} Robux, sınır {MAX_ROBUX}`)
	highest = math.max(highest, price.value)
end

-- İksir ürünleri: her iksir x her süre için tam bir ürün; kimlikler benzersiz
local seen = {}
for _, potion in Config.Potions.List do
	for _, minutes in Config.Potions.Durations do
		local id = potion.id .. minutes
		assert(Catalog.PotionSkuById[id], "iksir ürünü yok: " .. id)
		assert(not seen[id])
		seen[id] = true
	end
end
local skuCount = 0
for _ in Catalog.PotionSkuById do
	skuCount += 1
end
assert(skuCount == #Config.Potions.List * #Config.Potions.Durations, "iksir ürün sayısı: " .. skuCount)

-- Çark / Gifts / görev bonusundan çıkan iksirler envantere girer: kind + süre bir ürüne denk gelmeli
for _, prize in Config.Wheel.Prizes do
	if Catalog.PotionByKind[prize.kind] then
		assert(Catalog.potionSkuFor(prize.kind, prize.minutes), `çark iksiri ürün değil: {prize.kind} {prize.minutes}`)
	end
end
for _, reward in Config.GiftRewards do
	if Catalog.PotionByKind[reward.kind] then
		assert(Catalog.potionSkuFor(reward.kind, reward.minutes or Config.BoostMinutes), `Gifts iksiri ürün değil: {reward.kind}`)
	end
end
assert(Catalog.potionSkuFor("boostRainbow", Config.Quests.BonusBoostMinutes), "görev bonusu iksiri ürün değil")
print("prices ok, highest:", highest, "potion skus:", skuCount)
print("DONE")

-- Fiyat dengesi (2026-10-10, sahibi 'gereksiz ucuz olanları değiştirelim, yine çok pahalı olmasın' dedi): hiçbir Robux ürünü 25'in altında olmasın, aileler zayıftan güçlüye pahalılaşsın, uzun iksir dakika başına ucuz kalsın
for _, price in prices do
	assert(price.value >= 25 or string.find(price.name, "Gift unlock next", 1, true), `{price.name}: {price.value} Robux gereksiz ucuz (en az 25)`)
end
local previous = 0
for _, trail in Config.Trails do
	assert(trail.robuxPrice > previous, "iz fiyatları artmalı: " .. trail.id)
	previous = trail.robuxPrice
end
previous = 0
for _, aura in Config.Auras do
	assert(aura.robuxPrice > previous, "aura fiyatları artmalı: " .. aura.id)
	previous = aura.robuxPrice
end
local potionPrice = {}
for _, sku in Config.Shop.Potions do
	potionPrice[sku.id] = sku.robux
end
for _, potion in Config.Potions.List do
	local short, long = potionPrice[potion.id .. 15], potionPrice[potion.id .. 60]
	assert(short and long and long > short, potion.id .. ": 60 dk iksir 15 dk'dan pahalı olmalı")
	assert(long / 60 < short / 15, potion.id .. ": 60 dk iksir dakika başına ucuz olmalı (indirim)")
end
-- Rainbow iksiri üç tekil iksirin toplamından ucuz olmalı (paket indirimi)
assert(potionPrice.rainbow15 < potionPrice.luck15 + potionPrice.muscle15 + potionPrice.wins15, "Rainbow 15 dk paket indirimi")
assert(potionPrice.rainbow60 < potionPrice.luck60 + potionPrice.muscle60 + potionPrice.wins60, "Rainbow 60 dk paket indirimi")

-- WIN fiyat merdiveni (2026-10-10): izler ve aura'lar zayıftan güçlüye pahalılaşır, her biri oyunun bir aşamasının TEK sefer ödülüyle alınabilir ve en pahalısı bile 20. aşama ödülünün altındadır (alınabilir kalır);
-- aura'lar (kalıcı çarpan) aynı sıradaki izden pahalı ya da eşit hedef aşamaya konur ve rainbow aura son aşamalarda (>= 17) alınır
local Layout = require("./Layout")
local function stageFor(price)
	for stage = 1, Config.Wall.Count // Config.Wall.GroupSize do
		if Layout.reward(stage) >= price then
			return stage
		end
	end
	return nil
end
local lastStage, lastPrice = 0, 0
for _, trail in Config.Trails do
	assert(trail.winPrice > lastPrice, "iz Win fiyatları artmalı: " .. trail.id)
	local stage = stageFor(trail.winPrice)
	assert(stage and stage >= lastStage, "iz hedef aşaması azalmamalı: " .. trail.id)
	lastStage, lastPrice = stage, trail.winPrice
end
assert(lastStage >= 17 and lastStage <= 19, "rainbow iz oyunun sonlarında alınmalı: aşama " .. lastStage)
lastStage, lastPrice = 0, 0
for _, aura in Config.Auras do
	assert(aura.winPrice > lastPrice, "aura Win fiyatları artmalı: " .. aura.id)
	local stage = stageFor(aura.winPrice)
	assert(stage and stage > lastStage, "aura hedef aşaması ilerlemeli (her aura farklı aşama): " .. aura.id)
	lastStage, lastPrice = stage, aura.winPrice
end
assert(lastStage >= 18 and lastStage <= 19, "rainbow aura 18-19. aşamada alınmalı (oyunun sonu 20): aşama " .. lastStage)
