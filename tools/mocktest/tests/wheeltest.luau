-- Günlük çark (server/WheelService): dönen Model (dilimler, etiketler, göbek, lambalar, PrimaryPart) ve sabit stand (tabela, ibre, ProximityPrompt) pcall'sız hatasız kurulur.
local S = require("./stubs")
local fakeWorkspace = S.newInstance("Workspace")
local original = S.game.GetService
S.game.GetService = function(self, name)
	if name == "Workspace" then
		return fakeWorkspace
	end
	return original(self, name)
end
local Config = require("./Config")
local WheelService = require("./WheelService")
WheelService.init()

local children = rawget(fakeWorkspace, "_children")
assert(children.DailyWheel, "dönen çark modeli kurulmadı")
assert(children.DailyWheelStand, "çark standı kurulmadı")
local parts = rawget(children.DailyWheel, "_children")
for _, name in { "WheelPivot", "WheelRim", "WheelFace", "WheelFaceCarrier", "WheelRingBlock", "WheelHub", "WheelCap", "WheelLamp" } do
	assert(parts[name], "çark parçası yok: " .. name)
end
-- Çarkın yüzü: levhanın SurfaceGui'sinde 8 dilim (dik üçgen), ayırıcılar ve 8 yazı kutusu
local faceGui = rawget(parts.WheelFaceCarrier, "_children").SurfaceGui
assert(faceGui, "yüz levhasında SurfaceGui yok")
local face = rawget(faceGui, "_children").WheelFace
assert(face, "WheelFace çizilmedi")
local disc = rawget(face, "_children").Disc
assert(disc and rawget(disc, "ClassName") == "Frame", "3B çarkta disk düz Frame olmalı (SurfaceGui içinde CanvasGroup kırpmıyor; köşeleri altın halka örter)")
for index = 1, #Config.Wheel.Prizes do
	assert(rawget(disc, "_children")["Slice" .. index], "dilim yok: " .. index)
	assert(rawget(face, "_children")["Label" .. index], "dilim yazısı yok: " .. index)
end
assert(rawget(children.DailyWheel, "PrimaryPart") == parts.WheelPivot, "PrimaryPart WheelPivot olmalı")

local stand = rawget(children.DailyWheelStand, "_children")
for _, name in { "WheelPlinth", "WheelPlinthTop", "WheelSupport", "WheelPillar", "WheelBanner", "WheelPointer" } do
	assert(stand[name], "stand parçası yok: " .. name)
end
local prompt = rawget(stand.WheelPlinthTop, "_children").ProximityPrompt
assert(prompt and prompt:GetAttribute("Panel") == "Wheel", "ProximityPrompt 'Panel' = 'Wheel' olmalı")
assert(rawget(rawget(stand.WheelBanner, "_children").SpinStatus, "_children").SpinLabel, "durum yazısı SpinLabel yok")
print("WheelService ok")

-- Simge görselleri: Config.Icons'ta görsel yüklüyken çark dilimleri emoji yerine ImageLabel çizer (iksir dilimleri iksir görselini, diğerleri imageKey'i kullanır)
local WheelFace = require("./WheelFace")
local Catalog = require("./Catalog")
local savedIcons = { Wins = Config.Icons.Wins, Pet = Config.Icons.Pet, muscle = Config.Icons.Potions.muscle }
Config.Icons.Wins = ""
assert(Catalog.iconImage("Wins") == "", "görsel yokken boş dönmeli")
Config.Icons.Wins = "rbxassetid://111"
Config.Icons.Pet = "rbxassetid://222"
Config.Icons.Potions.muscle = "rbxassetid://333"
assert(Catalog.iconImage("Wins") == "rbxassetid://111" and Catalog.iconImage(nil, "muscle") == "rbxassetid://333", "iconImage yanlış")
local imgHost = S.newInstance("Frame")
WheelFace.build(imgHost, Config.Wheel.Prizes, { rim = false, hub = false, upright = false, clip = false })
local winsIndex, petIndex, potionIndex
for index, prize in Config.Wheel.Prizes do
	winsIndex = winsIndex or (if prize.kind == "wins" then index else nil)
	petIndex = petIndex or (if prize.kind == "pet" then index else nil)
	potionIndex = potionIndex or (if prize.kind == "boostMuscle" then index else nil)
end
local function prizeImage(index)
	local holder = rawget(rawget(imgHost, "_children").WheelFace or imgHost, "_children")["Label" .. index]
	local icon = holder and rawget(holder, "_children").PrizeIcon
	return icon and rawget(icon, "Image")
end
assert(prizeImage(winsIndex) == "rbxassetid://111", "Wins dilimi kupa görselini göstermeli: " .. tostring(prizeImage(winsIndex)))
assert(prizeImage(petIndex) == "rbxassetid://222", "Pet dilimi pati görselini göstermeli")
assert(prizeImage(potionIndex) == "rbxassetid://333", "iksir dilimi iksir görselini göstermeli")
Config.Icons.Wins, Config.Icons.Pet, Config.Icons.Potions.muscle = savedIcons.Wins, savedIcons.Pet, savedIcons.muscle
print("wheel prize images ok")
print("DONE")
