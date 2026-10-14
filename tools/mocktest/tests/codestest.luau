-- PROMOSYON KODLARI (Config.Codes; sahibi 2026-10-14 onayladı): Settings'ten girilir, sunucu doğrular; kod/harf/boşluk duyarsız, hesap başına bir kez, ödüller (Win, kas, iksir) verilir, süresi dolan reddedilir, yanlış deneme sınırlı, kayıtlıdır.
local S = require("./stubs")
local Config = require("./Config")
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

assert(#Config.Codes >= 5, "lansman kodları tanımlı olmalı")
local seen = {}
for _, def in Config.Codes do
	assert(def.code == string.upper(def.code) and string.match(def.code, "^%w+$") and not seen[def.code], "kodlar büyük harf, harf-rakam ve benzersiz olmalı: " .. def.code)
	seen[def.code] = true
	assert(def.wins or def.muscleClicks or def.potions, "her kod bir ödül vermeli: " .. def.code)
end

local player = join(9801, "Coder")
local winsBefore = stat(player, Config.StatWins)
-- 1) LAUNCH: Win + Luck iksiri; küçük harf ve boşluk fark etmez
local ok, message = PlayerStats.redeemCode(player, "  launch ")
assert(ok == true and string.find(message, "LAUNCH", 1, true), "kod kullanılabilmeli: " .. tostring(message))
assert(stat(player, Config.StatWins) == winsBefore + 100 and count(player, "luck15") == 1, "LAUNCH 100 Win + Luck 15 dk vermeli")
-- 2) aynı kod ikinci kez yok
local again, againMessage = PlayerStats.redeemCode(player, "LAUNCH")
assert(again == false and string.find(againMessage, "already", 1, true), "kod hesap başına bir kez: " .. tostring(againMessage))
assert(stat(player, Config.StatWins) == winsBefore + 100, "ikinci kullanım ödül vermemeli")
-- 3) kas ödülü: SQUAT
local muscleBefore = stat(player, Config.StatLegMuscle)
local okSquat = PlayerStats.redeemCode(player, "SQUAT")
assert(okSquat == true and stat(player, Config.StatLegMuscle) > muscleBefore and count(player, "muscle15") == 1, "SQUAT kas + Muscle iksiri vermeli")
-- 4) olmayan / boş kod
assert(PlayerStats.redeemCode(player, "NOPE123") == false, "olmayan kod reddedilmeli")
assert(PlayerStats.redeemCode(player, "") == false and PlayerStats.redeemCode(player, 5) == false, "boş ya da yanlış türde kod reddedilmeli")
-- 5) süresi dolan kod
table.insert(Config.Codes, { code = "OLDONE", wins = 5, expires = os.time() - 10 })
local expired = join(9802, "Late")
local okOld, oldMessage = PlayerStats.redeemCode(expired, "oldone")
assert(okOld == false and string.find(oldMessage, "expired", 1, true), "süresi dolan kod reddedilmeli: " .. tostring(oldMessage))
table.remove(Config.Codes)
-- 6) yanlış deneme sınırı (dakikada Config.CodeAttempts.PerMinute)
local brute = join(9803, "Brute")
local blocked = false
for index = 1, Config.CodeAttempts.PerMinute + 3 do
	local result, text = PlayerStats.redeemCode(brute, "WRONG" .. index)
	if not result and string.find(text, "Too many", 1, true) then
		blocked = true
	end
end
assert(blocked, "çok sayıda yanlış denemeden sonra sınır devreye girmeli")
-- 7) kayıt: kullanılan kod kalıcı, yeniden girişte tekrar kullanılamaz
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local saved = S.datastore["Player_9801"].Codes
assert(type(saved) == "table" and table.find(saved, "LAUNCH") and table.find(saved, "SQUAT"), "kullanılan kodlar kayıtlı olmalı")
local back = join(9801, "CoderAgain")
local okAgain = PlayerStats.redeemCode(back, "LAUNCH")
assert(okAgain == false, "yeniden girişte de kod tekrar kullanılamamalı")
print("codes ok")
