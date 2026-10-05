-- Duvarlar sadece bu oyuncunun ekranında vardır. Diğer oyuncular senin duvarlarını görmez,
-- yani senin duvarlardan geçtiğini görürler. Canları sunucu tutar, burada sadece gösterilir.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local UIStyle = require(script.Parent.UIStyle)
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

-- Duvarın ön yüzündeki LEGO TUĞLA DESENİ: koyu harç zemini üstünde kayık sıralı yuvarlak köşeli tuğlalar (her sıra bir öncekine göre yarım tuğla kayık).
-- GUI olarak çizilir (ön yüze 3B çıkıntı koymak yazıları deler). 7 sıra, sıra başına 4-5 tuğla = 31 tuğla; her aşamanın deseni bir kez kurulup
-- aynı aşamadaki duvarlara kopyalanır (100 duvar için binlerce nesneyi tek tek kurmamak için). Tuğla rengi ve yüz deseni aşamanın temasından
-- gelir (Config.Wall.Themes: decor = lines, grain, specks, shine, facet, crack, swirl).
local BRICK_ROWS = 7
local patternTemplates = {}

local function darker(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

local function addFrame(parent, props)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	for key, value in props do
		frame[key] = value
	end
	frame.ZIndex = 0
	frame.Parent = parent
	return frame
end

local function addRound(frame, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = frame
end

-- Tuğlanın yüzüne temaya göre küçük süs
local function decorateBrick(brick, theme, random, brickColor)
	local kind = theme.decor
	local accent = theme.accent
	if kind == "lines" then
		-- Defter kağıdı: iki ince mavi çizgi
		for _, y in { 0.34, 0.68 } do
			addFrame(brick, { Position = UDim2.fromScale(0.08, y), Size = UDim2.new(0.84, 0, 0, 2), BackgroundColor3 = Color3.fromRGB(140, 165, 215), BackgroundTransparency = 0.25 })
		end
	elseif kind == "grain" then
		-- Ahşap/karton damarı: iki koyu yatay çizgi, rastgele kayık
		for _, y in { 0.3, 0.66 } do
			addFrame(brick, { Position = UDim2.fromScale(0.05 + random:NextNumber() * 0.2, y), Size = UDim2.new(0.6 + random:NextNumber() * 0.25, 0, 0, 3), BackgroundColor3 = darker(brickColor, 0.72), BackgroundTransparency = 0.2 })
		end
	elseif kind == "specks" then
		-- Taş/kil/bedrock benekleri: üç küçük kare (koyu, koyu, açık)
		for index = 1, 3 do
			local speck = addFrame(brick, {
				Position = UDim2.fromScale(0.1 + random:NextNumber() * 0.75, 0.15 + random:NextNumber() * 0.6),
				Size = UDim2.fromOffset(5 + random:NextInteger(0, 5), 5 + random:NextInteger(0, 5)),
				BackgroundColor3 = if index == 3 then accent else darker(brickColor, 0.7),
				BackgroundTransparency = 0.35,
			})
			addRound(speck, UDim.new(0, 2))
		end
	elseif kind == "shine" then
		-- Metal/cam parıltısı: eğik açık şerit (tuğlanın dışına taşanı kırpılır)
		brick.ClipsDescendants = true
		local strip = addFrame(brick, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.25 + random:NextNumber() * 0.5, 0.5),
			Size = UDim2.new(0.09, 0, 1.8, 0),
			Rotation = 22,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.72,
		})
		addRound(strip, UDim.new(0.5, 0))
	elseif kind == "facet" then
		-- Mücevher yüzü: ortada eğik açık kare + onun içinde daha küçük parlak kare
		local outer = addFrame(brick, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(34, 34),
			Rotation = 45,
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.55,
		})
		addRound(outer, UDim.new(0, 4))
		local inner = addFrame(outer, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.45, 0.45),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.45,
		})
		addRound(inner, UDim.new(0, 3))
	elseif kind == "crack" then
		-- Meteor: içinden kor parlayan iki çatlak
		for index = 1, 2 do
			addFrame(brick, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.3 + random:NextNumber() * 0.4, 0.3 + index * 0.18),
				Size = UDim2.new(0.35 + random:NextNumber() * 0.2, 0, 0, 3),
				Rotation = random:NextInteger(-35, 35),
				BackgroundColor3 = accent,
				BackgroundTransparency = 0.05,
			})
		end
	elseif kind == "swirl" then
		-- Blackhole: iç içe iki mor halka (girdap)
		for index, diameter in { 70, 36 } do
			local ring = addFrame(brick, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(diameter, diameter),
				BackgroundTransparency = 1,
			})
			addRound(ring, UDim.new(0.5, 0))
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = if index == 1 then accent else Color3.new(1, 1, 1)
			stroke.Transparency = if index == 1 then 0.25 else 0.55
			stroke.Parent = ring
		end
	end
