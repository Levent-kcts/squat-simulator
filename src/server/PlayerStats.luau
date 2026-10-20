local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Progression = require(Shared:WaitForChild("Progression"))
local Layout = require(Shared:WaitForChild("Layout"))
local Format = require(Shared:WaitForChild("Format"))
local PaidRandomPolicy = require(script.Parent.PaidRandomPolicy)
local okBadges, Badges = pcall(require, script.Parent.Badges) -- Roblox rozetleri: yüklenemezse atlanır
local okEvents, ServerEvents = pcall(require, script.Parent.ServerEvents) -- Power Hour: yüklenemezse çarpan 1 kalır
local okAnalytics, Analytics = pcall(require, script.Parent.Analytics) -- ölçüm (Economy / Custom Events): yüklenemezse atlanır
local okFeed, GlobalFeed = pcall(require, script.Parent.GlobalFeed) -- çapraz sunucu duyuru akışı: yüklenemezse duyuru atlanır, oyun etkilenmez

local PlayerStats = {}

local store = DataStoreService:GetDataStore(Config.Save.StoreName)

-- OTURUM KİLİDİ (yayın öncesi veri güvenliği): oyuncu bir sunucudan çıkıp hızla başkasına girince eski sunucunun son kaydı yeni sunucunun ilerlemesinin (ya da satın alınan şeyin) üstüne yazmasın.
-- Kayıtta 'Lock = { id, t }' tutulur (id = bu sunucunun rastgele kimliği, t = son kayıt zamanı). Başka sunucunun TAZE kilidi (LOCK_STALE saniyeden yeni) varsa yüklemede LOCK_WAIT saniye beklenir (o sunucu çıkış kaydında kilidi bırakır),
-- sonra kilit çökmüş sunucudan kalmış sayılıp devralınır. Kilidi kaybeden sunucu o oyuncu için KAYDETMEYİ bırakır (yeni sunucunun verisini ezmesin). Çıkış/kapanış kaydı kilidi bırakır.
local SERVER_ID = HttpService:GenerateGUID(false)
local LOCK_STALE = 120 -- saniye: bu kadar süredir kayıt yapmayan sunucunun kilidi artık geçersizdir (otomatik kayıt 30 sn'de bir kilidi yeniler)
local LOCK_WAIT = if RunService:IsStudio() then 0 else 24 -- saniye: başka sunucunun taze kilidi için en çok bu kadar beklenir (Studio'da beklenmez: Stop ile kapatılan test oturumları kilidi bırakamayabilir)

local function lockedByOther(record)
	local lock = type(record) == "table" and record.Lock
	return type(lock) == "table" and lock.id ~= SERVER_ID and os.time() - (tonumber(lock.t) or 0) < LOCK_STALE
end
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

-- Pet envanterinin dolu sayılacağı sınır: başlangıç yeri + Shop'tan alınan ek yerler (profile.petSlots)
local function petCapacity(profile)
	return Config.MaxOwnedPets + profile.petSlots
end

-- İksirler (Config.Potions): field = profile.boostMuscleUntil / boostWinsUntil / boostLuckUntil. Rainbow Potion hepsini birden sağlar ('bütün iksirlerden almışsın gibi').
-- Etki hep Config.Potions.Mult katıdır; aynı etki iki kaynaktan gelse de üst üste çarpmaz.
local POTION_FIELD = {
	boostLuck = "boostLuckUntil",
	boostMuscle = "boostMuscleUntil",
	boostWins = "boostWinsUntil",
	boostRainbow = "boostRainbowUntil",
	boostAuto = "boostAutoUntil", -- Auto Click Potion: Rainbow BUNU İÇERMEZ (aşağıda potionActive), sabit 30 dk (Config.Potions.AutoMinutes)
}
local function potionActive(profile, field)
	local now = os.time()
	if field == "boostAutoUntil" then
		return now < profile[field] -- Rainbow Potion Auto Click Potion'ı kapsamaz
	end
	return now < profile[field] or now < profile.boostRainbowUntil
end

-- AUTO CLICK POTION SAHİBİ KURALI (2026-10-13, sahibi 'eğer kişi auto clicki satın aldıysa bu potion olan her yerde rainbow potion gelsin' dedi): Auto Click game pass'i olan (HasAutoClick, server/AutoClickPass; pass satışı yokken herkes)
-- oyuncuya Auto Click Potion yerine Config.Potions.AutoOwnerReplacement (Rainbow Potion) verilir: günlük görev bonusu, çark, DEV ve envanterdeki eski iksirler.
local function ownsAutoPass(player)
	return player:GetAttribute("HasAutoClick") == true
end
-- Auto Click Potion yerine verilecek iksir: dönüş (kind, dakika)
local function autoPotionReward(player)
	if ownsAutoPass(player) then
		local replacement = Config.Potions.AutoOwnerReplacement
		return replacement.kind, replacement.minutes
	end
	return "boostAuto", Config.Potions.AutoMinutes
end

-- 'Luck Potion! 2x Egg Luck for 10 minutes!' gibi ödül mesajı
local function potionMessage(kind, minutes)
	local potion = Catalog.PotionByKind[kind]
	return `{potion.name}! {potion.effect} for {minutes or Config.BoostMinutes} minutes!`
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

-- ---------- Günlük görevler (Config.Quests) ----------
-- Gün sayısı UTC'dir (os.time() / 86400); aynı gün herkes aynı görevleri görür. Durum: { day, progress = {n,n,n}, claimed = {b,b,b}, bonus = b }

local function currentQuestDay()
	return math.floor(os.time() / 86400)
end

local function newQuestState(day)
	local progress, claimed = {}, {}
	for slot = 1, Config.Quests.PerDay do
		progress[slot] = 0
		claimed[slot] = false
	end
	return { day = day, progress = progress, claimed = claimed, bonus = false }
end

-- Günün görevleri (slot sırasıyla kolay, orta, zor): gün sayısıyla tohumlanır, hardOnly görevler sadece son slota girer
local questCache = {}
local function questsForDay(day)
	local cached = questCache[day]
	if cached then
		return cached
	end
	local random = Random.new(day * 7919 + 13)
	local pool = Config.Quests.Pool
	local used = {}
	local list = {}
	for slot = 1, Config.Quests.PerDay do
		local candidates = {}
		for index, definition in pool do
			if not used[index] and (not definition.hardOnly or slot == Config.Quests.PerDay) then
				table.insert(candidates, index)
			end
		end
		local index = candidates[random:NextInteger(1, #candidates)]
		used[index] = true
		local definition = pool[index]
		local goal = definition.goals[math.min(slot, #definition.goals)]
		table.insert(list, { id = definition.id, text = (string.gsub(definition.text, "{goal}", tostring(goal))), goal = goal })
	end
	questCache[day] = list
	return list
end

-- Gün değiştiyse görev durumunu sıfırlar
local function ensureQuestDay(profile)
	if profile.quests.day ~= currentQuestDay() then
		profile.quests = newQuestState(currentQuestDay())
	end
end

-- Oyuncunun o sıralar oynadığı tahmini aşamanın Win ödülü (rebirth sayısından): günlük görev ve çark Win ödülleri bununla ölçeklenir
local function estimatedStageReward(player)
	local rebirthStat = getStat(player, Config.StatRebirths)
	local rebirths = if rebirthStat then rebirthStat.Value else 0
	local stage = math.clamp(math.floor(2 + 2.6 * math.log(1 + rebirths) + 0.5), 1, Layout.StageCount)
	return Layout.reward(stage)
end

-- Slotun ödülü: kind ('muscle' / 'wins') ve miktar. Miktar oyuncunun gücüne göre ölçeklenir (kas: tıklama başı kazanç, Win: tahmini aşama ödülü)
local function questReward(profile, player, slot)
	local definition = Config.Quests.Rewards[slot]
	if definition.kind == "muscle" then
		return "muscle", math.max(100, math.floor(profile.gain * definition.clicks))
	end
	return "wins", estimatedStageReward(player) * definition.mult
end

local function rewardText(kind, amount)
	return if kind == "muscle" then `+{Format.compact(amount)} Leg Muscle` else `+{Format.compact(amount)} Wins`
end

-- GÜNLÜK GİRİŞ ÖDÜLÜ: durum öznitelikleri (istemci client/LoginPanel okur): LoginNext (sıradaki gün 1-7), LoginReady (bugün alınabilir mi), LoginTotal
local function publishLogin(player, profile)
	player:SetAttribute("LoginNext", profile.login.next)
	player:SetAttribute("LoginReady", profile.login.last ~= currentQuestDay())
	player:SetAttribute("LoginTotal", profile.login.total)
end

-- Görev durumunu istemciye JSON öznitelik olarak yazar ('QuestData'; client/QuestPanel okur)
local function publishQuests(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	ensureQuestDay(profile)
	local state = profile.quests
	local entries = {}
	for slot, quest in questsForDay(state.day) do
		local kind, amount = questReward(profile, player, slot)
		table.insert(entries, {
			id = quest.id,
			text = quest.text,
			goal = quest.goal,
			progress = state.progress[slot],
			claimed = state.claimed[slot],
			reward = rewardText(kind, amount),
		})
	end
	player:SetAttribute(
		"QuestData",
		HttpService:JSONEncode({
			resetAt = (state.day + 1) * 86400,
			quests = entries,
			bonusClaimed = state.bonus,
			bonusText = (function()
				local autoKind, autoMinutes = autoPotionReward(player)
				return `Rainbow Potion {Config.Quests.BonusBoostMinutes}m + {Catalog.PotionByKind[autoKind].name} {autoMinutes}m`
			end)(),
		})
	)
end

-- Günlük çark (Config.Wheel): bugün (UTC gün) çevrildi mi? İstemci (client/WheelController) 'WheelReady' ve bir sonraki hak zamanını ('WheelNext', epoch saniye) okur
local function publishWheel(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local today = currentQuestDay()
	player:SetAttribute("WheelReady", profile.wheelDay ~= today)
	player:SetAttribute("WheelNext", (today + 1) * 86400)
end

-- Geçerli dünya kimlikleri (Config.Worlds.List)
local validWorlds = {}
for index, def in Config.Worlds.List do
	validWorlds[def.id or index] = true
end

-- Dünya öznitelikleri: 'World' (bulunulan), 'WorldsUnlocked' ('1,2'); istemci (kemer yazısı, duvarlar, rehber) bunları okur
local function publishWorlds(player, profile)
	local list = {}
	for id in profile.worlds do
		table.insert(list, id)
	end
	table.sort(list)
	player:SetAttribute("WorldsUnlocked", table.concat(list, ","))
	player:SetAttribute("World", profile.world)
end

-- Kayıtlı veriyi güvenli hale getirir (bozuk/eksik/silinmiş eşya id'lerine karşı)
local function sanitize(raw)
	local data = { Muscle = 0, LifetimeMuscle = 0, WhatsNew = 0, Event = {}, Training = {}, Login = { next = 1, last = -1, total = 0 }, Codes = {}, Referral = { by = 0, paid = false, secs = 0 }, Wins = 0, Level = 1, Taps = 0, Rebirths = 0, Items = {}, Pets = {}, AutoDelete = {}, Trails = {}, EquippedTrail = "", Auras = {}, EquippedAura = "", Skins = {}, EquippedItem = "", EquippedSkin = "", LastSeen = 0, OfflinePending = 0, OfflineSeconds = 0, Receipts = {}, EquippedPets = {}, Settings = {}, Discovered = {}, WheelDay = 0, PetSlots = 0, PotionItems = {}, BoostUntil = {}, TutorialDone = false, TutorialClicks = 0, Quests = newQuestState(0),
		StarterWins = false, AutoTrial = Config.AutoClick.TrialSeconds or 0, Funnel = {}, IndexRewards = {}, StarterDone = {}, StarterClaimed = {}, WallsBroken = 0, Flags = {}, GuideSeen = {}, Worlds = { 1 }, World = 1 }
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
	if type(raw.WheelDay) == "number" then
		data.WheelDay = math.max(0, math.floor(raw.WheelDay)) -- çarkın son çevrildiği UTC gün
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
	if type(raw.PetSlots) == "number" then
		data.PetSlots = math.clamp(math.floor(raw.PetSlots), 0, Config.MaxExtraPetSlots)
	end
	-- İksir envanteri (sku -> adet) ve etkin iksirlerin bitiş zamanları (os.time, iksir id -> saniye); bilinmeyen ürünler atılır
	if type(raw.PotionItems) == "table" then
		for sku, count in raw.PotionItems do
			if type(sku) == "string" and Catalog.PotionSkuById[sku] and type(count) == "number" and count >= 1 then
				data.PotionItems[sku] = math.min(math.floor(count), 9999)
			end
		end
	end
	if type(raw.BoostUntil) == "table" then
		for _, potion in Config.Potions.List do
			local untilTime = raw.BoostUntil[potion.id]
			if type(untilTime) == "number" then
				data.BoostUntil[potion.id] = untilTime
			end
		end
	end
	if type(raw.Pets) == "table" then
		for _, id in raw.Pets do
			if Catalog.PetById[id] and #data.Pets < Config.MaxOwnedPets + data.PetSlots then
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
	if type(raw.Quests) == "table" and type(raw.Quests.day) == "number" then
		local quests = raw.Quests
		data.Quests.day = math.floor(quests.day)
		for slot = 1, Config.Quests.PerDay do
			local value = 0
			if type(quests.progress) == "table" and type(quests.progress[slot]) == "number" then
				value = math.max(0, math.floor(quests.progress[slot]))
			end
			data.Quests.progress[slot] = value
			data.Quests.claimed[slot] = type(quests.claimed) == "table" and quests.claimed[slot] == true
		end
		data.Quests.bonus = quests.bonus == true
	end
	if type(raw.TutorialClicks) == "number" then
		data.TutorialClicks = math.clamp(math.floor(raw.TutorialClicks), 0, Config.Tutorial.ClickGoal)
	end
	-- Eğitim: kayıtlı true ise bitmiştir; eski kayıtta alan yoksa ilerlemesi olan oyuncu eski oyuncudur (eğitim görmez), tamamen yeni oyuncu görür
	if raw.TutorialDone == true then
		data.TutorialDone = true
	elseif raw.TutorialDone == nil
		and (data.Muscle > 0 or data.Wins > 0 or data.Rebirths > 0 or #data.Items > 0 or #data.Skins > 0 or #data.Pets > 0) then
		data.TutorialDone = true
	end
	-- RETENTION (2026-10-13): başlangıç Win hediyesi, ücretsiz Auto Click denemesi ve level kilometre taşı ödülleri YENİ oyuncuya (eğitimi bitmemiş) verilir; eski oyuncuya geriye dönük VERİLMEZ
	if raw.StarterWins == true or (raw.StarterWins == nil and data.TutorialDone) then
		data.StarterWins = true
	end
	if type(raw.AutoTrial) == "number" then
		data.AutoTrial = math.clamp(math.floor(raw.AutoTrial), 0, Config.AutoClick.TrialSeconds or 0)
	elseif data.TutorialDone then
		data.AutoTrial = 0
	end
	-- Pet Index ödülleri: geriye dönük VERİLİR (eski oyuncu ulaştığı eşiklerin ödülünü bir sonraki yenilemede alır)
	if type(raw.IndexRewards) == "table" then
		for _, count in raw.IndexRewards do
			if type(count) == "number" then
				data.IndexRewards[math.floor(count)] = true
			end
		end
	end
	-- YENİ OYUNCU GÖREVLERİ ve REHBER TURU (2026-10-13): kayıtlı kimlikler doğrulanır; eski oyuncuda (eğitimi bitmiş) görevler 'alınmış', rehber adımları 'görülmüş' sayılır (geriye dönük ödül/tur YOK)
	local function readIds(source, target, valid)
		if type(source) ~= "table" then
			return false
		end
		for _, id in source do
			if type(id) == "string" and valid[id] then
				target[id] = true
			end
		end
		return true
	end
	local validQuests, validSteps = {}, {}
	for _, quest in Config.StarterQuests do
		validQuests[quest.id] = true
	end
	for _, step in Config.GuideTour do
		validSteps[step.id] = true
	end
	local hadClaimed = readIds(raw.StarterClaimed, data.StarterClaimed, validQuests)
	readIds(raw.StarterDone, data.StarterDone, validQuests)
	if not hadClaimed and data.TutorialDone then
		for id in validQuests do
			data.StarterClaimed[id] = true
		end
	end
	for id in data.StarterClaimed do
		data.StarterDone[id] = true -- alınan görev tamamlanmıştır
	end
	readIds(raw.Flags, data.Flags, { gift = true, train = true, starter = true, notif = true, group = true, fav = true })
	-- Sezonluk etkinlik durumu (Config.Event; server/SeasonEvent): { id, candy, total, claimed = { [kilometre taşı] = true }, bought = { [ürün] = adet }, perks = { title, trail } }
	do
		local source = if type(raw.Event) == "table" then raw.Event else {}
		local event = { id = if type(source.id) == "string" then source.id else "", candy = 0, total = 0, claimed = {}, bought = {}, perks = {} }
		if type(source.candy) == "number" then
			event.candy = math.clamp(math.floor(source.candy), 0, 1e9)
		end
		if type(source.total) == "number" then
			event.total = math.clamp(math.floor(source.total), 0, 1e9)
		end
		if type(source.claimed) == "table" then
			for _, index in source.claimed do
				if type(index) == "number" then
					event.claimed[math.floor(index)] = true
				end
			end
		end
		if type(source.bought) == "table" then
			for itemId, count in source.bought do
				if type(itemId) == "string" and type(count) == "number" then
					event.bought[itemId] = math.clamp(math.floor(count), 0, 9999)
				end
			end
		end
		if type(source.perks) == "table" then
			for _, perk in source.perks do
				if type(perk) == "string" then
					event.perks[perk] = true
				end
			end
		end
		data.Event = event
	end
	-- 'Neler yeni' kartı: görülen sürüm. Kayıtlı değer varsa o; yoksa eğitimi bitirmiş eski oyuncuda 0 (kartı görür), yeni oyuncuda güncel sürüm (görmez)
	if type(raw.WhatsNew) == "number" then
		data.WhatsNew = math.clamp(math.floor(raw.WhatsNew), 0, 1e6)
	else
		data.WhatsNew = if data.TutorialDone then 0 else Config.WhatsNew.Version
	end
	-- Eğitim yumurtası sayaçları (kısıtlı hesaplar için sabit sıralı yumurta): { [yumurta id] = o yumurtadan kaç kez açıldı }
	if type(raw.Training) == "table" then
		for eggId, opened in raw.Training do
			if type(eggId) == "string" and Catalog.EggById[eggId] and type(opened) == "number" then
				data.Training[eggId] = math.clamp(math.floor(opened), 0, 1e9)
			end
		end
	end
	-- Günlük giriş ödülü durumu: sıradaki gün (1-7), son alınan UTC günü, toplam alınan
	if type(raw.Login) == "table" then
		if type(raw.Login.next) == "number" then
			data.Login.next = math.clamp(math.floor(raw.Login.next), 1, #Config.Login.Rewards)
		end
		if type(raw.Login.last) == "number" then
			data.Login.last = math.floor(raw.Login.last)
		end
		if type(raw.Login.total) == "number" then
			data.Login.total = math.max(0, math.floor(raw.Login.total))
		end
	end
	-- Kullanılan promosyon kodları (Config.Codes; kod başına bir kez). Listede olmayan eski kodlar da korunur (sonradan kaldırılsa bile yeniden kullanılamasın)
	if type(raw.Codes) == "table" then
		for _, code in raw.Codes do
			if type(code) == "string" and #code <= 24 then
				data.Codes[string.upper(code)] = true
			end
		end
	end
	-- Friend Referral durumu (server/Referrals): kim davet etti (0 = kimse), ödül verildi mi, davetlinin oynadığı saniye
	if type(raw.Referral) == "table" then
		if type(raw.Referral.by) == "number" and raw.Referral.by > 0 then
			data.Referral.by = math.floor(raw.Referral.by)
		end
		data.Referral.paid = raw.Referral.paid == true
		if type(raw.Referral.secs) == "number" then
			data.Referral.secs = math.clamp(math.floor(raw.Referral.secs), 0, Config.Referral.RequiredSeconds)
		end
	end
	if type(raw.WallsBroken) == "number" then
		data.WallsBroken = math.max(0, math.floor(raw.WallsBroken))
	end
	-- DÜNYALAR (World 2): açık dünyalar listesi (World 1 hep açık) ve son bulunulan dünya. Eski kayıtta yok: World 1.
	if type(raw.Worlds) == "table" then
		for _, id in raw.Worlds do
			if type(id) == "number" and validWorlds[id] and not table.find(data.Worlds, id) then
				table.insert(data.Worlds, id)
			end
		end
	end
	if type(raw.World) == "number" and table.find(data.Worlds, raw.World) then
		data.World = raw.World
	end
	if not readIds(raw.GuideSeen, data.GuideSeen, validSteps) and data.TutorialDone then
		for id in validSteps do
			data.GuideSeen[id] = true
		end
	end
	-- ÖMÜR BOYU KAS (2026-10-14, sahibi 'Leg Muscle şimdiye kadar üretilmiş tüm leg powera göre sıralasın, o an olana göre değil' dedi): rebirth kası sıfırlar, sıralama panosu ise
	-- bugüne kadar kazanılan TOPLAM kasa bakar. Eski kayıtta alan yoksa geriye dönük tahmin: her geçmiş rebirth için o sırada ulaşılması ZORUNLU olan en az kas
	-- (rebirth için level sınırına çıkmak gerekir; level toplam kastan hesaplanır: Progression.cumulativeMuscle(maxLevel)) + şimdiki kas. Robux 'SKIP' ile atlanan rebirth'ler bu tahmini biraz şişirebilir.
	if type(raw.LifetimeMuscle) == "number" then
		data.LifetimeMuscle = math.max(math.floor(raw.LifetimeMuscle), data.Muscle)
	else
		local estimate = data.Muscle
		for passed = 0, data.Rebirths - 1 do
			estimate += Progression.cumulativeMuscle(Progression.maxLevel(passed))
		end
		data.LifetimeMuscle = estimate
	end
	-- Hüni adımları: eski oyuncuda hepsi 'gönderilmiş' sayılır (analitiği kirletmesin)
	if type(raw.Funnel) == "table" then
		for _, step in raw.Funnel do
			if type(step) == "number" then
				data.Funnel[math.floor(step)] = true
			end
		end
	elseif data.TutorialDone then
		for step = 1, #Config.Funnel do
			data.Funnel[step] = true
		end
	end

	return data
end

local function loadData(player)
	local key = `Player_{player.UserId}`
	local failures, waited = 0, 0
	while true do
		-- Okuma ve KİLİT ALMA tek atomik işlemdir (UpdateAsync): kayıt bu sunucuya kilitlenir, veri olduğu gibi korunur
		local blocked = false
		local ok, result = pcall(store.UpdateAsync, store, key, function(old)
			blocked = false -- (UpdateAsync işlevi yeniden denenebilir: her seferinde sıfırla)
			if lockedByOther(old) and waited < LOCK_WAIT then
				blocked = true
				return nil -- iptal: başka sunucu hâlâ kullanıyor
			end
			local record = if type(old) == "table" then old else {}
			record.Lock = { id = SERVER_ID, t = os.time() }
			return record
		end)
		if ok and not blocked then
			return true, result
		end
		if blocked then
			if not player.Parent then
				return false, nil -- beklerken oyundan çıktı
			end
			warn(`[Save] {player.Name}'s data is still locked by another server, waiting...`)
			task.wait(3)
			waited += 3
		else
			failures += 1
			warn(`[Save] Load failed (attempt {failures}): {result}`)
			-- Studio'da API erişimi kapalıysa tekrar denemek boşuna (her Play'de 12 sn beklemeye yol açıyordu)
			if failures >= 3 or string.find(tostring(result), "Studio access to API", 1, true) then
				return false, nil
			end
			task.wait(2 * failures)
		end
	end
end

-- Roblox rozeti ver (Config.Badges; id 0 iken pasif); hata verirse sessizce atlanır
function PlayerStats.awardBadge(player, key)
	if okBadges then
		pcall(Badges.award, player, key)
	end
end

-- Duyuru akışı (server/GlobalFeed): nadir pet ve rebirth eşikleri tüm sunuculara gider; hata verirse sessizce atlanır
local function announce(player, kind, text, tier)
	if okFeed then
		pcall(GlobalFeed.announce, player, kind, text, tier)
	end
end
local FEED_REBIRTHS = { 1, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100 } -- bu rebirth sayılarına ulaşınca duyurulur

-- Oyuncuya kısa bildirim (istemci 'RewardToast' özniteliği değişince gösterir: '<sayaç>|<mesaj>'; sayaç aynı mesaj art arda gelse de değişim olsun diye)
local function sendToast(player, profile, message)
	profile.toastSeq += 1
	player:SetAttribute("RewardToast", `{profile.toastSeq}|{message}`)
end

-- {anahtar = true} kümesini kayıt listesine çevirir
local function setToList(set)
	local list = {}
	for key in set do
		table.insert(list, key)
	end
	table.sort(list, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return list
end

-- İlk oyun hunisi (Config.Funnel): adımı bu oyuncu için bir kez Roblox Analytics'e gönderir (hata verirse oyunu etkilemez)
local function funnel(player, profile, name)
	local step = table.find(Config.Funnel, name)
	if not step or profile.funnel[step] then
		return
	end
	profile.funnel[step] = true
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

-- ÖLÇÜM: Win kaynağı / gideri (Creator Hub > Analytics > Economy). Çağrıdan SONRA bakiye okunur (bitiş bakiyesi). Hata verirse oyunu etkilemez
local function econ(player, flow, amount, transaction, sku)
	if okAnalytics then
		local stat = getStat(player, Config.StatWins)
		pcall(Analytics.economy, player, flow, "Wins", if stat then stat.Value else 0, amount, transaction, sku)
	end
end
local function customEvent(player, name, value, fields)
	if okAnalytics then
		pcall(Analytics.event, player, name, value, fields)
	end
end

-- YENİ OYUNCU GÖREVLERİ (Config.StarterQuests): ilerleme sunucuda hesaplanır, biten görev KİLİTLENİR (starterDone) ve 'StarterState' özniteliğine 'id,ilerleme,bitti,alındı;...' diye yazılır (istemci QuestPanel > NEW PLAYER sekmesi)
local function starterProgress(player, profile, quest)
	local metric = quest.metric
	if metric == "clicks" then
		return profile.tutorialClicks
	elseif metric == "walls" then
		return profile.wallsBroken
	elseif metric == "pets" then
		return if next(profile.discovered) ~= nil then 1 else 0
	elseif metric == "skins" then
		return #profile.skins
	elseif metric == "shoes" then
		return #profile.items
	elseif metric == "level" then
		local levelStat = getStat(player, Config.StatLevel)
		return if levelStat then levelStat.Value else 0
	elseif metric == "gifts" then
		return if profile.flags.gift then 1 else 0
	elseif metric == "train" then
		return if profile.flags.train then 1 else 0
	elseif metric == "wheel" then
		return if profile.wheelDay > 0 then 1 else 0
	elseif metric == "rebirths" then
		local rebirthStat = getStat(player, Config.StatRebirths)
		return if rebirthStat then rebirthStat.Value else 0
	end
	return 0
end

local function publishStarter(player, profile)
	local parts = {}
	local newlyDone = 0
	for _, quest in Config.StarterQuests do
		local progress = starterProgress(player, profile, quest)
		if progress >= quest.goal and not profile.starterDone[quest.id] then
			profile.starterDone[quest.id] = true
			newlyDone += 1
		end
		local done = profile.starterDone[quest.id] == true
		local claimed = profile.starterClaimed[quest.id] == true
		table.insert(parts, `{quest.id},{if done then quest.goal else math.min(progress, quest.goal)},{if done then 1 else 0},{if claimed then 1 else 0}`)
	end
	local text = table.concat(parts, ";")
	if player:GetAttribute("StarterState") ~= text then
		player:SetAttribute("StarterState", text)
	end
	-- Rehber turu: görülen adımlar (istemci tekrar göstermesin)
	local seen = table.concat(setToList(profile.guideSeen), ",")
	if player:GetAttribute("GuideSeen") ~= seen then
		player:SetAttribute("GuideSeen", seen)
	end
	-- (Biten görev bildirimini istemci verir: RightHud alınabilir görev sayısı artınca 'Quest complete!' der; burada tekrar bildirim yok)
	return newlyDone
end

local grantIndexRewards -- Pet Index ödülleri; giveItem tanımlandıktan sonra aşağıda atanır

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
	if level >= 12 and profile.loaded then
		funnel(player, profile, "Level12")
	end
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

-- Antrenman alanı bu oyuncu için açık mı? rebirths = N: N rebirth'te açılır (0: ücretsiz); robux'lu pedler (Prism, Shadow) game pass'e sahip oyuncuda da açıktır
-- (server/AreaPasses 'HasArea_<id>' özniteliğini koyar); robuxOnly (Shadow) pedin rebirth yolu YOKTUR, sadece pass
local function areaUnlocked(player, area, rebirths)
	if area.robux and player:GetAttribute(`HasArea_{area.id}`) == true then
		return true
	end
	if area.robuxOnly then
		return false
	end
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

	-- Takılı skin geçerlidir (toplanmaz): rengi karakteri boyar, SABİT bonusu (+N) tıklama başı bacak kası kazancına eklenir
	profile.equippedSkin = pickEquipped(profile.skins, profile.equippedSkin, Catalog.SkinById, "bonus")
	local skin = Catalog.SkinById[profile.equippedSkin]
	local skinBonus = if skin then skin.bonus else 0

	-- Takılı petlerin çarpanı (oyuncu Pets menüsünden takar)
	local equipped = profile.equipped
	local multiplier = 1
	for _, id in equipped do
		multiplier += Catalog.PetById[id].mult
	end

	local level = getStat(player, Config.StatLevel).Value
	local rebirths = getStat(player, Config.StatRebirths).Value
	local maxLevel = Progression.maxLevel(rebirths)
	-- Çarpan = petler x level x rebirth x aura; yüzde bonusları (süreli güçlendirme, arkadaş, Index) ayrıca çarpar. Skin ÇARPAN DEĞİL sabit bonustur.
	local aura = Catalog.AuraById[profile.equippedAura]
	local auraMultiplier = if aura then aura.mult else 1
	local boostMultiplier = if potionActive(profile, "boostMuscleUntil") then Config.Potions.Mult else 1
	-- Pet Index: sahip olunan her tür keşfedilir (silinse de kalır); keşfedilen her tür +%X (Config.Index)
	for _, id in profile.pets do
		profile.discovered[Catalog.PetById[id].baseId] = true -- birleşmiş boylar da türü keşfetmiş sayılır
	end
	local discoveredIds = {}
	for id in profile.discovered do
		table.insert(discoveredIds, id)
	end
	local indexPercent = #discoveredIds * Config.Index.PercentPerPet
	-- Tamamlama bonusu DÜNYA BAŞINA: bir dünyanın bütün türleri keşfedildiyse +CompletionPercent (World 2 petleri eklenince World 1 bonusu kaybolmaz)
	for _, ids in Catalog.WorldPetIds do
		local complete = #ids > 0
		for _, id in ids do
			if not profile.discovered[id] then
				complete = false
				break
			end
		end
		if complete then
			indexPercent += Config.Index.CompletionPercent
		end
	end

	-- Arkadaş bonusu: sunucudaki her arkadaş için +%X (Config.Friends)
	local friendsConfig = Config.Friends
	local friendCount = if friendsConfig.Enabled then math.min(friendCounts[player] or 0, friendsConfig.MaxFriends) else 0
	local friendPercent = friendCount * friendsConfig.PercentPerFriend
	local coreMultiplier = multiplier
		* Progression.levelMultiplier(level)
		* Progression.rebirthMultiplier(rebirths)
		* auraMultiplier
	local percentMultiplier = boostMultiplier * (1 + friendPercent / 100) * (1 + indexPercent / 100)
	local totalMultiplier = coreMultiplier * percentMultiplier

	-- Skinin sabit bonusu çarpanlardan sonra eklenir, yüzde bonuslarıyla birlikte çarpılır
	profile.gain = math.max(1, math.floor((Config.MusclePerClick * coreMultiplier + skinBonus) * percentMultiplier))

	player:SetAttribute("Taps", profile.taps)
	player:SetAttribute("TapsNeeded", Progression.tapsNeeded(level))
	player:SetAttribute("MaxLevel", maxLevel)
	player:SetAttribute("TotalMultiplier", totalMultiplier)
	player:SetAttribute("FriendCount", friendCount)
	player:SetAttribute("FriendBonus", friendPercent)
	player:SetAttribute("DiscoveredPets", table.concat(discoveredIds, ","))
	player:SetAttribute("IndexBonus", indexPercent)
	if profile.loaded and grantIndexRewards then
		task.defer(grantIndexRewards, player, profile, #discoveredIds) -- ödül verilince refresh yeniden çağrılır; defer iç içe çağrıyı önler
	end
	-- Eğitim: ilk skin alınınca biter (eski/yeni fark etmez), bir daha dönmez
	if #profile.skins > 0 and not profile.tutorialDone then
		profile.tutorialDone = true -- kayıt, skini alan işlemdeki requestSave (buySkin) ya da sonraki otomatik kayıtla yapılır
	end
	player:SetAttribute("TutorialDone", profile.tutorialDone)
	player:SetAttribute("TutorialClicks", profile.tutorialClicks)
	publishQuests(player)
	publishLogin(player, profile)
	do -- Eğitim yumurtası sayaçları: istemci sıradaki peti ('NEXT') buradan bilir ('starter:12,forest:3')
		local counters = {}
		for eggId, opened in profile.training do
			table.insert(counters, `{eggId}:{opened}`)
		end
		table.sort(counters)
		player:SetAttribute("TrainingEggs", table.concat(counters, ","))
	end
	player:SetAttribute("WhatsNewSeen", profile.whatsNew) -- istemci kartı Config.WhatsNew.Version'dan küçükse gösterir
	player:SetAttribute("NotifAsked", profile.flags.notif == true) -- bildirim izni bir kez soruldu mu (client/NotifOptIn)
	player:SetAttribute("FavDone", profile.flags.fav == true) -- oyunu favoriledi mi (client/HappyMoments bir daha sormaz)
	player:SetAttribute("StarterPackOwned", profile.flags.starter == true) -- Shop'taki Başlangıç Paketi kartı alındıktan sonra kalkar
	publishWheel(player)
	player:SetAttribute("DamageMultiplier", shoeDamage)

	player:SetAttribute("PerClick", profile.gain)
	player:SetAttribute("PetMultiplier", multiplier)
	player:SetAttribute("OwnedItems", table.concat(profile.items, ","))
	player:SetAttribute("EquippedShoe", profile.equippedShoe)
	local unlockedAreas = {}
	for _, area in Config.Training.Areas do
		if areaUnlocked(player, area, rebirths) then
			table.insert(unlockedAreas, area.id)
		end
	end
	player:SetAttribute("UnlockedAreas", table.concat(unlockedAreas, ","))
	player:SetAttribute("OwnedSkins", table.concat(profile.skins, ","))
	player:SetAttribute("EquippedSkin", profile.equippedSkin)
	player:SetAttribute("SkinBonus", skinBonus)
	player:SetAttribute("OwnedPets", table.concat(profile.pets, ","))
	-- İlk oyun hunisi (analitik): ilk pet, ilk skin ve ilk rebirth (her biri bir kez)
	if profile.loaded then
		if #profile.pets > 0 then
			funnel(player, profile, "FirstPet")
		end
		if #profile.skins > 0 then
			funnel(player, profile, "FirstSkin")
		end
		local rebirthStat = getStat(player, Config.StatRebirths)
		if rebirthStat and rebirthStat.Value >= 1 then
			funnel(player, profile, "FirstRebirth")
		end
		publishStarter(player, profile)
	end
	player:SetAttribute("PetCapacity", Config.MaxOwnedPets + profile.petSlots)
	player:SetAttribute("EquippedPets", table.concat(equipped, ","))
	player:SetAttribute("OwnedTrails", table.concat(profile.trails, ","))
	player:SetAttribute("OwnedAuras", table.concat(profile.auras, ","))
	player:SetAttribute("EquippedAura", profile.equippedAura)
	player:SetAttribute("MuscleBoostUntil", profile.boostMuscleUntil)
	player:SetAttribute("WinBoostUntil", profile.boostWinsUntil)
	player:SetAttribute("LuckBoostUntil", profile.boostLuckUntil)
	player:SetAttribute("RainbowBoostUntil", profile.boostRainbowUntil)
	player:SetAttribute("AutoBoostUntil", profile.boostAutoUntil) -- Auto Click Potion: istemci süresince Auto Click'i açık sayar
	-- Auto Click game pass'i olanın envanterindeki Auto Click Potion'lar Rainbow Potion'a döner (pass sonradan alınmış ya da eski kayıttan kalmış olabilir)
	local autoItems = profile.potionItems.auto30
	if autoItems and autoItems > 0 and ownsAutoPass(player) then
		local replacementKind, replacementMinutes = autoPotionReward(player)
		local replacementSku = Catalog.potionSkuFor(replacementKind, replacementMinutes)
		if replacementSku then
			profile.potionItems.auto30 = nil
			profile.potionItems[replacementSku] = math.min((profile.potionItems[replacementSku] or 0) + autoItems, 9999)
			if profile.loaded then
				sendToast(player, profile, `Auto Click owner perk: your Auto Click Potion became a {Catalog.PotionByKind[replacementKind].name}! Open Shop > Potions.`)
			end
		end
	end
	local itemList = {}
	for sku, count in profile.potionItems do
		table.insert(itemList, `{sku}:{count}`)
	end
	table.sort(itemList)
	player:SetAttribute("PotionItems", table.concat(itemList, ",")) -- Shop > Potions kartları sayıyı buradan okur
	player:SetAttribute("EggLuck", if potionActive(profile, "boostLuckUntil") then Config.Potions.Mult else 1) -- yumurta panelindeki yüzdeler bunu kullanır (Catalog.luckWeights)
	player:SetAttribute("EquippedTrail", profile.equippedTrail)
	local autoDeleteList = {}
	for id in profile.autoDelete do
		table.insert(autoDeleteList, id)
	end
	player:SetAttribute("AutoDeletePets", table.concat(autoDeleteList, ","))
end

-- mode: nil = otomatik kayıt (tek deneme, bir sonraki otomatik kayıt zaten yakın), 'now' = hemen kaydet (satın alma sonrası; 3 deneme), 'final' = çıkış/kapanış (4 deneme, kilidi bırakır).
-- Dönüş: kaydedildi mi (kilit başka sunucuya geçtiyse false: o oyuncu için bir daha kaydedilmez)
local function save(player, mode)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	-- Yükleme başarısız olduysa asla kaydetme, yoksa eski ilerleme silinir
	if not profile or not profile.canSave or not muscle or not wins then
		return false
	end
	if Config.Save.StudioReadOnly and RunService:IsStudio() then
		return true -- çekim modu: Studio'da kayda yazılmaz (Config.Save.StudioReadOnly)
	end

	local data = {
		Muscle = muscle.Value,
		LifetimeMuscle = profile.lifetimeMuscle,
		Referral = profile.referral,
		Codes = setToList(profile.codes),
		Training = profile.training,
		WhatsNew = profile.whatsNew,
		Event = {
			id = profile.event.id,
			candy = profile.event.candy,
			total = profile.event.total,
			claimed = setToList(profile.event.claimed),
			bought = profile.event.bought,
			perks = setToList(profile.event.perks),
		},
		Login = profile.login,
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
		TutorialDone = profile.tutorialDone,
		TutorialClicks = profile.tutorialClicks,
		StarterWins = profile.starterWins,
		StarterDone = setToList(profile.starterDone),
		StarterClaimed = setToList(profile.starterClaimed),
		WallsBroken = profile.wallsBroken,
		Flags = setToList(profile.flags),
		GuideSeen = setToList(profile.guideSeen),
		Worlds = (function()
			local list = {}
			for id in profile.worlds do
				table.insert(list, id)
			end
			table.sort(list)
			return list
		end)(),
		World = profile.world,
		IndexRewards = (function()
			local list = {}
			for count in profile.indexRewards do
				table.insert(list, count)
			end
			return list
		end)(),
		Funnel = (function()
			local list = {}
			for step in profile.funnel do
				table.insert(list, step)
			end
			return list
		end)(),
		AutoTrial = math.max(0, math.floor(profile.trialUntil - workspace:GetServerTimeNow())),
		Quests = profile.quests,
		WheelDay = profile.wheelDay,
		PetSlots = profile.petSlots,
		PotionItems = profile.potionItems,
		BoostUntil = {
			luck = profile.boostLuckUntil,
			muscle = profile.boostMuscleUntil,
			wins = profile.boostWinsUntil,
			rainbow = profile.boostRainbowUntil,
			auto = profile.boostAutoUntil,
		},
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
	local attempts = if mode == "final" then 4 elseif mode == "now" then 3 else 1
	for attempt = 1, attempts do
		local lost = false
		local ok, err = pcall(store.UpdateAsync, store, `Player_{player.UserId}`, function(old)
			lost = false
			if lockedByOther(old) then
				lost = true
				return nil -- kilit başka sunucuya geçti: onun verisinin üstüne yazma
			end
			data.Lock = if mode == "final" then nil else { id = SERVER_ID, t = os.time() }
			return data
		end)
		if ok and not lost then
			return true
		end
		if lost then
			profile.canSave = false
			warn(`[Save] {player.Name}'s data was taken over by another server: this server will not save it anymore.`)
			return false
		end
		warn(`[Save] Could not save ({player.Name}, attempt {attempt}/{attempts}): {err}`)
		if attempt < attempts then
			task.wait(attempt * 1.5)
		end
	end
	return false
end

-- Hemen kaydeder (Robux satın alması sonrası: ödül kayda geçmeden Roblox'a 'verildi' denmesin). Dönüş: kaydedildi mi
function PlayerStats.saveNow(player)
	return save(player, "now")
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

-- İksiri içirir (kind: "boostLuck" / "boostMuscle" / "boostWins" / "boostRainbow"); iksir zaten etkiliyse süre ÜZERİNE eklenir. Süre bitince kazanç yeniden hesaplanır
local function startBoost(player, profile, kind, minutes)
	local fixed = Catalog.PotionByKind[kind]
	if fixed and fixed.fixedMinutes then
		minutes = fixed.fixedMinutes -- Auto Click Potion hep 30 dk
	end
	local seconds = (minutes or Config.BoostMinutes) * 60
	local field = POTION_FIELD[kind]
	profile[field] = math.max(os.time(), profile[field]) + seconds
	task.delay(seconds + 1, function()
		if profiles[player] == profile then
			refresh(player)
		end
	end)
end

-- İksiri ENVANTERE ekler (çark, Gifts, günlük görev bonusu, DEV): Shop > Potions'ta 'USE xN' olarak görünür. Süre Config.Shop.Potions'taki ürünlerden biri olmalı (15 ya da 60 dk).
-- Dönüş: oyuncuya gösterilecek mesaj. Ürün bulunamazsa (yapılandırma hatası) iksir hemen içilir.
local function giveItem(player, profile, kind, minutes)
	minutes = minutes or Config.BoostMinutes
	if kind == "boostAuto" then
		kind, minutes = autoPotionReward(player) -- Auto Click pass'i olana Rainbow Potion (her kaynakta: görev bonusu, çark, DEV)
	end
	local fixed = Catalog.PotionByKind[kind]
	if fixed and fixed.fixedMinutes then
		minutes = fixed.fixedMinutes -- Auto Click Potion hep 30 dk (hangi kaynaktan gelirse gelsin)
	end
	local sku = Catalog.potionSkuFor(kind, minutes)
	if not sku then
		startBoost(player, profile, kind, minutes)
		return potionMessage(kind, minutes)
	end
	profile.potionItems[sku] = math.min((profile.potionItems[sku] or 0) + 1, 9999)
	local potion = Catalog.PotionByKind[kind]
	return `{potion.name} ({minutes} min) added to your potions! Open Shop > Potions and press USE: {potion.effect} for {minutes} min.`
end

-- Envanterdeki bir iksiri içer (Shop > Potions kartında USE). Dönüş: başarılı mı, mesaj
function PlayerStats.usePotion(player, sku)
	local profile = profiles[player]
	local def = Catalog.PotionSkuById[sku]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	if not def then
		return false, "That potion does not exist."
	end
	local count = profile.potionItems[sku] or 0
	if count < 1 then
		return false, "You do not have this potion."
	end
	if count == 1 then
		profile.potionItems[sku] = nil
	else
		profile.potionItems[sku] = count - 1
	end
	startBoost(player, profile, def.kind, def.minutes)
	refresh(player)
	requestSave(player)
	return true, potionMessage(def.kind, def.minutes)
end

-- Çevrimdışı kazanç: verilen süre (saniye) için bacak kası miktarı = (süre x Auto Click hızı) x tıklama başı kazanç x Rate (aktif Auto Click oyununun %2'si)
local function offlineGain(profile, seconds)
	return math.floor(seconds * Config.AutoClick.PerSecond * profile.gain * Config.Offline.Rate)
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

local loadedCallbacks = {} -- veri yüklenince çağrılacak işlevler (PlayerStats.onLoaded)

local function setup(player)
	task.spawn(PaidRandomPolicy.check, player) -- Roblox 'ücretli rastgele ürün' politikası: sonuç 'PaidRandomRestricted' özniteliğine yazılır (yumurta açma ve Luck iksiri satın alma bakar)
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
		whatsNew = 0, -- 'Neler yeni' kartında görülen sürüm (kayıtlı)
		event = { id = "", candy = 0, total = 0, claimed = {}, bought = {}, perks = {} }, -- sezonluk etkinlik durumu (kayıtlı, server/SeasonEvent)
		training = {}, -- Eğitim yumurtası sayaçları { [yumurta id] = açılış sayısı } (kayıtlı)
		login = { next = 1, last = -1, total = 0 }, -- günlük giriş ödülü durumu (kayıtlı)
		codes = {}, -- kullanılan promosyon kodları { KOD = true } (kayıtlı)
		referral = { by = 0, paid = false, secs = 0 }, -- Friend Referral durumu (kayıtlı)
		lifetimeMuscle = 0, -- bugüne kadar kazanılan TOPLAM bacak kası (rebirth sıfırlamaz; sıralama panosu bunu okur; kayıtlı)
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
		boostLuckUntil = 0,
		boostRainbowUntil = 0,
		boostAutoUntil = 0, -- Auto Click Potion bitişi (os.time; Rainbow kapsamaz)
		claimedGifts = {}, -- oyun süresi ödülleri (bu oturum)
		unlockedGifts = {}, -- Robux 'Unlock' ile AÇILAN ama henüz ALINMAYAN ödüller [sıra] = true (bu tur; süre beklemeden alınabilir, oyuncu CLAIM eder)
		offlinePending = 0, -- alınmayı bekleyen çevrimdışı kazanç (bacak kası) ve uzakta geçen süre (saniye)
		offlineSeconds = 0,
		musicLevel = nil, -- teypteki müzik ses kademesi (nil = kaydedilmemiş, istemci varsayılanı kullanır)
		settings = {}, -- oyuncu ayarları (Config.Settings anahtarları: true/false)
		tutorialDone = false, -- eğitim bitti mi (ilk skin alınınca true olur; kayıtlı)
		quests = newQuestState(0), -- günlük görevler (gün, ilerleme, alınanlar, bonus); kayıttan yüklenir
		petSlots = 0, -- Shop'tan alınan ek pet envanter yeri (Config.MaxOwnedPets'e eklenir; kayıtlı)
		potionItems = {}, -- iksir envanteri [sku] = adet (çark / Gifts / görev bonusundan çıkanlar; Shop > Potions'ta 'USE xN' görünür; kayıtlı)
		wheelDay = 0, -- günlük çarkın son çevrildiği UTC gün (os.time() / 86400); bugüne eşitse bugünkü hak kullanılmış demektir (kayıtlı)
		tutorialClicks = 0, -- eğitimin ilk adımı: Config.Tutorial.ClickGoal kez tıklama sayısı (kayıtlı)
		starterWins = false, -- başlangıç Win hediyesi verildi mi (kayıtlı)
		trialUntil = 0, -- ücretsiz Auto Click denemesinin bitişi (sunucu saati, GetServerTimeNow); kayıtta KALAN saniye tutulur (çevrimdışıyken akmaz)
		indexRewards = {}, -- ödülü alınmış Pet Index eşikleri [tür sayısı] = true (kayıtlı)
		starterDone = {}, -- biten yeni oyuncu görevleri [id] = true (kilitlenir: level/rebirth sıfırlansa da kalır; kayıtlı)
		starterClaimed = {}, -- ödülü alınmış yeni oyuncu görevleri (kayıtlı)
		wallsBroken = 0, -- ömür boyu kırılan duvar sayısı (kayıtlı)
		flags = {}, -- tek seferlik işaretler: gift (bir Playtime ödülü aldı), train (antrenman alanına girdi) (kayıtlı)
		guideSeen = {}, -- gösterilmiş rehber turu adımları [id] = true (kayıtlı)
		worlds = { [1] = true }, -- açık dünyalar [id] = true (World 2: World 1'in son aşama Win pedine basınca açılır; kayıtlı)
		world = 1, -- oyuncunun bulunduğu dünya (girişte o dünyanın spawn'ında doğar; kayıtlı)
		funnel = {}, -- analitik hunisine gönderilmiş adımlar [adım numarası] = true (kayıtlı, Config.Funnel)
		toastSeq = 0, -- oyuncuya giden 'RewardToast' bildirim sayacı
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
	profile.tutorialDone = data.TutorialDone
	profile.tutorialClicks = data.TutorialClicks
	profile.starterWins = data.StarterWins
	profile.funnel = data.Funnel
	profile.indexRewards = data.IndexRewards
	profile.starterDone = data.StarterDone
	profile.starterClaimed = data.StarterClaimed
	profile.wallsBroken = data.WallsBroken
	profile.flags = data.Flags
	profile.guideSeen = data.GuideSeen
	profile.worlds = {}
	for _, id in data.Worlds do
		profile.worlds[id] = true
	end
	profile.world = data.World
	publishWorlds(player, profile)
	profile.trialUntil = if data.AutoTrial > 0 then workspace:GetServerTimeNow() + data.AutoTrial else 0
	player:SetAttribute("AutoClickTrialUntil", profile.trialUntil) -- istemci Auto Click'i deneme süresince açık sayar
	profile.quests = data.Quests
	profile.wheelDay = data.WheelDay
	profile.petSlots = data.PetSlots
	profile.potionItems = data.PotionItems
	-- Etkin iksirlerin kalan süresi kayıtlıdır: oyundan çıkıp girince sürer, süresi dolanlar atılır
	local loadNow = os.time()
	for _, potion in Config.Potions.List do
		local untilTime = data.BoostUntil[potion.id] or 0
		if untilTime > loadNow then
			profile[POTION_FIELD[potion.kind]] = untilTime
			task.delay(untilTime - loadNow + 1, function()
				if profiles[player] == profile then
					refresh(player)
				end
			end)
		end
	end
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
	profile.lifetimeMuscle = data.LifetimeMuscle
	profile.referral = data.Referral
	profile.codes = data.Codes
	profile.training = data.Training
	profile.whatsNew = data.WhatsNew
	profile.event = data.Event
	profile.login = data.Login
	-- Kas her ARTTIĞINDA (tıklama, Win/çark/görev ödülü, Robux paketi, çevrimdışı kazanç...) ömür boyu toplama eklenir; azalma (rebirth, DEV sıfırlama) eklenmez. Yükleme ataması yukarıda
	-- sinyalden ÖNCE yapıldığı için sayılmaz.
	local lastMuscle = muscle.Value
	muscle:GetPropertyChangedSignal("Value"):Connect(function()
		local value = muscle.Value
		if value > lastMuscle and profiles[player] == profile then
			profile.lifetimeMuscle += value - lastMuscle
		end
		lastMuscle = value
	end)
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
	funnel(player, profile, "Joined")
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
	PlayerStats.awardBadge(player, "welcome")
	for _, callback in loadedCallbacks do
		task.spawn(pcall, callback, player) -- diğer sunucu modülleri (Referrals ...): hata verirse oyun etkilenmez
	end
end

function PlayerStats.init()
	Players.PlayerAdded:Connect(setup)
	task.spawn(function()
		while true do
			task.wait(60)
			for player, profile in profiles do
				if profile.loaded and profile.quests.day ~= currentQuestDay() then
					publishQuests(player)
				end
				if profile.loaded and player:GetAttribute("LoginReady") ~= (profile.login.last ~= currentQuestDay()) then
					publishLogin(player, profile)
				end
			end
		end
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player, "final")
		profiles[player] = nil
		friendCounts[player] = nil
	end)

	-- Sunucu kapanırken herkesin verisini kaydet
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				save(player, "final")
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
	-- Antrenman alanının çarpanı kazanca eklenir (alan dışında 1); Power Hour sırasında sunucudaki herkesin kazancı x2 (Config.PowerHour)
	local eventMultiplier = if okEvents then ServerEvents.multiplier() else 1
	local gained = math.max(1, math.floor(profile.gain * (areaMultiplier or 1) * eventMultiplier))
	stat.Value += gained
	return stat.Value, gained
end

-- Oyuncunun şu anki toplam bacak kası (duvara hasar = toplam kas x ayakkabı çarpanı); veri yüklenmediyse nil
function PlayerStats.getMuscle(player)
	local profile = profiles[player]
	local stat = getStat(player, Config.StatLegMuscle)
	if not profile or not profile.loaded or not stat then
		return nil
	end
	return stat.Value
end

-- Ödül tanımını ({ wins, muscleClicks, potions }) oyuncuya verir (promosyon kodu ve günlük giriş ortak). Dönüş: verilenlerin kısa listesi (yazı)
local function grantRewardDef(player, profile, def, sku)
	local wins = getStat(player, Config.StatWins)
	local muscle = getStat(player, Config.StatLegMuscle)
	local parts = {}
	if def.wins then
		wins.Value += def.wins
		econ(player, "Source", def.wins, "TimedReward", sku or "reward")
		table.insert(parts, `+{Format.compact(def.wins)} Wins`)
	end
	if def.winsStage then -- oyuncunun tahmini aşama ödülünün N katı (geç oyunda da anlamlı kalır)
		local amount = estimatedStageReward(player) * def.winsStage
		wins.Value += amount
		econ(player, "Source", amount, "Gameplay", sku or "reward")
		table.insert(parts, `+{Format.compact(amount)} Wins`)
	end
	if def.muscleClicks then
		local amount = math.max(100, math.floor(profile.gain * def.muscleClicks))
		muscle.Value += amount
		syncLevel(player)
		table.insert(parts, `+{Format.compact(amount)} Leg Muscle`)
	end
	for _, potion in def.potions or {} do
		giveItem(player, profile, potion.kind, potion.minutes)
		table.insert(parts, `{Catalog.PotionByKind[potion.kind].name} ({potion.minutes} min)`)
	end
	return table.concat(parts, ", ")
end

-- SEZONLUK ETKİNLİK (server/SeasonEvent) için dışa açılanlar: canlı durum tablosu, ödül verme, iz verme, olay dinleyicileri
function PlayerStats.eventState(player)
	local profile = profiles[player]
	return if profile and profile.loaded then profile.event else nil
end

-- Ödül tanımını ({ wins, winsStage, muscleClicks, potions }) verir, yeniler ve kaydeder. Dönüş: verilenlerin kısa yazısı (veri yoksa nil)
function PlayerStats.giveReward(player, def, sku)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return nil
	end
	local text = grantRewardDef(player, profile, def, sku)
	refresh(player)
	requestSave(player)
	return text
end

-- Bir izi sahipliğe ekler (takmaz): etkinlik izi gibi Win dışı yollarla kazanılan izler için
function PlayerStats.grantTrail(player, trailId)
	local profile = profiles[player]
	if not profile or not profile.loaded or not Catalog.TrailById[trailId] then
		return false
	end
	if not table.find(profile.trails, trailId) then
		table.insert(profile.trails, trailId)
	end
	refresh(player)
	requestSave(player)
	return true
end

function PlayerStats.markDirty(player)
	requestSave(player)
end

-- Oyuncuya küçük bildirim yollar (üstte kısa yazı)
function PlayerStats.toast(player, message)
	local profile = profiles[player]
	if profile and profile.loaded then
		sendToast(player, profile, message)
	end
end

-- Küçük olay dinleyicisi: 'walls' (player, adet) ve 'stagewin' (player, Win) olayları. Dinleyici hata verirse oyun etkilenmez
local listeners = {}
function PlayerStats.listen(name, fn)
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], fn)
end
local function emit(name, ...)
	for _, fn in listeners[name] or {} do
		local ok, err = pcall(fn, ...)
		if not ok then
			warn(`[PlayerStats] {name} listener failed: {err}`)
		end
	end
end

function PlayerStats.claimLogin(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local today = currentQuestDay()
	if profile.login.last == today then
		return false, "You already claimed today's reward. Come back tomorrow!"
	end
	local day = profile.login.next
	local def = Config.Login.Rewards[day]
	profile.login.last = today
	profile.login.next = if day >= #Config.Login.Rewards then 1 else day + 1 -- seri kopmaz: kaçırılan günler cezasız, sıradaki gün devam eder
	profile.login.total += 1
	local text = grantRewardDef(player, profile, def, "login_day")
	customEvent(player, "LoginClaimed", day)
	publishLogin(player, profile)
	refresh(player)
	requestSave(player)
	return true, `Day {day} reward: {text}!{if def.potions then " Potions are in Shop > Potions." else ""}`
end

-- PROMOSYON KODU (Config.Codes): Settings'teki 'Redeem code' satırı. Büyük/küçük harf ve boşluk duyarsız, hesap başına kod başına BİR kez, yanlış deneme sınırlı. Dönüş: başarılı mı, mesaj
local codeBuckets = setmetatable({}, { __mode = "k" }) -- [oyuncu] = { tokens, last }: dakikada Config.CodeAttempts.PerMinute deneme
function PlayerStats.redeemCode(player, raw)
	local profile = profiles[player]
	local wins = getStat(player, Config.StatWins)
	local muscle = getStat(player, Config.StatLegMuscle)
	if not profile or not profile.loaded or not wins or not muscle then
		return false, "Loading your data, please wait."
	end
	local perMinute = Config.CodeAttempts.PerMinute
	local bucket = codeBuckets[player]
	local now = os.clock()
	if not bucket then
		bucket = { tokens = perMinute, last = now }
		codeBuckets[player] = bucket
	end
	bucket.tokens = math.min(perMinute, bucket.tokens + (now - bucket.last) * perMinute / 60)
	bucket.last = now
	if bucket.tokens < 1 then
		return false, "Too many tries. Wait a minute and try again."
	end
	bucket.tokens -= 1

	local typed = if type(raw) == "string" then string.upper(string.gsub(string.sub(raw, 1, 40), "[^%w]", "")) else ""
	if typed == "" then
		return false, "Type a code first."
	end
	local def
	for _, entry in Config.Codes do
		if entry.code == typed then
			def = entry
			break
		end
	end
	if not def then
		return false, "That code does not exist."
	end
	if def.expires and os.time() > def.expires then
		return false, "That code has expired."
	end
	if profile.codes[def.code] then
		return false, "You already used this code."
	end
	profile.codes[def.code] = true
	local text = grantRewardDef(player, profile, def, "code_" .. string.lower(def.code))
	customEvent(player, "CodeRedeemed", 1, { code = def.code })
	refresh(player)
	requestSave(player)
	return true, `Code {def.code} redeemed: {text}! Potions are in Shop > Potions.`
end

-- DÜNYALAR: dünya açık mı?
function PlayerStats.worldUnlocked(player, id)
	local profile = profiles[player]
	return id == 1 or (profile ~= nil and profile.loaded == true and profile.worlds[id] == true)
end

-- Dünyayı kalıcı olarak açar (WallService: önceki dünyanın son aşama Win pedi). Yeni açıldıysa true döner.
function PlayerStats.unlockWorld(player, id)
	local profile = profiles[player]
	if not profile or not profile.loaded or not validWorlds[id] or profile.worlds[id] then
		return false
	end
	profile.worlds[id] = true
	publishWorlds(player, profile)
	customEvent(player, "WorldUnlocked", id)
	PlayerStats.saveNow(player)
	return true
end

-- Oyuncunun bulunduğu dünyayı kaydeder (geçiş kararını ve ışınlamayı WallService verir)
function PlayerStats.setWorld(player, id)
	local profile = profiles[player]
	if not profile or not profile.loaded or not profile.worlds[id] or profile.world == id then
		return false
	end
	profile.world = id
	publishWorlds(player, profile)
	requestSave(player)
	return true
end

-- Oyuncunun bulunduğu dünya (veri yüklenmediyse 1)
function PlayerStats.currentWorld(player)
	local profile = profiles[player]
	return if profile and profile.loaded then profile.world else 1
end

-- Oyuncunun verisi yüklenince fn(player) çağrılır (başka sunucu modülleri bağlanır; hata verirse oyun etkilenmez)
function PlayerStats.onLoaded(fn)
	table.insert(loadedCallbacks, fn)
end

-- Friend Referral durumu (server/Referrals'ın DEĞİŞTİRDİĞİ canlı tablo { by, paid, secs }); veri yüklenmediyse nil
function PlayerStats.referralState(player)
	local profile = profiles[player]
	return if profile and profile.loaded then profile.referral else nil
end

-- Yeni oyuncu mu (eğitimi bitmemiş)? Friend Referral'da sadece yeni oyuncu davetli sayılır
function PlayerStats.isNewPlayer(player)
	local profile = profiles[player]
	return profile ~= nil and profile.loaded == true and not profile.tutorialDone
end

-- Verilen iksir ödüllerini ({ kind, minutes } listesi) envantere ekler, bildirim gösterir ve kaydeder (Friend Referral gibi sunucu modülleri için)
function PlayerStats.grantPotions(player, rewards, message)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false
	end
	for _, reward in rewards do
		giveItem(player, profile, reward.kind, reward.minutes)
	end
	refresh(player)
	sendToast(player, profile, message)
	requestSave(player)
	return true
end

-- Bugüne kadar kazanılan toplam bacak kası (sıralama panosu); veri yüklenmediyse 0
function PlayerStats.lifetimeMuscle(player)
	local profile = profiles[player]
	return if profile and profile.loaded then math.floor(profile.lifetimeMuscle) else 0
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
	return areaUnlocked(player, area, rebirths.Value)
end

-- Bir ped game pass'i satın alınınca / DEV anahtarı değişince: açık pedler listesini ('UnlockedAreas') yeniden yayınlar (veri yüklenmediyse bir şey yapmaz; yüklenince zaten hesaplanır)
function PlayerStats.refreshAreas(player)
	local profile = profiles[player]
	if profile and profile.loaded then
		refresh(player)
	end
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
-- 'Neler yeni' kartı görüldü: güncel sürüm kaydedilir (kart bir daha kendiliğinden açılmaz)
function PlayerStats.seenWhatsNew(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false
	end
	if profile.whatsNew < Config.WhatsNew.Version then
		profile.whatsNew = Config.WhatsNew.Version
		player:SetAttribute("WhatsNewSeen", profile.whatsNew)
		requestSave(player)
	end
	return true
end

-- Favori istemi sonucu (client/HappyMoments; ödülsüz): 'done' = oyuncu favoriledi, bir daha sorulmaz. Her istem ölçülür (Analytics 'FavoritePrompt').
function PlayerStats.markFavorite(player, done)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false
	end
	if okAnalytics then
		pcall(Analytics.event, player, "FavoritePrompt", if done == true then 1 else 0)
	end
	if done == true and not profile.flags.fav then
		profile.flags.fav = true
		player:SetAttribute("FavDone", true)
		requestSave(player)
	end
	return true
end

-- Bildirim izni penceresi gösterildi: bir daha sorulmaz
function PlayerStats.markNotifAsked(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false
	end
	if not profile.flags.notif then
		profile.flags.notif = true
		player:SetAttribute("NotifAsked", true)
		requestSave(player)
	end
	return true
end

-- GRUP ÖDÜLÜ (server/GroupReward): henüz alınmadı mı / iksirleri ver ve işaretle
function PlayerStats.groupRewardPending(player)
	local profile = profiles[player]
	return profile ~= nil and profile.loaded == true and profile.canSave ~= false and not profile.flags.group
end

function PlayerStats.grantGroupReward(player, rewards, message)
	local profile = profiles[player]
	if not profile or not profile.loaded or profile.flags.group then
		return false
	end
	profile.flags.group = true
	return PlayerStats.grantPotions(player, rewards, message)
end

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
	-- 2026-10-13 (sahibi 'rebirthde sadece level ve kas gücü sıfırlansın' dedi): Win, ayakkabı, skin, pet, iz ve aura KALIR. (Eskiden Win, ayakkabı ve skinler de sıfırlanırdı: ilk rebirth ceza gibi hissettiriyordu.)
	PlayerStats.questEvent(player, "rebirth", 1)
	customEvent(player, "Rebirth", rebirthStat.Value)
	refresh(player)
	requestSave(player)
	PlayerStats.awardBadge(player, "rebirth1")
	if rebirthStat.Value >= 10 then
		PlayerStats.awardBadge(player, "rebirth10")
	end
	if table.find(FEED_REBIRTHS, rebirthStat.Value) then
		local tier = if rebirthStat.Value >= 20 then "Mythic" elseif rebirthStat.Value >= 10 then "Legendary" elseif rebirthStat.Value >= 5 then "Epic" else "Rare"
		announce(player, "rebirth", `reached Rebirth {rebirthStat.Value}!`, tier)
	end
	return true, `Rebirth {rebirthStat.Value}! Permanent x{Progression.rebirthMultiplier(rebirthStat.Value)} multiplier.`
end

-- Robux ürününün ödülünü verir (product: Config.Shop.Products satırı ya da { kind = "trail"/"aura", id } / { kind = "skip" }).
-- Dönüş: verildi mi
-- ---------- Oyun süresi ödülleri: verme (hem süresi dolunca elle alma hem Robux 'Unlock' ürünleri kullanır) ----------

-- Alınan ödüllerin sırası istemciye öznitelik olarak gider ('1,3,4'): Gifts penceresi ve FREE REWARD kutusu sunucunun verdiği ödülleri (Robux ile açılanlar dahil) 'Claimed' gösterir
local function publishClaimedGifts(player, profile)
	local list = {}
	for index in profile.claimedGifts do
		table.insert(list, index)
	end
	table.sort(list)
	player:SetAttribute("ClaimedGifts", table.concat(list, ","))
	-- Robux ile açılan (alınmayı bekleyen) ödüller: istemci bunları süresi dolmuş gibi 'Claim' gösterir
	local unlocked = {}
	for index in profile.unlockedGifts do
		table.insert(unlocked, index)
	end
	table.sort(unlocked)
	player:SetAttribute("UnlockedGifts", table.concat(unlocked, ","))
end

-- 10 ödülün HEPSİ alınınca tur BAŞTAN başlar (sahibi 'playtime rewards fullendikten sonra baştan başlasın' dedi): sayaç o andan sıfırlanır, ödüller yeniden kilitlenir.
-- 'GiftCycle' özniteliği her yeni turda artar: istemci kendi 'Claimed' bilgisini yarış durumunda yanlış turda işaretlemesin diye bunu karşılaştırır
local function restartGifts(player, profile)
	profile.claimedGifts = {}
	profile.unlockedGifts = {}
	profile.sessionStart = workspace:GetServerTimeNow()
	player:SetAttribute("SessionStart", profile.sessionStart)
	player:SetAttribute("GiftCycle", (player:GetAttribute("GiftCycle") or 0) + 1)
end

-- index. ödülü verir (oyuncunun CLAIM'i). Süresi dolmuş ya da Robux 'Unlock' ile açılmış (profile.unlockedGifts) olmalı. Dönüş: başarılı mı, mesaj
local function giveGift(player, profile, index)
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not muscle or not wins then
		return false, "Loading your data, please wait."
	end
	local reward = Config.GiftRewards[index]
	if type(index) ~= "number" or not reward then
		return false, "That reward does not exist."
	end
	if profile.claimedGifts[index] then
		return false, "You already claimed this reward."
	end
	if not profile.unlockedGifts[index] and workspace:GetServerTimeNow() - profile.sessionStart < reward.time then
		return false, "This reward is not ready yet."
	end

	local message
	if reward.kind == "muscle" then
		muscle.Value += reward.amount
		message = `+{reward.amount} Leg Muscle`
	elseif reward.kind == "wins" then
		wins.Value += reward.amount
		econ(player, "Source", reward.amount, "TimedReward", "playtime_gift")
		message = `+{reward.amount} Wins`
	elseif reward.kind == "pet" then
		local pet = Catalog.PetById[reward.pet]
		if #profile.pets >= petCapacity(profile) then
			return false, "Your pet inventory is full."
		end
		table.insert(profile.pets, pet.id)
		if #profile.equipped < Config.MaxEquippedPets then
			table.insert(profile.equipped, pet.id)
		end
		message = `New pet: {pet.name}! It was added to your Pets menu.`
	elseif POTION_FIELD[reward.kind] then
		message = giveItem(player, profile, reward.kind, reward.minutes) -- iksir envantere girer
	else
		return false, "Unknown reward."
	end

	profile.claimedGifts[index] = true
	profile.unlockedGifts[index] = nil
	profile.flags.gift = true -- Yeni oyuncu görevi 'Claim a Playtime Reward'
	local claimedCount = 0
	for _ in profile.claimedGifts do
		claimedCount += 1
	end
	if claimedCount >= #Config.GiftRewards then
		restartGifts(player, profile)
		message ..= " All rewards restart!"
	end
	publishClaimedGifts(player, profile)
	refresh(player)
	requestSave(player)
	return true, message
end

-- Robux 'Unlock' ürünleri (2026-10-13, sahibi 'unlock all olduğunda ya da süre bittiğinde süre başa sarması için TÜM itemlerin claimlenmesi gerekiyor' dedi): ürün ödülleri VERMEZ, sadece AÇAR (süre beklemeden 'Claim' olur);
-- oyuncu her ödülü kendisi CLAIM eder ve tur (süre sayacı) ancak 10 ödülün HEPSİ alınınca baştan başlar. mode = 'next' (sıradaki KİLİTLİ ödülü açar; süresi dolmuş ödüller zaten alınabilir) ya da 'all' (hâlâ kilitli olan hepsini açar).
-- Açılacak kilitli ödül yoksa satın alma boşa gitmesin diye bir aşamanın Win ödülü verilir. Dönüş: açılan ödül sayısı
local function unlockGifts(player, profile, mode)
	local elapsed = workspace:GetServerTimeNow() - profile.sessionStart
	local opened = 0
	for index, reward in Config.GiftRewards do
		if not profile.claimedGifts[index] and not profile.unlockedGifts[index] and elapsed < reward.time then
			profile.unlockedGifts[index] = true
			opened += 1
			if mode == "next" then
				break
			end
		end
	end
	if opened > 0 then
		publishClaimedGifts(player, profile)
		sendToast(player, profile, `{if mode == "all" then "All gifts unlocked" else "Gift unlocked"}! Open Gifts and press CLAIM. Claim all {#Config.GiftRewards} rewards and the list starts over!`)
	else
		local wins = getStat(player, Config.StatWins)
		if wins then
			local amount = estimatedStageReward(player)
			wins.Value += amount
			econ(player, "Source", amount, "IAP", "gift_unlock")
		end
	end
	return opened
end

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
	elseif POTION_FIELD[product.kind] then
		startBoost(player, profile, product.kind, product.minutes)
	elseif product.kind == "starterPack" then
		-- Başlangıç paketi: iksirler envantere, pet yuvaları; tekrar satın alınırsa yine verilir (Robux boşa gitmesin), Shop kartı ilkinden sonra kalkar
		for _, potion in Config.StarterPack.Potions do
			giveItem(player, profile, potion.kind, potion.minutes)
		end
		profile.petSlots = math.min(profile.petSlots + Config.StarterPack.PetSlots, Config.MaxExtraPetSlots)
		-- Güçlü pet (envanter doluysa da verilir: Robux ile alındı) ve Win paketi kadar Win
		local starterPet = Config.StarterPack.Pet and Catalog.PetById[Config.StarterPack.Pet]
		if starterPet then
			table.insert(profile.pets, starterPet.id)
			if #profile.equipped < Config.MaxEquippedPets then
				table.insert(profile.equipped, starterPet.id)
			end
		end
		if Config.StarterPack.WinsStage then
			local amount = Layout.reward(Config.StarterPack.WinsStage)
			wins.Value += amount
			econ(player, "Source", amount, "IAP", "iap_starterPack")
		end
		profile.flags.starter = true
	elseif product.kind == "petSpace" then
		profile.petSlots = math.min(profile.petSlots + product.amount, Config.MaxExtraPetSlots) -- üst sınırda da satın alma işlenmiş sayılır (Robux boşa gitmesin)
	elseif product.kind == "wins" then
		wins.Value += product.amount
		econ(player, "Source", product.amount, "IAP", "iap_" .. tostring(product.id))
	elseif product.kind == "stageWins" then
		local amount = Layout.reward(product.stage)
		wins.Value += amount
		econ(player, "Source", amount, "IAP", "iap_" .. tostring(product.id))
	elseif product.kind == "moves" then
		muscle.Value += product.amount * profile.gain
		syncLevel(player)
	elseif product.kind == "giftNext" or product.kind == "giftAll" then
		unlockGifts(player, profile, if product.kind == "giftAll" then "all" else "next")
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
	customEvent(player, "ProductGranted", 1, { product = tostring(product.id) }) -- Robux satın alma kaydı verildi (Creator Hub'da hangi ürün ne kadar satıyor)
	requestSave(player)
	return true
end

-- Eğitimin ilk adımı: oyuncu bir hareket (squat/tekme) başlattığında sunucu sayar (Config.Tutorial.ClickGoal'e kadar, kayıtlı). Eğitimi bitmiş oyuncuda bir şey yapmaz.
function PlayerStats.tutorialClick(player)
	local profile = profiles[player]
	if not profile or not profile.loaded or profile.tutorialDone then
		return
	end
	if profile.tutorialClicks < Config.Tutorial.ClickGoal then
		profile.tutorialClicks += 1
		player:SetAttribute("TutorialClicks", profile.tutorialClicks)
		publishStarter(player, profile) -- Yeni oyuncu görevi 'Squat 30 times' ilerlemesi
		-- (Başlangıç Win'i artık sessizce verilmez: 'Squat 30 times' görevinin ödülüdür, oyuncu Quests'ten CLAIM ile alır. 'starterWins' kayıt alanı eski kayıtlarla uyum için duruyor, kullanılmıyor.)
		if profile.tutorialClicks >= Config.Tutorial.ClickGoal then
			funnel(player, profile, "Clicked30")
		end
	end
end

-- Günlük görev ilerlemesi: kind = 'walls' / 'clicks' / 'hatch' / 'winpads' / 'fuse' / 'rebirth' (Config.Quests.Pool id'leri). Sunucudaki ilgili işlem çağırır.
function PlayerStats.questEvent(player, kind, amount)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return
	end
	ensureQuestDay(profile)
	if kind == "walls" then
		funnel(player, profile, "FirstWall")
		profile.wallsBroken += math.max(1, math.floor(amount or 1)) -- ömür boyu kırılan duvar (Yeni oyuncu görevi)
		publishStarter(player, profile)
		emit("walls", player, math.max(1, math.floor(amount or 1)))
	end
	local changed = false
	for slot, quest in questsForDay(profile.quests.day) do
		if quest.id == kind and not profile.quests.claimed[slot] and profile.quests.progress[slot] < quest.goal then
			profile.quests.progress[slot] = math.min(quest.goal, profile.quests.progress[slot] + (amount or 1))
			changed = true
		end
	end
	if changed then
		publishQuests(player)
	end
end

-- Biten görevin ödülünü alır. Dönüş: başarılı mı, mesaj
function PlayerStats.claimQuest(player, slot)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not muscle or not wins then
		return false, "Loading your data, please wait."
	end
	ensureQuestDay(profile)
	local quest = if type(slot) == "number" then questsForDay(profile.quests.day)[slot] else nil
	if not quest then
		return false, "That quest does not exist."
	end
	if profile.quests.claimed[slot] then
		return false, "You already claimed this reward."
	end
	if profile.quests.progress[slot] < quest.goal then
		return false, "This quest is not finished yet."
	end
	local kind, amount = questReward(profile, player, slot)
	profile.quests.claimed[slot] = true
	if kind == "muscle" then
		muscle.Value += amount
		syncLevel(player)
	else
		wins.Value += amount
		econ(player, "Source", amount, "Gameplay", "daily_quest")
	end
	refresh(player)
	requestSave(player)
	return true, `Quest reward: {rewardText(kind, amount)}`
end

-- Üç görev de alındıysa bonus: süreli 2x bacak kası. Dönüş: başarılı mı, mesaj
function PlayerStats.claimQuestBonus(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	ensureQuestDay(profile)
	if profile.quests.bonus then
		return false, "You already claimed the bonus."
	end
	for slot = 1, Config.Quests.PerDay do
		if not profile.quests.claimed[slot] then
			return false, "Claim all 3 quests first."
		end
	end
	profile.quests.bonus = true
	giveItem(player, profile, "boostRainbow", Config.Quests.BonusBoostMinutes)
	local autoKind, autoMinutes = autoPotionReward(player) -- Auto Click pass'i olana Rainbow Potion
	giveItem(player, profile, autoKind, autoMinutes)
	refresh(player)
	requestSave(player)
	return true, `Bonus! Rainbow Potion ({Config.Quests.BonusBoostMinutes} min) and {Catalog.PotionByKind[autoKind].name} ({autoMinutes} min) added to your potions: open Shop > Potions and press USE!`
end

-- Ayakkabıdan gelen duvar hasar çarpanı (ayakkabı yoksa 1)
function PlayerStats.getDamageMultiplier(player)
	local profile = profiles[player]
	if not profile then
		return 1
	end
	return profile.damageMultiplier or 1
end

function PlayerStats.addWin(player, amount)
	local profile = profiles[player]
	local stat = getStat(player, Config.StatWins)
	if profile and profile.loaded and stat then
		local boost = if potionActive(profile, "boostWinsUntil") then Config.Potions.Mult else 1
		local granted = math.floor((amount or 1) * boost)
		stat.Value += granted
		econ(player, "Source", granted, "Gameplay", "stage_win")
		emit("stagewin", player, granted)
		requestSave(player)
		PlayerStats.questEvent(player, "winpads", 1)
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
	econ(player, "Sink", item.price, "Shop", "shoe_" .. tostring(itemId))
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
		return true, `Equipped {skin.name} skin (+{Format.compact(skin.bonus)} muscle per click)`
	end

	if wins.Value < skin.price then
		return false, `Not enough Wins (need {skin.price}).`
	end

	wins.Value -= skin.price
	econ(player, "Sink", skin.price, "Shop", "skin_" .. tostring(skinId))
	table.insert(profile.skins, skinId)
	profile.equippedSkin = skinId
	refresh(player)
	requestSave(player)
	return true, `Bought {skin.name} skin! (+{Format.compact(skin.bonus)} muscle per click)`
end

-- Yumurtanın pet havuzundan ağırlıklarına göre rastgele pet seçer
local function rollPet(egg, luck)
	local weights = Catalog.luckWeights(egg, luck or 1) -- Luck Potion nadir petlerin ağırlığını artırır
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = rng:NextNumber() * total
	for index, entry in egg.pets do
		roll -= weights[index]
		if roll <= 0 then
			return Catalog.PetById[entry.id]
		end
	end
	return Catalog.PetById[egg.pets[#egg.pets].id]
end

-- PET INDEX ÖDÜLLERİ (Config.Index.Rewards): keşfedilen tür sayısı eşiğe ulaşınca bir kez; iksir ENVANTERE girer (giveItem), Win hemen eklenir
grantIndexRewards = function(player, profile, count)
	if profiles[player] ~= profile or not profile.loaded then
		return
	end
	local wins = getStat(player, Config.StatWins)
	if not wins then
		return
	end
	local messages = {}
	-- 'Pet Collector' rozeti: World 1'in bütün türleri (30) keşfedildi
	local worldOne = Catalog.WorldPetIds[1] or {}
	local allWorldOne = #worldOne > 0
	for _, id in worldOne do
		if not profile.discovered[id] then
			allWorldOne = false
			break
		end
	end
	if allWorldOne then
		PlayerStats.awardBadge(player, "index30")
	end
	for _, reward in Config.Index.Rewards do
		if count >= reward.count and not profile.indexRewards[reward.count] then
			profile.indexRewards[reward.count] = true
			if reward.kind == "wins" then
				wins.Value += reward.amount
				econ(player, "Source", reward.amount, "Gameplay", "pet_index")
				table.insert(messages, `+{reward.amount} Wins`)
			elseif POTION_FIELD[reward.kind] then
				giveItem(player, profile, reward.kind, reward.minutes)
				table.insert(messages, `{Catalog.PotionByKind[reward.kind].name} ({reward.minutes or Config.BoostMinutes} min) in your potions`)
			end
		end
	end
	if #messages > 0 then
		sendToast(player, profile, `Pet Index {count}/{#Config.Pets} reward! {table.concat(messages, ", ")}`)
		refresh(player)
		requestSave(player)
	end
end

-- Ödül listesini verir (Config.StarterQuests[].rewards): wins hemen eklenir, iksir HEMEN başlar. Dönüş: oyuncuya gösterilecek parçalar
local function grantRewardList(player, profile, rewards)
	local wins = getStat(player, Config.StatWins)
	local messages = {}
	for _, reward in rewards do
		if reward.kind == "wins" and wins then
			wins.Value += reward.amount
			econ(player, "Source", reward.amount, "Onboarding", "starter_quest")
			table.insert(messages, `+{reward.amount} Wins`)
		elseif POTION_FIELD[reward.kind] then
			-- (Auto Click game pass'i olana Auto Click Potion yerine Rainbow: Catalog.ownerPotion)
			local kind, minutes = Catalog.ownerPotion(reward.kind, reward.minutes, ownsAutoPass(player))
			startBoost(player, profile, kind, minutes)
			local potion = Catalog.PotionByKind[kind]
			local shownMinutes = if potion.fixedMinutes then potion.fixedMinutes else (minutes or Config.BoostMinutes)
			table.insert(messages, `{potion.name} active for {shownMinutes} min`)
		end
	end
	return messages
end

-- Yeni oyuncu görevinin ödülünü alır (sunucu görevin bittiğini kendi hesabıyla doğrular). Dönüş: başarılı mı, mesaj
function PlayerStats.claimStarter(player, id)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local quest = nil
	for _, candidate in Config.StarterQuests do
		if candidate.id == id then
			quest = candidate
		end
	end
	if not quest then
		return false, "That quest does not exist."
	end
	publishStarter(player, profile) -- bitiş durumunu güncelle (kilitle)
	if profile.starterClaimed[id] then
		return false, "You already claimed this reward."
	end
	if not profile.starterDone[id] then
		return false, "Finish the quest first!"
	end
	profile.starterClaimed[id] = true
	local messages = grantRewardList(player, profile, quest.rewards)
	refresh(player)
	requestSave(player)
	return true, `Quest reward: {table.concat(messages, ", ")}`
end

-- Rehber turu adımı gösterildi/kapatıldı: bir daha gösterilmesin (kayıtlı). Dönüş: başarılı mı
function PlayerStats.guideSeen(player, id)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local valid = false
	for _, step in Config.GuideTour do
		if step.id == id then
			valid = true
		end
	end
	if not valid then
		return false, "Unknown guide step."
	end
	if not profile.guideSeen[id] then
		profile.guideSeen[id] = true
		publishStarter(player, profile) -- 'GuideSeen' özniteliğini de yeniler
		requestSave(player)
	end
	return true, ""
end

-- Oyuncu bir antrenman alanına girdi (Yeni oyuncu görevi 'Visit the Training Area'): TrainingArea sunucusu çağırır
function PlayerStats.markTrained(player)
	local profile = profiles[player]
	if profile and profile.loaded and not profile.flags.train then
		profile.flags.train = true
		publishStarter(player, profile)
		requestSave(player)
	end
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
	local luck = if potionActive(profile, "boostLuckUntil") then Config.Potions.Mult else 1
	-- EĞİTİM YUMURTASI: 'ücretli rastgele ürün' kısıtı olan (ya da henüz bilinmeyen) hesapta sonuç rastgele DEĞİL, sabit sıralı döngüdür (Catalog.trainingCycle; panelde gösterilir)
	local training = player:GetAttribute("PaidRandomRestricted") ~= false
	local spentOnEggs = 0
	for _ = 1, count do
		if wins.Value < egg.price then
			break
		end
		local pet
		if training then
			local cycle = Catalog.trainingCycle(egg)
			pet = Catalog.PetById[cycle[(profile.training[egg.id] or 0) % #cycle + 1]]
		else
			pet = rollPet(egg, luck)
		end
		local willDelete = profile.autoDelete[pet.id]
		if not willDelete and #profile.pets >= petCapacity(profile) then
			break
		end
		wins.Value -= egg.price
		spentOnEggs += egg.price
		if training then
			profile.training[egg.id] = (profile.training[egg.id] or 0) + 1
		end
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

	PlayerStats.questEvent(player, "hatch", #kept + #deleted)
	econ(player, "Sink", spentOnEggs, "Gameplay", "egg_" .. egg.id) -- açılış başına değil çağrı başına tek olay (otomatik açma ölçümü boğmasın)
	refresh(player)
	requestSave(player)

	-- DUYURU: kalan petlerin en nadiri Legendary ya da Mythic ise tüm sunuculara küçük bir duyuru gider (silinenler duyurulmaz)
	local bestPet, bestRank = nil, 0
	for _, pet in kept do
		local rank = table.find({ "Common", "Rare", "Epic", "Legendary", "Mythic" }, Catalog.rarityOf(pet).name) or 0
		if rank >= 4 and rank > bestRank then
			bestPet, bestRank = pet, rank
		end
	end
	if bestPet then
		local rarityName = Catalog.rarityOf(bestPet).name
		announce(player, "pet", `hatched a {string.upper(rarityName)} {bestPet.name}!`, rarityName)
		PlayerStats.awardBadge(player, if rarityName == "Mythic" then "mythic" else "legendary")
	end

	if #kept == 1 and #deleted == 0 then
		local pet = kept[1]
		return true, `Hatched {pet.name}! ({Format.petBonus(pet.mult)} multiplier)`, results
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

-- Auto Click game pass sahipliği değişince (server/AutoClickPass): envanterdeki Auto Click Potion'ları Rainbow'a çevirir, görev bonusu yazısını yeniler
function PlayerStats.autoPassChanged(player)
	local profile = profiles[player]
	if profile and profile.loaded then
		refresh(player)
	end
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
	econ(player, "Sink", trail.winPrice, "Shop", "trail_" .. tostring(trail.id))
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
	econ(player, "Sink", aura.winPrice, "Shop", "aura_" .. tostring(aura.id))
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

-- ---------- Pet birleştirme (Pets menüsündeki Merge düğmesi) ----------

-- Birleştirme: aynı id'den Cost kopya silinir, bir üst boydan 1 pet gelir (envanter dolmaz: Cost - 1 yer açılır). Takılı kopya silindiyse takılıdan da düşer,
-- yeni pet boş yuva varsa takılır. İç fonksiyon, mesaj ve ödül metni dışarıda: fusePet tek, fuseAllPets hepsi için kullanır.
local function fuseOnce(player, profile, petId)
	local pet = Catalog.PetById[petId]
	local fusion = Config.PetFusion
	local nextPet = pet and Catalog.nextTier(pet)
	if not pet or not nextPet or countOf(profile.pets, petId) < fusion.Cost then
		return nil
	end
	for _ = 1, fusion.Cost do
		table.remove(profile.pets, table.find(profile.pets, petId))
	end
	local removedEquipped = 0 -- takılı olup birleştirmede giden kopya sayısı: yuvaları boş bırakmamak için en iyi takılmamışlarla doldurulur
	while countOf(profile.equipped, petId) > countOf(profile.pets, petId) do
		table.remove(profile.equipped, table.find(profile.equipped, petId))
		removedEquipped += 1
	end
	table.insert(profile.pets, nextPet.id)
	if #profile.equipped < Config.MaxEquippedPets then
		table.insert(profile.equipped, nextPet.id)
	end
	if removedEquipped > 1 then
		local sorted = table.clone(profile.pets)
		table.sort(sorted, function(a, b)
			return Catalog.PetById[a].mult > Catalog.PetById[b].mult
		end)
		local toFill = removedEquipped - 1
		for _, id in sorted do
			if toFill <= 0 or #profile.equipped >= Config.MaxEquippedPets then
				break
			end
			if countOf(profile.equipped, id) < countOf(profile.pets, id) then
				table.insert(profile.equipped, id)
				toFill -= 1
			end
		end
	end
	PlayerStats.questEvent(player, "fuse", 1)
	return nextPet
end

function PlayerStats.fusePet(player, petId)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local pet = Catalog.PetById[petId]
	if not pet then
		return false, "That pet does not exist."
	end
	local fusion = Config.PetFusion
	if not Catalog.nextTier(pet) then
		return false, `{pet.label} is already at the maximum size!`
	end
	local have = countOf(profile.pets, petId)
	if have < fusion.Cost then
		return false, `You need {fusion.Cost} {pet.label} to merge (you have {have}).`
	end
	local nextPet = fuseOnce(player, profile, petId)
	if nextPet.tier >= Config.PetFusion.MaxTier then
		PlayerStats.awardBadge(player, "boss")
	end
	refresh(player)
	requestSave(player)
	return true, `Merged! You got {nextPet.label} ({Format.petBonus(nextPet.mult)} multiplier)`, nextPet.id
end

-- Elde fuse edilebilecek ne varsa birleştirir (yeni oluşan boylar da kendi içinde birleşebilir). Dönüş: başarılı mı, mesaj
function PlayerStats.fuseAllPets(player)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	local fusions, best = 0, nil
	for _ = 1, 200 do
		local didAny = false
		-- Küçük boyutlardan başla ki yeni oluşanlar aynı turda ilerleyebilsin
		for _, pet in Catalog.AllPets do
			if Catalog.nextTier(pet) and countOf(profile.pets, pet.id) >= Config.PetFusion.Cost then
				local made = fuseOnce(player, profile, pet.id)
				if made then
					fusions += 1
					didAny = true
					if not best or made.mult > best.mult then
						best = made
					end
					if made.tier >= Config.PetFusion.MaxTier then
						PlayerStats.awardBadge(player, "boss")
					end
				end
			end
		end
		if not didAny then
			break
		end
	end
	if fusions == 0 then
		return false, `You need {Config.PetFusion.Cost} of the same pet to merge.`
	end
	refresh(player)
	requestSave(player)
	return true, `Merged {fusions} time{if fusions == 1 then "" else "s"}! Best: {best.label} ({Format.petBonus(best.mult)} multiplier)`
end

-- ---------- Günlük çark (Config.Wheel) ----------

-- Ağırlıklara göre bir dilim seçer (sunucuda). Dönüş: dilim sırası, dilim
local function pickWheelPrize()
	local prizes = Config.Wheel.Prizes
	local total = 0
	for _, prize in prizes do
		total += prize.weight
	end
	local roll = rng:NextNumber() * total
	for index, prize in prizes do
		roll -= prize.weight
		if roll <= 0 then
			return index, prize
		end
	end
	return #prizes, prizes[#prizes]
end

-- Çarkı çevirir: günde 1 hak (UTC gün), sonucu ve ödülü SUNUCU belirler, ödül hemen verilir ve kaydedilir. Dönüş: başarılı mı, mesaj, dilim sırası (istemci animasyonu o dilimde durdurur)
function PlayerStats.spinWheel(player)
	local profile = profiles[player]
	local muscle = getStat(player, Config.StatLegMuscle)
	local wins = getStat(player, Config.StatWins)
	if not profile or not profile.loaded or not muscle or not wins then
		return false, "Loading your data, please wait."
	end
	local today = currentQuestDay()
	if profile.wheelDay == today then
		local left = (today + 1) * 86400 - os.time()
		return false, `You already spun today! Next free spin in {left // 3600}h {(left % 3600) // 60}m.`
	end

	local index, prize = pickWheelPrize()
	local kind = prize.kind
	-- Envanter doluysa pet dilimi Win'e döner
	if kind == "pet" and #profile.pets >= petCapacity(profile) then
		kind = "wins"
		prize = { kind = "wins", mult = 4 }
	end

	local message
	if kind == "wins" then
		local amount = estimatedStageReward(player) * prize.mult
		wins.Value += amount
		econ(player, "Source", amount, "TimedReward", "wheel")
		message = `+{Format.compact(amount)} Wins`
	elseif kind == "muscle" then
		local amount = math.max(100, math.floor(profile.gain * prize.clicks))
		muscle.Value += amount
		syncLevel(player)
		message = `+{Format.compact(amount)} Leg Muscle`
	elseif POTION_FIELD[kind] then
		message = giveItem(player, profile, kind, prize.minutes) -- iksir envantere girer
	elseif kind == "pet" then
		local pet = rollPet(Config.Eggs[Config.Wheel.PetEgg])
		table.insert(profile.pets, pet.id)
		if #profile.equipped < Config.MaxEquippedPets then
			table.insert(profile.equipped, pet.id)
		end
		message = `New pet: {pet.name}! It was added to your Pets menu.`
	else -- jackpot: Win ve bacak kası birlikte
		local winAmount = estimatedStageReward(player) * prize.mult
		local muscleAmount = math.max(100, math.floor(profile.gain * prize.clicks))
		wins.Value += winAmount
		econ(player, "Source", winAmount, "TimedReward", "wheel_jackpot")
		muscle.Value += muscleAmount
		syncLevel(player)
		message = `JACKPOT! +{Format.compact(winAmount)} Wins and +{Format.compact(muscleAmount)} Leg Muscle!`
	end

	profile.wheelDay = today
	refresh(player)
	requestSave(player)
	return true, message, index
end

-- ---------- Oyun süresi ödülleri ----------

-- index. ödülü alır: süresi dolmuş ve bu oturumda alınmamış olmalı. Dönüş: başarılı mı, mesaj
function PlayerStats.claimGift(player, index)
	local profile = profiles[player]
	if not profile or not profile.loaded then
		return false, "Loading your data, please wait."
	end
	return giveGift(player, profile, index)
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
		if #profile.pets >= petCapacity(profile) then
			return false, "Your pet inventory is full."
		end
		local pet = rollPet(Config.Eggs[rng:NextInteger(1, #Config.Eggs)])
		table.insert(profile.pets, pet.id)
		message = `Free pet: {pet.name}`
	elseif command == "FreeCat" or command == "FreeBossCat" then
		-- Blender kedi modelini denemek için: Small ya da Boss kedi verir ve (yer varsa) takar
		if #profile.pets >= petCapacity(profile) then
			return false, "Your pet inventory is full."
		end
		local petId = if command == "FreeBossCat" then `cat@{Config.PetFusion.MaxTier}` else "cat"
		table.insert(profile.pets, petId)
		if #profile.equipped < Config.MaxEquippedPets then
			table.insert(profile.equipped, petId)
		end
		message = `Free {Catalog.PetById[petId].label} (equipped if there was room)`
	elseif command == "QuestsComplete" then
		-- Günlük görevleri denemek için bugünün üç görevini de bitmiş yapar
		ensureQuestDay(profile)
		for slot, quest in questsForDay(profile.quests.day) do
			profile.quests.progress[slot] = quest.goal
		end
		publishQuests(player)
		message = "All of today's quests are complete: claim them!"
	elseif command == "PotionLuck" or command == "PotionMuscle" or command == "PotionWins" or command == "PotionRainbow" or command == "PotionAuto" then
		-- İksirleri denemek için: envantere 15 dakikalık (Auto Click Potion: sabit 30 dk) 1 iksir ekler; Shop > Potions'ta USE ile içilir
		local kind = "boost" .. string.sub(command, 7)
		message = giveItem(player, profile, kind, 15) -- envantere 1 adet (Shop > Potions'tan içilir)
	elseif command == "WheelReset" then
		profile.wheelDay = 0
		publishWheel(player)
		message = "Daily wheel is ready again"
	elseif command == "QuestsReset" then
		profile.quests = newQuestState(currentQuestDay())
		publishQuests(player)
		message = "Today's quests were reset"
	elseif command == "FreeCats" then
		-- Pet birleştirmeyi denemek için aynı petten 3 tane (envanter yeterse)
		if #profile.pets + 3 > petCapacity(profile) then
			return false, "Your pet inventory is too full for 3 more pets."
		end
		local pet = Config.Pets[rng:NextInteger(1, #Config.Pets)]
		for _ = 1, 3 do
			table.insert(profile.pets, pet.id)
		end
		message = `3 free {pet.name}: open Pets and Merge them!`
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
	elseif command == "RestartTutorial" then
		-- Eğitimi ve rehberi (hızlı ok turu, kartlar, yeni oyuncu görevleri, başlangıç Win'i, ücretsiz Auto Click denemesi) baştan denemek için YENİ OYUNCU durumuna döner:
		-- kas, level, rebirth, Win, ayakkabı, skin, pet ve görev/rehber kayıtları sıfırlanır (rebirth > 0 iken rehber zaten çıkmaz, pet/skin varken ilgili adımlar atlanır).
		-- 'İlk pet' görevi keşfedilen pet türlerine, 'çark' görevi çark gününe bakar: ikisi de sıfırlanır (Pet Index ödülleri de yeniden denenebilsin diye). İz, aura, iksir ve günlük görevler KALIR (RESET ALL hepsini sıfırlar).
		muscle.Value = 0
		profile.lifetimeMuscle = 0 -- yeni oyuncu durumu: ömür boyu kas da sıfırlanır
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
		profile.equipped = {}
		profile.discovered = {}
		profile.indexRewards = {}
		profile.wheelDay = 0
		profile.tutorialDone = false
		profile.tutorialClicks = 0
		player:SetAttribute("TutorialClicks", 0)
		profile.starterWins = false
		profile.starterDone = {}
		profile.starterClaimed = {}
		profile.wallsBroken = 0
		profile.flags = {}
		profile.guideSeen = {}
		profile.worlds = { [1] = true } -- yeni oyuncu: yalnız World 1 açık, oyuncu World 1'e döner (WallService.resetPlayer dünyayı okur)
		profile.world = 1
		publishWorlds(player, profile)
		profile.trialUntil = if (Config.AutoClick.TrialSeconds or 0) > 0 then workspace:GetServerTimeNow() + Config.AutoClick.TrialSeconds else 0
		player:SetAttribute("AutoClickTrialUntil", profile.trialUntil)
		PlayerStats.setSetting(player, "GuideOn", true) -- Guide anahtarı kapalıysa tekrar açılır
		message = "Tutorial restarted: you are a new player again (level, Wins, shoes, skins, pets and quests reset)"
	elseif command == "Reset" then
		muscle.Value = 0
		profile.lifetimeMuscle = 0 -- yeni oyuncu durumu: ömür boyu kas da sıfırlanır
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
		profile.boostLuckUntil = 0
		profile.boostRainbowUntil = 0
		profile.boostAutoUntil = 0
		profile.potionItems = {}
		profile.discovered = {}
		profile.tutorialDone = false -- eğitim yeniden başlar
		profile.tutorialClicks = 0
		player:SetAttribute("TutorialClicks", 0)
		profile.starterWins = false
		profile.starterDone = {}
		profile.starterClaimed = {}
		profile.wallsBroken = 0
		profile.flags = {}
		profile.guideSeen = {}
		profile.worlds = { [1] = true } -- yeni oyuncu: yalnız World 1 açık, oyuncu World 1'e döner (WallService.resetPlayer dünyayı okur)
		profile.world = 1
		publishWorlds(player, profile)
		profile.trialUntil = if (Config.AutoClick.TrialSeconds or 0) > 0 then workspace:GetServerTimeNow() + Config.AutoClick.TrialSeconds else 0
		player:SetAttribute("AutoClickTrialUntil", profile.trialUntil)
		profile.quests = newQuestState(currentQuestDay())
		profile.wheelDay = 0
		publishQuests(player)
		profile.offlinePending = 0
		profile.offlineSeconds = 0
		publishOffline(player, profile)
		message = "Everything reset to zero (tutorial restarts)"
	else
		return false, "Unknown command."
	end

	syncLevel(player)
	refresh(player)
	requestSave(player)
	return true, message
end

return PlayerStats
