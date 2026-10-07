-- Sayı biçimleri: büyük çarpanlar ve tıklama başı kazanç ham ondalıkla taşmaz (alt ortadaki istatistik satırı)
local Format = require("./Format")
local cases = {
	{ Format.multiplier, 1.5, "1.50" },
	{ Format.multiplier, 12.345, "12.35" },
	{ Format.multiplier, 250, "250.0" },
	{ Format.multiplier, 999.94, "999.9" },
	{ Format.multiplier, 2704825.32, "2.7M" },
	{ Format.short, 5, "5" },
	{ Format.short, 2704867, "2.7M" },
	{ Format.short, 999999, "999,999" },
	{ Format.short, 1.4e15, "1.4Qa" },
}
for _, case in cases do
	local actual = case[1](case[2])
	assert(actual == case[3], `{case[2]} -> beklenen {case[3]}, gelen {actual}`)
end
print("formats ok")
print("DONE")
