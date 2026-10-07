local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Layout = require(Shared:WaitForChild("Layout"))
local PetFollowers = require(script.PetFollowers)
local PetsPanel = require(script.PetsPanel)
local GiftsPanel = require(script.GiftsPanel)
local CosmeticPanel = require(script.CosmeticPanel)
local ShoeShop = require(script.ShoeShop)
local SkinShop = require(script.SkinShop)
local TrainingClient = require(script.TrainingClient)
local EggShop = require(script.EggShop)
local DevPanel = require(script.DevPanel)
local RebirthPanel = require(script.RebirthPanel)
local WallClient = require(script.WallClient)
local Moves = require(script.Moves)
local UIStyle = require(script.UIStyle)
local PanelManager = require(script.PanelManager)

local clickEvent = ReplicatedStorage:WaitForChild("Click")
local moveEvent = ReplicatedStorage:WaitForChild("MoveEvent")
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cfg = Config.Wall

player.CameraMaxZoomDistance = Config.CameraMaxZoom

local FONT = Enum.Font.FredokaOne

-- Yeni/isteğe bağlı modüller korumalı yüklenir ve başlatılır: biri hata verirse oyunun geri kalanı çalışmaya devam eder
local startupErrors = {} -- [modül adı] = hata metni: açılış hatası oyuncuya da gösterilebilsin (Output'a bakmadan; örneğin çark)
local function loadOptional(name)
	local module = script:FindFirstChild(name)
	if not module then
		startupErrors[name] = "module not found"
		return nil
	end
	local ok, result = pcall(require, module)
	if not ok then
		startupErrors[name] = tostring(result)
		warn(`[Client] Could not load {name}: {result}`)
		return nil
	end
	return result
end

local function safeInit(label, module, ...)
	if module and module.init then
		local ok, err = pcall(module.init, ...)
		if not ok then
			warn(`[Client] {label} init failed: {err}`)
		end
	end
end

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Kalın siyah kenarlı yazı (referans oyundaki gibi)
local function makeText(parent, props, maxTextSize, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UITextSizeConstraint", { MaxTextSize = maxTextSize }, label)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Sibling: ZIndex sadece aynı ebeveynin çocukları arasında sıralar (Global'de yüksek ZIndex'li bir torun, ebeveyninin dışına çıkıp
-- sonradan açılan pencerelerin ÜSTÜNE biniyordu: Auto Click'in OFF rozeti Gifts penceresinin üstünde görünüyordu)
local hudGui = create("ScreenGui", { Name = "StatsGui", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)

-- ÖLÇEK KÖKÜ: bütün HUD ve pencereler (screenGui) bu çerçevenin içine kurulur; çerçevenin UIScale'i ekran yüksekliğine göre ayarlanır (Config.UI),
-- böylece arayüz her ekranda referans oyundaki oranda büyük görünür. Çerçeve 1/scale boyutundadır, ölçeklenince ekranı tam kaplar
-- (sağ/alt kenara yaslı parçalar yerinde kalır). Modüllere bu çerçeve verilir; onlar için ScreenGui gibi davranır.
local screenGui = create("Frame", { Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, hudGui)
local rootScale = create("UIScale", { Name = "RootScale" }, screenGui)
local function updateRootScale()
	local camera = workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else Config.UI.ReferenceHeight
	local scale = math.clamp(height / Config.UI.ReferenceHeight, Config.UI.MinScale, Config.UI.MaxScale)
	rootScale.Scale = scale
	screenGui.Size = UDim2.fromScale(1 / scale, 1 / scale)
end
updateRootScale()
do
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateRootScale)
	end
end

-- =====================================================================
-- ÜST ORTA: hedef şeridi (oyuncuya ne yapacağını söyler)
-- =====================================================================
local banner = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.new(0.55, 0, 0, 46),
	BackgroundColor3 = Color3.fromRGB(35, 35, 42),
	BackgroundTransparency = 0.15,
}, screenGui)
create("UISizeConstraint", { MaxSize = Vector2.new(560, 46), MinSize = Vector2.new(260, 46) }, banner)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, banner)
create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(190, 190, 205) }, banner)
UIStyle.soften(banner, { radius = 10, strength = 0.25, shine = false })
local bannerText = makeText(banner, {
	Position = UDim2.fromOffset(12, 4),
	Size = UDim2.new(1, -24, 1, -8),
	TextColor3 = Color3.new(1, 1, 1),
}, 24, 2)

-- Eğitimin ilk adımında ('Click to squat... (n/30)') yazının altında ilerleme çubuğu
local bannerBar = create("Frame", {
	Position = UDim2.new(0, 0, 1, 5),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundColor3 = Color3.fromRGB(30, 32, 44),
	BorderSizePixel = 0,
	Visible = false,
}, banner)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bannerBar)
create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, bannerBar)
local bannerFill = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(110, 255, 140),
	BorderSizePixel = 0,
}, bannerBar)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bannerFill)

