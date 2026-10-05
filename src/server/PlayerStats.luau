local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Progression = require(Shared:WaitForChild("Progression"))
local Layout = require(Shared:WaitForChild("Layout"))
local Format = require(Shared:WaitForChild("Format"))

local PlayerStats = {}

local store = DataStoreService:GetDataStore(Config.Save.StoreName)
local rng = Random.new()

-- profiles[player] = { loaded, canSave, items = {id}, pets = {id}, gain }
local profiles = {}
local friendCounts = {} -- [player] = aynı sunucudaki arkadaş sayısı (server/FriendBonus bildirir; profil yüklenmeden önce de gelebilir)

-- Listede id kaç kez geçiyor
local function countOf(list, id)
	local count = 0
	for _, value in list do
		if value == id then
			count += 1
		end
	end
	return count
end

-- Pet envanterinden (kopyalar dahil) en güçlü MaxEquippedPets tanesini seçer
local function bestEquipped(pets)
	local sorted = table.clone(pets)
	table.sort(sorted, function(a, b)
		return Catalog.PetById[a].mult > Catalog.PetById[b].mult
	end)
	local equipped = {}
	for i = 1, math.min(#sorted, Config.MaxEquippedPets) do
		table.insert(equipped, sorted[i])
	end
	return equipped
end

local function getStat(player, name)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name)
end

-- Kaydedilebilir oyuncu ayarları (Config.Settings): sadece bu anahtarlar kabul edilir
local SETTING_KEYS = {}
for _, setting in Config.Settings do
	SETTING_KEYS[setting.key] = true
end

-- Kayıtlı veriyi güvenli hale getirir (bozuk/eksik/silinmiş eşya id'lerine karşı)
local function sanitize(raw)
	local data = { Muscle = 0, Wins = 0, Level = 1, Taps = 0, Rebirths = 0, Items = {}, Pets = {}, AutoDelete = {}, Trails = {}, EquippedTrail = "", Auras = {}, EquippedAura = "", Skins = {}, EquippedItem = "", EquippedSkin = "", LastSeen = 0, OfflinePending = 0, OfflineSeconds = 0, Receipts = {}, EquippedPets = {}, Settings = {}, Discovered = {} }
	if type(raw) ~= "table" then
		return data
	end

	if type(raw.Muscle) == "number" then
		data.Muscle = math.max(0, math.floor(raw.Muscle))
	end
	if type(raw.Wins) == "number" then
		data.Wins = math.max(0, math.floor(raw.Wins))
	end
	if type(raw.LastSeen) == "number" then
		data.LastSeen = math.max(0, math.floor(raw.LastSeen))
	end
	if type(raw.OfflinePending) == "number" then
		data.OfflinePending = math.max(0, math.floor(raw.OfflinePending))
	end
	if type(raw.Receipts) == "table" then
		for _, id in raw.Receipts do
			if type(id) == "string" and #data.Receipts < 300 then
				table.insert(data.Receipts, id)
			end
		end
	end
	if type(raw.MusicLevel) == "number" then
		data.MusicLevel = math.clamp(math.floor(raw.MusicLevel), 0, Config.Music.maxLevel)
	end
	if type(raw.Discovered) == "table" then
		for _, id in raw.Discovered do
			if Catalog.PetById[id] and not table.find(data.Discovered, id) then
				table.insert(data.Discovered, id)
			end
		end
	end
	if type(raw.Settings) == "table" then
		for key, value in raw.Settings do
			if SETTING_KEYS[key] and type(value) == "boolean" then
				data.Settings[key] = value
			end
		end
	end
	if type(raw.OfflineSeconds) == "number" then
		data.OfflineSeconds = math.max(0, math.floor(raw.OfflineSeconds))
	end
	if type(raw.Rebirths) == "number" then
		data.Rebirths = math.max(0, math.floor(raw.Rebirths))
	end
	if type(raw.Level) == "number" then
		data.Level = math.clamp(math.floor(raw.Level), 1, Progression.maxLevel(data.Rebirths))
	end
	if type(raw.Taps) == "number" and data.Level < Progression.maxLevel(data.Rebirths) then
		data.Taps = math.clamp(math.floor(raw.Taps), 0, Progression.tapsNeeded(data.Level) - 1)
	end
	if type(raw.Items) == "table" then
		for _, id in raw.Items do
			if Catalog.ItemById[id] and not table.find(data.Items, id) then
				table.insert(data.Items, id)
			end
		end
	end
	if type(raw.Skins) == "table" then
		for _, id in raw.Skins do
			if Catalog.SkinById[id] and not table.find(data.Skins, id) then
				table.insert(data.Skins, id)
			end
		end
	end
	-- Takılı ayakkabı/skin: sahip olunan biri olmalı. Eski kayıtlarda yoksa refresh en güçlüsünü takar.
	if type(raw.EquippedItem) == "string" and table.find(data.Items, raw.EquippedItem) then
		data.EquippedItem = raw.EquippedItem
	end
	if type(raw.EquippedSkin) == "string" and table.find(data.Skins, raw.EquippedSkin) then
		data.EquippedSkin = raw.EquippedSkin
	end
	if type(raw.Trails) == "table" then
		for _, id in raw.Trails do
			if Catalog.TrailById[id] and not table.find(data.Trails, id) then
				table.insert(data.Trails, id)
			end
		end
	end
	if type(raw.EquippedTrail) == "string" and table.find(data.Trails, raw.EquippedTrail) then
		data.EquippedTrail = raw.EquippedTrail
	end
	if type(raw.Auras) == "table" then
		for _, id in raw.Auras do
			if Catalog.AuraById[id] and not table.find(data.Auras, id) then
				table.insert(data.Auras, id)
			end
		end
	end
	if type(raw.EquippedAura) == "string" and table.find(data.Auras, raw.EquippedAura) then
		data.EquippedAura = raw.EquippedAura
	end
	if type(raw.AutoDelete) == "table" then
		for _, id in raw.AutoDelete do
			if Catalog.PetById[id] and not table.find(data.AutoDelete, id) then
				table.insert(data.AutoDelete, id)
			end
		end
	end
	if type(raw.Pets) == "table" then
		for _, id in raw.Pets do
			if Catalog.PetById[id] and #data.Pets < Config.MaxOwnedPets then
				table.insert(data.Pets, id)
			end
		end
	end
	-- Takılı petler: sahip olunan kopya sayısını ve üst sınırı aşamaz. Eski kayıtlarda yoksa en güçlüler takılır.
	if type(raw.EquippedPets) == "table" then
		for _, id in raw.EquippedPets do
			if Catalog.PetById[id]
				and #data.EquippedPets < Config.MaxEquippedPets
				and countOf(data.EquippedPets, id) < countOf(data.Pets, id)
			then
				table.insert(data.EquippedPets, id)
			end
		end
	else
		data.EquippedPets = bestEquipped(data.Pets)
	end
	return data
end

local function loadData(player)
	local key = `Player_{player.UserId}`
	for attempt = 1, 3 do
		local ok, result = pcall(store.GetAsync, store, key)
		if ok then
			return true, result
		end
		warn(`[Save] Load failed (attempt {attempt}): {result}`)
		-- Studio'da API erişimi kapalıysa tekrar denemek boşuna (her Play'de 12 sn beklemeye yol açıyordu)
		if string.find(tostring(result), "Studio access to API", 1, true) then
			break
		end
		task.wait(2 * attempt)
	end
	return false, nil
