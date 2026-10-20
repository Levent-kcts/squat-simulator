-- Koridorun düzeni ve duvar/ödül hesapları. Sunucu da istemci de aynı hesapları kullanır.
local Config = require(script.Parent.Config)

local cfg = Config.Wall

local Layout = {}

Layout.FloorTop = 0.2
Layout.StageCount = cfg.Count // cfg.GroupSize
Layout.ZFront = cfg.StartZ + cfg.Thickness / 2

-- Duvarın Z konumu (1. duvar spawn'a en yakın)
function Layout.wallZ(index)
	local group = (index - 1) // cfg.GroupSize
	local inGroup = (index - 1) % cfg.GroupSize
	local groupLength = (cfg.GroupSize - 1) * cfg.Spacing + cfg.ButtonGap
	return cfg.StartZ - group * groupLength - inGroup * cfg.Spacing
end

Layout.ZEnd = Layout.wallZ(cfg.Count) - cfg.ButtonGap - 1

function Layout.wallPosition(index)
	return Vector3.new(0, Layout.FloorTop + cfg.Height / 2, Layout.wallZ(index))
end

-- Duvarın ait olduğu aşama (1..StageCount). Her aşama GroupSize duvardır.
function Layout.stageOf(index)
	return (index - 1) // cfg.GroupSize + 1
end

function Layout.maxHp(index)
	local stage = Layout.stageOf(index)
	local list = cfg.GroupHealth
	local base = if stage <= #list then list[stage] else math.floor(list[#list] * cfg.HealthGrowthAfter ^ (stage - #list) + 0.5)
	-- Aşama içindeki sıraya göre artar (1. duvar taban can, sonrakiler GroupHealthSteps kadar daha dayanıklı)
	local steps = cfg.GroupHealthSteps
	local step = if steps then (steps[(index - 1) % cfg.GroupSize + 1] or steps[#steps]) else 1
	return math.max(1, math.floor(base * step + 0.5))
end

-- Aşamanın teması (Config.Wall.Themes: isim, renk, parçacık, desen). Aynı aşamadaki 5 duvar aynı temayı taşır.
function Layout.theme(stage)
	return cfg.Themes[math.clamp(stage, 1, #cfg.Themes)]
end

-- Kırılan duvarlar: aşamanın tema rengi (Paper krem, Wood kahve, Gold altın ... Blackhole siyah)
function Layout.wallColor(index)
	return Layout.theme(Layout.stageOf(index)).color
end

-- Aşamanın yan duvar/tavan rengi: tema renginin soluk (pastel) hali (siyah gibi koyu temalarda koridor kararmasın diye açık griye çekilir), lobi duvarlarıyla uyumlu
function Layout.stageColor(stage)
	return Layout.theme(stage).color:Lerp(Color3.fromRGB(205, 210, 230), 0.45)
end

-- Aşamanın koridor bölümünün bittiği Z: Win pedlerinin hemen arkası, sonraki aşamanın ilk duvarının önü
function Layout.sectionEndZ(stage)
	if stage >= Layout.StageCount then
		return Layout.ZEnd
	end
	return Layout.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap + 2
end

-- Win pedlerinin Z konumu: Win odasının ORTASI (2026-10-20: eskiden sonraki aşamanın ilk duvarının 6 stud önündeydi, yani tekme menzilinin
-- [HitRange] içinde: sonraki duvara tekme atan oyuncu pede kazara basıyordu, sahibi şikayet etti). Ortada sonraki duvarın tekme menzilinden uzak kalır.
function Layout.padZ(stage)
	return Layout.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap / 2
end

-- Win pedlerinin yatay konumu (sağda normal ped +padX, solda VIP pedi -padX): oda genişse köşelere yaklaşır, koridor genişliğinde eski yerinde kalır
function Layout.padX()
	return math.max(cfg.Width / 2 - 6, cfg.Width / 2 + (cfg.ChamberExtra or 0) - 11)
end

-- Pozisyon, index'inci duvarın önünde vuruş menzilinde mi? (duvarın ön yüzüne yatay mesafe)
-- extra: menzile eklenen mesafe (squat yok bölgesi için Config.Wall.NoSquatRange; verilmezse tam tekme/hasar menzili)
function Layout.withinReach(index, position, extra)
	local frontZ = Layout.wallZ(index) + cfg.Thickness / 2
	return math.abs(position.Z - frontZ) <= cfg.HitRange + (extra or 0) and math.abs(position.X) <= cfg.Width / 2 + 2
end

function Layout.stageName(stage)
	return Layout.theme(stage).name
end

function Layout.sectionStartZ(stage)
	if stage <= 1 then
		return Layout.ZFront
	end
	return Layout.sectionEndZ(stage - 1)
end

local rewards = {}
do
	local reward = 0
	for stage = 1, Layout.StageCount do
		reward = math.floor(reward * cfg.RewardGrowth) + 1
		rewards[stage] = reward
	end
end

function Layout.reward(stage)
	return rewards[stage]
end

return Layout
