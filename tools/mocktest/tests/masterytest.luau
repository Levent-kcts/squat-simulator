-- MASTERY AĞACI (Config.Mastery, PlayerStats.buyMastery): ilk rebirth'ten sonra açılır, Win ile kalıcı kademeler; power tıklama başı kası, smash duvar hasarını, fortune Win pedi ödülünü yüzde artırır; kayıtlıdır.
local S = require("./stubs")
local Config = require("./Config")
local Layout = require("./Layout")
local PlayerStats = require("./PlayerStats")

local settings = Config.Mastery
settings.Enabled = true -- test için aç (üretimde raftadır)
local function branchOf(id)
	for _, branch in settings.Branches do
		if branch.id == id then
			return branch
		end
	end
end
-- Maliyet: aşama ödülüne bağlı, kademe başına artar
for _, branch in settings.Branches do
	local previous = 0
	for level = 0, settings.MaxLevel - 1 do
		local cost = Layout.masteryCost(branch, level, settings.CostMult)
		assert(cost >= previous and cost >= 1, "maliyet artmalı: " .. branch.id .. " " .. level)
		previous = cost
	end
end

PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Master"
player.UserId = 9997
rawset(player, "DisplayName", "Master")
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
local function stat(name)
	return player:FindFirstChild("leaderstats"):FindFirstChild(name).Value
end

PlayerStats.dev(player, "AddWins", 10000000)
local okLocked, whyLocked = PlayerStats.buyMastery(player, "power")
assert(okLocked == false and string.find(whyLocked, "Rebirth", 1, true), "ilk rebirth'ten önce kilitli olmalı: " .. tostring(whyLocked))

PlayerStats.dev(player, "AddRebirth", 1)
local _, baseGain = PlayerStats.addMuscle(player)
local baseDamage = PlayerStats.getDamageMultiplier(player)
local winsBefore = stat(Config.StatWins)
local power = branchOf("power")
local cost = Layout.masteryCost(power, 0, settings.CostMult)
local ok, message = PlayerStats.buyMastery(player, "power")
assert(ok == true, "power kademe 1 alınmalı: " .. tostring(message))
assert(stat(Config.StatWins) == winsBefore - cost, "maliyet kadar Win düşmeli")
assert(string.find(tostring(player:GetAttribute("MasteryLevels")), "power:1", 1, true), "kademe yayınlanmalı: " .. tostring(player:GetAttribute("MasteryLevels")))
assert(player:GetAttribute("MasteryPower") == power.perLevel, "MasteryPower yüzde olmalı")
-- Tüm kademeleri al: power kası artırır
for _ = 2, settings.MaxLevel do
	assert(PlayerStats.buyMastery(player, "power") == true, "power kademeleri alınmalı")
end
assert(PlayerStats.buyMastery(player, "power") == false, "azami kademeden sonra alınamaz")
local _, boostedGain = PlayerStats.addMuscle(player)
assert(boostedGain >= baseGain, "power kazancı düşürmemeli: " .. baseGain .. " -> " .. boostedGain)

-- smash hasarı, fortune Win ödülünü artırır
for _ = 1, settings.MaxLevel do
	assert(PlayerStats.buyMastery(player, "smash") == true, "smash alınmalı")
	assert(PlayerStats.buyMastery(player, "fortune") == true, "fortune alınmalı")
end
local maxSmash = branchOf("smash").perLevel * settings.MaxLevel
assert(math.abs(PlayerStats.getDamageMultiplier(player) - baseDamage * (1 + maxSmash / 100)) < 1e-6, "smash hasar çarpanını yüzde artırmalı: " .. PlayerStats.getDamageMultiplier(player))
local winsNow = stat(Config.StatWins)
PlayerStats.addWin(player, 100)
local gained = stat(Config.StatWins) - winsNow
assert(gained >= 100 * (1 + branchOf("fortune").perLevel * settings.MaxLevel / 100) - 1, "fortune Win ödülünü artırmalı: " .. gained)

-- Bilinmeyen dal
assert(PlayerStats.buyMastery(player, "nope") == false, "bilinmeyen dal reddedilmeli")

-- Kayıt
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local saved = S.datastore["Player_9997"].Mastery
assert(saved and saved.power == settings.MaxLevel and saved.smash == settings.MaxLevel, "Mastery kayıtlı olmalı")
print("mastery ok")
