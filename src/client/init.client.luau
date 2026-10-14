local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Layout = require(Shared:WaitForChild("Layout"))

-- Yükleme ekranı YEDEĞİ: normalde ReplicatedFirst/Loading betiği başlatır (oyundan önce); o senkronlanmadıysa (Rojo yeniden başlatılmadı vb.) ya da geç kaldıysa burada başlar.
-- run() tek örnek korumalıdır: ekran zaten açıksa hemen çıkar. Hata verirse oyun yine açılır.
task.spawn(function()
	local okLoading, errLoading = pcall(function()
		require(Shared:WaitForChild("LoadingScreen")).run()
	end)
	if not okLoading then
		warn(`[Client] Loading screen fallback failed: {errLoading}`)
	end
end)

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

local Theme = UIStyle.Theme
local C = Theme.colors
local FONT = Theme.fonts.bold -- HUD yazıları Gotham ailesi (FredokaOne yalnız marka anlarında)

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

-- Yazı: Gotham, üzerinde yalnız ince (en çok 1.5 px) yarı saydam siyah kontur (okunurluk için; eski kalın siyah kontur kalktı)
local function makeText(parent, props, maxTextSize, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UITextSizeConstraint", { MaxTextSize = maxTextSize }, label)
	if strokeThickness and strokeThickness > 0 then
		create("UIStroke", {
			Thickness = math.min(strokeThickness, 1.5),
			Color = Color3.new(0, 0, 0),
			Transparency = 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		}, label)
	end
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
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.12,
}, screenGui)
create("UISizeConstraint", { MaxSize = Vector2.new(560, 46), MinSize = Vector2.new(260, 46) }, banner)
UIStyle.soften(banner, { radius = Theme.radius.card, style = "flat" })
local bannerText = makeText(banner, {
	Position = UDim2.fromOffset(12, 4),
	Size = UDim2.new(1, -24, 1, -8),
	TextColor3 = Color3.new(1, 1, 1),
}, 24, 2)

-- Eğitimin ilk adımında ('Click to squat... (n/30)') yazının altında ilerleme çubuğu
local bannerBar = create("Frame", {
	Position = UDim2.new(0, 0, 1, 5),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundColor3 = C.cardDeep,
	BorderSizePixel = 0,
	Visible = false,
}, banner)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bannerBar)
create("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.88, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, bannerBar)
local bannerFill = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = C.success.base,
	BorderSizePixel = 0,
}, bannerBar)
create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bannerFill)

-- =====================================================================
-- SOL ÜST: sayaçlar (Rebirth sayısı ve Win)
-- =====================================================================
-- İkon: asıl görselin altına tek bir yumuşak gölge katmanı (eski 8 yönlü kalın siyah dış çizgi kalktı: ekran daha sade, nesne sayısı daha az)
local function addOutlinedIcon(parent, imageId, size, position, anchor)
	local holder = create("Frame", {
		AnchorPoint = anchor,
		Position = position,
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, parent)
	local function layer(dy, color, transparency, zIndex)
		return create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, dy),
			Size = UDim2.fromScale(1, 1),
			Image = imageId,
			ImageColor3 = color,
			ImageTransparency = transparency,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = zIndex,
		}, holder)
	end
	layer(2.5, Color3.new(0, 0, 0), 0.7, 2) -- yumuşak gölge
	layer(0, Color3.new(1, 1, 1), 0, 3) -- asıl görsel en üstte
	return holder
end

-- TELEFON (sahibi 'soldaki her şeyi biraz sola ve yukarı al' dedi): sol HUD (sayaçlar ve 2x3 butonlar) kaydırılır; sadece telefonda (Performance.mobile), masaüstü aynı kalır (Config.UI.Phone)
local PerformanceForLayout = loadOptional("Performance")
local ON_PHONE = PerformanceForLayout ~= nil and PerformanceForLayout.mobile == true
local PHONE_SHIFT_X = if ON_PHONE then Config.UI.Phone.LeftShiftX else 0
local PHONE_SHIFT_Y = if ON_PHONE then Config.UI.Phone.LeftShiftY else 0

local function makeStatChip(order, icon, imageId)
	-- Hap çip: yumuşak koyu kart + ince açık çerçeve, solda ikon, sağda GothamBlack sayı (dünyanın üstünde yüzer)
	local row = create("Frame", {
		Position = UDim2.fromOffset(14 + PHONE_SHIFT_X, 60 + PHONE_SHIFT_Y + (order - 1) * 50),
		Size = UDim2.fromOffset(150, 42),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.2,
	}, screenGui)
	UIStyle.soften(row, { radius = 21, style = "flat", shine = false })
	if imageId and imageId ~= "" then
		addOutlinedIcon(row, imageId, 34, UDim2.fromOffset(6, 4), Vector2.new(0, 0))
	else
		makeText(row, { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(34, 34), Text = icon }, 28, 0)
	end
	return makeText(row, {
		Position = UDim2.fromOffset(46, 4),
		Size = UDim2.new(1, -56, 1, -8),
		TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.fonts.title,
	}, 26, 1)
