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

-- Bir ödül/ürün simgesinin görseli: imageKey = Config.Icons anahtarı ('Wins', 'LegMuscle', 'Pet'...), potionId = iksir id'si ('luck', 'muscle', 'wins', 'rainbow').
-- Görsel yüklenmişse 'rbxassetid://...', yoksa '' döner (çağıran emoji yedeğine düşer).
function Catalog.iconImage(imageKey, potionId)
	if potionId then
		local potions = Config.Icons.Potions
		local id = potions and potions[potionId]
		return if type(id) == "string" then id else ""
	end
	local id = imageKey and Config.Icons[imageKey]
	return if type(id) == "string" then id else ""
end

-- Bir iksir türü (kind: boostLuck...) ve süre (dakika) için Shop ürün kimliği ('luck15'); öyle bir ürün yoksa nil. Çark/Gifts/görev iksirleri envantere bu kimlikle girer.
function Catalog.potionSkuFor(kind, minutes)
	local potion = Catalog.PotionByKind[kind]
	local id = potion and `{potion.id}{minutes}`
	return if id and Catalog.PotionSkuById[id] then id else nil
end

-- Ödül yazısı/verilişi için: Auto Click game pass'i olan oyuncuda Auto Click Potion ödülü Rainbow olur (Config.Potions.AutoOwnerReplacement). Dönüş: kind, minutes
function Catalog.ownerPotion(kind, minutes, ownsAutoPass)
	if kind == "boostAuto" and ownsAutoPass then
		local replacement = Config.Potions.AutoOwnerReplacement
		return replacement.kind, replacement.minutes
	end
	return kind, minutes
end

-- Çarkın dilimleri: Auto Click game pass'i olan oyuncu için 'Auto Click Potion' dilimi 'Rainbow Potion' görünür (sunucu da öyle verir: Config.Potions.AutoOwnerReplacement); diğerleri Config.Wheel.Prizes ile aynı
function Catalog.wheelPrizes(ownsAutoPass)
	if not ownsAutoPass then
		return Config.Wheel.Prizes
	end
	local replacement = Config.Potions.AutoOwnerReplacement
	local potion = Catalog.PotionByKind[replacement.kind]
	local list = {}
	for _, prize in Config.Wheel.Prizes do
		if prize.kind == "boostAuto" then
			local copy = table.clone(prize)
			copy.kind = replacement.kind
			copy.minutes = replacement.minutes
			copy.potion = potion.id
			copy.icon = potion.emoji
			copy.label = potion.name
			table.insert(list, copy)
		else
			table.insert(list, prize)
		end
	end
	return list
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

-- PET NADİRLİĞİ yumurtadaki çıkma şansına göre (Config.Rarities'in açıklaması): havuz ağırlığa göre sıralanır (eşitlikte havuzdaki sıra), sıra sayısı nadirlik sırasıdır.
-- Petin kendisine ve bütün boylarına ('cat', 'cat@2'...) 'rarity' yazılır; Catalog.rarityOf bunu okur.
for _, egg in Config.Eggs do
	local order = table.clone(egg.pets)
	local position = {}
	for index, entry in egg.pets do
		position[entry] = index
	end
	table.sort(order, function(a, b)
		if a.weight ~= b.weight then
			return a.weight > b.weight
		end
		return position[a] < position[b]
	end)
	for rank, entry in order do
		local rarity = Config.Rarities[math.min(rank, #Config.Rarities)]
		local base = Catalog.PetById[entry.id]
		if base then
			base.rarity = rarity
			for tier = 2, fusion.MaxTier do
				local variant = Catalog.PetById[`{base.id}@{tier}`]
				if variant then
					variant.rarity = rarity
				end
			end
		end
	end
end

-- Sezonluk etkinlik izi (Config.Event.Trail): Config.Trails'te değil, ama aynı katalogdan bulunur (takma, iz efekti, kayıt temizliği)
if Config.Event and Config.Event.Trail then
	Catalog.TrailById[Config.Event.Trail.id] = Config.Event.Trail
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

-- EĞİTİM YUMURTASI (2026-10-14 büyüme planı sprint 1.3): Roblox 'ücretli rastgele ürün' kısıtı olan hesaplarda (UK, AU, NL, BE, BR...) rastgele yumurta açılamaz; Roblox'un önerdiği uyumlu yol:
-- sonuçları ÖNCEDEN BİLİNEN, SABİT SIRALI yumurta. Her yumurtanın havuzu en sık çıkandan en nadire 25 / 15 / 6 / 3 / 1 kez geçen 50 açılıklık sabit bir döngüdür (oranlar normal yumurtaya yakın: %50/30/12/6/2);
-- döngü yumurta paneli açıkken oyuncuya GÖSTERİLİR (her pet '25/50' gibi) ve sıradaki pet 'NEXT' diye işaretlenir. Sunucu (PlayerStats.hatchEgg) ve istemci AYNI döngüyü buradan alır.
Catalog.TrainingCounts = { 25, 15, 6, 3, 1 }
Catalog.TrainingLength = 50
local trainingCache = {}
function Catalog.trainingCycle(egg)
	local cached = trainingCache[egg.id]
	if cached then
		return cached
	end
	local order = {}
	for index, entry in egg.pets do
		order[index] = { id = entry.id, weight = entry.weight, position = index }
	end
	table.sort(order, function(a, b)
		if a.weight ~= b.weight then
			return a.weight > b.weight
		end
		return a.position < b.position
	end)
	-- Açıklık (deficit) programlaması: her adımda hedef oranından en çok geride kalan pet seçilir; böylece nadir petler döngüye düzgün yayılır
	local placed, cycle = {}, {}
	for index = 1, #Catalog.TrainingCounts do
		placed[index] = 0
	end
	for slot = 1, Catalog.TrainingLength do
		local bestIndex, bestDeficit = 1, -math.huge
		for index, target in Catalog.TrainingCounts do
			if placed[index] < target then
				local deficit = target * slot / Catalog.TrainingLength - placed[index]
				if deficit > bestDeficit + 1e-9 then
					bestIndex, bestDeficit = index, deficit
				end
			end
		end
		placed[bestIndex] += 1
		table.insert(cycle, order[math.min(bestIndex, #order)].id)
	end
	trainingCache[egg.id] = cycle
	return cycle
end

-- Döngüde her petin kaç kez geçtiği { [petId] = adet }
function Catalog.trainingCounts(egg)
	local counts = {}
	for _, id in Catalog.trainingCycle(egg) do
		counts[id] = (counts[id] or 0) + 1
	end
	return counts
end

-- Pet nadirliği (Config.Rarities): yumurtadaki çıkma şansına göre (yukarıdaki döngü); hiçbir yumurtada çıkmayan pet için yedek: çarpanı sınırın altında kalan ilk sınıf
function Catalog.rarityOf(pet)
	if pet.rarity then
		return pet.rarity
	end
	for _, rarity in Config.Rarities do
		if pet.mult < rarity.maxMult then
			return rarity
		end
	end
	return Config.Rarities[#Config.Rarities]
end

return Catalog
