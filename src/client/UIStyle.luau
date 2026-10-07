-- Arayüz yumuşatma yardımcıları (referans oyundaki gibi): üstten alta renk geçişi, üstte parlak şerit, yuvarlak köşe, ince kenar,
-- ve pet simgesi (Blender pet modeli varsa 3B ViewportFrame, yoksa sevimli yüz). Sadece görseldir; oyun mantığına dokunmaz. Her modül kendi düz Frame/TextButton'unu yaratır,
-- sonra UIStyle.soften(nesne, ayarlar) ile yumuşatır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))

local UIStyle = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

function UIStyle.lighten(color, amount)
	return color:Lerp(WHITE, amount)
end

function UIStyle.darken(color, amount)
	return color:Lerp(BLACK, amount)
end

-- Köşeyi yuvarlar (varsa mevcut UICorner'ı günceller). radius: piksel (sayı) ya da UDim
function UIStyle.round(obj, radius)
	local corner = obj:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = obj
	end
	corner.CornerRadius = if typeof(radius) == "UDim" then radius else UDim.new(0, radius)
	return corner
end

-- ayarlar (hepsi isteğe bağlı):
--   radius       köşe yuvarlaklığı (piksel ya da UDim; varsayılan 8)
--   stroke       dış kenar kalınlığı (verilmezse mevcut kenara dokunulmaz); strokeColor: kenar rengi (varsayılan siyah)
--   strength     alt kısmın ne kadar koyulaşacağı, 0..1 (varsayılan 0.2); gradient = false ise geçiş eklenmez
--   shine = false  üstteki parlak şeridi kapatır (daire/hap şeklindeki nesnelerde kapat)
local function softenUnsafe(obj, opts)
	opts = opts or {}
	local radius = opts.radius or 8
	UIStyle.round(obj, radius)

	if opts.stroke then
		local stroke = obj:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Parent = obj
		end
		stroke.Thickness = opts.stroke
		stroke.Color = opts.strokeColor or BLACK
	end

	if obj.BackgroundTransparency >= 1 then
		return obj
	end

	-- Üstten alta: üstte asıl renk, altta biraz koyu (BackgroundColor3 ile çarpılır; renk sonradan değişse de geçiş çalışır)
	if opts.gradient ~= false then
		local gradient = obj:FindFirstChildOfClass("UIGradient")
		if not gradient then
			gradient = Instance.new("UIGradient")
			gradient.Parent = obj
		end
		local strength = opts.strength or 0.2
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new(WHITE, Color3.new(1 - strength, 1 - strength, 1 - strength * 0.75))
	end

	-- Üstte yumuşak parlak şerit (içeriğin altında kalsın diye ZIndex 0)
	if opts.shine ~= false and not obj:FindFirstChild("Shine") then
		local shine = Instance.new("Frame")
		shine.Name = "Shine"
		shine.AnchorPoint = Vector2.new(0.5, 0)
		shine.Position = UDim2.new(0.5, 0, 0, 3)
		shine.Size = UDim2.new(1, -8, 0.4, 0)
		shine.BackgroundColor3 = WHITE
		shine.BorderSizePixel = 0
		shine.ZIndex = 0
		shine.Active = false
		local shineCorner = Instance.new("UICorner")
		if typeof(radius) == "UDim" then
			shineCorner.CornerRadius = radius
		else
			shineCorner.CornerRadius = UDim.new(0, math.max(2, radius - 2))
		end
		shineCorner.Parent = shine
		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = shine
		shine.Parent = obj
	end
	return obj
end

-- Yumuşatma bir şey yüzünden hata verirse düz haliyle kalır, oyun arayüzü bozulmaz
function UIStyle.soften(obj, opts)
	local ok, err = pcall(softenUnsafe, obj, opts)
	if not ok then
		warn(`[UIStyle] Yumuşatılamadı: {err}`)
	end
	return obj
end

-- =====================================================================
-- PET SİMGESİ: pet renginde sevimli bir yüz (kulak, göz, burun, yanak). Kare bir Frame döner.
-- props: Frame özellikleri (Position, Size, AnchorPoint ...) ve dim = true (silinen pet için solgun renk)
-- =====================================================================
local function dot(parent, x, y, w, h, color, extra)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(x, y)
	frame.Size = UDim2.fromScale(w, h)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	extra = extra or {}
	if extra.rotation then
		frame.Rotation = extra.rotation
	end
	if extra.transparency then
		frame.BackgroundTransparency = extra.transparency
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(extra.corner or 0.5, 0)
	corner.Parent = frame
	if extra.stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = extra.stroke
		stroke.Color = extra.strokeColor or BLACK
		stroke.Parent = frame
	end
	frame.Parent = parent
	return frame
end

-- Her pet için görünüm özellikleri. Listede olmayan pet "round" kulaklı varsayılanı kullanır.
local LOOKS = {
	cat = { ears = "point", inner = true },
	dog = { ears = "floppy" },
	bunny = { ears = "tall", inner = true },
	fox = { ears = "point", inner = true, whiteCheeks = true },
	panda = { ears = "round", earColor = Color3.fromRGB(40, 40, 46), patches = true },
	tiger = { ears = "round", stripes = true },
	wolf = { ears = "point", inner = true },
	dragon = { ears = "point", horns = true },
	phoenix = { ears = "none", crest = true },
	unicorn = { ears = "point", inner = true, horn = true },
	robot = { robot = true },
	galaxy = { ears = "point", inner = true, stars = true },
	titan = { ears = "round", crown = true },
}

local PINK = Color3.fromRGB(255, 160, 180)
local DARK = Color3.fromRGB(60, 34, 42)

-- 3B pet simgesi: ReplicatedStorage.GameModels'te 'pet_<tür>' modeli varsa küçük bir ViewportFrame'de (ön tarafından, hafif yandan ve yukarıdan) gösterir.
-- Birleşmiş boylar ('cat@2') türün modelini kullanır (boy farkı simge boyutundan gelir). props.dim: keşfedilmemiş pet, koyu siluet.
-- Model yoksa nil döner ve petIcon çizilmiş yüze düşer.
function UIStyle.petModelIcon(parent, pet, props)
	local config = Config.Models.PetIcon
	local part, offset = ModelLibrary.create("pet_" .. (pet.baseId or pet.id), 1)
	if not part then
		return nil
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = config.Ambient
	viewport.LightColor = config.LightColor
	viewport.LightDirection = config.LightDirection
	for key, value in props or {} do
		if key ~= "dim" then
			viewport[key] = value
		end
	end
	if props and props.dim then
		viewport.ImageColor3 = config.DimColor
	end
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = viewport

	-- Model orijinde: kutu merkezi 'offset'te, ön -Z'ye bakar; kamera ön tarafta (-Z), azimut ve yükseklik açısıyla
	part.CFrame = ModelLibrary.cframe(CFrame.new(), offset)
	part.Parent = viewport
	local size = part.Size
	local reach = math.max(size.X, size.Y, size.Z) * config.Distance
	local azimuth, elevation = math.rad(config.Azimuth), math.rad(config.Elevation)
	local direction = Vector3.new(math.sin(azimuth) * math.cos(elevation), math.sin(elevation), -math.cos(azimuth) * math.cos(elevation))
	local camera = Instance.new("Camera")
	camera.FieldOfView = config.FieldOfView
	camera.CFrame = CFrame.lookAt(offset + direction * reach, offset)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Parent = parent
	return viewport
end

function UIStyle.petIcon(parent, pet, props)
	props = props or {}
	local modelIcon = UIStyle.petModelIcon(parent, pet, props)
	if modelIcon then
		return modelIcon
	end
	local look = LOOKS[pet.baseId or pet.id] or { ears = "round" } -- birleşmiş boylar ('cat@2') ilk boyun görünümünü taşır
	local color = pet.color
	if props.dim then
		color = color:Lerp(Color3.fromRGB(80, 82, 92), 0.7)
	end

	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	for key, value in props do
		if key ~= "dim" then
			holder[key] = value
		end
	end
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = holder

	local earColor = look.earColor or color
	local earStroke = { stroke = 2 }

	-- Arkadaki parçalar: tepelik, boynuz, kulaklar
	if look.crest then
		dot(holder, 0.5, 0.13, 0.22, 0.22, Color3.fromRGB(255, 210, 60), earStroke)
		dot(holder, 0.34, 0.2, 0.16, 0.16, Color3.fromRGB(255, 140, 40), earStroke)
		dot(holder, 0.66, 0.2, 0.16, 0.16, Color3.fromRGB(255, 140, 40), earStroke)
	end
	if look.ears == "point" then
		for _, side in { -1, 1 } do
			local x = 0.5 + side * 0.3
			dot(holder, x, 0.25, 0.27, 0.27, earColor, { rotation = 45, corner = 0.22, stroke = 2 })
			if look.inner then
				dot(holder, x, 0.27, 0.13, 0.13, PINK, { rotation = 45, corner = 0.22 })
			end
		end
	elseif look.ears == "round" then
		for _, side in { -1, 1 } do
			dot(holder, 0.5 + side * 0.3, 0.26, 0.28, 0.28, earColor, earStroke)
		end
	elseif look.ears == "floppy" then
		for _, side in { -1, 1 } do
			dot(holder, 0.5 + side * 0.38, 0.5, 0.22, 0.42, UIStyle.darken(color, 0.25), { rotation = side * 14, stroke = 2 })
		end
	elseif look.ears == "tall" then
		for _, side in { -1, 1 } do
			dot(holder, 0.5 + side * 0.16, 0.23, 0.2, 0.5, earColor, { rotation = side * 8, stroke = 2 })
			dot(holder, 0.5 + side * 0.16, 0.25, 0.1, 0.34, PINK, { rotation = side * 8 })
		end
	end
	if look.horns then
		for _, side in { -1, 1 } do
			dot(holder, 0.5 + side * 0.14, 0.15, 0.13, 0.13, Color3.fromRGB(255, 235, 180), { rotation = 45, corner = 0.2, stroke = 2 })
		end
	end
	if look.horn then
		dot(holder, 0.5, 0.15, 0.12, 0.3, Color3.fromRGB(255, 240, 190), { corner = 0.5, stroke = 2, rotation = 0 })
	end
	if look.robot then
		dot(holder, 0.5, 0.1, 0.04, 0.16, DARK, { corner = 0.2 })
		dot(holder, 0.5, 0.04, 0.11, 0.11, Color3.fromRGB(255, 70, 70), { stroke = 2 })
	end

	-- Baş
	local head = dot(holder, 0.5, 0.58, 0.8, 0.7, color, { stroke = 2, corner = if look.robot then 0.2 else 0.5 })
	local headGradient = Instance.new("UIGradient")
	headGradient.Rotation = 90
	headGradient.Color = ColorSequence.new(WHITE, Color3.fromRGB(205, 205, 215))
	headGradient.Parent = head
	-- Başın üstünde küçük parlama
	dot(holder, 0.34, 0.37, 0.2, 0.1, WHITE, { rotation = -20, transparency = 0.6 })

	if look.crown then
		dot(holder, 0.5, 0.2, 0.42, 0.1, Color3.fromRGB(255, 205, 50), { corner = 0.3, stroke = 2 })
		for _, offset in { -0.16, 0, 0.16 } do
			dot(holder, 0.5 + offset, 0.13, 0.1, 0.1, Color3.fromRGB(255, 220, 80), { rotation = 45, corner = 0.15, stroke = 2 })
		end
	end
	if look.patches then
		dot(holder, 0.3, 0.54, 0.22, 0.3, Color3.fromRGB(40, 40, 46), { rotation = 25 })
		dot(holder, 0.7, 0.54, 0.22, 0.3, Color3.fromRGB(40, 40, 46), { rotation = -25 })
	end
	if look.whiteCheeks then
		dot(holder, 0.27, 0.74, 0.3, 0.22, WHITE, { rotation = 20 })
		dot(holder, 0.73, 0.74, 0.3, 0.22, WHITE, { rotation = -20 })
	end

	-- Yüz: burun çevresi, burun, gözler, yanaklar
	if not look.robot then
		dot(holder, 0.5, 0.73, 0.36, 0.24, UIStyle.lighten(color, 0.6))
		dot(holder, 0.5, 0.67, 0.1, 0.07, DARK)
	else
		-- Robot: ızgara ağız
		dot(holder, 0.5, 0.8, 0.34, 0.08, DARK, { corner = 0.3 })
	end
	for _, side in { -1, 1 } do
		local x = 0.5 + side * 0.2
		if look.robot then
			dot(holder, x, 0.52, 0.2, 0.18, Color3.fromRGB(90, 235, 255), { corner = 0.25, stroke = 2 })
			dot(holder, x - 0.03, 0.49, 0.05, 0.05, WHITE)
		else
			dot(holder, x, 0.53, 0.2, 0.24, WHITE, { stroke = 1.5 })
			dot(holder, x, 0.56, 0.12, 0.17, Color3.fromRGB(70, 36, 48))
			dot(holder, x + 0.02, 0.5, 0.05, 0.06, WHITE)
			dot(holder, x - 0.02, 0.6, 0.025, 0.03, WHITE)
		end
	end
	if not look.robot then
		dot(holder, 0.17, 0.7, 0.13, 0.08, PINK, { transparency = 0.5 })
		dot(holder, 0.83, 0.7, 0.13, 0.08, PINK, { transparency = 0.5 })
	end

	-- Ön süsler: çizgiler, yıldızlar
	if look.stripes then
		dot(holder, 0.5, 0.33, 0.05, 0.13, Color3.fromRGB(60, 36, 20), { corner = 0.5 })
		dot(holder, 0.4, 0.35, 0.045, 0.1, Color3.fromRGB(60, 36, 20), { corner = 0.5, rotation = 15 })
		dot(holder, 0.6, 0.35, 0.045, 0.1, Color3.fromRGB(60, 36, 20), { corner = 0.5, rotation = -15 })
	end
	if look.stars then
		dot(holder, 0.5, 0.32, 0.06, 0.06, WHITE, { rotation = 45, corner = 0.1 })
		dot(holder, 0.38, 0.36, 0.04, 0.04, Color3.fromRGB(255, 240, 150), { rotation = 45, corner = 0.1 })
		dot(holder, 0.63, 0.35, 0.045, 0.045, Color3.fromRGB(150, 235, 255), { rotation = 45, corner = 0.1 })
	end

	holder.Parent = parent
	return holder
end

-- İKSİR SİMGESİ (Frame'lerden çizilir): mantar, cam boyun, renkli sıvı dolu yuvarlak gövde (gradyan), parlak yansıma ve ortasında iksirin emojisi.
-- potion: Config.Potions.List girdisi (color, emoji, rainbow). props: Position, Size, AnchorPoint ... Kare bir Frame döner.
local RAINBOW = {
	Color3.fromRGB(255, 80, 90),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 220, 110),
	Color3.fromRGB(70, 160, 255),
	Color3.fromRGB(170, 90, 255),
}
function UIStyle.potionIcon(parent, potion, props)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	for key, value in props or {} do
		holder[key] = value
	end
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = holder

	-- Sahibin yüklediği hazır görsel (Config.Icons.Potions) varsa o, yoksa aşağıdaki çizilmiş şişe
	local imageId = Config.Icons.Potions[potion.id]
	if imageId and imageId ~= "" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = imageId
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = holder
		holder.Parent = parent
		return holder
	end

	dot(holder, 0.5, 0.08, 0.26, 0.14, Color3.fromRGB(176, 112, 60), { corner = 0.3, stroke = 2 }) -- mantar
	dot(holder, 0.5, 0.22, 0.3, 0.3, Color3.fromRGB(215, 236, 252), { corner = 0.2, stroke = 2 }) -- cam boyun
	local body = dot(holder, 0.5, 0.64, 0.82, 0.68, potion.color, { stroke = 2.5, corner = 0.5 }) -- sıvı dolu gövde
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	if potion.rainbow then
		local keypoints = {}
		for index, color in RAINBOW do
			table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / (#RAINBOW - 1), color))
		end
		gradient.Color = ColorSequence.new(keypoints)
	else
		gradient.Color = ColorSequence.new(UIStyle.lighten(potion.color, 0.4), UIStyle.darken(potion.color, 0.18))
	end
	gradient.Parent = body
	dot(holder, 0.3, 0.5, 0.16, 0.09, WHITE, { rotation = -35, transparency = 0.35 }) -- cam yansıması
	local symbol = Instance.new("TextLabel")
	symbol.BackgroundTransparency = 1
	symbol.AnchorPoint = Vector2.new(0.5, 0.5)
	symbol.Position = UDim2.fromScale(0.5, 0.67)
	symbol.Size = UDim2.fromScale(0.5, 0.42)
	symbol.TextScaled = true
	symbol.Text = potion.emoji
	symbol.Parent = holder
	holder.Parent = parent
	return holder
end

-- petIcon bir hata verirse oyun/panel bozulmasın: eski düz daireye döner
function UIStyle.safePetIcon(parent, pet, props)
	local ok, result = pcall(UIStyle.petIcon, parent, pet, props)
	if ok then
		return result
	end
	warn(`[UIStyle] Pet simgesi çizilemedi: {result}`)
	local circle = Instance.new("Frame")
	for key, value in props or {} do
		if key ~= "dim" then
			circle[key] = value
		end
	end
	circle.BackgroundColor3 = pet.color
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle
	circle.Parent = parent
	return circle
end

return UIStyle