end
local rebirthLabel = makeStatChip(1, "🔄", Config.Icons.Rebirth)
local winLabel = makeStatChip(2, "🏆", Config.Icons.Wins)
if winLabel.Parent then
	winLabel.Parent.Name = "WinsChip" -- rehber turu (GuideTour) bu adla işaretler
end

-- =====================================================================
-- SOL: 2 sütun x 3 satır kare butonlar (Shop, Rebirth, Settings, Backpack, Pets, Gifts)
-- =====================================================================
-- Buton: yumuşak koyu kart (radius 16) + ince açık çerçeve; renk SADECE ikonun arkasındaki yumuşak tonlu daire gradyanında (accent) ve etikette.
-- Altta GothamBold 12 etiket. accent = { üst-sol renk, alt-sağ renk } dairenin gradyanı; imageId doluysa ikon bu görsel (Config.Icons), boşsa emoji.
local BORDER = 4
-- İki sütun arası (buton başına 74 + boşluk): 82 iken Shop'un köşe rozeti yan düğmeye (Rebirth) değiyordu, sahibi 'arayı açabilirsin' dedi; 90 = 16 birim boşluk
local GRID_PITCH = 90
-- iconSize: görselin kenarı (varsayılan 56 -> kartta 0.8 ile küçülür). Kenarlara kadar dolu görseller (Auras alevi) taşmasın diye küçültülür (Config.IconSizes)
local function makeSquareButton(position, icon, label, accent, imageId, iconSize)
	local button = create("TextButton", {
		Name = label .. "Button", -- ShopButton, RebirthButton, PetsButton...: rehber turu (GuideTour) bu adlarla işaretler
		Position = position,
		Size = UDim2.fromOffset(74, 74),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = C.card,
	}, screenGui)
	UIStyle.anchorCenter(button) -- Rebirth nabzı gibi büyüme/küçülme animasyonları ortadan olsun (sol-üst köşe sabit kalmasın)
	UIStyle.soften(button, { radius = Theme.radius.card + 2, style = "flat", shine = false })

	-- İkonun arkasındaki yumuşak tonlu daire (renk kimliği burada)
	local disc = create("Frame", {
		Name = "AccentDisc",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 5),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		ZIndex = 1,
	}, button)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disc)
	local borderGradient = create("UIGradient", { Color = ColorSequence.new(accent[1], accent[2]), Rotation = 45 }, disc)

	-- Üstüne gelince kart hafif aydınlanır
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = C.cardHover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = C.card
	end)

	if imageId and imageId ~= "" then
		iconSize = math.floor((iconSize or 56) * 0.78)
		addOutlinedIcon(button, imageId, iconSize, UDim2.new(0.5, 0, 0, 5 + (46 - iconSize) / 2), Vector2.new(0.5, 0))
	else
		makeText(button, {
			Position = UDim2.new(0.5, -23, 0, 5),
			Size = UDim2.fromOffset(46, 46),
			Text = icon,
			ZIndex = 3,
		}, 30, 0)
	end
	local caption = makeText(button, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(1, -6, 0, 14),
		Text = label,
		TextColor3 = C.text,
		ZIndex = 5,
	}, 12, 0)

	-- Vurgu renklerini sonradan değiştirmek için (Rebirth hazır olunca parlar)
	local function setAccent(top, bottom)
		borderGradient.Color = ColorSequence.new(top, bottom)
	end
	return button, caption, setAccent
end

local function makeGridButton(index, icon, label, accent, imageId)
	local column = (index - 1) % 2
	local row = (index - 1) // 2
	return makeSquareButton(UDim2.fromOffset(14 + PHONE_SHIFT_X + column * GRID_PITCH, 166 + PHONE_SHIFT_Y + row * 82), icon, label, accent, imageId)
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
-- GÜNLÜK GİRİŞ ÖDÜLÜ düğmesi (2026-10-14: sahibi onayladı; client/LoginPanel): 7. sol buton (sütun 0, 4. satır); ikon yüklenmediyse emoji. Bugünün ödülü hazırken köşesinde kırmızı '!' rozeti
local dailyButton = makeGridButton(7, "📅", "Daily", { Color3.fromRGB(255, 190, 60), Color3.fromRGB(235, 110, 30) }, icons.Daily)

-- SEZONLUK ETKİNLİK düğmesi (Spooky Gym; client/SpookyPanel): 8. sol buton, SADECE etkinlik açıkken görünür; altındaki yazı Candy sayısını gösterir
local spookyButton, spookyCaption = makeGridButton(8, Config.Event and Config.Event.Emoji or "🎃", "Spooky", { Color3.fromRGB(255, 140, 40), Color3.fromRGB(110, 50, 170) }, nil)
spookyButton.Name = "SpookyButton"
spookyButton.Visible = false
do
	local Workspace = game:GetService("Workspace")
	local function refreshSpooky()
		local active = Config.Event ~= nil and Workspace:GetAttribute("SeasonActive") == true and player:GetAttribute("DataLoaded") == true
		spookyButton.Visible = active
		spookyCaption.Text = `{Config.Event and Config.Event.CurrencyEmoji or ""} {Format.compact(player:GetAttribute("Candy") or 0)}`
	end
	Workspace:GetAttributeChangedSignal("SeasonActive"):Connect(refreshSpooky)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(refreshSpooky)
	player:GetAttributeChangedSignal("Candy"):Connect(refreshSpooky)
	refreshSpooky()
