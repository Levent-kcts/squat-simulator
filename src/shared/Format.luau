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

return Format
