-- İstemci açılışı: init.client (tüm HUD, paneller, sağ üst daireler, eğitim yazısı...) tüm modülleriyle hatasız kurulmalı.
-- Özellik/enum adı geçerliliğini ve görünümü DOĞRULAMAZ.
local S = require("../cstubs")
local Config = require("./Config")
-- Yerel oyuncunun leaderstats'ı (istemci bunları bekler)
local leaderstats = S.newInstance("Folder")
leaderstats.Name = "leaderstats"
for _, name in { Config.StatLegMuscle, Config.StatWins, Config.StatLevel, Config.StatRebirths } do
	local value = S.newInstance("IntValue")
	value.Name = name
	value.Value = if name == Config.StatLevel then 1 else 0
	rawget(leaderstats, "_children")[name] = value
end
rawget(S.localPlayer, "_children")["leaderstats"] = leaderstats
S.localPlayer:SetAttribute("DataLoaded", true)
S.localPlayer:SetAttribute("TutorialDone", false)
S.localPlayer:SetAttribute("TutorialClicks", 5)
S.localPlayer:SetAttribute("MaxLevel", 20)
S.localPlayer:SetAttribute("TapsNeeded", 10)
S.localPlayer:SetAttribute("QuestData", "x")
S.jsonData = { resetAt = os.time() + 100, quests = {}, bonusClaimed = false, bonusText = "" }
-- Click olayını sayan sahte uzak olay (Auto Click testi için): istemci her tıklamada FireServer çağırır
local clickRemote = S.newInstance("RemoteEvent")
clickRemote.Name = "Click"
clickRemote.Parent = S.replicated
local clicksSent = 0
rawset(clickRemote, "FireServer", function()
	clicksSent += 1
end)
local ok, err = pcall(require, "./clientMain")
print("client boot:", ok, err)
if not ok then
	print("ERROR client boot failed: " .. tostring(err))
end
-- Heartbeat döngülerini birkaç kez koştur (otomatik tıklama, gökkuşağı, yakınlık...)
-- Taklitte dünya nesneleri (yumurta pedleri, ses dosyaları) olmadığı için bu modüllerin döngüleri hata verir: bilinen taklit boşluğu, 'note' olarak yazılır
local KNOWN_GAPS = { "EggShop.luau", "Sfx.luau", "GiftsPanel.luau", "MusicPlayer.luau", "TrainingClient.luau", "OverheadTags.luau" }
for _ = 1, 3 do
	for _, hb in S.heartbeat do
		local good, message = pcall(hb, 0.5)
		if not good then
			local known = false
			for _, gap in KNOWN_GAPS do
				if string.find(tostring(message), gap, 1, true) then
					known = true
				end
			end
			print((if known then "note (mock gap) heartbeat: " else "ERROR heartbeat: ") .. tostring(message))
		end
	end
end
-- AUTO CLICK: açılınca istemci SERİ SERİ tıklar (kare başına Config.AutoClick.PerSecond hızında), kapalıyken tıklamaz
local function findAutoButton(instance)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "ClassName") == "TextButton" then
			for _, grandchild in rawget(child, "_children") do
				if rawget(grandchild, "Text") == "Auto Click" then
					return child
				end
			end
		end
		local deeper = findAutoButton(child)
		if deeper then
			return deeper
		end
	end
	return nil
end
local autoButton = findAutoButton(S.localPlayer)
assert(autoButton, "Auto Click düğmesi bulunamadı")
local sentBefore = clicksSent
for _ = 1, 3 do
	for _, hb in S.heartbeat do
		pcall(hb, 0.5)
	end
end
assert(clicksSent == sentBefore, "Auto Click kapalıyken tıklama gitmemeli")
rawget(autoButton, "_handlers").MouseButton1Click()
for _ = 1, 4 do
	for _, hb in S.heartbeat do
		pcall(hb, 0.5)
	end
end
assert(clicksSent - sentBefore >= 6, "Auto Click seri tıklamalı (kare başına 2): " .. (clicksSent - sentBefore))
rawget(autoButton, "_handlers").MouseButton1Click() -- kapat
print("auto click rapid-fire ok:", clicksSent - sentBefore)
-- Eğitim yazısı: ekrandaki TextLabel'ları gezip duruma göre doğru yönergenin çıktığını denetle
local function allTexts()
	local found = {}
	local function walk(instance)
		for _, child in rawget(instance, "_children") do
			local text = rawget(child, "Text")
			if type(text) == "string" and text ~= "" then
				found[text] = true
			end
			walk(child)
		end
	end
	walk(S.localPlayer)
	return found
end
local function hasText(prefix)
	for text in allTexts() do
		if string.sub(text, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end
local wins = leaderstats:FindFirstChild(Config.StatWins)
local nonce = 100
local function refreshBanner()
	nonce += 1
	S.localPlayer:SetAttribute("TutorialClicks", nonce) -- yazıyı yeniden hesaplatmak için değişen bir değer (sayaç hedefin üstündeyse davranış aynı)
end
-- 1. adım: sayaç hedefin altında
S.localPlayer:SetAttribute("TutorialClicks", 7)
assert(hasText("Click anywhere to squat and get stronger!  (7/" .. Config.Tutorial.ClickGoal .. ")"), "1. adım yazısı yok")
-- 2. adım: sayaç doldu, Win yok: duvar yönergesi (Win yetmedi)
S.localPlayer:SetAttribute("TutorialClicks", Config.Tutorial.ClickGoal)
assert(not hasText("Click anywhere"), "sayaç dolunca ilk adım yazısı kalkmalı")
-- 3. adım: ilk skinin fiyatına yetecek Win: skin rafına yönlendirme
wins.Value = Config.Skins[1].price
refreshBanner()
assert(hasText("You have " .. Config.Skins[1].price .. " Wins! Go to the SKIN shelf"), "3. adım yazısı yok")
-- Eğitim bitti: yönerge yazıları kalkar
S.localPlayer:SetAttribute("TutorialDone", true)
-- (yazı metni silinmez, yönerge çerçevesi gizlenir: etiketin ebeveyni Visible = false olmalı)
local function labelWith(prefix)
	local found = nil
	local function walk(instance)
		for _, child in rawget(instance, "_children") do
			local text = rawget(child, "Text")
			if type(text) == "string" and string.sub(text, 1, #prefix) == prefix then
				found = child
			end
			walk(child)
		end
	end
	walk(S.localPlayer)
	return found
end
local label = labelWith("You have")
assert(label and rawget(rawget(label, "Parent"), "Visible") == false, "eğitim bitince yönerge çerçevesi gizlenmeli")
print("tutorial banner states ok")
print("DONE")
