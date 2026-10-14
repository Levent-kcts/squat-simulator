-- GÜNLÜK GİRİŞ ÖDÜLÜ (Config.Login; sahibi 2026-10-14 onayladı): 7 günlük döngü, günde bir (UTC), NAZİK: gün kaçırılırsa seri kopmaz, sıradaki gün devam eder; ödüller Robux'suz; kayıtlıdır.
local S = require("./stubs")
local Config = require("./Config")
local Catalog = require("./Catalog")
local PlayerStats = require("./PlayerStats")

PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
local function stat(player, name)
	return player:FindFirstChild("leaderstats"):FindFirstChild(name).Value
end
local function count(player, sku)
	return tonumber(string.match(tostring(player:GetAttribute("PotionItems") or ""), sku .. ":(%d+)")) or 0
end
local today = math.floor(os.time() / 86400)

-- Yapılandırma: 7 gün, her biri bir ödül; iksirler Shop ürünü olarak var; 7. gün büyük
assert(#Config.Login.Rewards == 7, "7 günlük döngü olmalı")
for day, reward in Config.Login.Rewards do
	assert(reward.wins or reward.muscleClicks or reward.potions, "her gün bir ödül vermeli: " .. day)
	for _, potion in reward.potions or {} do
		assert(Catalog.potionSkuFor(potion.kind, potion.minutes), `{day}. gün iksiri bir ürün olmalı: {potion.kind} {potion.minutes}`)
	end
end
assert(Config.Login.Rewards[7].big == true, "7. gün büyük ödül olmalı")

-- 1) Yeni oyuncu: bugün alınabilir, sıradaki gün 1
local player = join(9901, "Daily")
assert(player:GetAttribute("LoginReady") == true and player:GetAttribute("LoginNext") == 1 and player:GetAttribute("LoginTotal") == 0, "yeni oyuncuda 1. gün hazır olmalı")
local ok, message = PlayerStats.claimLogin(player)
assert(ok == true and string.find(message, "Day 1", 1, true) and count(player, "muscle15") == 1, "1. gün Muscle iksiri vermeli: " .. tostring(message))
assert(player:GetAttribute("LoginReady") == false and player:GetAttribute("LoginNext") == 2 and player:GetAttribute("LoginTotal") == 1, "alınca hazır değil, sıradaki 2. gün")
local again, againMessage = PlayerStats.claimLogin(player)
assert(again == false and string.find(againMessage, "tomorrow", 1, true), "aynı gün ikinci kez alınamaz: " .. tostring(againMessage))

-- 2) Ertesi gün: 2. gün 50 Win
S.datastore["Player_9902"] = { Muscle = 100, Wins = 10, Level = 3, Rebirths = 0, TutorialDone = true, Login = { next = 2, last = today - 1, total = 1 } }
local second = join(9902, "NextDay")
assert(second:GetAttribute("LoginReady") == true and second:GetAttribute("LoginNext") == 2, "ertesi gün yeniden hazır")
local winsBefore = stat(second, Config.StatWins)
assert(PlayerStats.claimLogin(second) == true and stat(second, Config.StatWins) == winsBefore + 50, "2. gün 50 Win")

-- 3) NAZİK: günler kaçırıldı: seri kopmaz; 7. gün büyük ödülü alınır, sonra döngü 1'e döner
S.datastore["Player_9903"] = { Muscle = 100, Wins = 10, Level = 3, Rebirths = 0, TutorialDone = true, Login = { next = 7, last = today - 5, total = 6 } }
local missed = join(9903, "Missed")
assert(missed:GetAttribute("LoginNext") == 7 and missed:GetAttribute("LoginReady") == true, "kaçırılan günler seriyi sıfırlamamalı")
local missedWins = stat(missed, Config.StatWins)
local okBig, bigMessage = PlayerStats.claimLogin(missed)
assert(okBig == true and stat(missed, Config.StatWins) == missedWins + 300 and count(missed, "rainbow60") == 1, "7. gün 300 Win + Rainbow 60 dk: " .. tostring(bigMessage))
assert(missed:GetAttribute("LoginNext") == 1 and missed:GetAttribute("LoginTotal") == 7, "7. günden sonra döngü başa dönmeli")

-- 4) Kayıt
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local saved = S.datastore["Player_9901"].Login
assert(saved and saved.next == 2 and saved.last == today and saved.total == 1, "giriş durumu kayıtlı olmalı")
local back = join(9901, "DailyAgain")
assert(back:GetAttribute("LoginReady") == false and back:GetAttribute("LoginNext") == 2, "yeniden girişte aynı gün tekrar alınamamalı")
print("login ok")
