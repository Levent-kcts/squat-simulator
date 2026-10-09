-- Yumurta açma kuralları (sunucu ve istemci ortak): hangi açma biçimi hangi game pass'i ister (Config.EggPasses). Saf hesaplardır, durum tutmaz.
--   x1 açmak her zaman ücretsizdir. x2-x10 (T ile seçilen x3 ve x10 modları) 'Multi Open' pass'ini (count = 10) ister; otomatik açma 'Auto Open' ister.
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

-- T tuşu (sahibi 'satın almasan dahi T'ye basınca fiyat değişiyor, satın almadan o düğme çalışmasın' dedi): bir İMLEÇ x1 > x3 > x10 > x1 diye gezer. Imlecin geldiği seçenek AÇIKSA (x1 her zaman, x3/x10 ilgili pass varsa) SEÇİLİR;
-- KİLİTLİYSE seçim ve başlıktaki toplam fiyat DEĞİŞMEZ, sadece o pass'in satın alma penceresi/fiyatı görünür. Döner: yeni imleç, seçilen çarpan (kilitliyse nil), satın alınacak pass (açıksa nil). owns(pass) -> bool
function EggRules.step(options, cursor, owns)
	local nextCursor = cursor % #options + 1
	local count = options[nextCursor]
	local pass = EggRules.passForCount(count)
	if owns(pass) then
		return nextCursor, count, nil
	end
	return nextCursor, nil, pass
end

return EggRules
