-- Yumurta havuzları: her pet SADECE bir yumurtada çıkar (sahibi istedi), her yumurtada 5 pet vardır, havuzdaki her pet Config.Pets'te ve Blender ölçü tablosunda (ModelInfo) bulunur
local S = require("./cstubs")
local Config = require("./Config")
local ModelInfo = require("./ModelInfo")
local Catalog = require("./Catalog")

local owner = {}
for _, egg in Config.Eggs do
	assert(#egg.pets == 5, egg.id .. ": 5 pet olmalı, " .. #egg.pets .. " var")
	local total = 0
	for _, entry in egg.pets do
		assert(not owner[entry.id], entry.id .. " iki yumurtada: " .. tostring(owner[entry.id]) .. " ve " .. egg.id)
		owner[entry.id] = egg.id
		total += entry.weight
	end
	assert(total == 100, egg.id .. ": ağırlık toplamı 100 olmalı: " .. total)
end
local count = 0
for _, pet in Config.Pets do
	assert(owner[pet.id], pet.id .. " hiçbir yumurtada çıkmıyor")
	-- World 2 petlerinin Blender modelleri ayrı işte (tools/blender/pets_space.py); gelene kadar kod yedek yüz çizer: model şartı World 1 petlerinde
	if Catalog.petWorld(pet.id) == 1 then
		assert(ModelInfo["pet_" .. pet.id], "ModelInfo'da pet_" .. pet.id .. " yok (tools/blender/pets*.py)")
	end
	count += 1
end
assert(count == 60, "60 pet olmalı (World 1: 30, World 2: 30): " .. count)
assert(#Catalog.WorldPetIds[1] == 30 and #Catalog.WorldPetIds[2] == 30, "her dünyada 30 pet türü olmalı")
-- Luck Potion: luck 1 ağırlıkları aynen verir; luck 2'de en nadir pet x2, en sık pet x1 ağırlıkta kalır, nadirlerin yüzdesi artar
for _, egg in Config.Eggs do
	local base = Catalog.luckWeights(egg, 1)
	local lucky = Catalog.luckWeights(egg, Config.Potions.Mult)
	local baseTotal, luckyTotal = 0, 0
	for index, entry in egg.pets do
		assert(base[index] == entry.weight, egg.id .. ": luck 1 ağırlığı değiştirmemeli")
		baseTotal += base[index]
		luckyTotal += lucky[index]
	end
	local rarest, commonest = egg.pets[#egg.pets], egg.pets[1]
	assert(math.abs(lucky[#egg.pets] - rarest.weight * Config.Potions.Mult) < 1e-9, egg.id .. ": en nadir pet x2 olmalı")
	assert(lucky[1] == commonest.weight, egg.id .. ": en sık pet x1 kalmalı")
	local before = base[#egg.pets] / baseTotal
	local after = lucky[#egg.pets] / luckyTotal
	assert(after > before * 1.4 and after < before * 2.01, egg.id .. ": nadir pet şansı belirgin ama 2 katını geçmeden artmalı: " .. before .. " -> " .. after)
	assert(lucky[1] / luckyTotal < base[1] / baseTotal, egg.id .. ": en sık petin yüzdesi düşmeli")
end
print("egg pools ok", count)
print("DONE")
