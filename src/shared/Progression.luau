-- Level ve rebirth hesapları (sunucu ve istemci ortak kullanır).
-- Her hareket bitince 1 "tap" kazanılır; yeterli tap biriktirince level atlanır.
-- Level, o rebirth sayısının izin verdiği üst sınıra (maxLevel) kadar çıkar. Sınıra gelince rebirth yapılabilir.
local Config = require(script.Parent.Config)

local Progression = {}

-- Bu levelden bir sonrakine geçmek için kazanılması gereken bacak kası (level 1 = 10, level 10 = 22; sonrası kuvvet yasasıyla artar).
-- CostPower yoksa eski doğrusal formül kullanılır.
function Progression.tapsNeeded(level)
	local lc = Config.Level
	if lc.CostPower then
		local scale = (lc.TapsAtLevel10 - lc.BaseTaps) / 9 ^ lc.CostPower
		return math.max(1, math.floor(lc.BaseTaps + scale * (level - 1) ^ lc.CostPower + 0.5))
	end
	return math.floor(lc.BaseTaps + (level - 1) * lc.TapsPerLevel + 0.5)
end

-- Verilen rebirth sayısında ulaşılabilecek en yüksek level
function Progression.maxLevel(rebirths)
	return Config.Level.BaseMaxLevel + rebirths * Config.Level.MaxLevelPerRebirth
end

-- Verilen levele ulaşmak için gereken TOPLAM bacak kası (level 1 = 0)
function Progression.cumulativeMuscle(level)
	local total = 0
	for l = 1, level - 1 do
		total += Progression.tapsNeeded(l)
	end
	return total
end

-- Toplam bacak kasından level hesaplar (rebirth üst sınırı maxLevel'i geçmez).
-- Dönüş: level, o level içinde kazanılan kas (çubuk dolulugu). Sınırda ikincisi 0'dır.
function Progression.levelFromMuscle(muscle, maxLevel)
	local level, remaining = 1, muscle
	while level < maxLevel do
		local needed = Progression.tapsNeeded(level)
		if remaining < needed then
			break
		end
		remaining -= needed
		level += 1
	end
	if level >= maxLevel then
		remaining = 0
	end
	return level, remaining
end

-- Level'ın tıklama başı kazanca çarpanı (1. level x1)
function Progression.levelMultiplier(level)
	return 1 + Config.Level.MultiplierPerLevel * (level - 1)
end

-- Her rebirth kalıcı bir çarpan ekler
function Progression.rebirthMultiplier(rebirths)
	return 1 + Config.Rebirth.MultiplierPerRebirth * rebirths
end

-- Karakter ölçeği: level 1'de ince ve normal boy, Body.MaxLevel'de en büyük boyut; sonrasında değişmez.
-- Dönüş: genişlik ölçeği, boy ölçeği
function Progression.bodyScale(level)
	local body = Config.Body
	local t = math.clamp((level - 1) / (body.MaxLevel - 1), 0, 1) ^ body.GrowthCurve
	return body.StartWidth + (body.MaxWidth - body.StartWidth) * t, body.StartHeight + (body.MaxHeight - body.StartHeight) * t
end

-- Bacak kas aşaması: kaç eşik level geçildi (0 = hiç kas yok). Eşikler Config.Legs.StageLevels'te.
-- Rebirth level'ı 1'e döndürdüğü için kaslar da kaybolur.
function Progression.legStage(level)
	local stage = 0
	for _, threshold in Config.Legs.StageLevels do
		if level >= threshold then
			stage += 1
		end
	end
	return stage
end

return Progression
