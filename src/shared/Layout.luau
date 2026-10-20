-- Koridorun düzeni ve duvar/ödül hesapları. Sunucu da istemci de aynı hesapları kullanır.
-- DÜNYALAR (2026-10-20, World 2): her dünyanın kendi koridoru vardır. Layout.world(id) o dünyanın düzen nesnesini verir
-- (aynı fonksiyonlar: wallZ, wallPosition, stageOf, maxHp, theme, padZ/padX, withinReach, reward ...). Dünyanın koridoru
-- originX kadar yana kaymıştır (World 1 = 0); Z ekseni bütün dünyalarda aynıdır. Can ve ödül, dünyalar arasında
-- KESİNTİSİZ devam eder: World 2'nin 1. aşaması 'global' 21. aşamadır (stageOffset). Modülün kendi alanları (Layout.wallZ ...)
-- World 1'indir: dünya bilmeyen eski kod değişmeden çalışır.
local Config = require(script.Parent.Config)

local base = Config.Wall
local worldDefs = Config.Worlds.List

local Layout = {}

Layout.FloorTop = 0.2

-- Dünyanın duvar ayarları: World 2 yalnız değişen alanları yazar, gerisi Config.Wall'dan gelir
local function wallConfig(def)
	local overrides = def.wall
	if not overrides then
		return base
	end
	return setmetatable(overrides, { __index = base })
end

-- Global aşama listesi: her global aşamanın can büyümesi kendi dünyasının HealthGrowthAfter'ından gelir
local stageGrowth = {} -- [global aşama] = büyüme katsayısı
local totalStages = 0
for _, def in worldDefs do
	local wc = wallConfig(def)
	for _ = 1, wc.Count // wc.GroupSize do
		totalStages += 1
		stageGrowth[totalStages] = wc.HealthGrowthAfter
	end
end
Layout.TotalStages = totalStages

