local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")
local Catalog = require("./Catalog")
PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Tester2"
player.UserId = 777
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
local ls = player:FindFirstChild("leaderstats")

local failures = 0
local function try(label, fn, ...)
	local ok, a, b, c = pcall(fn, ...)
	if not ok then
		failures += 1
		print("ERROR in", label, a)
	else
		print(label, a, b)
	end
	return a, b, c
end

-- DEV komutları (DevPanel listesi)
local commands = {
	{ "AddLevel", 10 }, { "MaxLevel" }, { "AddRebirth" }, { "AddRebirth", 10 }, { "AddWins", 100 }, { "AddWins", 1000000 },
	{ "AddMuscle", 1000 }, { "AddMuscle", 10000000 }, { "AllShoes" }, { "AllSkins" }, { "FreePet" }, { "FreeCats" },
	{ "DiscoverAll" }, { "BreakStage" }, { "TeleportToWalls" }, { "GiftTime", 10 }, { "FakeFriends", 3 }, { "FakeFriends", 0 },
	{ "SimulateOffline", 1 }, { "SimulateOffline", 8 }, { "ShowOffline" }, { "ClearOffline" }, { "QuestsComplete" }, { "QuestsReset" },
}
for _, cmd in commands do
	try("dev " .. cmd[1], PlayerStats.dev, player, cmd[1], cmd[2])
end

-- Mağaza ve envanter
ls:FindFirstChild(Config.StatWins).Value = 10000000
for _, item in Config.Items do
	try("buyItem " .. item.id, PlayerStats.buyItem, player, item.id)
end
for _, skin in Config.Skins do
	try("buySkin " .. skin.id, PlayerStats.buySkin, player, skin.id)
end
for _, trail in Config.Trails do
	try("buyTrail " .. trail.id, PlayerStats.buyTrail, player, trail.id)
	try("equipTrail " .. trail.id, PlayerStats.equipTrail, player, trail.id)
end
for _, aura in Config.Auras do
	try("buyAura " .. aura.id, PlayerStats.buyAura, player, aura.id)
end
for _, egg in Config.Eggs do
	try("hatch " .. egg.id, PlayerStats.hatchEgg, player, egg.id, 10)
end
try("equipBest", PlayerStats.equipBestPets, player)
try("unequipAll", PlayerStats.unequipAllPets, player)
local firstPet = string.match(player:GetAttribute("OwnedPets") or "", "[^,]+")
if firstPet then
	try("equipPet", PlayerStats.equipPet, player, firstPet)
	try("toggleAutoDelete", PlayerStats.toggleAutoDelete, player, firstPet)
	try("deletePet", PlayerStats.deletePet, player, firstPet)
end
try("fuseAll", PlayerStats.fuseAllPets, player)
for index = 1, #Config.GiftRewards do
	try("claimGift " .. index, PlayerStats.claimGift, player, index)
end
try("claimOffline", PlayerStats.claimOffline, player)
try("setSetting", PlayerStats.setSetting, player, "SfxOn", false)
try("setMusicLevel", PlayerStats.setMusicLevel, player, 5)
try("rebirth", PlayerStats.rebirth, player, true)
try("addWin", PlayerStats.addWin, player, 5)
try("addTap", PlayerStats.addTap, player)
try("addMuscle", PlayerStats.addMuscle, player, 1)
try("processPurchase skip", PlayerStats.processPurchase, player, "r1", { kind = "skip" })
try("processPurchase wins", PlayerStats.processPurchase, player, "r2", { kind = "wins", amount = 100 })
try("dev Reset", PlayerStats.dev, player, "Reset")
S.events.PlayerRemoving(player)
print("failures:", failures)