-- =====================================================================
-- SOL ÜST: sayaçlar (Rebirth sayısı ve Win)
-- =====================================================================
-- Görselin (ikonun) etrafına siyah dış çizgi ve gölge katmanları ekler: ImageLabel'in kendi çizgisi olmadığı için aynı görselin siyaha boyanmış
-- kopyaları 8 yöne 1.6 px kaydırılır (dış çizgi) ve biri aşağıya kaydırılıp yarı saydam bırakılır (gölge). Referanstaki parlak, çizgili ikon görünümü.
local OUTLINE_OFFSETS = { { -1.6, 0 }, { 1.6, 0 }, { 0, -1.6 }, { 0, 1.6 }, { -1.2, -1.2 }, { 1.2, -1.2 }, { -1.2, 1.2 }, { 1.2, 1.2 } }
local function addOutlinedIcon(parent, imageId, size, position, anchor)
	local holder = create("Frame", {
		AnchorPoint = anchor,
		Position = position,
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, parent)
	local function layer(dx, dy, color, transparency, zIndex)
		return create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(dx, dy),
			Size = UDim2.fromScale(1, 1),
			Image = imageId,
			ImageColor3 = color,
			ImageTransparency = transparency,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = zIndex,
		}, holder)
	end
	layer(0, 3.5, Color3.new(0, 0, 0), 0.55, 2) -- gölge
	for _, offset in OUTLINE_OFFSETS do
		layer(offset[1], offset[2], Color3.new(0, 0, 0), 0, 2)
	end
	layer(0, 0, Color3.new(1, 1, 1), 0, 3) -- asıl görsel en üstte
	return holder
end

local function makeStatChip(order, icon, imageId)
	-- Referanstaki gibi hapsız: büyük ikon ve yanında büyük, kalın siyah kenarlı rakam (dünyanın üstünde yüzer)
	local row = create("Frame", {
		Position = UDim2.fromOffset(14, 60 + (order - 1) * 50),
		Size = UDim2.fromOffset(150, 48),
		BackgroundTransparency = 1,
	}, screenGui)
	-- Hale: ekranın sol kenarından başlayıp sağa doğru silinen yarı saydam gri şerit (referanstaki gibi); üst ve alt kenarında ince açık çizgi.
	-- Satırların arkasında durur (ZIndex 0), ikon ve rakam üstte kalır.
	local band = create("Frame", {
		Position = UDim2.fromOffset(-14, 0),
		Size = UDim2.fromOffset(300, 48),
		BackgroundColor3 = Color3.fromRGB(46, 48, 64),
		BorderSizePixel = 0,
		ZIndex = 0,
	}, row)
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.55, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, band)
	for _, edge in { 0, 1 } do
		local line = create("Frame", {
			AnchorPoint = Vector2.new(0, edge),
			Position = UDim2.new(0, 0, edge, 0),
			Size = UDim2.new(1, 0, 0, 1.5),
			BackgroundColor3 = Color3.fromRGB(235, 238, 255),
			BorderSizePixel = 0,
			ZIndex = 0,
		}, band)
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(0.6, 0.75),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, line)
	end
	if imageId and imageId ~= "" then
		addOutlinedIcon(row, imageId, 44, UDim2.fromOffset(0, 2), Vector2.new(0, 0))
	else
		makeText(row, { Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(44, 44), Text = icon }, 38, 0)
	end
	return makeText(row, {
		Position = UDim2.fromOffset(54, 4),
		Size = UDim2.new(1, -54, 1, -8),
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 36, 3)
end
local rebirthLabel = makeStatChip(1, "🔄", Config.Icons.Rebirth)
local winLabel = makeStatChip(2, "🏆", Config.Icons.Wins)

-- =====================================================================
-- SOL: 2 sütun x 3 satır kare butonlar (Shop, Rebirth, Settings, Backpack, Pets, Gifts)
-- =====================================================================
-- Buton referanstaki gibi: kalın siyah dış çizgi, İÇİNDE ince RENKLİ GRADYAN ÇERÇEVE (buton arka planı = gradyan, üstüne koyu iç panel biner),
-- koyu zeminde büyük ikon (siyah çizgili + gölgeli) ve butonun en altında, ikonun altına binen kalın kenarlı küçük yazı.
-- accent = { üst-sol renk, alt-sağ renk } çerçevenin gradyanı; imageId doluysa ikon bu görsel (Config.Icons), boşsa emoji.
local BORDER = 4
-- iconSize: görselin kenarı (varsayılan 56). Kenarlara kadar dolu görseller (Auras alevi) taşmasın diye küçültülür (Config.IconSizes)
local function makeSquareButton(position, icon, label, accent, imageId, iconSize)
	local button = create("TextButton", {
		Position = position,
		Size = UDim2.fromOffset(74, 74),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
	local borderGradient = create("UIGradient", { Color = ColorSequence.new(accent[1], accent[2]), Rotation = 45 }, button)

	local inner = create("Frame", {
		Position = UDim2.fromOffset(BORDER, BORDER),
		Size = UDim2.new(1, -BORDER * 2, 1, -BORDER * 2),
		BackgroundColor3 = Color3.fromRGB(24, 27, 46),
		BackgroundTransparency = 0.1,
	}, button)
	UIStyle.soften(inner, { radius = 5, strength = 0.35, shine = false })
	-- Üstüne gelince iç zemin hafif aydınlanır
	button.MouseEnter:Connect(function()
		inner.BackgroundColor3 = Color3.fromRGB(44, 48, 78)
	end)
	button.MouseLeave:Connect(function()
		inner.BackgroundColor3 = Color3.fromRGB(24, 27, 46)
	end)

	if imageId and imageId ~= "" then
		iconSize = iconSize or 56
		addOutlinedIcon(button, imageId, iconSize, UDim2.new(0.5, 0, 0, 2 + (56 - iconSize) / 2), Vector2.new(0.5, 0))
	else
		makeText(button, {
			Position = UDim2.fromScale(0.1, 0.03),
			Size = UDim2.fromScale(0.8, 0.62),
			Text = icon,
			ZIndex = 3,
		}, 44, 0)
	end
	local caption = makeText(button, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -1),
		Size = UDim2.fromScale(0.94, 0.26),
		Text = label,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
	}, 16, 3)

	-- Çerçeve renklerini sonradan değiştirmek için (Rebirth hazır olunca parlar)
	local function setAccent(top, bottom)
		borderGradient.Color = ColorSequence.new(top, bottom)
	end
	return button, caption, setAccent
end

local function makeGridButton(index, icon, label, accent, imageId)
	local column = (index - 1) % 2
	local row = (index - 1) // 2
	return makeSquareButton(UDim2.fromOffset(14 + column * 82, 166 + row * 82), icon, label, accent, imageId)
end

local icons = Config.Icons
local shopButton = makeGridButton(1, "🛒", "Shop", { Color3.fromRGB(255, 160, 60), Color3.fromRGB(180, 70, 235) }, icons.Shop)
local REBIRTH_DIM = { Color3.fromRGB(120, 120, 150), Color3.fromRGB(70, 70, 100) }
local REBIRTH_READY = { Color3.fromRGB(255, 70, 175), Color3.fromRGB(255, 205, 60) }
local rebirthButton, rebirthCaption, setRebirthAccent = makeGridButton(2, "🔄", "Rebirth", REBIRTH_DIM, icons.Rebirth)
local settingsButton = makeGridButton(3, "⚙️", "Settings", { Color3.fromRGB(165, 190, 225), Color3.fromRGB(85, 105, 150) }, icons.Settings)
local backpackButton = makeGridButton(4, "🎒", "Backpack", { Color3.fromRGB(70, 230, 235), Color3.fromRGB(60, 110, 255) }, icons.Backpack)
local petsButton = makeGridButton(5, "🐾", "Pets", { Color3.fromRGB(255, 215, 70), Color3.fromRGB(190, 120, 30) }, icons.Pets)
local giftsButton = makeGridButton(6, "🎁", "Gifts", { Color3.fromRGB(110, 235, 100), Color3.fromRGB(40, 150, 75) }, icons.Gifts)

-- Rebirth hazır olunca buton nabız gibi büyüyüp küçülür (dikkat çeker)
local rebirthPulse = create("UIScale", { Scale = 1 }, rebirthButton)
local rebirthPulseTween = TweenService:Create(rebirthPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 })

