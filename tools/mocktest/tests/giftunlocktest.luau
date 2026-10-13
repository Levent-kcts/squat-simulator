-- Gifts > Playtime Rewards'taki Robux 'Unlock Next' / 'Unlock All' ürünleri (sahibi 'bunları eklemeyi unutmuşuz' dedi; sonra 'unlock all olduğunda ya da süre bittiğinde süre başa sarması için TÜM itemlerin claimlenmesi gerekiyor' dedi):
-- ürünler ödülleri VERMEZ, sadece AÇAR ('UnlockedGifts'; süre beklemeden Claim olur); oyuncu her ödülü kendisi CLAIM eder ve tur (süre sayacı) ancak 10 ödülün HEPSİ alınınca baştan başlar.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")

local now = 5000000
S.workspace.GetServerTimeNow = function()
	return now + 0.0
end

PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "GiftBuyer"
player.UserId = 9191
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
local ls = player:FindFirstChild("leaderstats")
local function stat(name)
	return ls:FindFirstChild(name).Value
end

local function petCount(who)
	local list = who:GetAttribute("OwnedPets") or ""
	return if list == "" then 0 else #string.split(list, ",")
end
local function has(who, attribute, index)
	return string.find("," .. (who:GetAttribute(attribute) or "") .. ",", "," .. index .. ",", 1, true) ~= nil
end

