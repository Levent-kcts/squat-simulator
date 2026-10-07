-- Yumurta havuzları: her pet SADECE bir yumurtada çıkar (sahibi istedi), her yumurtada 5 pet vardır, havuzdaki her pet Config.Pets'te ve Blender ölçü tablosunda (ModelInfo) bulunur
local S = require("./cstubs")
local Config = require("./Config")
local ModelInfo = require("./ModelInfo")

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
	assert(ModelInfo["pet_" .. pet.id], "ModelInfo'da pet_" .. pet.id .. " yok (tools/blender/pets*.py)")
	count += 1
end
assert(count == 30, "30 pet olmalı: " .. count)
print("egg pools ok", count)
print("DONE")
