-- Gifts > Playtime Rewards: pet ödül kartlarında genel pati simgesi değil PETİN RESMİ çizilir (sahibi 'bunlar yerine pet resmi olsun' dedi); kas/Win/iksir kartları eskisi gibi
local S = require("../cstubs")
local Config = require("./Config")

-- Satın alma penceresi taklidi: PromptProductPurchase'a verilen ürün kimliklerini toplar (GiftsPanel MarketplaceService'i modül yüklenirken alır, o yüzden require'dan ÖNCE)
local prompted = {}
local market = {
	PromptProductPurchase = function(_, _, productId)
		table.insert(prompted, productId)
	end,
}
local realGetService = S.game.GetService
S.game.GetService = function(self, name)
	if name == "MarketplaceService" then
		return market
	end
	return realGetService(self, name)
end
local GiftsPanel = require("./GiftsPanel")
local GiftState = require("./GiftState")

local workspaceService = S.game:GetService("Workspace")
rawset(workspaceService, "GetServerTimeNow", function()
	return 1000
end)
S.localPlayer:SetAttribute("SessionStart", 1000)
local root = S.newInstance("Frame")
local ok, err = pcall(GiftsPanel.init, root, function() end, function() end)
assert(ok, "GiftsPanel.init hata verdi: " .. tostring(err))

-- Ağacı gez: ad -> kaç tane
local function countNamed(instance, name)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			total += 1
		end
		total += countNamed(child, name)
	end
	return total
end
local petRewards = 0
for _, reward in Config.GiftRewards do
	if reward.kind == "pet" then
		petRewards += 1
	end
end
assert(petRewards >= 2, "Config.GiftRewards'ta pet ödülleri olmalı (dragon, phoenix)")
assert(countNamed(root, "RewardPet") == petRewards, "her pet ödül kartında petin kendi resmi olmalı: " .. countNamed(root, "RewardPet") .. "/" .. petRewards)
print("GiftsPanel pet images ok")

