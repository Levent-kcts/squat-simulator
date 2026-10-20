-- WORLDS geçitlerinin yüz yazısını bu oyuncunun durumuna göre YEREL olarak değiştirir (sadece görünüm; geçişe sunucu karar verir).
-- Hedef dünya açıksa: dünya adı + 'Step in to travel!', kapalıysa: 'LOCKED' + açma koşulu. Geçit klasörleri Workspace'te
-- 'TargetWorld' özniteliği taşır (server/WorldsGate.build). init.client'ta safeInit ile korumalı yüklenir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))

local WorldsGateClient = {}

local player = Players.LocalPlayer

local function unlockedSet()
	local set = { [1] = true }
	for id in string.gmatch(player:GetAttribute("WorldsUnlocked") or "", "%d+") do
		set[tonumber(id)] = true
	end
	return set
end

-- Bir geçidin yazılarını günceller
local function refreshGate(folder)
	local target = folder:GetAttribute("TargetWorld")
	if type(target) ~= "number" then
		return
	end
	local plate = folder:FindFirstChild("GateSoon")
	local gui = plate and plate:FindFirstChildOfClass("SurfaceGui")
	local soon = gui and gui:FindFirstChild("Soon")
	local note = gui and gui:FindFirstChild("Note")
	if not soon or not note then
		return
	end
	local W = Layout.world(target)
	if unlockedSet()[target] then
		soon.Text = string.upper(W.name)
		note.Text = "Step in to travel!"
	else
		local def = Config.Worlds.List and Config.Worlds.List[target]
		local unlock = def and def.unlock
		soon.Text = "LOCKED"
		note.Text = if unlock then `Clear World {unlock.world} Stage {unlock.stage} to unlock` else "Locked"
	end
end

local function refreshAll()
	for _, child in Workspace:GetChildren() do
		if child:IsA("Folder") and child:GetAttribute("TargetWorld") then
			refreshGate(child)
		end
	end
end

function WorldsGateClient.init()
	refreshAll()
	player:GetAttributeChangedSignal("WorldsUnlocked"):Connect(refreshAll)
	-- Geçitler sunucuda kurulup sonradan çoğalır: yeni gelen klasörü de güncelle (yazılar içine yerleşsin diye kısa gecikmeyle)
	Workspace.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			task.delay(1, function()
				if child.Parent and child:GetAttribute("TargetWorld") then
					refreshGate(child)
				end
			end)
		end
	end)
end

return WorldsGateClient
