-- ÖMÜR BOYU KAS (sahibi 2026-10-14: 'Leg Muscle şimdiye kadar üretilmiş tüm leg powera göre sıralasın, o an olana göre değil' dedi): rebirth bacak kasını sıfırlar ama sıralama panosu
-- bugüne kadar kazanılan TOPLAM kasa bakar. Kas her arttığında toplama eklenir (tıklama, ödül, Robux...), azalma (rebirth, DEV sıfırlama) eklenmez; kayıtlıdır; eski kayıtta alan yoksa
-- geçmiş rebirth'ler için en az kas tahmin edilir; sıralama panosu (Leaderboards.lifetime = true) bunu okur.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")
local Progression = require("./Progression")

PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
local function stat(player, name)
	return player:FindFirstChild("leaderstats"):FindFirstChild(name).Value
end

-- 1) Yeni oyuncu: 0 ile başlar, kas kazandıkça toplam artar (güncel kasa eşit)
local player = join(9801, "Lifetime")
assert(PlayerStats.lifetimeMuscle(player) == 0, "yeni oyuncunun ömür boyu kası 0 olmalı")
for _ = 1, 40 do
	PlayerStats.addMuscle(player, 1)
end
local gained = stat(player, Config.StatLegMuscle)
assert(gained > 0 and PlayerStats.lifetimeMuscle(player) == gained, `kazanılan kas toplama eklenmeli: kas {gained}, toplam {PlayerStats.lifetimeMuscle(player)}`)

-- 2) Rebirth bacak kasını sıfırlar, ÖMÜR BOYU toplam KALIR ve yeni kazanç üstüne eklenir
PlayerStats.dev(player, "MaxLevel")
local beforeRebirth = PlayerStats.lifetimeMuscle(player)
assert(beforeRebirth >= Progression.cumulativeMuscle(Progression.maxLevel(0)), "level sınırına çıkmak en az o kadar kas getirmeli: " .. beforeRebirth)
local ok = PlayerStats.rebirth(player, true)
assert(ok == true and stat(player, Config.StatLegMuscle) == 0, "rebirth güncel kası sıfırlamalı")
assert(PlayerStats.lifetimeMuscle(player) == beforeRebirth, `rebirth ömür boyu kası SIFIRLAMAMALI: önce {beforeRebirth}, sonra {PlayerStats.lifetimeMuscle(player)}`)
PlayerStats.addMuscle(player, 1)
local afterGain = stat(player, Config.StatLegMuscle)
assert(afterGain > 0 and PlayerStats.lifetimeMuscle(player) == beforeRebirth + afterGain, "rebirth sonrası kazanç toplama eklenmeli")

-- 3) Kayıt: toplam kayıtlı, tekrar girişte yüklenir ve yükleme kendiliğinden SAYILMAZ (çift sayım yok)
local total = PlayerStats.lifetimeMuscle(player)
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
assert(S.datastore["Player_9801"].LifetimeMuscle == total, `LifetimeMuscle kayıtlı olmalı: {tostring(S.datastore["Player_9801"].LifetimeMuscle)} / {total}`)
local again = join(9801, "LifetimeAgain")
assert(PlayerStats.lifetimeMuscle(again) == total, `tekrar girişte yüklenen toplam aynı olmalı (yükleme sayılmaz): {PlayerStats.lifetimeMuscle(again)} / {total}`)

-- 4) Eski kayıt (LifetimeMuscle alanı yok): geçmiş rebirth'ler için en az kas tahmin edilir + şimdiki kas
S.datastore["Player_9802"] = { Muscle = 1000, Wins = 10, Level = 5, Rebirths = 3 }
local veteran = join(9802, "Veteran")
local expected = 1000
for passed = 0, 2 do
	expected += Progression.cumulativeMuscle(Progression.maxLevel(passed))
end
assert(PlayerStats.lifetimeMuscle(veteran) == expected, `eski kayıtta geriye dönük tahmin beklenen {expected}, çıkan {PlayerStats.lifetimeMuscle(veteran)}`)
assert(PlayerStats.lifetimeMuscle(veteran) > stat(veteran, Config.StatLegMuscle), "rebirth yapmış eski oyuncunun toplamı güncel kasından büyük olmalı")
-- rebirth yapmamış eski oyuncu: toplam = güncel kas
S.datastore["Player_9803"] = { Muscle = 777, Wins = 1, Level = 3, Rebirths = 0 }
local fresh = join(9803, "NoRebirth")
assert(PlayerStats.lifetimeMuscle(fresh) == 777, "rebirth yapmamış oyuncunun toplamı güncel kasına eşit olmalı: " .. PlayerStats.lifetimeMuscle(fresh))
-- kayıtlı toplam güncel kasından küçükse (bozuk kayıt) güncel kas esas alınır
S.datastore["Player_9804"] = { Muscle = 900, Wins = 1, Level = 3, Rebirths = 0, LifetimeMuscle = 10 }
local odd = join(9804, "Odd")
assert(PlayerStats.lifetimeMuscle(odd) == 900, "toplam güncel kastan küçük olamaz: " .. PlayerStats.lifetimeMuscle(odd))

-- 5) DEV 'Reset' yeni oyuncu durumuna döndürür: toplam da sıfırlanır
PlayerStats.dev(player, "Reset")
assert(PlayerStats.lifetimeMuscle(player) == 0, "DEV Reset ömür boyu kası sıfırlamalı")

print("lifetime muscle ok")
