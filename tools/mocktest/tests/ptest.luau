local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")
PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Tester"
player.UserId = 4242
rawset(player, "Parent", {})
S.events.PlayerAdded(player)

local ls = player:FindFirstChild("leaderstats")
local function stat(name)
	return ls:FindFirstChild(name).Value
end
print("loaded: TutorialDone=", player:GetAttribute("TutorialDone"), "Clicks=", player:GetAttribute("TutorialClicks"), "DataLoaded=", player:GetAttribute("DataLoaded"))
print("QuestData:", player:GetAttribute("QuestData"))

for i = 1, 32 do
	PlayerStats.tutorialClick(player)
end
print("clicks after 32:", player:GetAttribute("TutorialClicks"))

ls:FindFirstChild(Config.StatWins).Value = 100
print("buySkin:", PlayerStats.buySkin(player, "mint"))
print("TutorialDone after skin:", player:GetAttribute("TutorialDone"), "SkinBonus", player:GetAttribute("SkinBonus"), "PerClick", player:GetAttribute("PerClick"))
print("buyItem:", PlayerStats.buyItem(player, "oldsneakers"))

ls:FindFirstChild(Config.StatWins).Value = 5000
print("hatch:", PlayerStats.hatchEgg(player, Config.Eggs[1].id, 3))
print("OwnedPets:", player:GetAttribute("OwnedPets"), "EquippedPets:", player:GetAttribute("EquippedPets"))

print("dev FreeCats:", PlayerStats.dev(player, "FreeCats"))
local owned = player:GetAttribute("OwnedPets")
print("OwnedPets:", owned)
local counts = {}
for id in string.gmatch(owned, "[^,]+") do
	counts[id] = (counts[id] or 0) + 1
end
for id, n in counts do
	if n >= 3 then
		print("fusePet", id, PlayerStats.fusePet(player, id))
		break
	end
end
print("OwnedPets:", player:GetAttribute("OwnedPets"), "Equipped:", player:GetAttribute("EquippedPets"), "PetMult:", player:GetAttribute("PetMultiplier"))
print("fuseAll:", PlayerStats.fuseAllPets(player))
print("Discovered:", player:GetAttribute("DiscoveredPets"), "Index%:", player:GetAttribute("IndexBonus"))

print("dev QuestsComplete:", PlayerStats.dev(player, "QuestsComplete"))
print("claim 1:", PlayerStats.claimQuest(player, 1))
print("claim 1 again:", PlayerStats.claimQuest(player, 1))
print("bonus too early:", PlayerStats.claimQuestBonus(player))
print("claim 2:", PlayerStats.claimQuest(player, 2))
print("claim 3:", PlayerStats.claimQuest(player, 3))
print("bonus:", PlayerStats.claimQuestBonus(player))
print("bonus again:", PlayerStats.claimQuestBonus(player))
print("QuestData:", player:GetAttribute("QuestData"))
PlayerStats.dev(player, "QuestsReset")
PlayerStats.questEvent(player, "walls", 5)
PlayerStats.questEvent(player, "clicks", 10)
print("QuestData after events:", player:GetAttribute("QuestData"))
print("muscle", stat(Config.StatLegMuscle), "wins", stat(Config.StatWins), "level", stat(Config.StatLevel))
-- İksirler kayda girer: envanterdeki iksir ve etkin iksirin kalan süresi çıkış-giriş sonrası geri gelir
PlayerStats.dev(player, "PotionWins")
PlayerStats.dev(player, "PotionMuscle")
assert(PlayerStats.usePotion(player, "muscle15") == true, "iksir içilebilmeli")
S.events.PlayerRemoving(player)
local saved = S.datastore["Player_4242"]
print("saved TutorialDone:", saved and saved.TutorialDone, "Quests day:", saved and saved.Quests and saved.Quests.day, "pets:", saved and #saved.Pets)
assert(saved.PotionItems and saved.PotionItems.wins15 == 1, "envanterdeki iksir kaydedilmeli")
assert(saved.BoostUntil and saved.BoostUntil.muscle > os.time(), "etkin iksirin bitiş zamanı kaydedilmeli")
local again = S.newInstance("Player")
again.Name = "Tester"
again.UserId = 4242
rawset(again, "Parent", {})
S.events.PlayerAdded(again)
assert(string.find(again:GetAttribute("PotionItems") or "", "wins15:1", 1, true), "iksir envanteri girişte geri gelmeli: " .. tostring(again:GetAttribute("PotionItems")))
assert(again:GetAttribute("MuscleBoostUntil") > os.time(), "etkin iksir girişte sürmeli")
print("potions persisted ok")
print("DONE")
