-- Ayakkabı rafının oyuncuya özel görünümü (ortak kod: ShelfClient).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local ShelfClient = require(script.Parent.ShelfClient)

local ShoeShop = {}

-- Her dünyanın rafı ayrı klasördedir ('ShoeShop', 'ShoeShop_W2'): her biri kendi eşyalarıyla
local function initShelf(folderName, items)
	ShelfClient.init({
		folderName = folderName,
		items = items,
		displayPrefix = "Shoes_",
		ownedAttr = "OwnedItems",
		equippedAttr = "EquippedShoe",
		powerText = function(item)
			return `x{ShelfClient.fmtMultiplier(item.damage)} Damage`
		end,
		labelHeight = 4.3,
	})
end

function ShoeShop.init()
	for worldId = 1, #Config.Worlds.List do
		local items = Catalog.forWorld(Config.Items, worldId)
		if #items > 0 then
			task.spawn(initShelf, if worldId == 1 then "ShoeShop" else `ShoeShop_W{worldId}`, items)
		end
	end
end

return ShoeShop
