-- GÜNCEL HEDEF (client/Objective): üst şerit, yol çizgisi ve rehber kartları aynı hedefi okur (2026-10-13 'iki görev çakışıyor' düzeltmesi).
local S = require("../cstubs")
local Config = require("./Config")
local Objective = require("./Objective")

local player = S.localPlayer
local function read(overrides)
	local ctx = { wins = 0, level = 1, maxLevel = Config.Level.BaseMaxLevel, rebirths = 0, wallText = "WALLS" }
	for key, value in overrides or {} do
		ctx[key] = value
	end
	return Objective.read(player, ctx)
end
local function states(done)
	local parts = {}
	for _, quest in Config.StarterQuests do
		local isDone = done[quest.id] == true
		table.insert(parts, `{quest.id},{if isDone then quest.goal else 0},{if isDone then 1 else 0},{if isDone then 1 else 0}`)
	end
	player:SetAttribute("StarterState", table.concat(parts, ";"))
end

-- Görev sırası: tıklama > pet > skin (Win'ler ilk 30 tıklamanın hediyesinden gelir), sonra duvar ve diğerleri, rebirth en sonda
local order = {}
for _, quest in Config.StarterQuests do
	table.insert(order, quest.id)
end
assert(table.concat(order, ",", 1, 4) == "squat,pet,skin,wall", "görev sırası squat, pet, skin, wall ile başlamalı: " .. table.concat(order, ","))
assert(order[#order - 1] == "rebirth" and order[#order] == "wheel", "sıra ... rebirth, wheel ile bitmeli (çark ilk rebirth'ten SONRA, son görev)")

states({})
player:SetAttribute("TutorialClicks", 7)
local objective = read()
assert(objective.id == "squat" and objective.fraction == 7 / Config.Tutorial.ClickGoal and string.find(objective.text, "(7/" .. Config.Tutorial.ClickGoal .. ")", 1, true), "squat hedefi tıklama sayısını göstermeli: " .. objective.text)

player:SetAttribute("TutorialClicks", Config.Tutorial.ClickGoal)
assert(read({ wins = 0 }).id == "wall" and read({ wins = 0 }).earning, "Win yokken hedef Win kazanmak (duvar) olmalı")
assert(read({ wins = 0 }).text == "WALLS", "Win kazanma adımı duvar ilerleme yazısını göstermeli")
assert(read({ wins = Config.Eggs[1].price }).id == "pet", "ilk yumurtaya yetecek Win varken hedef ilk pet olmalı")

player:SetAttribute("OwnedPets", "cat")
assert(read({ wins = 0 }).id == "wall", "pet alındı, skine Win yok: hedef duvar")
assert(read({ wins = Config.Skins[1].price }).id == "skin", "skine yetecek Win varken hedef ilk skin olmalı")

player:SetAttribute("OwnedSkins", Config.Skins[1].id)
objective = read()
assert(objective.id == "wall" and string.find(objective.text, "Quest 4/" .. #order .. ": " .. Config.StarterQuests[4].text, 1, true) and objective.fraction == 0, "skinden sonra hedef 3 duvar görevi olmalı: " .. objective.text)

-- Görevler bitince son hedef rebirth: level ilerlemesi ve sınırda 'MAX LEVEL'
local allButRebirth = {}
for _, quest in Config.StarterQuests do
	allButRebirth[quest.id] = quest.id ~= "rebirth"
end
states(allButRebirth)
objective = read({ level = 3 })
assert(objective.id == "rebirth" and string.find(objective.text, "Goal: reach level " .. Config.Level.BaseMaxLevel .. " to REBIRTH!", 1, true) and objective.fraction == 3 / Config.Level.BaseMaxLevel, "son hedef rebirth olmalı: " .. objective.text)
assert(string.find(read({ level = Config.Level.BaseMaxLevel }).text, "MAX LEVEL!", 1, true), "sınırda MAX LEVEL yazmalı")

-- Level sınırına gelince (rebirth yapılmadıysa) sıradaki isteğe bağlı görevler ne olursa olsun hedef REBIRTH'tir
states({ squat = true, pet = true, skin = true })
assert(read({ level = 3 }).id == "wall", "sınırdan uzaktayken görev zinciri sürer")
assert(read({ level = Config.Level.BaseMaxLevel }).id == "rebirth", "level sınırında hedef rebirth olmalı (ilerleme orada tıkanır)")

-- Biten ama ödülü alınmamış görev: hedef 'claim' (ödül sessizce verilmez; Quests'ten alınır), alınınca zincir sürer
local function statesWithUnclaimed(doneIds, unclaimedId)
	local parts = {}
	for _, quest in Config.StarterQuests do
		local isDone = doneIds[quest.id] == true
		table.insert(parts, `{quest.id},{if isDone then quest.goal else 0},{if isDone then 1 else 0},{if isDone and quest.id ~= unclaimedId then 1 else 0}`)
	end
	player:SetAttribute("StarterState", table.concat(parts, ";"))
end
player:SetAttribute("OwnedPets", "") -- (önceki bölümlerde pet/skin alınmıştı; zincir yeniden başlasın)
player:SetAttribute("OwnedSkins", "")
statesWithUnclaimed({ squat = true }, "squat")
objective = read({ wins = 0 })
assert(objective.id == "claim" and objective.quest.id == "squat" and string.find(objective.text, "CLAIM +" .. Config.StarterQuests[1].rewards[1].amount .. " Wins", 1, true), "biten görev için hedef 'claim' olmalı: " .. objective.text)
assert(Objective.rewardText({ { kind = "wins", amount = 8 } }) == "+8 Wins", "ödül yazısı")
statesWithUnclaimed({ squat = true }, "none")
assert(read({ wins = Config.Eggs[1].price }).id == "pet", "ödül alınınca zincir sürmeli")
statesWithUnclaimed({ squat = true, pet = true }, "pet")
assert(read({ wins = 99 }).id == "claim" and read({ wins = 99 }).quest.id == "pet", "her biten görev sırayla claim hedefi olur")
-- İLK REBIRTH: ödülü (Win + Rainbow + Auto Click Potion) de Quests'ten alınır; rebirth'ten sonra SADECE bu 'claim' hedefi kalır
local everything = { squat = true, pet = true, skin = true, wall = true, shoes = true, level10 = true, gift = true, train = true, wheel = true, rebirth = true }
statesWithUnclaimed(everything, "rebirth")
objective = read({ level = 1, rebirths = 1 })
assert(objective.id == "claim" and objective.quest.id == "rebirth" and string.find(objective.text, "Auto Click Potion 30m", 1, true), "rebirth sonrası ödülü Quests'ten al hedefi çıkmalı (Auto Click Potion yazmalı): " .. tostring(objective and objective.text))
player:SetAttribute("HasAutoClick", true) -- Auto Click game pass'i olana ödül yazısı Rainbow görünür
assert(string.find(read({ level = 1, rebirths = 1 }).text, "Rainbow Potion 15m + Rainbow Potion 15m", 1, true) or string.find(read({ level = 1, rebirths = 1 }).text, "Rainbow Potion 15m", 1, true), "pass sahibine yazı Rainbow demeli")
assert(not string.find(read({ level = 1, rebirths = 1 }).text, "Auto Click Potion", 1, true), "pass sahibine Auto Click Potion yazılmamalı")
player:SetAttribute("HasAutoClick", nil)
statesWithUnclaimed(everything, "none")
assert(read({ level = 1, rebirths = 1 }) == nil, "ödül alınınca rebirth sonrası hedef kalmamalı")

-- ÇARK SON GÖREV (sahibi 'ilk rebirth'ten sonra günlük çarka yönlendirsin, daha önce çevirilmediyse; görevler öyle bitsin' dedi)
local wheelNotDone = {}
for _, quest in Config.StarterQuests do
	wheelNotDone[quest.id] = quest.id ~= "wheel"
end
states(wheelNotDone)
assert(read({ level = 2 }).id == "rebirth", "rebirth'ten ÖNCE çark sorulmaz: hedef rebirth")
objective = read({ level = 1, rebirths = 1 })
assert(objective and objective.id == "wheel" and string.find(objective.text, "Spin the Daily Wheel", 1, true) and string.find(objective.text, "Quest " .. #order .. "/" .. #order, 1, true), "rebirth sonrası hedef çark olmalı: " .. tostring(objective and objective.text))
-- Rebirth sonrası bitmemiş diğer isteğe bağlı görevler (Gifts, antrenman...) atlanır: sadece çark kalır
local skippedOptional = {}
for _, quest in Config.StarterQuests do
	skippedOptional[quest.id] = quest.id == "rebirth" or quest.id == "squat" or quest.id == "pet" or quest.id == "skin"
end
states(skippedOptional)
assert(read({ level = 1, rebirths = 1 }).id == "wheel", "rebirth sonrası bitmemiş diğer görevler atlanıp çark gösterilmeli")
-- Çark daha önce çevrilmişse (görev bitti) rebirth sonrası hedef kalmaz; çevrilmiş ama alınmamışsa ödül alınır
statesWithUnclaimed(everything, "wheel")
objective = read({ level = 1, rebirths = 1 })
assert(objective and objective.id == "claim" and objective.quest.id == "wheel", "çevrilmiş çarkın ödülü alınmayı beklerse hedef claim olmalı")
statesWithUnclaimed(everything, "none")
assert(read({ level = 1, rebirths = 1 }) == nil, "çark da bitince görevler biter: hedef kalmamalı")

-- Eski oyuncu (tüm görevler 'alınmış', rebirth yok): hedef yine rebirth; rebirth yapınca hedef kalmaz
local allDone = {}
for _, quest in Config.StarterQuests do
	allDone[quest.id] = true
end
states(allDone)
assert(read({ level = 2 }).id == "rebirth", "eski oyuncuda da rebirth hedefi durmalı")
assert(read({ rebirths = 1 }) == nil, "ilk rebirth'ten sonra hedef kalmamalı")
print("objective ok")
