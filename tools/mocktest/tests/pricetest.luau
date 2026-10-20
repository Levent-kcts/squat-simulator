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
	if sku.forSale ~= false then -- (Auto Click Potion satılmaz: fiyatı yok)
		add("Potion " .. sku.id, sku.robux)
	end
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
local fixedPotions = 0
for _, potion in Config.Potions.List do
	if potion.fixedMinutes then
		-- Sabit süreli, SATILMAYAN iksir (Auto Click Potion): tek ürün, fiyatı/Robux ürünü yok
		fixedPotions += 1
		local id = potion.id .. potion.fixedMinutes
		local sku = Catalog.PotionSkuById[id]
		assert(sku and sku.forSale == false and sku.robux == nil and sku.productId == nil, "satılmayan iksir ürünü fiyatsız olmalı: " .. id)
		assert(potion.forSale == false and potion.fixedMinutes == Config.Potions.AutoMinutes and potion.id == "auto", "sabit süreli iksir Auto Click Potion olmalı")
		seen[id] = true
	else
		for _, minutes in Config.Potions.Durations do
			local id = potion.id .. minutes
			assert(Catalog.PotionSkuById[id], "iksir ürünü yok: " .. id)
			assert(Catalog.PotionSkuById[id].forSale ~= false, "satılan iksir ürünü satışta olmalı: " .. id)
			assert(not seen[id])
			seen[id] = true
		end
	end
end
assert(fixedPotions == 1, "tam bir sabit süreli (Auto Click) iksir olmalı")
local skuCount = 0
for _ in Catalog.PotionSkuById do
	skuCount += 1
