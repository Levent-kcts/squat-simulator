-- Ayakkabı karakterde: model (shoe_<id>) GameModels'ta varken iki ayağa MeshPart olarak oturur (Weld ile bağlı), ayak gizlenir ve ayak rengi/malzemesi DEĞİŞMEZ;
-- ayak büyüyünce (level / son büyüme evresi) ayakkabı ölçüsü ayağın ölçüsüyle orantılı büyür; ayakkabı kalkınca parçalar kalkar ve ayak geri görünür.
local S = require("./cstubs")
local Config = require("./Config")
local ModelInfo = require("./ModelInfo")
local ShoeWear = require("./ShoeWear")
local AppearanceCleaner = require("./AppearanceCleaner")

local function child(parent, name, className)
	local instance = S.newInstance(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

-- GameModels: raftaki ayakkabı modelleri (içe aktarılmış gibi)
local gameModels = S.newInstance("Folder")
gameModels.Name = "GameModels"
gameModels.Parent = S.replicated
for _, item in Config.Items do
	local mesh = S.newInstance("MeshPart")
	mesh.Name = "shoe_" .. item.id
	mesh.Parent = gameModels
end

local function makeCharacter()
	local character = S.newInstance("Model")
	character.Name = "WearTester"
	local humanoid = child(character, "Humanoid", "Humanoid")
	humanoid.RigType = "R15"
	humanoid.MoveDirection = S.Vector3.new(0, 0, 0)
	humanoid.FindFirstChildOfClass = function()
		return nil
	end
	for _, name in { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } do
		local part = child(character, name, "Part")
		part.Color = S.Color3.new(0.8, 0.6, 0.5)
	end
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = child(character, name, "Part")
		foot.Color = S.Color3.new(0.8, 0.6, 0.5)
		foot.Material = "Plastic"
		foot.Transparency = 0
		foot.Size = S.Vector3.new(1, 0.3, 1)
		foot.CFrame = S.CFrame.new()
	end
	return character, humanoid
end

local function setup(shoeId)
	local player = S.newInstance("Player")
	player.Name = "WearPlayer"
	player.UserId = 21
	rawset(player, "Parent", S.newInstance("Players"))
	local character = makeCharacter()
	player.Character = character
	S.characterOwners[character] = player
	player:SetAttribute("EquippedShoe", shoeId)
	for _, handler in S.playerAdded do
		pcall(handler, player)
	end
	return player, character
end

AppearanceCleaner.init()

local shoe = Config.Items[1]
local player, character = setup(shoe.id)
local folder = character:FindFirstChild("ShoeParts")
assert(folder, "ShoeParts klasörü kurulmadı")
local shoes = folder:GetChildren()
assert(#shoes == 2, "iki ayağa da ayakkabı gerekir: " .. #shoes)
local wear = Config.Models.ShoeWear
local info = ModelInfo["shoe_" .. shoe.id]
for _, part in shoes do
	assert(part.Name == "Shoe" and rawget(part, "Anchored") == false, "ayakkabı parçası kaynaklı (Anchored false) olmalı")
	assert(part:FindFirstChild("ShoeWeld"), "ayakkabıyı ayağa bağlayan Weld yok")
	local size = rawget(part, "Size")
	assert(math.abs(size.X - info.size.X * wear.sx) < 1e-3 and math.abs(size.Y - info.size.Y * wear.sh) < 1e-3 and math.abs(size.Z - info.size.Z * wear.sl) < 1e-3, "ayakkabı ölçüsü ayağa göre değil")
end
for _, footName in { "LeftFoot", "RightFoot" } do
	local foot = character:FindFirstChild(footName)
	assert(rawget(foot, "Transparency") == 1, "ayakkabı giyilince ayak gizlenmeli")
	assert(rawget(foot, "Material") == "Plastic", "ayağın malzemesi (neon boyama) değişmemeli")
	assert(foot:FindFirstChild("ShoeGlow"), "ayak ışığı (ShoeGlow) hâlâ olmalı")
end
print("shoe wear attach ok")

-- Son büyüme evresi: ayak 2.0 x 0.66 x 2.0 olunca ayakkabı 2 / 2.2 / 2 katı büyür
for _, footName in { "LeftFoot", "RightFoot" } do
	character:FindFirstChild(footName).Size = S.Vector3.new(2, 0.66, 2)
end
ShoeWear.refit(character)
for _, part in folder:GetChildren() do
	local size = rawget(part, "Size")
	assert(math.abs(size.X - info.size.X * wear.sx * 2) < 1e-3, "genişlik ayakla birlikte büyümeli")
	assert(math.abs(size.Y - info.size.Y * wear.sh * 2.2) < 1e-3, "boy ayakla birlikte büyümeli")
	assert(math.abs(size.Z - info.size.Z * wear.sl * 2) < 1e-3, "uzunluk ayakla birlikte büyümeli")
end
print("shoe wear regrow ok")

-- Başka ayakkabıya geçiş: parçalar yenilenir (hâlâ iki tane), eski kalmaz
player:SetAttribute("EquippedShoe", Config.Items[5].id)
local again = character:FindFirstChild("ShoeParts")
assert(again and #again:GetChildren() == 2, "ayakkabı değişince iki yeni parça olmalı")
print("shoe wear swap ok")

-- Ayakkabı kalkınca (rebirth): parçalar gider, ayak geri görünür
player:SetAttribute("EquippedShoe", "")
assert(not character:FindFirstChild("ShoeParts"), "ayakkabı kalkınca parçalar silinmeli")
for _, footName in { "LeftFoot", "RightFoot" } do
	assert(rawget(character:FindFirstChild(footName), "Transparency") == 0, "ayak geri görünür olmalı")
end
print("shoe wear remove ok")
print("DONE")
