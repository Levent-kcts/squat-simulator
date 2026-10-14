-- SEZONLUK ETKİNLİK PENCERESİ (client/SpookyPanel): Candy sayısı, kilometre taşı kutuları (CLAIM), etkinlik mağazası satırları (fiyat / sahip / sınır).
local S = require("../cstubs")
local Config = require("./Config")
local SpookyPanel = require("./SpookyPanel")

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

local workspace = S.game:GetService("Workspace")
workspace:SetAttribute("SeasonActive", true)
workspace:SetAttribute("SeasonEnds", os.time() + 86400 * 3)
S.localPlayer:SetAttribute("Candy", 140)
S.localPlayer:SetAttribute("CandyTotal", 200)
S.localPlayer:SetAttribute("EventClaimed", "1")
S.localPlayer:SetAttribute("EventBought", "rainbow:2")
S.localPlayer:SetAttribute("EventPerks", "")

local root = S.newInstance("Frame")
local ok, toggle, panel = pcall(SpookyPanel.init, root, function() end)
assert(ok, "SpookyPanel.init hata verdi: " .. tostring(toggle))
assert(type(toggle) == "function" and panel, "init açma fonksiyonu ve pencere döndürmeli")
toggle()
assert(countNamed(root, "Milestone_") == #Config.Event.Milestones, "her kilometre taşı için kutu olmalı")
assert(countNamed(root, "EventItem_") == #Config.Event.Items, "her ürün için satır olmalı")
assert(findText(root, "140"), "Candy sayısı görünmeli")
assert(findText(root, "CLAIM"), "eşiği geçilmiş, alınmamış taş için CLAIM olmalı (200 toplam: 2. taş 180)")
assert(findText(root, "✓"), "alınmış kilometre taşı işaretli olmalı")
assert(findText(root, "2/10"), "limitli ürünlerde alım sayacı görünmeli")
assert(findText(root, "Ends in") and findText(root, "d "), "kalan süre görünmeli")
assert(findText(root, "no random items"), "mağaza 'rastgele ürün yok' notunu taşımalı")

-- Etkinlik bitince kalan süre yerine 'Event ended'
workspace:SetAttribute("SeasonActive", false)
assert(findText(root, "Event ended"), "bitince yazı güncellenmeli (pencere açıkken)")
print("spooky panel ok")
