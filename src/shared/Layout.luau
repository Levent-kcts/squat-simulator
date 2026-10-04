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
	if stage <= #list then
		return list[stage]
	end
	return math.floor(list[#list] * cfg.HealthGrowthAfter ^ (stage - #list) + 0.5)
end

-- Kırılan duvarlar: canlı "şeker" renkler. Aynı aşamadaki 5 duvar aynı renkte.
function Layout.wallColor(index)
	local hue = (Layout.stageOf(index) - 1) / Layout.StageCount
	return Color3.fromHSV(hue, 0.7, 0.95)
end

-- Aşamanın yan duvar/tavan rengi: aynı tonun soluk (pastel) hali, lobi duvarlarıyla uyumlu
function Layout.stageColor(stage)
	return Color3.fromHSV((stage - 1) / Layout.StageCount, 0.4, 0.78)
end

-- Aşamanın koridor bölümünün bittiği Z: Win pedlerinin hemen arkası, sonraki aşamanın ilk duvarının önü
function Layout.sectionEndZ(stage)
	if stage >= Layout.StageCount then
		return Layout.ZEnd
	end
	return Layout.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap + 2
end

-- Win pedlerinin Z konumu: sonraki aşamanın ilk duvarının hemen önü
function Layout.padZ(stage)
	return Layout.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap + 6
end

-- Pozisyon, index'inci duvarın önünde vuruş menzilinde mi? (duvarın ön yüzüne yatay mesafe)
function Layout.withinReach(index, position)
	local frontZ = Layout.wallZ(index) + cfg.Thickness / 2
	return math.abs(position.Z - frontZ) <= cfg.HitRange and math.abs(position.X) <= cfg.Width / 2 + 2
end

function Layout.stageName(stage)
	return cfg.StageNames[stage] or `Stage {stage}`
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