end
assert(skuCount == (#Config.Potions.List - fixedPotions) * #Config.Potions.Durations + fixedPotions, "iksir ürün sayısı: " .. skuCount)

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
assert(Catalog.potionSkuFor("boostAuto", Config.Potions.AutoMinutes) == "auto30", "Auto Click Potion (görev bonusu) ürün değil")
print("prices ok, highest:", highest, "potion skus:", skuCount)
print("DONE")

-- Fiyat dengesi (2026-10-10, sahibi 'gereksiz ucuz olanları değiştirelim, yine çok pahalı olmasın' dedi): hiçbir Robux ürünü 25'in altında olmasın, aileler zayıftan güçlüye pahalılaşsın, uzun iksir dakika başına ucuz kalsın
for _, price in prices do
	local cosmetic = string.sub(price.name, 1, 6) == "Trail " or string.sub(price.name, 1, 5) == "Aura "
	local floor = if cosmetic then Config.WinValue.Floor else 15 -- iz ve aura'lar Win'in Robux değerine göre (WinValue), erken olanlar en az Floor
	assert(price.value >= floor, `{price.name}: {price.value} Robux gereksiz ucuz (en az {floor})`)
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
	if not potion.fixedMinutes then
		local short, long = potionPrice[potion.id .. 15], potionPrice[potion.id .. 60]
		assert(short and long and long > short, potion.id .. ": 60 dk iksir 15 dk'dan pahalı olmalı")
		assert(long / 60 < short / 15, potion.id .. ": 60 dk iksir dakika başına ucuz olmalı (indirim)")
	end
end
-- Rainbow iksiri üç tekil iksirin toplamından ucuz olmalı (paket indirimi)
assert(potionPrice.rainbow15 < potionPrice.luck15 + potionPrice.muscle15 + potionPrice.wins15, "Rainbow 15 dk paket indirimi")
assert(potionPrice.rainbow60 < potionPrice.luck60 + potionPrice.muscle60 + potionPrice.wins60, "Rainbow 60 dk paket indirimi")

-- WIN fiyat merdiveni (2026-10-10): izler ve aura'lar zayıftan güçlüye pahalılaşır, her biri oyunun bir aşamasının TEK sefer ödülüyle alınabilir ve en pahalısı bile 20. aşama ödülünün altındadır (alınabilir kalır);
-- aura'lar (kalıcı çarpan) oyunun BAŞINA çekildi (sahibi: 'oyunun çok ileri safhasında olmasın, ilki zayıf ve 1 saat gerektiriyor'): ilk aura 4. aşamada (~5 dk) ve en az x1.5, hepsi 15. aşamaya kadar, çarpanlar artar
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
	if lastPrice == 0 then
		assert(stage <= 5, "ilk iz oyunun başında (<= 5. aşama, ~6 dk) alınmalı: aşama " .. stage)
	end
	lastStage, lastPrice = stage, trail.winPrice
end
assert(lastStage <= 16, "rainbow iz de oyunun ilk yarısında alınmalı (<= 16. aşama, sahibi izleri de erkene istedi): aşama " .. lastStage)
lastStage, lastPrice = 0, 0
local lastMult = 1
for index, aura in Config.Auras do
	assert(aura.winPrice > lastPrice, "aura Win fiyatları artmalı: " .. aura.id)
	local stage = stageFor(aura.winPrice)
	assert(stage and stage > lastStage, "aura hedef aşaması ilerlemeli (her aura farklı aşama): " .. aura.id)
	assert(aura.mult > lastMult, "aura çarpanı artmalı: " .. aura.id)
	if index == 1 then
		assert(stage <= 4, "ilk aura oyunun başında (<= 4. aşama, ~5 dk) alınmalı: aşama " .. stage)
		assert(aura.mult >= 2, "ilk aura belirgin güçlü olmalı (>= x2): " .. aura.mult)
	end
	lastStage, lastPrice, lastMult = stage, aura.winPrice, aura.mult
end
assert(lastStage <= 16, "son aura oyunun ilk yarısında alınmalı (<= 16. aşama): aşama " .. lastStage)
assert(lastMult == 14, "son aura çarpanı x14 kalmalı (2026-10-20 hızlı oyun dengesi: x8 -> x14; tam sayı çarpanlar)")

-- WIN'İN ROBUX DEĞERİ (2026-10-10, sahibi 'oyuncu sadece Win paketi alıp çok daha ucuza istediğini alamasın' dedi): Win paketinin içindeki Win ile BİR SEFERDE alınabilecek iz/aura sepetinin doğrudan Robux toplamı,
-- paket fiyatının MaxBasketRatio katını geçmemeli (yoksa paket yoldan almak doğrudan Robux'tan çok daha ucuz olur). Sepet = en pahalı alt küme (15 ürün: 2^15 olası sepet, kaba kuvvetle).
local cosmetics = {}
for _, trail in Config.Trails do
	table.insert(cosmetics, { wins = trail.winPrice, robux = trail.robuxPrice, name = "Trail " .. trail.id })
end
for _, aura in Config.Auras do
	table.insert(cosmetics, { wins = aura.winPrice, robux = aura.robuxPrice, name = "Aura " .. aura.id })
end
local packs = 0
for _, product in Config.Shop.Products do
	if product.kind == "stageWins" then
		packs += 1
		local packWins = Layout.reward(product.stage)
		local best, bestMask = 0, 0
		for mask = 0, 2 ^ #cosmetics - 1 do
			local wins, robux, bits = 0, 0, mask
			for index = 1, #cosmetics do
				if bits % 2 == 1 then
					wins += cosmetics[index].wins
					robux += cosmetics[index].robux
				end
				bits = bits // 2
			end
			if wins <= packWins and robux > best then
				best, bestMask = robux, mask
			end
		end
		assert(best <= product.robux * Config.WinValue.MaxBasketRatio, `{product.name} ({packWins} Win, {product.robux} Robux): içindeki Win ile {best} Robux'luk iz/aura sepeti alınabiliyor (sınır x{Config.WinValue.MaxBasketRatio})`)
		-- Tek tek de: pakete sığan hiçbir ürünün doğrudan fiyatı paket fiyatından yüksek olmamalı
		for _, item in cosmetics do
			if item.wins <= packWins then
				assert(item.robux <= product.robux, `{item.name}: doğrudan {item.robux} Robux, ama {product.name} {product.robux} Robux ve içine sığıyor`)
			end
		end
	end
end
assert(packs == 2, "iki Win paketi olmalı (Win Pack ve Mega Win Pack): " .. packs)

-- GIFTS ROBUX KİLİT AÇMA ADİL FİYATI (2026-10-10, sahibi 'Unlock All / Unlock Next fiyatlarını adil düzenle' dedi): ödüllerin Shop karşılığından UCUZA alınamasın.
-- Unlock Next = tek bir (en pahalı) iksir ödülünün Shop fiyatından az olmasın; Unlock All = içindeki iksirlerin Shop toplamından az olmasın ama 10 x Next'ten (toplu alım) ucuz kalsın
local potionShop = {}
for _, sku in Config.Shop.Potions do
	potionShop[sku.id] = sku.robux
end
local dearestGift, potionSum = 0, 0
for _, reward in Config.GiftRewards do
	if Catalog.PotionByKind[reward.kind] then
		local value = potionShop[Catalog.potionSkuFor(reward.kind, reward.minutes or Config.BoostMinutes)]
		assert(value, "Gifts iksirinin Shop fiyatı yok: " .. reward.kind)
		dearestGift = math.max(dearestGift, value)
		potionSum += value
	end
end
assert(Config.GiftUnlockNextRobux >= dearestGift, `Unlock Next ({Config.GiftUnlockNextRobux}) en pahalı iksir ödülünün Shop fiyatından ({dearestGift}) ucuz`)
assert(Config.GiftUnlockAllRobux >= potionSum, `Unlock All ({Config.GiftUnlockAllRobux}) iksir ödüllerinin Shop toplamından ({potionSum}) ucuz`)
assert(Config.GiftUnlockAllRobux < Config.GiftUnlockNextRobux * #Config.GiftRewards, "Unlock All, 10 kez Unlock Next'ten ucuz olmalı (toplu alım indirimi)")
assert(Config.GiftUnlockAllRobux > Config.GiftUnlockNextRobux, "Unlock All, Unlock Next'ten pahalı olmalı")
print("gift unlock prices ok:", Config.GiftUnlockNextRobux, Config.GiftUnlockAllRobux, "potion sum", potionSum)

-- ROBUX'LU ANTRENMAN PEDLERİ (2026-10-10, sahibi 'Shadow sadece Robux, Prism rebirth ya da Robux, fiyat adil olsun' dedi): game pass'ler; '150 Robux'u geçmesin' kuralının (yumurta pass'leri gibi) İSTİSNASI, çünkü pedi en baştan açmak oyunun sonunu
-- 10.2 saatten Prism ile ~2.7, Shadow ile ~1.6 saate indirir (tools/padsim.py); fiyat = kazanılan süre x 0.45-0.6 R$/dk. Prism rebirth ile de açıldığı için Shadow'dan ucuz, ikisi de makul bir üst sınırın altında.
local prismArea, shadowArea
for _, area in Config.Training.Areas do
	if area.id == "rainbow" then
		prismArea = area
	elseif area.id == "black" then
		shadowArea = area
	end
end
assert(prismArea.robux > 0 and prismArea.robux <= 400, "Coach Prism: fiyat makul olmalı (<= 400): " .. prismArea.robux)
assert(shadowArea.robux > 0 and shadowArea.robux <= 400, "Coach Shadow: fiyat makul olmalı (<= 400): " .. shadowArea.robux)
assert(shadowArea.robux > prismArea.robux, "Shadow (en güçlü, sadece Robux) Prism'den (rebirth ile de açılır) pahalı olmalı")
assert(shadowArea.mult > prismArea.mult, "Shadow çarpanı Prism'den büyük olmalı")
print("coach pad prices ok:", prismArea.robux, shadowArea.robux)
