-- RETENTION (2026-10-13, playtest: 'insanlar 1K güçte bırakıyor'): başlangıç Win hediyesi, ücretsiz Auto Click denemesi (kalıcı, çevrimdışıyken akmaz) ve level kilometre taşı ödülleri;
-- eski oyuncuya bunların HİÇBİRİ geriye dönük verilmez.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")

local now = 7000000
S.workspace.GetServerTimeNow = function()
	return now + 0.0
end

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
local function petCount(player)
	local list = player:GetAttribute("OwnedPets") or ""
	return if list == "" then 0 else #string.split(list, ",")
end

-- ---- 1) Yeni oyuncu: ücretsiz Auto Click denemesi
local kid = join(9301, "NewKid")
assert(Config.AutoClick.TrialSeconds == 600 and Config.Tutorial.StarterWins == 8, "ayar değerleri beklenen gibi olmalı")
assert(kid:GetAttribute("AutoClickTrialUntil") == now + Config.AutoClick.TrialSeconds, "yeni oyuncu 10 dakikalık deneme almalı: " .. tostring(kid:GetAttribute("AutoClickTrialUntil")))

-- ---- 2) Başlangıç hediyesi: hedef tıklamaya varınca BİR KEZ
local winsBefore = stat(kid, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal - 1 do
	PlayerStats.tutorialClick(kid)
end
assert(stat(kid, Config.StatWins) == winsBefore, "hedefe varmadan Win verilmemeli")
PlayerStats.tutorialClick(kid)
assert(stat(kid, Config.StatWins) == winsBefore + Config.Tutorial.StarterWins, "hedefe varınca başlangıç Win'i verilmeli: " .. stat(kid, Config.StatWins))
assert(string.find(tostring(kid:GetAttribute("RewardToast")), "Free gift", 1, true), "hediye bildirimi gitmeli: " .. tostring(kid:GetAttribute("RewardToast")))
PlayerStats.tutorialClick(kid)
assert(stat(kid, Config.StatWins) == winsBefore + Config.Tutorial.StarterWins, "hediye ikinci kez verilmemeli")
-- Ilk yumurta ve ilk skin birlikte alınabilmeli
assert(Config.Tutorial.StarterWins >= Config.Eggs[1].price + Config.Skins[1].price, "başlangıç Win'i ilk yumurta + ilk skine yetmeli")

-- ---- 3) Level kilometre taşı ödülleri (hepsi bir kez)
local wins0 = stat(kid, Config.StatWins)
PlayerStats.dev(kid, "AddLevel", 5) -- level 6
assert(stat(kid, Config.StatLevel) >= 6 and stat(kid, Config.StatWins) == wins0 + 8, "level 6: +8 Win: " .. stat(kid, Config.StatWins) .. " / level " .. stat(kid, Config.StatLevel))
assert(string.find(tostring(kid:GetAttribute("RewardToast")), "Level 6 reward", 1, true), "level ödülü bildirimi: " .. tostring(kid:GetAttribute("RewardToast")))
PlayerStats.dev(kid, "AddLevel", 6) -- level 12: Muscle Potion HEMEN başlar
assert(kid:GetAttribute("MuscleBoostUntil") and kid:GetAttribute("MuscleBoostUntil") > 0, "level 12: Muscle Potion başlamalı")
local wins1 = stat(kid, Config.StatWins)
PlayerStats.dev(kid, "AddLevel", 6) -- level 18: +20 Win
assert(stat(kid, Config.StatWins) == wins1 + 20, "level 18: +20 Win")
local pets0 = petCount(kid)
PlayerStats.dev(kid, "AddLevel", 4) -- level 22: ücretsiz pet
assert(petCount(kid) == pets0 + 1, "level 22: ücretsiz pet verilmeli")
local wins2 = stat(kid, Config.StatWins)
PlayerStats.dev(kid, "AddLevel", 3) -- level 25 (sınır)
assert(stat(kid, Config.StatWins) == wins2 + 30, "level 25: +30 Win")
-- Aynı ödüller tekrar verilmez (rebirth sonrası da)
local wins3 = stat(kid, Config.StatWins)
local pets1 = petCount(kid)
PlayerStats.dev(kid, "MaxLevel")
assert(stat(kid, Config.StatWins) == wins3 and petCount(kid) == pets1, "alınmış ödül ikinci kez verilmemeli")