end

-- MASTERY düğmesi (client/MasteryPanel): 9. sol buton, İLK REBIRTH'ten sonra görünür (Config.Mastery.UnlockRebirths)
local masteryButton = makeGridButton(9, "🎓", "Mastery", { Color3.fromRGB(255, 200, 61), Color3.fromRGB(217, 150, 26) }, nil)
masteryButton.Name = "MasteryButton"
masteryButton.Visible = false
do
	local function refreshMastery()
		local leaderstats = player:FindFirstChild("leaderstats")
		local rebirths = leaderstats and leaderstats:FindFirstChild(Config.StatRebirths)
		masteryButton.Visible = Config.Mastery ~= nil and player:GetAttribute("DataLoaded") == true and rebirths ~= nil and rebirths.Value >= Config.Mastery.UnlockRebirths
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(refreshMastery)
	task.defer(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		local rebirths = leaderstats and leaderstats:FindFirstChild(Config.StatRebirths)
		if rebirths then
			rebirths:GetPropertyChangedSignal("Value"):Connect(refreshMastery)
		end
		refreshMastery()
	end)
	refreshMastery()
end

-- Rebirth hazır olunca buton nabız gibi büyüyüp küçülür (dikkat çeker)
local rebirthPulse = create("UIScale", { Scale = 1 }, rebirthButton)
local rebirthPulseTween = UIStyle.loopTween(TweenService:Create(rebirthPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 }), rebirthPulse, { Scale = 1 })

-- Gifts butonundaki alınabilir ödül sayısı rozeti
local giftsBadge = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = C.danger.base,
	Visible = false,
	ZIndex = 8,
}, giftsButton)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, giftsBadge)
create("UIStroke", { Thickness = 1.5, Color = C.bg, Transparency = 0.1 }, giftsBadge)
local giftsBadgeText = makeText(giftsBadge, {
	Position = UDim2.fromScale(0.1, 0.1),
	Size = UDim2.fromScale(0.8, 0.8),
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 9,
}, 16, 1)

local loginBadge = create("Frame", {
	Name = "LoginBadge",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = C.danger.base,
	Visible = false,
	ZIndex = 8,
}, dailyButton)
create("UICorner", { CornerRadius = UDim.new(1, 0) }, loginBadge)
create("UIStroke", { Thickness = 1.5, Color = C.bg, Transparency = 0.1 }, loginBadge)
makeText(loginBadge, {
	Position = UDim2.fromScale(0.1, 0.1),
	Size = UDim2.fromScale(0.8, 0.8),
	Text = "!",
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 9,
}, 16, 1)
local function refreshLoginBadge()
	loginBadge.Visible = player:GetAttribute("DataLoaded") == true and player:GetAttribute("LoginReady") == true
end
player:GetAttributeChangedSignal("LoginReady"):Connect(refreshLoginBadge)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refreshLoginBadge)
refreshLoginBadge()

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
	TextColor3 = C.hot.base,
	Visible = false,
}, 20, 2.5)

-- Üst bilgi iki satırdır (eskiden tek satırda üst üste biniyordu): 1. satır büyük 'Leg Muscle' sayısı, 2. satır solda çarpan, sağda tıklama başı kazanç
local multiplierLabel = makeText(bottom, {
	Position = UDim2.fromOffset(2, 42),
	Size = UDim2.new(0.48, 0, 0, 24),
	TextColor3 = C.success.base,
	TextXAlignment = Enum.TextXAlignment.Left,
}, 20, 2)

-- Bacak kası yazısı (referanstaki '3.6M Punch' gibi sade): eskiden 36 punto ve 40 yüksekliğindi, ekranı çok kaplıyordu (sahibi 'referansa göre bunaltıcı' dedi)
local muscleLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(0.5, 0.5), -- her kas artışında hafifçe 'pop' yapar: ortadan büyüyüp küçülsün
	Position = UDim2.new(0.5, 0, 0, 17),
	Size = UDim2.new(0.7, 0, 0, 34),
	TextColor3 = Color3.new(1, 1, 1),
}, 28, 2.5)
local pop = create("UIScale", {}, muscleLabel)

local gainLabel = makeText(bottom, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -2, 0, 42),
	Size = UDim2.new(0.5, 0, 0, 24),
	TextColor3 = C.warn.base,
	TextXAlignment = Enum.TextXAlignment.Right,
}, 20, 2)

local bar = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), -- merkezden büyüyüp küçülsün (level atlayınca nabız, aşağıda)
	Position = UDim2.new(0.5, 0, 0, 72 + 27),
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = C.cardDeep, -- çukur zemin
}, bottom)
UIStyle.soften(bar, { radius = 14, style = "flat", shine = false })

