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

-- ---- 1) Ücretsiz Auto Click denemesi KAPALI (sahibi 'zamanlayıcı vermesin, ilk rebirth'inde Auto Click Potion versin' dedi): yeni oyuncuya deneme süresi verilmez
local kid = join(9301, "NewKid")
assert(Config.AutoClick.TrialSeconds == 0, "ücretsiz deneme kapalı olmalı")
assert((kid:GetAttribute("AutoClickTrialUntil") or 0) == 0, "yeni oyuncu deneme süresi almamalı: " .. tostring(kid:GetAttribute("AutoClickTrialUntil")))

-- ---- 2) Başlangıç Win'i SESSİZCE verilmez (sahibi istedi): 'Squat 30 times' görevinin ödülüdür, oyuncu Quests'ten CLAIM ile alır
local winsBefore = stat(kid, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(kid)
end
assert(stat(kid, Config.StatWins) == winsBefore, "30 tıklamada Win sessizce verilmemeli: " .. stat(kid, Config.StatWins))
local squatQuest = Config.StarterQuests[1]
assert(squatQuest.id == "squat" and squatQuest.rewards[1].kind == "wins", "ilk görev 30 squat ve Win ödüllü olmalı")
-- İlk yumurta ve ilk skin birlikte alınabilmeli
assert(squatQuest.rewards[1].amount >= Config.Eggs[1].price + Config.Skins[1].price, "squat görevinin ödülü ilk yumurta + ilk skine yetmeli")
local okClaimSquat = PlayerStats.claimStarter(kid, "squat")
assert(okClaimSquat == true and stat(kid, Config.StatWins) == winsBefore + squatQuest.rewards[1].amount, "ödül Quests'ten CLAIM ile alınmalı: " .. stat(kid, Config.StatWins))
assert(select(1, PlayerStats.claimStarter(kid, "squat")) == false, "ödül ikinci kez alınamaz")

-- ---- 3) LEVEL KİLOMETRE TAŞI ÖDÜLÜ YOK (sahibi 'hiçbir şey vermesin, zaten quest yardımcı oluyor, komple kaldır' dedi): level atlamak Win, iksir ya da pet VERMEZ, bildirim çıkmaz
assert(Config.LevelRewards == nil, "Config.LevelRewards kaldırılmış olmalı")
local winsLevel = stat(kid, Config.StatWins)
local petsLevel = petCount(kid)
local toastLevel = tostring(kid:GetAttribute("RewardToast"))
PlayerStats.dev(kid, "MaxLevel")
assert(stat(kid, Config.StatLevel) >= Config.Level.BaseMaxLevel, "level sınıra çıkmalı (sınır " .. Config.Level.BaseMaxLevel .. "): " .. stat(kid, Config.StatLevel))
assert(stat(kid, Config.StatWins) == winsLevel and petCount(kid) == petsLevel, "level atlamak Win ya da pet vermemeli")
for _, attribute in { "MuscleBoostUntil", "LuckBoostUntil", "RainbowBoostUntil", "WinBoostUntil" } do
	assert((kid:GetAttribute(attribute) or 0) <= os.time(), "level atlamak iksir başlatmamalı: " .. attribute)
end
assert(tostring(kid:GetAttribute("RewardToast")) == toastLevel and not string.find(tostring(kid:GetAttribute("RewardToast")), "Level", 1, true), "level atlayınca ödül bildirimi çıkmamalı")

-- (İlk pet artık level ödülünden gelmez: yumurtadan açılır; huni 'FirstPet' adımı ve sonraki bölümler için)
PlayerStats.dev(kid, "AddWins", 50)
assert(PlayerStats.hatchEgg(kid, Config.Eggs[1].id, 1) == true, "ilk yumurta açılmalı")

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

-- ---- 3c) Pet Index ödülleri (2026-10-13): eşiğe ulaşınca bir kez; hepsi keşfedilince tamamlama bonusu
local totalIndexWins = 0
for _, reward in Config.Index.Rewards do
	if reward.kind == "wins" then
		totalIndexWins += reward.amount
	end
end
local winsIdx = stat(kid, Config.StatWins)
PlayerStats.dev(kid, "DiscoverAll")
assert(stat(kid, Config.StatWins) - winsIdx == totalIndexWins, "Index ödüllerinin Win'leri verilmeli: " .. (stat(kid, Config.StatWins) - winsIdx) .. " / " .. totalIndexWins)
-- tamamlama bonusu dünya başına (World 1 + World 2 tamam = 2 kez)
assert(kid:GetAttribute("IndexBonus") == #Config.Pets * Config.Index.PercentPerPet + 2 * Config.Index.CompletionPercent, "tamamlama bonusu eklenmeli: " .. tostring(kid:GetAttribute("IndexBonus")))
assert(string.find(tostring(kid:GetAttribute("RewardToast")), "Pet Index " .. #Config.Pets .. "/" .. #Config.Pets .. " reward", 1, true), "Index ödül bildirimi: " .. tostring(kid:GetAttribute("RewardToast")))
local winsIdx2 = stat(kid, Config.StatWins)
PlayerStats.dev(kid, "DiscoverAll")
assert(stat(kid, Config.StatWins) == winsIdx2, "Index ödülü ikinci kez verilmemeli")

-- ---- 4) Kayıt: bayraklar kalıcı, deneme süresi çevrimdışıyken AKMAZ
now += 300 -- 5 dakika oynadı
assert(PlayerStats.saveNow(kid) == true, "kayıt başarılı olmalı")
local record = S.datastore["Player_9301"]
assert(record, "kayıt yazılmış olmalı")
assert(record.AutoTrial == 0, "deneme süresi kayıtlı olmamalı: " .. tostring(record.AutoTrial))
assert(#record.IndexRewards == #Config.Index.Rewards, "alınan Index ödülleri kayıtlı olmalı: " .. #record.IndexRewards)
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
assert((kidAgain:GetAttribute("AutoClickTrialUntil") or 0) == 0, "tekrar girişte de deneme süresi olmamalı: " .. tostring(kidAgain:GetAttribute("AutoClickTrialUntil")))
local winsAgain = stat(kidAgain, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(kidAgain)
end
assert(stat(kidAgain, Config.StatWins) == winsAgain, "tekrar girişte de tıklamalar Win'i sessizce vermemeli")

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
