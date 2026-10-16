-- POWER HOUR GÖSTERGESİ (client/PowerHourHud): başlamadan önce hiçbir şey görünmez; başlarken üstte 'PowerHourBanner' duyurusu, sonra sol altta
-- 'PowerHourBadge' (simge + süre + x2); bitince hepsi gizlenir. Üstte kalıcı hap YOK (sahibi 'ekranı çok kaplıyor' dedi).
local S = require("../cstubs")
local PowerHourHud = require("./PowerHourHud")

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

local workspace = S.game:GetService("Workspace")
local root = S.newInstance("Frame")
local ok, err = pcall(PowerHourHud.init, root, function() end)
assert(ok, "PowerHourHud.init hata verdi: " .. tostring(err))
local banner = findNamed(root, "PowerHourBanner")
local badge = findNamed(root, "PowerHourBadge")
assert(banner and badge, "PowerHourBanner ve PowerHourBadge kurulmalı")
assert(findNamed(root, "PowerHourPill") == nil, "eski üst hap kaldırıldı")
assert(findNamed(root, "PowerHourTooltip") and findNamed(root, "BubbleTail"), "rozetin açıklaması konuşma balonu olmalı (tıklayınca bildirim değil)")
assert(rawget(banner, "Visible") == false and rawget(badge, "Visible") == false, "öznitelik yokken hepsi gizli")

-- Yakında başlayacak: yine gizli (geri sayım yok)
workspace:SetAttribute("PowerHourActive", false)
workspace:SetAttribute("PowerHourAt", os.time() + 45)
assert(rawget(banner, "Visible") == false and rawget(badge, "Visible") == false, "başlamadan önce hiçbir şey görünmemeli")

-- Aktif: önce üstte duyuru, rozetin süre yazısı ve x2 hazır
local endsAt = os.time() + 3600
workspace:SetAttribute("PowerHourAt", endsAt)
workspace:SetAttribute("PowerHourActive", true)
assert(rawget(banner, "Visible") == true and findText(banner, "POWER HOUR"), "başlarken üstte POWER HOUR duyurusu")
assert(findText(badge, "x2"), "rozette x2 yazmalı")
assert(findText(badge, "59:") or findText(badge, "1:00:00"), "rozetin altında kalan süre yazmalı")

-- Bitti: hepsi gizli
workspace:SetAttribute("PowerHourActive", false)
workspace:SetAttribute("PowerHourAt", os.time() + 20000)
assert(rawget(banner, "Visible") == false and rawget(badge, "Visible") == false, "bitince hepsi gizlenmeli")
print("power hour hud ok")
