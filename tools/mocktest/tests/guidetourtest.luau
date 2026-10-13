-- REHBER TURU (client/GuideTour): hızlı ok turu, kartlar (büyük ok + balon), görev bağı (Quests'e 'claim' oku); 'Got it!'/'Next' görüldü sayar (sunucuya GuideSeen),
-- Skip/Settings anahtarı kapatır, rebirth sonrası çıkmaz, eğitim tıklamaları bitmeden ikinci görev kartı açılmaz.
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
local introSteps = 0
for _, step in Config.GuideTour do
	assert(type(step.id) == "string" and not ids[step.id], "rehber adım kimlikleri benzersiz olmalı: " .. tostring(step.id))
	ids[step.id] = true
	assert(type(step.title) == "string" and type(step.text) == "string" and #step.text < 220, "adımın başlığı ve kısa metni olmalı: " .. step.id)
	assert(step.when == "start" or step.when == "clicks" or step.when == "winsFirst" or step.when == "pet" or step.when == "skin" or step.when == "nearMax" or string.match(step.when, "^level:%d+$"), "geçersiz koşul: " .. step.id .. " " .. tostring(step.when))
	if step.intro then
		introSteps += 1
	end
end
assert(#Config.GuideTour >= 10, "rehber turu en az 10 adım olmalı")
assert(introSteps == 1 and ids.intro, "tam bir 'intro' (hızlı ok turu) adımı olmalı")
assert(#Config.GuideIntro >= 6, "hızlı turda en az 6 durak olmalı")
for _, stop in Config.GuideIntro do
	assert(type(stop.target) == "string" and type(stop.text) == "string" and #stop.text <= 60, "durağın hedef adı ve kısa balon yazısı olmalı: " .. tostring(stop.target))
end
assert(Config.GuideIntro[#Config.GuideIntro].target == "QuestsButton", "tur Quests ile bitmeli (görevlerle bağ)")
assert(Config.GuideIntroSeconds > 0 and Config.GuideIntroSeconds <= 4, "hızlı tur durak başına en çok 4 sn olmalı")
local hasSetting = false
for _, setting in Config.Settings do
	if setting.key == "GuideOn" then
		hasSetting = true
	end
end
assert(hasSetting, "Settings'te 'GuideOn' (Guide aç/kapat) anahtarı olmalı")

-- Sahte PlayerGui: turun gezdiği düğmeler (konumlar 600x400'lük sahte ekrana göre)
local playerGui = S.newInstance("PlayerGui")
playerGui.Name = "PlayerGui"
rawget(S.localPlayer, "_children")["PlayerGui"] = playerGui
local placements = {
	WinsChip = { 10, 100, 60, 60 }, -- sol kenar: ok sağında
	QuestsButton = { 540, 10, 50, 50 }, -- sağ üst: ok altında
	AutoClickButton = { 260, 350, 80, 40 }, -- alt orta: ok üstünde
}
local fallback = { 100, 150, 60, 60 }
local function addButton(name)
	if rawget(playerGui, "_children")[name] then
		return
	end
	local place = placements[name] or fallback
	local button = S.newInstance("TextButton")
	button.Name = name
	rawset(button, "AbsolutePosition", { X = place[1], Y = place[2] })
	rawset(button, "AbsoluteSize", { X = place[3], Y = place[4] })
	button.Parent = playerGui
end
for _, stop in Config.GuideIntro do
	addButton(stop.target)
end
for _, step in Config.GuideTour do
	if step.target then
		addButton(step.target)
	end
end
local function button(name)
	return rawget(playerGui, "_children")[name]
end

S.localPlayer:SetAttribute("DataLoaded", true)
S.localPlayer:SetAttribute("GuideSeen", "") -- sunucu yükleyince ''
local root = S.newInstance("Frame")
local toasts = {}
local GuideTour = require("./GuideTour")
local card = GuideTour.init(root, function(_, message)
	table.insert(toasts, message)
end)
GuideTour._timing.gap = 0 -- testte bekleme yok
local function visible()
	return rawget(card, "Visible") == true
end
local function barVisible()
	return rawget(GuideTour._introBar, "Visible") == true
end
local function find(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = find(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function click(instance)
	rawget(instance, "_handlers").MouseButton1Click()
end
local function hasText(instance, text)
	if rawget(instance, "Text") == text then
		return true
	end
	for _, child in rawget(instance, "_children") do
		if hasText(child, text) then
			return true
		end
	end
	return false
end
local function cardHas(text)
	return hasText(card, text)
end
local function calloutText()
	local callout = GuideTour._state().callout
	return callout and rawget(find(callout.bubble, "Text"), "Text")
end

-- 1) İlk adım: hoş geldin (düğme 'Show me!')
GuideTour._tick()
assert(visible(), "yeni oyuncuya ilk kart (hoş geldin) gösterilmeli")
assert(cardHas(Config.GuideTour[1].title) and cardHas(Config.GuideTour[1].text), "ilk kartın başlığı ve metni gösterilmeli")
assert(cardHas("Show me!"), "hoş geldin kartının düğmesi turu başlatan 'Show me!' olmalı")

-- 2) 'Show me!': kart kapanır, sunucuya GuideSeen gider ve HIZLI OK TURU başlar
S.lastInvoke = nil
click(find(card, "GotIt"))
assert(not visible(), "'Show me!' kartı kapatmalı")
assert(S.lastInvoke and S.lastInvoke[1] == "GuideSeen" and S.lastInvoke[2] == "welcome", "görülen adım sunucuya bildirilmeli: " .. tostring(S.lastInvoke and S.lastInvoke[2]))
GuideTour._tick()
assert(barVisible() and not visible(), "hoş geldin'den sonra hızlı tur çubuğu açılmalı (kart değil)")
local state = GuideTour._state()
assert(state.intro and state.callout, "tur ilk durağı ok ve balonla işaretlemeli")
local stops = state.intro.stops
assert(#stops == #Config.GuideIntro, "tüm hedefler varken bütün duraklar gezilmeli")
assert(calloutText() == stops[1].text and state.callout.dir == "right", "sol kenardaki Wins için ok sağda (sola bakan) olmalı: " .. tostring(state.callout.dir))
assert(hasText(GuideTour._introBar, `Quick tour  1/{#stops}`), "çubuk 'Quick tour 1/N' yazmalı")

-- 3) 'Next' her basışta sonraki durağı işaretler; yön ekrandaki konuma göre seçilir
local seenDirs = {}
for index = 2, #stops do
	click(find(GuideTour._introBar, "IntroNext"))
	local now = GuideTour._state()
	assert(now.intro and now.intro.index == index and calloutText() == stops[index].text, "Next sonraki durağı göstermeli: " .. index)
	seenDirs[stops[index].target] = now.callout.dir
end
assert(seenDirs.AutoClickButton == "above", "alttaki Auto Click için ok üstte (aşağı bakan) olmalı: " .. tostring(seenDirs.AutoClickButton))
assert(seenDirs.QuestsButton == "below", "sağ üstteki Quests için ok altta (yukarı bakan) olmalı: " .. tostring(seenDirs.QuestsButton))
assert(find(GuideTour._state().callout.bubble, "Text") and GuideTour._state().callout.container, "ok kapsayıcısı ve balon kurulmuş olmalı")

-- 4) Son durakta Next turu bitirir: 'intro' sunucuya bildirilir, ok kalkar, kısa yönlendirme bildirimi gelir
S.lastInvoke = nil
click(find(GuideTour._introBar, "IntroNext"))
assert(not barVisible() and GuideTour._state().intro == nil and GuideTour._state().callout == nil, "tur bitince çubuk ve ok kalkmalı")
assert(S.lastInvoke and S.lastInvoke[1] == "GuideSeen" and S.lastInvoke[2] == "intro", "hızlı tur görüldü diye bildirilmeli: " .. tostring(S.lastInvoke and S.lastInvoke[2]))
assert(toasts[#toasts] and string.find(toasts[#toasts], "Quests", 1, true), "tur bitince Quests'e yönlendiren bildirim gelmeli")
S.localPlayer:SetAttribute("GuideSeen", "welcome,intro") -- sunucu yayımlar

-- 5) Eğitim görevi (30 tık) bitmeden ikinci bir görev kartı açılmaz (iki görev birbirine bağlı)
stats[Config.StatLevel].Value = 6
GuideTour._tick()
assert(not visible(), "30 tıklama bitmeden 'level 6' kartı çıkmamalı")
stats[Config.StatLevel].Value = 1
S.localPlayer:SetAttribute("TutorialClicks", Config.Tutorial.ClickGoal)
GuideTour._tick()
assert(visible() and cardHas(Config.GuideTour[3].title), "30 tıktan sonra duvar kartı gösterilmeli")
click(find(card, "GotIt"))

-- 6) GÖREV BAĞI: görev bitince Quests düğmesine 'claim' oku, altında sıradaki görev
local first, second = Config.StarterQuests[1], Config.StarterQuests[2]
S.localPlayer:SetAttribute("StarterState", `{first.id},{first.goal},1,0;{second.id},0,0,0`)
GuideTour._tick()
local claimState = GuideTour._state()
assert(claimState.current and claimState.current.claim and claimState.callout, "biten görev için Quests'e ok çıkmalı")
assert(calloutText() == "Quest complete! Tap to claim", "ok balonu 'görev tamamlandı' demeli: " .. tostring(calloutText()))
assert(hasText(claimState.callout.bubble, "Next: " .. second.text), "balon sıradaki görevi söylemeli")
assert(claimState.callout.target == button("QuestsButton"), "ok Quests düğmesini göstermeli")
-- Konum düzeltmesi: ilk yerleştirme hedefin AbsolutePosition'ına göredir, sonrakiler kapsayıcının GERÇEK konumunu ölçüp farkı kapatır (üst çubuk payı yüzünden halka kaçmasın)
local callout = claimState.callout
local pad = callout.pad
local wantX = 540 - pad -- QuestsButton'un sol kenarı (600x400'lük sahte ekranda) - pay
assert(callout.lastX == wantX, "ilk yerleştirme hedefin konumu olmalı: " .. tostring(callout.lastX))
GuideTour._place()
assert(callout.lastX == wantX + (wantX - 600), "ikinci yerleştirme kapsayıcının ölçülen konumuna göre düzeltilmeli (sahte ölçüm 600): " .. tostring(callout.lastX))
assert(rawget(callout.container, "Visible") == true, "ölçümden sonra ok görünür olmalı")
click(button("QuestsButton")) -- oyuncu Quests'e basar
assert(GuideTour._state().callout == nil and GuideTour._state().current == nil, "Quests'e basınca ok kalkmalı")
GuideTour._tick()
assert(GuideTour._state().callout == nil, "aynı görev için ok tekrar çıkmamalı")
-- Yeni görev bitince yeniden; alınınca kendiliğinden kalkar
S.localPlayer:SetAttribute("StarterState", `{first.id},{first.goal},1,1;{second.id},{second.goal},1,0`)
GuideTour._tick()
assert(GuideTour._state().current and GuideTour._state().current.questId == second.id, "yeni biten görev için ok yeniden çıkmalı")
S.localPlayer:SetAttribute("StarterState", `{first.id},{first.goal},1,1;{second.id},{second.goal},1,1`)
assert(GuideTour._state().current == nil and GuideTour._state().callout == nil, "görev alınınca ok kalkmalı")

-- 7) Hedefli kart: büyük ok + kısa balon, hedefe basınca kart kapanır
stats[Config.StatWins].Value = 8
GuideTour._tick()
assert(visible() and cardHas(Config.GuideTour[4].title), "ilk Win kartı gösterilmeli")
assert(calloutText() == Config.GuideTour[4].pointer and GuideTour._state().callout.target == button("WinsChip"), "kart hedef düğmeyi balonlu okla işaretlemeli")
S.lastInvoke = nil
click(button("WinsChip"))
assert(not visible() and GuideTour._state().callout == nil, "işaretlenen düğmeye basmak kartı kapatmalı")
assert(S.lastInvoke and S.lastInvoke[2] == "wins", "hedefe basmak da görüldü sayılmalı")

-- 8) Guide anahtarı kapanınca açık kart/ok gider ve yenisi çıkmaz; yeniden açılınca devam eder
S.localPlayer:SetAttribute("OwnedPets", "cat")
GuideTour._tick()
assert(visible() and GuideTour._state().callout, "pet kartı ve oku açık olmalı")
S.localPlayer:SetAttribute("GuideOn", false)
assert(not visible() and GuideTour._state().callout == nil, "Guide kapanınca kart ve ok kaybolmalı")
GuideTour._tick()
assert(not visible(), "Guide kapalıyken kart çıkmamalı")
S.localPlayer:SetAttribute("GuideOn", true)
GuideTour._tick()
assert(visible(), "Guide yeniden açılınca görülmemiş adım gelir")
click(find(card, "SkipGuide"))
assert(not visible() and S.localPlayer:GetAttribute("GuideOn") == false, "'Skip guide' rehberi kapatmalı")
assert(toasts[#toasts] and string.find(toasts[#toasts], "Settings", 1, true), "kapatınca Settings'ten açılabileceği söylenmeli")

-- 9) Hızlı turda 'Skip' sadece turu bitirir (rehber açık kalır); hedefe basmak sonraki durağa geçirir
S.localPlayer:SetAttribute("GuideOn", true)
S.localPlayer:SetAttribute("GuideSeen", "")
S.localPlayer:SetAttribute("StarterState", "")
local root2 = S.newInstance("Frame")
local card2 = GuideTour.init(root2, function(_, message)
	table.insert(toasts, message)
end)
GuideTour._timing.gap = 0
GuideTour._tick() -- hoş geldin
click(find(card2, "GotIt"))
GuideTour._tick() -- hızlı tur
assert(rawget(GuideTour._introBar, "Visible") == true and GuideTour._state().intro, "ikinci örnekte de tur başlamalı")
local firstStop = GuideTour._state().intro.stops[1].target
click(button(firstStop)) -- hedefe basmak sonraki durağa geçirir
assert(GuideTour._state().intro.index == 2, "işaretlenen düğmeye basmak turu ilerletmeli")
S.lastInvoke = nil
click(find(GuideTour._introBar, "IntroSkip"))
assert(GuideTour._state().intro == nil and GuideTour._state().callout == nil and rawget(GuideTour._introBar, "Visible") ~= true, "Skip turu bitirmeli")
assert(S.localPlayer:GetAttribute("GuideOn") ~= false, "tur 'Skip'i rehberin tamamını kapatmamalı")
assert(S.lastInvoke and S.lastInvoke[2] == "intro", "atlanan tur da görüldü sayılmalı")

-- 10) İlk rebirth yapıldıysa tur hiç çıkmaz
S.localPlayer:SetAttribute("GuideSeen", "")
stats[Config.StatRebirths].Value = 1
GuideTour._tick()
assert(rawget(card2, "Visible") ~= true and GuideTour._state().current == nil, "rebirth sonrası rehber turu çıkmamalı")
print("guide tour ok")
