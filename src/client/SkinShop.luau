-- Skin rafının oyuncuya özel görünümü (ortak kod: ShelfClient). Etiketteki '+N Power' tıklama başı bacak kası kazancına eklenen sabit sayıdır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
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
			return `+{Format.compact(item.bonus)} Power`
		end,
		labelHeight = 5.7, -- manken ayakkabıdan uzun, etiket onun üstünde kalsın
	})
end

return SkinShop
