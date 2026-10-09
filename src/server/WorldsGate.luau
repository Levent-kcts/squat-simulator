-- Lobinin ARKA duvarındaki WORLDS GEÇİDİ (sahibi referans görseli verip 'arkadaki gibi Worlds yazan bir geçit koy, üstüne coming soon yazsın' dedi):
-- yumurta standının 3. katındaki terasın (Config.Worlds.TerraceHeight) üstünde, duvarın tam ortasında parlak taş kemer; üstünde cyan 'WORLDS',
-- parlayan yüzünde 'COMING SOON'. Yeni dünya gelene kadar içi kapalıdır (arkası duvar). Her şey kodla kurulur, Studio'da elle model gerekmez.
-- Yerel eksen: yumurta standı gibi arka duvar çerçevesi (Shelf.backWallFrame): yerel -Z salonun ortasına (izleyiciye) bakar, yerel X geçidin genişliği, Y yukarı.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Build = require(script.Parent.Build)
local Shelf = require(script.Parent.Shelf)

local WorldsGate = {}

-- PARLAKLIK (2026-10-09): ilk sürümde yüz neredeyse beyaz Neon, taşlar açık beyazdı ve ışık geniş yayılıyordu: kemer ekranı boğdu, sahibi 'çok parlak' dedi. Yüz artık orta tonda mavi Neon (rengi koyu = az parlak),
-- taşlar bir kademe koyu, ışık zayıf ve kısa menzilli. Tekrar açma: önce sahibine sor.
local STONE_LIGHT = Color3.fromRGB(205, 213, 236) -- taş çerçevenin açık tonu
local STONE_SHADE = Color3.fromRGB(176, 187, 220) -- bir koyu ton (taşlar dönüşümlü, referanstaki kemer taşları gibi)
local GLOW_COLOR = Color3.fromRGB(105, 150, 225) -- parlayan yüz: orta ton mavi (Neon parlak görünür, açık renk göz alır)
local TITLE_COLOR = Color3.fromRGB(0, 205, 255) -- 'WORLDS' yazısı, referanstaki gibi cyan
local SOON_COLOR = Color3.fromRGB(255, 205, 60)
local OUTLINE_COLOR = Color3.fromRGB(20, 25, 50)

local ARC_STONES = 15 -- yarım dairedeki taş sayısı
local GLOW_SLABS = 16 -- yarım dairenin dolgusu bu kadar yatay dilimle çizilir

