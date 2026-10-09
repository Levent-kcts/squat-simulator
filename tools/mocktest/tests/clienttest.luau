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

-- Alt satır: Auto Click'in solunda 3 hızlı satın alma düğmesi, sağında '+' (Shop); ürün ID'si yokken tıklayınca 'coming soon' bildirimi (hata vermemeli)
for _, text in { "+1K Power", "+10K Power", "+100K Power" } do
	assert(hasText(text), "hızlı satın alma düğmesi yok: " .. text)
end
local quickCount = 0
for _, product in Config.Shop.Products do
	if product.quick then
		quickCount += 1
		assert(product.kind == "moves" and product.amount > 0 and type(product.productId) == "number" and product.productId >= 0, "hızlı ürün 'moves' türünde olmalı ve ID sayı olmalı (0 = henüz yok): " .. product.id)
	end
end
assert(quickCount == 3, "3 hızlı satın alma ürünü olmalı: " .. quickCount)
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
for _, id in { "Quick_power1k", "Quick_power10k", "Quick_power100k", "PlusButton" } do
	local button = findNamed(S.localPlayer, id)
	assert(button, "düğme bulunamadı: " .. id)
	rawget(button, "_handlers").MouseButton1Click() -- coming soon / Shop açma: hata vermemeli
end
print("quick buy buttons ok")

-- Shop > POTIONS: her iksir x süre için bir kart; fiyat Robux simgesiyle yazar, envanterde varsa 'USE xN' yazar (mavi), tükenince fiyat döner
local robuxSign = utf8.char(0xE002)
assert(hasText("POTIONS") and hasText("PACKS"), "Shop bölüm başlıkları yok")
for _, sku in Config.Shop.Potions do
	assert(hasText(robuxSign .. " " .. sku.robux), "iksir fiyatı yok: " .. sku.id)
end
assert(hasText("15 min") and hasText("60 min"), "iksir süreleri yok")
S.localPlayer:SetAttribute("PotionItems", "luck15:2")
assert(hasText("USE  x2"), "envanterdeki iksirde 'USE x2' yazmalı")
S.localPlayer:SetAttribute("PotionItems", "")
assert(not hasText("USE  x"), "envanter boşalınca fiyat dönmeli")
print("shop potions ok")

-- Shop PACKS kartları: Config.Icons'ta görsel varsa (Power kartları LegMuscle) emoji yerine ImageLabel görünür
local function countImages(image)
	local count = 0
	local function walk(instance)
		for _, child in rawget(instance, "_children") do
			if rawget(child, "ClassName") == "ImageLabel" and rawget(child, "Name") == "Icon" and rawget(child, "Image") == image then
				count += 1
			end
			walk(child)
		end
	end
	walk(S.localPlayer)
	return count
end
assert(Config.Icons.LegMuscle ~= "" and countImages(Config.Icons.LegMuscle) >= 1, "Power kartlarında bacak görseli (ImageLabel) olmalı")
for _, key in { "Vip", "PetSpace", "WinPack", "WinPackBig" } do
	assert(Config.Icons[key] ~= nil, "Config.Icons." .. key .. " tanımlı olmalı (boş olabilir)")
end
-- Pet Space kartında simgenin sağ altında büyük '+' rozeti (yükseltme belli olsun)
local function findNamed(name)
	local found
	local function walk(instance)
		for _, child in rawget(instance, "_children") do
			if rawget(child, "Name") == name then
				found = child
			end
			walk(child)
		end
	end
	walk(S.localPlayer)
	return found
end
local badge = findNamed("UpgradeBadge")
assert(badge, "Pet Space kartında '+' rozeti olmalı")
assert(rawget(findNamed("BadgeText"), "Text") == "+", "rozet yazısı '+' olmalı")
print("shop card images ok")

-- Pencere başlığı simgeleri: sol menü / sağ üst düğmelerle AYNI görsel (Config.Icons) olmalı; çanta sayacı Shop'taki Pet Space görselini kullanır
local headerImages = {}
local function collectHeaderIcons(instance)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == "HeaderIcon" and rawget(child, "ClassName") == "ImageLabel" then
			headerImages[rawget(child, "Image")] = true
		end
		collectHeaderIcons(child)
	end
end
collectHeaderIcons(S.localPlayer)
for _, key in { "Shop", "Rebirth", "Settings", "Pets", "Gifts", "Quests", "Index", "Stats", "Trails", "Auras", "PetSpace" } do
	assert(Config.Icons[key] ~= "" and headerImages[Config.Icons[key]], "pencere başlığında menüdeki görsel yok: " .. key)
end
print("window header icons ok")
-- Tıklayınca çıkan kazanç yazısı (Juice.screenPop): veri yüklüyken kas artınca ekranda bacak görseli ve '+N' yazısı belirir
local Juice = require("./Juice")
S.localPlayer:SetAttribute("DataLoaded", true)
Juice.screenPop("+7", S.Color3.new(1, 1, 1), Config.Icons.LegMuscle)
assert(hasText("+7"), "kas artınca '+7' yazısı çıkmalı (Juice.screenPop)")
local function imageCount(image)
	local count = 0
	local function walk(instance)
		for _, child in rawget(instance, "_children") do
			if rawget(child, "ClassName") == "ImageLabel" and rawget(child, "Image") == image then
				count += 1
			end
			walk(child)
		end
	end
	walk(S.localPlayer)
	return count
end
assert(imageCount(Config.Icons.LegMuscle) >= 1, "kas artınca bacak görseli çıkmalı")
print("click gain pop ok")
print("DONE")
