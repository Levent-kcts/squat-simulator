-- CALM UI (hareketi azalt): UIStyle.calm(), press/pop/countTo/fadeScaleIn/fadeScaleOut anında biter, loopTween nabzı oynatmaz ve CalmUI canlı değişince uygular,
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

-- Normal modda pop/fadeScaleIn/countTo animasyonlu başlar
local root = S.newInstance("Frame")
local card = S.newInstance("Frame")
card.Parent = root
UIStyle.pop(card)
assert(child(card, "PopScale").Scale > 1, "normal pop 1'den başlamalı")

local modal = S.newInstance("Frame")
modal.Parent = root
UIStyle.fadeScaleIn(modal)
assert(child(modal, "ModalScale").Scale < 1, "normal fadeScaleIn küçükten başlamalı")

local label = S.newInstance("TextLabel")
label.Parent = root
UIStyle.countTo(label, 0, 500)
assert(label.Text == "0", "normal countTo 'from'dan başlamalı")

-- Calm açık
player:SetAttribute("CalmUI", true)
assert(UIStyle.calm() == true, "calm açık olmalı")
assert(PlayerSettings.get("CalmUI") == true, "PlayerSettings.get CalmUI açık olmalı")

local card2 = S.newInstance("Frame")
card2.Parent = root
UIStyle.pop(card2)
assert(child(card2, "PopScale").Scale == 1, "calm pop anında 1 olmalı")

local modal2 = S.newInstance("Frame")
modal2.Parent = root
UIStyle.fadeScaleIn(modal2)
assert(modal2.Visible == true, "calm fadeScaleIn pencereyi göstermeli")
assert(child(modal2, "ModalScale").Scale == 1, "calm fadeScaleIn ölçek 1 olmalı")

local label2 = S.newInstance("TextLabel")
label2.Parent = root
UIStyle.countTo(label2, 0, 500)
assert(label2.Text == "500", "calm countTo anında son değer olmalı")

local closed = false
UIStyle.fadeScaleOut(modal2, function()
	closed = true
end)
assert(closed and modal2.Visible == false, "calm fadeScaleOut anında kapanmalı")

-- press: basınca küçülme yok
local button = S.newInstance("TextButton")
button.Parent = root
UIStyle.press(button)
local handlers = rawget(button, "_handlers")
if handlers and handlers.MouseButton1Down then
	handlers.MouseButton1Down()
end
local pressScale = child(button, "PressScale")
assert(pressScale == nil or pressScale.Scale ~= 0.96, "calm press ölçeği değiştirmemeli")

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