end

local function brickPattern(stage, theme)
	local template = patternTemplates[stage]
	if not template then
		local color = theme.color
		-- Harç: tuğlanın koyusu; çok koyu temalarda (Blackhole, Obsidian) tuğla ile ayrışsın diye parıltı rengine doğru açılır
		local luminance = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
		local mortar = if luminance < 0.25 then color:Lerp(theme.accent, 0.22) else darker(color, 0.55)
		template = Instance.new("Frame")
		template.Name = "Bricks"
		template.Size = UDim2.fromScale(1, 1)
		template.BackgroundColor3 = mortar
		template.BorderSizePixel = 0
		template.ZIndex = 0 -- yazıların ve can çubuğunun altında kalsın
		local random = Random.new(stage)
		for row = 0, BRICK_ROWS - 1 do
			local edges = if row % 2 == 0 then { 0, 0.25, 0.5, 0.75, 1 } else { 0, 0.125, 0.375, 0.625, 0.875, 1 }
			for i = 1, #edges - 1 do
				local jitter = 0.95 + random:NextNumber() * 0.1
				local brickColor = Color3.new(math.clamp(color.R * jitter, 0, 1), math.clamp(color.G * jitter, 0, 1), math.clamp(color.B * jitter, 0, 1))
				local brick = Instance.new("Frame")
				brick.Position = UDim2.new(edges[i], 2, row / BRICK_ROWS, 2)
				brick.Size = UDim2.new(edges[i + 1] - edges[i], -4, 1 / BRICK_ROWS, -4)
				brick.BackgroundColor3 = brickColor
				brick.BorderSizePixel = 0
				brick.ZIndex = 0
				addRound(brick, UDim.new(0, 6))
				-- Hafif kabartma: tuğlanın üstü açık, altı biraz koyu
				local bevel = Instance.new("UIGradient")
				bevel.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.84, 0.84, 0.84))
				bevel.Rotation = 90
				bevel.Parent = brick
				decorateBrick(brick, theme, random, brickColor)
				brick.Parent = template
			end
		end
		patternTemplates[stage] = template
	end
	return template:Clone()
end

local function createWall(folder, index)
	local part = Instance.new("Part")
	part.Name = `Wall_{index}`
	part.Anchored = true
	part.Size = Vector3.new(cfg.Width, cfg.Height, cfg.Thickness)
	part.Position = Layout.wallPosition(index)
	part.Material = Enum.Material.Plastic
	local stage = Layout.stageOf(index)
	local theme = Layout.theme(stage)
	part.Color = theme.color
	part.Reflectance = theme.reflect or 0
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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	brickPattern(stage, theme).Parent = gui -- yazılardan ÖNCE kurulur, altta kalır
	gui.Parent = part

	makeText(gui, UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.2, 0.12), tostring(index))
	makeText(gui, UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.5, 0.14), theme.name)

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
	UIStyle.soften(bar, { radius = UDim.new(0.5, 0), strength = 0.3, shine = false })

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	UIStyle.soften(fill, { radius = UDim.new(0.5, 0), strength = 0.3 })

	-- Can yazısı çubuğun içinde
	local label = makeText(bar, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.8), "")
	label.ZIndex = 2

	-- Temaya göre duvarın etrafında dolaşan parçacık (altın parıltısı, kor, girdap); duvar kırılınca kapanır
	local ambient = nil
	if okJuice then
		local ok, result = pcall(Juice.addWallAmbient, part, theme)
		if ok then
			ambient = result
		end
	end

	local maxHp = Layout.maxHp(index)
	return { part = part, gui = gui, label = label, fill = fill, maxHp = maxHp, hp = maxHp, theme = theme, ambient = ambient }
end

local function setHp(wall, hp)
	local wasAlive = wall.hp > 0
	wall.hp = hp
	if hp <= 0 then
		wall.part.CanCollide = false
		wall.part.Transparency = 1
		wall.gui.Enabled = false
		if wall.ambient then
			wall.ambient.Enabled = false
		end
		if wasAlive and okJuice then
			pcall(Juice.wallBroken, wall.part, wall.theme) -- kırılma patlaması + sarsıntı (yakındaysa)
		end
		return
	end

	local ratio = math.clamp(hp / wall.maxHp, 0, 1)
	wall.part.CanCollide = true
	wall.part.Transparency = 0
	wall.gui.Enabled = true
	if wall.ambient then
		wall.ambient.Enabled = true
	end
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
