-- Lobideki ayakkabı rafı: SOL duvarda (duvarlara bakarken sol taraf). Raf yapısı server/Shelf'te, skin rafıyla ortaktır;
-- burada sadece ayakkabı modeli ve satın alma bağlanır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShoeModel = require(Shared:WaitForChild("ShoeModel"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)

local ShoeShop = {}

local SHOE_SCALE = 0.4 -- ayakkabı çifti ~3 stud geniş, postamentin biraz altı

-- Çift ayakkabıyı basit parçalardan kurar. Burun izleyiciye (yerel -Z) bakar.
local function buildShoes(parent, item, frame, center)
	local model = Instance.new("Model")
	model.Name = `Shoes_{item.id}`

	local function part(name, size, offset, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size * SHOE_SCALE
		p.CFrame = frame * CFrame.new(center + offset * SHOE_SCALE)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Parent = model
		return p
	end

	-- Parçalar karakterin ayağındaki ayakkabıyla ortaktır (shared/ShoeModel)
	for _, side in { -1, 1 } do
		for _, spec in ShoeModel.parts(item) do
			part(spec.name, spec.size, spec.offset + Vector3.new(side * 2.4, 0, 0), spec.color, spec.material)
		end
	end

	model.Parent = parent
end

function ShoeShop.init(notifyEvent)
	-- Postament ışığı da ayakkabı parlaklığıyla aynı yerde (Neon Kicks) sabitlenir
	local maxGlowIndex
	for index, item in Config.Items do
		if item.id == Config.MaxGlowShoeId then
			maxGlowIndex = index
		end
	end

	Shelf.build({
		maxGlowIndex = maxGlowIndex,
		name = "ShoeShop",
		frame = Shelf.leftWallFrame(Config.Lobby.ShoeShelfZ),
		title = "SHOE UPGRADES",
		signColor = Color3.fromRGB(255, 205, 40),
		items = Config.Items,
		buildDisplay = buildShoes,
		buy = function(player, item)
			return PlayerStats.buyItem(player, item.id)
		end,
		notifyEvent = notifyEvent,
	})
end

return ShoeShop
