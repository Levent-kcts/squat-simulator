local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Layout"))
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

-- Koridor canlılığı (aşama tabelaları) isteğe bağlıdır: hata verirse oyunun geri kalanı çalışır
do
	local okHub, Hub = pcall(require, script.Hub)
	if okHub then
		local started, err = pcall(Hub.init)
		if not started then
			warn(`[Server] Hub init failed: {err}`)
		end
	else
		warn(`[Server] Could not load Hub: {Hub}`)
	end
end

-- Günlük çark (lobide spawn'ın solunda) isteğe bağlıdır: hata verirse oyunun geri kalanı çalışır
do
	local okWheel, WheelService = pcall(require, script.WheelService)
	if okWheel then
		local started, err = pcall(WheelService.init, notifyEvent)
		if not started then
			warn(`[Server] WheelService init failed: {err}`)
		end
	else
		warn(`[Server] Could not load WheelService: {WheelService}`)
	end
end

-- Arkadaş bonusu isteğe bağlıdır: hata verirse oyunun geri kalanı çalışır
do
	local okFriends, FriendBonus = pcall(require, script.FriendBonus)
	if okFriends then
		local started, err = pcall(FriendBonus.init, notifyEvent)
		if not started then
			warn(`[Server] FriendBonus init failed: {err}`)
		end
	else
		warn(`[Server] Could not load FriendBonus: {FriendBonus}`)
	end
end

-- Oyunun başlangıç alanı (spawn ve Win sonrası ışınlanma noktası): klasik Roblox doğma yeri.
-- Studio'dan eklenen SpawnLocation'daki gibi üst yüzünde 'SpawnLocation.png' deseni (beyaz zemin, siyah patlama) vardır;
-- koddan yaratılan SpawnLocation bu deseni kendiliğinden almaz, o yüzden Decal elle eklenir (rbxasset:// Roblox'un kendi içeriğidir).
local spawnPad = Instance.new("SpawnLocation")
spawnPad.Name = "SpawnPad"
spawnPad.Anchored = true
spawnPad.Neutral = true
spawnPad.Duration = 0
spawnPad.Size = Vector3.new(Config.Lobby.SpawnPadSize, 1, Config.Lobby.SpawnPadSize)
spawnPad.Position = Vector3.new(Config.SpawnPosition.X, Layout.FloorTop + 0.5, Config.SpawnPosition.Z)
spawnPad.Color = Color3.fromRGB(163, 162, 165)
spawnPad.Material = Enum.Material.Plastic
spawnPad.TopSurface = Enum.SurfaceType.Smooth
spawnPad.BottomSurface = Enum.SurfaceType.Smooth
local spawnDecal = Instance.new("Decal")
spawnDecal.Name = "Decal"
spawnDecal.Face = Enum.NormalId.Top
spawnDecal.Texture = "rbxasset://textures/SpawnLocation.png"
spawnDecal.Parent = spawnPad
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

-- HER TIKLAMA bacak kasını ANINDA verir (sahibi: 'her clickte leg power alayım, squat'ın bitmesini beklemesin'). Hareket (animasyon) ve duvara hasar ise hareket
-- boştayken başlar: squat'ta hasar hareketin SONUNDA, tekmede ayağın duvara değdiği anda (Config.MoveContact); hareket sürerken gelen tıklama kas verir ama yeni hareket başlatmaz.
-- Gecikme dalgalanması yüzünden geçerli tıklamalar reddedilmesin diye hareket süresinden küçük bir pay düşülür.
local MOVE_TOLERANCE = 0.1
local busyUntil = {}
local clickBuckets = {} -- [oyuncu] = { tokens, last }: tıklama hızı sınırı (jeton kovası, Config.ClickLimit)

local function allowClick(player, now)
	local limit = Config.ClickLimit
	local bucket = clickBuckets[player]
	if not bucket then
		bucket = { tokens = limit.Burst, last = now }
		clickBuckets[player] = bucket
	end
	bucket.tokens = math.min(limit.Burst, bucket.tokens + (now - bucket.last) * limit.PerSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player)
	busyUntil[player] = nil
	clickBuckets[player] = nil
end)

clickEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if not allowClick(player, now) then
		return -- saniyede çok fazla tıklama (otomatik tıklayıcı ya da hile): fazlası yok sayılır
	end

	-- Antrenman alanındaysa (açık bir pedin üstünde) pedin çarpanı geçerlidir
	local area = TrainingArea.getArea(player)

	-- 1) Bacak kası: her tıklamada hemen
	local muscle, gained = PlayerStats.addMuscle(player, if area then area.mult else 1)
	if not muscle then
		return -- veri henüz yüklenmedi
	end
	PlayerStats.tutorialClick(player) -- eğitimin ilk adımı için tıklama sayısı
	PlayerStats.questEvent(player, "clicks", 1) -- günlük görev ilerlemesi
	-- Kazanılan bacak kası level çubuğunu doldurur; dolunca level atlanır
	local leveledUp, newLevel = PlayerStats.addTap(player, gained)
	if leveledUp then
		notifyEvent:FireClient(player, true, `Level up! You are now level {newLevel}`)
	end

	-- 2) Hareket ve duvara hasar: sadece önceki hareket bittiyse yeni bir hareket başlar
	if now < (busyUntil[player] or 0) then
		return
	end
	-- Antrenman alanındaysa squat; değilse duvara yakınsa tekme, uzaktaysa squat
	local move = if not area and WallService.isNearWall(player) then "Kick" else "Squat"
	local duration = Config.MoveDuration[move]
	busyUntil[player] = now + duration - MOVE_TOLERANCE
	broadcastMove(player, move)

	task.delay(duration * (Config.MoveContact[move] or 1), function()
		if player.Parent == nil then
			return -- oyundan çıktı
		end
		local total = PlayerStats.getMuscle(player)
		if total then
			-- Hasar = toplam bacak kası x ayakkabı hasar çarpanı
			local _, brokenWalls = WallService.hit(player, math.floor(total * PlayerStats.getDamageMultiplier(player)))
			if brokenWalls and brokenWalls > 0 then
				PlayerStats.questEvent(player, "walls", brokenWalls) -- günlük görev ilerlemesi
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
	elseif action == "ClaimOffline" then
		return PlayerStats.claimOffline(player)
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
	elseif action == "ClaimQuest" and type(id) == "number" then
		return PlayerStats.claimQuest(player, id)
	elseif action == "ClaimQuestBonus" then
		return PlayerStats.claimQuestBonus(player)
	elseif action == "SpinWheel" then
		return PlayerStats.spinWheel(player) -- günlük çark: ok, mesaj, dilim sırası
	elseif action == "FusePet" and type(id) == "string" then
		return PlayerStats.fusePet(player, id)
	elseif action == "FuseAllPets" then
		return PlayerStats.fuseAllPets(player)
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
