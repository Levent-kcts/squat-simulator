-- Lobinin/koridorun canlılığı: her aşamanın başında asılı AŞAMA TABELALARI. Kodla kurulur (Studio'da elle model yok) ve sadece görseldir: oyun kuralları PlayerStats'tadır.
-- Lobideki GÖREV PANOSU ve PET FUSION MAKİNESİ sahibinin isteğiyle KALDIRILDI (görevler sadece sağ üstteki 📜 düğmesinden, pet birleştirme Pets menüsünden); geri ekleme.
-- Koridorda ve lobide ışık paneli YOK kuralı korunur.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Format = require(Shared:WaitForChild("Format"))
local Build = require(script.Parent.Build)

local Hub = {}

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
	for name, builder in { StageSigns = buildStageSigns } do
		local ok, err = pcall(builder, folder)
		if not ok then
			warn(`[Hub] {name} could not be built: {err}`)
		end
	end
end

return Hub
