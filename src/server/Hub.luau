-- Lobinin canlılığı: sağ duvarın arka ucundaki GÖREV PANOSU ve PET FUSION MAKİNESİ, koridorda her aşamanın başında asılı AŞAMA TABELALARI.
-- Hepsi kodla kurulur (Studio'da elle model yok) ve sadece görsel/etkileşim noktasıdır: oyun kuralları PlayerStats'tadır. Koridorda ve lobide ışık paneli YOK kuralı korunur:
-- makinenin içindeki küçük ışık hariç yeni PointLight yok, parlak (Neon) yüzeyler kısıktır. Pencereleri istemci açar: ProximityPrompt'ların 'Panel' özniteliği 'Quests' / 'Fusion' (init.client).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Format = require(Shared:WaitForChild("Format"))
local Build = require(script.Parent.Build)

local Hub = {}

local HALF = Config.Lobby.HalfWidth
local FLOOR = Layout.FloorTop

-- Basınca (E) ilgili pencereyi açan etkileşim noktası; pencereyi istemci 'Panel' özniteliğine bakıp açar
local function addPrompt(parent, panelName, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Panel", panelName)
	prompt.Parent = parent
	return prompt
end

-- SurfaceGui'ye ortalanmış, kalın siyah kenarlı yazı ekler
local function addLabel(gui, position, size, text, color, strokeThickness)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = Color3.fromRGB(35, 20, 5)
	stroke.Parent = label
	return label
end

local function newGui(part, face, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 30
	gui.LightInfluence = 0
	gui.Parent = part
	return gui
end

-- ---------------------------------------------------------------------------------------------
-- GÖREV PANOSU: sağ duvara yaslı tahta pano, üstünde kağıt notlar; E ile günlük görevler açılır
-- ---------------------------------------------------------------------------------------------
local function buildQuestBoard(folder)
	local z = 30
	local boardX = HALF - 0.9 -- duvarın iç yüzüne yaslı
	local centerY = FLOOR + 10.5
	local board = Build.block(folder, "QuestBoard", Vector3.new(1.2, 14, 20), Vector3.new(boardX, centerY, z), Color3.fromRGB(160, 108, 60), Enum.Material.WoodPlanks)
	-- Çerçeve ve ayaklar
	local frameColor = Color3.fromRGB(95, 60, 32)
	Build.block(folder, "QuestBoardTop", Vector3.new(1.8, 1.2, 21.6), Vector3.new(boardX - 0.3, centerY + 7.3, z), frameColor, Enum.Material.WoodPlanks)
	Build.block(folder, "QuestBoardBottom", Vector3.new(1.8, 1.2, 21.6), Vector3.new(boardX - 0.3, centerY - 7.3, z), frameColor, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		Build.block(folder, "QuestBoardSide", Vector3.new(1.8, 14, 1.2), Vector3.new(boardX - 0.3, centerY, z + side * 10.4), frameColor, Enum.Material.WoodPlanks)
		Build.block(folder, "QuestBoardLeg", Vector3.new(1.4, centerY - 7.3 - FLOOR, 1.4), Vector3.new(boardX - 0.2, FLOOR + (centerY - 7.3 - FLOOR) / 2, z + side * 8), frameColor, Enum.Material.WoodPlanks)
	end

	local gui = newGui(board, Enum.NormalId.Left, 30)
	addLabel(gui, UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.92, 0.17), "DAILY QUESTS", Color3.fromRGB(255, 214, 60), 5)
	addLabel(gui, UDim2.fromScale(0.5, 0.27), UDim2.fromScale(0.84, 0.08), "New quests every day!", Color3.new(1, 1, 1), 3)
	-- Kağıt notlar (süs): hafif eğik, farklı renkte
	local notes = {
		{ 0.07, "🧱 Break walls", Color3.fromRGB(255, 240, 190), -4 },
		{ 0.37, "🥚 Hatch eggs", Color3.fromRGB(205, 240, 255), 3 },
		{ 0.67, "🦵 Squat & kick", Color3.fromRGB(255, 215, 225), -2 },
	}
	for _, note in notes do
		local paper = Instance.new("Frame")
		paper.Position = UDim2.fromScale(note[1], 0.4)
		paper.Size = UDim2.fromScale(0.26, 0.5)
		paper.Rotation = note[4]
		paper.BackgroundColor3 = note[3]
		paper.BorderSizePixel = 0
		paper.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = paper
		local pin = Instance.new("Frame")
		pin.AnchorPoint = Vector2.new(0.5, 0)
		pin.Position = UDim2.fromScale(0.5, 0.03)
		pin.Size = UDim2.fromOffset(16, 16)
		pin.BackgroundColor3 = Color3.fromRGB(225, 50, 60)
		pin.BorderSizePixel = 0
		pin.Parent = paper
		local pinCorner = Instance.new("UICorner")
		pinCorner.CornerRadius = UDim.new(1, 0)
		pinCorner.Parent = pin
		local text = Instance.new("TextLabel")
		text.AnchorPoint = Vector2.new(0.5, 0.5)
		text.Position = UDim2.fromScale(0.5, 0.55)
		text.Size = UDim2.fromScale(0.86, 0.5)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextWrapped = true
		text.Text = note[2]
		text.TextColor3 = Color3.fromRGB(70, 45, 20)
		text.Parent = paper
	end
	addPrompt(board, "Quests", "Open", "Daily Quests")
end

-- ---------------------------------------------------------------------------------------------
-- PET FUSION MAKİNESİ: altın direkli, camlı kubbe ve içinde parıldayan çekirdek; E ile birleştirme penceresi açılır
-- ---------------------------------------------------------------------------------------------
local function buildFusionMachine(folder)
	local cx, cz = HALF - 14, 49
	local gold = Color3.fromRGB(235, 185, 60)

	-- Yatay disk: silindirin ekseni yerel X'tedir, Z çevresinde 90 derece döndürülünce dikey olur
	local function disc(name, height, diameter, y, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Cylinder
		part.Anchored = true
		part.Size = Vector3.new(height, diameter, diameter)
		part.CFrame = CFrame.new(cx, y, cz) * CFrame.Angles(0, 0, math.pi / 2)
		part.Color = color
		part.Material = material
		part.Parent = folder
		return part
	end

	local base = disc("FusionBase", 1.4, 16, FLOOR + 0.7, Color3.fromRGB(88, 96, 150), Enum.Material.Plastic)
	local glow = disc("FusionGlow", 0.3, 11.5, FLOOR + 1.5, Color3.fromRGB(105, 55, 175), Enum.Material.Neon)
	glow.CanCollide = false
	disc("FusionRing", 0.9, 14, FLOOR + 11, gold, Enum.Material.Plastic).CanCollide = false

	for index = 0, 2 do
		local angle = math.rad(90 + index * 120)
		local pillar = Build.block(
			folder,
			"FusionPillar",
			Vector3.new(1.6, 10, 1.6),
			Vector3.new(cx + math.cos(angle) * 6.4, FLOOR + 6.3, cz + math.sin(angle) * 6.4),
			gold,
			Enum.Material.Plastic,
			true
		)
		pillar.CanCollide = false
	end

	-- Cam kubbe ve parlayan çekirdek
	local dome = Instance.new("Part")
	dome.Name = "FusionDome"
	dome.Shape = Enum.PartType.Ball
	dome.Anchored = true
	dome.CanCollide = false
	dome.Size = Vector3.new(10, 10, 10)
	dome.Position = Vector3.new(cx, FLOOR + 6.6, cz)
	dome.Material = Enum.Material.Glass
	dome.Transparency = 0.55
	dome.Color = Color3.fromRGB(210, 190, 255)
	dome.Parent = folder

	local core = Instance.new("Part")
	core.Name = "FusionCore"
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = false
	core.Size = Vector3.new(3.4, 3.4, 3.4)
	core.Position = Vector3.new(cx, FLOOR + 6.6, cz)
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(150, 85, 235)
	core.Parent = folder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(190, 130, 255)
	light.Brightness = 0.6
	light.Range = 14
	light.Shadows = false
	light.Parent = core
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 160, 255), Color3.fromRGB(150, 220, 255))
	sparkles.LightEmission = 0.8
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Lifetime = NumberRange.new(1.2, 2.2)
	sparkles.Rate = 9
	sparkles.Speed = NumberRange.new(1, 3.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = core

	-- Tabela: lobinin ortasına bakan yüzde ad ve açıklama
	local sign = Build.block(folder, "FusionSign", Vector3.new(0.6, 4.6, 18), Vector3.new(cx, FLOOR + 15, cz), Color3.fromRGB(70, 45, 130), Enum.Material.SmoothPlastic)
	sign.CanCollide = false
	local gui = newGui(sign, Enum.NormalId.Left, 30)
	addLabel(gui, UDim2.fromScale(0.5, 0.34), UDim2.fromScale(0.94, 0.5), "PET FUSION", Color3.fromRGB(255, 225, 120), 5)
	addLabel(gui, UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.94, 0.26), `{Config.PetFusion.Cost} same pets = 1 BIGGER pet!`, Color3.new(1, 1, 1), 3)

	addPrompt(base, "Fusion", "Fuse Pets", "Pet Fusion Machine")
end

-- ---------------------------------------------------------------------------------------------
-- AŞAMA TABELALARI: her aşamanın ilk duvarının hemen önünde, tavandan asılı; aşama numarası, adı ve Win ödülü
-- ---------------------------------------------------------------------------------------------
local function buildStageSigns(folder)
	local wall = Config.Wall
	for stage = 1, Layout.StageCount do
		local theme = Layout.theme(stage)
		local firstWall = (stage - 1) * wall.GroupSize + 1
		local z = Layout.wallZ(firstWall) + wall.Thickness / 2 + 3
		local centerY = wall.CeilingHeight - 4.2
		local banner = Build.block(folder, `StageSign_{stage}`, Vector3.new(26, 4.6, 0.5), Vector3.new(0, centerY, z), theme.color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.SmoothPlastic)
		banner.CanCollide = false
		banner.CanQuery = false
		for _, side in { -1, 1 } do
			local rod = Build.block(folder, "StageSignRod", Vector3.new(0.4, wall.CeilingHeight - (centerY + 2.3), 0.4), Vector3.new(side * 11, (wall.CeilingHeight + centerY + 2.3) / 2, z), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
			rod.CanCollide = false
			rod.CanQuery = false
		end
		local gui = newGui(banner, Enum.NormalId.Back, 30) -- koridora +Z'den giren oyuncuya bakan yüz
		addLabel(gui, UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.9, 0.46), `STAGE {stage}`, Color3.new(1, 1, 1), 4)
		addLabel(gui, UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0.9, 0.34), `{theme.name}  -  Win +{Format.compact(Layout.reward(stage))}`, theme.accent:Lerp(Color3.new(1, 1, 1), 0.4), 3)
	end
end

function Hub.init()
	local folder = Instance.new("Folder")
	folder.Name = "Hub"
	folder.Parent = Workspace
	-- Her parça kendi korumasıyla kurulur: biri hata verirse diğerleri yine gelir
	for name, builder in { QuestBoard = buildQuestBoard, FusionMachine = buildFusionMachine, StageSigns = buildStageSigns } do
		local ok, err = pcall(builder, folder)
		if not ok then
			warn(`[Hub] {name} could not be built: {err}`)
		end
	end
end

return Hub
