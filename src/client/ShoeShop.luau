-- Ayakkabı rafının oyuncuya özel görünümü (ortak kod: ShelfClient).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local ShelfClient = require(script.Parent.ShelfClient)

local ShoeShop = {}

function ShoeShop.init()
	ShelfClient.init({
		folderName = "ShoeShop",
		items = Config.Items,
		displayPrefix = "Shoes_",
		ownedAttr = "OwnedItems",
		equippedAttr = "EquippedShoe",
		powerText = function(item)
			return `+{Format.compact(item.bonus)} Damage`
		end,
		labelHeight = 4.3,
	})
end

return ShoeShop