-- Gifts butonundaki alınabilir ödül sayısı rozeti
local giftsBadge = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Color3.fromRGB(235, 40, 50),
	Visible = false,
	ZIndex = 8,
}, giftsButton)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, giftsBadge)
create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, giftsBadge)
local giftsBadgeText = makeText(giftsBadge, {
	Position = UDim2.fromScale(0.1, 0.1),
	Size = UDim2.fromScale(0.8, 0.8),
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 9,
}, 16, 1)

-- Backpack: Trails/Auras sekmeleri, açık olan panelin SOL tarafında dikey iki buton olarak durur.
local backpackMenu = create("Frame", {
	Position = UDim2.new(0.5, -280 - 14 - 74, 0.5, -78),
	Size = UDim2.fromOffset(74, 156),
	BackgroundTransparency = 1,
	Visible = false,
}, screenGui)
local function makeMenuButton(row, icon, label, accent, imageId, iconSize)
	local button = makeSquareButton(UDim2.fromOffset(0, row * 82), icon, label, accent, imageId, iconSize)
	button.Parent = backpackMenu
	return button
end
local trailsButton = makeMenuButton(0, "✨", "Trails", { Color3.fromRGB(255, 120, 190), Color3.fromRGB(235, 60, 130) }, Config.Icons.Trails, Config.IconSizes.Trails)
local aurasButton = makeMenuButton(1, "🔮", "Auras", { Color3.fromRGB(200, 120, 255), Color3.fromRGB(110, 70, 235) }, Config.Icons.Auras, Config.IconSizes.Auras)

-- Rebirth butonunun üstündeki yüzde rozeti (level / üst sınır)
local rebirthBadge = makeText(rebirthButton, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromScale(0.9, 0.3),
	TextColor3 = Color3.new(1, 1, 1),
}, 18, 2)
rebirthBadge.ZIndex = 3

