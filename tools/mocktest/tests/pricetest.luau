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
