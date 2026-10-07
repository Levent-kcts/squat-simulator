-- Günlük çark arayüzü (referans oyundaki gibi): lobideki çarka E ile yaklaşınca açılır; arka plan karartılır, ortada büyük yuvarlak çark (8 renkli dilim, simge + ad + yüzde),
-- üstte sabit ibre, sağ üstte kırmızı X, altta yeşil 'Spin! (1)' düğmesi ve sonuç/durum yazısı. Çarkın yüzü shared/WheelFace ile çizilir (lobideki 3B çarkla aynı).
-- Bu modül SADECE arayüzdür: dönüş animasyonunu ve sunucu isteğini client/WheelController yapar (panel.place ile açıyı verir, Spin düğmesi onSpin'i çağırır).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WheelFace = require(Shared:WaitForChild("WheelFace"))
local UIStyle = require(script.Parent.UIStyle)

local WheelPanel = {}

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GREEN = Color3.fromRGB(80, 215, 40)
local GREY = Color3.fromRGB(100, 106, 126)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = BLACK }, label)
	return label
end

-- screenGui: arayüz kökü (init.client'taki screenGui; sadece yedek). onSpin: Spin düğmesine basılınca çağrılır.
-- Karartma TÜM ekranı (Roblox'un üst çubuğu payı dahil, sağ üst daireler de) örtsün diye panel kendi ScreenGui'sinde kurulur (IgnoreGuiInset = true; ana arayüzde y = 0 ekranın ~58 piksel altıdır).
-- Dönüş: { open, close, isOpen, place(açı), setStatus(hazır, yazı, meşgul), showResult(yazı, renk) }
function WheelPanel.init(screenGui, onSpin)
	local isOpen = false

	local host = screenGui
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui", 5)
	if playerGui then
		host = create("ScreenGui", {
			Name = "WheelGui",
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			DisplayOrder = 20,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, playerGui)
	end

	-- Karartılmış arka plan: bütün ekranı kaplar, boşluğa tıklayınca kapanır, altındaki dünyaya/oyuna tıklama geçmez
	local backdrop = create("TextButton", {
		Name = "WheelPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.4,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Visible = false,
		ZIndex = 40,
	}, host)

	makeText(backdrop, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.07),
		Size = UDim2.fromScale(0.5, 0.09),
		Text = "DAILY WHEEL",
		TextColor3 = Color3.fromRGB(255, 225, 90),
		ZIndex = 41,
	}, 3.5)

	-- Çark: ekran yüksekliğinin %58'i kadar kare
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.58, 0.58),
		BackgroundTransparency = 1,
		Active = true, -- çarka tıklamak paneli kapatmasın
		ZIndex = 41,
	}, backdrop)
	create("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, holder)
	local face = WheelFace.build(holder, Config.Wheel.Prizes, { rim = true, hub = true, upright = true, image = Config.Icons.WheelFace })

	-- İbre: çarkın üstünde sabit, aşağı bakan beyaz üçgen
	makeText(holder, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.0),
		Size = UDim2.fromScale(0.16, 0.16),
		Text = "▼",
		TextColor3 = WHITE,
		ZIndex = 44,
	}, 3)

	-- Kapat (X): çarkın sağ üst köşesinde
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1.02, 0.0),
		Size = UDim2.fromScale(0.13, 0.13),
		Text = "X",
		Font = FONT,
		TextScaled = true,
		TextColor3 = WHITE,
		BackgroundColor3 = Color3.fromRGB(235, 40, 60),
		ZIndex = 45,
	}, holder)
	create("UIStroke", { Thickness = 3, Color = BLACK }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	-- Alt: sonuç/durum yazısı ve Spin düğmesi
	local statusLabel = makeText(backdrop, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.805),
		Size = UDim2.fromScale(0.6, 0.05),
		Text = "",
		TextColor3 = Color3.fromRGB(215, 225, 245),
		ZIndex = 41,
	}, 2.5)
	local spin = create("TextButton", {
		Name = "SpinButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.89),
		Size = UDim2.fromScale(0.3, 0.09),
		Text = "",
		BackgroundColor3 = GREEN,
		ZIndex = 41,
	}, backdrop)
	create("UIStroke", { Thickness = 4, Color = BLACK }, spin)
	UIStyle.soften(spin, { radius = 14, strength = 0.3 })
	local spinText = makeText(spin, {
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		Text = "Spin! (1)",
		TextColor3 = WHITE,
		ZIndex = 42,
	}, 3)

	local panel = {}

	function panel.isOpen()
		return isOpen
	end
	function panel.open()
		isOpen = true
		backdrop.Visible = true
	end
	function panel.close()
		isOpen = false
		backdrop.Visible = false
	end
	-- Çarkı açıya (derece, saat yönü) döndürür
	function panel.place(angle)
		face.place(angle)
	end
	-- hazır: bugünkü hak var mı; yazı: altındaki durum yazısı (boşsa değişmez); meşgul: çark dönüyor ya da sunucudan yanıt bekleniyor
	function panel.setStatus(ready, text, busy)
		spin.BackgroundColor3 = if ready and not busy then GREEN else GREY
		spinText.Text = if busy then "Spinning..." elseif ready then "Spin! (1)" else "Spin! (0)"
		if text then
			statusLabel.Text = text
			statusLabel.TextColor3 = Color3.fromRGB(215, 225, 245)
		end
	end
	function panel.showResult(text, color)
		statusLabel.Text = text
		statusLabel.TextColor3 = color or Color3.fromRGB(255, 235, 110)
	end

	close.MouseButton1Click:Connect(panel.close)
	backdrop.MouseButton1Click:Connect(panel.close)
	spin.MouseButton1Click:Connect(function()
		if onSpin then
			onSpin()
		end
	end)

	return panel
end

return WheelPanel
