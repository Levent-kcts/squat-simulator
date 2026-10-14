-- Arayüz yumuşatma yardımcıları (referans oyundaki gibi): üstten alta renk geçişi, üstte parlak şerit, yuvarlak köşe, ince kenar,
-- ve pet simgesi (Blender pet modeli varsa 3B ViewportFrame, yoksa sevimli yüz). Sadece görseldir; oyun mantığına dokunmaz. Her modül kendi düz Frame/TextButton'unu yaratır,
-- sonra UIStyle.soften(nesne, ayarlar) ile yumuşatır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))
-- Performans modülü korumalı yüklenir: hafif grafik modunda uzun listelerdeki pet simgeleri 3B yerine çizilmiş yüz olur
local okPerf, Performance = pcall(require, script.Parent.Performance)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIStyle = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

-- =====================================================================
-- TASARIM SİSTEMİ ("Soft Dark Candy", research/06_ui_modern.md bölüm 4): koyu lacivert panel, ince açık çerçeve, yumuşak gölge, Gotham ailesi,
-- tek vurgu rengi, dudaklı (tuş hissi veren) düğmeler. Sadece GÖRÜNÜM; mantığa dokunmaz. Her yardımcı pcall'lidir: hata olursa düz (ama çalışan) nesne döner
-- ve nesneye 'UIStyleFallback' özniteliği konur. Hafif grafik modunda (Performance.low) gölge/gradyan/nabız/parlama yoktur.
--
-- KULLANIM ÖRNEĞİ:
--   local panel = UIStyle.panel(root, { name = "ShopPanel", width = 460, height = 520, position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
--   local head = UIStyle.header(panel, { title = "Shop", subtitle = "Spend your Wins", icon = Config.Icons.Shop, emoji = "🛒", accent = "primary", chip = "12/50", onClose = function() ... end })
--   local card = UIStyle.card(panel, { name = "Item_1", size = UDim2.new(1, -32, 0, 80), position = UDim2.fromOffset(16, 72), accent = "magic", selected = false })
--   local buy = UIStyle.button(card, { text = "Buy", kind = "success", size = "md", width = 120, position = UDim2.fromScale(0.7, 0.2), onClick = function() ... end })
--   UIStyle.setButtonEnabled(buy, false) / UIStyle.setButtonText(buy, "Need 120 Wins")   -- ya da buy:SetAttribute("Disabled", true)
-- Vurgu rengi (accent) her yerde: "primary"|"success"|"info"|"magic"|"hot"|"danger"|"warn" adı, {base, dark, text} tablosu ya da Color3.
-- Her yardımcı 'props' tablosu alır (Position, Size, AnchorPoint, LayoutOrder, ZIndex... ham özellikler).
-- =====================================================================
local function rgb(hex)
	return Color3.fromRGB(math.floor(hex / 65536) % 256, math.floor(hex / 256) % 256, hex % 256)
end

local function accentColors(base, dark, text)
	return { base = rgb(base), dark = rgb(dark), text = text and rgb(text) or WHITE }
end

UIStyle.Theme = {
	colors = {
		bg = rgb(0x12142A), -- karartma / arka (BackgroundTransparency 0.35 ile)
		panel = rgb(0x1B1F3B), -- pencere gövdesi
		panelHigh = rgb(0x232849), -- iç bölüm, sekme çubuğu zemini
		card = rgb(0x2A3059), -- kart / satır
		cardHover = rgb(0x343B6B), -- hover / odakta
		cardDeep = rgb(0x181B33), -- çukur (girdi kutusu, ilerleme çubuğu boşluğu)
		line = WHITE, -- ince çerçeve / ayırıcı (saydamlık için Theme.stroke)
		text = rgb(0xF5F7FF),
		textDim = rgb(0xA9B2DA),
		textMute = rgb(0x6F79A8),
		primary = accentColors(0xFFC83D, 0xD9961A, 0x3A2A00), -- ana CTA, Win, ödül
		success = accentColors(0x3FDC85, 0x1FA85B), -- Claim, sahip, açık
		info = accentColors(0x4DA6FF, 0x2F78D1), -- bilgi, seçili sekme
		magic = accentColors(0x9B6CFF, 0x6C42D6), -- pet, Index, aura
		hot = accentColors(0xFF4D93, 0xD42B70), -- Rebirth, özel
		danger = accentColors(0xFF5468, 0xCC2F44), -- kapat, hata, sil
		warn = accentColors(0xFF9B3D, 0xCC7418), -- uyarı, sınırlı süre
	},
	-- Roblox'un Enum.Font'u doğrudan (FontFace/Font.new YOK). brand: sadece marka anları (yükleme başlığı, REBIRTH! gibi dev başlıklar)
	fonts = {
		title = Enum.Font.GothamBlack,
		bold = Enum.Font.GothamBold,
		body = Enum.Font.GothamMedium,
		brand = Enum.Font.FredokaOne,
	},
	textSize = { title = 22, bold = 16, body = 15, caption = 12, number = 20 },
	radius = { panel = 20, card = 14, button = 12, chip = 8, input = 10 },
	space = { 4, 8, 12, 16, 24 },
	-- ince çerçeve: panel 1.5 px, kart 1 px, beyaz, Transparency 0.88
	stroke = { color = WHITE, transparency = 0.88, panel = 1.5, card = 1 },
	tween = {
		press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		release = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		hover = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		pop = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		panelIn = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		panelOut = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		count = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
}
local Theme = UIStyle.Theme

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
--   style = "flat"  modern düz görünüm: parlak şerit kapalı, strength 0.08, ince (1 px) beyaz-saydam çerçeve. Verilmezse eski davranış AYNEN kalır.
local function softenUnsafe(obj, opts)
	opts = opts or {}
	local flat = opts.style == "flat"
	local radius = opts.radius or 8
	UIStyle.round(obj, radius)

	if opts.stroke or flat then
		local stroke = obj:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Parent = obj
		end
		if flat and not opts.stroke then
			stroke.Thickness = Theme.stroke.card
			stroke.Color = opts.strokeColor or Theme.stroke.color
			stroke.Transparency = Theme.stroke.transparency
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		else
			stroke.Thickness = opts.stroke
			stroke.Color = opts.strokeColor or BLACK
		end
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
		local strength = opts.strength or (if flat then 0.08 else 0.2)
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new(WHITE, Color3.new(1 - strength, 1 - strength, 1 - strength * 0.75))
	end

	-- Üstte yumuşak parlak şerit (içeriğin altında kalsın diye ZIndex 0)
	if opts.shine ~= false and not flat and not obj:FindFirstChild("Shine") then
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

-- ORTADAN BÜYÜYÜP KÜÇÜLSÜN (2026-10-13, sahibi 'butonlar tek tarafı sabit kalıp diğer taraftan büyüyüp küçülüyor, hareket edecekse olduğu yerde her yöne doğru büyüt küçült' dedi):
-- UIScale / Size animasyonu nesnenin AnchorPoint'inden büyür; varsayılan (0, 0) sol-üst köşeyi sabit tutar. Bu yardımcı nesneyi YERİNDE bırakıp AnchorPoint'ini (0.5, 0.5) yapar (konumu buna göre kaydırır);
-- nabız atan, basınca küçülen ya da büyüyen HER düğme animasyondan ÖNCE bunu çağırmalı. Düzen (UIListLayout/UIGridLayout) içindeki nesnelerde kullanma: onlar sabit boyutlu bir tutucunun içinde ortalanır (RightHud FREE REWARD gibi).
function UIStyle.anchorCenter(obj)
	local ok, err = pcall(function()
		local size, position, anchor = obj.Size, obj.Position, obj.AnchorPoint
		obj.AnchorPoint = Vector2.new(0.5, 0.5)
		obj.Position = UDim2.new(
			position.X.Scale + (0.5 - anchor.X) * size.X.Scale,
			position.X.Offset + (0.5 - anchor.X) * size.X.Offset,
			position.Y.Scale + (0.5 - anchor.Y) * size.Y.Scale,
			position.Y.Offset + (0.5 - anchor.Y) * size.Y.Offset
		)
	end)
	if not ok then
		warn(`[UIStyle] Ortalanamadı: {err}`)
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
local function modelViewportIcon(parent, modelName, props)
	local config = Config.Models.PetIcon
	local part, offset = ModelLibrary.create(modelName, 1)
	if not part then
		return nil
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = config.Ambient
	viewport.LightColor = config.LightColor
	viewport.LightDirection = config.LightDirection
	for key, value in props or {} do
		if key ~= "dim" and key ~= "lite" then
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

function UIStyle.petModelIcon(parent, pet, props)
	-- 'lite' (uzun listelerdeki kartlar: Pets menüsü, Pet Index): hafif grafik modunda (telefon) 3B ViewportFrame yerine çizilmiş yüz kullanılır; onlarca ViewportFrame aynı anda çizilince telefon takılıyordu
	if props and props.lite and okPerf and Performance.low then
		return nil
	end
	return modelViewportIcon(parent, "pet_" .. (pet.baseId or pet.id), props)
end

-- 3B yumurta simgesi (yumurta açılış animasyonu, client/Reveal): GameModels'te 'egg_<yumurta id>' modeli varsa ViewportFrame'de gösterir; yoksa nil (çağıran çizilmiş yumurtaya düşer)
function UIStyle.eggModelIcon(parent, egg, props)
	return modelViewportIcon(parent, "egg_" .. egg.id, props)
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
		if key ~= "dim" and key ~= "lite" then
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

-- LEGO TUĞLA DESENİ (referanstaki düğme/çubuk görünümü): parent'ın üstüne ince, kayık sıralı (yarım tuğla kaydırmalı) yarı saydam açık dikdörtgenler çizer.
-- Konumlar ölçek (scale) olduğu için parent'ın pikseli bilinmese de desen oturur. cols x rows: tuğla sayısı (satır başına), radius: köşe yuvarlaklığı (parent ile aynı olsun,
-- taşan tuğlalar kırpılır), opts.light: tuğla şeffaflığı (büyük = daha silik). Döner: desen çerçevesi (ZIndex 2: arka plan ve dolgunun üstünde, simge/yazının altında)
function UIStyle.brickSkin(parent, cols, rows, radius, opts)
	opts = opts or {}
	local holder = Instance.new("Frame")
	holder.Name = "BrickSkin"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.ZIndex = 2
	holder.Active = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = holder
	local light = opts.light or 0.88
	for row = 0, rows - 1 do
		local shift = if row % 2 == 0 then 0 else -0.5
		for col = 0, cols do
			local brick = Instance.new("Frame")
			brick.Position = UDim2.new((col + shift) / cols, 1, row / rows, 1)
			brick.Size = UDim2.new(1 / cols, -2, 1 / rows, -2)
			brick.BackgroundColor3 = WHITE
			brick.BackgroundTransparency = if (row + col) % 2 == 0 then light else light + 0.05
			brick.BorderSizePixel = 0
			brick.ZIndex = 2
			local brickCorner = Instance.new("UICorner")
			brickCorner.CornerRadius = UDim.new(0, 2)
			brickCorner.Parent = brick
			brick.Parent = holder
		end
	end
	holder.Parent = parent
	return holder
end

-- PENCERE BAŞLIĞI SİMGESİ: sol menüdeki / sağ üstteki düğmeyle AYNI görsel (imageId = Config.Icons.X) olsun diye tek yerden çizilir; görsel yüklü değilse emoji yazısı kalır.
-- props: Position, Size (kare). Döner: simge nesnesi (ImageLabel ya da TextLabel, adı 'HeaderIcon').
function UIStyle.headerIcon(parent, imageId, emoji, props)
	local icon
	if type(imageId) == "string" and imageId ~= "" then
		icon = Instance.new("ImageLabel")
		icon.Image = imageId
		icon.ScaleType = Enum.ScaleType.Fit
	else
		icon = Instance.new("TextLabel")
		icon.Text = emoji
		icon.Font = Theme.fonts.bold
		icon.TextScaled = true
		icon.TextColor3 = Color3.new(1, 1, 1)
	end
	icon.Name = "HeaderIcon"
	icon.BackgroundTransparency = 1
	icon.Position = props.Position
	icon.Size = props.Size
	icon.Parent = parent
	return icon
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
		if key ~= "dim" and key ~= "lite" then
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

-- =====================================================================
-- TASARIM SİSTEMİ YARDIMCILARI (üstteki blokta anlatıldı)
-- =====================================================================
local function isLow()
	return okPerf and Performance.low == true
end
UIStyle.isLow = isLow

-- Vurgu rengini {base, dark, text} tablosuna çevirir: ad ("primary"), tablo ya da Color3; bilinmeyen = primary
function UIStyle.accent(accent)
	if type(accent) == "string" then
		local found = Theme.colors[accent]
		if type(found) == "table" and found.base then
			return found
		end
		return Theme.colors.primary
	elseif type(accent) == "table" and accent.base then
		return accent
	elseif accent ~= nil then
		return { base = accent, dark = UIStyle.darken(accent, 0.3), text = WHITE }
	end
	return Theme.colors.primary
end
local accentOf = UIStyle.accent

local function tween(obj, info, goal)
	pcall(function()
		TweenService:Create(obj, info, goal):Play()
	end)
end

local function applyProps(obj, props)
	for key, value in props or {} do
		obj[key] = value
	end
end

local function makeInstance(className, name, parent, props)
	local obj = Instance.new(className)
	obj.Name = name
	applyProps(obj, props)
	if parent then
		obj.Parent = parent
	end
	return obj
end

-- İnce beyaz-saydam çerçeve (varsa günceller)
local function thinStroke(obj, thickness, color, transparency)
	local stroke = obj:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = obj
	end
	stroke.Thickness = thickness
	stroke.Color = color or Theme.stroke.color
	stroke.Transparency = transparency or Theme.stroke.transparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

-- Yazı üstü 1-1.5 px, siyah, Transparency 0.55 gölge (sadece renkli düğme/kart üzerindeki sayılarda)
local function textShadow(label)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.2
	stroke.Color = BLACK
	stroke.Transparency = 0.55
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
	return stroke
end

local function softGradient(obj, strength)
	if isLow() then
		return
	end
	local gradient = obj:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Parent = obj
	end
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(WHITE, Color3.new(1 - strength, 1 - strength, 1 - strength * 0.75))
end

-- Bir yardımcı hata verirse düz ama çalışan yedek nesne kurulur ('UIStyleFallback' özniteliği testlerde yedeğe düşüldüğünü gösterir)
local function plain(parent, className, name, props)
	local obj = Instance.new(className)
	obj.Name = name
	if className == "Frame" then
		obj.BackgroundColor3 = Theme.colors.card
	end
	for key, value in props or {} do
		if value ~= nil then
			obj[key] = value
		end
	end
	obj:SetAttribute("UIStyleFallback", true)
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function guard(name, builder, fallback)
	return function(...)
		local ok, a, b, c = pcall(builder, ...)
		if ok then
			return a, b, c
		end
		warn(`[UIStyle] {name} kurulamadı: {a}`)
		local fine, result, second = pcall(fallback, ...)
		if fine then
			return result, second
		end
		return nil
	end
end

-- ---------------------------------------------------------------------
-- Gölge: nesnenin ARKASINDA kardeş Frame (Sibling modunda ZIndex düşük). Konum/boyut/görünürlük nesneyi izler. Hafif modda nil.
-- UIStyle.shadow(frame, {offset = 8, transparency = 0.72}) -> shadow Frame ('Shadow') ya da nil (frame önce bir ebeveyne bağlanmış olmalı)
-- ---------------------------------------------------------------------
function UIStyle.shadow(frame, opts)
	opts = opts or {}
	if isLow() or not frame.Parent then
		return nil
	end
	local offset = opts.offset or 8
	local shadow = makeInstance("Frame", "Shadow", nil, {
		AnchorPoint = frame.AnchorPoint,
		Position = frame.Position + UDim2.fromOffset(0, offset),
		Size = frame.Size,
		BackgroundColor3 = BLACK,
		BackgroundTransparency = opts.transparency or 0.72,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = frame.ZIndex - 1,
		Visible = frame.Visible,
	})
	local corner = frame:FindFirstChildOfClass("UICorner")
	UIStyle.round(shadow, if corner then corner.CornerRadius else UDim.new(0, Theme.radius.panel))
	shadow.Parent = frame.Parent
	pcall(function()
		frame:GetPropertyChangedSignal("Position"):Connect(function()
			shadow.Position = frame.Position + UDim2.fromOffset(0, offset)
		end)
		frame:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
			shadow.AnchorPoint = frame.AnchorPoint
		end)
		frame:GetPropertyChangedSignal("Visible"):Connect(function()
			shadow.Visible = frame.Visible
		end)
		-- UISizeConstraint ekran sınırı Size'a yansımaz: gerçek ölçü AbsoluteSize'dan alınır
		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local size = frame.AbsoluteSize
			shadow.Size = UDim2.fromOffset(size.X, size.Y)
		end)
		frame.AncestryChanged:Connect(function()
			if not frame.Parent then
				shadow:Destroy()
			end
		end)
	end)
	return shadow
