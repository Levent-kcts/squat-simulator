-- AUTO CLICK POTION (2026-10-13): sabit 30 dk, SATILMAZ, günlük görev bonusundan ve çarktan çıkar, envantere girer (Shop > Potions > USE); Rainbow Potion bunu İÇERMEZ; kayıtlıdır.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")
local Catalog = require("./Catalog")

PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
local function itemCount(player, sku)
	return tonumber(string.match(player:GetAttribute("PotionItems") or "", sku .. ":(%d+)")) or 0
end

-- Yapılandırma: tek, sabit süreli, satılmayan iksir
local auto = Catalog.PotionById.auto
assert(auto and auto.kind == "boostAuto" and auto.attribute == "AutoBoostUntil" and not auto.rainbow, "Auto Click Potion tanımlı olmalı (Rainbow değil)")
assert(auto.forSale == false and auto.fixedMinutes == 30 and Config.Potions.AutoMinutes == 30, "sabit 30 dk ve satılmaz olmalı")
local sku = Catalog.PotionSkuById.auto30
assert(sku and sku.forSale == false and sku.robux == nil and sku.productId == nil and sku.minutes == 30, "auto30 ürünü fiyatsız olmalı (satılmaz)")

-- Çark: tam 8 dilim, ağırlık toplamı 100, bir dilim Auto Click Potion (30 dk)
local totalWeight, autoSlices = 0, 0
for _, prize in Config.Wheel.Prizes do
	totalWeight += prize.weight
	if prize.kind == "boostAuto" then
		autoSlices += 1
		assert(prize.minutes == 30 and prize.potion == "auto", "çarkta Auto Click Potion 30 dk olmalı")
	end
end
assert(#Config.Wheel.Prizes == 8 and totalWeight == 100 and autoSlices == 1, `çark: dilim {#Config.Wheel.Prizes}, ağırlık {totalWeight}, auto dilim {autoSlices}`)

-- DEV ile envantere ekleme (sabit 30 dk: 15 istense de 30'luk ürün girer) ve içme
local player = join(9501, "AutoPotion")
assert((player:GetAttribute("AutoBoostUntil") or 0) == 0, "başta etkin Auto Click Potion yok")
PlayerStats.dev(player, "PotionAuto")
assert(itemCount(player, "auto30") == 1, "PotionAuto envantere auto30 eklemeli: " .. tostring(player:GetAttribute("PotionItems")))
local now = os.time()
local ok = PlayerStats.usePotion(player, "auto30")
assert(ok == true and itemCount(player, "auto30") == 0, "iksir içilince envanterden düşmeli")
local untilTime = player:GetAttribute("AutoBoostUntil")
assert(untilTime >= now + 30 * 60 - 3 and untilTime <= now + 30 * 60 + 3, "süre 30 dk olmalı: " .. tostring(untilTime - now))
-- İkinci iksir süreyi ÜZERİNE ekler
PlayerStats.dev(player, "PotionAuto")
PlayerStats.usePotion(player, "auto30")
assert(player:GetAttribute("AutoBoostUntil") >= untilTime + 30 * 60 - 1, "ikinci iksir süreyi uzatmalı")

-- RAINBOW POTION Auto Click Potion'ı İÇERMEZ
local other = join(9502, "RainbowOnly")
PlayerStats.dev(other, "PotionRainbow")
assert(PlayerStats.usePotion(other, "rainbow15") == true)
assert(other:GetAttribute("RainbowBoostUntil") > os.time(), "Rainbow etkin olmalı")
assert((other:GetAttribute("AutoBoostUntil") or 0) <= os.time(), "Rainbow Auto Click Potion etkisi VERMEMELİ")
assert(other:GetAttribute("EggLuck") == Config.Potions.Mult, "Rainbow yine Luck verir")

-- GÜNLÜK GÖREV BONUSU: 3 görev alınınca Rainbow + Auto Click Potion envantere girer
local quester = join(9503, "Quester")
PlayerStats.dev(quester, "QuestsComplete")
for slot = 1, Config.Quests.PerDay do
	assert(select(1, PlayerStats.claimQuest(quester, slot)) == true, "görev alınmalı: " .. slot)
end
local bonusOk, bonusMessage = PlayerStats.claimQuestBonus(quester)
assert(bonusOk == true and string.find(bonusMessage, "Auto Click Potion", 1, true), "bonus mesajı Auto Click Potion'ı söylemeli: " .. tostring(bonusMessage))
assert(itemCount(quester, "rainbow15") == 1 and itemCount(quester, "auto30") == 1, "bonus Rainbow ve Auto Click Potion vermeli: " .. tostring(quester:GetAttribute("PotionItems")))
assert(string.find(quester:GetAttribute("QuestData"), "Auto Click Potion 30m", 1, true), "günlük görev penceresi bonusta Auto Click Potion'ı yazmalı")
assert(select(1, PlayerStats.claimQuestBonus(quester)) == false, "bonus bir kez alınır")

-- KAYIT: etkin iksirin bitişi kaydedilir, tekrar girişte sürer
assert(PlayerStats.saveNow(player) == true)
local record = S.datastore["Player_9501"]
assert(record and record.BoostUntil and record.BoostUntil.auto and record.BoostUntil.auto > os.time(), "etkin Auto Click Potion kaydedilmeli")
S.events.PlayerRemoving(player)
local again = join(9501, "AutoPotionAgain")
assert(again:GetAttribute("AutoBoostUntil") > os.time(), "tekrar girişte Auto Click Potion sürmeli")

-- RESET ALL iksiri de sıfırlar
PlayerStats.dev(again, "Reset")
assert((again:GetAttribute("AutoBoostUntil") or 0) <= os.time(), "Reset Auto Click Potion'ı silmeli")
print("auto potion ok")