-- =====================================================================
-- ALT ORTA: sayaçlar, level çubuğu ve Auto Click
-- =====================================================================
local bottom = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -14),
	Size = UDim2.new(0.5, 0, 0, 180),
	BackgroundTransparency = 1,
	ZIndex = 0, -- alt grup (level çubuğu, Auto Click) açılan pencerelerin hep ALTINDA kalır
}, screenGui)
create("UISizeConstraint", { MaxSize = Vector2.new(580, 180), MinSize = Vector2.new(320, 180) }, bottom)

-- Level sınırında çıkan uyarı (çubuğun üstünde)
local rebirthHint = makeText(bottom, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -34),
	Size = UDim2.new(1, 0, 0, 30),
	Text = "Rebirth to unlock more levels!",
	TextColor3 = Color3.fromRGB(255, 50, 140),
	Visible = false,
}, 26, 3)

-- Üst bilgi iki satırdır (eskiden tek satırda üst üste biniyordu): 1. satır büyük 'Leg Muscle' sayısı, 2. satır solda çarpan, sağda tıklama başı kazanç
local multiplierLabel = makeText(bottom, {
	Position = UDim2.fromOffset(2, 42),
	Size = UDim2.new(0.48, 0, 0, 24),
	TextColor3 = Color3.fromRGB(110, 255, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
}, 24, 2)

local muscleLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.new(0.7, 0, 0, 40),
	TextColor3 = Color3.new(1, 1, 1),
}, 36, 3)
local pop = create("UIScale", {}, muscleLabel)

local gainLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -2, 0, 42),
	Size = UDim2.new(0.5, 0, 0, 24),
	TextColor3 = Color3.fromRGB(255, 220, 90),
	TextXAlignment = Enum.TextXAlignment.Right,
}, 24, 2)

local bar = create("Frame", {
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = Color3.fromRGB(70, 10, 45),
}, bottom)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, bar)
create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, bar)
UIStyle.soften(bar, { radius = 12, strength = 0.35, shine = false })

local barFill = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(255, 20, 130),
	BorderSizePixel = 0,
}, bar)
UIStyle.soften(barFill, { radius = 12, strength = 0.3 })

local stageLabel = makeText(bar, {
	Position = UDim2.fromOffset(14, 4),
	Size = UDim2.new(0.5, 0, 1, -8),
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
}, 38, 3)
local countLabel = makeText(bar, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 4),
	Size = UDim2.new(0.4, 0, 1, -8),
	TextColor3 = Color3.new(1, 1, 1),
	TextXAlignment = Enum.TextXAlignment.Right,
}, 38, 3)

-- Auto Click: açıkken hareketler kendiliğinden tekrarlanır (ileride VIP'ye özel yapılabilir).
-- Referanstaki gibi: GÖKKUŞAĞI renkli, kayan zemin (açıkken daha hızlı ve parlak) ve üst kenarda "OFF" / "ON" rozeti.
local autoButton = create("TextButton", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 138),
	Size = UDim2.fromOffset(220, 40),
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(1, 1, 1), -- renk gökkuşağı gradyanından gelir
}, bottom)
create("UICorner", { CornerRadius = UDim.new(0, 6) }, autoButton)
create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, autoButton)
UIStyle.soften(autoButton, { radius = 12, gradient = false }) -- sadece köşe ve üst parlak şerit; gradyanı gökkuşağı verir
local autoRainbow = create("UIGradient", {}, autoButton)
local autoLabel = makeText(autoButton, {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 1, -12),
	Text = "Auto Click",
	TextColor3 = Color3.new(1, 1, 1),
}, 26, 3)
local autoBadge = makeText(autoButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 1),
	Size = UDim2.fromOffset(64, 26),
	Text = "OFF",
	TextColor3 = Color3.fromRGB(255, 92, 70),
	ZIndex = 5,
}, 22, 3)

-- Kayıt uyarısı sadece Studio'da ve küçük görünür (canlı oyunda oyuncular görmez, hata Output'a yazılır)
local warning = create("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 14, 1, -10),
	Size = UDim2.fromOffset(300, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 170, 90),
	Text = "Studio: saving is off (publish the game + enable API access)",
	Visible = false,
}, screenGui)

-- =====================================================================
-- DEĞERLER
-- =====================================================================
local leaderstats = player:WaitForChild("leaderstats")
local muscleValue = leaderstats:WaitForChild(Config.StatLegMuscle)
local winValue = leaderstats:WaitForChild(Config.StatWins)
local levelValue = leaderstats:WaitForChild(Config.StatLevel)
local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)

local autoClick = false