end

-- ---------------------------------------------------------------------
-- PENCERE GÖVDESİ: UIStyle.panel(parent, {name, size (UDim2), width, height, accent, shadow = true, position, anchor})
--   width verilirse: genişlik ekranın %92'si ile 'width' (UISizeConstraint) arasında kalır (telefon), yükseklik size/height'tan.
--   DÖNER: panel (Frame, Active = true, ClipsDescendants), shadow (ya da nil). Birden çok dönüş: local panel, shadow = UIStyle.panel(...)
-- ---------------------------------------------------------------------
UIStyle.panel = guard("panel", function(parent, opts)
	opts = opts or {}
	local frame = makeInstance("Frame", opts.name or "Panel", nil, {
		BackgroundColor3 = Theme.colors.panel,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
	})
	if opts.anchor then
		frame.AnchorPoint = opts.anchor
	end
	if opts.position then
		frame.Position = opts.position
	end
	if opts.width then
		local height = opts.size or UDim2.fromOffset(opts.width, opts.height or 400)
		frame.Size = UDim2.new(0.92, 0, height.Y.Scale, height.Y.Offset)
		makeInstance("UISizeConstraint", "WidthLimit", frame, { MaxSize = Vector2.new(opts.width, math.huge) })
	else
		frame.Size = opts.size or UDim2.fromOffset(460, opts.height or 400)
	end
	if type(opts.accent) == "string" then
		frame:SetAttribute("AccentName", opts.accent)
	end
	UIStyle.round(frame, Theme.radius.panel)
	thinStroke(frame, Theme.stroke.panel)
	frame.Parent = parent
	local shadow = nil
	if opts.shadow ~= false then
		shadow = UIStyle.shadow(frame)
	end
	return frame, shadow
end, function(parent, opts)
	opts = opts or {}
	return plain(parent, "Frame", opts.name or "Panel", { Size = opts.size or UDim2.fromOffset(460, 400), Position = opts.position, AnchorPoint = opts.anchor, Active = true, ClipsDescendants = true })
end)

