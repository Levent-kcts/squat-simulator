-- YENİ OYUNCU GÖREVLERİ ve REHBER TURU (2026-10-13): sunucu ilerlemeyi hesaplar, biten görev kilitlenir, ödül bir kez alınır; eski oyuncuya geriye dönük ödül/tur yok.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")

local now = 8000000
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

-- 'StarterState' = 'id,ilerleme,bitti,alındı;...'
local function state(player)
	local result = {}
	for entry in string.gmatch(player:GetAttribute("StarterState") or "", "[^;]+") do
		local id, progress, done, claimed = string.match(entry, "^([^,]+),(%d+),(%d),(%d)$")
		result[id] = { progress = tonumber(progress), done = done == "1", claimed = claimed == "1" }
	end
	return result
end
local function claim(player, id)
	return PlayerStats.claimStarter(player, id)
end

local kid = join(9401, "StarterKid")
local quests = Config.StarterQuests
assert(#quests == 10, "10 yeni oyuncu görevi olmalı")
local s0 = state(kid)
for _, quest in quests do
	assert(s0[quest.id] and not s0[quest.id].done and not s0[quest.id].claimed, "başta hiçbir görev bitmemiş olmalı: " .. quest.id)
end
assert(select(1, claim(kid, "squat")) == false, "bitmeyen görev alınamaz")
assert(select(1, claim(kid, "nope")) == false, "olmayan görev alınamaz")

-- 1) squat: eğitim tıklamaları
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(kid)
end
assert(state(kid).squat.done, "30 tıklama görevi bitmeli")
local winsBefore = stat(kid, Config.StatWins)
assert(winsBefore == 0, "görev bitince ödül SESSİZCE verilmemeli: " .. winsBefore)
assert(select(1, claim(kid, "squat")) == true, "bitmiş görev alınmalı")
assert(stat(kid, Config.StatWins) == winsBefore + quests[1].rewards[1].amount, "squat ödülü Quests'ten alınınca verilir: " .. stat(kid, Config.StatWins))
assert(select(1, claim(kid, "squat")) == false, "ödül ikinci kez alınamaz")
assert(state(kid).squat.claimed, "alındı işareti")

-- 2) duvar: ömür boyu kırılan duvar sayısı
PlayerStats.questEvent(kid, "walls", 2)
assert(not state(kid).wall.done and state(kid).wall.progress == 2, "2 duvar: görev bitmemeli")
PlayerStats.questEvent(kid, "walls", 1)
assert(state(kid).wall.done, "3 duvar: görev bitmeli")
assert(select(1, claim(kid, "wall")) == true)

-- 3) pet / skin / ayakkabı
PlayerStats.dev(kid, "AddWins", 500)
assert(PlayerStats.hatchEgg(kid, Config.Eggs[1].id, 1) == true, "yumurta açılmalı")
assert(state(kid).pet.done, "ilk pet görevi bitmeli")
assert(select(1, PlayerStats.buySkin(kid, Config.Skins[1].id)) == true)
assert(state(kid).skin.done, "ilk skin görevi")
assert(select(1, PlayerStats.buyItem(kid, Config.Items[1].id)) == true)
assert(state(kid).shoes.done, "ilk ayakkabı görevi")

-- 4) level 10 (kilitlenir: rebirth sonrası level 1 olsa da görev bitmiş kalır)
PlayerStats.dev(kid, "AddLevel", 9)
assert(state(kid).level10.done, "level 10 görevi bitmeli")

-- 5) Playtime ödülü, antrenman alanı, çark
assert(not state(kid).gift.done and not state(kid).train.done and not state(kid).wheel.done, "bu üç görev henüz bitmemiş")
PlayerStats.dev(kid, "GiftTime", 60)
assert(select(1, PlayerStats.claimGift(kid, 1)) == true, "Playtime ödülü alınmalı")
assert(state(kid).gift.done, "Playtime görevi bitmeli")
PlayerStats.markTrained(kid)
assert(state(kid).train.done, "antrenman alanı görevi bitmeli")
local okSpin = PlayerStats.spinWheel(kid)
assert(okSpin == true and state(kid).wheel.done, "çark görevi bitmeli")

-- 6) rebirth: level sınırı + rebirth; iksir ödülü hemen başlar
PlayerStats.dev(kid, "MaxLevel")
assert(not state(kid).rebirth.done, "rebirth yapılmadan görev bitmemeli")
assert(PlayerStats.rebirth(kid) == true)
assert(stat(kid, Config.StatLevel) == 1 and state(kid).level10.done and state(kid).level10.progress == 10, "level 1'e dönse de level 10 görevi kilitli kalmalı")
assert(state(kid).rebirth.done, "rebirth görevi bitmeli")
local winsRebirth = stat(kid, Config.StatWins)
assert(select(1, claim(kid, "rebirth")) == true)
assert(stat(kid, Config.StatWins) == winsRebirth + 100 and kid:GetAttribute("RainbowBoostUntil") and kid:GetAttribute("RainbowBoostUntil") > 0, "rebirth ödülü: +100 Win ve Rainbow iksiri başlamalı")
for _, id in { "level10", "gift", "train", "wheel", "pet", "skin", "shoes" } do
	assert(select(1, claim(kid, id)) == true, "görev alınmalı: " .. id)
