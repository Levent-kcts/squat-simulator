-- Skin rafının oyuncuya özel görünümü (ortak kod: ShelfClient). Etiketteki çarpan bacak kası kazancı çarpanıdır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ShelfClient = require(script.Parent.ShelfClient)

local SkinShop = {}

function SkinShop.init()
	ShelfClient.init({
		folderName = "SkinShop",
		items = Config.Skins,
		displayPrefix = "Skin_",
		ownedAttr = "OwnedSkins",
		equippedAttr = "EquippedSkin",
		powerText = function(item)
			return `x{ShelfClient.fmtMultiplier(item.mult)} Power`
		end,
		labelHeight = 5.7, -- manken ayakkabıdan uzun, etiket onun üstünde kalsın
	})
end

return SkinShop