end

-- Level, TOPLAM bacak kasından hesaplanır (rebirth üst sınırı geçilmez). Dönüş: level atladı mı, yeni level
local function syncLevel(player)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local levelStat = getStat(player, Config.StatLevel)
	local rebirthStat = getStat(player, Config.StatRebirths)
	if not profile or not muscle or not levelStat or not rebirthStat then
		return false, 1
	end
	local before = levelStat.Value
	local level, progress = Progression.levelFromMuscle(muscle.Value, Progression.maxLevel(rebirthStat.Value))
	levelStat.Value = level
	profile.taps = progress -- çubuktaki ilerleme (bu level içinde kazanılan kas)
	return level > before, level
end

-- Sahip olunanlar arasında takılı olanı döndürür; takılı olan geçersizse (yok/silinmiş) en güçlü olan (field büyüklüğüne göre) seçilir
local function pickEquipped(owned, current, byId, field)
	if table.find(owned, current) then
		return current
	end
	local best, bestValue = "", 0
	for _, id in owned do
		if byId[id][field] > bestValue then
			best, bestValue = id, byId[id][field]
		end
	end
	return best
end

-- Antrenman alanı bu oyuncu için açık mı? Sadece rebirth sayısına bağlı (rebirths = N: N rebirth'te açılır, 0: ücretsiz)
local function areaUnlocked(area, rebirths)
	return rebirths >= (area.rebirths or 0)
end

-- Eşya/pet durumundan tıklama başına kazancı hesaplar, istemciye öznitelik olarak yollar
local function refresh(player)
	local profile = profiles[player]

	-- Takılı ayakkabı geçerlidir (toplanmaz): oyuncu satın alınca ya da raftaki sahip olduğu ayakkabıya basınca değiştirir
	profile.equippedShoe = pickEquipped(profile.items, profile.equippedShoe, Catalog.ItemById, "damage")
	local shoe = Catalog.ItemById[profile.equippedShoe]
	local shoeDamage = if shoe then shoe.damage else 1
	profile.damageMultiplier = shoeDamage

	-- Takılı skin geçerlidir (toplanmaz): rengi karakteri boyar, çarpanı bacak kası kazancına girer
	profile.equippedSkin = pickEquipped(profile.skins, profile.equippedSkin, Catalog.SkinById, "mult")
	local skin = Catalog.SkinById[profile.equippedSkin]
	local skinMultiplier = if skin then skin.mult else 1

	-- Takılı petlerin çarpanı (oyuncu Pets menüsünden takar)
	local equipped = profile.equipped
	local multiplier = 1
	for _, id in equipped do
		multiplier += Catalog.PetById[id].mult
	end

	local level = getStat(player, Config.StatLevel).Value
	local rebirths = getStat(player, Config.StatRebirths).Value
	local maxLevel = Progression.maxLevel(rebirths)
	-- Toplam çarpan = petler x level x rebirth x aura x skin x süreli güçlendirme
	local aura = Catalog.AuraById[profile.equippedAura]
	local auraMultiplier = if aura then aura.mult else 1
	local boostMultiplier = if os.time() < profile.boostMuscleUntil then 2 else 1
	-- Pet Index: sahip olunan her tür keşfedilir (silinse de kalır); keşfedilen her tür +%X (Config.Index)
	for _, id in profile.pets do
		profile.discovered[id] = true
	end
	local discoveredIds = {}
	for id in profile.discovered do
		table.insert(discoveredIds, id)
	end
	local indexPercent = #discoveredIds * Config.Index.PercentPerPet

	-- Arkadaş bonusu: sunucudaki her arkadaş için +%X (Config.Friends)
	local friendsConfig = Config.Friends
	local friendCount = if friendsConfig.Enabled then math.min(friendCounts[player] or 0, friendsConfig.MaxFriends) else 0
	local friendPercent = friendCount * friendsConfig.PercentPerFriend
	local totalMultiplier = multiplier
		* Progression.levelMultiplier(level)
		* Progression.rebirthMultiplier(rebirths)
		* auraMultiplier
		* skinMultiplier
		* boostMultiplier
		* (1 + friendPercent / 100)
		* (1 + indexPercent / 100)

	profile.gain = math.max(1, math.floor(Config.MusclePerClick * totalMultiplier))

	player:SetAttribute("Taps", profile.taps)
	player:SetAttribute("TapsNeeded", Progression.tapsNeeded(level))
	player:SetAttribute("MaxLevel", maxLevel)
	player:SetAttribute("TotalMultiplier", totalMultiplier)
	player:SetAttribute("FriendCount", friendCount)
	player:SetAttribute("FriendBonus", friendPercent)
	player:SetAttribute("DiscoveredPets", table.concat(discoveredIds, ","))
	player:SetAttribute("IndexBonus", indexPercent)
	player:SetAttribute("DamageMultiplier", shoeDamage)

	player:SetAttribute("PerClick", profile.gain)
	player:SetAttribute("PetMultiplier", multiplier)
	player:SetAttribute("OwnedItems", table.concat(profile.items, ","))
	player:SetAttribute("EquippedShoe", profile.equippedShoe)
	local unlockedAreas = {}
	for _, area in Config.Training.Areas do
		if areaUnlocked(area, rebirths) then
			table.insert(unlockedAreas, area.id)
		end
	end
	player:SetAttribute("UnlockedAreas", table.concat(unlockedAreas, ","))
	player:SetAttribute("OwnedSkins", table.concat(profile.skins, ","))
	player:SetAttribute("EquippedSkin", profile.equippedSkin)
	player:SetAttribute("SkinMultiplier", skinMultiplier)
	player:SetAttribute("OwnedPets", table.concat(profile.pets, ","))
	player:SetAttribute("EquippedPets", table.concat(equipped, ","))
	player:SetAttribute("OwnedTrails", table.concat(profile.trails, ","))
	player:SetAttribute("OwnedAuras", table.concat(profile.auras, ","))
	player:SetAttribute("EquippedAura", profile.equippedAura)
	player:SetAttribute("MuscleBoostUntil", profile.boostMuscleUntil)
	player:SetAttribute("WinBoostUntil", profile.boostWinsUntil)
	player:SetAttribute("EquippedTrail", profile.equippedTrail)
	local autoDeleteList = {}
	for id in profile.autoDelete do
		table.insert(autoDeleteList, id)
	end
	player:SetAttribute("AutoDeletePets", table.concat(autoDeleteList, ","))
end

local function save(player)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	-- Yükleme başarısız olduysa asla kaydetme, yoksa eski ilerleme silinir
	if not profile or not profile.canSave or not muscle or not wins then
		return
	end

	local data = {
		Muscle = muscle.Value,
		Wins = wins.Value,
		Level = getStat(player, Config.StatLevel).Value,
		Taps = profile.taps,
		Rebirths = getStat(player, Config.StatRebirths).Value,
		Items = profile.items,
		EquippedItem = profile.equippedShoe,
		Skins = profile.skins,
		EquippedSkin = profile.equippedSkin,
		LastSeen = os.time(),
		OfflinePending = profile.offlinePending,
		OfflineSeconds = profile.offlineSeconds,
		MusicLevel = profile.musicLevel,
		Settings = profile.settings,
		Discovered = (function()
			local list = {}
			for id in profile.discovered do
				table.insert(list, id)
			end
			return list
		end)(),
		Receipts = profile.receipts,
		Pets = profile.pets,
		Trails = profile.trails,
		EquippedTrail = profile.equippedTrail,
		Auras = profile.auras,
		EquippedAura = profile.equippedAura,
		EquippedPets = profile.equipped,
		AutoDelete = (function()
			local list = {}
			for id in profile.autoDelete do
				table.insert(list, id)
			end
			return list
		end)(),
	}
	profile.lastSave = os.clock()
	local ok, err = pcall(store.UpdateAsync, store, `Player_{player.UserId}`, function()
		return data
	end)
	if not ok then
		warn(`[Save] Could not save ({player.Name}): {err}`)
	end
end

-- Önemli bir olaydan (Win, satın alma, pet) sonra kısa süre içinde kaydeder.
-- DataStore limitlerini aşmamak için kayıtlar arası en az MIN_SAVE_INTERVAL saniye bırakılır.
local MIN_SAVE_INTERVAL = 10

local function requestSave(player)
	local profile = profiles[player]
	if not profile or not profile.canSave or profile.savePending then
		return
	end
	profile.savePending = true
	local delay = math.max(0, profile.lastSave + MIN_SAVE_INTERVAL - os.clock())
	task.delay(delay, function()
		profile.savePending = false
		if profiles[player] == profile then
			save(player)
		end
	end)
end

-- 2x güçlendirmeyi başlatır (kind: "boostMuscle" / "boostWins"); süre bitince kazanç yeniden hesaplanır
local function startBoost(player, profile, kind, minutes)
	local seconds = (minutes or Config.BoostMinutes) * 60
	if kind == "boostMuscle" then
		profile.boostMuscleUntil = os.time() + seconds
	else
		profile.boostWinsUntil = os.time() + seconds
	end
	task.delay(seconds + 1, function()
		if profiles[player] == profile then
			refresh(player)
		end
	end)
end

-- Çevrimdışı kazanç: verilen süre (saniye) için bacak kası miktarı = (süre / squat süresi) x tıklama başı kazanç x Rate
local function offlineGain(profile, seconds)
	return math.floor(seconds / Config.MoveDuration.Squat * profile.gain * Config.Offline.Rate)
end

-- DEV: çevrimdışı penceresini yeniden açtırmak için sayaç. Öznitelik değeri aynı kalsa bile (örneğin pencere X ile kapatılmışken
-- aynı kazanç tekrar simüle edilince) istemci OfflineNonce değişimini görüp pencereyi açar.
local offlineNonce = 0
local function pingOfflinePopup(player)
	offlineNonce += 1
	player:SetAttribute("OfflineNonce", offlineNonce)
end

-- Bekleyen çevrimdışı kazancı istemciye yansıtır (OfflinePending > 0 ise CLAIM penceresi açılır). Önce süre, sonra miktar ayarlanır.
local function publishOffline(player, profile)
	local pending = profile.offlinePending > 0
	player:SetAttribute("OfflineSeconds", if pending then profile.offlineSeconds else nil)
	player:SetAttribute("OfflinePending", if pending then profile.offlinePending else nil)
end

local function setup(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local muscle = Instance.new("IntValue")
	muscle.Name = Config.StatLegMuscle
	muscle.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = Config.StatWins
	wins.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = Config.StatLevel
	level.Value = 1
	level.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = Config.StatRebirths
	rebirths.Parent = leaderstats

	leaderstats.Parent = player

	local profile = {
		taps = 0,
		loaded = false,
		canSave = false,
		items = {},
		equippedShoe = "", -- takılı ayakkabı (sahip olunanlardan biri)
		skins = {},
		equippedSkin = "", -- takılı skin (sahip olunanlardan biri)
		pets = {},
		autoDelete = {}, -- [petId] = true: bu pet yumurtadan çıkınca anında silinir
		trails = {},
		equippedTrail = "",
		auras = {},
		equippedAura = "",
		equipped = {}, -- takılı petler (envanterden kopyalar)
		boostMuscleUntil = 0, -- os.time() cinsinden süreli 2x güçlendirme bitişleri
		boostWinsUntil = 0,
		claimedGifts = {}, -- oyun süresi ödülleri (bu oturum)
		offlinePending = 0, -- alınmayı bekleyen çevrimdışı kazanç (bacak kası) ve uzakta geçen süre (saniye)
		offlineSeconds = 0,
		musicLevel = nil, -- teypteki müzik ses kademesi (nil = kaydedilmemiş, istemci varsayılanı kullanır)
		settings = {}, -- oyuncu ayarları (Config.Settings anahtarları: true/false)
		discovered = {}, -- Pet Index: şimdiye kadar sahip olunan pet türleri [id] = true (kalıcı)
		receipts = {}, -- işlenmiş Robux satın alma kimlikleri (aynı satın alma iki kez ödül vermesin)
		sessionStart = workspace:GetServerTimeNow(),
		gain = 1,
		damageMultiplier = 1,
		lastSave = 0,
		savePending = false,
	}
	profiles[player] = profile

	local ok, raw = loadData(player)
	if not player.Parent then
		return -- yüklenirken oyundan çıktı
	end

	local data = sanitize(raw)
	profile.items = data.Items
	profile.equippedShoe = data.EquippedItem
	profile.skins = data.Skins
	profile.equippedSkin = data.EquippedSkin
	profile.musicLevel = data.MusicLevel
	player:SetAttribute("MusicLevel", data.MusicLevel) -- istemci DataLoaded gelince okur
	for _, id in data.Discovered do
		profile.discovered[id] = true
	end
	profile.settings = data.Settings
	for key, value in data.Settings do
		player:SetAttribute(key, value)
	end
	profile.receipts = data.Receipts
	profile.pets = data.Pets
	profile.trails = data.Trails
	profile.equippedTrail = data.EquippedTrail
	profile.auras = data.Auras
	profile.equippedAura = data.EquippedAura
	profile.equipped = data.EquippedPets
	for _, id in data.AutoDelete do
		profile.autoDelete[id] = true
	end
	muscle.Value = data.Muscle
	wins.Value = data.Wins
	level.Value = data.Level
	rebirths.Value = data.Rebirths
	profile.taps = data.Taps
	syncLevel(player) -- level kayıtlı değerden değil toplam bacak kasından hesaplanır

	if ok then
		profile.canSave = true
	else
		player:SetAttribute("DataError", true)
		warn(`[Save] Could not load data for {player.Name}, progress will NOT be saved this session.`)
	end

	profile.loaded = true
	refresh(player)

	-- Çevrimdışı kazanç: uzakta geçen süre için bacak kası birikir ve oyuncu açılan pencerede CLAIM'e basınca verilir (claimOffline).
	-- Alınmadan çıkarsa kayıtlı kalır (OfflinePending), sonraki girişte yeni süreyle birleşir; toplam MaxHours'luk kazancı geçmez.
	profile.offlinePending = data.OfflinePending
	profile.offlineSeconds = data.OfflineSeconds
	local offline = Config.Offline
	if ok and offline and offline.Enabled and data.LastSeen > 0 then
		local maxSeconds = offline.MaxHours * 3600
		local away = math.clamp(os.time() - data.LastSeen, 0, maxSeconds)
		if away >= offline.MinSeconds then
			profile.offlinePending = math.min(profile.offlinePending + offlineGain(profile, away), offlineGain(profile, maxSeconds))
			profile.offlineSeconds = math.min(profile.offlineSeconds + away, maxSeconds)
			requestSave(player)
		end
	end
	publishOffline(player, profile)
	-- Oyun süresi ödülleri için sayaç buradan başlar (istemci aynı sunucu saatiyle geri sayar)
	profile.sessionStart = workspace:GetServerTimeNow()
	player:SetAttribute("SessionStart", profile.sessionStart)
	player:SetAttribute("DataLoaded", true)
end

function PlayerStats.init()
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		friendCounts[player] = nil
	end)

	-- Sunucu kapanırken herkesin verisini kaydet
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				save(player)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait()
		end
	end)

	-- Düzenli otomatik kayıt
	task.spawn(function()
		while true do
			task.wait(Config.Save.AutosaveInterval)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)