-- ---------------------------------------------------------------------
-- KART: UIStyle.card(parent, {size, position, accent, selected, name, padding = true, props}) -> Frame
--   radius 14, 1 px ince çerçeve, UIPadding 12 (padding = false ile kapanır); seçili: 2 px vurgu çerçevesi + cardHover.
--   Seçimi sonradan değiştirmek: UIStyle.setCardSelected(card, true/false, accent)
-- ---------------------------------------------------------------------
function UIStyle.setCardSelected(card, selected, accent)
	pcall(function()
		local colors = accentOf(accent or card:GetAttribute("AccentName"))
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if selected then
			card.BackgroundColor3 = Theme.colors.cardHover
			if stroke then
				stroke.Thickness = 2
				stroke.Color = colors.base
				stroke.Transparency = 0
			end
		else
			card.BackgroundColor3 = Theme.colors.card
			if stroke then
				stroke.Thickness = Theme.stroke.card
				stroke.Color = Theme.stroke.color
				stroke.Transparency = Theme.stroke.transparency
			end
		end
		card:SetAttribute("Selected", selected and true or false)
	end)
end

UIStyle.card = guard("card", function(parent, opts)
	opts = opts or {}
	local card = makeInstance("Frame", opts.name or "Card", nil, {
		BackgroundColor3 = Theme.colors.card,
		BorderSizePixel = 0,
		Size = opts.size or UDim2.new(1, 0, 0, 80),
	})
	applyProps(card, opts.props)
	if opts.position then
		card.Position = opts.position
	end
	if type(opts.accent) == "string" then
		card:SetAttribute("AccentName", opts.accent)
	end
	UIStyle.round(card, Theme.radius.card)
	thinStroke(card, Theme.stroke.card)
	softGradient(card, 0.06)
	if opts.padding ~= false then
		local pad = Theme.space[3]
		makeInstance("UIPadding", "Padding", card, {
			PaddingTop = UDim.new(0, pad),
			PaddingBottom = UDim.new(0, pad),
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		})
	end
	card.Parent = parent
	if opts.selected then
		UIStyle.setCardSelected(card, true, opts.accent)
	end
	return card
end, function(parent, opts)
	opts = opts or {}
	return plain(parent, "Frame", opts.name or "Card", { Size = opts.size or UDim2.new(1, 0, 0, 80), Position = opts.position })
end)

