-- REHBER TURU (client/GuideTour): ilk rebirth'e kadar, doğru anda tek kart; 'Got it!' görüldü sayar (sunucuya GuideSeen), Skip/Settings anahtarı kapatır, rebirth sonrası çıkmaz.
local S = require("../cstubs")
local Config = require("./Config")

local function fakeValue(initial)
	local object = { Value = initial }
	function object:GetPropertyChangedSignal()
		return { Connect = function() return S.proxy() end }
	end
	return object
end
local stats = {
	[Config.StatLegMuscle] = fakeValue(0),
	[Config.StatWins] = fakeValue(0),
	[Config.StatLevel] = fakeValue(1),
	[Config.StatRebirths] = fakeValue(0),
}
rawget(S.localPlayer, "_children")["leaderstats"] = {
	WaitForChild = function(_, name)
		return stats[name]
	end,
}
rawget(S.replicated, "_children")["Shop"] = S.remoteFunction

-- Yapılandırma sağlam mı
local ids = {}
for _, step in Config.GuideTour do
	assert(type(step.id) == "string" and not ids[step.id], "rehber adım kimlikleri benzersiz olmalı: " .. tostring(step.id))
	ids[step.id] = true
	assert(type(step.title) == "string" and type(step.text) == "string" and #step.text < 220, "adımın başlığı ve kısa metni olmalı: " .. step.id)
	assert(step.when == "start" or step.when == "clicks" or step.when == "winsFirst" or step.when == "pet" or step.when == "skin" or step.when == "nearMax" or string.match(step.when, "^level:%d+$"), "geçersiz koşul: " .. step.id .. " " .. tostring(step.when))
end
assert(#Config.GuideTour >= 10, "rehber turu en az 10 adım olmalı")
local hasSetting = false
for _, setting in Config.Settings do
	if setting.key == "GuideOn" then
		hasSetting = true
	end
end
assert(hasSetting, "Settings'te 'GuideOn' (Guide aç/kapat) anahtarı olmalı")

S.localPlayer:SetAttribute("DataLoaded", true)
S.localPlayer:SetAttribute("GuideSeen", "") -- sunucu yükleyince ''
local root = S.newInstance("Frame")
local toasts = {}
local GuideTour = require("./GuideTour")
local card = GuideTour.init(root, function(_, message)
	table.insert(toasts, message)
end)
local function visible()
	return rawget(card, "Visible") == true
end
local function buttonNamed(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = buttonNamed(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function click(button)
	rawget(button, "_handlers").MouseButton1Click()
end
local function cardHas(text)
	for _, child in rawget(card, "_children") do
		if rawget(child, "Text") == text then
			return true
		end
	end
	return false
end

-- 1) İlk adım: hoş geldin
GuideTour._tick()
assert(visible(), "yeni oyuncuya ilk kart (hoş geldin) gösterilmeli")
assert(cardHas(Config.GuideTour[1].title) and cardHas(Config.GuideTour[1].text), "ilk kartın başlığı ve metni gösterilmeli")

-- 2) 'Got it!': kart kapanır, sunucuya GuideSeen gider
S.lastInvoke = nil
click(buttonNamed(card, "GotIt"))
assert(not visible(), "'Got it!' kartı kapatmalı")
assert(S.lastInvoke and S.lastInvoke[1] == "GuideSeen" and S.lastInvoke[2] == "welcome", "görülen adım sunucuya bildirilmeli: " .. tostring(S.lastInvoke and S.lastInvoke[2]))

-- 3) İki kart arası bekleme: hemen yeni kart çıkmaz; bekleyince koşulu sağlanmayan adım yoksa kart çıkmaz
GuideTour._tick()
assert(not visible(), "iki kart arasında bekleme olmalı")
local start = os.clock()
while os.clock() - start < 2.7 do
end
GuideTour._tick()
assert(not visible(), "koşulu sağlanmayan adım gösterilmemeli (30 tık yok)")
S.localPlayer:SetAttribute("TutorialClicks", Config.Tutorial.ClickGoal)
GuideTour._tick()
assert(visible() and cardHas(Config.GuideTour[2].title), "30 tıktan sonra duvar kartı gösterilmeli")

-- 4) Guide anahtarı kapanınca açık kart gider ve yeni kart çıkmaz
S.localPlayer:SetAttribute("GuideOn", false)
assert(not visible(), "Guide kapanınca açık kart kaybolmalı")
GuideTour._tick()
assert(not visible(), "Guide kapalıyken kart çıkmamalı")

-- 5) Yeniden açılınca kalan adımlar (görülmeyenler) gelir; 'Skip guide' tamamen kapatır
S.localPlayer:SetAttribute("GuideOn", true)
start = os.clock()
while os.clock() - start < 2.7 do
end
GuideTour._tick()
assert(visible(), "Guide yeniden açılınca görülmemiş adım gelir")
click(buttonNamed(card, "SkipGuide"))
assert(not visible() and S.localPlayer:GetAttribute("GuideOn") == false, "'Skip guide' rehberi kapatmalı")
assert(toasts[#toasts] and string.find(toasts[#toasts], "Settings", 1, true), "kapatınca Settings'ten açılabileceği söylenmeli")

-- 6) İlk rebirth yapıldıysa tur hiç çıkmaz
S.localPlayer:SetAttribute("GuideOn", true)
stats[Config.StatRebirths].Value = 1
start = os.clock()
while os.clock() - start < 2.7 do
end
GuideTour._tick()
assert(not visible(), "rebirth sonrası rehber turu çıkmamalı")
print("guide tour ok")