local barFill = create("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.new(1, 1, 1), -- renk gradyandan gelir (tek vurgu: pembe-turuncu)
	BorderSizePixel = 0,
	ZIndex = 1,
}, bar)
UIStyle.soften(barFill, { radius = 14, gradient = false, shine = false })
create("UIGradient", { Rotation = 0, Color = ColorSequence.new(C.hot.base, C.warn.base) }, barFill)

-- LEVEL ATLAYINCA çubuk hafifçe büyüyüp küçülür (sahibi 'level up yazısı yerine alttaki bar hafif büyüyüp küçülsün' dedi; ekranın ortasına yazı çıkmaz). Juice level atlamayı görünce çağırır.
local barScale = create("UIScale", { Scale = 1 }, bar)
local barPulseToken = 0
local function pulseLevelBar()
	barPulseToken += 1
	local token = barPulseToken
	local grow = TweenService:Create(barScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.07 })
	grow:Play()
	grow.Completed:Connect(function()
		if token == barPulseToken then -- arka arkaya level atlanırsa eski nabız yenisini bozmasın
			TweenService:Create(barScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end)
end

local stageLabel = makeText(bar, {
	Position = UDim2.fromOffset(14, 3),
	Size = UDim2.new(0.5, 0, 1, -6),
	TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
}, 17, 1.5)
local countLabel = makeText(bar, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 3),
	Size = UDim2.new(0.4, 0, 1, -6),
	TextColor3 = C.text,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 5,
}, 17, 1.5)

-- Auto Click: açıkken hareketler kendiliğinden tekrarlanır (ileride VIP'ye özel yapılabilir).
-- Referanstaki gibi: GÖKKUŞAĞI renkli, kayan zemin (açıkken daha hızlı ve parlak) ve üst kenarda "OFF" / "ON" rozeti.
-- ALT SATIR (referanstaki gibi): [+1K Power] [+10K Power] [+100K Power] [Auto Click] [+]. Satır ekranda ortalanır; Auto Click sağa kayar.
-- Üç 'Power' düğmesi Robux ile anında bacak kası satın alır (Config.Shop.Products[].quick), '+' Shop'u açar. Tıklamaları aşağıda (showToast tanımlandıktan sonra) bağlanır.
local QUICK_WIDTH, QUICK_GAP, AUTO_WIDTH, PLUS_WIDTH, ROW_Y = 104, 8, 200, 36, 138
local quickProducts = {}
for _, product in Config.Shop.Products do
	if product.quick then
		table.insert(quickProducts, product)
	end
end
local rowWidth = #quickProducts * (QUICK_WIDTH + QUICK_GAP) + AUTO_WIDTH + QUICK_GAP + PLUS_WIDTH
local rowLeft = -rowWidth / 2
local autoLeft = rowLeft + #quickProducts * (QUICK_WIDTH + QUICK_GAP)

local autoButton = create("TextButton", {
	Name = "AutoClickButton", -- rehber turu (GuideTour) işaretler
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0.5, autoLeft, 0, ROW_Y),
	Size = UDim2.fromOffset(AUTO_WIDTH, 40),
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(1, 1, 1), -- renk gökkuşağı gradyanından gelir
}, bottom)
create("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, autoButton)
UIStyle.soften(autoButton, { radius = Theme.radius.button + 2, gradient = false, shine = false }) -- sadece köşe ve üst parlak şerit; gradyanı gökkuşağı verir
local autoRainbow = create("UIGradient", {}, autoButton)
local autoLabel = makeText(autoButton, {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 1, -12),
	Text = "Auto Click",
	TextColor3 = Color3.new(1, 1, 1),
}, 24, 1.5)
autoLabel.ZIndex = 5 -- yazı ortadaki tıklama simgesinin ÜSTÜNDE kalır
if Config.Icons.Click and Config.Icons.Click ~= "" then
	addOutlinedIcon(autoButton, Config.Icons.Click, 36, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
end
local autoBadge = makeText(autoButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 1),
	Size = UDim2.fromOffset(64, 26),
	Text = "OFF",
	TextColor3 = C.danger.base,
	ZIndex = 5,
}, 20, 1.5)
-- Auto Click game pass'i satılıyorsa (Config.AutoClick.GamePassId > 0) ve oyuncuda yoksa: 'ONLY R$ 99' rozeti OFF/ON rozetinin yerinde durur, düğmeye basınca satın alma penceresi açılır
local ROBUX_SIGN = utf8.char(0xE002)
local autoPrice = makeText(autoButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0, 1),
	Size = UDim2.fromOffset(120, 28),
	Text = `ONLY {ROBUX_SIGN} {Config.AutoClick.Robux}`,
	TextColor3 = C.warn.base,
	Visible = false,
	ZIndex = 6,
}, 20, 1.5)
-- (Ücretsiz deneme KAPALI: Config.AutoClick.TrialSeconds = 0; düğmede zamanlayıcı YAZMAZ, sahibi istemedi. Kalan iksir süresi sol alttaki iksir şişesinde görünür.)
-- AUTO CLICK POTION (Config.Potions, 2026-10-13): iksir süresince de Auto Click pass'siz açıktır ('AutoBoostUntil'); ücretsiz süre = deneme ya da iksir, hangisi daha uzunsa
local function trialSecondsLeft()
	local best = 0
	for _, name in { "AutoClickTrialUntil", "AutoBoostUntil" } do
		local untilTime = player:GetAttribute(name)
		if type(untilTime) == "number" then
			best = math.max(best, untilTime - workspace:GetServerTimeNow())
		end
	end
	return math.max(0, best)
