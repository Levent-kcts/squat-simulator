local Format = {}

-- 1234567 -> "1,234,567"
function Format.number(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- 1234567 -> "1.2M"  (duvar canı gibi dar yerlerde). Çok büyük sayılar için T, Qa, Qi ... ekleri. decimals: virgülden sonra basamak (varsayılan 1; level çubuğu 2 kullanır: 4.21B).
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.compact(n, decimals)
	n = math.ceil(n)
	if n < 1000 then
		return tostring(n)
	end
	local power = math.min(math.floor(math.log10(n) / 3), #SUFFIXES)
	local text = string.format("%." .. (decimals or 1) .. "f", n / 10 ^ (power * 3))
	text = string.gsub(text, "%.?0+$", "") -- gereksiz sıfırlar atılır: 1.0K -> 1K, 4.20B -> 4.2B (ondalık sıfır değilse korunur: 883.5K)
	return text .. SUFFIXES[power]
end

-- Çarpan yazısı (x işareti çağıranda): HER ZAMAN TAM SAYI (2026-10-13, sahibi 'çarpanlarda ondalık olmasın' dedi): 2.4 -> "2", 250.6 -> "251", 2704825 -> "2.7M".
-- (Arkadaş/Index/iksir yüzde bonusları toplam çarpanı ondalık yapabilir; gösterimde yuvarlanır, hesap ondalıkla yapılır.)
function Format.multiplier(value)
	return Format.compact(math.max(0, math.floor(value + 0.5)))
end

-- Pet bonusu yazısı: petin çarpana eklediği TAM SAYI ('+3'; büyük sayılar kısalır: 1600 -> '+1.6K')
function Format.petBonus(mult)
	return "+" .. Format.compact(mult)
end

return Format
