local S = require("../cstubs")
local root = S.newInstance("Frame")
local function toast(ok, msg)
	print("  toast:", ok, msg)
end

-- QuestPanel
S.jsonData = {
	resetAt = os.time() + 3600,
	quests = {
		{ id = "walls", text = "Break 12 walls", goal = 12, progress = 12, claimed = false, reward = "+600 Leg Muscle" },
		{ id = "hatch", text = "Hatch 4 eggs", goal = 4, progress = 1, claimed = false, reward = "+12 Wins" },
		{ id = "fuse", text = "Fuse pets 2x", goal = 2, progress = 0, claimed = true, reward = "+3.0K Leg Muscle" },
	},
	bonusClaimed = false,
	bonusText = "2x Leg Muscle for 15 minutes",
}
S.localPlayer:SetAttribute("QuestData", "x")
local QuestPanel = require("./QuestPanel")
print("claimable:", QuestPanel.claimable(S.localPlayer))
local toggleQuests = QuestPanel.init(root, toast)
toggleQuests()
print("QuestPanel ok")

-- WallClient
local wallsHandler
local wallsEvent = S.newInstance("RemoteEvent")
wallsEvent.OnClientEvent = {
	Connect = function(_, f)
		wallsHandler = f
		return S.proxy()
	end,
}
wallsEvent.FireServer = function() end
rawget(S.replicated, "_children")["WallsEvent"] = wallsEvent
local WallClient = require("./WallClient")
WallClient.init(function(frontier)
	print("  frontier", frontier)
end)
for _, hb in S.heartbeat do
	hb(0.6)
end
print("WallClient init ok; heartbeat callbacks:", #S.heartbeat)
wallsHandler("Update", { { 1, 0 } })
wallsHandler("Update", { { 2, 0 }, { 3, 10 } })
S.root.Position = S.Vector3.new(0, 3, -400)
for _, hb in S.heartbeat do
	hb(0.6)
end
S.root.Position = S.Vector3.new(0, 3, 0)
for _, hb in S.heartbeat do
	hb(0.6)
end
print("proximity loop ok")
-- Tüm temaların deseni: oyuncuyu koridor boyunca gezdir (her duvar bir kez yakın olsun)
local Layout = require("./Layout")
local lastZ = Layout.wallZ(100)
local z = 0
while z > lastZ - 100 do
	S.root.Position = S.Vector3.new(0, 3, z)
	for _, hb in S.heartbeat do
		hb(0.6)
	end
	z -= 120
end
print("all-theme patterns ok (z down to", lastZ, ")")
-- Juice: her temanın kırılma parçacığı/lego parçaları/bekleme parçacığı, pcall OLMADAN (hata gizlenmesin)
local Juice = require("./Juice")
local part = S.newInstance("Part")
part.Position = S.Vector3.new(0, 12, -100)
part.Size = S.Vector3.new(32, 23.8, 3)
part.Color = S.Color3.new(0.5, 0.5, 0.5)
S.root.Position = S.Vector3.new(0, 3, -90)
for stage = 1, 20 do
	local theme = Layout.theme(stage)
	Juice.wallBroken(part, theme)
	Juice.addWallAmbient(part, theme)
end
Juice.burst(S.Vector3.new(0, 5, 0), S.Vector3.new(4, 4, 4), S.Color3.new(1, 1, 1), 50)
for _, hb in S.heartbeat do
	hb(0.05)
end
print("Juice all themes ok")
-- Pets menüsü (referans stilinde): boy adları (Small/Normal/Big/Boss), Merge ilerlemesi, Pet Team, tıklamalar (sunucuya giden istekler)
local function textsUnder(instance, found)
	for _, child in rawget(instance, "_children") do
		local text = rawget(child, "Text")
		if type(text) == "string" then
			found[text] = true
		end
		textsUnder(child, found)
	end
	return found
end
-- Torunlarında verilen yazı bulunan ilk TextButton
local function buttonWith(instance, text)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "ClassName") == "TextButton" and textsUnder(child, {})[text] then
			return child
		end
		local deeper = buttonWith(child, text)
		if deeper then
			return deeper
		end
	end
	return nil
end
-- Adı verilen ilk nesne (ayrıntı kutusundaki 'DeleteButton', alttaki 'TrashButton')
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
	assert(button, "tıklanacak düğme bulunamadı")
	local handlers = rawget(button, "_handlers")
	assert(handlers and handlers.MouseButton1Click, "düğmeye tıklama işleyicisi bağlı değil")
	handlers.MouseButton1Click()
