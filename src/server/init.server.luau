local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.PlayerStats)
local WallService = require(script.WallService)
local EnvironmentService = require(script.EnvironmentService)
local ShoeShop = require(script.ShoeShop)
local SkinShop = require(script.SkinShop)
local EggShop = require(script.EggShop)
local TrainingArea = require(script.TrainingArea)
local TrailService = require(script.TrailService)
local AuraService = require(script.AuraService)
local LegGrowth = require(script.LegGrowth)
local DevTools = require(script.DevTools)
local AppearanceCleaner = require(script.AppearanceCleaner)

-- Oyuncuya kısa mesaj (satın alma sonucu vb.) göstermek için
local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = ReplicatedStorage

PlayerStats.init()
WallService.init(notifyEvent)
EnvironmentService.init()

-- Oyunun başlangıç alanı (spawn ve Win sonrası ışınlanma noktası)
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "SpawnPad"
spawnPad.Anchored = true
spawnPad.Neutral = true
spawnPad.Duration = 0
spawnPad.Size = Vector3.new(16, 1, 16)
spawnPad.Position = Vector3.new(Config.SpawnPosition.X, 0.5, Config.SpawnPosition.Z)
spawnPad.Color = Color3.fromRGB(80, 200, 120)
spawnPad.Material = Enum.Material.SmoothPlastic
spawnPad.Parent = Workspace

ShoeShop.init(notifyEvent)
SkinShop.init(notifyEvent)
EggShop.init(notifyEvent)
TrainingArea.init(notifyEvent)

-- Robux satın almaları (ProcessReceipt) isteğe bağlı modüldür: hata verirse oyunun geri kalanı çalışır
do
	local ok, Purchases = pcall(require, script.Purchases)
	if ok then
		local started, err = pcall(Purchases.init, WallService, notifyEvent)
		if not started then
			warn(`[Server] Purchases init failed: {err}`)
		end
	else
		warn(`[Server] Could not load Purchases: {Purchases}`)
	end
end

-- Sıralama tabloları isteğe bağlıdır: hata verirse oyunun geri kalanı çalışmaya devam eder
do
	local ok, Leaderboards = pcall(require, script.Leaderboards)
	if ok then
		local started, err = pcall(Leaderboards.init)
		if not started then
			warn(`[Server] Leaderboards init failed: {err}`)
		end
	else
		warn(`[Server] Could not load Leaderboards: {Leaderboards}`)
	end
end
TrailService.init()
AuraService.init()
LegGrowth.init(notifyEvent)
DevTools.init(notifyEvent)
AppearanceCleaner.init()

-- İstemci her tıklamada bu olayı tetikler. Tüm hesaplamalar sunucuda yapılır.
local clickEvent = Instance.new("RemoteEvent")
clickEvent.Name = "Click"
clickEvent.Parent = ReplicatedStorage

-- Tekme/squat animasyonunu diğer oyunculara bildirir (her istemci kendi ekranında oynatır)
local moveEvent = Instance.new("RemoteEvent")
moveEvent.Name = "MoveEvent"
moveEvent.Parent = ReplicatedStorage

local function broadcastMove(player, move)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			moveEvent:FireClient(other, player, move)
		end
	end
end

-- Bir hareket (animasyon) süresince yeni tıklamalar yok sayılır. Puan ve hasar hareketin SONUNDA bir kez verilir.
-- Gecikme dalgalanması yüzünden geçerli tıklamalar reddedilmesin diye küçük bir pay bırakılır.
local MOVE_TOLERANCE = 0.1
local busyUntil = {}

clickEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now < (busyUntil[player] or 0) then
		return
	end

	-- Antrenman alanındaysa (açık bir pedin üstünde) squat ve pedin çarpanı; değilse duvara yakınsa tekme, uzaktaysa squat
	local area = TrainingArea.getArea(player)
	local move = if not area and WallService.isNearWall(player) then "Kick" else "Squat"
	local duration = Config.MoveDuration[move]
	busyUntil[player] = now + duration - MOVE_TOLERANCE
	broadcastMove(player, move)

	task.delay(duration, function()
		if player.Parent == nil then
			return -- oyundan çıktı
		end
		local muscle, gained = PlayerStats.addMuscle(player, if area then area.mult else 1)
		if muscle then
			-- Hasar = toplam bacak kası x ayakkabı hasar çarpanı
			WallService.hit(player, math.floor(muscle * PlayerStats.getDamageMultiplier(player)))
			-- Kazanılan bacak kası level çubuğunu doldurur; dolunca level atlanır
			local leveledUp, newLevel = PlayerStats.addTap(player, gained)
			if leveledUp then
				notifyEvent:FireClient(player, true, `Level up! You are now level {newLevel}`)
			end
		end
	end)
end)

-- Mağaza: eşya satın alma ve yumurta açma
local shopFunction = Instance.new("RemoteFunction")
shopFunction.Name = "Shop"
shopFunction.Parent = ReplicatedStorage

shopFunction.OnServerInvoke = function(player, action, id, value)
	if action == "BuyItem" and type(id) == "string" then
		return PlayerStats.buyItem(player, id)
	elseif action == "SetSetting" and type(id) == "string" and type(value) == "boolean" then
		return PlayerStats.setSetting(player, id, value)
	elseif action == "SetMusicLevel" and type(id) == "number" then
		return PlayerStats.setMusicLevel(player, id)
	elseif action == "ToggleAutoDelete" and type(id) == "string" then
		return PlayerStats.toggleAutoDelete(player, id)
	elseif action == "BuyTrail" and type(id) == "string" then
		return PlayerStats.buyTrail(player, id)
	elseif action == "EquipTrail" and type(id) == "string" then
		return PlayerStats.equipTrail(player, id)
	elseif action == "BuyAura" and type(id) == "string" then
		return PlayerStats.buyAura(player, id)
	elseif action == "EquipAura" and type(id) == "string" then
		return PlayerStats.equipAura(player, id)
	elseif action == "EquipPet" and type(id) == "string" then
		return PlayerStats.equipPet(player, id)
	elseif action == "UnequipPet" and type(id) == "string" then
		return PlayerStats.unequipPet(player, id)
	elseif action == "EquipBestPets" then
		return PlayerStats.equipBestPets(player)
	elseif action == "UnequipAllPets" then
		return PlayerStats.unequipAllPets(player)
	elseif action == "DeletePet" and type(id) == "string" then
		return PlayerStats.deletePet(player, id)
	elseif action == "ClaimGift" and type(id) == "number" then
		return PlayerStats.claimGift(player, id)
	elseif action == "Rebirth" then
		local ok, message = PlayerStats.rebirth(player)
		if ok then
			WallService.resetPlayer(player)
		end
		return ok, message
	end
	return false, "Invalid action."
end

Players.PlayerRemoving:Connect(function(player)
	busyUntil[player] = nil
end)
