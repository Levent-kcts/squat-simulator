-- GÜNCEL HEDEF (2026-10-13, sahibi 'iki görev çakışıyor, görevleri birbirine entegre et' dedi: üst şerit 'ilk pet'i çıkar' derken rehber kartı 'duvarları kır' diyordu):
-- yeni oyuncunun o an yapması gereken TEK şey burada hesaplanır ve hepsi bunu okur: üstteki hedef şeridi (init.client), yol gösterici çizgi (Guide), rehber kartları (GuideTour 'quest:<id>').
-- Hedef = Config.StarterQuests listesinin sırasıyla ilk bitmemiş görevi (sunucu 'StarterState' + anlık özellikler); pet/skin görevlerinde Win yetmiyorsa o an yapılacak şey 'duvar kırıp Win kazanmak'tır.
-- Tamamen görseldir; sunucu mantığına dokunmaz.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local Objective = {}

-- 'StarterState' = 'id,ilerleme,bitti,alındı;...' (sunucu PlayerStats.publishStarter)
function Objective.readStates(player)
	local states = {}
	for entry in string.gmatch(player:GetAttribute("StarterState") or "", "[^;]+") do
		local id, progress, done, claimed = string.match(entry, "^([^,]+),(%d+),(%d),(%d)$")
		if id then
			states[id] = { progress = tonumber(progress), done = done == "1", claimed = claimed == "1" }
		end
	end
	return states
end

-- Ödül listesini kısa yazıya çevirir ('+8 Wins', 'Rainbow Potion 15m'); QuestPanel'deki ile aynı biçim
function Objective.rewardText(rewards)
	local parts = {}
	for _, reward in rewards do
		if reward.kind == "wins" then
			table.insert(parts, `+{reward.amount} Wins`)
		else
			local potion = Catalog.PotionByKind[reward.kind]
			table.insert(parts, `{if potion then potion.name else "Potion"} {reward.minutes or Config.BoostMinutes}m`)
		end
	end
	return table.concat(parts, " + ")
end

local function rebirthObjective(quest, ctx)
	local level = ctx.level or 1
	local maxLevel = math.max(1, ctx.maxLevel or level)
	if level >= maxLevel then
		return { id = "rebirth", quest = quest, text = "MAX LEVEL! Open REBIRTH on the left to grow stronger forever!", fraction = 1 }
	end
	return { id = "rebirth", quest = quest, text = `Goal: reach level {maxLevel} to REBIRTH!  ({level}/{maxLevel})`, fraction = math.clamp(level / maxLevel, 0, 1) }
end

-- ctx: { wins, level, maxLevel, rebirths, wallText }  (wallText: duvar ilerleme yazısı, Win kazanma adımında gösterilir)
-- Dönüş: { id = görev kimliği, text = şerit yazısı, fraction = 0-1 ya da nil (çubuk), quest = görev girdisi } ya da nil (hedef kalmadı)
function Objective.read(player, ctx)
	local states = Objective.readStates(player)
	local clicks = player:GetAttribute("TutorialClicks") or 0
	local goal = Config.Tutorial.ClickGoal
	local quests = Config.StarterQuests
	local total = #quests
	local wins = ctx.wins or 0
	-- Biten ama ödülü alınmamış görev varsa hedef: Quests'ten ödülü almak. Ödül SESSİZCE verilmez (sahibi istedi): oyuncu Quests penceresine yönlendirilir, oradan CLAIM eder, ardından zincir devam eder.
	-- (rebirth görevi hariç: rebirth'ten sonra şerit/rehber zaten kapanır, ödülü Quests rozetinden alınır.)
	for _, quest in quests do
		local state = states[quest.id]
		if state and state.done and not state.claimed and quest.id ~= "rebirth" then
			return { id = "claim", quest = quest, text = `Quest complete! Tap 📜 QUESTS (top right) and CLAIM {Objective.rewardText(quest.rewards)}!` }
		end
	end
	-- Level sınırına gelindiyse (ve ilk rebirth yapılmadıysa) sıradaki isteğe bağlı görevler ne olursa olsun hedef REBIRTH'tir: ilerleme orada tıkanıyor
	local maxLevel = ctx.maxLevel or 0
	if (ctx.rebirths or 0) == 0 and clicks >= goal and maxLevel > 0 and (ctx.level or 1) >= maxLevel then
		for _, quest in quests do
			if quest.id == "rebirth" then
				return rebirthObjective(quest, ctx)
			end
		end
	end
	for index, quest in quests do
		local state = states[quest.id]
		local done = state ~= nil and state.done
		local progress = if state then state.progress else 0
		-- Anlık bayraklar: sunucunun yayımı gelmeden de şerit doğru çıksın
		if quest.id == "squat" then
			done = done or clicks >= goal
			progress = math.max(progress, clicks)
		elseif quest.id == "pet" then
			done = done or (player:GetAttribute("OwnedPets") or "") ~= ""
		elseif quest.id == "skin" then
			done = done or (player:GetAttribute("OwnedSkins") or "") ~= ""
		elseif quest.id == "rebirth" then
			done = (ctx.rebirths or 0) > 0 -- eski oyuncuda görev 'alınmış' sayılsa da rebirth yapılmadıysa hedef durur
		end
		if not done then
			if quest.id == "squat" then
				return { id = "squat", quest = quest, text = `Click anywhere to squat and get stronger!  ({math.min(clicks, goal)}/{goal})`, fraction = math.clamp(clicks / goal, 0, 1) }
			elseif quest.id == "pet" then
				local egg = Config.Eggs[1]
				if wins >= egg.price then
					return { id = "pet", quest = quest, text = `You have {Format.number(wins)} Wins! Hatch your FIRST PET: step on the {egg.name} pad at the back wall and press E!` }
				end
				return { id = "wall", quest = quest, text = ctx.wallText or "Break the walls to earn Wins!", earning = true }
			elseif quest.id == "skin" then
				local skin = Config.Skins[1]
				if wins >= skin.price then
					return { id = "skin", quest = quest, text = `You have {Format.number(wins)} Wins! Go to the SKIN shelf on the left wall and step on the {skin.name} pad!` }
				end
				return { id = "wall", quest = quest, text = ctx.wallText or "Break the walls to earn Wins!", earning = true }
			elseif quest.id == "rebirth" then
				return rebirthObjective(quest, ctx)
			end
			-- Diğer görevler: 'Quest 4/10: Break 3 walls (1/3)'
			local text = `Quest {index}/{total}: {quest.text}`
			local fraction = nil
			if quest.goal > 1 then
				local shown = math.min(progress, quest.goal)
				text ..= `  ({shown}/{quest.goal})`
				fraction = math.clamp(shown / quest.goal, 0, 1)
			end
			return { id = quest.id, quest = quest, text = text, fraction = fraction }
		end
	end
	return nil
end

return Objective
