-- İstemci açılışı: init.client (tüm HUD, paneller, sağ üst daireler, eğitim yazısı...) tüm modülleriyle hatasız kurulmalı.
-- Özellik/enum adı geçerliliğini ve görünümü DOĞRULAMAZ.
local S = require("../cstubs")
local Config = require("./Config")
-- Yerel oyuncunun leaderstats'ı (istemci bunları bekler)
local leaderstats = S.newInstance("Folder")
leaderstats.Name = "leaderstats"
for _, name in { Config.StatLegMuscle, Config.StatWins, Config.StatLevel, Config.StatRebirths } do
	local value = S.newInstance("IntValue")
	value.Name = name
	value.Value = if name == Config.StatLevel then 1 else 0
	rawget(leaderstats, "_children")[name] = value
end
rawget(S.localPlayer, "_children")["leaderstats"] = leaderstats
S.localPlayer:SetAttribute("DataLoaded", true)
S.localPlayer:SetAttribute("TutorialDone", false)
S.localPlayer:SetAttribute("TutorialClicks", 5)
S.localPlayer:SetAttribute("MaxLevel", 20)
S.localPlayer:SetAttribute("TapsNeeded", 10)
S.localPlayer:SetAttribute("QuestData", "x")
S.jsonData = { resetAt = os.time() + 100, quests = {}, bonusClaimed = false, bonusText = "" }
local ok, err = pcall(require, "./clientMain")
print("client boot:", ok, err)
if not ok then
	print("ERROR client boot failed: " .. tostring(err))
end
-- Heartbeat döngülerini birkaç kez koştur (otomatik tıklama, gökkuşağı, yakınlık...)
-- Taklitte dünya nesneleri (yumurta pedleri, ses dosyaları) olmadığı için bu modüllerin döngüleri hata verir: bilinen taklit boşluğu, 'note' olarak yazılır
local KNOWN_GAPS = { "EggShop.luau", "Sfx.luau", "GiftsPanel.luau", "MusicPlayer.luau", "TrainingClient.luau", "OverheadTags.luau" }
for _ = 1, 3 do
	for _, hb in S.heartbeat do
		local good, message = pcall(hb, 0.5)
		if not good then
			local known = false
			for _, gap in KNOWN_GAPS do
				if string.find(tostring(message), gap, 1, true) then
					known = true
				end
			end
			print((if known then "note (mock gap) heartbeat: " else "ERROR heartbeat: ") .. tostring(message))
		end
	end
end
-- Eğitim yazısı mantığı: öznitelikleri değiştir
S.localPlayer:SetAttribute("TutorialClicks", 30)
S.localPlayer:SetAttribute("TutorialDone", true)
print("DONE")
