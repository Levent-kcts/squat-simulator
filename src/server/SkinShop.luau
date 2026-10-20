-- Lobideki skin rafı: SOL duvarda, ayakkabı rafının yanında, aynı standın aynısı. Postamentin üstüne basınca Win karşılığı
-- skin rengi alınır: karakter o renge boyanır (AppearanceCleaner, LegGrowth) ve bacak kası çarpanı kazanılır (PlayerStats).
-- Postamentin üstünde skin renginde küçük bir manken durur (server/Mannequin).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)
local Mannequin = require(script.Parent.Mannequin)

local SkinShop = {}

local DUMMY_SCALE = 0.55 -- manken ~2.9 stud boyunda, postamentin (4 stud) içinde kalır

local function buildDummy(parent, item, frame, center)
	Mannequin.build(parent, `Skin_{item.id}`, frame, center, DUMMY_SCALE, item.color)
end

function SkinShop.init(notifyEvent)
	-- Her dünyanın kendi rafı: World 1 sol duvarda ayakkabıların yanında ('SkinShop'), World 2 kendi salonunun SAĞ duvarında ('SkinShop_W2')
	for worldId = 1, #Config.Worlds.List do
		local items = Catalog.forWorld(Config.Skins, worldId)
		if #items > 0 then
			local lobby = Shelf.worldLobby(worldId)
			Shelf.build({
				name = if worldId == 1 then "SkinShop" else `SkinShop_W{worldId}`,
				frame = if lobby then Shelf.rightWallFrame(lobby.ShelfZ, lobby) else Shelf.leftWallFrame(Config.Lobby.SkinShelfZ),
				title = if worldId == 1 then "SKIN UPGRADES" else "SPACE SKINS",
				signColor = Color3.fromRGB(190, 90, 255),
				items = items,
				buildDisplay = buildDummy,
				buy = function(player, item)
					return PlayerStats.buySkin(player, item.id)
				end,
				notifyEvent = notifyEvent,
			})
		end
	end
end

return SkinShop
