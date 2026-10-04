-- Shop penceresi: Robux ile alınan ürünler (Config.Shop.Products) ve VIP game pass. Kartlardaki buton Roblox'un satın alma penceresini açar;
-- ödülü sunucu ProcessReceipt ile verir (server/Purchases). productId 0 olan ürünlerde kart "SOON" gösterir ve satın alma açılmaz.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ShopPanel = {}

local FONT = Enum.Font.FredokaOne

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function text(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Döner: pencereyi açıp kapatan fonksiyon
function ShopPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(560, 420),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(560, 420), MinSize = Vector2.new(300, 260) }, panel)

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(235, 50, 120),
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
	text(header, {
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -90, 1, -12),
		Text = "🛒 SHOP",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
	}, header)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	text(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1) }, 2)

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 68),
		Size = UDim2.new(1, -24, 1, -80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(160, 168),
		CellPadding = UDim2.fromOffset(10, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	-- Tek kart: renkli kutu, simge, ad, açıklama ve fiyat/satın alma butonu
	local function addCard(order, color, icon, name, detail, priceText, onBuy)
		local card = create("Frame", { LayoutOrder = order, BackgroundColor3 = color }, list)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
		text(card, { Position = UDim2.fromScale(0.1, 0.03), Size = UDim2.fromScale(0.8, 0.3), Text = icon }, 0)
		text(card, { Position = UDim2.fromScale(0.04, 0.34), Size = UDim2.fromScale(0.92, 0.17), Text = name, TextColor3 = Color3.new(1, 1, 1) }, 2)
		text(card, { Position = UDim2.fromScale(0.04, 0.52), Size = UDim2.fromScale(0.92, 0.12), Text = detail, TextColor3 = Color3.fromRGB(255, 245, 200) }, 1.5)
		local buy = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.8, 0.24),
			Text = "",
			BackgroundColor3 = Color3.fromRGB(50, 150, 255),
		}, card)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, buy)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, buy)
		text(buy, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = priceText, TextColor3 = Color3.new(1, 1, 1) }, 2)
		buy.MouseButton1Click:Connect(onBuy)
	end

	local order = 0

	-- VIP game pass (Config.VipGamePassId): kartta fiyat yazmaz, Roblox penceresi fiyatı gösterir
	order += 1
	addCard(order, Color3.fromRGB(255, 80, 200), "👑", "VIP", "2x Wins pad", if Config.VipGamePassId > 0 then "BUY" else "SOON", function()
		if Config.VipGamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.VipGamePassId)
		else
			showToast(false, "VIP is coming soon!")
		end
	end)

	for _, product in Config.Shop.Products do
		order += 1
		addCard(order, product.color, product.icon, product.name, product.detail, if product.productId > 0 then `R$ {product.robux}` else "SOON", function()
			if product.productId > 0 then
				MarketplaceService:PromptProductPurchase(player, product.productId)
			else
				showToast(false, `{product.name} is coming soon!`)
			end
		end)
	end

	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	return function()
		panel.Visible = not panel.Visible
	end
end

return ShopPanel
