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
local shopFunction = ReplicatedStorage:WaitForChild("Shop")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cfg = Config.Wall

player.CameraMaxZoomDistance = Config.CameraMaxZoom

local FONT = Enum.Font.FredokaOne

-- Yeni/isteğe bağlı modüller korumalı yüklenir ve başlatılır: biri hata verirse oyunun geri kalanı çalışmaya devam eder
local function loadOptional(name)
	local module = script:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	if not ok then
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

local screenGui = create("ScreenGui", { Name = "StatsGui", ResetOnSpawn = false }, playerGui)

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
local function makeSquareButton(position, icon, label, accent, imageId)
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
		addOutlinedIcon(button, imageId, 56, UDim2.new(0.5, 0, 0, 2), Vector2.new(0.5, 0))
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
local function makeMenuButton(row, icon, label, accent)
	local button = makeSquareButton(UDim2.fromOffset(0, row * 82), icon, label, accent)
	button.Parent = backpackMenu
	return button
end
local trailsButton = makeMenuButton(0, "✨", "Trails", { Color3.fromRGB(255, 120, 190), Color3.fromRGB(235, 60, 130) })
local aurasButton = makeMenuButton(1, "🔮", "Auras", { Color3.fromRGB(200, 120, 255), Color3.fromRGB(110, 70, 235) })

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
	Size = UDim2.new(0.5, 0, 0, 154),
	BackgroundTransparency = 1,
}, screenGui)
create("UISizeConstraint", { MaxSize = Vector2.new(580, 154), MinSize = Vector2.new(320, 154) }, bottom)

-- Level sınırında çıkan uyarı (çubuğun üstünde)
local rebirthHint = makeText(bottom, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -34),
	Size = UDim2.new(1, 0, 0, 30),
	Text = "Rebirth to unlock more levels!",
	TextColor3 = Color3.fromRGB(255, 50, 140),
	Visible = false,
}, 26, 3)

local multiplierLabel = makeText(bottom, {
	Position = UDim2.fromOffset(2, 8),
	Size = UDim2.new(0.25, 0, 0, 26),
	TextColor3 = Color3.fromRGB(110, 255, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
}, 24, 2)

local muscleLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.new(0.36, 0, 0, 40),
	TextColor3 = Color3.new(1, 1, 1),
}, 36, 3)
local pop = create("UIScale", {}, muscleLabel)

local gainLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -2, 0, 8),
	Size = UDim2.new(0.4, 0, 0, 26),
	TextColor3 = Color3.fromRGB(255, 220, 90),
	TextXAlignment = Enum.TextXAlignment.Right,
}, 24, 2)

local bar = create("Frame", {
	Position = UDim2.fromOffset(0, 46),
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
	Position = UDim2.new(0.5, 0, 0, 110),
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
	muscleLabel.Text = `{Config.StatLegMuscle}: {Format.number(muscleValue.Value)}`
	winLabel.Text = Format.number(winValue.Value)
	rebirthLabel.Text = Format.number(rebirthValue.Value)
	-- Antrenman alanındayken kazanç pedin çarpanıyla çarpılır (sunucu AreaMultiplier'ı pede girince ayarlar)
	local areaMultiplier = player:GetAttribute("AreaMultiplier") or 1
	local perClick = math.floor((player:GetAttribute("PerClick") or 1) * areaMultiplier)
	gainLabel.Text = `+{Format.number(perClick)}/click  x{string.format("%g", player:GetAttribute("DamageMultiplier") or 1)} dmg`
	multiplierLabel.Text = `x{string.format("%.2f", (player:GetAttribute("TotalMultiplier") or 1) * areaMultiplier)} Multiplier`
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

local function refreshBanner()
	local areaId = player:GetAttribute("TrainingArea") or ""
	local area = nil
	for _, candidate in Config.Training.Areas do
		if candidate.id == areaId then
			area = candidate
		end
	end
	if area then
		bannerText.Text = `Training with {area.trainer}: x{string.format("%g", area.mult)} Squat!`
	else
		bannerText.Text = progressText
	end
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
-- Bir hareket sürerken yeni tıklamalar yok sayılır. Puan hareket bitince sunucudan gelir.
local busyUntil = 0

local function tryAction()
	if os.clock() < busyUntil then
		return
	end

	-- Duvara yakınsa tekme (duvara dönerek), uzaktaysa squat
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	-- Havadayken hareket başlatma: bacak sallanması karakteri döndürüp bozuyordu
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	local near = WallClient.isNearWall(root.Position)
	local move = if near then "Kick" else "Squat"
	if near then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(0, 0, -1))
	end

	busyUntil = os.clock() + Config.MoveDuration[move]
	Moves.play(character, move)
	clickEvent:FireServer()
end

-- Arayüz butonlarına basmak sayılmaz
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
		tryAction()
	end
end)

-- Auto Click açıkken ya da açık bir antrenman alanındayken (sunucu TrainingArea özniteliğini ayarlar) bir hareket
-- bitince diğeri kendiliğinden başlar: karakter otomatik squat yapar
RunService.Heartbeat:Connect(function()
	if autoClick or (player:GetAttribute("TrainingArea") or "") ~= "" then
		tryAction()
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
local togglePets = PetsPanel.init(screenGui, showToast)
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
		warn(`[Client] {name} init failed: {result}`)
	end
	return nil
end
local toggleIndex = loadPanel("IndexPanel", screenGui)
local toggleStats = loadPanel("StatsPanel", screenGui)
safeInit("RightHud", loadOptional("RightHud"), screenGui, toggleGifts, showToast, toggleIndex, toggleStats)

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
local toggleShop = nil
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
