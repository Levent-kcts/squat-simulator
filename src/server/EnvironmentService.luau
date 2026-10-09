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
local SEAM_COLOR = Color3.fromRGB(104, 112, 168) -- lego plakaların arasındaki koyu derz
local PLATE_LIGHT = Color3.fromRGB(176, 184, 228)
local PLATE_DARK = Color3.fromRGB(148, 157, 211)
local BRICK_COLORS = {
	Color3.fromRGB(240, 92, 102), -- kırmızı
	Color3.fromRGB(92, 146, 242), -- mavi
	Color3.fromRGB(252, 206, 72), -- sarı
	Color3.fromRGB(102, 208, 132), -- yeşil
	Color3.fromRGB(252, 152, 72), -- turuncu
	Color3.fromRGB(172, 114, 236), -- mor
}

local EnvironmentService = {}

function EnvironmentService.init()
	-- Kapalı mekan: tavan güneşi keser, aydınlığı ORTAM ışığı verir. Karanlık/mavi havayı kaldırmak için ortam ışığı yüksek ve pozlama nötr;
	-- koridorda ve Win odalarında ayrıca ışık paneli YOK (sahibi istemedi), orası da ortam ışığıyla aydınlıktır.
	local light = Config.Lighting
	Lighting.ClockTime = 14
	Lighting.Brightness = light.Brightness
	Lighting.ExposureCompensation = light.Exposure
	Lighting.Ambient = light.Ambient
	Lighting.OutdoorAmbient = light.Ambient
	Lighting.GlobalShadows = true

	-- Işık efekti: parıltı (bloom) ve hafif renk canlılığı. Efektler Lighting'de durur ve tüm oyunculara görünür; eskileri silinir
	for _, name in { "GameBloom", "GameColor" } do
		local old = Lighting:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if light.Bloom.Enabled then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "GameBloom"
		bloom.Intensity = light.Bloom.Intensity
		bloom.Size = light.Bloom.Size
		bloom.Threshold = light.Bloom.Threshold
		bloom.Parent = Lighting
	end
	if light.Color.Saturation ~= 0 or light.Color.Contrast ~= 0 then
		local color = Instance.new("ColorCorrectionEffect")
		color.Name = "GameColor"
		color.Saturation = light.Color.Saturation
		color.Contrast = light.Color.Contrast
		color.Parent = Lighting
	end

	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = Workspace

	local widthLeft = Config.Lobby.WidthLeft -- spawn'dan sol duvara
	local widthRight = Config.Lobby.WidthRight -- spawn'dan sağ duvara (antrenman alanı için geniş; salon simetrik değil)
	local hallWidth = widthLeft + widthRight
	local centerX = (widthRight - widthLeft) / 2 -- salonun orta noktası (spawn x = 0'da)
	local back = Config.Lobby.BackZ
	local zFront = Layout.ZFront
	local length = back - zFront
	local centerZ = (back + zFront) / 2
	local ceiling = Config.Lobby.Height -- salonun yüksekliği
	local corridorCeiling = cfg.CeilingHeight
	local floorTop = Layout.FloorTop

	-- Zemin: referanstaki gibi LEGO PLAKALAR. Altta koyu bir levha (derz rengi), üstünde 12 x 13 plaka; her plakanın üst yüzünde lego çıkıntıları
	-- (Plastic + Studs) vardır, plakalar dama gibi iki tonda ve her biri hafif farklı parlaklıktadır, aralarında ince koyu derz kalır.
	-- Plakaların üstü zemin seviyesindedir (floorTop), levha 0.1 altta durur; üstündeki raf/ped taşları 0.4+ kalın olduğu için çıkıntılar onları delmez.
	Build.block(
		folder,
		"LobbyFloor",
		Vector3.new(hallWidth, 1, length),
		Vector3.new(centerX, floorTop - 0.6, centerZ),
		SEAM_COLOR,
		Enum.Material.SmoothPlastic
	)

	local columns = math.max(12, math.floor(hallWidth / 10.33 + 0.5)) -- plaka boyu salon genişlese de ~10.3 stud kalır (eskiden 124 / 12)
	local rows = 13
	local cellWidth = hallWidth / columns
	local cellLength = length / rows
	local shadeRandom = Random.new(11)
	for row = 0, rows - 1 do
		for column = 0, columns - 1 do
			local base = if (row + column) % 2 == 0 then PLATE_DARK else PLATE_LIGHT
			local shade = 1 + (shadeRandom:NextNumber() - 0.5) * 0.07
			local plate = Build.block(
				folder,
				"Plate",
				Vector3.new(cellWidth - 0.3, 0.6, cellLength - 0.3),
				Vector3.new(-widthLeft + cellWidth * (column + 0.5), floorTop - 0.3, back - cellLength * (row + 0.5)),
				Color3.new(math.clamp(base.R * shade, 0, 1), math.clamp(base.G * shade, 0, 1), math.clamp(base.B * shade, 0, 1)),
				Enum.Material.Plastic
			)
			plate.TopSurface = Enum.SurfaceType.Studs
		end
	end

	-- Yan duvarlar ve arka duvar
	for _, side in { -1, 1 } do
		Build.block(
			folder,
			"LobbySide",
			Vector3.new(1, ceiling, length),
			Vector3.new(if side < 0 then -widthLeft - 0.5 else widthRight + 0.5, ceiling / 2, centerZ),
			WALL_COLOR,
			Enum.Material.Plastic,
			true
		)
	end
	Build.block(
		folder,
		"LobbyBack",
		Vector3.new(hallWidth + 2, ceiling, 1),
		Vector3.new(centerX, ceiling / 2, back + 0.5),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)

	-- Koridor girişi olan duvar: ortada koridor genişliğinde boşluk bırakılır
	local openingHalf = (cfg.Width + 2) / 2
	for _, side in { -1, 1 } do
		local segmentWidth = (if side < 0 then widthLeft else widthRight) - openingHalf
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
		Vector3.new(hallWidth + 2, 1, length + 1),
		Vector3.new(centerX, ceiling + 0.5, centerZ),
		WALL_COLOR,
		Enum.Material.Plastic,
		true
	)
	-- Tavan ışık panelleri: salona oranla küçük (7x7), seyrek ızgara (salon 124 geniş iken 4 sütun x 4 sıra = 16 adet; genişleyince yanlara sütun eklenir, 28 stud aralık)
	local lightColumns = {} -- salonun orta noktasının (centerX) iki yanında 28 stud aralıklı sütunlar
	local lightOffset = 14
	while lightOffset < hallWidth / 2 - 14 do
		table.insert(lightColumns, centerX - lightOffset)
		table.insert(lightColumns, centerX + lightOffset)
		lightOffset += 28
	end
	local lightRows = {}
	local z = back - 18
	while z > zFront + 8 do
		table.insert(lightRows, z)
		for _, x in lightColumns do
			Build.ceilingLight(
				folder,
				"LobbyLight",
				Vector3.new(light.PanelSize[1], 0.5, light.PanelSize[2]),
				Vector3.new(x, ceiling - 0.25, z),
				40,
				light.PanelColor,
				light.PanelLightBrightness
			)
			if light.PanelGlow.Enabled then
				-- Hale, damga çıkıntılarının altında (tavan - 0.25) ince bir katman olarak durur
				Build.ceilingHalo(folder, "LobbyLightHalo", Vector3.new(x, ceiling - 0.25, z), light.PanelGlow.Size, light.PanelGlow.Layers, light.PanelGlow.Alpha)
			end
		end
		z -= 32
	end

	-- LEGO BLOK KULELERİ: koridor girişinin iki yanında, ön duvara yakın. Raflar (sol duvarda x < -38) ve antrenman alanı
	-- (sağ duvarda x > 18, z > -39) bu köşelere uzanmaz; spawn'dan koridora giden yol (|x| < 17) da açık kalır.
	-- Sol/sağ yansıma değil, hafif farklı renk ve yükseklik: oyuncu 'elle dizilmiş' gibi görsün.
	local function brick(cx, baseY, cz, sx, sy, sz, color, yaw)
		local part = Build.block(folder, "LegoBrick", Vector3.new(sx, sy, sz), Vector3.new(cx, baseY + sy / 2, cz), color, Enum.Material.Plastic)
		part.TopSurface = Enum.SurfaceType.Studs
		part.CFrame = CFrame.new(cx, baseY + sy / 2, cz) * CFrame.Angles(0, yaw, 0)
		return part
	end
	-- Kule: her kat bir öncekine göre 90 derece döner (lego gibi üst üste kenetlenir), kule hafif kayık durur
	local function tower(cx, cz, layers, colorOffset, wobble)
		for layer = 1, layers do
			local yaw = if layer % 2 == 0 then math.pi / 2 else 0
			local color = BRICK_COLORS[(colorOffset + layer - 2) % #BRICK_COLORS + 1]
			brick(cx + wobble * (layer % 2), floorTop + (layer - 1) * 3, cz, 8, 3, 4, color, yaw)
		end
	end
	for side = -1, 1, 2 do
		local colorShift = if side < 0 then 0 else 3
		tower(side * 23.5, -58, 4, colorShift + 1, 0.4 * side)
		tower(side * 33, -59, 2, colorShift + 3, -0.3 * side)
		-- yerdeki tek parça
		brick(side * 29, floorTop, -51.5, 4, 3, 4, BRICK_COLORS[(colorShift + 4) % #BRICK_COLORS + 1], 0.45 * side)
	end

	-- SAĞ ARKA KÖŞE (x > 56, z 36-64) ve çarkın arkası: çarkın eski yeri. Çark yumurta standının yanına taşındı (sahibi 'uzak kısma legolar falan olsun' dedi): köşe lego kuleleri ve tek parçalarla dolar.
	-- Antrenman alanı z = 31'de biter, çark x <= 60 olduğu için çakışma yok. Konumlar sağ duvara göre ayarlanır (widthRight).
	tower(widthRight - 13, 56, 5, 2, 0.5)
	tower(widthRight - 24, 60, 3, 5, -0.4)
	tower(widthRight - 9, 44, 2, 7, 0.3)
	brick(widthRight - 20, floorTop, 47, 4, 3, 4, BRICK_COLORS[(5) % #BRICK_COLORS + 1], 0.5)
	brick(widthRight - 29, floorTop, 52, 4, 3, 4, BRICK_COLORS[(1) % #BRICK_COLORS + 1], -0.3)
	brick(widthRight - 6, floorTop, 37, 4, 3, 4, BRICK_COLORS[(3) % #BRICK_COLORS + 1], 0.2)
	-- Çarkın ARKASI ve yanı ('köşeye arkasını doldur'): çark (46, 45), kaidesi 20 stud geniş ve merkeze doğru 45 derece döner. Parçalar birbirine ve çarka GİRMEZ (sahibi 'kesişmesin' dedi): her parça 8x4 (dönen katlar 4x8),
	-- aralarında en az 1.5 stud boşluk var (konumlar `python tools/lego_overlap.py` denetimiyle seçildi, parça eklersen/taşırsan orayı da güncelle; yeni parça eklersen kule katlarının dönünce 8 stud derinleştiğini ve çark kaidesini unutma). Kuleler arka duvara (z 65) girmez.
	tower(62, 59, 4, 3, -0.3)
	tower(51.5, 60, 3, 1, 0.4)
	tower(42.5, 60, 2, 6, -0.2)
	tower(66, 41, 2, 4, 0.2)
	brick(61, floorTop, 48, 4, 3, 4, BRICK_COLORS[(0) % #BRICK_COLORS + 1], 0.3)
	brick(59, floorTop, 37, 4, 3, 4, BRICK_COLORS[(2) % #BRICK_COLORS + 1], -0.25)
	brick(53.5, floorTop, 50, 4, 3, 4, BRICK_COLORS[(4) % #BRICK_COLORS + 1], 0.4)

	-- (Arka duvardaki 'SQUAT SIMULATOR' oyun adı tabelası sahibinin isteğiyle KALDIRILDI: Worlds kemerinin üstünde kalabalık duruyordu, geri ekleme.)

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

	-- Duvar derzleri, sütunlar, kirişli tavan, yol kenarları (sadece görünüm): hata verirse lobi yine kurulu kalır
	local okDetail, LobbyDetail = pcall(require, script.Parent.LobbyDetail)
	if okDetail then
		local built, err = pcall(LobbyDetail.init, {
			folder = folder,
			widthLeft = widthLeft,
			widthRight = widthRight,
			back = back,
			zFront = zFront,
			ceiling = ceiling,
			corridorCeiling = corridorCeiling,
			openingHalf = openingHalf,
			floorTop = floorTop,
			lightColumns = lightColumns,
			lightRows = lightRows,
		})
		if not built then
			warn(`[Environment] LobbyDetail failed: {err}`)
		end
	else
		warn(`[Environment] Could not load LobbyDetail: {LobbyDetail}`)
	end
end

return EnvironmentService
