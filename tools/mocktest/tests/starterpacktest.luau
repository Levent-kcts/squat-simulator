-- BAŞLANGIÇ PAKETİ (Config.Shop.Products 'starterPack', Config.StarterPack): tek seferlik Developer Product; içerik iksirler + pet yuvası; alınınca 'StarterPackOwned' ve Shop'tan kalkar; productId 0 iken satışta değil.
local S = require("./stubs")
local Config = require("./Config")
local PlayerStats = require("./PlayerStats")

PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Buyer"
player.UserId = 9951
rawset(player, "DisplayName", "Buyer")
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
local function count(sku)
	return tonumber(string.match(tostring(player:GetAttribute("PotionItems") or ""), sku .. ":(%d+)")) or 0
end

local pack
for _, product in Config.Shop.Products do
	if product.id == "starterPack" then
		pack = product
	end
end
assert(pack and pack.kind == "starterPack" and pack.once == true and pack.robux > 0 and pack.robux <= 99, "Başlangıç Paketi tanımlı, tek seferlik ve ucuz olmalı")
assert(player:GetAttribute("StarterPackOwned") == false, "başta sahip olunmamalı")
local capacityBefore = player:GetAttribute("PetCapacity")
assert(PlayerStats.processPurchase(player, "starter-1", pack) == true, "satın alma işlenmeli")
assert(count("rainbow15") == 2 and count("luck60") == 1, "2 Rainbow 15 dk + 1 Luck 60 dk envantere girmeli: " .. tostring(player:GetAttribute("PotionItems")))
assert(player:GetAttribute("StarterPackOwned") == true, "alınınca StarterPackOwned olmalı")
if capacityBefore then
	assert(player:GetAttribute("PetCapacity") == capacityBefore + Config.StarterPack.PetSlots, "pet yuvası artmalı")
end
assert(PlayerStats.processPurchase(player, "starter-1", pack) == true and count("rainbow15") == 2, "aynı makbuz ikinci kez ödül vermemeli")
print("starter pack ok")
