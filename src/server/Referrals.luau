-- FRIEND REFERRAL ÖDÜLÜ (büyüme planı sprint 1.2; araştırma: research/02, 04; resmi sistem: create.roblox.com/docs/production/promotion/referral-system):
-- Bir oyuncu davet bağlantısıyla (Roblox'un kendi davet menüsü ya da oyundaki davet düğmesi) YENİ bir oyuncu getirirse Player:GetJoinData().ReferredByPlayerId davetçiyi verir.
-- Ödül SADECE gerçek katılım içindir: davetli en az Config.Referral.RequiredSeconds (10 dk) oynayınca İKİ TARAFA da iksir verilir (Robux/Win DEĞİL), davetli başına TEK seferlik, davetçi başına en çok Config.Referral.MaxPerInviter.
-- Sahte hesap önlemi: sadece yeni oyuncu (eğitimi bitmemiş, ilk kez katılan) davetli sayılır, davetçiye ödül en çok 3 kez, davetli kendini davet edemez.
-- Davetçi başka sunucudaysa/çevrimdışıysa ödül DataStore'da bekler ('Ref_<id>' = { total, pending }); davetçi girince ya da MessagingService bildirimi gelince alır.
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Referrals = {}

local TOPIC = "SquatReferral_v1"
local TICK = 30 -- saniye: davetli oynama süresi bu aralıkla sayılır
local store = DataStoreService:GetDataStore("Referrals_v1")
local PlayerStats = nil

local function key(userId)
	return `Ref_{userId}`
end

-- Davetçinin bekleyen ödül sayısını alır ve sıfırlar (UpdateAsync: iki sunucu aynı anda alamaz). Dönüş: alınan sayı
local function takePending(userId)
	local taken = 0
	local ok = pcall(function()
		store:UpdateAsync(key(userId), function(old)
			if type(old) ~= "table" or (old.pending or 0) <= 0 then
				return nil
			end
			taken = old.pending
			return { total = old.total or 0, pending = 0 }
		end)
	end)
	return if ok then taken else 0
end

-- Davetçiye bir ödül hakkı ekler (en çok MaxPerInviter). Dönüş: eklendi mi
local function addPending(userId)
	local added = false
	local ok = pcall(function()
		store:UpdateAsync(key(userId), function(old)
			old = if type(old) == "table" then old else { total = 0, pending = 0 }
			if (old.total or 0) >= Config.Referral.MaxPerInviter then
				return nil
			end
			added = true
			return { total = (old.total or 0) + 1, pending = (old.pending or 0) + 1 }
		end)
	end)
	return ok and added
end

-- Davetçi oyundaysa bekleyen ödülleri verir
function Referrals.claimForInviter(player)
	if not PlayerStats then
		return 0
	end
	local count = takePending(player.UserId)
	for _ = 1, count do
		PlayerStats.grantPotions(player, Config.Referral.InviterRewards, "A friend you invited joined the game! Free potions added: open Shop > Potions.")
	end
	return count
end

-- Davetli yeterince oynadı: ikisine de ödül
function Referrals.payOut(invitee)
	local state = PlayerStats.referralState(invitee)
	if not state or state.paid or state.by == 0 then
		return false
	end
	state.paid = true -- önce işaretle (çift ödül olmasın); kayıt PlayerStats.grantPotions içinde istenir
	PlayerStats.grantPotions(invitee, Config.Referral.InviteeRewards, "Thanks for joining through a friend! Free potion added: open Shop > Potions.")
	if addPending(state.by) then
		local inviter = Players:GetPlayerByUserId(state.by)
		if inviter then
			Referrals.claimForInviter(inviter)
		else
			task.spawn(pcall, MessagingService.PublishAsync, MessagingService, TOPIC, state.by) -- başka sunucudaki davetçi alsın
		end
	end
	return true
end

-- Oyuncu yüklendi: davetçi mi (bekleyen ödül) ve davetli mi (ReferredByPlayerId) kontrolü
function Referrals.onLoaded(player, referrerId)
	Referrals.claimForInviter(player)
	local state = PlayerStats.referralState(player)
	if not state or state.by ~= 0 or not PlayerStats.isNewPlayer(player) then
		return false
	end
	if type(referrerId) ~= "number" or referrerId == 0 or referrerId == player.UserId then
		return false
	end
	state.by = referrerId
	return true
end

-- Davetlinin oynama süresini say (saniye); süre dolunca ödemeyi yap. Dönüş: ödendi mi
function Referrals.addPlaytime(player, seconds)
	local state = PlayerStats.referralState(player)
	if not state or state.by == 0 or state.paid then
		return false
	end
	state.secs += seconds
	if state.secs >= Config.Referral.RequiredSeconds then
		return Referrals.payOut(player)
	end
	return false
end

function Referrals.init(playerStats)
	PlayerStats = playerStats
	playerStats.onLoaded(function(player)
		local ok, joinData = pcall(player.GetJoinData, player)
		local referrerId = if ok and type(joinData) == "table" then joinData.ReferredByPlayerId else nil
		Referrals.onLoaded(player, referrerId)
	end)
	task.spawn(pcall, MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message)
		local inviter = Players:GetPlayerByUserId(tonumber(message.Data) or 0)
		if inviter then
			Referrals.claimForInviter(inviter)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				pcall(Referrals.addPlaytime, player, TICK)
			end
		end
	end)
end

return Referrals
