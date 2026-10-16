-- CALM UI (hareketi azalt): UIStyle.calm() özniteliği okur, loopTween nabzı oynatmaz ve CalmUI canlı değişince uygular,
-- Settings'te CalmUI varsayılan KAPALI (defaultOff), PlayerSettings.get bunu doğru okur.
local S = require("../cstubs")
local UIStyle = require("./UIStyle")
local Config = require("./Config")
local PlayerSettings = require("./PlayerSettings")

local player = S.localPlayer
local function child(parent, name)
	for _, c in rawget(parent, "_children") do
		if rawget(c, "Name") == name then
			return c
		end
	end
	return nil
end

-- Ayar listesi: CalmUI var ve defaultOff
local setting = nil
for _, row in Config.Settings do
	if row.key == "CalmUI" then
		setting = row
	end
end
assert(setting and setting.defaultOff == true and setting.name == "Calm UI", "Config.Settings CalmUI satırı")

-- Varsayılan kapalı
player:SetAttribute("CalmUI", nil)
assert(UIStyle.calm() == false, "calm varsayılan kapalı olmalı")
assert(PlayerSettings.get("CalmUI") == false, "PlayerSettings.get CalmUI varsayılan false olmalı")
assert(PlayerSettings.get("SfxOn") == true, "diğer ayarlar varsayılan açık kalmalı")

-- Calm açık
player:SetAttribute("CalmUI", true)
assert(UIStyle.calm() == true, "calm açık olmalı")
assert(PlayerSettings.get("CalmUI") == true, "PlayerSettings.get CalmUI açık olmalı")

-- loopTween: calm iken oynamaz, ölçek 1'de kalır; calm kapanınca istenen oynar
local plays, cancels = 0, 0
local fake = {
	Play = function()
		plays += 1
	end,
	Cancel = function()
		cancels += 1
	end,
	Destroy = function() end,
}
local pulseTarget = S.newInstance("UIScale")
pulseTarget.Scale = 1.1
local loop = UIStyle.loopTween(fake, pulseTarget, { Scale = 1 })
loop:Play()
assert(plays == 0, "calm iken nabız oynamamalı")
assert(pulseTarget.Scale == 1, "calm iken nabız hedefi 1'e dönmeli")
player:SetAttribute("CalmUI", false)
assert(plays == 1, "calm kapanınca istenen nabız başlamalı")
player:SetAttribute("CalmUI", true)
assert(cancels >= 1, "calm açılınca çalışan nabız durmalı")
loop:Cancel()
player:SetAttribute("CalmUI", false)
assert(plays == 1, "iptal edilen nabız geri başlamamalı")

print("calmtest ok")
