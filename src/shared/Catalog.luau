-- Config'teki eşya ve petleri id ile hızlıca bulmak için.
local Config = require(script.Parent.Config)

local Catalog = {
	ItemById = {},
	PetById = {},
	AllPets = {}, -- bütün petler: ilk boylar ve birleşmiş boylar (Config.PetFusion), arayüz listeleri için
	EggById = {},
	TrailById = {},
	AuraById = {},
	SkinById = {},
	TrainingAreaById = {},
}

for _, item in Config.Items do
	Catalog.ItemById[item.id] = item
end

-- Petler: ilk boy (Small) Config.Pets'ten gelir; birleştirilmiş (büyümüş) boylar 'id@boy' kimliğiyle burada üretilir (boy adı, çarpan ve boy Config.PetFusion'dan).
-- Her petin alanları: tier (1-4), tierName (Small/Normal/Big/Boss), tierColor, scale, name (ilk boyda 'Cat', diğerlerinde 'Normal Cat') ve label (hep boy adlı: 'Small Cat').
local fusion = Config.PetFusion
for _, pet in Config.Pets do
	pet.baseId = pet.id
	pet.baseName = pet.name
	pet.tier = 1
	pet.tierName = fusion.TierNames[1]
	pet.tierColor = fusion.TierColors[1]
	pet.scale = fusion.Scale[1]
	pet.label = `{pet.tierName} {pet.name}`
	Catalog.PetById[pet.id] = pet
	table.insert(Catalog.AllPets, pet)
end
for _, base in Config.Pets do
	for tier = 2, fusion.MaxTier do
		local id = `{base.id}@{tier}`
		local tierName = fusion.TierNames[tier]
		local pet = {
			id = id,
			baseId = base.id,
			baseName = base.name,
			tier = tier,
			tierName = tierName,
			tierColor = fusion.TierColors[tier],
			name = `{tierName} {base.name}`,
			label = `{tierName} {base.name}`,
			mult = base.mult * fusion.PowerFactor ^ (tier - 1),
			color = base.color:Lerp(Color3.new(1, 1, 1), 0.1 * (tier - 1)),
			scale = fusion.Scale[tier],
		}
		Catalog.PetById[id] = pet
		table.insert(Catalog.AllPets, pet)
	end
end

-- En büyük boy (Boss) mu? Efektli gösterilir (PetFollowers, Pets menüsü)
function Catalog.isBoss(pet)
	return pet.tier >= fusion.MaxTier
end

-- Bir sonraki boyun peti (en büyük boyda nil)
function Catalog.nextTier(pet)
	return Catalog.PetById[`{pet.baseId}@{pet.tier + 1}`]
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
