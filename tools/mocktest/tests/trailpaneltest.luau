-- İZ PANELİ (client/CosmeticPanel): her iz kartında temasının simgesi (tuğla, pati, kupa, bacak kası ya da emoji yedeği) görünür (tester E4: 'trail'ler oyunla alakasız görünüyor').
local S = require("../cstubs")
local Config = require("./Config")
local CosmeticPanel = require("./CosmeticPanel")

local function countNamed(instance, name)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			total += 1
		end
		total += countNamed(child, name)
	end
	return total
end

-- Yerel oyuncunun Win sayacı (panel Win'e göre satın alınabilirlik rengini hesaplar)
local leaderstats = S.newInstance("Folder")
leaderstats.Name = "leaderstats"
local winValue = S.newInstance("IntValue")
winValue.Name = Config.StatWins
winValue.Value = 0
rawget(leaderstats, "_children")[Config.StatWins] = winValue
rawget(S.localPlayer, "_children")["leaderstats"] = leaderstats

local root = S.newInstance("Frame")
local ok, panel = pcall(CosmeticPanel.init, root, function() end, {
	title = "Trails",
	icon = "✨",
	image = Config.Icons.Trails,
	headerTop = Config.Trails[1].color,
	headerBottom = Config.Trails[1].color,
	panelColor = Config.Trails[1].color,
	items = Config.Trails,
	ownedAttr = "OwnedTrails",
	equippedAttr = "EquippedTrail",
	buyAction = "BuyTrail",
	equipAction = "EquipTrail",
	bonusText = function(item)
		return `+{item.speed} Speed`
	end,
	previewKind = "trail",
})
assert(ok, "CosmeticPanel.init hata verdi: " .. tostring(panel))
panel.show()
assert(countNamed(root, "TrailIcon") == #Config.Trails, `her iz kartında tema simgesi olmalı: {countNamed(root, "TrailIcon")} / {#Config.Trails}`)
print("trail panel icons ok")
