-- Sayı biçimleri: büyük çarpanlar ve tıklama başı kazanç ham ondalıkla taşmaz (alt ortadaki istatistik satırı)
local Format = require("./Format")
local cases = {
	-- Çarpanlar HER ZAMAN tam sayı (2026-10-13): 1.5 -> 2, 12.345 -> 12, 250 -> 250, 999.94 -> 1K, 2704825.32 -> 2.7M
	{ Format.multiplier, 1.5, "2" },
	{ Format.multiplier, 12.345, "12" },
	{ Format.multiplier, 250, "250" },
	{ Format.multiplier, 999.94, "1K" },
	{ Format.multiplier, 2704825.32, "2.7M" },
	{ Format.petBonus, 3, "+3" },
	{ Format.petBonus, 1600, "+1.6K" },
	{ Format.compact, 5, "5" },
	{ Format.compact, 1000, "1K" },
	{ Format.compact, 10000, "10K" },
	{ Format.compact, 100000, "100K" },
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
assert(Format.compact(4200000000, 2) == "4.2B", Format.compact(4200000000, 2))
assert(Format.compact(422000000, 1) == "422M", Format.compact(422000000, 1))
print("formats ok")
print("DONE")