-- ---------------------------------------------------------------------
-- YAZI: UIStyle.label(parent, {text, role = "title|bold|body|caption|number", color, size, align = "left|center|right", wrap, name, props}) -> TextLabel
--   title GothamBlack 22, bold GothamBold 16, body GothamMedium 15, caption GothamMedium 12 (textDim), number GothamBlack 20.
--   Sabit TextSize + TextTruncate (TextScaled YOK).
-- ---------------------------------------------------------------------
local LABEL_FONTS = { title = "title", bold = "bold", body = "body", caption = "body", number = "title" }
UIStyle.label = guard("label", function(parent, opts)
	opts = opts or {}
	local role = if opts.role and Theme.textSize[opts.role] then opts.role else "body"
	local textSize = opts.size or Theme.textSize[role]
	local label = makeInstance("TextLabel", opts.name or "Label", nil, {
		BackgroundTransparency = 1,
		Font = Theme.fonts[LABEL_FONTS[role]],
		TextSize = textSize,
		TextColor3 = opts.color or (if role == "caption" then Theme.colors.textDim else Theme.colors.text),
		Text = opts.text or "",
		Size = UDim2.new(1, 0, 0, textSize + 6),
		TextXAlignment = if opts.align == "center" then Enum.TextXAlignment.Center elseif opts.align == "right" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
		TextWrapped = opts.wrap == true,
		TextTruncate = if opts.wrap then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd,
	})
	applyProps(label, opts.props)
	label.Parent = parent
	return label
end, function(parent, opts)
	opts = opts or {}
	return plain(parent, "TextLabel", opts.name or "Label", { BackgroundTransparency = 1, Text = opts.text or "", Size = UDim2.new(1, 0, 0, 24) })
end)

-- ---------------------------------------------------------------------
-- ÇİP (durum/sayaç): UIStyle.chip(parent, {text, accent, icon, name, props}) -> Frame 'Chip' (içinde TextLabel 'Text', isteğe bağlı 'Icon'); yatayda içeriğe göre büyür.
--   radius 8, yarı saydam vurgu zemini, vurgu renginde yazı. icon: 'rbxassetid://...' ise ImageLabel, değilse emoji TextLabel. Yazıyı değiştirmek: UIStyle.setChipText(chip, "OWNED")
-- ---------------------------------------------------------------------
function UIStyle.setChipText(chip, text)
	pcall(function()
		local label = chip:FindFirstChild("Text")
		if label then
			label.Text = text
		end
	end)
end

UIStyle.chip = guard("chip", function(parent, opts)
	opts = opts or {}
	local colors = accentOf(opts.accent)
	local chip = makeInstance("Frame", opts.name or "Chip", nil, {
		BackgroundColor3 = colors.base,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
	})
	applyProps(chip, opts.props)
	UIStyle.round(chip, Theme.radius.chip)
	makeInstance("UIPadding", "Padding", chip, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
	makeInstance("UIListLayout", "Layout", chip, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	if type(opts.icon) == "string" and opts.icon ~= "" then
		if string.sub(opts.icon, 1, 4) == "rbxa" then
			makeInstance("ImageLabel", "Icon", chip, { BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), Image = opts.icon, LayoutOrder = 1 })
		else
			makeInstance("TextLabel", "Icon", chip, { BackgroundTransparency = 1, Size = UDim2.fromOffset(14, 14), Text = opts.icon, TextSize = 12, Font = Theme.fonts.bold, LayoutOrder = 1 })
		end
	end
	makeInstance("TextLabel", "Text", chip, {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),
		Font = Theme.fonts.bold,
		TextSize = 12,
		TextColor3 = colors.base,
		Text = opts.text or "",
		LayoutOrder = 2,
	})
	chip.Parent = parent
	return chip
end, function(parent, opts)
	opts = opts or {}
	return plain(parent, "Frame", opts.name or "Chip", { Size = UDim2.fromOffset(60, 24) })
end)

-- ---------------------------------------------------------------------
-- SAYI ROZETİ: UIStyle.badge(parent, {text, color, name, props}) -> Frame 'Badge' (28 px daire, 2 px çerçeve; Gifts/PotionBadge ölçüsü; içinde TextLabel 'Count', en çok 16 punto)
--   Sayıyı değiştirmek: UIStyle.setBadge(badge, "3"). Varsayılan renk danger (kırmızı); Quests dairesinde kullanma (orada sarı sayı kalır).
-- ---------------------------------------------------------------------
function UIStyle.setBadge(badge, text)
	pcall(function()
		local count = badge:FindFirstChild("Count")
		if count then
			count.Text = tostring(text)
		end
	end)
end

