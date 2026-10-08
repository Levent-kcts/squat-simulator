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
	PotionByKind = {}, -- iksirler (Config.Potions.List) ödül türüne göre
	PotionById = {}, -- iksirler id'ye göre (luck, muscle, wins, rainbow)
	PotionSkuById = {}, -- Shop'ta satılan iksir ürünleri (Config.Shop.Potions): luck15, luck60 ...; sku.def = iksir, sku.kind = ödül türü
}

for _, item in Config.Items do
	Catalog.ItemById[item.id] = item
end
for _, potion in Config.Potions.List do
	Catalog.PotionByKind[potion.kind] = potion
	Catalog.PotionById[potion.id] = potion
end
for _, sku in Config.Shop.Potions do
	sku.def = Catalog.PotionById[sku.potion]
	sku.kind = sku.def.kind
	Catalog.PotionSkuById[sku.id] = sku
end

-- Bir iksir türü (kind: boostLuck...) ve süre (dakika) için Shop ürün kimliği ('luck15'); öyle bir ürün yoksa nil. Çark/Gifts/görev iksirleri envantere bu kimlikle girer.
function Catalog.potionSkuFor(kind, minutes)
	local potion = Catalog.PotionByKind[kind]
	local id = potion and `{potion.id}{minutes}`
	return if id and Catalog.PotionSkuById[id] then id else nil
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

-- Şans iksiri (Luck Potion): yumurta havuzundaki petlerin etkin ağırlıkları (egg.pets ile aynı sırada). Havuz sıklığa göre sıralanır, en sık pet x1'de kalır,
-- en nadir pet x luck olur, aradakiler düzgün (geometrik) artar: nadir petler şanslandıkça daha sık çıkar. luck = 1 ise ağırlıklar aynen döner.
-- Sunucu (PlayerStats.rollPet) ve istemci (yumurta paneli yüzdeleri) AYNI hesabı kullanır.
function Catalog.luckWeights(egg, luck)
	local entries = egg.pets
	local order = {}
	for index in entries do
		table.insert(order, index)
	end
	table.sort(order, function(a, b)
		if entries[a].weight ~= entries[b].weight then
			return entries[a].weight > entries[b].weight
		end
		return a < b
	end)
	local count = #order
	local weights = {}
	for rank, index in order do
		local exponent = if count > 1 then (rank - 1) / (count - 1) else 0
		weights[index] = entries[index].weight * (luck or 1) ^ exponent
	end
	return weights
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
