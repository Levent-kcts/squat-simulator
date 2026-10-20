-- Test araçları: level, rebirth, Win, kas vb. vermek için. Sadece Studio'da veya oyunun sahibi tarafından kullanılabilir.
-- İstemci DevPanel butonları bu olaya komut yollar; yetki kontrolü burada, sunucuda yapılır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)
local WallService = require(script.Parent.WallService)
local AutoClickPass = require(script.Parent.AutoClickPass)
local EggPasses = require(script.Parent.EggPasses)
local AreaPasses = require(script.Parent.AreaPasses)
local okEvents, ServerEvents = pcall(require, script.Parent.ServerEvents)

local DevTools = {}

local function isAllowed(player)
	if RunService:IsStudio() then
		return true -- Studio test oturumları her zaman (yayında bu kod çalışmaz)
	end
	-- Yayındaki oyun: Config.DevTools.Enabled = false iken (yayın hâli) kimse kullanamaz; true iken sadece oyunun sahibi
	return Config.DevTools.Enabled and player.UserId == game.CreatorId
end

function DevTools.init(notifyEvent)
	local remote = Instance.new("RemoteEvent")
	remote.Name = "DevCommand"
	remote.Parent = ReplicatedStorage

	-- İstemci paneli göstermek için bu özniteliğe bakar (asıl kontrol yine de her komutta yapılır)
	local function mark(player)
		player:SetAttribute("IsDev", isAllowed(player))
		-- Oyunun SAHİBİ (ya da Studio) canlıda da ekran görüntüsü modunu (H tuşu, client/DevPanel) kullanabilsin: sadece bu oyuncunun ekranındaki arayüzü gizler, DEV komutu vermez
		player:SetAttribute("IsCreator", RunService:IsStudio() or player.UserId == game.CreatorId)
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
		elseif command == "TogglePassLock" then
			-- Oyunun sahibi tüm pass'lerin sahibi sayılabilir: kilit ve satın alma akışını denemek için VIP ve Auto Click'e 'sahip değilmiş gibi' bakılır
			local locked = player:GetAttribute("DevPassLock") ~= true
			player:SetAttribute("DevPassLock", if locked then true else nil)
			AutoClickPass.recheck(player)
			EggPasses.recheck(player)
			AreaPasses.recheck(player)
			ok, message = true, if locked then "Passes LOCKED (test): VIP, Auto Click, egg upgrades and coach pads act as not owned" else "Passes back to normal"
		elseif command == "ToggleEggPasses" then
			-- Yumurta game pass'leri (Auto, x3, x10) henüz satışa açık değilken de çoklu/otomatik açmayı denemek için üçünü birden açar/kapatır
			local on = player:GetAttribute("DevEggPasses") ~= true
			player:SetAttribute("DevEggPasses", if on then true else nil)
			EggPasses.recheck(player)
			ok, message = true, if on then "Egg upgrades UNLOCKED (test): Auto, x3 and x10 work" else "Egg upgrades back to normal"
		elseif command == "ToggleAreaPasses" then
			-- Robux'lu antrenman pedlerini (Coach Prism, Coach Shadow) pass'leri satışa açılmadan denemek için ikisini birden açar/kapatır
			local on = player:GetAttribute("DevAreaPasses") ~= true
			player:SetAttribute("DevAreaPasses", if on then true else nil)
			AreaPasses.recheck(player)
			ok, message = true, if on then "Coach pads UNLOCKED (test): Prism and Shadow work" else "Coach pads back to normal"
		elseif command == "UnlockWorld" then
			-- World 2'yi 20. aşamayı bitirmeden denemek için açar (kalıcı, kayda geçer; RESET ALL / RESTART TUTORIAL kapatır)
			local id = if type(amount) == "number" then amount else 2
			local opened = PlayerStats.unlockWorld(player, id)
			ok, message = true, if opened then `World {id} UNLOCKED (test): walk into the WORLDS gate` else `World {id} is already unlocked`
		elseif command == "GoWorld" then
			-- Dünyalar arası geçişi kemere gitmeden denemek için (dünya açık olmalı)
			ok, message = WallService.setWorld(player, if type(amount) == "number" then amount else 1)
		elseif command == "TogglePowerHour" then
			-- Power Hour'u saatini beklemeden denemek için: bu sunucuda hemen başlatır (tam süre) ya da bitirir
			if okEvents and ServerEvents.devToggle then
				local on = ServerEvents.devToggle()
				ok, message = true, if on then "POWER HOUR started (test): x2 Leg Muscle for everyone in this server" else "Power Hour stopped (test)"
			else
				ok, message = false, "Power Hour is not available"
			end
		else
			ok, message = PlayerStats.dev(player, command, amount)
			-- Rebirth ve sıfırlama duvarları da baştan kurmalı
			if ok and (command == "AddRebirth" or command == "Reset" or command == "RestartTutorial") then
				WallService.resetPlayer(player)
			end
		end
		notifyEvent:FireClient(player, ok, message)
	end)
end

return DevTools
