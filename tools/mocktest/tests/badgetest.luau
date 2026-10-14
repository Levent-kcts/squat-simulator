-- ROZETLER VE UNVANLAR (büyüme planı; Config.Badges, Config.Titles, server/Badges): id 0 iken rozet pasif; id verilince başarıda BadgeService:AwardBadge çağrılır (oturumda bir kez); unvan rebirth sayısına göre.
local S = require("./stubs")
local Config = require("./Config")
local Progression = require("./Progression")
local PlayerStats = require("./PlayerStats")

-- Unvanlar: artan eşik, ilki 0
assert(Config.Titles[1].rebirths == 0, "ilk unvan 0 rebirth'te başlamalı")
local previous = -1
for _, title in Config.Titles do
	assert(title.rebirths > previous and type(title.name) == "string" and title.color, "unvanlar artan eşikli, adlı ve renkli olmalı")
	previous = title.rebirths
end
assert(Progression.title(0).name == "Rookie" and Progression.title(1).name == "Trainee" and Progression.title(2).name == "Trainee", "rebirth 0-2 unvanı")
assert(Progression.title(10).name == "Champion" and Progression.title(24).name == "Titan" and Progression.title(25).name == "Legend" and Progression.title(999).name == "Legend", "yüksek rebirth unvanları")

-- Rozetler: tanımlı, başta pasif (id = 0)
for key, def in Config.Badges do
	assert(type(def.name) == "string" and type(def.description) == "string" and type(def.id) == "number", "rozet tanımı eksik: " .. key)
end
for _, key in { "welcome", "rebirth1", "rebirth10", "stage10", "stage20", "legendary", "mythic", "boss", "index30" } do
	assert(Config.Badges[key], "rozet tanımlı olmalı: " .. key)
end

PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end

-- 1) Hepsi pasifken hiçbir şey verilmez
local first = join(9961, "Passive")
PlayerStats.dev(first, "MaxLevel")
PlayerStats.rebirth(first, true)
assert(#S.badgesAwarded == 0, "id 0 iken rozet verilmemeli")

-- 2) id verilince: hoş geldin (girişte), First Rebirth ve Rebirth 10 (oturumda bir kez)
Config.Badges.welcome.id = 1001
Config.Badges.rebirth1.id = 1002
Config.Badges.rebirth10.id = 1003
local player = join(9962, "Active")
assert(#S.badgesAwarded == 1 and S.badgesAwarded[1].userId == 9962 and S.badgesAwarded[1].badgeId == 1001, "girişte hoş geldin rozeti verilmeli")
PlayerStats.dev(player, "MaxLevel")
PlayerStats.rebirth(player, true)
local awarded = {}
for _, entry in S.badgesAwarded do
	awarded[entry.badgeId] = (awarded[entry.badgeId] or 0) + 1
end
assert(awarded[1002] == 1 and not awarded[1003], "ilk rebirth rozeti verilmeli, Rebirth 10 değil")
PlayerStats.dev(player, "AddRebirth", 9)
PlayerStats.dev(player, "MaxLevel")
PlayerStats.rebirth(player, true)
awarded = {}
for _, entry in S.badgesAwarded do
	awarded[entry.badgeId] = (awarded[entry.badgeId] or 0) + 1
end
assert(awarded[1003] == 1 and awarded[1002] == 1, "Rebirth 10 rozeti verilmeli, ilk rebirth rozeti oturumda ikinci kez istenmemeli: " .. tostring(awarded[1002]))
print("badges ok")