local function refresh()
	muscleLabel.Text = `{Format.compact(muscleValue.Value)} {Config.StatLegMuscle}` -- referanstaki '2M Punch' gibi: önce sayı (büyük sayılar K/M/B ile kısalır)
	winLabel.Text = Format.number(winValue.Value)
	rebirthLabel.Text = Format.number(rebirthValue.Value)
	-- Antrenman alanındayken kazanç pedin çarpanıyla çarpılır (sunucu AreaMultiplier'ı pede girince ayarlar)
	local areaMultiplier = player:GetAttribute("AreaMultiplier") or 1
	local perClick = math.floor((player:GetAttribute("PerClick") or 1) * areaMultiplier)
	gainLabel.Text = `+{Format.short(perClick)}/click  x{Format.multiplier(player:GetAttribute("DamageMultiplier") or 1)} dmg`
	multiplierLabel.Text = `x{Format.multiplier((player:GetAttribute("TotalMultiplier") or 1) * areaMultiplier)} Multiplier`
	autoBadge.Text = if autoClick then "ON" else "OFF"
	autoBadge.TextColor3 = if autoClick then Color3.fromRGB(110, 255, 130) else Color3.fromRGB(255, 92, 70)
	warning.Visible = RunService:IsStudio() and player:GetAttribute("DataError") == true
end

muscleValue:GetPropertyChangedSignal("Value"):Connect(function()
	refresh()
	pop.Scale = 1.12
	TweenService:Create(pop, TweenInfo.new(0.1), { Scale = 1 }):Play()
end)
winValue:GetPropertyChangedSignal("Value"):Connect(refresh)
rebirthValue:GetPropertyChangedSignal("Value"):Connect(refresh)
player:GetAttributeChangedSignal("PerClick"):Connect(refresh)
player:GetAttributeChangedSignal("TotalMultiplier"):Connect(refresh)
player:GetAttributeChangedSignal("AreaMultiplier"):Connect(refresh)
player:GetAttributeChangedSignal("DamageMultiplier"):Connect(refresh)
player:GetAttributeChangedSignal("DataError"):Connect(refresh)
refresh()

-- Duvar ilerlemesi: üstteki hedef şeridi
-- Banner iki kaynaktan beslenir: duvar ilerlemesi ve antrenman alanı (alandayken "Training..." yazar, çıkınca duvar yazısına döner)
local progressText = bannerText.Text

-- EĞİTİM: üstteki yönerge yazısı SADECE yeni oyuncuya görünür ve oyuncu ilk skinini alana kadar sürer (sunucu 'TutorialDone' bayrağı, Config.Guide notuna bak).
-- Deneyimli oyuncuda yazı gizlidir; sadece antrenman alanındayken 'Training with...' bilgisi için görünür.
local firstSkin = Config.Skins[1]

local function tutorialActive()
	return player:GetAttribute("DataLoaded") == true and player:GetAttribute("TutorialDone") == false
end

local function tutorialClicks()
	return player:GetAttribute("TutorialClicks") or 0
end

local function tutorialText()
	-- 1. adım: squat say. Sunucu hareket başlatılınca sayar; ClickGoal kez olunca oyuncu duvara yönlendirilir
	local goal = Config.Tutorial.ClickGoal
	if tutorialClicks() < goal then
		return `Click anywhere to squat and get stronger!  ({tutorialClicks()}/{goal})`
	end
	local wins = winValue.Value
	if wins >= firstSkin.price then
		return `You have {Format.number(wins)} Wins! Go to the SKIN shelf on the left wall and step on the {firstSkin.name} pad!`
	end
	return progressText
end

local function refreshBanner()
	local areaId = player:GetAttribute("TrainingArea") or ""
	local area = nil
	for _, candidate in Config.Training.Areas do
		if candidate.id == areaId then
			area = candidate
		end
	end
	local showBar = false
	if area then
		banner.Visible = true
		bannerText.Text = `Training with {area.trainer}: x{string.format("%g", area.mult)} Squat!`
	elseif tutorialActive() then
		banner.Visible = true
		bannerText.Text = tutorialText()
		showBar = tutorialClicks() < Config.Tutorial.ClickGoal
	else
		banner.Visible = false
	end
	bannerBar.Visible = showBar
	bannerFill.Size = UDim2.fromScale(math.clamp(tutorialClicks() / Config.Tutorial.ClickGoal, 0, 1), 1)
end

local function onProgress(frontier)
	local broken = frontier - 1

	if frontier > cfg.Count then
		progressText = "Last wall broken! Step on the yellow WIN button!"
	elseif broken == 0 then
		progressText = "Walk into the corridor, get close to the walls and tap!"
	elseif broken % cfg.GroupSize == 0 then
		local done = broken // cfg.GroupSize
		progressText = `Stage {done} complete! Step on the yellow WIN (+{Layout.reward(done)} Wins) or keep going`
	else
		progressText = `Break the walls! ({broken % cfg.GroupSize}/{cfg.GroupSize})`
	end
	refreshBanner()
end
player:GetAttributeChangedSignal("TrainingArea"):Connect(refreshBanner)
player:GetAttributeChangedSignal("TutorialDone"):Connect(refreshBanner)
player:GetAttributeChangedSignal("TutorialClicks"):Connect(refreshBanner)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refreshBanner)
winValue:GetPropertyChangedSignal("Value"):Connect(refreshBanner)
refreshBanner()