end
for _, quest in quests do
	assert(state(kid)[quest.id].claimed, "hepsi alınmış olmalı: " .. quest.id)
end

-- 7) Rehber turu: görülen adım kaydedilir, geçersiz id reddedilir
assert((kid:GetAttribute("GuideSeen") or "") == "", "başta görülmüş adım yok")
assert(select(1, PlayerStats.guideSeen(kid, "welcome")) == true)
assert(select(1, PlayerStats.guideSeen(kid, "nope")) == false, "geçersiz adım reddedilmeli")
assert(string.find(kid:GetAttribute("GuideSeen"), "welcome", 1, true), "görülen adım özniteliğe yazılmalı")

-- 8) Kayıt: alınanlar, kilitler, bayraklar ve görülen adımlar kalıcı
assert(PlayerStats.saveNow(kid) == true)
local record = S.datastore["Player_9401"]
assert(#record.StarterClaimed == #quests and #record.StarterDone == #quests, "hepsi kayıtlı olmalı")
assert(record.WallsBroken == 3, "kırılan duvar sayısı kayıtlı: " .. tostring(record.WallsBroken))
assert(#record.GuideSeen == 1 and record.GuideSeen[1] == "welcome", "görülen rehber adımı kayıtlı")
local again = join(9401, "StarterKidAgain")
assert(state(again).rebirth.claimed and state(again).wall.claimed, "tekrar girişte alınanlar korunmalı")
assert(select(1, claim(again, "squat")) == false, "tekrar girişte ödül ikinci kez alınamaz")

-- 8b) DEV 'RestartTutorial': yeni oyuncu durumuna döner (kas/level/rebirth/Win/pet/skin/görev/rehber sıfır, deneme yeniden, Guide açık); iz/aura/iksir kalır
PlayerStats.dev(again, "DiscoverAll")
PlayerStats.dev(again, "PotionLuck")
PlayerStats.dev(again, "AddWins", 100)
PlayerStats.dev(again, "AddRebirth")
PlayerStats.setSetting(again, "GuideOn", false)
local okRestart, restartMessage = PlayerStats.dev(again, "RestartTutorial")
assert(okRestart and string.find(restartMessage, "Tutorial restarted", 1, true), "RestartTutorial başarılı olmalı: " .. tostring(restartMessage))
assert(again:GetAttribute("TutorialDone") == false and again:GetAttribute("TutorialClicks") == 0, "eğitim baştan başlamalı")
assert(stat(again, Config.StatWins) == 0 and stat(again, Config.StatLevel) == 1 and stat(again, Config.StatRebirths) == 0 and stat(again, Config.StatLegMuscle) == 0, "kas, level, rebirth ve Win sıfırlanmalı")
assert((again:GetAttribute("OwnedPets") or "") == "" and (again:GetAttribute("OwnedSkins") or "") == "" and (again:GetAttribute("OwnedItems") or "") == "", "pet, skin ve ayakkabı sıfırlanmalı")
assert((again:GetAttribute("GuideSeen") or "x") == "", "rehber kaydı sıfırlanmalı (tur baştan)")
for _, quest in quests do
	local entry = state(again)[quest.id]
	assert(entry and not entry.done and not entry.claimed, "yeni oyuncu görevleri sıfırlanmalı: " .. quest.id)
end
assert(again:GetAttribute("GuideOn") == true, "kapalı Guide tekrar açılmalı")
assert((again:GetAttribute("AutoClickTrialUntil") or 0) == 0, "ücretsiz Auto Click denemesi kapalı: süre verilmemeli")
assert(string.find(again:GetAttribute("PotionItems") or "", "luck", 1, true), "iksir kalmalı")
assert((again:GetAttribute("DiscoveredPets") or "x") == "", "keşfedilen petler sıfırlanmalı ('ilk pet' görevi buna bakar)")
local restartWins = stat(again, Config.StatWins)
for _ = 1, Config.Tutorial.ClickGoal do
	PlayerStats.tutorialClick(again)
end
assert(stat(again, Config.StatWins) == restartWins, "30 tıklamada Win sessizce verilmemeli (ödül Quests'ten CLAIM ile alınır)")
assert(select(1, claim(again, "squat")) == true and stat(again, Config.StatWins) == restartWins + quests[1].rewards[1].amount, "restart sonrası squat ödülü yeniden alınabilmeli")

-- 9) Eski oyuncu: görevler 'alınmış', rehber 'görülmüş' sayılır (geriye dönük ödül ve tur YOK)
S.datastore["Player_9402"] = { Muscle = 5000, Wins = 10, Level = 5, Rebirths = 1 }
local veteran = join(9402, "Veteran")
local vs = state(veteran)
for _, quest in quests do
	assert(vs[quest.id].claimed, "eski oyuncuda görev alınmış sayılmalı: " .. quest.id)
end
local veteranWins = stat(veteran, Config.StatWins)
assert(select(1, claim(veteran, "squat")) == false and stat(veteran, Config.StatWins) == veteranWins, "eski oyuncuya ödül verilmemeli")
local seen = veteran:GetAttribute("GuideSeen") or ""
for _, step in Config.GuideTour do
	assert(string.find(seen, step.id, 1, true), "eski oyuncuda rehber adımı görülmüş sayılmalı: " .. step.id)
end

print("starter quests ok")
