-- BAŞLANGIÇ PAKETİ TEKLİF KARTI (client/StarterOffer): RightHud sütununa yerleşir; sadece veri yüklü, eğitim bitmiş, paket alınmamış ve kısıtsız hesapta görünür;
-- X bu oturum için gizler; paket alınınca kalkar.
local S = require("../cstubs")
local StarterOffer = require("./StarterOffer")

local player = S.localPlayer
local root = S.newInstance("Frame")
local column = S.newInstance("Frame")
column.Name = "RightHud"
column.Parent = root

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

player:SetAttribute("DataLoaded", true)
player:SetAttribute("StarterPackOwned", nil)
player:SetAttribute("TutorialDone", false)
player:SetAttribute("PaidRandomRestricted", false)
local ok, err = pcall(StarterOffer.init, root, function() end)
assert(ok, "StarterOffer.init hata verdi: " .. tostring(err))
local offer = findNamed(root, "StarterOffer")
assert(offer and rawget(offer, "Parent") == column, "kart RightHud sütununda olmalı")
assert(rawget(offer, "Visible") == false, "eğitim bitmeden görünmemeli")

player:SetAttribute("TutorialDone", true)
assert(rawget(offer, "Visible") == true, "eğitimi bitmiş, almamış oyuncuda görünmeli")

player:SetAttribute("PaidRandomRestricted", true)
assert(rawget(offer, "Visible") == false, "kısıtlı hesapta görünmemeli")
player:SetAttribute("PaidRandomRestricted", false)
assert(rawget(offer, "Visible") == true, "kısıt kalkınca yine görünmeli")

player:SetAttribute("StarterPackOwned", true)
assert(rawget(offer, "Visible") == false, "paket alınınca kalkmalı")
player:SetAttribute("StarterPackOwned", nil)

local close = findNamed(offer, "CloseOffer")
local handlers = rawget(close, "_handlers")
assert(handlers and handlers.MouseButton1Click, "X düğmesinin tıklama işleyicisi olmalı")
handlers.MouseButton1Click()
assert(rawget(offer, "Visible") == false, "X kartı gizlemeli")
player:SetAttribute("TutorialDone", true)
assert(rawget(offer, "Visible") == false, "kapatılan kart bu oturumda geri gelmemeli")
print("starter offer ok")