UIStyle.badge = guard("badge", function(parent, opts)
	opts = opts or {}
	local color = opts.color or Theme.colors.danger.base
	local badge = makeInstance("Frame", opts.name or "Badge", nil, {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(28, 28),
	})
	applyProps(badge, opts.props)
	UIStyle.round(badge, UDim.new(1, 0))
	thinStroke(badge, 2, UIStyle.darken(color, 0.45), 0)
	local count = makeInstance("TextLabel", "Count", badge, {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		Font = Theme.fonts.title,
		TextScaled = true,
		TextColor3 = WHITE,
		Text = tostring(opts.text or ""),
	})
	makeInstance("UITextSizeConstraint", "SizeLimit", count, { MaxTextSize = 16, MinTextSize = 8 })
	badge.Parent = parent
	return badge
end, function(parent, opts)
	opts = opts or {}
	return plain(parent, "Frame", opts.name or "Badge", { Size = UDim2.fromOffset(28, 28) })
end)

-- ---------------------------------------------------------------------
-- İLERLEME ÇUBUĞU: UIStyle.progressBar(parent, {accent, value (0..1), text, name, props})
--   DÖNER: { frame, fill, label, set = function(value, text) }. Çukur cardDeep, tam yuvarlak, dolgu vurgu gradyanı, yazı çubuğun ÜZERİNDE ortada.
-- ---------------------------------------------------------------------
UIStyle.progressBar = guard("progressBar", function(parent, opts)
	opts = opts or {}
	local colors = accentOf(opts.accent)
	local frame = makeInstance("Frame", opts.name or "ProgressBar", nil, {
		BackgroundColor3 = Theme.colors.cardDeep,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 18),
		ClipsDescendants = true,
	})
	applyProps(frame, opts.props)
	UIStyle.round(frame, UDim.new(1, 0))
	local fill = makeInstance("Frame", "Fill", frame, { BackgroundColor3 = colors.base, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) })
	UIStyle.round(fill, UDim.new(1, 0))
	if not isLow() then
		local gradient = makeInstance("UIGradient", "Gradient", fill, { Rotation = 90 })
		gradient.Color = ColorSequence.new(UIStyle.lighten(colors.base, 0.15), colors.dark)
	end
	local label = makeInstance("TextLabel", "Text", frame, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.fonts.bold,
		TextSize = 12,
		TextColor3 = Theme.colors.text,
		Text = opts.text or "",
		ZIndex = 2,
	})
	textShadow(label)
	local bar = { frame = frame, fill = fill, label = label }
	function bar.set(value, text)
		value = math.clamp(value or 0, 0, 1)
		if isLow() then
			fill.Size = UDim2.fromScale(value, 1)
		else
			tween(fill, Theme.tween.hover, { Size = UDim2.fromScale(value, 1) })
		end
		if text ~= nil then
			label.Text = text
		end
	end
	fill.Size = UDim2.fromScale(math.clamp(opts.value or 0, 0, 1), 1)
	frame.Parent = parent
	return bar
end, function(parent, opts)
	opts = opts or {}
	local frame = plain(parent, "Frame", opts.name or "ProgressBar", { Size = UDim2.new(1, 0, 0, 18) })
	return { frame = frame, set = function() end }
end)

-- ---------------------------------------------------------------------
-- AYIRICI: UIStyle.divider(parent, {props}) -> Frame 'Divider' (1 px, beyaz Transparency 0.92)
-- ---------------------------------------------------------------------
UIStyle.divider = guard("divider", function(parent, opts)
	opts = opts or {}
	local line = makeInstance("Frame", opts.name or "Divider", nil, {
		BackgroundColor3 = Theme.colors.line,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
	})
	applyProps(line, opts.props)
	line.Parent = parent
	return line
end, function(parent)
	return plain(parent, "Frame", "Divider", { Size = UDim2.new(1, 0, 0, 1) })
end)

