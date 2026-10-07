-- Sayı biçimleri: büyük çarpanlar ve tıklama başı kazanç ham ondalıkla taşmaz (alt ortadaki istatistik satırı)
local Format = require("./Format")
local cases = {
	{ Format.multiplier, 1.5, "1.50" },
	{ Format.multiplier, 12.345, "12.35" },
	{ Format.multiplier, 250, "250.0" },
	{ Format.multiplier, 999.94, "999.9" },
	{ Format.multiplier, 2704825.32, "2.7M" },
	{ Format.compact, 5, "5" },
	{ Format.compact, 883549, "883.5K" },
	{ Format.compact, 2704867, "2.7M" },
	{ Format.compact, 1.4e15, "1.4Qa" },
}
for _, case in cases do
	local actual = case[1](case[2])
	assert(actual == case[3], `{case[2]} -> beklenen {case[3]}, gelen {actual}`)
end
-- Level çubuğu sayıları: iki ondalık (421952954 -> 421.95M, 4210000000 -> 4.21B), küçükler olduğu gibi
assert(Format.compact(421952954, 2) == "421.95M", Format.compact(421952954, 2))
assert(Format.compact(4210000000, 2) == "4.21B", Format.compact(4210000000, 2))
assert(Format.compact(7, 2) == "7")
print("formats ok")
print("DONE")