-- Global aşamanın taban canı: Config.Wall.GroupHealth listesi, sonra her aşamada o aşamanın büyümesi
local stageBase = {}
do
	local list = base.GroupHealth
	-- Büyümeler üs olarak toplanır (g1^n1 x g2^n2): World 1'in eski formülüyle (list[#list] x g^(aşama - #list), yuvarlanmış) birebir aynı sonuç
	local counts, order = {}, {}
	for stage = 1, totalStages do
		if stage <= #list then
			stageBase[stage] = list[stage]
		else
			local growth = stageGrowth[stage]
			if not counts[growth] then
				counts[growth] = 0
				table.insert(order, growth)
			end
			counts[growth] += 1
			local product = 1
			for _, g in order do
				product *= g ^ counts[g]
			end
			stageBase[stage] = math.floor(list[#list] * product + 0.5)
		end
	end
end

-- Global aşama ödülleri: 1, 3, 7, 15 ... (her aşama bir öncekini 2 kez yapmaktan fazla verir; dünyalar arasında devam eder)
local rewards = {}
do
	local reward = 0
	for stage = 1, totalStages do
		reward = math.floor(reward * base.RewardGrowth) + 1
		rewards[stage] = reward
	end
end

local worlds = {}

local function makeWorld(def, stageOffset)
	local cfg = wallConfig(def)
	local W = {}
	W.id = def.id
	W.name = def.name or `World {def.id}`
	W.cfg = cfg
	W.FloorTop = Layout.FloorTop
	W.originX = def.originX or 0
	W.stageOffset = stageOffset
	W.StageCount = cfg.Count // cfg.GroupSize
	W.ZFront = cfg.StartZ + cfg.Thickness / 2
	-- Oyuncunun bu dünyada doğduğu yer (World 1 = Config.SpawnPosition)
	W.spawn = Vector3.new(Config.SpawnPosition.X + W.originX, Config.SpawnPosition.Y, Config.SpawnPosition.Z)

	-- Duvarın Z konumu (1. duvar spawn'a en yakın)
	function W.wallZ(index)
		local group = (index - 1) // cfg.GroupSize
		local inGroup = (index - 1) % cfg.GroupSize
		local groupLength = (cfg.GroupSize - 1) * cfg.Spacing + cfg.ButtonGap
		return cfg.StartZ - group * groupLength - inGroup * cfg.Spacing
	end

	W.ZEnd = W.wallZ(cfg.Count) - cfg.ButtonGap - 1

	function W.wallPosition(index)
		return Vector3.new(W.originX, Layout.FloorTop + cfg.Height / 2, W.wallZ(index))
	end

	-- Duvarın ait olduğu aşama (1..StageCount, dünyanın kendi numarası). Her aşama GroupSize duvardır.
	function W.stageOf(index)
		return (index - 1) // cfg.GroupSize + 1
	end

	-- Dünyanın aşaması -> global aşama (can ve ödül hesabı)
	function W.globalStage(stage)
		return stage + stageOffset
	end

	function W.maxHp(index)
		local stage = W.stageOf(index)
		local value = stageBase[math.clamp(stage + stageOffset, 1, totalStages)]
		-- Aşama içindeki sıraya göre artar (1. duvar taban can, sonrakiler GroupHealthSteps kadar daha dayanıklı)
		local steps = cfg.GroupHealthSteps
		local step = if steps then (steps[(index - 1) % cfg.GroupSize + 1] or steps[#steps]) else 1
		return math.max(1, math.floor(value * step + 0.5))
	end

	-- Aşamanın teması (Themes: isim, renk, parçacık, desen). Aynı aşamadaki 5 duvar aynı temayı taşır.
	function W.theme(stage)
		return cfg.Themes[math.clamp(stage, 1, #cfg.Themes)]
	end

	-- Kırılan duvarlar: aşamanın tema rengi
	function W.wallColor(index)
		return W.theme(W.stageOf(index)).color
	end

	-- Aşamanın yan duvar/tavan rengi: tema renginin soluk (pastel) hali (koyu temalarda koridor kararmasın diye açık tona çekilir)
	function W.stageColor(stage)
		return W.theme(stage).color:Lerp(cfg.CorridorTint or Color3.fromRGB(205, 210, 230), 0.45)
	end

	-- Aşamanın koridor bölümünün bittiği Z: Win pedlerinin hemen arkası, sonraki aşamanın ilk duvarının önü
	function W.sectionEndZ(stage)
		if stage >= W.StageCount then
			return W.ZEnd
		end
		return W.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap + 2
	end

	-- Win pedlerinin Z konumu: Win odasının ORTASI (2026-10-20: eskiden sonraki aşamanın ilk duvarının 6 stud önündeydi, yani tekme menzilinin
	-- [HitRange] içinde: sonraki duvara tekme atan oyuncu pede kazara basıyordu, sahibi şikayet etti). Ortada sonraki duvarın tekme menzilinden uzak kalır.
	function W.padZ(stage)
		return W.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap / 2
	end

	-- Win pedlerinin yatay konumu, koridorun ortasına göre (sağda normal ped +padX, solda VIP pedi -padX); dünya kayması EKLENMEZ
	function W.padX()
		return math.max(cfg.Width / 2 - 6, cfg.Width / 2 + (cfg.ChamberExtra or 0) - 11)
	end

	-- Pozisyon, index'inci duvarın önünde vuruş menzilinde mi? (duvarın ön yüzüne yatay mesafe)
	-- extra: menzile eklenen mesafe (squat yok bölgesi için Config.Wall.NoSquatRange; verilmezse tam tekme/hasar menzili)
	function W.withinReach(index, position, extra)
		local frontZ = W.wallZ(index) + cfg.Thickness / 2
		return math.abs(position.Z - frontZ) <= cfg.HitRange + (extra or 0) and math.abs(position.X - W.originX) <= cfg.Width / 2 + 2
	end

	-- Pozisyon bu dünyanın koridorunun içinde mi (lobiden ileride, koridor genişliğinde)?
	function W.inCorridor(position)
		return position.Z < W.ZFront and math.abs(position.X - W.originX) <= cfg.Width / 2 + (cfg.ChamberExtra or 0) + 2
	end

	function W.stageName(stage)
		return W.theme(stage).name
	end

	function W.sectionStartZ(stage)
		if stage <= 1 then
			return W.ZFront
		end
		return W.sectionEndZ(stage - 1)
	end

	-- Aşamanın Win ödülü (global aşama merdiveni: World 2'nin 1. aşaması World 1'in 20. aşamasından fazla verir)
	function W.reward(stage)
		return rewards[math.clamp(stage + stageOffset, 1, totalStages)]
	end

	return W
end

do
	local offset = 0
	for index, def in worldDefs do
		local W = makeWorld(def, offset)
		worlds[def.id or index] = W
		offset += W.StageCount
	end
end

Layout.worldCount = #worldDefs

-- id'nin dünya nesnesi (bilinmeyen id: World 1)
function Layout.world(id)
	return worlds[id] or worlds[1]
end

-- Oyuncunun bulunduğu dünyanın nesnesi (öznitelik 'World'; sunucu yazar)
function Layout.forPlayer(player)
	return Layout.world(player and player:GetAttribute("World") or 1)
end

-- Pozisyon hangi dünyanın alanında? (dünyalar X ekseninde uzak; en yakın originX)
function Layout.worldAt(position)
	local best, bestDistance = worlds[1], math.huge
	for _, W in worlds do
		local distance = math.abs(position.X - W.originX)
		if distance < bestDistance then
			best, bestDistance = W, distance
		end
	end
	return best
end

-- Geriye dönük: modülün kendi alanları World 1'indir
do
	local W1 = worlds[1]
	for key, value in W1 do
		if Layout[key] == nil then
			Layout[key] = value
		end
	end
end

return Layout
