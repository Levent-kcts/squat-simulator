-- GRUP ÖDÜLÜ (server/GroupReward, Config.Group): Id = 0 iken pasif; grup üyesi bir kez iksir alır.
local S = require("./stubs")
local Config = require("./Config")
local PlayerStats = require("./PlayerStats")
local GroupReward = require("./GroupReward")

assert(Config.Group.Id == 0, "grup kimliği başta 0 (pasif) olmalı")
PlayerStats.init()
GroupReward.init(PlayerStats)
local function join(id)
	local player = S.newInstance("Player")
	player.Name = "G" .. id
	player.UserId = id
	rawset(player, "DisplayName", "G" .. id)
	rawset(player, "Parent", {})
	rawset(player, "IsInGroup", function(_, groupId)
		return groupId == 777
	end)
	S.events.PlayerAdded(player)
	return player
end
local function potionCount(player)
	local total = 0
	for count in string.gmatch(tostring(player:GetAttribute("PotionItems") or ""), ":(%d+)") do
		total += tonumber(count)
	end
	return total
end
local passive = join(9996)
GroupReward.check(passive)
assert(potionCount(passive) == 0, "Id = 0 iken ödül verilmemeli")
Config.Group.Id = 777
GroupReward.check(passive)
local after = potionCount(passive)
assert(after >= #Config.Group.Rewards, "üyeye iksirler verilmeli: " .. after)
GroupReward.check(passive)
assert(potionCount(passive) == after, "ödül yalnızca bir kez verilmeli")
Config.Group.Id = 0
print("group ok")
