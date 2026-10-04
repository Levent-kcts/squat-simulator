-- Duvarlar sadece bu oyuncunun ekranında vardır. Diğer oyuncular senin duvarlarını görmez,
-- yani senin duvarlardan geçtiğini görürler. Canları sunucu tutar, burada sadece gösterilir.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Format = require(Shared:WaitForChild("Format"))

local cfg = Config.Wall

-- Efekt modülü korumalı yüklenir: hata verirse duvarlar yine çalışır
local okJuice, Juice = pcall(require, script.Parent.Juice)

local WallClient = {}

-- Hayatta olan ilk duvarın sırası (Count + 1 = hepsi kırık)
local currentFrontier = 1

-- Hayatta olan ilk duvarın sırası (Count + 1 = hepsi kırık). Yol gösterici bunu okur.
function WallClient.getFrontier()
	return currentFrontier
end

-- Oyuncu, ilk sağlam duvarın vuruş menzilinde mi? (tekme mi squat mı seçmek için)
function WallClient.isNearWall(position)
	return currentFrontier <= cfg.Count and Layout.withinReach(currentFrontier, position)
end

-- Duvar yüzündeki yazı: ortalanmış, kalın siyah kenarlı
local function makeText(parent, position, size, text)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label
end

local function createWall(folder, index)
	local part = Instance.new("Part")
	part.Name = `Wall_{index}`
	part.Anchored = true
	part.Size = Vector3.new(cfg.Width, cfg.Height, cfg.Thickness)
	part.Position = Layout.wallPosition(index)
	part.Material = Enum.Material.Plastic
	part.Color = Layout.wallColor(index)
	-- Lego çıkıntıları (ön yüz yazılar için düz kalır)
	part.TopSurface = Enum.SurfaceType.Studs
	part.LeftSurface = Enum.SurfaceType.Studs
	part.RightSurface = Enum.SurfaceType.Studs
	part.Parent = folder

	-- Duvarın ön yüzü (oyuncu +Z tarafından yaklaşır): üstte duvar numarası, altında isim, sonra can çubuğu
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = part

	makeText(gui, UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.2, 0.12), tostring(index))
	makeText(gui, UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.5, 0.14), Layout.stageName(Layout.stageOf(index)))

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.56)
	bar.Size = UDim2.fromScale(0.5, 0.13)
	bar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	bar.BorderSizePixel = 0
	bar.Parent = gui

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0)
	barCorner.Parent = bar

	local barStroke = Instance.new("UIStroke")
	barStroke.Thickness = 3
	barStroke.Color = Color3.new(0, 0, 0)
	barStroke.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill

	-- Can yazısı çubuğun içinde
	local label = makeText(bar, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.8), "")
	label.ZIndex = 2

	local maxHp = Layout.maxHp(index)
	return { part = part, gui = gui, label = label, fill = fill, maxHp = maxHp, hp = maxHp }
end

local function setHp(wall, hp)
	local wasAlive = wall.hp > 0
	wall.hp = hp
	if hp <= 0 then
		wall.part.CanCollide = false
		wall.part.Transparency = 1
		wall.gui.Enabled = false
		if wasAlive and okJuice then
			pcall(Juice.wallBroken, wall.part) -- kırılma patlaması + sarsıntı (yakındaysa)
		end
		return
	end

	local ratio = math.clamp(hp / wall.maxHp, 0, 1)
	wall.part.CanCollide = true
	wall.part.Transparency = 0
	wall.gui.Enabled = true
	wall.label.Text = `{Format.compact(hp)}/{Format.compact(wall.maxHp)}`
	wall.fill.Size = UDim2.fromScale(ratio, 1)
	-- dolu = yeşil, azaldıkça kırmızıya döner
	wall.fill.BackgroundColor3 = Color3.fromHSV(ratio * 0.33, 0.9, 1)
end

-- onProgress(frontier): hayatta olan ilk duvarın sırası (kırılan duvar sayısı = frontier - 1)
function WallClient.init(onProgress)
	local event = ReplicatedStorage:WaitForChild("WallsEvent")

	local folder = Instance.new("Folder")
	folder.Name = "MyWalls"
	folder.Parent = Workspace

	local walls = {}
	for i = 1, cfg.Count do
		walls[i] = createWall(folder, i)
		setHp(walls[i], walls[i].maxHp)
	end

	local function notify()
		local frontier = 1
		while frontier <= cfg.Count and walls[frontier].hp <= 0 do
			frontier += 1
		end
		currentFrontier = frontier
		if onProgress then
			onProgress(frontier)
		end
	end
	notify()

	event.OnClientEvent:Connect(function(action, data)
		if action == "Sync" then
			for i, hp in data do
				setHp(walls[i], hp)
			end
		elseif action == "Update" then
			for _, change in data do
				setHp(walls[change[1]], change[2])
			end
		end
		notify()
	end)

	-- Duvarlar kuruldu, sunucudan güncel canları iste
	event:FireServer("Request")
end

return WallClient
