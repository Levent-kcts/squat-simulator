-- Lobideki skin rafı: SOL duvarda, ayakkabı rafının yanında, aynı standın aynısı. Postamentin üstüne basınca Win karşılığı
-- skin rengi alınır: karakter o renge boyanır (AppearanceCleaner, LegGrowth) ve bacak kası çarpanı kazanılır (PlayerStats).
-- Postamentin üstünde skin renginde küçük bir manken durur (server/Mannequin).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)
local Mannequin = require(script.Parent.Mannequin)

local SkinShop = {}

local DUMMY_SCALE = 0.55 -- manken ~2.9 stud boyunda, postamentin (4 stud) içinde kalır

local function buildDummy(parent, item, frame, center)
	Mannequin.build(parent, `Skin_{item.id}`, frame, center, DUMMY_SCALE, item.color)
end

function SkinShop.init(notifyEvent)
	Shelf.build({
		name = "SkinShop",
		frame = Shelf.leftWallFrame(Config.Lobby.SkinShelfZ),
		title = "SKIN UPGRADES",
		signColor = Color3.fromRGB(190, 90, 255),
		items = Config.Skins,
		buildDisplay = buildDummy,
		buy = function(player, item)
			return PlayerStats.buySkin(player, item.id)
		end,
		notifyEvent = notifyEvent,
	})
end

return SkinShop
