-- Yumurta açma kuralları (sunucu ve istemci ortak): hangi açma biçimi hangi game pass'i ister (Config.EggPasses). Saf hesaplardır, durum tutmaz.
--   x1 açmak her zaman ücretsizdir. x2-x3 'Triple Open' (count = 3), x4-x10 'Mega Open' (count = 10) ister; otomatik açma 'Auto Open' ister.
local Config = require(script.Parent.Config)

local EggRules = {}

-- Config.EggPasses'te id'ye göre pass (yoksa nil)
function EggRules.pass(id)
	for _, pass in Config.EggPasses do
		if pass.id == id then
			return pass
		end
	end
	return nil
end

-- Bir seferde 'count' yumurta açmak için gereken pass (1 ya da altı için nil). count hiçbir pass'ten büyükse en büyük pass'tir.
function EggRules.passForCount(count)
	if count <= 1 then
		return nil
	end
	local best, largest = nil, nil
	for _, pass in Config.EggPasses do
		if pass.count then
			if pass.count >= count and (not best or pass.count < best.count) then
				best = pass
			end
			if not largest or pass.count > largest.count then
				largest = pass
			end
		end
	end
	return best or largest
end

-- Otomatik açma pass'i
function EggRules.autoPass()
	return EggRules.pass("auto")
end

-- Oyuncu pass'e sahip mi: öznitelik sunucuda yazılır ('HasEggAuto' vb.); pass yoksa (nil: x1) hep serbest
function EggRules.owns(player, pass)
	return pass == nil or player:GetAttribute(pass.attribute) == true
end

-- T tuşu: 'options' sırasında 'current'tan sonra gelen, AÇIK ilk çarpan. Hiç açık çarpan yoksa (sadece x1) nil ve satın alma önerilecek ilk kilitli pass döner.
-- owns(pass) -> bool
function EggRules.nextMulti(options, current, owns)
	local start = 1
	for index, count in options do
		if count == current then
			start = index
		end
	end
	local firstLocked = nil
	for step = 1, #options - 1 do
		local count = options[(start - 1 + step) % #options + 1]
		local pass = EggRules.passForCount(count)
		if owns(pass) then
			return count, nil
		end
		firstLocked = firstLocked or pass
	end
	return nil, firstLocked
end

return EggRules
