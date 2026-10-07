local Format = {}

-- 1234567 -> "1,234,567"
function Format.number(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- 1234567 -> "1.2M"  (duvar canı gibi dar yerlerde). Çok büyük sayılar için T, Qa, Qi ... ekleri.
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.compact(n)
	n = math.ceil(n)
	if n < 1000 then
		return tostring(n)
	end
	local power = math.min(math.floor(math.log10(n) / 3), #SUFFIXES)
	return string.format("%.1f%s", n / 10 ^ (power * 3), SUFFIXES[power])
end

-- Çarpan yazısı (x işareti çağıranda): 1.5 -> "1.50", 250 -> "250.0", 2704825.32 -> "2.7M". Çok büyük çarpanlar ham ondalıkla taşmasın diye kısaltılır.
function Format.multiplier(value)
	if value >= 1000 then
		return Format.compact(value)
	elseif value >= 100 then
		return string.format("%.1f", value)
	end
	return string.format("%.2f", value)
end

-- Tıklama başı kazanç gibi büyük tam sayılar: bir milyona kadar virgüllü (1,234,567'ye kadar uzun), sonrası kısaltılır (2.7M, 1.4Qa)
function Format.short(n)
	if n < 1000000 then
		return Format.number(n)
	end
	return Format.compact(n)
end

return Format
