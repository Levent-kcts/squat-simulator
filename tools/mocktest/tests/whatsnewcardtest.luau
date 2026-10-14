-- NELER YENİ KARTI (client/WhatsNewCard): görülmemiş sürümde ve eğitim bitmişse kendiliğinden açılır; GOT IT sunucuya 'SeenWhatsNew' yollar; Settings'teki OPEN aynı kartı açar.
local S = require("../cstubs")
local Config = require("./Config")
local WhatsNewCard = require("./WhatsNewCard")

local function findNamed(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = findNamed(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
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

S.localPlayer:SetAttribute("DataLoaded", true)
S.localPlayer:SetAttribute("TutorialDone", true)
S.localPlayer:SetAttribute("WhatsNewSeen", 0)
local root = S.newInstance("Frame")
local ok, show = pcall(WhatsNewCard.init, root)
assert(ok, "WhatsNewCard.init hata verdi: " .. tostring(show))
assert(type(show) == "function", "init kartı açan fonksiyon döndürmeli")
local card = findNamed(root, "WhatsNewCard")
assert(card, "kart kurulmalı")
assert(countNamed(card, "Line_") == #Config.WhatsNew.Lines, "her satır için bir kutu olmalı")
assert(findNamed(card, "GotItButton"), "GOT IT düğmesi olmalı")
show()
assert(rawget(card, "Visible") == true, "show() kartı açmalı")
print("whats new card ok")