ShoeShop.init()
SkinShop.init()
TrainingClient.init()
safeInit("Juice", loadOptional("Juice"), screenGui)
safeInit("OverheadTags", loadOptional("OverheadTags"))
safeInit("BoostHud", loadOptional("BoostHud"), screenGui)
EggShop.init(screenGui)
DevPanel.init(screenGui)
PetFollowers.init()
WallClient.init(onProgress)
safeInit("Guide", loadOptional("Guide"), WallClient)
local Sfx = loadOptional("Sfx")
safeInit("Sfx", Sfx)
safeInit("MusicPlayer", loadOptional("MusicPlayer"), screenGui) -- sağ alttaki teyp

-- =====================================================================
-- HAREKET (tıklama / Auto Click)
-- =====================================================================
-- HER tıklama sunucuya gider ve bacak kasını hemen verir (hareketin bitmesi beklenmez). Hareket (animasyon) ise sadece boştayken başlar:
-- hareket sürerken gelen tıklama yeni animasyon başlatmaz. Duvara hasar sunucudan hareketle gelir (squat bitince, tekmede ayak değince).
local busyUntil = 0

-- Boştaysa bir hareket (tekme/squat) başlatır. Döner: başladı mı
local function playMove()
	if os.clock() < busyUntil then
		return false
	end

	-- Duvara yakınsa tekme (duvara dönerek), uzaktaysa squat
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return false
	end
	-- Havadayken hareket başlatma: bacak sallanması karakteri döndürüp bozuyordu
	if humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end
	local near = WallClient.isNearWall(root.Position)
	local move = if near then "Kick" else "Squat"
	if near then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(0, 0, -1))
	end

	busyUntil = os.clock() + Config.MoveDuration[move]
	Moves.play(character, move)
	-- Tekme sesi ayak duvara değdiği anda çalar; ses istemcide çalındığı için ağ gecikmesi yoktur
	if move == "Kick" and Sfx then
		task.delay(Config.MoveDuration.Kick * Config.MoveContact.Kick, function()
			pcall(Sfx.play, "Kick")
		end)
	end
	return true
end

-- Arayüz butonlarına basmak sayılmaz. Her tıklama sayılır (sunucu hızı sınırlar), animasyon boştayken oynar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
		playMove()
		clickEvent:FireServer()
	end
end)

-- AUTO CLICK açıkken (koçun pedinde de) SERİ SERİ tıklar: saniyede Config.AutoClick.PerSecond tıklama, her tıklama anında kas verir (elle hızlı tıklamayla aynı);
-- animasyon boştayken oynar. Kare atlaması sonrası yığılma olmasın diye birikim en çok 2 tıklamadır. Sunucu hız sınırı Config.ClickLimit'tir.
-- Auto Click KAPALIYKEN açık bir antrenman pedindeyken (sunucu TrainingArea özniteliğini ayarlar) pedin kendi otomatik squat'ı sürer: hareket başına bir tıklama.
local autoCredit = 0
RunService.Heartbeat:Connect(function(dt)
	if autoClick then
		autoCredit = math.min(autoCredit + dt * Config.AutoClick.PerSecond, 2)
		while autoCredit >= 1 do
			autoCredit -= 1
			playMove()
			clickEvent:FireServer()
		end
		return
	end
	autoCredit = 0
	if (player:GetAttribute("TrainingArea") or "") ~= "" then
		if playMove() then
			clickEvent:FireServer()
		end
	end
end)

autoButton.MouseButton1Click:Connect(function()
	autoClick = not autoClick
	refresh()
end)

-- Auto Click gökkuşağı: renk tonu zamanla kayar (kapalıyken yavaş ve biraz sönük, açıkken hızlı ve parlak)
local rainbowShift = 0
RunService.Heartbeat:Connect(function(dt)
	rainbowShift = (rainbowShift + dt * (if autoClick then 0.3 else 0.05)) % 1
	local brightness = if autoClick then 1 else 0.82
	local points = {}
	for index = 0, 6 do
		table.insert(points, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV((rainbowShift + index / 6) % 1, 0.8, brightness)))
	end
	autoRainbow.Color = ColorSequence.new(points)
end)

-- Diğer oyuncuların tekme/squat hareketleri
moveEvent.OnClientEvent:Connect(function(other, move)
	if other and other.Character then
		Moves.play(other.Character, move)
	end
end)

-- =====================================================================
-- BİLDİRİM MESAJI (satın alma sonucu vb.), 2.5 saniye görünür
-- =====================================================================
local toast = makeText(screenGui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.62),
	Size = UDim2.fromOffset(560, 40),
	TextColor3 = Color3.new(1, 1, 1),
	Visible = false,
}, 28, 3)
local toastId = 0


