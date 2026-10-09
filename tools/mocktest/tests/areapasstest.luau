-- Robux'lu antrenman pedleri (Coach Prism: rebirth 32 ya da Robux, Coach Shadow: sadece Robux; sahibi istedi): sahiplik sunucuda, kilit kararı PlayerStats.isAreaUnlocked'ta, satın alma penceresi AreaPasses.prompt'ta
local S = require("./stubs")

local owners = {} -- [userId] = { [passId] = true }
local purchaseHandlers = {}
local prompts = {}
local market = {
	UserOwnsGamePassAsync = function(_, userId, passId)
		return owners[userId] ~= nil and owners[userId][passId] == true
	end,
	PromptGamePassPurchase = function(_, _, passId)
		table.insert(prompts, passId)
	end,
	PromptGamePassPurchaseFinished = {
		Connect = function(_, f)
			table.insert(purchaseHandlers, f)
			return { Disconnect = function() end }
		end,
	},
}
local originalGetService = S.game.GetService
S.game.GetService = function(self, name)
	if name == "MarketplaceService" then
		return market
	end
	return originalGetService(self, name)
end

local Config = require("./Config")
local PlayerStats = require("./PlayerStats")
local AreaPasses = require("./AreaPasses")

local prism, shadow
for _, area in Config.Training.Areas do
	if area.id == "rainbow" then
		prism = area
	elseif area.id == "black" then
		shadow = area
	end
end
-- ---- Config: Prism rebirth ile de açılır, Shadow SADECE Robux ile; ikisinin de fiyatı var
assert(prism and prism.robux and not prism.robuxOnly and prism.rebirths == 32, "Prism: rebirth 32 ya da Robux")
assert(shadow and shadow.robux and shadow.robuxOnly == true and shadow.rebirths == nil, "Shadow: sadece Robux, rebirth yolu YOK")
local paid = 0
for _, area in Config.Training.Areas do
	if area.robux then
		paid += 1
	end
end
assert(paid == 2, "sadece iki ped Robux'lu olmalı (Prism, Shadow): " .. paid)

PlayerStats.init()
local function newPlayer(userId)
	local player = S.newInstance("Player")
	player.Name = "Coach" .. userId
	player.UserId = userId
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
local messages = {}
local notifyEvent = {
	FireClient = function(_, _, ok, message)
		table.insert(messages, { ok = ok, message = message })
	end,
}
-- Taklitte PlayerAdded tek işleyici tutar (AreaPasses.init onu değiştirir): oyuncular PlayerStats yüklemesi için ÖNCEDEN eklenir, AreaPasses sahipliği recheck ile sorar
local player = newPlayer(7001)
local second = newPlayer(7002) -- rebirth 0
local third = newPlayer(7003)
local fourth = newPlayer(7004)
AreaPasses.init(notifyEvent)

local function unlockedList(who)
	return "," .. (who:GetAttribute("UnlockedAreas") or "") .. ","
end

-- 1) Pass'ler satışa açık değil (gamePassId 0): ikisi de kilitli; rebirth sayısı Shadow'u ASLA açmaz, Prism'i 32'de açar
prism.gamePassId, shadow.gamePassId = 0, 0
AreaPasses.recheck(player)
assert(player:GetAttribute("HasArea_rainbow") == false and player:GetAttribute("HasArea_black") == false, "satışta değilken kilitli")
assert(not PlayerStats.isAreaUnlocked(player, prism) and not PlayerStats.isAreaUnlocked(player, shadow), "rebirth 0: ikisi de kilitli")
PlayerStats.dev(player, "AddRebirth", 50)
assert(PlayerStats.isAreaUnlocked(player, prism), "Prism rebirth ile açılır")
assert(not PlayerStats.isAreaUnlocked(player, shadow), "Shadow rebirth ile ASLA açılmaz (sadece Robux)")
assert(string.find(unlockedList(player), ",rainbow,", 1, true) and not string.find(unlockedList(player), ",black,", 1, true), "UnlockedAreas: Prism var, Shadow yok: " .. unlockedList(player))