-- ---- Kart bilgi balonu: potionun ne işe yaradığı, petin kaç çarpan verdiği (sahibi istedi)
local function findFirst(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = findFirst(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function textsIn(instance, found)
	local text = rawget(instance, "Text")
	if type(text) == "string" and text ~= "" then
		found[text] = true
	end
	for _, child in rawget(instance, "_children") do
		textsIn(child, found)
	end
	return found
end
local tipFrame = findFirst(root, "RewardTip")
assert(tipFrame and rawget(tipFrame, "Visible") == false, "bilgi balonu kurulmuş ve başta gizli olmalı")
local Format = require("./Format")
local Catalog = require("./Catalog")
local sawPotion, sawPet = false, false
for index, reward in Config.GiftRewards do
	local title, body = GiftsPanel.rewardInfo(reward)
	assert(title ~= "" and body ~= "", "her ödülün bilgisi olmalı: " .. index)
	local info = findFirst(root, "Info_" .. index)
	assert(info, "her karta bilgi düğmesi konmalı: " .. index)
	rawget(info, "_handlers").MouseButton1Click() -- dokununca (ya da üzerine gelince) balon açılır
	assert(rawget(tipFrame, "Visible") == true, "karta dokununca balon açılmalı: " .. index)
	local shown = textsIn(tipFrame, {})
	assert(shown[title] and shown[body], "balonda başlık ve açıklama yazmalı: " .. index)
	if Catalog.PotionByKind[reward.kind] then
		sawPotion = true
		assert(string.find(body, Catalog.PotionByKind[reward.kind].description, 1, true) and string.find(body, "USE", 1, true), "iksirin ne işe yaradığı ve USE yazmalı: " .. reward.kind)
	elseif reward.kind == "pet" then
		sawPet = true
		assert(string.find(body, Format.petBonus(Catalog.PetById[reward.pet].mult) .. " Pet Multiplier", 1, true), "petin verdiği çarpan yazmalı: " .. reward.pet)
	end
	rawget(tipFrame, "_handlers").MouseButton1Click() -- balona dokunmak kapatır
	assert(rawget(tipFrame, "Visible") == false, "balona dokununca kapanmalı")
end
assert(sawPotion and sawPet, "Gifts'te hem iksir hem pet ödülü olmalı")
print("GiftsPanel reward tips ok")

-- ---- Robux 'Unlock Next / Unlock All' düğmeleri (sahibi 'bunları eklemeyi unutmuşuz' dedi): gerçek Developer Product satın alma penceresini açar; açılacak ödül yoksa Robux boşa gitmesin diye pencere AÇILMAZ
local function descendants(instance, list)
	for _, child in rawget(instance, "_children") do
		table.insert(list, child)
		descendants(child, list)
	end
	return list
end
local function findButton(frame, title)
	for _, instance in descendants(frame, {}) do
		if rawget(instance, "ClassName") == "TextButton" then
			for _, child in rawget(instance, "_children") do
				if rawget(child, "Text") == title then
					return instance
				end
			end
		end
	end
	error("düğme yok: " .. title)
end
local function click(frame, title)
	local handlers = rawget(findButton(frame, title), "_handlers")
	assert(handlers and handlers.MouseButton1Click, title .. ": tıklama işleyicisi yok")
	handlers.MouseButton1Click()
end
local function newPanel(toasts)
	local frame = S.newInstance("Frame")
	GiftsPanel.init(frame, function(_, message)
		table.insert(toasts, message)
	end, function() end)
	return frame
end

local realNext, realAll = Config.GiftUnlockNextProductId, Config.GiftUnlockAllProductId
assert(type(realNext) == "number" and type(realAll) == "number" and realNext ~= realAll or realNext == 0, "ürün kimlikleri sayı olmalı ve farklı olmalı")
-- 1) Kimlik 0 (ürün henüz açılmamışsa): fiyatlı 'coming soon', satın alma penceresi yok
Config.GiftUnlockNextProductId = 0
Config.GiftUnlockAllProductId = 0
local toasts = {}
local panel = newPanel(toasts)
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(#prompted == 0, "kimlik yokken satın alma penceresi açılmamalı")
assert(string.find(toasts[1], "coming soon", 1, true) and string.find(toasts[1], tostring(Config.GiftUnlockNextRobux), 1, true), "fiyatlı coming soon: " .. tostring(toasts[1]))
assert(string.find(toasts[2], tostring(Config.GiftUnlockAllRobux), 1, true), "All için de fiyatlı mesaj: " .. tostring(toasts[2]))

-- 2) Kimlik varken (hepsi kilitli): doğru ürün sorulur
Config.GiftUnlockNextProductId = 111
Config.GiftUnlockAllProductId = 222
toasts = {}
panel = newPanel(toasts)
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(prompted[1] == 111 and prompted[2] == 222 and #prompted == 2, "Next 111, All 222 sorulmalı")

-- 3) Hepsi alınmışsa satın alma açılmaz
for index in Config.GiftRewards do
	GiftState.claimed[index] = true
end
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(#prompted == 2, "hepsi alınmışken satın alma açılmamalı")
assert(#toasts == 2 and string.find(toasts[1], "already claimed", 1, true), "bilgi mesajı: " .. tostring(toasts[1]))

-- 4) Hepsi hazır (süresi dolmuş) ama alınmamış: satın alınacak kilitli ödül yok, ikisi de önce ücretsiz almasını söyler
for index in Config.GiftRewards do
	GiftState.claimed[index] = nil
end
rawset(workspaceService, "GetServerTimeNow", function()
	return 1000 + 5000
end)
toasts = {}
panel = newPanel(toasts)
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(#prompted == 2, "kilitli ödül yokken satın alma açılmamalı")
assert(string.find(toasts[1], "Nothing is locked", 1, true) and string.find(toasts[2], "Nothing is locked", 1, true), "hazır ödülleri ücretsiz almaya yönlendirmeli: " .. tostring(toasts[1]))

-- 5) Bir kısmı kilitli: ikisi de satın alma açar
rawset(workspaceService, "GetServerTimeNow", function()
	return 1000 + 300 -- 1-3. ödül hazır, 4-10. kilitli
end)
panel = newPanel(toasts)
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(prompted[3] == 111 and prompted[4] == 222 and #prompted == 4, "kilitli ödül varken ikisi de satın alma açmalı")
print("GiftsPanel unlock buttons ok")

-- 6) Tur baştan başlayınca sunucu ClaimedGifts'i boşaltır: istemcideki 'Claimed' işaretleri de silinmeli (tablo YERİNDE yenilenir, panel aynı tabloyu tutar)
S.localPlayer:SetAttribute("ClaimedGifts", "1,2,4")
assert(GiftState.claimed[1] and GiftState.claimed[2] and GiftState.claimed[4] and not GiftState.claimed[3], "sunucunun verdiği ödüller 'Claimed' görünmeli")
S.localPlayer:SetAttribute("ClaimedGifts", "")
assert(next(GiftState.claimed) == nil, "yeni turda eski 'Claimed'lar silinmeli")
print("GiftState round restart ok")

-- 7) Robux 'Unlock' ile AÇILAN ödüller ('UnlockedGifts'): süresi dolmasa da alınabilir ('Claim'), hazır sayılır; Unlock butonları açılmışları 'kilitli' saymaz (açılacak bir şey yoksa Robux harcatmaz)
rawset(workspaceService, "GetServerTimeNow", function()
	return 1000 -- oturum başı: hiçbir ödülün süresi dolmadı
end)
assert(#GiftState.ready() == 0, "süre dolmadan hazır ödül yok")
S.localPlayer:SetAttribute("UnlockedGifts", "4,5")
assert(GiftState.unlocked[4] and GiftState.unlocked[5] and not GiftState.unlocked[6], "açılan ödüller istemcide görünmeli")
local readyList = GiftState.ready()
assert(#readyList == 2 and readyList[1] == 4 and readyList[2] == 5, "açılan ödüller 'hazır' sayılmalı")
assert(GiftState.nextRemaining() == 0, "açılmış ödül varken sıradaki süre 0 (FREE REWARD READY)")
local allIndices = {}
for index in Config.GiftRewards do
	table.insert(allIndices, index)
end
S.localPlayer:SetAttribute("UnlockedGifts", table.concat(allIndices, ","))
local beforePrompts = #prompted
toasts = {}
panel = newPanel(toasts)
click(panel, "Unlock Next")
click(panel, "Unlock All")
assert(#prompted == beforePrompts, "hepsi açılmışken satın alma açılmamalı (Robux boşa gitmesin)")
assert(string.find(toasts[1], "Nothing is locked", 1, true), "açılmışları kilitli saymamalı: " .. tostring(toasts[1]))
S.localPlayer:SetAttribute("UnlockedGifts", "")
assert(next(GiftState.unlocked) == nil, "yeni turda açılanlar silinmeli")
print("GiftState unlocked ok")
