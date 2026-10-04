-- Config'teki eşya ve petleri id ile hızlıca bulmak için.
local Config = require(script.Parent.Config)

local Catalog = {
	ItemById = {},
	PetById = {},
	EggById = {},
	TrailById = {},
	AuraById = {},
	SkinById = {},
	TrainingAreaById = {},
}

for _, item in Config.Items do
	Catalog.ItemById[item.id] = item
end

for _, pet in Config.Pets do
	Catalog.PetById[pet.id] = pet
end

for _, egg in Config.Eggs do
	Catalog.EggById[egg.id] = egg
end

for _, trail in Config.Trails do
	Catalog.TrailById[trail.id] = trail
end

for _, aura in Config.Auras do
	Catalog.AuraById[aura.id] = aura
end

for _, skin in Config.Skins do
	Catalog.SkinById[skin.id] = skin
end

for _, area in Config.Training.Areas do
	Catalog.TrainingAreaById[area.id] = area
end

-- Pet nadirliği (Config.Rarities): çarpanı sınırın altında kalan ilk sınıf
function Catalog.rarityOf(pet)
	for _, rarity in Config.Rarities do
		if pet.mult < rarity.maxMult then
			return rarity
		end
	end
	return Config.Rarities[#Config.Rarities]
end

return Catalog
