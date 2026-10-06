local S = require("../cstubs")
local root = S.newInstance("Frame")
local function toast(ok, msg)
	print("  toast:", ok, msg)
end

-- QuestPanel
S.jsonData = {
	resetAt = os.time() + 3600,
	quests = {
		{ id = "walls", text = "Break 12 walls", goal = 12, progress = 12, claimed = false, reward = "+600 Leg Muscle" },
		{ id = "hatch", text = "Hatch 4 eggs", goal = 4, progress = 1, claimed = false, reward = "+12 Wins" },
		{ id = "fuse", text = "Fuse pets 2x", goal = 2, progress = 0, claimed = true, reward = "+3.0K Leg Muscle" },
	},
	bonusClaimed = false,
	bonusText = "2x Leg Muscle for 15 minutes",
}
S.localPlayer:SetAttribute("QuestData", "x")
local QuestPanel = require("./QuestPanel")
print("claimable:", QuestPanel.claimable(S.localPlayer))
local toggleQuests = QuestPanel.init(root, toast)
toggleQuests()
print("QuestPanel ok")

-- FusionPanel
S.localPlayer:SetAttribute("OwnedPets", "cat,cat,cat,dog,dog@2")
local FusionPanel = require("./FusionPanel")
local toggleFusion = FusionPanel.init(root, toast)
toggleFusion()
S.localPlayer:SetAttribute("OwnedPets", "cat,cat,cat,cat@2,cat@2,cat@2")
print("FusionPanel ok")

-- WallClient
local wallsHandler
local wallsEvent = S.newInstance("RemoteEvent")
wallsEvent.OnClientEvent = {
	Connect = function(_, f)
		wallsHandler = f
		return S.proxy()
	end,
}
wallsEvent.FireServer = function() end
rawget(S.replicated, "_children")["WallsEvent"] = wallsEvent
local WallClient = require("./WallClient")
WallClient.init(function(frontier)
	print("  frontier", frontier)
end)
for _, hb in S.heartbeat do
	hb(0.6)
end
print("WallClient init ok; heartbeat callbacks:", #S.heartbeat)
wallsHandler("Update", { { 1, 0 } })
wallsHandler("Update", { { 2, 0 }, { 3, 10 } })
S.root.Position = S.Vector3.new(0, 3, -400)
for _, hb in S.heartbeat do
	hb(0.6)
end
S.root.Position = S.Vector3.new(0, 3, 0)
for _, hb in S.heartbeat do
	hb(0.6)
end
print("proximity loop ok")
-- Tüm temaların deseni: oyuncuyu koridor boyunca gezdir (her duvar bir kez yakın olsun)
local Layout = require("./Layout")
local lastZ = Layout.wallZ(100)
local z = 0
while z > lastZ - 100 do
	S.root.Position = S.Vector3.new(0, 3, z)
	for _, hb in S.heartbeat do
		hb(0.6)
	end
	z -= 120
end
print("all-theme patterns ok (z down to", lastZ, ")")
-- Juice: her temanın kırılma parçacığı/lego parçaları/bekleme parçacığı, pcall OLMADAN (hata gizlenmesin)
local Juice = require("./Juice")
local part = S.newInstance("Part")
part.Position = S.Vector3.new(0, 12, -100)
part.Size = S.Vector3.new(32, 23.8, 3)
part.Color = S.Color3.new(0.5, 0.5, 0.5)
S.root.Position = S.Vector3.new(0, 3, -90)
for stage = 1, 20 do
	local theme = Layout.theme(stage)
	Juice.wallBroken(part, theme)
	Juice.addWallAmbient(part, theme)
end
Juice.burst(S.Vector3.new(0, 5, 0), S.Vector3.new(4, 4, 4), S.Color3.new(1, 1, 1), 50)
for _, hb in S.heartbeat do
	hb(0.05)
end
print("Juice all themes ok")
print("DONE")