-- ---------------------------------------------------------------------
-- GİRDİ: UIStyle.input(parent, {placeholder, text, accent, name, props}) -> TextBox, Frame
--   Frame 'Input' (cardDeep, radius 10, 1 px çerçeve; odakta vurgu çerçevesi), içinde TextBox 'Box' (placeholder textMute, ClearTextOnFocus kapalı).
-- ---------------------------------------------------------------------
UIStyle.input = guard("input", function(parent, opts)
	opts = opts or {}
	local colors = accentOf(opts.accent or "info")
	local frame = makeInstance("Frame", opts.name or "Input", nil, {
		BackgroundColor3 = Theme.colors.cardDeep,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
	})
	applyProps(frame, opts.props)
	UIStyle.round(frame, Theme.radius.input)
	local stroke = thinStroke(frame, 1)
	local box = makeInstance("TextBox", "Box", frame, {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Font = Theme.fonts.body,
		TextSize = Theme.textSize.body,
		TextColor3 = Theme.colors.text,
		PlaceholderColor3 = Theme.colors.textMute,
		PlaceholderText = opts.placeholder or "",
		Text = opts.text or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	pcall(function()
		box.Focused:Connect(function()
			stroke.Color = colors.base
			stroke.Transparency = 0
			stroke.Thickness = 1.5
		end)
		box.FocusLost:Connect(function()
			stroke.Color = Theme.stroke.color
			stroke.Transparency = Theme.stroke.transparency
			stroke.Thickness = 1
		end)
	end)
	frame.Parent = parent
	return box, frame
end, function(parent, opts)
	opts = opts or {}
	local frame = plain(parent, "Frame", opts.name or "Input", { Size = UDim2.new(1, 0, 0, 40) })
	return plain(frame, "TextBox", "Box", { Size = UDim2.fromScale(1, 1), PlaceholderText = opts.placeholder or "" }), frame
end)

-- ---------------------------------------------------------------------
-- DÜĞME: UIStyle.button(parent, {text, kind = "primary|success|secondary|danger|ghost", size = "sm|md|lg", width, icon, name, position, anchor,
--                                 layout = false, disabled, onClick, props}) -> TextButton
--   YAPI: TextButton ('dudak' rengi, koyu) > Body (asıl yüz, üstte) > [Icon] + Label (TextLabel, yazı BURADA). Basınca Body 2-3 px aşağı kayar, dudak kapanır.
--   Yükseklik sm 36 / md 44 / lg 52. width: sayı (piksel) ya da UDim2 (varsayılan sm 100 / md 140 / lg 180). props.Size tüm ölçüyü ezer.
--   anchorCenter İÇERİDE çağrılır (Size/Position ayarlandıktan sonra; sonradan Position yazarsan MERKEZİ yazarsın). layout = true: UIListLayout/UIGridLayout
--   içindeyse anchorCenter yapılmaz. onClick: tıklama işleyicisi (devre dışıyken çağrılmaz). Devre dışı: button:SetAttribute("Disabled", true) ya da
--   UIStyle.setButtonEnabled(btn, false); yazı: UIStyle.setButtonText(btn, "..."); tür: UIStyle.setButtonKind(btn, "success").
--   Hover (sadece fare, dokunmatik değil): Body rengi hafif açılır. AutoButtonColor kapalı.
-- ---------------------------------------------------------------------
local BUTTON_SIZES = {
	sm = { height = 36, text = 14, lip = 3, width = 100 },
	md = { height = 44, text = 16, lip = 3, width = 140 },
	lg = { height = 52, text = 18, lip = 4, width = 180 },
}
local buttonState = setmetatable({}, { __mode = "k" })

local function buttonPalette(kind, disabled)
	local colors = Theme.colors
	if disabled then
		return { body = colors.card, lip = nil, text = colors.textMute, hover = colors.card }
	elseif kind == "ghost" then
		return { body = nil, lip = nil, text = colors.text, hover = colors.card }
	elseif kind == "secondary" then
		return { body = colors.card, lip = UIStyle.darken(colors.card, 0.35), text = colors.text, hover = colors.cardHover }
	end
	local accent = colors[kind]
	if type(accent) ~= "table" or not accent.base then
		accent = colors.primary
	end
	return { body = accent.base, lip = accent.dark, text = accent.text, hover = UIStyle.lighten(accent.base, 0.06) }
end

local function styleButton(button)
	pcall(function()
		local state = buttonState[button]
		if not state then
			return
		end
		local disabled = button:GetAttribute("Disabled") == true
		local kind = button:GetAttribute("ButtonKind") or "primary"
		local palette = buttonPalette(kind, disabled)
		state.rest, state.hover, state.disabled = palette.body, palette.hover, disabled
		if palette.lip then
			button.BackgroundColor3 = palette.lip
			button.BackgroundTransparency = 0
		else
			button.BackgroundTransparency = 1
		end
		local body = state.body
		if palette.body then
			body.BackgroundColor3 = palette.body
			body.BackgroundTransparency = 0
		else
			body.BackgroundTransparency = 1
		end
		state.label.TextColor3 = palette.text
		if state.icon and state.icon.ClassName == "TextLabel" then
			state.icon.TextColor3 = palette.text
		end
		-- dudak sönükken ve ghost'ta yok: Body tam boy
		body.Size = if palette.lip then UDim2.new(1, 0, 1, -state.lip) else UDim2.fromScale(1, 1)
		state.hasLip = palette.lip ~= nil
	end)
end

function UIStyle.setButtonText(button, text)
	pcall(function()
		buttonState[button].label.Text = text
	end)
end

function UIStyle.setButtonEnabled(button, enabled)
	pcall(function()
		button:SetAttribute("Disabled", not enabled)
		styleButton(button)
	end)
end

function UIStyle.setButtonKind(button, kind)
	pcall(function()
		button:SetAttribute("ButtonKind", kind)
		styleButton(button)
	end)
end

UIStyle.button = guard("button", function(parent, opts)
	opts = opts or {}
	local kind = opts.kind or "primary"
	local preset = BUTTON_SIZES[opts.size or "md"] or BUTTON_SIZES.md
	local width = opts.width or preset.width
	local button = makeInstance("TextButton", opts.name or "Button", nil, {
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	if type(width) == "number" then
		button.Size = UDim2.fromOffset(width, preset.height)
	else
		button.Size = UDim2.new(width.X.Scale, width.X.Offset, 0, preset.height)
	end
	applyProps(button, opts.props)
	if opts.position then
		button.Position = opts.position
	end
	if opts.anchor then
		button.AnchorPoint = opts.anchor
	end
	UIStyle.round(button, Theme.radius.button)
	button:SetAttribute("ButtonKind", kind)
	if opts.disabled then
		button:SetAttribute("Disabled", true)
	end

	local body = makeInstance("Frame", "Body", button, { BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -preset.lip), Active = false })
	UIStyle.round(body, Theme.radius.button)
	if kind ~= "ghost" then
		softGradient(body, 0.12)
	end
	if kind == "secondary" then
		thinStroke(body, 1)
	end
	local label = makeInstance("TextLabel", "Label", body, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = if kind == "primary" then Theme.fonts.title else Theme.fonts.bold,
		TextSize = preset.text,
		Text = opts.text or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local icon = nil
	if type(opts.icon) == "string" and opts.icon ~= "" then
		makeInstance("UIListLayout", "Layout", body, {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, preset.height)
		label.LayoutOrder = 2
		if string.sub(opts.icon, 1, 4) == "rbxa" then
			icon = makeInstance("ImageLabel", "Icon", body, { BackgroundTransparency = 1, Size = UDim2.fromOffset(preset.text + 6, preset.text + 6), Image = opts.icon, LayoutOrder = 1 })
		else
			icon = makeInstance("TextLabel", "Icon", body, { BackgroundTransparency = 1, Size = UDim2.fromOffset(preset.text + 6, preset.text + 6), Text = opts.icon, TextSize = preset.text, Font = Theme.fonts.bold, LayoutOrder = 1 })
		end
	end
	if kind ~= "ghost" and kind ~= "secondary" then
		textShadow(label)
	end

	local state = { body = body, label = label, icon = icon, lip = preset.lip, rest = nil, hover = nil, disabled = false, hasLip = true, pressed = false }
	buttonState[button] = state
	styleButton(button)

	local function release()
		if state.pressed then
			state.pressed = false
			tween(body, Theme.tween.release, { Position = UDim2.fromOffset(0, 0) })
		end
	end
	pcall(function()
		button.MouseButton1Down:Connect(function()
			if state.disabled then
				return
			end
			state.pressed = true
			tween(body, Theme.tween.press, { Position = UDim2.fromOffset(0, if state.hasLip then state.lip - 1 else 1) })
		end)
		button.MouseButton1Up:Connect(release)
		button.MouseLeave:Connect(function()
			release()
			if UserInputService.TouchEnabled == true then
				return
			end
			if state.rest then
				tween(body, Theme.tween.hover, { BackgroundColor3 = state.rest })
			else
				tween(body, Theme.tween.hover, { BackgroundTransparency = 1 })
			end
		end)
		if UserInputService.TouchEnabled ~= true then
			button.MouseEnter:Connect(function()
				if state.disabled then
					return
				end
				if state.rest then
					tween(body, Theme.tween.hover, { BackgroundColor3 = state.hover })
				else
					body.BackgroundColor3 = state.hover
					tween(body, Theme.tween.hover, { BackgroundTransparency = 0 })
				end
			end)
		end
		button:GetAttributeChangedSignal("Disabled"):Connect(function()
			styleButton(button)
		end)
		button:GetAttributeChangedSignal("ButtonKind"):Connect(function()
			styleButton(button)
		end)
	end)
	if opts.onClick then
		button.MouseButton1Click:Connect(function(...)
			if button:GetAttribute("Disabled") == true then
				return
			end
			opts.onClick(...)
		end)
	end
	if opts.layout ~= true then
		UIStyle.anchorCenter(button)
	end
	button.Parent = parent
	return button
end, function(parent, opts)
	opts = opts or {}
	local button = plain(parent, "TextButton", opts.name or "Button", { Text = opts.text or "", Size = UDim2.fromOffset(if type(opts.width) == "number" then opts.width else 140, 44), Position = opts.position })
	if opts.onClick then
		button.MouseButton1Click:Connect(opts.onClick)
	end
	return button
end)

-- ---------------------------------------------------------------------
-- BAŞLIK ÇUBUĞU: UIStyle.header(panel, {title, subtitle, icon (Config.Icons.X), emoji, accent, onClose, chip (yazı)}) -> { bar, close, titleLabel, subtitleLabel, chip, iconChip }
--   60 px, panelin PARÇASI (ayrı renkli şerit yok), alt ayırıcı çizgi. Sol: 40 px vurgu tonlu çip içinde headerIcon (ikon = pencereyi açan menü düğmesinin ikonu).
--   Başlık BÜYÜK HARF GothamBlack 22. Sağ: 36 px ghost daire X ('Close'; her pencerede aynı yerde). chip: kapat düğmesinin soluna sayaç çipi ('HeaderChip', UIStyle.setChipText ile güncellenir).
-- ---------------------------------------------------------------------
UIStyle.header = guard("header", function(panel, opts)
	opts = opts or {}
	local colors = accentOf(opts.accent)
	local bar = makeInstance("Frame", "Header", nil, { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60), Active = false })
	local textLeft = 16
	local iconChip = nil
	if opts.icon or opts.emoji then
		iconChip = makeInstance("Frame", "IconChip", bar, {
			BackgroundColor3 = colors.base,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.fromOffset(40, 40),
		})
		UIStyle.round(iconChip, Theme.radius.button)
		UIStyle.headerIcon(iconChip, opts.icon, opts.emoji or "", { Position = UDim2.new(0.5, -12, 0.5, -12), Size = UDim2.fromOffset(24, 24) })
		textLeft = 68
	end
	local hasSub = opts.subtitle ~= nil and opts.subtitle ~= ""
	local titleLabel = makeInstance("TextLabel", "Title", bar, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textLeft, if hasSub then 9 else 0),
		Size = UDim2.new(1, -(textLeft + 70), 0, if hasSub then 26 else 60),
		Font = Theme.fonts.title,
		TextSize = Theme.textSize.title,
		TextColor3 = Theme.colors.text,
		Text = string.upper(opts.title or ""),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local subtitleLabel = nil
	if hasSub then
		subtitleLabel = makeInstance("TextLabel", "Subtitle", bar, {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(textLeft, 34),
			Size = UDim2.new(1, -(textLeft + 70), 0, 16),
			Font = Theme.fonts.body,
			TextSize = Theme.textSize.caption,
			TextColor3 = Theme.colors.textDim,
			Text = opts.subtitle,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	local close = makeInstance("TextButton", "Close", bar, {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.colors.card,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(36, 36),
		Font = Theme.fonts.title,
		TextSize = 16,
		TextColor3 = Theme.colors.text,
		Text = "X",
	})
	UIStyle.round(close, UDim.new(1, 0))
	thinStroke(close, 1)
	pcall(function()
		if UserInputService.TouchEnabled ~= true then
			close.MouseEnter:Connect(function()
				tween(close, Theme.tween.hover, { BackgroundColor3 = Theme.colors.danger.base })
			end)
			close.MouseLeave:Connect(function()
				tween(close, Theme.tween.hover, { BackgroundColor3 = Theme.colors.card })
			end)
		end
		close.MouseButton1Down:Connect(function()
			tween(close, Theme.tween.press, { BackgroundColor3 = Theme.colors.danger.dark })
		end)
	end)
	if opts.onClose then
		close.MouseButton1Click:Connect(function(...)
			opts.onClose(...)
		end)
	end
	local chip = nil
	if opts.chip then
		chip = UIStyle.chip(bar, { name = "HeaderChip", text = tostring(opts.chip), accent = opts.accent, props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0) } })
	end
	makeInstance("Frame", "HeaderDivider", bar, {
		BackgroundColor3 = Theme.colors.line,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
	})
	bar.Parent = panel
	return { bar = bar, close = close, titleLabel = titleLabel, subtitleLabel = subtitleLabel, chip = chip, iconChip = iconChip }
end, function(panel, opts)
	opts = opts or {}
	local bar = plain(panel, "Frame", "Header", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60) })
	local titleLabel = plain(bar, "TextLabel", "Title", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Text = opts.title or "" })
	local close = plain(bar, "TextButton", "Close", { Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -44, 0, 12), Text = "X" })
	if opts.onClose then
		close.MouseButton1Click:Connect(opts.onClose)
	end
	return { bar = bar, close = close, titleLabel = titleLabel }
end)

