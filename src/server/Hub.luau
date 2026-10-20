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
-- Bir dünyanın aşama tabelaları (World 2'de 'W2 STAGE N'; koridor originX kadar kayık)
local function buildWorldSigns(folder, W)
	local wall = W.cfg
	local x0 = W.originX
	for stage = 1, W.StageCount do
		local theme = W.theme(stage)
		local firstWall = (stage - 1) * wall.GroupSize + 1
		local z = W.wallZ(firstWall) + wall.Thickness / 2 + 3
		local centerY = wall.CeilingHeight - 4.2
		local banner = Build.block(folder, if W.id == 1 then `StageSign_{stage}` else `StageSign_W{W.id}_{stage}`, Vector3.new(26, 4.6, 0.5), Vector3.new(x0, centerY, z), theme.color:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.SmoothPlastic)
		banner.CanCollide = false
		banner.CanQuery = false
		for _, side in { -1, 1 } do
			local rod = Build.block(folder, "StageSignRod", Vector3.new(0.4, wall.CeilingHeight - (centerY + 2.3), 0.4), Vector3.new(x0 + side * 11, (wall.CeilingHeight + centerY + 2.3) / 2, z), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
			rod.CanCollide = false
			rod.CanQuery = false
		end
		local gui = newGui(banner, Enum.NormalId.Back, 30) -- koridora +Z'den giren oyuncuya bakan yüz
		addLabel(gui, UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.9, 0.46), if W.id == 1 then `STAGE {stage}` else `W{W.id} STAGE {stage}`, Color3.new(1, 1, 1), 4)
		addLabel(gui, UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0.9, 0.34), `{theme.name}  -  Win +{Format.compact(W.reward(stage))}`, theme.accent:Lerp(Color3.new(1, 1, 1), 0.4), 3)
	end
end

local function buildStageSigns(folder)
	for worldId = 1, Layout.worldCount do
		buildWorldSigns(folder, Layout.world(worldId))
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