local function showToast(ok, message)
	toastId += 1
	local id = toastId
	-- Başarısız işlemde (Win yetmedi, yer yok...) hata sesi; satın alma/takma başarılıysa satın alma sesi
	if Sfx then
		if not ok then
			pcall(Sfx.play, "Error")
		elseif string.find(message, "^Bought") or string.find(message, "^Equipped") then
			pcall(Sfx.play, "Buy")
		end
	end
	toast.Text = message
	toast.TextColor3 = if ok then Color3.fromRGB(110, 255, 140) else Color3.fromRGB(255, 120, 120)
	toast.Visible = true
	task.delay(2.5, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

notifyEvent.OnClientEvent:Connect(showToast)

-- Eğitim bitince (ilk skin alınınca) kısa tebrik
do
	local wasActive = false
	local function checkTutorialEnd()
		local active = tutorialActive()
		if wasActive and not active and player:GetAttribute("TutorialDone") == true then
			showToast(true, "Great! Keep breaking walls, and open Daily Quests (📜 top right) for free rewards!")
		end
		wasActive = active
	end
	player:GetAttributeChangedSignal("TutorialDone"):Connect(checkTutorialEnd)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(checkTutorialEnd)
	checkTutorialEnd()
end

-- =====================================================================
-- LEVEL ÇUBUĞU VE REBIRTH
-- =====================================================================
local barTween = TweenInfo.new(0.2)
local rebirthReady = false

local function refreshLevel()
	local level = levelValue.Value
	local maxLevel = player:GetAttribute("MaxLevel") or level
	local taps = player:GetAttribute("Taps") or 0
	local needed = player:GetAttribute("TapsNeeded") or 1
	rebirthReady = level >= maxLevel

	stageLabel.Text = `Level {level}`
	if rebirthReady then
		countLabel.Text = "MAX"
		TweenService:Create(barFill, barTween, { Size = UDim2.fromScale(1, 1) }):Play()
	else
		countLabel.Text = `{taps}/{needed}`
		TweenService:Create(barFill, barTween, { Size = UDim2.fromScale(math.clamp(taps / needed, 0, 1), 1) }):Play()
	end

	rebirthHint.Visible = rebirthReady
	rebirthBadge.Text = `{math.floor(math.clamp(level / maxLevel, 0, 1) * 100)}%`
	rebirthCaption.Text = if rebirthReady then "REBIRTH!" else "Rebirth"
	local accent = if rebirthReady then REBIRTH_READY else REBIRTH_DIM
	setRebirthAccent(accent[1], accent[2])
	if rebirthReady then
		rebirthPulseTween:Play()
	else
		rebirthPulseTween:Cancel()
		rebirthPulse.Scale = 1
	end
end

levelValue:GetPropertyChangedSignal("Value"):Connect(refreshLevel)
for _, name in { "Taps", "TapsNeeded", "MaxLevel" } do
	player:GetAttributeChangedSignal(name):Connect(refreshLevel)
end
refreshLevel()

-- Rebirth butonu onay ekranını açar (önce/sonra değerleri ve uyarı gösterir)
local openRebirthPanel = RebirthPanel.init(screenGui, showToast)
rebirthButton.MouseButton1Click:Connect(openRebirthPanel)

-- =====================================================================
-- SOL BUTONLARIN İŞLEVLERİ
-- =====================================================================
local toggleShop = nil -- Shop penceresi aşağıda kurulur; Pets menüsündeki çanta + işareti onu açar
local togglePets = PetsPanel.init(screenGui, showToast, function()
	if toggleShop then
		toggleShop()
	else
		showToast(false, "Shop is coming soon!")
	end
end)
petsButton.MouseButton1Click:Connect(togglePets)

local toggleGifts = GiftsPanel.init(screenGui, showToast, function(count)
	giftsBadge.Visible = count > 0
	giftsBadgeText.Text = tostring(count)
end)
giftsButton.MouseButton1Click:Connect(toggleGifts)

-- Sağ taraftaki FREE REWARD / FRIEND BONUS kutuları (hata verirse oyun çalışır, sadece bu kutular görünmez)
-- Pet Index ve Stats pencereleri (sağ üstteki dairelerle açılır; korumalı yüklenir)
local function loadPanel(name, ...)
	local module = loadOptional(name)
	if module then
		local ok, result = pcall(module.init, ...)
		if ok then
			return result
		end
		startupErrors[name] = tostring(result)
		warn(`[Client] {name} init failed: {result}`)
	end
	return nil
end
local toggleIndex = loadPanel("IndexPanel", screenGui)
local toggleStats = loadPanel("StatsPanel", screenGui)
local toggleQuests = loadPanel("QuestPanel", screenGui, showToast)
local wheelControl = loadPanel("WheelController", screenGui, showToast) -- lobideki günlük çark (hareket, E ile açılan arayüz, tabela yazısı)
-- TEST (Config.Wheel.Debug): çark başlayamadıysa nedeni ekranda KALICI bir kutuda gösterilir (kısa bildirim başka bildirimle ezilebiliyor); çark çalışınca Debug = false yapılır
if Config.Wheel.Debug and not wheelControl then
	local names = {}
	for _, child in script:GetChildren() do
		if string.find(child.Name, "Wheel") then
			table.insert(names, child.Name)
		end
	end
	local box = create("TextLabel", {
		Position = UDim2.fromOffset(12, 120),
		Size = UDim2.fromOffset(560, 120),
		BackgroundColor3 = Color3.fromRGB(120, 0, 0),
		BackgroundTransparency = 0.15,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "WHEEL DEBUG: wheel client did not start.\nError: "
			.. tostring(startupErrors.WheelController or "none (init returned nothing)")
			.. "\nWheel modules found in Client script: "
			.. table.concat(names, ", ")
			.. " (children total: "
			.. tostring(#script:GetChildren())
			.. ")",
		ZIndex = 100,
	}, screenGui)
	warn(`[Client] WHEEL DEBUG: {startupErrors.WheelController}`)
end
-- Çarka E ile basınca: çark modülü açıldıysa arayüzü açar; açılamadıysa nedenini oyuncuya EKRANDA gösterir (Output'a bakmaya gerek kalmasın)
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, who)
	if who ~= player or prompt:GetAttribute("Panel") ~= "Wheel" then
		return
	end
	if wheelControl and wheelControl.open then
		wheelControl.open()
	else
		showToast(false, `The daily wheel could not start: {startupErrors.WheelController or "unknown error"}`)
	end
end)
safeInit("RightHud", loadOptional("RightHud"), screenGui, toggleGifts, showToast, toggleIndex, toggleStats, toggleQuests)

local trailsPanel = CosmeticPanel.init(screenGui, showToast, {
	title = "Trails",
	icon = "✨",
	headerTop = Color3.fromRGB(255, 215, 50),
	headerBottom = Color3.fromRGB(255, 110, 30),
	panelColor = Color3.fromRGB(75, 32, 22),
	items = Config.Trails,
	ownedAttr = "OwnedTrails",
	equippedAttr = "EquippedTrail",
	buyAction = "BuyTrail",
	equipAction = "EquipTrail",
	bonusText = function(item)
		return `👟 +{item.speed} Speed`
	end,
	previewKind = "trail",
})
local aurasPanel = CosmeticPanel.init(screenGui, showToast, {
	title = "Auras",
	icon = "🔮",
	headerTop = Color3.fromRGB(190, 80, 255),
	headerBottom = Color3.fromRGB(125, 40, 205),
	panelColor = Color3.fromRGB(45, 25, 70),
	items = Config.Auras,
	ownedAttr = "OwnedAuras",
	equippedAttr = "EquippedAura",
	buyAction = "BuyAura",
	equipAction = "EquipAura",
	bonusText = function(item)
		return `🦵 x{item.mult} Muscle`
	end,
	previewKind = "aura",
})

-- Backpack: önce Trails açılır; soldaki sekmelerle Auras'a geçilir. Sekmeler (backpackMenu) bir paneli açıkken görünür ve panelle birlikte soldan kayar.
-- Menü kendi başına pencere sayılmaz (exclusive = false): hangi panel açıksa o belirler.
PanelManager.register(backpackMenu, false)
local function refreshTabs()
	if PanelManager.isOpen(trailsPanel.panel) or PanelManager.isOpen(aurasPanel.panel) then
		PanelManager.show(backpackMenu)
	else
		PanelManager.hide(backpackMenu)
	end
end
trailsPanel.panel:GetAttributeChangedSignal("PanelOpen"):Connect(refreshTabs)
aurasPanel.panel:GetAttributeChangedSignal("PanelOpen"):Connect(refreshTabs)

backpackButton.MouseButton1Click:Connect(function()
	if PanelManager.isOpen(trailsPanel.panel) or PanelManager.isOpen(aurasPanel.panel) then
		trailsPanel.hide()
		aurasPanel.hide()
	else
		trailsPanel.show()
	end
end)
trailsButton.MouseButton1Click:Connect(function()
	trailsPanel.show() -- açık olan Auras kendiliğinden kapanır
end)
aurasButton.MouseButton1Click:Connect(function()
	aurasPanel.show()
end)

-- Shop: Robux ürünleri penceresi (korumalı yüklenir: hata verirse buton "coming soon" der)
local ShopPanelModule = loadOptional("ShopPanel")
if ShopPanelModule then
	local okShop, result = pcall(ShopPanelModule.init, screenGui, showToast)
	if okShop then
		toggleShop = result
	else
		warn(`[Client] ShopPanel init failed: {result}`)
	end
end
shopButton.MouseButton1Click:Connect(function()
	if toggleShop then
		toggleShop()
	else
		showToast(false, "Shop is coming soon!")
	end
end)

-- Settings: ses efektleri, müzik, kazanç yazıları, ekran sarsıntısı ve isim etiketleri ayarları (korumalı yüklenir)
local SettingsPanelModule = loadOptional("SettingsPanel")
local toggleSettings = nil
if SettingsPanelModule then
	local okSettings, result = pcall(SettingsPanelModule.init, screenGui)
	if okSettings then
		toggleSettings = result
	else
		warn(`[Client] SettingsPanel init failed: {result}`)
	end
end
settingsButton.MouseButton1Click:Connect(function()
	if toggleSettings then
		toggleSettings()
	else
		showToast(false, "Settings are not available right now.")
	end
end)

-- Çevrimdışı kazanç penceresi (girişte bekleyen kazanç varsa CLAIM ile alınır; korumalı yüklenir)
safeInit("OfflinePanel", loadOptional("OfflinePanel"), screenGui, showToast)