function WorldsGate.init()
	local cfg = Config.Worlds
	if not cfg or not cfg.Enabled then
		return
	end

	local floorTop = Layout.FloorTop
	local frame = Shelf.backWallFrame()
	local terraceTop = floorTop + cfg.TerraceHeight

	local folder = Instance.new("Folder")
	folder.Name = "WorldsGate"
	folder.Parent = Workspace

	local radius = cfg.ArchWidth / 2
	local straight = cfg.ArchStraight
	local thickness = cfg.FrameThickness
	local stoneDepth = 1.6
	local stoneZ = -(0.2 + stoneDepth / 2) -- duvardaki çıkıntıların (~0.2) önünde

	-- Dünya konumu için yerel (x, terastan yükseklik, z) -> CFrame
	local function place(part, x, height, z, roll)
		part.CFrame = frame * CFrame.new(x, terraceTop + height, z) * CFrame.Angles(0, 0, roll or 0)
		return part
	end

	-- ---------- Parlayan yüz: düz kısım + yarım daire (yatay dilimlerle) ----------
	local function glowPart(name, size, x, height)
		local part = Build.block(folder, name, size, Vector3.zero, GLOW_COLOR, Enum.Material.Neon)
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		place(part, x, height, -0.15)
		return part
	end
	local glow = glowPart("GateGlow", Vector3.new(cfg.ArchWidth, straight, 0.3), 0, straight / 2)
	local sliceHeight = radius / GLOW_SLABS
	for index = 1, GLOW_SLABS do
		local lowY = (index - 1) * sliceHeight
		-- Dilimin genişliği alt kenardaki daire genişliğidir (köşeler taş çerçevenin arkasında kalır, aralık görünmez)
		local width = 2 * math.sqrt(math.max(0, radius * radius - lowY * lowY))
		glowPart(`GateGlowArc_{index}`, Vector3.new(width, sliceHeight + 0.02, 0.3), 0, straight + lowY + sliceHeight / 2)
	end

	-- Parlayan yüzün ışığı ve yukarı süzülen parıltılar: geçit 'canlı' görünür
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 185, 245)
	light.Range = 14
	light.Brightness = 0.35
	light.Shadows = false
	light.Parent = glow
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	sparkles.LightEmission = 0.5
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Lifetime = NumberRange.new(1.5, 2.6)
	sparkles.Rate = 4
	sparkles.Speed = NumberRange.new(1, 2.5)
	sparkles.SpreadAngle = Vector2.new(30, 30)
	sparkles.Parent = glow

	-- ---------- Taş çerçeve: iki yan sütun (kat kat taş) + yarım daire kemer ----------
	local function stone(name, size, x, height, roll, shade, depthExtra)
		local part = Build.block(
			folder,
			name,
			Vector3.new(size.X, size.Y, size.Z + depthExtra),
			Vector3.zero,
			if shade then STONE_SHADE else STONE_LIGHT,
			Enum.Material.Plastic,
			true
		)
		place(part, x, height, stoneZ - depthExtra / 2, roll)
		return part
	end
	-- Yan sütunlar: düz kısmın yüksekliğince, alternatif çıkıntılı katlar (komşu taşların yüzleri aynı düzlemde olmasın: titreme olmaz)
	local courses = math.max(2, math.floor(straight / 2 + 0.5))
	local courseHeight = straight / courses
	for _, side in { -1, 1 } do
		for course = 1, courses do
			local odd = course % 2 == 1
			stone(
				`GateColumn_{side}_{course}`,
				Vector3.new(thickness, courseHeight, stoneDepth),
				side * (radius + thickness / 2),
				(course - 0.5) * courseHeight,
				0,
				odd,
				if odd then 0.3 else 0
			)
		end
	end
	-- Kemer: yarım daire boyunca teğet dizilen taşlar; taş boyu dış yayın uzunluğundan biraz büyük (yan yana bitişik dururlar)
	local stoneLength = math.pi * (radius + thickness) / ARC_STONES * 1.08
	for index = 1, ARC_STONES do
		local angle = (index - 0.5) * math.pi / ARC_STONES -- 0 = sağ uç, pi = sol uç
		local ring = radius + thickness / 2
		local odd = index % 2 == 1
		stone(
			`GateArch_{index}`,
			Vector3.new(stoneLength, thickness, stoneDepth),
			ring * math.cos(angle),
			straight + ring * math.sin(angle),
			angle - math.pi / 2, -- yerel Y ekseni dışarı (yarıçap yönü) baksın
			odd,
			if odd then 0.3 else 0
		)
	end
	-- Anahtar taşı: kemerin tepesine büyükçe bir taş
	stone("GateKeystone", Vector3.new(thickness * 0.9, thickness * 1.2, stoneDepth), 0, straight + radius + thickness * 0.6, 0, false, 0.6)

	-- ---------- Yazılar ----------
	local function textPlate(name, size, x, height, texts)
		local plate = Build.block(folder, name, size, Vector3.zero, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		plate.Transparency = 1
		plate.CanCollide = false
		plate.CanQuery = false
		plate.CastShadow = false
		place(plate, x, height, stoneZ - 0.4)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front -- salonun ortasına (izleyiciye) bakan yüz
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = plate
		for _, def in texts do
			local label = Instance.new("TextLabel")
			label.Name = def.name
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = def.position
			label.Size = def.size
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.Text = def.text
			label.TextColor3 = def.color
			label.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = def.stroke
			stroke.Color = def.strokeColor or OUTLINE_COLOR
			stroke.Parent = label
		end
		return plate
	end

	-- Kemerin üstünde cyan 'WORLDS' (referanstaki gibi, kalın koyu kenarlı)
	local archTop = straight + radius + thickness
	textPlate("GateTitle", Vector3.new(22, 5.2, 0.2), 0, archTop + 3.6, {
		{ name = "Title", text = cfg.Title, position = UDim2.fromScale(0.5, 0.5), size = UDim2.fromScale(1, 1), color = TITLE_COLOR, stroke = 6 },
	})
	-- Parlayan yüzün ÜST kısmında (kemerin yuvarlak bölümünde) 'COMING SOON' ve altında kısa not: alttaki yumurtalar önde durduğu için yazı onların arkasında kalmasın
	textPlate("GateSoon", Vector3.new(cfg.ArchWidth - 1, 6, 0.2), 0, straight + 0.5, {
		{ name = "Soon", text = cfg.SoonText, position = UDim2.fromScale(0.5, 0.38), size = UDim2.fromScale(0.96, 0.4), color = SOON_COLOR, stroke = 5, strokeColor = Color3.fromRGB(70, 35, 0) },
		{ name = "Note", text = "New worlds are on the way!", position = UDim2.fromScale(0.5, 0.7), size = UDim2.fromScale(0.86, 0.13), color = Color3.new(1, 1, 1), stroke = 3 },
	})
end

return WorldsGate
