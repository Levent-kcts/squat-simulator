-- FRIEND REFERRAL ÖDÜLÜ (büyüme planı sprint 1.2; server/Referrals): davet bağlantısıyla gelen YENİ oyuncu 10 dk oynayınca iki tarafa da iksir verilir (Robux/Win değil), davetli başına tek seferlik,
-- davetçi başına en çok 3; davetçi çevrimdışıysa ödül bekler ve girince verilir; kendini davet etmek ve eski oyuncu sayılmaz.
local S = require("./stubs")
local Config = require("./Config")
local PlayerStats = require("./PlayerStats")
local Referrals = require("./Referrals")

PlayerStats.init()
Referrals.init(PlayerStats)

local function join(userId, name, referrer)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	rawset(player, "GetJoinData", function()
		return { ReferredByPlayerId = referrer }
	end)
	S.playersById[userId] = player
	S.events.PlayerAdded(player)
	return player
end
local function potions(player)
	return tostring(player:GetAttribute("PotionItems") or "")
end
local function count(player, sku)
	return tonumber(string.match(potions(player), sku .. ":(%d+)")) or 0
end
local R = Config.Referral
assert(R.RequiredSeconds == 600 and R.MaxPerInviter == 3 and #R.InviterRewards >= 1 and #R.InviteeRewards >= 1, "Referral ayarları tanımlı olmalı")

-- 1) Davetçi çevrimiçi; yeni oyuncu onun bağlantısıyla geldi: süre dolunca İKİ TARAFA da iksir
local inviter = join(9701, "Inviter", 0)
assert(PlayerStats.referralState(inviter).by == 0, "davetçinin kendisi davetli değil")
local invitee = join(9702, "Invitee", 9701)
local state = PlayerStats.referralState(invitee)
assert(state and state.by == 9701 and state.paid == false, "yeni oyuncu davetçiyle eşleşmeli")
assert(Referrals.addPlaytime(invitee, R.RequiredSeconds - 1) == false and count(invitee, "rainbow15") == 0, "süre dolmadan ödül yok")
assert(Referrals.addPlaytime(invitee, 1) == true, "10 dk dolunca ödül verilmeli")
assert(count(invitee, "rainbow15") == 1, "davetliye Rainbow 15 dk iksiri: " .. potions(invitee))
assert(count(inviter, "muscle15") == 1 and count(inviter, "luck15") == 1, "davetçiye Muscle ve Luck 15 dk iksirleri: " .. potions(inviter))
assert(Referrals.addPlaytime(invitee, 5000) == false and count(invitee, "rainbow15") == 1 and count(inviter, "muscle15") == 1, "ödül davetli başına TEK seferlik olmalı")
assert(PlayerStats.saveNow(invitee) == true and S.datastore["Player_9702"].Referral.paid == true and S.datastore["Player_9702"].Referral.by == 9701, "referral durumu kayıtlı olmalı")

-- 2) Kendini davet etme ve eski oyuncu sayılmaz
local selfInvite = join(9703, "Selfie", 9703)
assert(PlayerStats.referralState(selfInvite).by == 0, "kendini davet sayılmamalı")
S.datastore["Player_9704"] = { Muscle = 5000, Wins = 10, Level = 5, Rebirths = 1, TutorialDone = true }
local veteran = join(9704, "Veteran", 9701)
assert(PlayerStats.referralState(veteran).by == 0, "eski oyuncu davetli sayılmamalı (sahte hesap önlemi)")

-- 3) Davetçi başına en çok 3 ödül
for index = 1, 4 do
	local friend = join(9710 + index, "Friend" .. index, 9701)
	Referrals.addPlaytime(friend, R.RequiredSeconds)
end
-- 1. davetli yukarıda ödendi: toplam 5 davetli, ödül hakkı 3
assert(count(inviter, "muscle15") == R.MaxPerInviter, `davetçi en çok {R.MaxPerInviter} ödül almalı: {count(inviter, "muscle15")}`)

-- 4) Davetçi ÇEVRİMDIŞI: ödül DataStore'da bekler, girince verilir
local offlineId = 9720
local friend = join(9721, "FriendOffline", offlineId)
Referrals.addPlaytime(friend, R.RequiredSeconds)
local record = S.datastore["Ref_" .. offlineId]
assert(record and record.pending == 1 and record.total == 1, "çevrimdışı davetçiye ödül hakkı yazılmalı")
local late = join(offlineId, "LateInviter", 0)
assert(count(late, "muscle15") == 1 and count(late, "luck15") == 1, "davetçi girince bekleyen ödül verilmeli: " .. potions(late))
assert(S.datastore["Ref_" .. offlineId].pending == 0, "ödül alınınca bekleyen sıfırlanmalı")
print("referral ok")
