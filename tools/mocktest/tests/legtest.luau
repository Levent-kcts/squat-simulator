-- Bacak kasları: LegGrowth.buildMuscles Blender kası (muscle_s<aşama>_thigh|calf) varsa onu bacağa kaynaklar (bacak ölçüsüne göre ölçekli), yoksa küre kaslara düşer
local S = require("./cstubs")
local Config = require("./Config")
local LegGrowth = require("./LegGrowth")
local ModelInfo = require("./ModelInfo")

local function newLeg(character, name, size)
	local part = S.newInstance("Part")
	part.Name = name
	part.Size = size
	part.Color = S.Color3.new(0.9, 0.7, 0.5)
	part.CFrame = S.CFrame.new()
	part.Parent = character
	return part
end
local function newCharacter(widthScale)
	local character = S.newInstance("Model")
	newLeg(character, "Head", S.Vector3.new(2, 1, 1))
	for _, side in { "Left", "Right" } do
		newLeg(character, side .. "UpperLeg", S.Vector3.new(1 * widthScale, 1.217 * widthScale, 1 * widthScale))
		newLeg(character, side .. "LowerLeg", S.Vector3.new(1 * widthScale, 1.193 * widthScale, 1 * widthScale))
	end
	return character
end
local function countByName(folder)
	local counts = {}
	for _, child in folder:GetChildren() do
		counts[child.Name] = (counts[child.Name] or 0) + 1
	end
	return counts
end

-- 1) Model yokken: küre kaslar (popo, ön uyluk, arka uyluk, baldır = 4 / bacak) + şort tüpleri
local character = newCharacter(1)
LegGrowth.buildMuscles(character, 3)
local folder = character:FindFirstChild("LegMuscles")
assert(folder, "LegMuscles klasörü kurulmadı")
local counts = countByName(folder)
assert(counts.Muscle == 8, "küre kas sayısı 8 olmalı: " .. tostring(counts.Muscle))
assert(counts.Shorts == 2, "şort tüpü 2 olmalı")

-- 2) Aşama 0: kas yok (sadece şort)
local plain = newCharacter(1)
LegGrowth.buildMuscles(plain, 0)
assert(countByName(plain:FindFirstChild("LegMuscles")).Muscle == nil, "aşama 0'da kas olmamalı")

-- 3) Model varken: bacak başına 2 mesh (uyluk + baldır), boyutları ModelInfo x bacak/referans oranı
local gameModels = S.newInstance("Folder")
gameModels.Name = "GameModels"
gameModels.Parent = S.replicated
for stage = 1, 6 do
	for _, part in { "thigh", "calf" } do
		local name = string.format("muscle_s%d_%s", stage, part)
		assert(ModelInfo[name], "ModelInfo'da yok (tools/blender/muscles.py): " .. name)
		local mesh = S.newInstance("MeshPart")
		mesh.Name = name
		mesh.Parent = gameModels
	end
end
for _, stage in { 1, 4, 6 } do
	local big = newCharacter(2) -- genişlik/boy ölçeği 2: kas da 2 kat büyür
	LegGrowth.buildMuscles(big, stage)
	local models = countByName(big:FindFirstChild("LegMuscles"))
	assert(models.Muscle == 4, "model kası sayısı 4 olmalı (2 bacak x uyluk+baldır): " .. tostring(models.Muscle))
	local found = false
	for _, child in big:FindFirstChild("LegMuscles"):GetChildren() do
		if child.Name == "Muscle" and child.ClassName == "MeshPart" then
			found = true
			assert(child.Anchored == false, "kas bacakla birlikte oynamalı (Anchored false)")
		end
	end
	assert(found, "MeshPart kas yok")
end
-- bacak ölçüsü referansın iki katı: her kasın genişliği ilgili ModelInfo genişliği x 2 x MuscleScale olmalı (uyluk ya da baldır)
local check = newCharacter(2)
LegGrowth.buildMuscles(check, 2)
local matched = 0
for _, child in check:FindFirstChild("LegMuscles"):GetChildren() do
	if child.Name == "Muscle" then
		local thigh = math.abs(child.Size.X - ModelInfo.muscle_s2_thigh.size.X * 2 * Config.Models.MuscleScale) < 1e-6
		local calf = math.abs(child.Size.X - ModelInfo.muscle_s2_calf.size.X * 2 * Config.Models.MuscleScale) < 1e-6
		assert(thigh or calf, "kas bacak ölçüsüne göre ölçeklenmeli")
		matched += 1
	end
end
assert(matched == 4, "ölçeği doğrulanan kas sayısı 4 olmalı: " .. matched)
-- aşama sınırı: 6'dan büyük aşama 6. modeli kullanır
local over = newCharacter(1)
LegGrowth.buildMuscles(over, 9)
assert(countByName(over:FindFirstChild("LegMuscles")).Muscle == 4, "aşama sınırı: son model kullanılmalı")
print("leg muscles ok")
print("DONE")