end
rawget(S.replicated, "_children")["Shop"] = S.remoteFunction
local PetsPanel = require("./PetsPanel")
local function openPets(owned, equipped)
	S.localPlayer:SetAttribute("OwnedPets", owned)
	S.localPlayer:SetAttribute("EquippedPets", equipped)
	local toasts = {}
	local root = S.newInstance("Frame")
	local toggle = PetsPanel.init(root, function(_, message)
		table.insert(toasts, message)
	end)
	toggle()
	return root, toasts
end

-- 1) Birleşmiş boylar kartlarda boy adıyla listelenir, Pet Team sayısı doğrudur
local root1 = openPets("cat,cat@2,dragon@4,phoenix@3", "cat@2,dragon@4")
local t1 = textsUnder(root1, {})
for _, label in { "Small Cat", "Normal Cat", "Boss Dragon", "Big Phoenix", "Pet Team (2/3 Pets)", "Small", "Normal", "Big", "Boss" } do
	assert(t1[label], "Pets penceresinde yazı yok: " .. label)
end
print("PetsPanel tiers ok")

-- 2) Aynı petten 3 tane: Merge 'Normal (3/3)' der ve tıklanınca FusePet gider; Equip, Merge All, Delete (iki basış)
local root2 = openPets("cat,cat,cat", "")
local t2 = textsUnder(root2, {})
for _, label in { "Normal (3/3)", "Equip", "Merge All", "Pet Team (0/3 Pets)", "Small Cat", "x3" } do
	assert(t2[label], "3'lü pet ekranında yazı yok: " .. label)
end
S.lastInvoke = nil
click(buttonWith(root2, "Equip"))
assert(S.lastInvoke and S.lastInvoke[1] == "EquipPet" and S.lastInvoke[2] == "cat", "Equip düğmesi EquipPet göndermeli")
click(buttonWith(root2, "Normal (3/3)"))
assert(S.lastInvoke[1] == "FusePet" and S.lastInvoke[2] == "cat", "Merge düğmesi FusePet göndermeli")
click(buttonWith(root2, "Merge All"))
assert(S.lastInvoke[1] == "FuseAllPets", "Merge All FuseAllPets göndermeli")
-- Merge All TEK düğmedir (sağda Equip Best / Unequip All'un altında); çöp kutusunun yanındaki eski düğme sahibinin isteğiyle kaldırıldı
local function allButtonsWith(instance, text, found)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "ClassName") == "TextButton" and textsUnder(child, {})[text] then
			table.insert(found, child)
		end
		allButtonsWith(child, text, found)
	end
	return found