-- ---------------------------------------------------------------------
-- SEKMELER: UIStyle.tabs(parent, {items = {"A", "B"} ya da {{id=, text=}}, accent, selected, onSelect(id), name, props}) -> { frame, buttons, select(id), current() }
--   panelHigh hap kapsayıcı (radius 12, padding 4); seçili sekme vurgu dolgulu, diğerleri ghost; 0.15 sn renk tween. Düğmeler 'Tab_<id>' (TextButton, Text doğrudan üzerinde).
-- ---------------------------------------------------------------------
UIStyle.tabs = guard("tabs", function(parent, opts)
	opts = opts or {}
	local colors = accentOf(opts.accent or "info")
	local frame = makeInstance("Frame", opts.name or "Tabs", nil, { BackgroundColor3 = Theme.colors.panelHigh, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 44) })
	applyProps(frame, opts.props)
	UIStyle.round(frame, Theme.radius.button)
	makeInstance("UIPadding", "Padding", frame, { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
	makeInstance("UIListLayout", "Layout", frame, { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
	local items = opts.items or {}
	local count = math.max(1, #items)
	local buttons, order = {}, {}
	local current = nil
	local api = { frame = frame, buttons = buttons }
	local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	function api.select(id, silent)
		if buttons[id] == nil then
			return
		end
		current = id
		for tabId, tabButton in buttons do
			local on = tabId == id
			tween(tabButton, info, {
				BackgroundColor3 = if on then colors.base else Theme.colors.panelHigh,
				BackgroundTransparency = if on then 0 else 1,
				TextColor3 = if on then colors.text else Theme.colors.textDim,
			})
			tabButton:SetAttribute("Selected", on)
		end
		if not silent and opts.onSelect then
			opts.onSelect(id)
		end
	end
	function api.current()
		return current
	end
	for index, item in items do
		local id = if type(item) == "table" then item.id or item.text else item
		local text = if type(item) == "table" then item.text or tostring(item.id) else item
		local tabButton = makeInstance("TextButton", "Tab_" .. tostring(id), nil, {
			AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			BackgroundColor3 = Theme.colors.panelHigh,
			Size = UDim2.new(1 / count, -4 * (count - 1) / count, 1, 0),
			Font = Theme.fonts.bold,
			TextSize = 14,
			TextColor3 = Theme.colors.textDim,
			Text = text,
			LayoutOrder = index,
		})
		UIStyle.round(tabButton, Theme.radius.chip + 2)
		tabButton.MouseButton1Click:Connect(function()
			api.select(id)
		end)
		tabButton.Parent = frame
		buttons[id] = tabButton
		table.insert(order, id)
	end
	api.select(opts.selected or order[1], true)
	frame.Parent = parent
	return api
end, function(parent, opts)
	local frame = plain(parent, "Frame", (opts and opts.name) or "Tabs", { Size = UDim2.new(1, 0, 0, 44) })
	return { frame = frame, buttons = {}, select = function() end, current = function() end }
end)

-- ---------------------------------------------------------------------
-- ANİMASYON YARDIMCILARI
-- ---------------------------------------------------------------------
-- Basma geri bildirimi (düğme DIŞI nesneler için; UIStyle.button kendi dudak animasyonunu yapar): 0.08 sn UIScale 0.96, bırakınca 0.12 Back.
-- Önce anchorCenter çağrılır (opts.anchor = false ile kapat, Layout içindeyse). Aynı nesneye iki kez bağlanmaz.
function UIStyle.press(btn, opts)
	opts = opts or {}
	pcall(function()
		if btn:GetAttribute("UIStylePress") then
			return
		end
		btn:SetAttribute("UIStylePress", true)
		if opts.anchor ~= false then
			UIStyle.anchorCenter(btn)
		end
		local scale = btn:FindFirstChild("PressScale") or makeInstance("UIScale", "PressScale", btn, {})
		btn.MouseButton1Down:Connect(function()
			tween(scale, Theme.tween.press, { Scale = opts.scale or 0.96 })
		end)
		local function back()
			tween(scale, Theme.tween.release, { Scale = 1 })
		end
		btn.MouseButton1Up:Connect(back)
		btn.MouseLeave:Connect(back)
	end)
	return btn
end

-- Pop: UIScale 1.06 -> 1, 0.2 sn Back (yeni gelen/ödül alınan karta). Nesne ortadan büyüsün diye anchorCenter çağrılır (Layout içindeyse opts.anchor = false).
function UIStyle.pop(obj, opts)
	opts = opts or {}
	pcall(function()
		if opts.anchor ~= false then
			UIStyle.anchorCenter(obj)
		end
		local scale = obj:FindFirstChild("PopScale") or makeInstance("UIScale", "PopScale", obj, {})
		scale.Scale = opts.from or 1.06
		tween(scale, Theme.tween.pop, { Scale = 1 })
	end)
	return obj
end

-- Sayı sayma: label.Text'i 'from'dan 'to'ya 0.5 sn Quad Out ile akıtır; formatFn(sayı) -> yazı (varsayılan tam sayı). Aynı etikette yeni çağrı eskiyi iptal eder.
-- Hafif modda (ve from == to) hemen son değer. Son yazı her durumda garantilidir (task.delay).
local countTokens = setmetatable({}, { __mode = "k" })
function UIStyle.countTo(label, from, to, formatFn)
	local format = formatFn or function(value)
		return tostring(math.floor(value + 0.5))
	end
	pcall(function()
		countTokens[label] = (countTokens[label] or 0) + 1
		local token = countTokens[label]
		if isLow() or from == to then
			label.Text = format(to)
			return
		end
		label.Text = format(from)
		local value = Instance.new("NumberValue")
		value.Value = from
		value.Changed:Connect(function(current)
			if countTokens[label] == token then
				label.Text = format(current)
			end
		end)
		tween(value, Theme.tween.count, { Value = to })
		task.delay(0.55, function()
			if countTokens[label] == token then
				label.Text = format(to)
			end
			value:Destroy()
		end)
	end)
end

-- Ortada açılan modaller (Wheel, Offline, WhatsNew, Rebirth onayı): Visible = true, UIScale 0.92 -> 1 (0.28 sn Back) + zeminin belirmesi.
-- Çerçeve ortadan büyüsün diye anchorCenter bir kez çağrılır (sonradan Position yazarsan MERKEZİ yazarsın).
function UIStyle.fadeScaleIn(frame)
	pcall(function()
		if not frame:GetAttribute("UIStyleCentered") then
			frame:SetAttribute("UIStyleCentered", true)
			UIStyle.anchorCenter(frame)
		end
		local scale = frame:FindFirstChild("ModalScale") or makeInstance("UIScale", "ModalScale", frame, {})
		local base = frame:GetAttribute("BaseTransparency")
		if base == nil then
			base = frame.BackgroundTransparency
			frame:SetAttribute("BaseTransparency", base)
		end
		frame.Visible = true
		if isLow() then
			scale.Scale = 1
			frame.BackgroundTransparency = base
			return
		end
		scale.Scale = 0.92
		frame.BackgroundTransparency = 1
		tween(scale, Theme.tween.panelIn, { Scale = 1 })
		tween(frame, Theme.tween.panelIn, { BackgroundTransparency = base })
	end)
	return frame
end

-- Kapanış: 0.18 sn küçülüp solar, sonra Visible = false (ölçek/saydamlık geri yüklenir, tekrar açılabilsin). onDone: kapanınca çağrılır.
function UIStyle.fadeScaleOut(frame, onDone)
	pcall(function()
		local scale = frame:FindFirstChild("ModalScale") or makeInstance("UIScale", "ModalScale", frame, {})
		local base = frame:GetAttribute("BaseTransparency")
		if base == nil then
			base = frame.BackgroundTransparency
			frame:SetAttribute("BaseTransparency", base)
		end
		local function finish()
			frame.Visible = false
			scale.Scale = 1
			frame.BackgroundTransparency = base
			if onDone then
				onDone()
			end
		end
		if isLow() then
			finish()
			return
		end
		tween(scale, Theme.tween.panelOut, { Scale = 0.94 })
		tween(frame, Theme.tween.panelOut, { BackgroundTransparency = 1 })
		task.delay(0.2, finish)
	end)
	return frame
end

return UIStyle
