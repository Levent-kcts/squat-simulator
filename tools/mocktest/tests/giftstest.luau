-- Gifts > Playtime Rewards: pet ödül kartlarında genel pati simgesi değil PETİN RESMİ çizilir (sahibi 'bunlar yerine pet resmi olsun' dedi); kas/Win/iksir kartları eskisi gibi
local S = require("../cstubs")
local Config = require("./Config")
local GiftsPanel = require("./GiftsPanel")

local workspaceService = S.game:GetService("Workspace")
rawset(workspaceService, "GetServerTimeNow", function()
	return 1000
end)
S.localPlayer:SetAttribute("SessionStart", 1000)
local root = S.newInstance("Frame")
local ok, err = pcall(GiftsPanel.init, root, function() end, function() end)
assert(ok, "GiftsPanel.init hata verdi: " .. tostring(err))

-- Ağacı gez: ad -> kaç tane
local function countNamed(instance, name)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			total += 1
		end
		total += countNamed(child, name)
	end
	return total
end
local petRewards = 0
for _, reward in Config.GiftRewards do
	if reward.kind == "pet" then
		petRewards += 1
	end
end
assert(petRewards >= 2, "Config.GiftRewards'ta pet ödülleri olmalı (dragon, phoenix)")
assert(countNamed(root, "RewardPet") == petRewards, "her pet ödül kartında petin kendi resmi olmalı: " .. countNamed(root, "RewardPet") .. "/" .. petRewards)
print("GiftsPanel pet images ok")