end
assert(#allButtonsWith(root2, "Merge All", {}) == 1, "Merge All düğmesi tek olmalı")
S.lastInvoke = nil
click(buttonNamed(root2, "DeleteButton"))
assert(S.lastInvoke == nil, "Delete ilk basışta silmemeli")
assert(textsUnder(root2, {})["Sure?"], "Delete ilk basışta 'Sure?' demeli")
click(buttonWith(root2, "Sure?"))
assert(S.lastInvoke and S.lastInvoke[1] == "DeletePet" and S.lastInvoke[2] == "cat", "ikinci basış DeletePet göndermeli")
local trashIcon = buttonNamed(buttonNamed(root2, "TrashButton"), "TrashIcon")
assert(trashIcon, "alt çöp kutusu düğmesinde simge olmalı")
local trashImage = rawget(trashIcon, "_children")["ImageLabel"]
assert(trashImage and rawget(trashImage, "Image") == "rbxassetid://72909566398443", "yüklenen çöp kutusu görseli kullanılmalı")
assert(t2["+10% when equipped"] and not t2["+10%"], "takılı olmayan petin kartında yüzde olmamalı, ayrıntıda 'when equipped' yazmalı")
print("PetsPanel merge/equip/delete ok")

-- 3) 3'ten az: ilerleme gösterilir, tıklayınca bilgi mesajı (sunucuya gitmez)
local root3, toasts3 = openPets("cat,cat", "")
local t3 = textsUnder(root3, {})
assert(t3["Normal (2/3)"] and t3["Nothing to merge"], "2'li pet için ilerleme / Nothing to merge yok")
S.lastInvoke = nil
click(buttonWith(root3, "Normal (2/3)"))
assert(S.lastInvoke == nil and toasts3[#toasts3] and string.find(toasts3[#toasts3], "You need 3 Small Cat"), "yetersiz pette bilgi mesajı gelmeli")

-- 4) En büyük boy (Boss): MAX SIZE
local root4, toasts4 = openPets("dog@4", "dog@4")
local t4 = textsUnder(root4, {})
assert(t4["MAX SIZE"] and t4["Boss Dog"] and t4["Unequip"], "Boss pet ekranı hatalı")
assert(t4["+33%"] and t4["+33% Leg Muscle"], "takılı petin kartında ve ayrıntısında yüzde olmalı")
click(buttonWith(root4, "MAX SIZE"))
assert(string.find(toasts4[#toasts4], "maximum size"), "Boss için 'maximum size' mesajı gelmeli")

-- 5) Takım dolu: takılı olmayan pette 'Team Full' uyarısı
local root5, toasts5 = openPets("cat,dog,bunny,fox", "dog,bunny,fox")
click(buttonWith(root5, "Small Cat")) -- kartı seç
assert(textsUnder(root5, {})["Team Full"], "takım doluyken Team Full yazmalı")
click(buttonWith(root5, "Team Full"))
assert(string.find(toasts5[#toasts5], "team is full"), "Team Full tıklanınca uyarı gelmeli")

-- 6) Keşif ipucu: kapalı pencerede ilk kez 3 aynı pet toplanınca bir kez hatırlatılır
S.localPlayer:SetAttribute("OwnedPets", "cat,cat")
local hintToasts = {}
PetsPanel.init(S.newInstance("Frame"), function(_, message)
	table.insert(hintToasts, message)
end)
S.localPlayer:SetAttribute("OwnedPets", "cat,cat,cat")
assert(#hintToasts == 1 and string.find(hintToasts[1], "matching pets"), "3 aynı pet toplanınca ipucu gelmeli")
S.localPlayer:SetAttribute("OwnedPets", "cat,cat,cat,dog")
assert(#hintToasts == 1, "ipucu oturumda bir kez gelmeli")
print("PetsPanel hint ok")

-- Çanta sayacı: More+ düğmesi YOK, çantanın sağ altında + işareti Shop'u (Robux) açar, sayaç PetCapacity'yi gösterir
S.localPlayer:SetAttribute("OwnedPets", "cat,cat,dog")
S.localPlayer:SetAttribute("EquippedPets", "")
S.localPlayer:SetAttribute("PetCapacity", 75)
local shopOpened = 0
local capRoot = S.newInstance("Frame")
PetsPanel.init(capRoot, function() end, function()
	shopOpened += 1
end)()
local capTexts = textsUnder(capRoot, {})
assert(not capTexts["More +"], "More + düğmesi kaldırıldı")
assert(capTexts["3/75"], "çanta sayacı kapasiteyi göstermeli (3/75)")
local plus = buttonNamed(capRoot, "BuyPetSpace")
assert(plus and plus.Text == "+", "çantanın yanında + düğmesi olmalı")
click(plus)
assert(shopOpened == 1, "+ düğmesi Shop penceresini açmalı")
S.localPlayer:SetAttribute("PetCapacity", nil)
print("PetsPanel bag plus ok")

-- İksirler (sol alt): etkin iksir şişe simgesi + geri sayımla görünür, etkin olmayanlar gizlidir; Rainbow tek şişedir
local BoostHud = require("./BoostHud")
local Config = require("./Config")
local UIStyle = require("./UIStyle")
local hudRoot = S.newInstance("Frame")
local hudWorkspace = S.game:GetService("Workspace")
rawset(hudWorkspace, "GetServerTimeNow", function() return 1000 end) -- sunucu saati taklitte sayı değil, sabit bir sayı veriyoruz
S.localPlayer:SetAttribute("LuckBoostUntil", 1125)
S.localPlayer:SetAttribute("RainbowBoostUntil", 1040)
BoostHud.init(hudRoot)
rawset(hudWorkspace, "GetServerTimeNow", nil)
local hudSlots = rawget(hudRoot, "_children")
assert(hudSlots["Potion_luck"] and hudSlots["Potion_luck"].Visible == true, "Luck Potion sol altta görünmeli")
assert(hudSlots["Potion_rainbow"].Visible == true, "Rainbow Potion görünmeli")
assert(hudSlots["Potion_muscle"].Visible == false and hudSlots["Potion_wins"].Visible == false, "etkin olmayan iksir gizli olmalı")
assert(textsUnder(hudSlots["Potion_luck"], {})["2:05"], "geri sayım 2:05 yazmalı")
-- Üzerine gelince (dokunmatikte tıklayınca) beyaz açıklama kutusu: ad, açıklama, kalan süre; tekrar tıklayınca kapanır
local tooltip = hudSlots["PotionTooltip"]
assert(tooltip and tooltip.Visible == false, "açıklama kutusu başta gizli olmalı")
click(hudSlots["Potion_luck"])
assert(tooltip.Visible == true, "iksire tıklayınca açıklama kutusu açılmalı")
local tipTexts = textsUnder(tooltip, {})
assert(tipTexts["Luck Potion"] and tipTexts[Config.Potions.List[1].description] and tipTexts["Time left: 2:05"], "kutuda ad, açıklama ve kalan süre olmalı")
click(hudSlots["Potion_luck"])
assert(tooltip.Visible == false, "ikinci tıklama kutuyu kapatmalı")
-- Hazır görsel (Config.Icons.Potions) verilince çizilmiş şişe yerine ImageLabel kullanılır
Config.Icons.Potions.luck = "rbxassetid://1"
local potionIconFrame = UIStyle.potionIcon(S.newInstance("Frame"), Config.Potions.List[1], {})
assert(rawget(potionIconFrame, "_children")["ImageLabel"], "iksir görseli varken ImageLabel kullanılmalı")
Config.Icons.Potions.luck = ""
-- Lego tuğla deseni (düğme/level çubuğu görünümü): hatasız kurulur, kırpılan ve arka plan/simge arasında kalan bir çerçeve döner
local brickHost = S.newInstance("Frame")
local brickSkin = UIStyle.brickSkin(brickHost, 5, 3, 10, { light = 0.9 })
assert(brickSkin and brickSkin.Name == "BrickSkin" and brickSkin.ZIndex == 2, "tuğla deseni çerçevesi kurulmalı (ZIndex 2)")
S.localPlayer:SetAttribute("LuckBoostUntil", nil)
S.localPlayer:SetAttribute("RainbowBoostUntil", nil)
print("potion hud ok")

-- Hareket sırasında boy ölçeği değişirse (level atlama: büyür, rebirth: küçülür) animasyon SIFIRLANMAZ: HipHeight yeni boya göre ölçeklenip hareket sürer, sonda asıl değerine (ölçekli) döner
local Moves = require("./Moves")
local moveCharacter = S.localPlayer.Character
moveCharacter.Parent = S.newInstance("Folder") -- dünyada olmayan karakterin hareketi hemen biter (not character.Parent)
local moveHumanoid = S.newInstance("Humanoid")
moveHumanoid.Health = 100
moveHumanoid.HipHeight = 2
moveHumanoid.FloorMaterial = "Plastic" -- yerde (taklitte Enum karşılaştırması aynı nesneyi verdiği için havada sayılmasın)
moveHumanoid.Parent = moveCharacter
local heightScale = S.newInstance("NumberValue")
heightScale.Name = "BodyHeightScale"
heightScale.Value = 1
heightScale.Parent = moveHumanoid
local widthScale = S.newInstance("NumberValue")
widthScale.Name = "BodyWidthScale"
widthScale.Value = 1
widthScale.Parent = moveHumanoid
for _, jointName in { "RightHip", "LeftHip", "Waist" } do
	local joint = S.newInstance("Motor6D")
	joint.Name = jointName
	joint.C0 = S.CFrame.new()
	joint.Parent = moveCharacter
end
local function runRender()
	for _, f in S.renderStepped do
		f()
	end
end
local function waitSeconds(seconds)
	local start = os.clock()
	while os.clock() - start < seconds do
	end
end
Moves.play(moveCharacter, "Squat")
waitSeconds(0.22) -- squat'ın en alçak anı (0.18-0.30 sn)
runRender()
assert(moveHumanoid.HipHeight > 1.5 and moveHumanoid.HipHeight < 1.9, "çökmüş squat: HipHeight düşmüş olmalı: " .. moveHumanoid.HipHeight)
heightScale.Value = 2 -- level atladı: boy iki katına çıktı (hareket sürerken)
runRender()
assert(moveHumanoid.HipHeight > 3.0 and moveHumanoid.HipHeight < 3.9, "boy değişince hareket sürmeli ve HipHeight yeni boya göre ölçeklenmeli (sıfırlanmamalı): " .. moveHumanoid.HipHeight)
waitSeconds(0.4) -- hareket bitti
runRender()
assert(math.abs(moveHumanoid.HipHeight - 4) < 1e-6, "hareket sonunda HipHeight yeni boyun asıl değerine dönmeli: " .. moveHumanoid.HipHeight)
-- Rebirth: boy bir anda küçülür (2 -> 0.5), hareket yine sıfırlanmaz ve sonda küçük boyun HipHeight'ı kalır
Moves.play(moveCharacter, "Squat")
waitSeconds(0.22)
runRender()
heightScale.Value = 0.5
runRender()
assert(moveHumanoid.HipHeight < 4 * 0.25, "rebirth küçülmesinde HipHeight küçük boya göre düşük kalmalı: " .. moveHumanoid.HipHeight)
waitSeconds(0.4)
runRender()
assert(math.abs(moveHumanoid.HipHeight - 1) < 1e-6, "rebirth sonrası HipHeight küçük boyun asıl değeri olmalı: " .. moveHumanoid.HipHeight)
print("moves keep playing across scale changes ok")

-- 7) Takipçi petler: Boss pet efektli (saydam kabuk + parçacık), diğer boylar düz küre ve boyları büyür
S.localPlayer:SetAttribute("EquippedPets", "cat@4,dog,bunny@3")
local PetFollowers = require("./PetFollowers")
PetFollowers.init()
local worldChildren = rawget(S.game:GetService("Workspace"), "_children")
for _, name in { "Boss Cat", "BossShell", "Small Dog", "Big Bunny" } do
	assert(worldChildren[name], "takipçi parçası yok: " .. name)
end
for _, hb in S.heartbeat do
	hb(0.05)
end
print("PetFollowers boss effect ok")

-- Blender modelleri: ReplicatedStorage.GameModels içinde 'pet_cat' varsa ModelLibrary onu ModelInfo boyutunda verir, PetFollowers model olarak kullanır (Boss dahil)
local ModelLibrary = require("./ModelLibrary")
local ModelInfo = require("./ModelInfo")
assert(not ModelLibrary.has("pet_cat"), "GameModels yokken model olmamalı")
local gameModels = S.newInstance("Folder")
gameModels.Name = "GameModels"
gameModels.Parent = S.replicated
local sourceMesh = S.newInstance("MeshPart")
sourceMesh.Name = "pet_cat"
sourceMesh.Parent = gameModels
assert(ModelLibrary.has("pet_cat"), "GameModels içindeki pet_cat bulunmalı")
local createdMesh, createdOffset = ModelLibrary.create("pet_cat", 0.8)
assert(createdMesh and math.abs(createdMesh.Size.Y - ModelInfo.pet_cat.size.Y * 0.8) < 1e-6, "model ModelInfo boyutunda olmalı")
assert(createdOffset and math.abs(createdOffset.Y - ModelInfo.pet_cat.center.Y * 0.8) < 1e-6, "kutu merkezi ölçeklenmeli")
assert(ModelLibrary.create("pet_yok", 1) == nil, "olmayan model nil dönmeli")
S.localPlayer:SetAttribute("EquippedPets", "cat@4,cat,dog")
PetFollowers.init()
for _, hb in S.heartbeat do
	hb(0.05)
end
print("PetFollowers with Blender model ok")

-- 3B pet simgesi: model varsa ViewportFrame (kamera + model içinde, koyu siluet 'dim'), modeli olmayan tür çizilmiş yüze düşer
local UIStyle = require("./UIStyle")
local Catalog = require("./Catalog")
local Config = require("./Config")
local iconHolder = S.newInstance("Frame")
local cat = Catalog.PetById.cat
local icon3d = UIStyle.petIcon(iconHolder, cat, { Size = S.UDim2.fromOffset(60, 60) })
assert(icon3d and icon3d.ClassName == "ViewportFrame", "pet_cat modeli varken simge ViewportFrame olmalı")
assert(icon3d.CurrentCamera, "ViewportFrame kamerası kurulmalı")
local dimIcon = UIStyle.petIcon(iconHolder, cat, { Size = S.UDim2.fromOffset(60, 60), dim = true })
assert(dimIcon.ImageColor3 == Config.Models.PetIcon.DimColor, "keşfedilmemiş pet koyu siluet olmalı")
local fused = Catalog.PetById["cat@2"]
assert(fused and UIStyle.petIcon(iconHolder, fused, {}).ClassName == "ViewportFrame", "birleşmiş boy türün modelini kullanmalı")
local noModel = UIStyle.petIcon(iconHolder, Catalog.PetById.dog, {})
assert(noModel and noModel.ClassName ~= "ViewportFrame", "pet_dog modeli yokken çizilmiş yüze düşmeli")
print("3D pet icons ok")

-- Günlük çark istemcisi: E ile çevirme isteği sunucuya gider, dilim seçilince çark dönüp durur ve sonuç gösterilir
local wheelToasts = {}
local invokes = {}
S.remoteFunction.InvokeServer = function(_, action, id)
	table.insert(invokes, action)
	return true, "+123 Wins", 3
end
local WheelController = require("./WheelController")
local wheelControl = WheelController.init(S.newInstance("Frame"), function(_, message)
	table.insert(wheelToasts, message)
end)
local trigger = wheelControl.trigger
assert(type(wheelControl.open) == "function", "çark açma işlevi dönmeli")
trigger()
assert(invokes[1] == "SpinWheel", "çevirme SpinWheel göndermeli")
for _ = 1, 16 do
	for _, hb in S.heartbeat do
		hb(0.5)
	end
end
assert(wheelToasts[#wheelToasts] == "+123 Wins", "dönüş bitince sonuç gösterilmeli")
-- Dönüş bittikten sonra yeni istek serbesttir; sunucu reddederse (aynı gün) hata mesajı gösterilir
S.remoteFunction.InvokeServer = function()
	return false, "You already spun today! Next free spin in 3h 10m."
end
trigger()
assert(string.find(wheelToasts[#wheelToasts], "already spun"), "reddedilen çevirmede mesaj gösterilmeli")
-- Çark arayüzü: karartılmış panel, 8 dilimin yazıları, Spin düğmesi onSpin'i çağırır, durum değişince düğme yazısı değişir
local WheelPanel = require("./WheelPanel")
local wheelRoot = S.newInstance("Frame")
local spins = 0
local wheelPanel = WheelPanel.init(wheelRoot, function()
	spins += 1
end)
wheelRoot = rawget(S.localPlayer, "_children").PlayerGui -- panel kendi tam ekran ScreenGui'sinde (WheelGui) kurulur
assert(rawget(wheelRoot, "_children").WheelGui, "çark arayüzü kendi ScreenGui'sinde olmalı")
wheelPanel.open()
assert(wheelPanel.isOpen(), "panel açılmalı")
local wheelTexts = textsUnder(wheelRoot, {})
for _, label in { "DAILY WHEEL", "Spin! (1)", "Wins", "Muscle", "Pet!", "JACKPOT", "24%", "1%", "5%" } do
	assert(wheelTexts[label], "çark arayüzünde yazı yok: " .. label)
end
click(buttonNamed(wheelRoot, "SpinButton"))
assert(spins == 1, "Spin düğmesi onSpin çağırmalı")
wheelPanel.place(123)
wheelPanel.setStatus(false, "Next free spin in 1h 0m", false)
wheelTexts = textsUnder(wheelRoot, {})
assert(wheelTexts["Spin! (0)"] and wheelTexts["Next free spin in 1h 0m"], "hak yokken düğme ve süre yazısı değişmeli")
wheelPanel.close()
assert(not wheelPanel.isOpen(), "panel kapanmalı")
print("WheelController ok")

-- Index ve Stats pencereleri
S.localPlayer:SetAttribute("DiscoveredPets", "cat,dog")
S.localPlayer:SetAttribute("IndexBonus", 2)
local IndexPanel = require("./IndexPanel")
local indexRoot = S.newInstance("Frame")
IndexPanel.init(indexRoot)()
assert(textsUnder(indexRoot, {})["Cat"], "Index'te keşfedilen pet adı yok")
local StatsPanel = require("./StatsPanel")
local statsRoot = S.newInstance("Frame")
StatsPanel.init(statsRoot)()
print("Index and Stats ok")
print("DONE")
