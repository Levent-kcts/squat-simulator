-- POWER HOUR GÖSTERGESİ (client/PowerHourHud): başlamasına son 90 sn ve aktifken küçük hap görünür, başlarken tek bildirim; arada gizli.
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
local toasts = {}
local root = S.newInstance("Frame")
-- Başlangıçta öznitelik yok: gizli
local ok, err = pcall(PowerHourHud.init, root, function(good, message)
	table.insert(toasts, { good, message })
end)
assert(ok, "PowerHourHud.init hata verdi: " .. tostring(err))
local pill = findNamed(root, "PowerHourPill")
assert(pill, "PowerHourPill kurulmalı")
assert(rawget(pill, "Visible") == false, "öznitelik yokken hap gizli olmalı")

-- Uzak gelecekte başlayacak: gizli
workspace:SetAttribute("PowerHourActive", false)
workspace:SetAttribute("PowerHourAt", os.time() + 900)
assert(rawget(pill, "Visible") == false, "başlamasına 15 dk varken gizli")

-- Son 90 sn: 'in m:ss' sayacı
workspace:SetAttribute("PowerHourAt", os.time() + 45)
assert(rawget(pill, "Visible") == true and findText(pill, "in 0:4"), "son 90 sn içinde geri sayım görünmeli")
assert(#toasts == 0, "başlamadan bildirim çıkmamalı")

-- Aktif: bitişe kalan süre + tek bildirim
local endsAt = os.time() + 200
workspace:SetAttribute("PowerHourAt", endsAt)
workspace:SetAttribute("PowerHourActive", true)
assert(rawget(pill, "Visible") == true and findText(pill, "left") and findText(pill, "x2"), "aktifken 'x2 ... left' görünmeli")
assert(#toasts == 1 and toasts[1][1] == true and string.find(toasts[1][2], "POWER HOUR", 1, true), "başlarken tek bildirim")
workspace:SetAttribute("PowerHourAt", endsAt) -- aynı bitiş zamanı = aynı Power Hour
assert(#toasts == 1, "aynı Power Hour için ikinci bildirim çıkmamalı")

-- Bitti: tekrar gizli
workspace:SetAttribute("PowerHourActive", false)
workspace:SetAttribute("PowerHourAt", os.time() + 1500)
assert(rawget(pill, "Visible") == false, "bitince hap gizlenmeli")
print("power hour hud ok")
