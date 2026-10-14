-- GRUP ÖDÜLÜ (büyüme planı 3.5; rakiplerde standart): oyuncu oyunun Roblox grubundaysa BİR KEZ küçük, Robux'suz ödül alır (iksirler). Config.Group.Id = 0 iken PASİF (sahibi grubu açınca kimliği yazar).
-- Üyelik Player:IsInGroup ile sunucuda kontrol edilir; oyuncu sonradan katılırsa bir sonraki girişte (ya da 5 dk'lık kontrolde) ödül gelir. Tek seferlik işaret profilde kayıtlı ('group').
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GroupReward = {}

local PlayerStats

local function check(player)
	local settings = Config.Group
	if not settings or settings.Id <= 0 or not PlayerStats.groupRewardPending(player) then
		return
	end
	local ok, inGroup = pcall(function()
		return player:IsInGroup(settings.Id)
	end)
	if ok and inGroup == true then
		PlayerStats.grantGroupReward(player, settings.Rewards, settings.Message)
	end
end

function GroupReward.init(stats)
	PlayerStats = stats
	local settings = Config.Group
	if not settings or settings.Id <= 0 then
		return
	end
	PlayerStats.onLoaded(check)
	task.spawn(function()
		while true do
			task.wait(300)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end)
end

GroupReward.check = check

return GroupReward
