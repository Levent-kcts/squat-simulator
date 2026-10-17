-- BAŞLANGIÇ PAKETİ TEKLİF KARTI (client/StarterOffer): RightHud sütununa yerleşir; veri yüklü, paket alınmamış, fırsat süresi ('StarterOfferUntil') bitmemiş ve kısıtsız hesapta görünür
-- (eğitim sırasında da); altında geri sayım yazar; X bu oturum için gizler; paket alınınca ya da süre bitince kalkar.
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

-- Süre yazısı
assert(StarterOffer.formatTime(3600) == "1:00:00", StarterOffer.formatTime(3600))
assert(StarterOffer.formatTime(3599) == "59:59", StarterOffer.formatTime(3599))
assert(StarterOffer.formatTime(65) == "01:05", StarterOffer.formatTime(65))
assert(StarterOffer.formatTime(-3) == "00:00", "eksi süre 00:00 olmalı")

local now = S.game:GetService("Workspace"):GetServerTimeNow()
player:SetAttribute("DataLoaded", true)
player:SetAttribute("StarterPackOwned", nil)
player:SetAttribute("TutorialDone", false)
player:SetAttribute("PaidRandomRestricted", false)
player:SetAttribute("StarterOfferUntil", now + 1800)
local ok, refresh = pcall(StarterOffer.init, root, function() end)
assert(ok, "StarterOffer.init hata verdi: " .. tostring(refresh))
local offer = findNamed(root, "StarterOffer")
assert(offer and rawget(offer, "Parent") == column, "kart RightHud sütununda olmalı")
assert(rawget(offer, "Visible") == true, "yeni oyuncuda (eğitim sürerken de) fırsat süresince görünmeli")
local timer = findNamed(offer, "OfferTimer")
assert(timer and (string.find(rawget(timer, "Text"), "30:00", 1, true) or string.find(rawget(timer, "Text"), "29:5", 1, true)), "geri sayım kalan süreyi yazmalı: " .. tostring(timer and rawget(timer, "Text")))

player:SetAttribute("StarterOfferUntil", now - 1)
assert(rawget(offer, "Visible") == false, "fırsat süresi bitince kalkmalı")
player:SetAttribute("StarterOfferUntil", 0)
assert(rawget(offer, "Visible") == false, "fırsat bitmiş (0) oyuncuda görünmemeli")
player:SetAttribute("StarterOfferUntil", now + 600)
assert(rawget(offer, "Visible") == true, "fırsat yeniden başlayınca (DEV) görünmeli")

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
refresh()
assert(rawget(offer, "Visible") == false, "kapatılan kart bu oturumda geri gelmemeli")
print("starter offer ok")
