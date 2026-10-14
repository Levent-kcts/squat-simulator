-- MASTERY PENCERESİ (client/MasteryPanel): her dal için kart, kademe yazısı, maliyetli BUY düğmesi; azami kademede MAXED.
local S = require("../cstubs")
local Config = require("./Config")
local MasteryPanel = require("./MasteryPanel")

local function findText(instance, wanted)
	if rawget(instance, "Text") ~= nil and string.find(tostring(rawget(instance, "Text")), wanted, 1, true) then
		return true
	end
	for _, child in rawget(instance, "_children") do
		if findText(child, wanted) then
			return true
		end
	end
	return false
end
local function countNamed(instance, prefix)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if string.sub(tostring(rawget(child, "Name")), 1, #prefix) == prefix then
			total += 1
		end
		total += countNamed(child, prefix)
	end
	return total
end

S.localPlayer:SetAttribute("MasteryLevels", `power:3,smash:{Config.Mastery.MaxLevel},fortune:0`)
local root = S.newInstance("Frame")
local ok, toggle = pcall(MasteryPanel.init, root, function() end)
assert(ok, "MasteryPanel.init hata verdi: " .. tostring(toggle))
assert(type(toggle) == "function", "açma fonksiyonu dönmeli")
toggle()
assert(countNamed(root, "Mastery_") == #Config.Mastery.Branches, "her dal için kart olmalı")
assert(findText(root, "3/" .. Config.Mastery.MaxLevel), "kademe çubuğu yazısı olmalı")
assert(findText(root, "MAXED"), "azami kademede MAXED yazmalı")
assert(findText(root, "Iron Legs") and findText(root, "Win Magnet"), "dal adları görünmeli")
print("mastery panel ok")
