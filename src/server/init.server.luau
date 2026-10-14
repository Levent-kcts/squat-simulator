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
local AutoClickPass = require(script.AutoClickPass)
local EggPasses = require(script.EggPasses)
local AreaPasses = require(script.AreaPasses)

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

-- Power Hour (sunucu çapı olay sayacı) isteğe bağlıdır: hata verirse çarpan 1 kalır
do
	local okEvents, ServerEvents = pcall(require, script.ServerEvents)
	if okEvents then
		local started, err = pcall(ServerEvents.init)
		if not started then
			warn(`[Server] ServerEvents init failed: {err}`)
		end
	else
		warn(`[Server] Could not load ServerEvents: {ServerEvents}`)
	end
end

-- Sezonluk etkinlik (Spooky Gym: Candy, mağaza, kilometre taşları) ve lobi süsü isteğe bağlıdır: hata verirse oyun etkilenmez
local SeasonEvent
do
	local okSeason, module = pcall(require, script.SeasonEvent)
	if okSeason then
		SeasonEvent = module
		local started, err = pcall(SeasonEvent.init, PlayerStats)
		if not started then
			SeasonEvent = nil
			warn(`[Server] SeasonEvent init failed: {err}`)
		end
	else
		warn(`[Server] Could not load SeasonEvent: {module}`)
	end
	local okDecor, EventDecor = pcall(require, script.EventDecor)
	if okDecor then
		local started, err = pcall(EventDecor.init)
		if not started then
			warn(`[Server] EventDecor init failed: {err}`)
		end
	else
		warn(`[Server] Could not load EventDecor: {EventDecor}`)
	end
end

-- Çapraz sunucu duyuru akışı (nadir pet, rebirth eşikleri) isteğe bağlıdır: hata verirse oyunun geri kalanı çalışır
do
	local okFeedModule, GlobalFeed = pcall(require, script.GlobalFeed)
	if okFeedModule then
		local started, err = pcall(GlobalFeed.init)
		if not started then
			warn(`[Server] GlobalFeed init failed: {err}`)
		end
	else
		warn(`[Server] Could not load GlobalFeed: {GlobalFeed}`)
	end
end

-- Friend Referral ödülü (davet bağlantısıyla gelen yeni oyuncu): isteğe bağlıdır, hata verirse oyunun geri kalanı çalışır
do
	local okReferrals, Referrals = pcall(require, script.Referrals)
	if okReferrals then
		local started, err = pcall(Referrals.init, PlayerStats)
		if not started then
			warn(`[Server] Referrals init failed: {err}`)
		end
	else
		warn(`[Server] Could not load Referrals: {Referrals}`)
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

-- Worlds geçidi (yumurta standının arkasındaki kemer, 'COMING SOON') isteğe bağlıdır: hata verirse oyunun geri kalanı çalışır
do
	local okGate, WorldsGate = pcall(require, script.WorldsGate)
	if okGate then
		local started, err = pcall(WorldsGate.init)
		if not started then
			warn(`[Server] WorldsGate init failed: {err}`)
		end
	else
		warn(`[Server] Could not load WorldsGate: {WorldsGate}`)
	end
end

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
AutoClickPass.init(notifyEvent)
EggPasses.init(notifyEvent)
AreaPasses.init(notifyEvent)

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

