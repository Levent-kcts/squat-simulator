-- Lobideki ayakkabı rafı: SOL duvarda (duvarlara bakarken sol taraf). Raf yapısı server/Shelf'te, skin rafıyla ortaktır;
-- burada sadece ayakkabı modeli ve satın alma bağlanır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local ShoeModel = require(Shared:WaitForChild("ShoeModel"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)

local ShoeShop = {}

local SHOE_SCALE = 0.4 -- ayakkabı çifti ~3 stud geniş, postamentin biraz altı

-- Çift ayakkabıyı basit parçalardan kurar. Burun izleyiciye (yerel -Z) bakar.
local function buildShoes(parent, item, frame, center)
	local model = Instance.new("Model")
	model.Name = `Shoes_{item.id}`

	-- Blender ayakkabısı (shared/ModelLibrary 'shoe_<id>') varsa çift olarak o dizilir; yoksa aşağıdaki kod modeli
	local firstShoe, offset = ModelLibrary.create("shoe_" .. item.id, Config.Models.ShoeScale)
	if firstShoe then
		for _, side in { -1, 1 } do
			local mesh = if side == -1 then firstShoe else (ModelLibrary.create("shoe_" .. item.id, Config.Models.ShoeScale))
			mesh.Name = "Shoe"
			-- Modelin orijini tabanın ortasıdır; taban postamentin hemen üstünde durur. Burun izleyiciye (yerel -Z) bakar.
			mesh.CFrame = ModelLibrary.cframe(frame * CFrame.new(center + Vector3.new(side * 0.96, ShoeModel.BOTTOM * SHOE_SCALE, 0)), offset)
			mesh.Parent = model
		end
		model.Parent = parent
		return
	end

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

	-- Her dünyanın kendi rafı: World 1 sol duvarda (klasör 'ShoeShop'), World 2 kendi salonunun sol duvarında ('ShoeShop_W2')
	for worldId = 1, #Config.Worlds.List do
		local items = Catalog.forWorld(Config.Items, worldId)
		if #items > 0 then
			local lobby = Shelf.worldLobby(worldId)
			Shelf.build({
				maxGlowIndex = if worldId == 1 then maxGlowIndex else 1,
				lightScale = Config.ShoeGlow.ShelfLightScale, -- raftaki ayakkabıların ışığı kısık (sahibi parlaklığı kıstırdı)
				name = if worldId == 1 then "ShoeShop" else `ShoeShop_W{worldId}`,
				frame = if lobby then Shelf.leftWallFrame(lobby.ShelfZ, lobby) else Shelf.leftWallFrame(Config.Lobby.ShoeShelfZ),
				title = if worldId == 1 then "SHOE UPGRADES" else "SPACE SHOES",
				signColor = Color3.fromRGB(255, 205, 40),
				items = items,
				buildDisplay = buildShoes,
				buy = function(player, item)
					return PlayerStats.buyItem(player, item.id)
				end,
				notifyEvent = notifyEvent,
			})
		end
	end
end

return ShoeShop
