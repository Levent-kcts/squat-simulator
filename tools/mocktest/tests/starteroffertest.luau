-- BAŞLANGIÇ PAKETİ TEKLİF KARTI (client/StarterOffer): RightHud sütununun en üstüne yerleşir; veri yüklü, paket alınmamış ve kısıtsız hesapta görünür (eğitim sırasında da);
-- geri sayım ve kapatma düğmesi YOK (sahibi istedi); paket alınınca kalkar.
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
assert(offer and rawget(offer, "Parent") == column and rawget(offer, "LayoutOrder") == 0, "kart RightHud sütununun en üstünde olmalı")
assert(rawget(offer, "Visible") == true, "almamış oyuncuda (eğitim sürerken de) görünmeli")
assert(findNamed(offer, "CloseOffer") == nil and findNamed(offer, "OfferTimer") == nil, "kapatma düğmesi ve geri sayım olmamalı")
local card = findNamed(offer, "OfferCard")
assert(card and rawget(card, "_handlers") and rawget(card, "_handlers").MouseButton1Click, "karta basınca satın alma açılmalı")

player:SetAttribute("PaidRandomRestricted", true)
assert(rawget(offer, "Visible") == false, "kısıtlı hesapta görünmemeli")
player:SetAttribute("PaidRandomRestricted", false)
assert(rawget(offer, "Visible") == true, "kısıt kalkınca yine görünmeli")

player:SetAttribute("StarterPackOwned", true)
assert(rawget(offer, "Visible") == false, "paket alınınca kalkmalı")
print("starter offer ok")
