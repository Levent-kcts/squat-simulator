-- Gifts > Playtime Rewards'taki Robux 'Unlock Next' / 'Unlock All' ürünleri (sahibi 'bunları eklemeyi unutmuşuz' dedi): sunucu ödülü HEMEN verir, süre kontrolünü atlar, alınanları 'ClaimedGifts' ile bildirir
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

local rewards = Config.GiftRewards
assert(#rewards == 10, "10 oyun süresi ödülü olmalı")
assert((player:GetAttribute("ClaimedGifts") or "") == "", "başta alınmış ödül yok: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "süresi dolmadan elle alınamaz")

-- ---- Unlock Next: ilk KİLİTLİ ödül (süre beklemeden)
local muscleBefore = stat(Config.StatLegMuscle)
assert(PlayerStats.processPurchase(player, "n1", { kind = "giftNext" }) == true, "giftNext işlenmeli")
assert(player:GetAttribute("ClaimedGifts") == "1", "ilk ödül açıldı: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(stat(Config.StatLegMuscle) > muscleBefore, "1. ödül (kas) verilmeli")
assert(PlayerStats.processPurchase(player, "n1", { kind = "giftNext" }) == true, "aynı makbuz tekrar gelirse (Roblox yeniden dener) bir kez sayılır")
assert(player:GetAttribute("ClaimedGifts") == "1", "aynı makbuz ikinci ödülü açmamalı")
assert(PlayerStats.processPurchase(player, "n2", { kind = "giftNext" }) == true)
assert(player:GetAttribute("ClaimedGifts") == "1,2", "ikinci Next ikinci ödülü açar: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(select(1, PlayerStats.claimGift(player, 2)) == false, "açılan ödül elle tekrar alınamaz")

-- ---- Süresi dolmuş (hazır) ödül Next'in hedefi DEĞİL: Next sıradaki KİLİTLİ ödülü açar, hazır olan oyuncuya kalır (ücretsiz alınır)
now += 300 -- 3. ödül (270 sn) hazır, 4. (420) kilitli
assert(PlayerStats.processPurchase(player, "n3", { kind = "giftNext" }) == true)
assert(player:GetAttribute("ClaimedGifts") == "1,2,4", "hazır 3. atlanıp kilitli 4. açılmalı: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(select(1, PlayerStats.claimGift(player, 3)) == true, "hazır ödül elle alınabilir")

-- ---- Unlock All: kalan bütün ödüller (iksirler envantere, petler envantere). Hepsi alınınca tur BAŞTAN başlar (sahibi: 'fullendikten sonra baştan başlasın')
local petsBefore = petCount(player)
assert(PlayerStats.processPurchase(player, "a1", { kind = "giftAll" }) == true)
assert(player:GetAttribute("ClaimedGifts") == "", "10 ödül de alınınca tur baştan başlar, alınanlar sıfırlanır: " .. tostring(player:GetAttribute("ClaimedGifts")))
assert(player:GetAttribute("GiftCycle") == 1, "yeni tur sayacı artmalı: " .. tostring(player:GetAttribute("GiftCycle")))
assert(player:GetAttribute("SessionStart") == now, "tur sayacı (SessionStart) yeniden başlamalı")
assert(petCount(player) == petsBefore + 2 and string.find(player:GetAttribute("OwnedPets"), "dragon", 1, true) and string.find(player:GetAttribute("OwnedPets"), "phoenix", 1, true), "iki pet ödülü de verilmeli: " .. tostring(player:GetAttribute("OwnedPets")))
local items = player:GetAttribute("PotionItems") or ""
assert(string.find(items, "muscle15", 1, true) and string.find(items, "luck15", 1, true) and string.find(items, "wins15", 1, true), "üç iksir envantere girmeli: " .. items)

-- ---- Yeni turda ödüller yine kilitli: Next tekrar 1. ödülü açar, hazır olmayan ödül elle alınamaz
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "yeni turda 1. ödülün süresi yeniden dolmalı")
local muscleNewRound = stat(Config.StatLegMuscle)
assert(PlayerStats.processPurchase(player, "n4", { kind = "giftNext" }) == true)
assert(player:GetAttribute("ClaimedGifts") == "1" and stat(Config.StatLegMuscle) > muscleNewRound, "yeni turda Next 1. ödülü açmalı: " .. tostring(player:GetAttribute("ClaimedGifts")))

-- ---- Elle alınan son ödül de turu başa sarar (zamanla dolan ödüller), bildirim 'restart' der
now += 3000 -- yeni turun hepsi hazır
local lastMessage
for index = 2, #rewards do
	local ok, message = PlayerStats.claimGift(player, index)
	assert(ok, `{index}. ödül alınmalı: {tostring(message)}`)
	lastMessage = message
end
assert(string.find(lastMessage, "restart", 1, true), "son ödülde 'restart' bildirimi: " .. tostring(lastMessage))
assert(player:GetAttribute("ClaimedGifts") == "" and player:GetAttribute("GiftCycle") == 2, "ikinci tur de başa sarmalı")
assert(select(1, PlayerStats.claimGift(player, 1)) == false, "tur başa sarınca ödüller yeniden kilitli")

-- ---- Pet envanteri doluysa pet ödülü atlanır (diğerleri açılır), elle sonra alınabilir
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
local claimed = second:GetAttribute("ClaimedGifts")
assert(not string.find("," .. claimed .. ",", ",5,", 1, true) and not string.find("," .. claimed .. ",", ",10,", 1, true), "dolu çantada pet ödülleri atlanmalı: " .. claimed)
assert(string.find("," .. claimed .. ",", ",1,", 1, true) and string.find("," .. claimed .. ",", ",9,", 1, true), "diğer ödüller açılmalı: " .. claimed)

print("giftunlock ok")
print("DONE")
