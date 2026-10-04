-- Başlangıç lobisi: kapalı, aydınlık, lego çıkıntılı duvarlı geniş salon. Koridor bu salondan açılır.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Build = require(script.Parent.Build)

local cfg = Config.Wall

local WALL_COLOR = Color3.fromRGB(150, 160, 215)
local FLOOR_COLOR = Color3.fromRGB(170, 178, 225)
local TILE_COLOR = Color3.fromRGB(140, 150, 205)

local EnvironmentService = {}

function EnvironmentService.init()
	-- Kapalı mekan: tavan güneşi keser, aydınlığı ORTAM ışığı verir. Karanlık/mavi havayı kaldırmak için ortam ışığı yüksek ve pozlama nötr;
	-- koridorda ve Win odalarında ayrıca ışık paneli YOK (sahibi istemedi), orası da ortam ışığıyla aydınlıktır.
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(172, 175, 196)
	Lighting.OutdoorAmbient = Color3.fromRGB(172, 175, 196)
	Lighting.GlobalShadows = true

	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = Workspace

	local halfWidth = Config.Lobby.HalfWidth
	local back = Config.Lobby.BackZ
	local zFront = Layout.ZFront
	local length = back - zFront
	local centerZ = (back + zFront) / 2
	local ceiling = Config.Lobby.Height -- salonun yüksekliği
	local corridorCeiling = cfg.CeilingHeight
	local floorTop = Layout.FloorTop

	-- Zemin ve dama tahtası deseni
	Build.block(
		folder,
		"LobbyFloor",
		Vector3.new(halfWidth * 2, 1, length),
		Vector3.new(0, floorTop - 0.5, centerZ),
		FLOOR_COLOR,
		Enum.Material.SmoothPlastic
	)

	local tile = 10
	local columns = (halfWidth * 2) // tile
	local rows = math.ceil(length / tile)
	for row = 0, rows - 1 do
		local rowTop = back - row * tile
		local rowLength = math.min(tile, rowTop - zFront)
		for column = 0, columns - 1 do
			if (row + column) % 2 == 0 then
				local part = Build.block(
					folder,
					"Tile",
					Vector3.new(tile, 0.1, rowLength),
					Vector3.new(-halfWidth + tile * (column + 0.5), floorTop + 0.05, rowTop - rowLength / 2),
					TILE_COLOR,
					Enum.Material.SmoothPlastic
				)
				part.CanCollide = false
				part.CanQuery = false
				part.CastShadow = false
			end
		end
	end

	-- Yan duvarlar ve arka duvar
	for _, side in { -1, 1 } do
		Build.block(
			folder,
			"LobbySide",
			Vector3.new(1, ceiling, length),
			Vector3.new(side * (halfWidth + 0.5), ceiling / 2, centerZ),
			WALL_COLOR,
			Enum.Material.Plastic,
			true
		)
	end
	Build.block(
		folder,
		"LobbyBack",
		Vector3.new(halfWidth * 2 + 2, ceiling, 1),
		Vector3.new(0, ceiling / 2, back + 0.5),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)

	-- Koridor girişi olan duvar: ortada koridor genişliğinde boşluk bırakılır
	local openingHalf = (cfg.Width + 2) / 2
	local segmentWidth = halfWidth - openingHalf
	for _, side in { -1, 1 } do
		Build.block(
			folder,
			"LobbyEntranceWall",
			Vector3.new(segmentWidth, ceiling, 2),
			Vector3.new(side * (openingHalf + segmentWidth / 2), ceiling / 2, zFront + 1),
			WALL_COLOR,
			Enum.Material.Plastic,
			true
		)
	end

	-- Tavan ve ışık panelleri
	-- Koridor girişinin üstü: salon koridordan yüksek olduğu için boşluğun üstü duvarla kapatılır
	Build.block(
		folder,
		"LobbyEntranceHeader",
		Vector3.new(openingHalf * 2, ceiling - corridorCeiling - 1, 2),
		Vector3.new(0, corridorCeiling + 1 + (ceiling - corridorCeiling - 1) / 2, zFront + 1),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)

	Build.block(
		folder,
		"LobbyCeiling",
		Vector3.new(halfWidth * 2 + 2, 1, length + 1),
		Vector3.new(0, ceiling + 0.5, centerZ),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)
	-- Tavan ışık panelleri: salona oranla küçük (7x7), seyrek ızgara (16 adet)
	local z = back - 18
	while z > zFront + 8 do
		for _, x in { -42, -14, 14, 42 } do
			Build.ceilingLight(
				folder,
				"LobbyLight",
				Vector3.new(7, 0.5, 7),
				Vector3.new(x, ceiling - 0.25, z),
				40
			)
		end
		z -= 32
	end

	-- Koridor girişinin üstünde yönlendirme tabelası (lobi içinden okunur)
	local sign = Build.block(
		folder,
		"EntranceSign",
		Vector3.new(34, 8, 1),
		Vector3.new(0, corridorCeiling + 6, zFront + 2.5), -- üst kısım duvara tam yaslı
		Color3.fromRGB(255, 205, 40),
		Enum.Material.SmoothPlastic
	)
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
	text.Text = "BREAK THE WALLS!"
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(40, 25, 0)
	stroke.Parent = text

	-- Oyunun adı: arka duvarda, yumurtaların üstünde büyük tabela (spawn'dan kırılan duvarlara bakarken arkada kalır)
	local title = Build.block(
		folder,
		"TitleSign",
		Vector3.new(70, 8, 0.5),
		Vector3.new(0, 28, back - 0.3),
		Color3.fromRGB(255, 205, 40),
		Enum.Material.SmoothPlastic
	)
	local titleGui = Instance.new("SurfaceGui")
	titleGui.Face = Enum.NormalId.Front
	titleGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	titleGui.PixelsPerStud = 20
	titleGui.Parent = title

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.fromScale(1, 1)
	titleText.BackgroundTransparency = 1
	titleText.Font = Enum.Font.FredokaOne
	titleText.TextScaled = true
	titleText.Text = string.upper(Config.GameName)
	titleText.TextColor3 = Color3.new(1, 1, 1)
	titleText.Parent = titleGui

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 5
	titleStroke.Color = Color3.fromRGB(40, 25, 0)
	titleStroke.Parent = titleText
end

return EnvironmentService