-- SQUAT (duvardan uzak ya da antrenman pedinde): HER TIKLAMA bacak kasını ANINDA verir (sahibi: 'her clickte leg power alayım, squat'ın bitmesini beklemesin'); hareket sürerken
-- gelen tıklama kas verir ama yeni hareket başlatmaz. TEKME (duvarın önünde): tıklama KAS VERMEZ (sahibi: 'duvara her tıkladığımda saymasın, duvara vurmak için animasyonu beklesin'):
-- sadece hareket boşken tekme başlar, kas ve duvara hasar tek seferde ayağın duvara değdiği anda gelir (Config.MoveContact), hareket sürerken gelen tıklamalar tamamen yok sayılır.
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

-- Bir tıklamanın kazancı: bacak kası + eğitim sayacı + günlük görev + level atlama. Döner: verildi mi (veri yüklenmediyse false)
local function creditClick(player, area)
	local muscle, gained = PlayerStats.addMuscle(player, if area then area.mult else 1)
	if not muscle then
		return false
	end
	PlayerStats.tutorialClick(player) -- eğitimin ilk adımı için tıklama sayısı
	PlayerStats.questEvent(player, "clicks", 1) -- günlük görev ilerlemesi
	-- Kazanılan bacak kası level çubuğunu doldurur; dolunca level atlanır
	-- (Level atlayınca yeşil 'Level up! You are now level N' bildirimi KALDIRILDI: ekranın ortasını kaplıyordu, sahibi 'ekran referansa göre çok bunaltıcı' dedi; sarı 'LEVEL UP!' yazısı [client/Juice] ve level çubuğu zaten gösteriyor)
	PlayerStats.addTap(player, gained)
	return true
end

-- Duvara hasar = toplam bacak kası x ayakkabı hasar çarpanı (tıklama sayısıyla çarpılmaz)
local function hitWalls(player)
	local total = PlayerStats.getMuscle(player)
	if total then
		local _, brokenWalls = WallService.hit(player, math.floor(total * PlayerStats.getDamageMultiplier(player)))
		if brokenWalls and brokenWalls > 0 then
			PlayerStats.questEvent(player, "walls", brokenWalls) -- günlük görev ilerlemesi
		end
	end
end

clickEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if not allowClick(player, now) then
		return -- saniyede çok fazla tıklama (otomatik tıklayıcı ya da hile): fazlası yok sayılır
	end

	-- Antrenman alanındaysa (açık bir pedin üstünde) squat ve pedin çarpanı; değilse duvara yakınsa tekme, uzaktaysa squat
	local area = TrainingArea.getArea(player)
	local move = if not area and WallService.isNearWall(player) then "Kick" else "Squat"
	local idle = now >= (busyUntil[player] or 0)

	if move == "Squat" then
		-- Squat: her tıklamada hemen kas
		if not creditClick(player, area) then
			return -- veri henüz yüklenmedi
		end
	end
	if not idle then
		return -- hareket sürüyor: squat'ta kas verildi, tekmede tıklama sayılmaz
	end

	local duration = Config.MoveDuration[move]
	busyUntil[player] = now + duration - MOVE_TOLERANCE
	broadcastMove(player, move)
	task.delay(duration * (Config.MoveContact[move] or 1), function()
		if player.Parent == nil then
			return -- oyundan çıktı
		end
		if move == "Kick" then
			creditClick(player, nil) -- tekmede kas ayak duvara değince (hareket başına bir kez) verilir
		end
		hitWalls(player)
	end)
end)

-- Mağaza: eşya satın alma ve yumurta açma
local shopFunction = Instance.new("RemoteFunction")
shopFunction.Name = "Shop"
shopFunction.Parent = ReplicatedStorage

-- Mağaza çağrılarına hız sınırı (yayın öncesi sertleştirme, Config.ShopLimit): tek oyuncu saniyede binlerce çağrıyla sunucuyu yormasın. Jeton kovası; Pets menüsü çok pet silerken çağrıları art arda yapar, bu yüzden sınır cömerttir
local shopBuckets = {} -- [oyuncu] = { tokens, last }
local function allowShop(player)
	local limit = Config.ShopLimit
	local bucket = shopBuckets[player]
	local now = os.clock()
	if not bucket then
		bucket = { tokens = limit.Burst, last = now }
		shopBuckets[player] = bucket
	end
	bucket.tokens = math.min(limit.Burst, bucket.tokens + (now - bucket.last) * limit.PerSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

shopFunction.OnServerInvoke = function(player, action, id, value)
	if not allowShop(player) then
		return false, "You are going too fast, slow down."
	end
	if action == "BuyItem" and type(id) == "string" then
		return PlayerStats.buyItem(player, id)
	elseif action == "UsePotion" and type(id) == "string" then
		return PlayerStats.usePotion(player, id)
	elseif action == "ClaimOffline" then
		return PlayerStats.claimOffline(player)
	elseif action == "ClaimLogin" then
		return PlayerStats.claimLogin(player)
	elseif action == "EventBuy" and type(id) == "string" then
		if not SeasonEvent then
			return false, "The event is not available right now."
		end
		return SeasonEvent.buy(player, id)
	elseif action == "EventClaim" and type(id) == "number" then
		if not SeasonEvent then
			return false, "The event is not available right now."
		end
		return SeasonEvent.claim(player, math.floor(id))
	elseif action == "SeenWhatsNew" then
		return PlayerStats.seenWhatsNew(player)
	elseif action == "RedeemCode" and type(id) == "string" then
		return PlayerStats.redeemCode(player, id)
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
	elseif action == "ClaimStarter" and type(id) == "string" then
		return PlayerStats.claimStarter(player, id) -- Yeni oyuncu görevi ödülü
	elseif action == "GuideSeen" and type(id) == "string" then
		return PlayerStats.guideSeen(player, id) -- rehber turu adımı görüldü
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
	shopBuckets[player] = nil
end)

-- Dünya kuruldu: istemcideki yükleme ekranı (ReplicatedFirst/Loading) bu işareti bekleyip kapanır
Workspace:SetAttribute("WorldReady", true)
