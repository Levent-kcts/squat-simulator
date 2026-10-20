-- WORLD 2 (UZAY) LOBİSİ (2026-10-20; sahibi 'ayrı küçük lobi, uzay teması' dedi): World 1'den X ekseninde uzakta (Config.Worlds.List[2].originX)
-- küçük, kapalı salon: koyu gece mavisi/mor lego plakalar, koyu lavanta duvarlar, tavanda küçük yıldızlar ve az sayıda ışık paneli, ön duvarda
-- kendi koridorunun ağzı (World 2 duvarları), ağzın üstünde 'SPACE WALLS!' tabelası ve ön duvarın solunda World 1'e DÖNÜŞ KEMERİ (WorldsGate.build).
-- SpawnLocation KONMAZ (World 1'in tek doğma yeri bozulmasın): oyuncu sunucu tarafından ışınlanır (WallService), zemindeki ped sadece görünümdür.
-- Raflar (ayakkabı, skin) ve yumurtalar bu salona kendi modülleriyle kurulur (Shelf çerçeveleri dünya kaymasını alır). Sadece görünüm, mantık yok.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Build = require(script.Parent.Build)

local World2Lobby = {}

local WALL_COLOR = Color3.fromRGB(128, 122, 190) -- lavanta (sahibi karanlık/mavi havayı sevmedi: koyu ama karanlık değil) (World 1'in açık salonundan ayrışır, karanlık değil)
local SEAM_COLOR = Color3.fromRGB(64, 58, 112)
local PLATE_LIGHT = Color3.fromRGB(128, 120, 196)
local PLATE_DARK = Color3.fromRGB(100, 94, 168)
local STAR_COLORS = { Color3.fromRGB(255, 250, 220), Color3.fromRGB(190, 220, 255), Color3.fromRGB(255, 200, 250) }
local PLANET_COLORS = { Color3.fromRGB(255, 160, 90), Color3.fromRGB(120, 200, 255), Color3.fromRGB(200, 140, 255) }

World2Lobby.FolderName = "World2Lobby"

-- Salonun ölçüleri (dünya koordinatında): sol/sağ duvar x, arka duvar z, ön duvar (koridor ağzı) z
function World2Lobby.bounds()
	local def = Config.Worlds.List[2]
	local W = Layout.world(2)
	local lobby = def.lobby
	return {
		x0 = W.originX,
		left = W.originX - lobby.WidthLeft,
		right = W.originX + lobby.WidthRight,
		back = lobby.BackZ,
		front = W.ZFront,
		height = lobby.Height,
	}
end

function World2Lobby.init()
	if Layout.worldCount < 2 then
		return nil
	end
	local W = Layout.world(2)
	local cfg = W.cfg
	local b = World2Lobby.bounds()
	local floorTop = Layout.FloorTop
	local hallWidth = b.right - b.left
	local centerX = (b.left + b.right) / 2
	local length = b.back - b.front
	local centerZ = (b.back + b.front) / 2
	local ceiling = b.height

	local folder = Instance.new("Folder")
	folder.Name = World2Lobby.FolderName
	folder.Parent = Workspace

	-- Zemin: koyu derz levhası + dama tonlu, studlu lego plakalar (World 1 ile aynı yapı, gece renkleri)
	Build.block(folder, "LobbyFloor", Vector3.new(hallWidth, 1, length), Vector3.new(centerX, floorTop - 0.6, centerZ), SEAM_COLOR, Enum.Material.SmoothPlastic)
	local columns = math.max(8, math.floor(hallWidth / 10.33 + 0.5))
	local rows = math.max(8, math.floor(length / 10.33 + 0.5))
	local cellWidth = hallWidth / columns
	local cellLength = length / rows
	local shadeRandom = Random.new(22)
	for row = 0, rows - 1 do
		for column = 0, columns - 1 do
			local base = if (row + column) % 2 == 0 then PLATE_DARK else PLATE_LIGHT
			local shade = 1 + (shadeRandom:NextNumber() - 0.5) * 0.08
			local plate = Build.block(
				folder,
				"Plate",
				Vector3.new(cellWidth - 0.3, 0.6, cellLength - 0.3),
				Vector3.new(b.left + cellWidth * (column + 0.5), floorTop - 0.3, b.back - cellLength * (row + 0.5)),
				Color3.new(math.clamp(base.R * shade, 0, 1), math.clamp(base.G * shade, 0, 1), math.clamp(base.B * shade, 0, 1)),
				Enum.Material.Plastic
			)
			plate.TopSurface = Enum.SurfaceType.Studs
		end
	end

	-- Yan ve arka duvarlar
	for _, side in { -1, 1 } do
		Build.block(folder, "LobbySide", Vector3.new(1, ceiling, length), Vector3.new(if side < 0 then b.left - 0.5 else b.right + 0.5, ceiling / 2, centerZ), WALL_COLOR, Enum.Material.Plastic, true)
	end
	Build.block(folder, "LobbyBack", Vector3.new(hallWidth + 2, ceiling, 1), Vector3.new(centerX, ceiling / 2, b.back + 0.5), WALL_COLOR, Enum.Material.Plastic, true)

	-- Ön duvar: ortada koridor genişliğinde ağız; ağzın üstü koridor tavanından salon tavanına kadar kapalı
	local openingHalf = (cfg.Width + 2) / 2
	for _, side in { -1, 1 } do
		local edge = if side < 0 then b.left else b.right
		local inner = b.x0 + side * openingHalf
		local segmentWidth = math.abs(edge - inner)
		Build.block(folder, "LobbyEntranceWall", Vector3.new(segmentWidth, ceiling, 2), Vector3.new((edge + inner) / 2, ceiling / 2, b.front + 1), WALL_COLOR, Enum.Material.Plastic, true)
	end
	local corridorCeiling = cfg.CeilingHeight
	Build.block(
		folder,
		"LobbyEntranceHeader",
		Vector3.new(openingHalf * 2, ceiling - corridorCeiling - 1, 2),
		Vector3.new(b.x0, corridorCeiling + 1 + (ceiling - corridorCeiling - 1) / 2, b.front + 1),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)

	-- Tavan: koyu, üstünde seyrek küçük 'yıldızlar' (çarpışmasız Neon noktalar; sadece görünüm) ve az sayıda yumuşak ışık paneli
	Build.block(folder, "LobbyCeiling", Vector3.new(hallWidth + 2, 1, length + 1), Vector3.new(centerX, ceiling + 0.5, centerZ), Color3.fromRGB(58, 52, 104), Enum.Material.SmoothPlastic, true)
	local starRandom = Random.new(77)
	for index = 1, 60 do
		local size = 0.25 + starRandom:NextNumber() * 0.45
		local star = Build.block(
			folder,
			"Star",
			Vector3.new(size, 0.1, size),
			Vector3.new(b.left + 2 + starRandom:NextNumber() * (hallWidth - 4), ceiling - 0.06, b.front + 3 + starRandom:NextNumber() * (length - 6)),
			STAR_COLORS[index % #STAR_COLORS + 1],
			Enum.Material.Neon
		)
		star.CanCollide = false
		star.CanQuery = false
		star.CastShadow = false
	end
	-- Tavana asılı üç küçük 'gezegen' (top + halka), duvarlara ve raflara yakın değil
	for index, spot in { { -22, 10 }, { 20, -20 }, { 4, 32 } } do
		local center = Vector3.new(b.x0 + spot[1], ceiling - 7 - index, spot[2])
		local planet = Instance.new("Part")
		planet.Name = "Planet"
		planet.Shape = Enum.PartType.Ball
		planet.Anchored = true
		planet.CanCollide = false
		planet.CanQuery = false
		planet.Size = Vector3.new(4.5, 4.5, 4.5)
		planet.Position = center
		planet.Color = PLANET_COLORS[index]
		planet.Material = Enum.Material.SmoothPlastic
		planet.Parent = folder
		local ring = Build.block(folder, "PlanetRing", Vector3.new(8, 0.2, 8), center, PLANET_COLORS[index]:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.SmoothPlastic)
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.2, 8, 8)
		ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2 + 0.3)
		ring.CanCollide = false
		ring.CanQuery = false
	end
	local light = Config.Lighting
	for _, x in { -20, 20 } do
		for _, z in { -30, 10 } do
			Build.ceilingLight(folder, "LobbyLight", Vector3.new(light.PanelSize[1], 0.5, light.PanelSize[2]), Vector3.new(b.x0 + x, ceiling - 0.25, z), 40, light.PanelColor, light.PanelLightBrightness)
		end
	end

	-- Doğma pedi: SADECE görünüm (SpawnLocation değil: oyun World 1'in doğma yerini kullanır, buraya sunucu ışınlar)
	local spawnSize = Config.Lobby.SpawnPadSize or 8
	local pad = Build.block(folder, "SpawnPad", Vector3.new(spawnSize, 0.6, spawnSize), Vector3.new(W.spawn.X, floorTop + 0.3, W.spawn.Z), Color3.fromRGB(163, 162, 165), Enum.Material.SmoothPlastic)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/SpawnLocation.png"
	decal.Face = Enum.NormalId.Top
	decal.Parent = pad

	-- Koridor ağzının üstünde yönlendirme tabelası
	local sign = Build.block(folder, "EntranceSign", Vector3.new(34, 8, 1), Vector3.new(b.x0, corridorCeiling + 6, b.front + 2.5), Color3.fromRGB(140, 110, 255), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = "SPACE WALLS!"
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(30, 15, 60)
	stroke.Parent = text

	-- World 1'e DÖNÜŞ KEMERİ: ön duvarın sol yarısında, salona bakan (yerel -Z salona dönük olsun diye 180 derece çevrilir)
	local okGate, WorldsGate = pcall(require, script.Parent.WorldsGate)
	if okGate then
		local gateX = (b.left + b.x0 - openingHalf) / 2
		local built, err = pcall(WorldsGate.build, {
			folderName = "WorldsGate_W2",
			frame = CFrame.new(gateX, 0, b.front + 2) * CFrame.Angles(0, math.pi, 0),
			baseHeight = 0,
			target = 1,
			title = "WORLD 1",
			soonText = "LOBBY",
			note = "Step in to go back",
		})
		if not built then
			warn(`[World2Lobby] return gate failed: {err}`)
		end
	end
	return folder
end

return World2Lobby