end
local function trialActive()
	return player:GetAttribute("HasAutoClick") ~= true and trialSecondsLeft() > 0
end
-- Auto Click kilitli mi: pass satılıyor, sunucu 'sahip değil' (ya da henüz bilmiyor) diyor ve ücretsiz deneme sürmüyor
local function autoLocked()
	return (Config.AutoClick.GamePassId or 0) > 0 and player:GetAttribute("HasAutoClick") ~= true and trialSecondsLeft() <= 0
end

-- Hızlı satın alma düğmeleri: kırmızı-pembe, kalın siyah çerçeveli, sağ altında bacak simgesi; sağdaki yeşil '+' Shop'u açar
local quickButtons = {}
for index, product in quickProducts do
	local button = create("TextButton", {
		Name = "Quick_" .. product.id,
		Position = UDim2.new(0.5, rowLeft + (index - 1) * (QUICK_WIDTH + QUICK_GAP), 0, ROW_Y),
		Size = UDim2.fromOffset(QUICK_WIDTH, 40),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = product.color,
	}, bottom)
	create("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
	UIStyle.soften(button, { radius = Theme.radius.button, strength = 0.2, shine = false })
	if Config.Icons.LegMuscle and Config.Icons.LegMuscle ~= "" then
		-- Bacak simgesi düğmenin ORTASINDA ve yazının ARKASINDA (referanstaki eldiven gibi); yazı ZIndex 5, simge 2-3 (desenin üstünde)
		local legIcon = addOutlinedIcon(button, Config.Icons.LegMuscle, 44, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		legIcon.ZIndex = 3
	end
	-- İki satır: büyük sayı + küçük 'POWER' (playtest: '100k Power yazısı soluk': uzun tek satır küçülüp silikleşiyordu, üç düğmede de aynı boyda ve net olsun)
	makeText(button, {
		Position = UDim2.fromOffset(4, 2),
		Size = UDim2.new(1, -8, 0, 24),
		Text = `+{Format.compact(product.amount)}`,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
	}, 24, 1.5)
	makeText(button, {
		Position = UDim2.fromOffset(4, 25),
		Size = UDim2.new(1, -8, 0, 13),
		Text = "POWER",
		TextColor3 = C.text,
		ZIndex = 5,
	}, 12, 1)
	table.insert(quickButtons, { button = button, product = product })
end
local plusButton = create("TextButton", {
	Name = "PlusButton",
	Position = UDim2.new(0.5, autoLeft + AUTO_WIDTH + QUICK_GAP, 0, ROW_Y),
	Size = UDim2.fromOffset(PLUS_WIDTH, 40),
	Text = "",
	AutoButtonColor = true,
	BackgroundColor3 = C.success.base,
}, bottom)
create("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, plusButton)
UIStyle.soften(plusButton, { radius = Theme.radius.button, strength = 0.2, shine = false })
makeText(plusButton, {
	Position = UDim2.fromOffset(2, 2),
	Size = UDim2.new(1, -4, 1, -6),
	Text = "+",
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 5,
}, 30, 1.5)

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
	winLabel.Text = Format.compact(winValue.Value) -- 2.8M gibi (1000 altı olduğu gibi); sahibi sayaçların da kısalmasını istedi
	rebirthLabel.Text = Format.compact(rebirthValue.Value)
	-- Antrenman alanındayken kazanç pedin çarpanıyla çarpılır (sunucu AreaMultiplier'ı pede girince ayarlar)
	local areaMultiplier = player:GetAttribute("AreaMultiplier") or 1
	local perClick = math.floor((player:GetAttribute("PerClick") or 1) * areaMultiplier)
	gainLabel.Text = `+{Format.compact(perClick)}/click  x{Format.multiplier(player:GetAttribute("DamageMultiplier") or 1)} dmg`
	multiplierLabel.Text = `x{Format.multiplier((player:GetAttribute("TotalMultiplier") or 1) * areaMultiplier)} Multiplier`
	local locked = autoLocked()
	autoClick = autoClick and not locked
	autoBadge.Visible = not locked
	autoPrice.Visible = locked
	autoBadge.Text = if autoClick then "ON" else "OFF"
	autoBadge.TextColor3 = if autoClick then C.success.base else C.danger.base
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

-- EĞİTİM + GÖREV ZİNCİRİ (2026-10-13, sahibi 'iki görev çakışıyor, görevleri birbirine entegre et' dedi): üstteki şerit, yol gösterici çizgi (Guide) ve rehber kartları (GuideTour)
-- AYNI güncel hedefi okur (client/Objective: NEW PLAYER görevlerinin sırasıyla ilk bitmemişi: 30 squat > ilk pet > ilk skin > 3 duvar > ayakkabı > level 10 > Playtime ödülü > antrenman > çark > rebirth).
-- Şerit ilk rebirth'e kadar sürer (Config.Tutorial.RebirthGoal = false ise sadece ilk skine kadar). Deneyimli oyuncuda şerit gizlidir (sadece antrenman alanında 'Training with...' görünür).
local Objective = require(script.Objective)

-- Settings'teki 'Guide' anahtarı: kapalıysa (GuideOn = false) üstteki yönerge/hedef şeridi, yol gösterici çizgi ve tanıtım kartları görünmez
local function guideOn()
	return player:GetAttribute("GuideOn") ~= false
end

local function tutorialActive()
	return player:GetAttribute("DataLoaded") == true and player:GetAttribute("TutorialDone") == false
end

local function currentObjective()
	if not guideOn() or player:GetAttribute("DataLoaded") ~= true then
		return nil
	end
	-- (İlk rebirth'ten sonra SADECE 'ilk rebirth görevinin ödülünü Quests'ten al' hedefi kalır: Objective.read başka hedef döndürmez)
	if rebirthValue.Value == 0 and player:GetAttribute("TutorialDone") == true and Config.Tutorial.RebirthGoal ~= true then
		return nil
	end
	return Objective.read(player, {
		wins = winValue.Value,
		level = levelValue.Value,
		maxLevel = player:GetAttribute("MaxLevel"),
		rebirths = rebirthValue.Value,
		wallText = progressText,
	})
end

local function refreshBanner()
	local areaId = player:GetAttribute("TrainingArea") or ""
	local area = nil
	for _, candidate in Config.Training.Areas do
		if candidate.id == areaId then
			area = candidate
		end
	end
	local fraction = nil -- çubuk gösterilecekse doluluğu (squat sayacı, level, görev ilerlemesi)
	if area then
		banner.Visible = true
		bannerText.Text = `Training with {area.trainer}: x{string.format("%g", area.mult)} Squat!`
	else
		local objective = currentObjective()
		if objective then
			banner.Visible = true
			bannerText.Text = objective.text
			fraction = objective.fraction
		else
			banner.Visible = false
		end
	end
	bannerBar.Visible = fraction ~= nil
	bannerFill.Size = UDim2.fromScale(fraction or 0, 1)
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
player:GetAttributeChangedSignal("GuideOn"):Connect(refreshBanner)
player:GetAttributeChangedSignal("TutorialDone"):Connect(refreshBanner)
player:GetAttributeChangedSignal("TutorialClicks"):Connect(refreshBanner)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refreshBanner)
player:GetAttributeChangedSignal("OwnedPets"):Connect(refreshBanner)
player:GetAttributeChangedSignal("OwnedSkins"):Connect(refreshBanner)
player:GetAttributeChangedSignal("StarterState"):Connect(refreshBanner)
player:GetAttributeChangedSignal("MaxLevel"):Connect(refreshBanner)
levelValue:GetPropertyChangedSignal("Value"):Connect(refreshBanner)
rebirthValue:GetPropertyChangedSignal("Value"):Connect(refreshBanner)
winValue:GetPropertyChangedSignal("Value"):Connect(refreshBanner)
refreshBanner()

ShoeShop.init()
SkinShop.init()
TrainingClient.init()
safeInit("Performance", loadOptional("Performance")) -- ışık/parçacık/tabela uzaklık kısması + hafif grafik modu (telefon); klasörler artık hazır
local JuiceModule = loadOptional("Juice")
safeInit("Juice", JuiceModule, screenGui)
if JuiceModule and JuiceModule.setLevelPulse then
	JuiceModule.setLevelPulse(pulseLevelBar) -- level atlayınca alttaki çubuk nabız atar (yazı yok)
end
safeInit("OverheadTags", loadOptional("OverheadTags"))
safeInit("FeedHud", loadOptional("FeedHud"), screenGui) -- çapraz sunucu duyuru akışı (nadir pet, rebirth); sağda küçük şeritler
safeInit("BoostHud", loadOptional("BoostHud"), screenGui)
local eggHooks = {} -- showToast ve openShop aşağıda (bildirim ve Shop kurulunca) doldurulur: yumurta panelindeki 'Get Wins' yönlendirmesi ve ücretli düğmelerin 'coming soon' mesajı
EggShop.init(screenGui, eggHooks)
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
-- FARE: tıklama anında sayılır. DOKUNMATİK (telefon): parmak ekrana değince DEĞİL, parmak kalkınca ve sadece KISA, HAREKETSİZ dokunuş (tap) sayılır; kaydırma (kamera döndürme, joystick)
-- tıklama sayılmaz (sahibi telefondan 'ekranı çeviremiyorum, her dokunuşta leg power veriyor, kaydırmamı algılamıyor' dedi). Süzgeç client/TapFilter; yüklenemezse eski davranış (dokunuşta anında).
local function registerClick()
	playMove()
	clickEvent:FireServer()
end
local TapFilterModule = loadOptional("TapFilter")
local tapFilter = if TapFilterModule then TapFilterModule.new(0.6, 14) else nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 then
		registerClick()
	elseif inputType == Enum.UserInputType.Touch then
		if tapFilter then
			tapFilter:began(input, input.Position.X, input.Position.Y, os.clock())
		else
			registerClick()
		end
	end
end)
if tapFilter then
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			tapFilter:moved(input, input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and tapFilter:ended(input, os.clock()) then
			registerClick()
		end
	end)
end

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
	if autoLocked() then
		-- pass'e sahip değil: satın alma penceresi (alınca sunucu HasAutoClick'i true yapar, aşağıdaki dinleyici Auto Click'i açar)
		pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, Config.AutoClick.GamePassId)
		return
	end
	autoClick = not autoClick
	refresh()
end)
-- Satın alınınca (sunucu HasAutoClick'i false iken true yapınca) Auto Click kendiliğinden açılır; girişteki ilk (nil -> true) değer açmaz
local previousAuto = player:GetAttribute("HasAutoClick")
player:GetAttributeChangedSignal("AutoBoostUntil"):Connect(refresh) -- iksir içilince düğme hemen açılır ('FREE m:ss')
player:GetAttributeChangedSignal("HasAutoClick"):Connect(function()
	local value = player:GetAttribute("HasAutoClick")
	if value == true and previousAuto == false and (Config.AutoClick.GamePassId or 0) > 0 then
		autoClick = true
	end
	previousAuto = value
	refresh()
end)

-- Auto Click gökkuşağı: renk tonu zamanla kayar (kapalıyken yavaş ve biraz sönük, açıkken hızlı ve parlak)
local rainbowShift = 0
local rainbowClock = 0
RunService.Heartbeat:Connect(function(dt)
	rainbowShift = (rainbowShift + dt * (if autoClick then 0.3 else 0.05)) % 1
	-- Renk dizisi her karede yeniden kurulmasın (bellek/CPU): saniyede ~15 güncelleme göze aynı akıcılıkta görünür
	rainbowClock += dt
	if rainbowClock < 0.066 then
		return
	end
	rainbowClock = 0
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
-- Bildirim (satın alma sonucu, hata): küçük ve ÜSTTE (hedef şeridinin altı). Eskiden ekranın ortasında (0.62) ve 28 punto idi, karakteri ve bacak kası yazısını kapatıyordu
local toast = makeText(screenGui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.fromOffset(520, 32),
	TextColor3 = Color3.new(1, 1, 1),
	Visible = false,
}, 22, 2.5)
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
	toast.TextColor3 = if ok then C.success.base else C.danger.base
	toast.Visible = true
	task.delay(2.5, function()
		if toastId == id then
			toast.Visible = false
		end
	end)
end

notifyEvent.OnClientEvent:Connect(showToast)
safeInit("NotifOptIn", loadOptional("NotifOptIn")) -- ilk rebirth sonrası Roblox bildirim izni (bir kez)
safeInit("PowerHourHud", loadOptional("PowerHourHud"), screenGui, showToast) -- Power Hour sayacı (son 90 sn + aktifken, üstte küçük hap); başlarken tek bildirim

-- Eğitim bitince (ilk skin alınınca) kısa tebrik
do
	local wasActive = false
	local function checkTutorialEnd()
		local active = tutorialActive()
		if wasActive and not active and player:GetAttribute("TutorialDone") == true then
			showToast(true, "Great! Open Quests (📜 top right): NEW PLAYER quests give free rewards. Keep breaking walls!")
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
		countLabel.Text = `{Format.compact(taps, 2)}/{Format.compact(needed, 2)}` -- 421.95M/2.84B (level sayısı hariç büyük sayılar K/M/B ile kısalır)
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
local toggleLogin = loadPanel("LoginPanel", screenGui, showToast) -- günlük giriş ödülü penceresi (sol menüdeki Daily düğmesi)
dailyButton.MouseButton1Click:Connect(function()
	if toggleLogin then
		toggleLogin()
	else
		showToast(false, "Daily rewards are coming soon!")
	end
end)
local toggleMastery = loadPanel("MasteryPanel", screenGui, showToast) -- Mastery ağacı penceresi (sol menüdeki Mastery düğmesi)
masteryButton.MouseButton1Click:Connect(function()
	if toggleMastery then
		toggleMastery()
	else
		showToast(false, "Mastery is not available right now.")
	end
end)
local toggleSpooky = loadPanel("SpookyPanel", screenGui, showToast) -- sezonluk etkinlik penceresi (sol menüdeki Spooky düğmesi)
spookyButton.MouseButton1Click:Connect(function()
	if toggleSpooky then
		toggleSpooky()
	else
		showToast(false, "The event is not available right now.")
	end
end)
-- Etkinlik açıkken oturumda BİR KEZ kısa duyuru (eğitimi bitmiş oyuncuya; ekranı kapatmaz)
do
	local Workspace = game:GetService("Workspace")
	local announced = false
	local function announceEvent()
		if announced or not Config.Event or Workspace:GetAttribute("SeasonActive") ~= true or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") ~= true then
			return
		end
		announced = true
		task.delay(9, function()
			showToast(true, `{Config.Event.Emoji} {Config.Event.Name} is ON! Break walls to collect {Config.Event.CurrencyName}.`)
		end)
	end
	Workspace:GetAttributeChangedSignal("SeasonActive"):Connect(announceEvent)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(announceEvent)
	player:GetAttributeChangedSignal("TutorialDone"):Connect(announceEvent)
	announceEvent()
end
-- Bugünün giriş ödülü hazırsa (eğitim bitmiş oyuncuya) oturumda BİR KEZ küçük bir hatırlatma; ekranı kapatmaz
do
	local reminded = false
	local function remindLogin()
		if reminded or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") ~= true or player:GetAttribute("LoginReady") ~= true then
			return
		end
		reminded = true
		task.delay(6, function()
			showToast(true, "Daily reward ready! Tap Daily (left menu).")
		end)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(remindLogin)
	player:GetAttributeChangedSignal("TutorialDone"):Connect(remindLogin)
	player:GetAttributeChangedSignal("LoginReady"):Connect(remindLogin)
	remindLogin()
end
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
	image = Config.Icons.Trails,
	headerTop = Color3.fromRGB(255, 215, 50),
	headerBottom = Color3.fromRGB(255, 110, 30),
	panelColor = Color3.fromRGB(75, 32, 22),
	items = Config.Trails,
	ownedOnlyItems = { Config.Event and Config.Event.Trail or nil }, -- sezonluk etkinlik izi: yalnızca sahibine görünür
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
	image = Config.Icons.Auras,
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
	local okShop, result = pcall(ShopPanelModule.init, screenGui, showToast, shopButton)
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
-- Yumurta paneli: Win yetmeyince Shop'u Win paketleri bölümünde aç, ücretli düğmeler bildirim göstersin
eggHooks.showToast = showToast
safeInit("GuideTour", loadOptional("GuideTour"), screenGui, showToast) -- yeni oyuncu rehber turu: ilk rebirth'e kadar arayüzü tanıtan kartlar (Config.GuideTour)

-- Sunucunun gönderdiği ödül bildirimleri (başlangıç hediyesi, level kilometre taşı ödülleri): 'RewardToast' = '<sayaç>|<mesaj>'
player:GetAttributeChangedSignal("RewardToast"):Connect(function()
	local value = player:GetAttribute("RewardToast")
	local message = if type(value) == "string" then string.match(value, "^%d+|(.*)$") else nil
	if message and message ~= "" then
		showToast(true, message)
	end
end)

-- Ücretsiz Auto Click denemesi: geri sayım her saniye yenilenir; bitince düğme normal (fiyat) hâline döner ve oyuncuya bir kez haber verilir
task.spawn(function()
	local wasTrial = false
	while true do
		local trialOn = trialActive()
		if trialOn or wasTrial then
			refresh()
		end
		if wasTrial and not trialOn and player:GetAttribute("HasAutoClick") ~= true and (Config.AutoClick.GamePassId or 0) > 0 then
			showToast(true, `Free Auto Click ended! Get it for R$ {Config.AutoClick.Robux} to keep it forever.`)
		end
		wasTrial = trialOn
		task.wait(1)
	end
end)
eggHooks.openShop = function(section)
	if toggleShop then
		toggleShop(section)
	end
end

-- Alt satırdaki hızlı satın alma düğmeleri: ürün ID'si varsa Roblox satın alma penceresi, yoksa 'coming soon' (Robux aşamasında ID'ler girilir); '+' Shop'u açar
for _, entry in quickButtons do
	entry.button.MouseButton1Click:Connect(function()
		if entry.product.productId > 0 then
			MarketplaceService:PromptProductPurchase(player, entry.product.productId)
		else
			showToast(false, `{entry.product.name} is coming soon!`)
		end
	end)
end
plusButton.MouseButton1Click:Connect(function()
	if toggleShop then
		toggleShop()
	else
		showToast(false, "Shop is coming soon!")
	end
end)

-- Settings: ses efektleri, müzik, kazanç yazıları, ekran sarsıntısı ve isim etiketleri ayarları (korumalı yüklenir)
local showWhatsNew = loadPanel("WhatsNewCard", screenGui) -- 'Neler yeni' kartı (girişte bir kez, Settings'ten her zaman)
local SettingsPanelModule = loadOptional("SettingsPanel")
local toggleSettings = nil
if SettingsPanelModule then
	local okSettings, result = pcall(SettingsPanelModule.init, screenGui, showWhatsNew)
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

-- Arayüz kuruldu: yükleme ekranı (ReplicatedFirst/Loading) bu işareti bekleyip kapanır
player:SetAttribute("ClientReady", true)