-- 2) Satış yokken ped'e basınca fiyatlı 'coming soon', satın alma penceresi açılmaz
messages = {}
assert(AreaPasses.prompt(player, shadow) == false, "satışta olmayan pass için pencere açılmaz")
assert(#prompts == 0 and string.find(messages[1].message, "coming soon", 1, true) and string.find(messages[1].message, tostring(shadow.robux), 1, true), "fiyatlı coming soon: " .. tostring(messages[1] and messages[1].message))

-- 3) Pass satışta: sahip değilse pencere açılır (aynı pede 20 sn içinde ikinci kez açılmaz), sahipse ped açılır
prism.gamePassId, shadow.gamePassId = 4444, 5555
AreaPasses.recheck(second)
assert(second:GetAttribute("HasArea_black") == false and not PlayerStats.isAreaUnlocked(second, shadow), "sahip değil: kilitli")
assert(AreaPasses.prompt(second, shadow) == true and prompts[#prompts] == 5555, "Shadow pass'ının satın alma penceresi açılmalı")
assert(AreaPasses.prompt(second, shadow) == false and #prompts == 1, "aynı pede kısa sürede ikinci pencere açılmamalı")
assert(AreaPasses.prompt(second, prism) == true and prompts[#prompts] == 4444, "başka pedin penceresi bağımsızdır")
owners[7002] = { [4444] = true } -- Prism'e sahip, rebirth 0
AreaPasses.recheck(second)
assert(PlayerStats.isAreaUnlocked(second, prism), "Prism pass'i rebirth olmadan açar")
assert(not PlayerStats.isAreaUnlocked(second, shadow), "Prism pass'i Shadow'u açmaz")
assert(string.find(unlockedList(second), ",rainbow,", 1, true) and not string.find(unlockedList(second), ",black,", 1, true), "UnlockedAreas yenilenmeli: " .. unlockedList(second))
owners[7002][5555] = true
AreaPasses.recheck(second)
assert(PlayerStats.isAreaUnlocked(second, shadow) and string.find(unlockedList(second), ",black,", 1, true), "Shadow pass'ı Shadow'u açar")

-- 4) DEV: 'Passes Lock' sahip olsa bile kilitler, 'Coach Pads (test)' pass'siz açar
second:SetAttribute("DevPassLock", true)
AreaPasses.recheck(second)
assert(not PlayerStats.isAreaUnlocked(second, shadow) and not PlayerStats.isAreaUnlocked(second, prism), "Passes Lock: kilitli")
second:SetAttribute("DevPassLock", nil)
third:SetAttribute("DevAreaPasses", true)
AreaPasses.recheck(third)
assert(PlayerStats.isAreaUnlocked(third, shadow) and PlayerStats.isAreaUnlocked(third, prism), "Coach Pads (test): ikisi de açık")
third:SetAttribute("DevAreaPasses", nil)
AreaPasses.recheck(third)
assert(not PlayerStats.isAreaUnlocked(third, shadow), "DEV kapanınca tekrar kilitli")

-- 5) Satın alma tamamlanınca anında açılır ve bildirim gelir; iptalde sahiplik yeniden sorulur
AreaPasses.recheck(fourth)
messages = {}
assert(#purchaseHandlers >= 1, "PromptGamePassPurchaseFinished dinlenmeli")
for _, handler in purchaseHandlers do
	handler(fourth, 5555, false) -- iptal: değişiklik yok
end
assert(not PlayerStats.isAreaUnlocked(fourth, shadow), "iptal edilen satın alma pedi açmaz")
for _, handler in purchaseHandlers do
	handler(fourth, 5555, true)
end
assert(PlayerStats.isAreaUnlocked(fourth, shadow), "satın alma tamamlanınca Shadow açılır")
assert(messages[1] and messages[1].ok == true and string.find(messages[1].message, shadow.trainer .. " unlocked", 1, true), "açıldı bildirimi: " .. tostring(messages[1] and messages[1].message))
assert(not PlayerStats.isAreaUnlocked(fourth, prism), "başka pedin pass'i açılmadı")

print("area passes ok")
print("DONE")