local rewards = Config.GiftRewards
assert(#rewards == 10, "10 oyun süresi ödülü olmalı")
assert((player:GetAttribute("ClaimedGifts") or "") == "", "başta alınmış ödül yok: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert((player:GetAttribute("UnlockedGifts") or "") == "", "başta açılmış ödül yok")
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "süresi dolmadan elle alınamaz")

-- ---- Unlock Next: ilk KİLİTLİ ödülü AÇAR, VERMEZ (süre beklemeden Claim olur)
local muscleBefore = stat(Config.StatLegMuscle)
assert(PlayerStats.processPurchase(player, "n1", { kind = "giftNext" }) == true, "giftNext işlenmeli")
assert(player:GetAttribute("UnlockedGifts") == "1" and (player:GetAttribute("ClaimedGifts") or "") == "", "ödül açıldı ama alınmadı: " .. tostring(player:GetAttribute("UnlockedGifts")) .. " / " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(stat(Config.StatLegMuscle) == muscleBefore, "Unlock ödülü kendiliğinden VERMEMELİ (oyuncu CLAIM eder)")
assert(string.find(tostring(player:GetAttribute("RewardToast")), "CLAIM", 1, true), "açılınca CLAIM'e yönlendiren bildirim gelmeli: " .. tostring(player:GetAttribute("RewardToast")))
assert(PlayerStats.processPurchase(player, "n1", { kind = "giftNext" }) == true, "aynı makbuz tekrar gelirse (Roblox yeniden dener) bir kez sayılır")
assert(player:GetAttribute("UnlockedGifts") == "1", "aynı makbuz ikinci ödülü açmamalı")
assert(PlayerStats.processPurchase(player, "n2", { kind = "giftNext" }) == true)
assert(player:GetAttribute("UnlockedGifts") == "1,2", "ikinci Next ikinci ödülü açar: " .. tostring(player:GetAttribute("UnlockedGifts")))
-- Açılan ödül süre dolmadan ELLE alınır
local okClaim1, claim1Message = PlayerStats.claimGift(player, 1)
assert(okClaim1 == true and stat(Config.StatLegMuscle) > muscleBefore, "açılan 1. ödül (kas) CLAIM ile alınmalı: " .. tostring(claim1Message))
assert(player:GetAttribute("ClaimedGifts") == "1" and player:GetAttribute("UnlockedGifts") == "2", "alınan ödül açılanlardan düşmeli: " .. tostring(player:GetAttribute("ClaimedGifts")) .. " / " .. tostring(player:GetAttribute("UnlockedGifts")))
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "alınan ödül tekrar alınamaz")
assert(select(1, PlayerStats.claimGift(player, 3)) == false, "açılmamış, süresi dolmamış ödül alınamaz")

-- ---- Süresi dolmuş (hazır) ödül Next'in hedefi DEĞİL: Next sıradaki KİLİTLİ ödülü açar, hazır olan zaten alınabilir
now += (Config.GiftRewards[3].time + Config.GiftRewards[4].time) // 2 -- 3. ödül hazır, 4. kilitli (süreler Config'ten: ayar değişse de test bozulmasın)
assert(PlayerStats.processPurchase(player, "n3", { kind = "giftNext" }) == true)
assert(player:GetAttribute("UnlockedGifts") == "2,4", "hazır 3. atlanıp kilitli 4. açılmalı: " .. tostring(player:GetAttribute("UnlockedGifts")))
assert(select(1, PlayerStats.claimGift(player, 3)) == true, "hazır ödül elle alınabilir")

-- ---- Unlock All: kalan KİLİTLİ ödüllerin hepsi AÇILIR, hiçbiri verilmez, tur BAŞA SARMAZ; oyuncu hepsini CLAIM edince baştan başlar
local petsBefore = petCount(player)
local cycleBefore = player:GetAttribute("GiftCycle") or 0
local startBefore = player:GetAttribute("SessionStart")
local claimedBefore = player:GetAttribute("ClaimedGifts")
assert(PlayerStats.processPurchase(player, "a1", { kind = "giftAll" }) == true)
assert(player:GetAttribute("ClaimedGifts") == claimedBefore and petCount(player) == petsBefore, "Unlock All ödülleri VERMEMELİ: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert((player:GetAttribute("GiftCycle") or 0) == cycleBefore and player:GetAttribute("SessionStart") == startBefore, "Unlock All turu (süre sayacını) başa SARMAMALI")
for index = 1, #rewards do
	if not has(player, "ClaimedGifts", index) then
		assert(has(player, "UnlockedGifts", index) or now - startBefore >= rewards[index].time, "alınmamış her ödül açılmış ya da süresi dolmuş olmalı: " .. index)
	end
end
-- Kalan ödüllerin hepsini oyuncu CLAIM eder: son ödülde tur başa sarar
local lastMessage
for index = 1, #rewards do
	if not has(player, "ClaimedGifts", index) then
		local ok, message = PlayerStats.claimGift(player, index)
		assert(ok, `{index}. ödül alınmalı: {tostring(message)}`)
		lastMessage = message
		if has(player, "ClaimedGifts", index) then
			assert((player:GetAttribute("GiftCycle") or 0) == cycleBefore or index == #rewards or string.find(message, "restart", 1, true), "tur ancak son ödül alınınca sarmalı")
		end
	end
end
assert(string.find(lastMessage, "restart", 1, true), "son ödülde 'restart' bildirimi: " .. tostring(lastMessage))
assert(player:GetAttribute("ClaimedGifts") == "" and (player:GetAttribute("UnlockedGifts") or "") == "", "10 ödül de alınınca tur baştan başlar, alınanlar ve açılanlar sıfırlanır: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(player:GetAttribute("GiftCycle") == cycleBefore + 1, "yeni tur sayacı artmalı: " .. tostring(player:GetAttribute("GiftCycle")))
assert(player:GetAttribute("SessionStart") == now, "tur sayacı (SessionStart) yeniden başlamalı")
assert(petCount(player) == petsBefore + 2 and string.find(player:GetAttribute("OwnedPets"), "dragon", 1, true) and string.find(player:GetAttribute("OwnedPets"), "phoenix", 1, true), "iki pet ödülü de verilmeli: " .. tostring(player:GetAttribute("OwnedPets")))
local items = player:GetAttribute("PotionItems") or ""
assert(string.find(items, "muscle15", 1, true) and string.find(items, "luck15", 1, true) and string.find(items, "wins15", 1, true), "üç iksir envantere girmeli: " .. items)

-- ---- Yeni turda ödüller yine kilitli: Next tekrar 1. ödülü AÇAR (vermez), hazır olmayan ödül elle alınamaz
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "yeni turda 1. ödülün süresi yeniden dolmalı")
local muscleNewRound = stat(Config.StatLegMuscle)
assert(PlayerStats.processPurchase(player, "n4", { kind = "giftNext" }) == true)
assert(player:GetAttribute("UnlockedGifts") == "1" and stat(Config.StatLegMuscle) == muscleNewRound, "yeni turda Next 1. ödülü açmalı ama vermemeli: " .. tostring(player:GetAttribute("UnlockedGifts")))

-- ---- SÜRE BİTTİĞİNDE de aynı kural: tüm süreler dolsa bile tur ancak 10 ödülün HEPSİ alınınca başa sarar
now += 3000 -- yeni turun hepsi hazır
local cycleNow = player:GetAttribute("GiftCycle")
assert(player:GetAttribute("ClaimedGifts") == "" and player:GetAttribute("GiftCycle") == cycleNow, "süre dolunca tur kendiliğinden başa SARMAMALI")
local lastTimed
for index = 2, #rewards do
	local ok, message = PlayerStats.claimGift(player, index)
	assert(ok, `{index}. ödül alınmalı: {tostring(message)}`)
	assert(player:GetAttribute("GiftCycle") == cycleNow, "tur son ödülden önce sarmamalı: " .. index)
	lastTimed = message
end
assert(select(1, PlayerStats.claimGift(player, 1)) == true, "açılmış 1. ödül de alınır")
assert(player:GetAttribute("GiftCycle") == cycleNow + 1 and player:GetAttribute("ClaimedGifts") == "", "10. ödül alınınca ikinci tur başa sarmalı")
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "tur başa sarınca ödüller yeniden kilitli")
assert(lastTimed ~= nil)

-- ---- Pet envanteri doluysa pet ödülü ALINAMAZ (Unlock All'dan sonra da): açık kalır, elle sonra alınır; tur ancak hepsi alınınca sarar
local second = S.newInstance("Player")
second.Name = "FullBag"
second.UserId = 9192
rawset(second, "Parent", {})
S.events.PlayerAdded(second)
local capacity = second:GetAttribute("PetCapacity")
for _ = 1, capacity do
	PlayerStats.dev(second, "FreeCat")
end
assert(petCount(second) >= capacity, "çanta dolu olmalı: " .. petCount(second) .. "/" .. capacity)
assert(PlayerStats.processPurchase(second, "a2", { kind = "giftAll" }) == true)
assert(second:GetAttribute("UnlockedGifts") == "1,2,3,4,5,6,7,8,9,10" and (second:GetAttribute("ClaimedGifts") or "") == "", "Unlock All hepsini açar, hiçbirini vermez: " .. tostring(second:GetAttribute("UnlockedGifts")))
local secondCycle = second:GetAttribute("GiftCycle") or 0
for index = 1, #rewards do
	local ok = PlayerStats.claimGift(second, index)
	if rewards[index].kind == "pet" then
		assert(ok == false, "dolu çantada pet ödülü alınamaz: " .. index)
	else
		assert(ok == true, "diğer ödüller alınır: " .. index)
	end
end
assert((second:GetAttribute("GiftCycle") or 0) == secondCycle, "pet ödülleri alınmadan tur başa SARMAMALI")
assert(has(second, "UnlockedGifts", 5) and has(second, "UnlockedGifts", 10), "alınamayan pet ödülleri açık kalmalı: " .. tostring(second:GetAttribute("UnlockedGifts")))
PlayerStats.dev(second, "Reset") -- çantayı boşalt
assert(select(1, PlayerStats.claimGift(second, 5)) == true, "yer açılınca pet ödülü alınır")

print("giftunlock ok")
print("DONE")