end

-- Tıklama başı kazanç kadar bacak kası ekler, yeni toplamı döndürür (veri yüklenmediyse nil)
function PlayerStats.addMuscle(player, areaMultiplier)
	local profile = profiles[player]
	local stat = getStat(player, Config.StatLegMuscle)
	if not profile or not profile.loaded or not stat then
		return nil
	end
	-- Antrenman alanının çarpanı kazanca eklenir (alan dışında 1)
	local gained = math.max(1, math.floor(profile.gain * (areaMultiplier or 1)))
	stat.Value += gained
	return stat.Value, gained
end

-- Verisi başarıyla yüklenmiş ve kaydedilebilir mi? (sıralama tabloları sadece böyle oyuncuları yazar)
function PlayerStats.canSave(player)
	local profile = profiles[player]
	return profile ~= nil and profile.canSave == true
end

-- Antrenman alanı bu oyuncu için açık mı (sunucu doğrulaması): rebirth sayısına bakar
function PlayerStats.isAreaUnlocked(player, area)
	local profile = profiles[player]
	local rebirths = getStat(player, Config.StatRebirths)
	if not profile or not profile.loaded or not rebirths then
		return false
	end
	return areaUnlocked(area, rebirths.Value)
end

-- Level toplam bacak kasından hesaplanır; bu fonksiyon yeni kasa göre leveli günceller. Dönüş: level atladı mı, level
-- Dönüş: level atladı mı, yeni level
function PlayerStats.addTap(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, 1
	end
	local leveledUp, level = syncLevel(player)
	refresh(player)
	if leveledUp then
		requestSave(player)
	end
	return leveledUp, level
end

-- Dönüş: başarılı mı, mesaj
function PlayerStats.rebirth(player, force)
	local profile = profiles[player]
	local levelStat = getStat(player, Config.StatLevel)
	local rebirthStat = getStat(player, Config.StatRebirths)
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not levelStat or not rebirthStat or not muscle or not wins then
		return false, "Loading your data, please wait."
	end

	local maxLevel = Progression.maxLevel(rebirthStat.Value)
	if not force and levelStat.Value < maxLevel then
		return false, `Reach level {maxLevel} to rebirth!`
	end

	rebirthStat.Value += 1
	levelStat.Value = 1
	profile.taps = 0
	muscle.Value = 0
	wins.Value = 0 -- rebirth tüm Win'leri de sıfırlar
	profile.items = {} -- ve ayakkabıları, skinleri de (petler, iz ve aura korunur)
	profile.equippedShoe = ""
	profile.skins = {}
	profile.equippedSkin = ""
	refresh(player)
	requestSave(player)
	return true, `Rebirth {rebirthStat.Value}! Permanent x{Progression.rebirthMultiplier(rebirthStat.Value)} multiplier.`
end

-- Robux ürününün ödülünü verir (product: Config.Shop.Products satırı ya da { kind = "trail"/"aura", id } / { kind = "skip" }).
-- Dönüş: verildi mi
local function applyProduct(player, profile, product)
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not muscle or not wins then
		return false
	end
	if product.kind == "trail" then
		if not Catalog.TrailById[product.id] then
			return false
		end
		if not table.find(profile.trails, product.id) then
			table.insert(profile.trails, product.id)
		end
		profile.equippedTrail = product.id
	elseif product.kind == "aura" then
		if not Catalog.AuraById[product.id] then
			return false
		end
		if not table.find(profile.auras, product.id) then
			table.insert(profile.auras, product.id)
		end
		profile.equippedAura = product.id
	elseif product.kind == "skip" then
		-- Level şartını atlayarak rebirth (sunucuda yapılır; duvarları sıfırlamayı Purchases çağırır)
		return (PlayerStats.rebirth(player, true))
	elseif product.kind == "boostMuscle" or product.kind == "boostWins" then
		startBoost(player, profile, product.kind, product.minutes)
	elseif product.kind == "wins" then
		wins.Value += product.amount
	elseif product.kind == "stageWins" then
		wins.Value += Layout.reward(product.stage)
	elseif product.kind == "moves" then
		muscle.Value += product.amount * profile.gain
		syncLevel(player)
	elseif product.kind == "offlineDouble" then
		-- 'DOUBLE IT!': bekleyen çevrimdışı kazancın 2 katını verir (bekleyen yoksa, örneğin başka yoldan alınmışsa, 4 saatlik kazanç)
		local pending = profile.offlinePending
		local amount = if pending > 0 then pending * 2 else offlineGain(profile, 4 * 3600)
		profile.offlinePending = 0
		profile.offlineSeconds = 0
		muscle.Value += amount
		publishOffline(player, profile)
		syncLevel(player)
	else
		return false
	end
	refresh(player)
	return true
end

-- ProcessReceipt'ten çağrılır: satın almayı işler. Dönüş: işlendi mi (false = Roblox daha sonra tekrar dener).
-- Aynı purchaseId ikinci kez gelirse ödül TEKRAR verilmez ama işlendi sayılır. Kaydedilemeyecek oyuncuya (veri yüklenemedi) verilmez.
function PlayerStats.processPurchase(player, purchaseId, product)
	local profile = profiles[player]
	if not profile or not profile.loaded or not profile.canSave then
		return false
	end
	if table.find(profile.receipts, purchaseId) then
		return true
	end
	if not applyProduct(player, profile, product) then
		return false
	end
	table.insert(profile.receipts, purchaseId)
	if #profile.receipts > 300 then
		table.remove(profile.receipts, 1)
	end
	requestSave(player)
	return true
end

-- Ayakkabıdan gelen duvar hasar çarpanı (ayakkabı yoksa 1)
function PlayerStats.getDamageMultiplier(player)
	local profile = profiles[player]
	return profile and profile.damageMultiplier or 1
end

function PlayerStats.addWin(player, amount)
	local profile = profiles[player]
	local stat = getStat(player, Config.StatWins)
	if profile and profile.loaded and stat then
		local boost = if os.time() < profile.boostWinsUntil then 2 else 1
		stat.Value += (amount or 1) * boost
		requestSave(player)
	end
end

-- Ayakkabı rafındaki postamente basınca: sahip olunan ayakkabı takılır (ucuz/zayıf olanlar da kullanılabilir),
-- sahip olunmayan Win ile alınır ve hemen takılır. Dönüş: başarılı mı, mesaj (zaten takılıysa mesaj nil)
function PlayerStats.buyItem(player, itemId)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not wins then
		return false, "Loading your data, please wait."
	end

	local item = Catalog.ItemById[itemId]
	if not item then
		return false, "That item does not exist."
	end

	if table.find(profile.items, itemId) then
		if profile.equippedShoe == itemId then
			return true, nil
		end
		profile.equippedShoe = itemId
		refresh(player)
		requestSave(player)
		return true, `Equipped {item.name}`
	end

	if wins.Value < item.price then
		return false, `Not enough Wins (need {item.price}).`
	end

	wins.Value -= item.price
	table.insert(profile.items, itemId)
	profile.equippedShoe = itemId
	refresh(player)
	requestSave(player)
	return true, `Bought {item.name}!`
end

-- Skin rafındaki postamente basınca: sahip olunan skin takılır (rengi ve çarpanı değişir), sahip olunmayan Win ile
-- alınır ve hemen takılır. Dönüş: başarılı mı, mesaj (zaten takılıysa mesaj nil)
function PlayerStats.buySkin(player, skinId)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not wins then
		return false, "Loading your data, please wait."
	end

	local skin = Catalog.SkinById[skinId]
	if not skin then
		return false, "That skin does not exist."
	end

	if table.find(profile.skins, skinId) then
		if profile.equippedSkin == skinId then
			return true, nil
		end
		profile.equippedSkin = skinId
		refresh(player)
		requestSave(player)
		return true, `Equipped {skin.name} skin (x{skin.mult} muscle)`
	end

	if wins.Value < skin.price then
		return false, `Not enough Wins (need {skin.price}).`
	end

	wins.Value -= skin.price
	table.insert(profile.skins, skinId)
	profile.equippedSkin = skinId
	refresh(player)
	requestSave(player)
	return true, `Bought {skin.name} skin! (x{skin.mult} muscle)`
end

-- Yumurtanın pet havuzundan ağırlıklarına göre rastgele pet seçer
local function rollPet(egg)
	local total = 0
	for _, entry in egg.pets do
		total += entry.weight
	end
	local roll = rng:NextNumber() * total
	for _, entry in egg.pets do
		roll -= entry.weight
		if roll <= 0 then
			return Catalog.PetById[entry.id]
		end
	end
	return Catalog.PetById[egg.pets[#egg.pets].id]
end

-- Pet listesini "Dragon x1, Cat x2" şeklinde özetler (en güçlüden başlayarak)
local function summarize(pets)
	local counts, order = {}, {}
	for _, pet in pets do
		if not counts[pet.id] then
			counts[pet.id] = 0
			table.insert(order, pet)
		end
		counts[pet.id] += 1
	end
	table.sort(order, function(a, b)
		return a.mult > b.mult
	end)
	local parts = {}
	for _, pet in order do
		table.insert(parts, `{pet.name} x{counts[pet.id]}`)
	end
	return table.concat(parts, ", ")
end

-- count kadar yumurta açar (Win veya pet envanteri yettiği kadar). Çarpı ile işaretlenmiş petler (autoDelete)
-- envantere girmeden anında silinir ama yumurta ücreti yine alınır. Dönüş: başarılı mı, mesaj
function PlayerStats.hatchEgg(player, eggId, count)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not wins then
		return false, "Loading your data, please wait."
	end
	local egg = Catalog.EggById[eggId]
	if not egg then
		return false, "That egg does not exist."
	end
	local maxCount = Config.EggMultiOptions[#Config.EggMultiOptions]
	count = math.clamp(math.floor(count or 1), 1, maxCount)

	local kept, deleted = {}, {}
	local results = {} -- açılış sırasıyla { id, kept }: istemcideki açılış ekranı için
	for _ = 1, count do
		if wins.Value < egg.price then
			break
		end
		local pet = rollPet(egg)
		local willDelete = profile.autoDelete[pet.id]
		if not willDelete and #profile.pets >= Config.MaxOwnedPets then
			break
		end
		wins.Value -= egg.price
		table.insert(results, { id = pet.id, kept = not willDelete })
		if willDelete then
			table.insert(deleted, pet)
		else
			table.insert(profile.pets, pet.id)
			if #profile.equipped < Config.MaxEquippedPets then
				table.insert(profile.equipped, pet.id)
			end
			table.insert(kept, pet)
		end
	end

	if #kept + #deleted == 0 then
		if wins.Value < egg.price then
			return false, `Not enough Wins (need {egg.price}).`
		end
		return false, "Your pet inventory is full. Mark unwanted pets with an X to auto-delete them."
	end

	refresh(player)
	requestSave(player)

	if #kept == 1 and #deleted == 0 then
		local pet = kept[1]
		return true, `Hatched {pet.name}! (+{math.floor(pet.mult * 100 + 0.5)}% muscle)`, results
	end
	if #kept == 0 and #deleted == 1 then
		return true, `{deleted[1].name} was auto-deleted`, results
	end

	local parts = {}
	if #kept > 0 then
		table.insert(parts, `Hatched {#kept}: {summarize(kept)}`)
	end
	if #deleted > 0 then
		table.insert(parts, `Deleted {#deleted}: {summarize(deleted)}`)
	end
	return true, table.concat(parts, " | "), results
end

-- Bir oyuncu ayarını (Config.Settings) kaydeder ve istemciye öznitelik olarak yansıtır. Dönüş: başarılı mı
function PlayerStats.setSetting(player, key, value)
	local profile = profiles[player]
	if not profile or not profile.loaded or type(key) ~= "string" or type(value) ~= "boolean" or not SETTING_KEYS[key] then
		return false
	end
	profile.settings[key] = value
	player:SetAttribute(key, value)
	requestSave(player)
	return true
end

-- Çevrimdışı kazancı verir (CLAIM butonu). Miktarı sunucu tutar, istemci miktar yollamaz. Dönüş: başarılı mı, mesaj
function PlayerStats.claimOffline(player)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	if not profile or not profile.loaded or not muscle then
		return false, "Loading your data, please wait."
	end
	local amount = profile.offlinePending
	if amount <= 0 then
		return false, "Nothing to claim."
	end
	profile.offlinePending = 0
	profile.offlineSeconds = 0
	muscle.Value += amount
	publishOffline(player, profile)
	syncLevel(player)
	refresh(player)
	requestSave(player)
	return true, `Claimed +{Format.compact(amount)} Leg Muscle!`
end

-- Sunucudaki arkadaş sayısını bildirir (server/FriendBonus); kazanç çarpanı hemen yeniden hesaplanır
function PlayerStats.setFriendCount(player, count)
	friendCounts[player] = count
	local profile = profiles[player]
	if profile and profile.loaded then
		refresh(player)
	end
end

-- Teypin müzik ses kademesini kaydeder (istemci değiştirdikten kısa süre sonra bildirir). Dönüş: başarılı mı
function PlayerStats.setMusicLevel(player, level)
	local profile = profiles[player]
	if not profile or not profile.loaded or type(level) ~= "number" or level ~= level then
		return false
	end
	profile.musicLevel = math.clamp(math.floor(level), 0, Config.Music.maxLevel)
	player:SetAttribute("MusicLevel", profile.musicLevel)
	requestSave(player)
	return true
end

-- Bir petin "yumurtadan çıkınca anında sil" işaretini açar/kapatır. Dönüş: başarılı mı, mesaj
function PlayerStats.toggleAutoDelete(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local pet = Catalog.PetById[petId]
	if not pet then
		return false, "That pet does not exist."
	end
	if profile.autoDelete[petId] then
		profile.autoDelete[petId] = nil
	else
		profile.autoDelete[petId] = true
	end
	refresh(player)
	requestSave(player)
	return true, if profile.autoDelete[petId] then `{pet.name} will be auto-deleted` else `{pet.name} will be kept`
end

-- Win ile iz satın alır ve hemen takar. Dönüş: başarılı mı, mesaj
function PlayerStats.buyTrail(player, trailId)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not wins then
		return false, "Loading your data, please wait."
	end
	local trail = Catalog.TrailById[trailId]
	if not trail then
		return false, "That trail does not exist."
	end
	if table.find(profile.trails, trailId) then
		return false, "You already own this trail."
	end
	if wins.Value < trail.winPrice then
		return false, `Not enough Wins (need {trail.winPrice}).`
	end

	wins.Value -= trail.winPrice
	table.insert(profile.trails, trailId)
	profile.equippedTrail = trailId
	refresh(player)
	requestSave(player)
	return true, `Bought {trail.name}! (+{trail.speed} speed)`
end

-- Sahip olunan bir izi takar; zaten takılıysa çıkarır (trailId boş string = izi çıkar). Dönüş: başarılı mı, mesaj
function PlayerStats.equipTrail(player, trailId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	if trailId == "" or profile.equippedTrail == trailId then
		profile.equippedTrail = ""
		refresh(player)
		requestSave(player)
		return true, "Trail removed"
	end
	local trail = Catalog.TrailById[trailId]
	if not trail or not table.find(profile.trails, trailId) then
		return false, "You do not own this trail."
	end
	profile.equippedTrail = trailId
	refresh(player)
	requestSave(player)
	return true, `Equipped {trail.name}`
end

-- Win ile aura satın alır ve hemen takar. Dönüş: başarılı mı, mesaj
function PlayerStats.buyAura(player, auraId)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not wins then
		return false, "Loading your data, please wait."
	end
	local aura = Catalog.AuraById[auraId]
	if not aura then
		return false, "That aura does not exist."
	end
	if table.find(profile.auras, auraId) then
		return false, "You already own this aura."
	end
	if wins.Value < aura.winPrice then
		return false, `Not enough Wins (need {aura.winPrice}).`
	end

	wins.Value -= aura.winPrice
	table.insert(profile.auras, auraId)
	profile.equippedAura = auraId
	refresh(player)
	requestSave(player)
	return true, `Bought {aura.name}! (x{aura.mult} muscle)`
end

-- Sahip olunan bir auranın takılı/çıkarılı durumunu değiştirir (boş id = çıkar). Dönüş: başarılı mı, mesaj
function PlayerStats.equipAura(player, auraId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	if auraId == "" or profile.equippedAura == auraId then
		profile.equippedAura = ""
		refresh(player)
		requestSave(player)
		return true, "Aura removed"
	end
	local aura = Catalog.AuraById[auraId]
	if not aura or not table.find(profile.auras, auraId) then
		return false, "You do not own this aura."
	end
	profile.equippedAura = auraId
	refresh(player)
	requestSave(player)
	return true, `Equipped {aura.name}`
end

-- ---------- Pet envanteri: takma, çıkarma, silme ----------

-- Bir pet kopyasını takar (envanterde takılmamış kopya ve boş yuva olmalı)
function PlayerStats.equipPet(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local pet = Catalog.PetById[petId]
	if not pet then
		return false, "That pet does not exist."
	end
	if #profile.equipped >= Config.MaxEquippedPets then
		return false, `You can equip only {Config.MaxEquippedPets} pets.`
	end
	if countOf(profile.equipped, petId) >= countOf(profile.pets, petId) then
		return false, "You have no free copy of this pet."
	end
	table.insert(profile.equipped, petId)
	refresh(player)
	requestSave(player)
	return true, `Equipped {pet.name}`
end

function PlayerStats.unequipPet(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local index = table.find(profile.equipped, petId)
	if not index then
		return false, "That pet is not equipped."
	end
	table.remove(profile.equipped, index)
	refresh(player)
	requestSave(player)
	return true, `Unequipped {Catalog.PetById[petId].name}`
end

function PlayerStats.equipBestPets(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	profile.equipped = bestEquipped(profile.pets)
	refresh(player)
	requestSave(player)
	return true, "Equipped your best pets"
end

function PlayerStats.unequipAllPets(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	profile.equipped = {}
	refresh(player)
	requestSave(player)
	return true, "Unequipped all pets"
end

-- Bir pet kopyasını siler (takılı kopya sayısı kalanı aşıyorsa fazla takılı kopya da çıkarılır)
function PlayerStats.deletePet(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local pet = Catalog.PetById[petId]
	local index = table.find(profile.pets, petId)
	if not pet or not index then
		return false, "You do not own this pet."
	end
	table.remove(profile.pets, index)
	if countOf(profile.equipped, petId) > countOf(profile.pets, petId) then
		table.remove(profile.equipped, table.find(profile.equipped, petId))
	end
	refresh(player)
	requestSave(player)
	return true, `Deleted {pet.name}`
end

-- ---------- Oyun süresi ödülleri ----------

-- index. ödülü alır: süresi dolmuş ve bu oturumda alınmamış olmalı. Dönüş: başarılı mı, mesaj
function PlayerStats.claimGift(player, index)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not muscle or not wins then
		return false, "Loading your data, please wait."
	end
	local reward = Config.GiftRewards[index]
	if type(index) ~= "number" or not reward then
		return false, "That reward does not exist."
	end
	if profile.claimedGifts[index] then
		return false, "You already claimed this reward."
	end
	if workspace:GetServerTimeNow() - profile.sessionStart < reward.time then
		return false, "This reward is not ready yet."
	end

	local message
	if reward.kind == "muscle" then
		muscle.Value += reward.amount
		message = `+{reward.amount} Leg Muscle`
	elseif reward.kind == "wins" then
		wins.Value += reward.amount
		message = `+{reward.amount} Wins`
	elseif reward.kind == "pet" then
		local pet = Catalog.PetById[reward.pet]
		if #profile.pets >= Config.MaxOwnedPets then
			return false, "Your pet inventory is full."
		end
		table.insert(profile.pets, pet.id)
		if #profile.equipped < Config.MaxEquippedPets then
			table.insert(profile.equipped, pet.id)
		end
		message = `New pet: {pet.name}!`
	elseif reward.kind == "boostMuscle" or reward.kind == "boostWins" then
		startBoost(player, profile, reward.kind)
		message = if reward.kind == "boostMuscle"
			then `2x Leg Muscle for {Config.BoostMinutes} minutes!`
			else `2x Wins for {Config.BoostMinutes} minutes!`
	else
		return false, "Unknown reward."
	end

	profile.claimedGifts[index] = true
	refresh(player)
	requestSave(player)
	return true, message
end

-- TEST ARAÇLARI: sadece DevTools modülü, sahiplik kontrolünden sonra çağırır.
-- Dönüş: başarılı mı, mesaj
function PlayerStats.dev(player, command, amount)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	local levelStat = getStat(player, Config.StatLevel)
	local rebirthStat = getStat(player, Config.StatRebirths)
	if not profile or not profile.loaded or not muscle or not wins or not levelStat or not rebirthStat then
		return false, "Data is not loaded yet."
	end
	amount = if type(amount) == "number" then math.clamp(math.floor(amount), 0, 1e15) else 0

	local message
	if command == "AddLevel" then
		local maxLevel = Progression.maxLevel(rebirthStat.Value)
		-- Level toplam kastan türetildiği için, hedef levelin gerektirdiği kası ver
		local target = math.min(levelStat.Value + amount, maxLevel)
		muscle.Value = math.max(muscle.Value, Progression.cumulativeMuscle(target))
		message = `Level is now {levelStat.Value} (max {maxLevel})`
	elseif command == "MaxLevel" then
		muscle.Value = math.max(muscle.Value, Progression.cumulativeMuscle(Progression.maxLevel(rebirthStat.Value)))
		message = `Level set to max ({levelStat.Value}) - you can rebirth now`
	elseif command == "AddRebirth" then
		rebirthStat.Value += if amount > 0 then amount else 1
		levelStat.Value = 1
		profile.taps = 0
		muscle.Value = 0
		message = `Rebirths: {rebirthStat.Value} (level and muscle reset)`
	elseif command == "AddWins" then
		wins.Value += amount
		message = `+{amount} Wins`
	elseif command == "AddMuscle" then
		muscle.Value += amount
		message = `+{amount} Leg Muscle`
	elseif command == "AllShoes" then
		profile.items = {}
		for _, item in Config.Items do
			table.insert(profile.items, item.id)
		end
		message = "All shoes unlocked"
	elseif command == "AllSkins" then
		profile.skins = {}
		for _, skin in Config.Skins do
			table.insert(profile.skins, skin.id)
		end
		message = "All skins unlocked"
	elseif command == "FreePet" then
		if #profile.pets >= Config.MaxOwnedPets then
			return false, "Your pet inventory is full."
		end
		local pet = rollPet(Config.Eggs[rng:NextInteger(1, #Config.Eggs)])
		table.insert(profile.pets, pet.id)
		message = `Free pet: {pet.name}`
	elseif command == "DiscoverAll" then
		-- Pet Index'i denemek için bütün petleri keşfedilmiş sayar
		for _, pet in Config.Pets do
			profile.discovered[pet.id] = true
		end
		message = "All pets discovered in the Index"
	elseif command == "FakeFriends" then
		-- Studio'da arkadaş olmadan bonusu denemek için sahte arkadaş sayısı (gerçek sayım bir sonraki giriş/çıkışta üzerine yazar)
		friendCounts[player] = math.clamp(amount, 0, 20)
		message = `Fake friends: {friendCounts[player]}`
	elseif command == "GiftTime" then
		-- Gifts / FREE REWARD sandığı için oyun süresini ileri sarar
		profile.sessionStart -= (if amount > 0 then amount else 10) * 60
		player:SetAttribute("SessionStart", profile.sessionStart)
		message = `Playtime +{if amount > 0 then amount else 10} min (gift timers)`
	elseif command == "SimulateOffline" then
		-- Seçilen saat kadar uzakta kalınmış gibi bekleyen kazanç oluşturur ve pencereyi açar
		local hours = math.clamp(if amount > 0 then amount else 3, 1, Config.Offline.MaxHours)
		profile.offlineSeconds = math.floor(hours * 3600)
		profile.offlinePending = math.max(1, offlineGain(profile, profile.offlineSeconds))
		publishOffline(player, profile)
		pingOfflinePopup(player)
		message = `Offline earnings simulated ({hours}h): use CLAIM in the popup`
	elseif command == "ShowOffline" then
		-- Bekleyen kazanç varsa pencereyi yeniden açar (X ile kapatılmışsa); yoksa 3 saatlik kazanç oluşturur
		if profile.offlinePending <= 0 then
			profile.offlineSeconds = 3 * 3600
			profile.offlinePending = math.max(1, offlineGain(profile, profile.offlineSeconds))
			publishOffline(player, profile)
		end
		pingOfflinePopup(player)
		message = "Offline earnings popup opened"
	elseif command == "ClearOffline" then
		profile.offlinePending = 0
		profile.offlineSeconds = 0
		publishOffline(player, profile)
		message = "Pending offline earnings cleared"
	elseif command == "Reset" then
		muscle.Value = 0
		wins.Value = 0
		levelStat.Value = 1
		rebirthStat.Value = 0
		profile.taps = 0
		profile.items = {}
		profile.equippedShoe = ""
		profile.skins = {}
		profile.equippedSkin = ""
		profile.pets = {}
		profile.autoDelete = {}
		profile.trails = {}
		profile.equippedTrail = ""
		profile.auras = {}
		profile.equippedAura = ""
		profile.equipped = {}
		profile.boostMuscleUntil = 0
		profile.boostWinsUntil = 0
		profile.discovered = {}
		profile.offlinePending = 0
		profile.offlineSeconds = 0
		publishOffline(player, profile)
		message = "Everything reset to zero"
	else
		return false, "Unknown command."
	end

	syncLevel(player)
	refresh(player)
	requestSave(player)
	return true, message
end

return PlayerStats
