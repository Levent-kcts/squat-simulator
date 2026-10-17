-- BAŞLANGIÇ PAKETİ TEKLİF KARTI (2026-10-17, sahibi referans oyunun sağ üstündeki 'Starter Pack' kartını gösterdi): sağdaki FREE REWARD kutusunun ÜSTÜNDE çerçevesiz kart:
-- büyük paket görseli (Config.Icons.StarterPack), sol üstte eğik yeşil fiyat rozeti, altında gökkuşağı 'Starter Pack' yazısı. Görsele basınca Roblox satın alma penceresi açılır
-- (Shop'taki kartla aynı Developer Product). GERİ SAYIM ve KAPATMA DÜĞMESİ YOK (sahibi önce 1 saatlik sayaç + X istedi, sonra 'geri sayım olmasın, kapama tuşu olmasın' dedi).
-- Görünür olduğu durumlar: ürün satışta (productId > 0), veri yüklü, oyuncu almamış ('StarterPackOwned') ve hesap ücretli rastgele ürün kısıtlı DEĞİL
-- (pakette Luck iksiri var; Shop da kısıtlı hesapta Luck/Rainbow satmaz). Eğitim sırasında da görünür. Sadece görsel/kısayol: satın almayı ve ödülü sunucu işler (Purchases).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local StarterOffer = {}

local ROBUX = utf8.char(0xE002) -- Roblox'un Robux simgesi (yazı tipinde özel karakter)
local FONT = Enum.Font.FredokaOne
local WIDTH, HEIGHT = 150, 136

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

	-- Sağdaki RightHud sütununun EN ÜSTÜNE (FREE REWARD'ın ÜSTÜNE; sahibi 'hediye paketini aşağı al, bunu onun üstüne koy' dedi) yerleşir; sütun yoksa aynı yere kendisi konur.
	-- GÖRÜNÜM referans oyundaki gibi (2026-10-17): kutu/çerçeve YOK, paketin görseli büyük ve serbest durur, sol üstünde eğik yeşil fiyat rozeti,
	-- altında gökkuşağı 'Starter Pack' yazısı.
	local column = screenGui:FindFirstChild("RightHud")
	local holder = create("Frame", {
		Name = "StarterOffer",
		LayoutOrder = 0,
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundTransparency = 1,
		Visible = false,
	}, column or screenGui)
	if not column then
		holder.AnchorPoint = Vector2.new(1, 0)
		holder.Position = UDim2.new(1, -14, 0.4, -HEIGHT)
	end

	-- Görsel (basınca satın alma penceresi): bütün üst alan tıklanır
	local card = create("TextButton", {
		Name = "OfferCard",
		Size = UDim2.new(1, 0, 0, 112),
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}, holder)
	local imageId = Config.Icons and Config.Icons.StarterPack
	if type(imageId) == "string" and imageId ~= "" then
		create("ImageLabel", {
			Name = "PackImage",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromOffset(112, 112),
			BackgroundTransparency = 1,
			Image = imageId,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}, card)
	else
		outlined(card, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(90, 90), Text = "🎁", ZIndex = 2 }, 0)
	end
	local cardScale = create("UIScale", { Scale = 1 }, card)

	-- Fiyat rozeti: sol üstte, hafif eğik, yeşil (referanstaki gibi görselin üstüne biner)
	local price = create("Frame", {
		Name = "PriceTag",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(34, 18),
		Size = UDim2.fromOffset(66, 30),
		Rotation = -10,
		BackgroundColor3 = Color3.fromRGB(70, 215, 70),
		ZIndex = 4,
	}, card)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, price)
	UIStyle.soften(price, { radius = 10, strength = 0.25 })
	outlined(price, { Position = UDim2.fromScale(0.06, 0.08), Size = UDim2.fromScale(0.88, 0.84), Text = `{ROBUX} {product.robux}`, TextColor3 = Color3.new(1, 1, 1), ZIndex = 5 }, 2.5)

	-- Gökkuşağı başlık (görselin altında)
	local title = outlined(holder, {
		Position = UDim2.fromOffset(0, 108),
		Size = UDim2.new(1, 0, 0, 26),
		Text = "Starter Pack",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
	}, 3)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(120, 255, 140)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 230, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 200)),
		}),
	}, title)

	local function refresh()
		holder.Visible = product.productId > 0
			and player:GetAttribute("DataLoaded") == true
			and player:GetAttribute("StarterPackOwned") ~= true
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
	for _, attribute in { "DataLoaded", "StarterPackOwned", "PaidRandomRestricted" } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	refresh()
end

return StarterOffer