-- ---- 3b) REBIRTH SADECE level ve bacak kasını sıfırlar (2026-10-13, sahibi istedi): Win, ayakkabı, skin, pet KALIR
PlayerStats.dev(kid, "AddWins", 1000)
assert(select(1, PlayerStats.buyItem(kid, Config.Items[1].id)) == true, "ayakkabı alınmalı")
assert(select(1, PlayerStats.buySkin(kid, Config.Skins[1].id)) == true, "skin alınmalı")
local winsBeforeRebirth = stat(kid, Config.StatWins)
local petsBeforeRebirth = petCount(kid)
local okRebirth = PlayerStats.rebirth(kid)
assert(okRebirth == true, "rebirth yapılabilmeli (level sınırında)")
assert(stat(kid, Config.StatLevel) == 1 and stat(kid, Config.StatLegMuscle) == 0 and stat(kid, Config.StatRebirths) == 1, "level 1, kas 0, rebirth 1 olmalı")
assert(stat(kid, Config.StatWins) == winsBeforeRebirth, "Win'ler KALMALI: " .. stat(kid, Config.StatWins) .. " / " .. winsBeforeRebirth)
assert(kid:GetAttribute("OwnedItems") == Config.Items[1].id and kid:GetAttribute("OwnedSkins") == Config.Skins[1].id, "ayakkabı ve skin KALMALI: " .. tostring(kid:GetAttribute("OwnedItems")) .. " / " .. tostring(kid:GetAttribute("OwnedSkins")))
assert(petCount(kid) == petsBeforeRebirth, "petler KALMALI")
assert(kid:GetAttribute("EquippedItem") == Config.Items[1].id or kid:GetAttribute("EquippedItem") ~= "", "takılı ayakkabı kalmalı")

-- ---- 4) Kayıt: bayraklar kalıcı, deneme süresi çevrimdışıyken AKMAZ
now += 300 -- 5 dakika oynadı
assert(PlayerStats.saveNow(kid) == true, "kayıt başarılı olmalı")
local record = S.datastore["Player_9301"]
assert(record and record.StarterWins == true, "StarterWins kayıtlı olmalı")
assert(record.AutoTrial == Config.AutoClick.TrialSeconds - 300, "kalan deneme süresi kayıtlı olmalı: " .. tostring(record.AutoTrial))
assert(#record.LevelRewards == #Config.LevelRewards, "alınan level ödülleri kayıtlı olmalı: " .. #record.LevelRewards)
-- İlk oyun hunisi: yaşanan adımlar kayıtlı (bir kez gönderilir)
local funnelSet = {}
for _, step in record.Funnel do
	funnelSet[step] = true
end
for _, name in { "Joined", "Clicked30", "FirstPet", "Level12", "FirstSkin", "FirstRebirth" } do
	assert(funnelSet[table.find(Config.Funnel, name)], "huni adımı kayıtlı olmalı: " .. name)
end
assert(not funnelSet[table.find(Config.Funnel, "FirstWall")], "duvar kırılmadan o adım gönderilmemeli")
now += 100000 -- uzun süre çevrimdışı kaldı
local kidAgain = join(9301, "NewKidAgain")
assert(kidAgain:GetAttribute("AutoClickTrialUntil") == now + Config.AutoClick.TrialSeconds - 300, "dönünce kalan süre devam etmeli (çevrimdışıyken akmaz): " .. tostring(kidAgain:GetAttribute("AutoClickTrialUntil")))
local winsAgain = stat(kidAgain, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(kidAgain)
end
assert(stat(kidAgain, Config.StatWins) == winsAgain, "hediye tekrar girişte yeniden verilmemeli")

-- ---- 5) Eski oyuncu: hiçbiri geriye dönük verilmez
S.datastore["Player_9302"] = { Muscle = 5000, Wins = 10, Level = 5, Rebirths = 1 } -- yeni alanlar yok (eski kayıt)
local veteran = join(9302, "Veteran")
assert(veteran:GetAttribute("AutoClickTrialUntil") == 0, "eski oyuncuya deneme verilmemeli: " .. tostring(veteran:GetAttribute("AutoClickTrialUntil")))
local veteranWins = stat(veteran, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(veteran)
end
PlayerStats.dev(veteran, "MaxLevel")
assert(stat(veteran, Config.StatWins) == veteranWins, "eski oyuncuya başlangıç/level ödülü verilmemeli: " .. stat(veteran, Config.StatWins))

assert(PlayerStats.saveNow(veteran) == true)
assert(#S.datastore["Player_9302"].Funnel == #Config.Funnel, "eski oyuncuda huni adımları 'gönderilmiş' sayılır (analitiği kirletmez)")

print("retention ok")
