-- Skin rafının oyuncuya özel görünümü (ortak kod: ShelfClient). Etiketteki '+N Power' tıklama başı bacak kası kazancına eklenen sabit sayıdır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local ShelfClient = require(script.Parent.ShelfClient)

local SkinShop = {}

-- Her dünyanın rafı ayrı klasördedir ('SkinShop', 'SkinShop_W2'): her biri kendi eşyalarıyla
local function initShelf(folderName, items)
	ShelfClient.init({
		folderName = folderName,
		items = items,
		displayPrefix = "Skin_",
		ownedAttr = "OwnedSkins",
		equippedAttr = "EquippedSkin",
		powerText = function(item)
			return `+{Format.compact(item.bonus)} Power`
		end,
		labelHeight = 5.7, -- manken ayakkabıdan uzun, etiket onun üstünde kalsın
	})
end

function SkinShop.init()
	for worldId = 1, #Config.Worlds.List do
		local items = Catalog.forWorld(Config.Skins, worldId)
		if #items > 0 then
			task.spawn(initShelf, if worldId == 1 then "SkinShop" else `SkinShop_W{worldId}`, items)
		end
	end
end

return SkinShop
