
local S = require("./stubs")
local Config = require("./Config")
local ShoeModel = require("./ShoeModel")
for _, item in Config.Items do
	local color = ShoeModel.neonColor(item)
	print(string.format("%-12s tier=%.2f neon=%.2f top=%s trail=%s", item.id, ShoeModel.tier(item), color.R / item.color.R, tostring(ShoeModel.isTop(item)), tostring(ShoeModel.trailLevel(item))))
end
local parts = ShoeModel.parts(Config.Items[#Config.Items])
print("parts", #parts)
