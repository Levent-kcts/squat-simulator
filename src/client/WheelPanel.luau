-- Günlük çark arayüzü (referans oyundaki gibi): lobideki çarka E ile yaklaşınca açılır; arka plan karartılır, ortada büyük yuvarlak çark (8 renkli dilim, simge + ad + yüzde),
-- üstte sabit ibre; modal kart UIStyle tasarım sistemiyle (header + ghost X, altta primary SPIN ve kısa sonuç/durum satırı). Çarkın yüzü shared/WheelFace ile çizilir (lobideki 3B çarkla aynı).
-- Bu modül SADECE arayüzdür: dönüş animasyonunu ve sunucu isteğini client/WheelController yapar (panel.place ile açıyı verir, Spin düğmesi onSpin'i çağırır).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WheelFace = require(Shared:WaitForChild("WheelFace"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)

local WheelPanel = {}

local Theme = UIStyle.Theme
local C = Theme.colors

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- screenGui: arayüz kökü (init.client'taki screenGui; sadece yedek). onSpin: Spin düğmesine basılınca çağrılır.
-- Karartma TÜM ekranı (Roblox'un üst çubuğu payı dahil, sağ üst daireler de) örtsün diye panel kendi ScreenGui'sinde kurulur (IgnoreGuiInset = true; ana arayüzde y = 0 ekranın ~58 piksel altıdır).
-- Dönüş: { open, close, isOpen, place(açı), setStatus(hazır, yazı, meşgul), showResult(yazı, renk) }
function WheelPanel.init(screenGui, onSpin)
	local isOpen = false
	local closeToken = 0
	local panel = {}

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
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.35,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Visible = false,
		ZIndex = 40,
	}, host)

	-- Ortadaki modal kart: ince çerçeveli koyu panel (genişlik ekranın %92'si ile 520 arası, yükseklik ekranın %92'si)
	local card = UIStyle.panel(backdrop, {
		name = "WheelCard",
		accent = "warn",
		width = 520,
		size = UDim2.fromScale(0, 0.92),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		shadow = false,
	})
	card.ZIndex = 41
	create("UISizeConstraint", { Name = "HeightLimit", MaxSize = Vector2.new(520, 720) }, card)

	UIStyle.header(card, {
		title = "DAILY WHEEL",
		emoji = "🎡",
		accent = "warn",
		onClose = function()
			panel.close() -- panel tablosu aşağıda doldurulur; tıklanınca çağrılır
		end,
	})

	-- Çark alanı: başlıkla alt bölüm arasındaki boşluk; çark bunun içine sığan en büyük kare
	local area = create("Frame", {
		Name = "WheelArea",
		Position = UDim2.new(0, 16, 0, 78),
		Size = UDim2.new(1, -32, 1, -78 - 124),
		BackgroundTransparency = 1,
		ZIndex = 41,
	}, card)
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.96),
		BackgroundTransparency = 1,
		Active = true, -- çarka tıklamak paneli kapatmasın
		ZIndex = 41,
	}, area)
	create("UIAspectRatioConstraint", { AspectRatio = 1 }, holder)
	-- Çarkın yüzü: Auto Click game pass'i olan oyuncuda 'Auto Click Potion' dilimi 'Rainbow Potion' görünür (sunucu da öyle verir); pass bilgisi sonradan gelince/satın alınınca yüz yeniden çizilir
	local face
	local faceAngle = 0
	local faceForOwner = nil
	local function buildFace()
		local owner = Players.LocalPlayer:GetAttribute("HasAutoClick") == true
		if face and owner == faceForOwner then
			return
		end
		faceForOwner = owner
		local old = holder:FindFirstChild("WheelFace")
		if old then
			old:Destroy()
		end
		face = WheelFace.build(holder, Catalog.wheelPrizes(owner), { rim = true, hub = true, upright = true, image = Config.Icons.WheelFace })
		face.place(faceAngle)
	end
	buildFace()
	Players.LocalPlayer:GetAttributeChangedSignal("HasAutoClick"):Connect(buildFace)

	-- İbre: çarkın üstünde sabit, aşağı bakan altın üçgen (yazı üstünde ince, yarı saydam siyah kontur)
	local pointer = UIStyle.label(holder, {
		name = "Pointer",
		text = "▼",
		role = "title",
		size = 34,
		align = "center",
		color = C.primary.base,
		props = {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.0),
			Size = UDim2.fromScale(0.16, 0.16),
			ZIndex = 44,
		},
	})
	pcall(function()
		pointer.TextScaled = true
		create("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, pointer)
	end)

	-- Alt: kısa sonuç/durum satırı ve Spin düğmesi
	local statusLabel = UIStyle.label(card, {
		name = "WheelStatus",
		text = "",
		role = "bold",
		align = "center",
		color = C.textDim,
		props = { Position = UDim2.new(0, 16, 1, -116), Size = UDim2.new(1, -32, 0, 30), ZIndex = 41 },
	})
	pcall(function()
		statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end)
	local spin = UIStyle.button(card, {
		name = "SpinButton",
		text = "Spin! (1)",
		kind = "primary",
		size = "lg",
		width = 260,
		position = UDim2.new(0.5, -130, 1, -76),
		onClick = function()
			if onSpin then
				onSpin()
			end
		end,
	})

	function panel.isOpen()
		return isOpen
	end
	function panel.open()
		isOpen = true
		closeToken += 1
		backdrop.Visible = true
		UIStyle.fadeScaleIn(card)
	end
	function panel.close()
		if not isOpen then
			return
		end
		isOpen = false
		closeToken += 1
		local token = closeToken
		UIStyle.fadeScaleOut(card, function()
			-- bu arada yeniden açıldıysa karartmayı kapatma
			if token == closeToken then
				backdrop.Visible = false
			end
		end)
	end
	-- Çarkı açıya (derece, saat yönü) döndürür
	function panel.place(angle)
		faceAngle = angle
		face.place(angle)
	end
	-- hazır: bugünkü hak var mı; yazı: altındaki durum yazısı (boşsa değişmez); meşgul: çark dönüyor ya da sunucudan yanıt bekleniyor
	function panel.setStatus(ready, text, busy)
		UIStyle.setButtonKind(spin, if ready and not busy then "primary" else "secondary")
		UIStyle.setButtonText(spin, if busy then "Spinning..." elseif ready then "Spin! (1)" else "Spin! (0)")
		if text then
			statusLabel.Text = text
			statusLabel.TextColor3 = C.textDim
		end
	end
	function panel.showResult(text, color)
		statusLabel.Text = text
		statusLabel.TextColor3 = color or C.primary.base
	end

	backdrop.MouseButton1Click:Connect(panel.close)

	return panel
end

return WheelPanel
