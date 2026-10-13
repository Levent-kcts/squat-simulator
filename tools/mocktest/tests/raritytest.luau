-- PET NADİRLİĞİ yumurtadaki ÇIKMA ŞANSINA göre (sahibi 2026-10-13: 'güçlü yumurtalarda zayıf petler legendary diye çıkıyor ama aslında yaygın olması lazım, hepsini rengine göre sırala' dedi):
-- her yumurtada en sık çıkan Common, sonra Rare, Epic, Legendary, en nadir Mythic; pet çarpanı ne kadar büyük olursa olsun etkilemez. Birleşmiş boylar tabanın nadirliğini taşır.
local Config = require("./Config")
local Catalog = require("./Catalog")

local rankOf = {}
for rank, rarity in Config.Rarities do
	rankOf[rarity.name] = rank
end
assert(#Config.Rarities == 5 and Config.Rarities[1].name == "Common" and Config.Rarities[5].name == "Mythic", "beş nadirlik sınıfı, Common'dan Mythic'e")
for first = 1, #Config.Rarities do
	for second = first + 1, #Config.Rarities do
		assert(Config.Rarities[first].color ~= Config.Rarities[second].color, "nadirlik renkleri birbirinden farklı olmalı")
	end
end

for _, egg in Config.Eggs do
	local pool = table.clone(egg.pets)
	table.sort(pool, function(a, b)
		return a.weight > b.weight
	end)
	assert(#pool == #Config.Rarities, egg.id .. ": havuzda nadirlik sayısı kadar pet olmalı")
	for rank, entry in pool do
		local pet = Catalog.PetById[entry.id]
		assert(pet, egg.id .. ": pet bulunamadı: " .. entry.id)
		assert(Catalog.rarityOf(pet).name == Config.Rarities[rank].name, `{egg.id}: {entry.id} ({entry.weight}) {Config.Rarities[rank].name} olmalı, {Catalog.rarityOf(pet).name} çıktı`)
		-- birleşmiş boylar tabanın nadirliğini taşır
		for tier = 2, Config.PetFusion.MaxTier do
			local variant = Catalog.PetById[`{entry.id}@{tier}`]
			assert(variant and Catalog.rarityOf(variant) == Catalog.rarityOf(pet), `{entry.id}@{tier} tabanın nadirliğini taşımalı`)
		end
	end
	-- en sık çıkan pet (yumurtanın %50'si) hiçbir yumurtada Common'dan yüksek görünmemeli
	assert(Catalog.rarityOf(Catalog.PetById[pool[1].id]).name == "Common", egg.id .. ": en sık çıkan pet Common olmalı")
end

-- EKRAN GÖRÜNTÜSÜNDEKİ HATA: Galaxy yumurtasının %50 çıkan Unicorn'u (+50) eskiden çarpanından dolayı 'Legendary' görünüyordu
local unicorn = Catalog.PetById.unicorn
assert(unicorn.mult >= 40, "Unicorn güçlü bir pet (çarpan eşiği eski kuralda Legendary yapardı)")
assert(Catalog.rarityOf(unicorn).name == "Common", "Galaxy yumurtasında en sık çıkan Unicorn Common olmalı: " .. Catalog.rarityOf(unicorn).name)
assert(Catalog.rarityOf(Catalog.PetById.titan).name == "Mythic", "Galaxy yumurtasında en nadir pet Mythic olmalı")
-- Zayıf yumurtada da aynı kural: Starter'ın en nadiri Mythic
assert(Catalog.rarityOf(Catalog.PetById.bunny).name == "Mythic" and Catalog.rarityOf(Catalog.PetById.cat).name == "Common", "Starter yumurtasında da sıra aynı")

-- Hiçbir yumurtada çıkmayan pet olursa eski çarpan eşiği yedek olur (hata vermez)
local orphan = Catalog.rarityOf({ mult = 7 })
assert(orphan.name == "Rare", "yumurtasız pet için çarpan eşiği yedek olmalı: " .. orphan.name)
print("rarity by drop chance ok")
