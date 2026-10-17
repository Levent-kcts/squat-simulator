-- BAŞLANGIÇ PAKETİ TEKLİF KARTI (2026-10-17, sahibi referans oyunun sağ üstündeki 'Starter Pack' kartını gösterip 'bunun gibi bir UI ekle, kapatılabilsin' dedi):
-- sağdaki FREE REWARD kutusunun ALTINDA küçük kart: gökkuşağı 'Starter Pack' başlığı, lego desenli sarı kutu içinde paketin görseli (Config.Icons.StarterPack),
-- altında 'ONLY R$ 49'. Karta basınca Roblox satın alma penceresi açılır (Shop'taki kartla aynı Developer Product). Köşedeki X bu oturum için gizler
-- (bir sonraki girişte yeniden çıkar; baskı/sayaç dili YOK). Görünür olduğu durumlar: ürün satışta (productId > 0), oyuncu almamış ('StarterPackOwned'),
-- eğitimi bitmiş ('TutorialDone': yeni oyuncunun ilk dakikalarında ekran sade kalsın) ve hesap ücretli rastgele ürün kısıtlı DEĞİL (pakette Luck iksiri var;
-- Shop da kısıtlı hesapta Luck/Rainbow satmaz). Sadece görsel/kısayol: satın almayı ve ödülü sunucu işler (Purchases).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local StarterOffer = {}

local ROBUX = utf8.char(0xE002) -- Roblox'un Robux simgesi (yazı tipinde özel karakter)
local FONT = Enum.Font.FredokaOne
local WIDTH, HEIGHT = 150, 116

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function outlined(parent, props, thickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = thickness or 2.5, Color = Color3.new(0, 0, 0) }, label)
	return label
end

local function findProduct()
	for _, product in Config.Shop.Products do
		if product.kind == "starterPack" then
			return product
		end
	end
	return nil
end

function StarterOffer.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local product = findProduct()
	if not product then
		return
	end

	-- Sağdaki RightHud sütununa (FREE REWARD'ın altına) yerleşir; sütun yoksa aynı yere kendisi konur
	local column = screenGui:FindFirstChild("RightHud")
	local holder = create("Frame", {
		Name = "StarterOffer",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundTransparency = 1,
		Visible = false,
	}, column or screenGui)
	if not column then
		holder.AnchorPoint = Vector2.new(1, 0)
		holder.Position = UDim2.new(1, -14, 0.4, 40)
	end

	-- Gökkuşağı başlık
	local title = outlined(holder, {
		Size = UDim2.new(1, 0, 0, 24),
		Text = "Starter Pack",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2.5)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(120, 255, 140)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 230, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 200)),
		}),
	}, title)

	-- Görselli kart (basınca satın alma penceresi)
	local card = create("TextButton", {
		Name = "OfferCard",
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 62),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(255, 205, 50),
	}, holder)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, card)
	UIStyle.soften(card, { radius = 12, strength = 0.25 })
	pcall(UIStyle.brickSkin, card, 6, 2, 12, { light = 0.92 })
	local imageId = Config.Icons and Config.Icons.StarterPack
	if type(imageId) == "string" and imageId ~= "" then
		create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(58, 58),
			BackgroundTransparency = 1,
			Image = imageId,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		}, card)
	else
		outlined(card, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(50, 50), Text = "🎁", ZIndex = 3 }, 0)
	end
	local cardScale = create("UIScale", { Scale = 1 }, card)

	-- Fiyat
	outlined(holder, {
		Position = UDim2.fromOffset(0, 91),
		Size = UDim2.new(1, 0, 0, 24),
		Text = `ONLY {ROBUX} {product.robux}`,
		TextColor3 = Color3.new(1, 1, 1),
	}, 2.5)

	-- Kapatma (bu oturum için)
	local close = create("TextButton", {
		Name = "CloseOffer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -2, 0, 28),
		Size = UDim2.fromOffset(24, 24),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(235, 50, 60),
		ZIndex = 4,
	}, holder)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, close)
	create("UIStroke", { Thickness = 2.5, Color = Color3.new(0, 0, 0) }, close)
	outlined(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1), ZIndex = 5 }, 1.5)

	local dismissed = false

	local function refresh()
		holder.Visible = not dismissed
			and product.productId > 0
			and player:GetAttribute("DataLoaded") == true
			and player:GetAttribute("StarterPackOwned") ~= true
			and player:GetAttribute("TutorialDone") == true
			and player:GetAttribute("PaidRandomRestricted") == false
	end

	card.MouseButton1Click:Connect(function()
		if product.productId > 0 then
			cardScale.Scale = 0.94
			TweenService:Create(cardScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			MarketplaceService:PromptProductPurchase(player, product.productId)
		elseif showToast then
			showToast(false, `{product.name} is coming soon!`)
		end
	end)
	close.MouseButton1Click:Connect(function()
		dismissed = true
		refresh()
	end)

	for _, attribute in { "DataLoaded", "StarterPackOwned", "TutorialDone", "PaidRandomRestricted" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
end

return StarterOffer
