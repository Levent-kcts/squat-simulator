-- Test araçları: level, rebirth, Win, kas vb. vermek için. Sadece Studio'da veya oyunun sahibi tarafından kullanılabilir.
-- İstemci DevPanel butonları bu olaya komut yollar; yetki kontrolü burada, sunucuda yapılır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)
local WallService = require(script.Parent.WallService)

local DevTools = {}

local function isAllowed(player)
	if not Config.DevTools.Enabled then
		return false
	end
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

function DevTools.init(notifyEvent)
	local remote = Instance.new("RemoteEvent")
	remote.Name = "DevCommand"
	remote.Parent = ReplicatedStorage

	-- İstemci paneli göstermek için bu özniteliğe bakar (asıl kontrol yine de her komutta yapılır)
	local function mark(player)
		player:SetAttribute("IsDev", isAllowed(player))
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in Players:GetPlayers() do
		mark(player)
	end

	remote.OnServerEvent:Connect(function(player, command, amount)
		if not isAllowed(player) or type(command) ~= "string" then
			return
		end

		local ok, message
		if command == "BreakStage" then
			WallService.devBreakStage(player)
			ok, message = true, "Current stage walls broken"
		elseif command == "TeleportToWalls" then
			WallService.devTeleportToWalls(player)
			ok, message = true, "Teleported to your walls"
		else
			ok, message = PlayerStats.dev(player, command, amount)
			-- Rebirth ve sıfırlama duvarları da baştan kurmalı
			if ok and (command == "AddRebirth" or command == "Reset") then
				WallService.resetPlayer(player)
			end
		end
		notifyEvent:FireClient(player, ok, message)
	end)
end

return DevTools
