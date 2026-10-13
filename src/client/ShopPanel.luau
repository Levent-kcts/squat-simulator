-- Shop penceresi: Robux ile alınan ürünler. İki bölüm:
--  * POTIONS (Config.Shop.Potions): iksir kartları (sol resim, ad, etki, süre, yeşil buton). Envanterde o iksirden varsa (çark / Gifts / görev bonusundan çıkanlar)
--    butonda fiyat yerine 'USE xN' yazar ve basınca iksir içilir (sunucu 'UsePotion'); hiç yoksa Robux fiyatı yazar ve basınca Roblox satın alma penceresi açılır (alınan iksir hemen içilir).
--  * PACKS & MORE: VIP game pass ve Config.Shop.Products (Power paketleri, Pet Space, Win paketleri).
-- productId 0 olan ürünlerde fiyat yine görünür ama basınca 'coming soon' bildirimi çıkar (Robux aşamasında ID'ler girilir). Ödülü sunucu ProcessReceipt ile verir (server/Purchases).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
require(Shared:WaitForChild("Catalog")) -- iksir ürünlerine (Config.Shop.Potions) .def / .kind alanlarını ekler
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local ShopPanel = {}

local FONT = Enum.Font.FredokaOne
local ROBUX = utf8.char(0xE002) -- Roblox'un Robux simgesi (yazı tipinde özel karakter)
local BUY_GREEN = Color3.fromRGB(72, 205, 40)
local USE_BLUE = Color3.fromRGB(60, 160, 255)
local CARD_ICON = 80 -- PACKS kartlarındaki simge kenarı (piksel)

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
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(640, 470),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(640, 470), MinSize = Vector2.new(300, 260) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(235, 50, 120),
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Shop, "🛒", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) })
	text(header, {
		Position = UDim2.fromOffset(68, 6),
		Size = UDim2.new(1, -150, 1, -12),
		Text = "SHOP",
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
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
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
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	create("UIPadding", { PaddingRight = UDim.new(0, 8) }, list)

	local function addHeader(order, label)
		local row = text(list, {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 28),
			Text = label,
			TextColor3 = Color3.fromRGB(255, 225, 90),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 2)
		return row
	end

	-- ------------------------------------------------------------ POTIONS
	addHeader(1, "POTIONS")
	local potionGrid = create("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, list)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(292, 104),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, potionGrid)

	-- Envanter özniteliği 'luck15:2,wins60:1' -> { luck15 = 2, wins60 = 1 }
	local function parseItems()
		local items = {}
		for sku, count in string.gmatch(player:GetAttribute("PotionItems") or "", "(%w+):(%d+)") do
			items[sku] = tonumber(count)
		end
		return items
	end

	local potionRows = {}
	local function addPotionCard(order, sku)
		local potion = sku.def
		local card = create("Frame", { LayoutOrder = order, BackgroundColor3 = UIStyle.lighten(potion.color, 0.2) }, potionGrid)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
		UIStyle.soften(card, { radius = 12, strength = 0.35 })
		UIStyle.brickSkin(card, 9, 3, 12, { light = 0.92 })
		local icon = UIStyle.potionIcon(card, potion, { Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(80, 80) })
		icon.ZIndex = 3
		text(card, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 4),
			Size = UDim2.fromOffset(190, 26),
			Text = potion.name,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		}, 2)
		text(card, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 30),
			Size = UDim2.fromOffset(190, 16),
			Text = potion.effect,
			TextColor3 = Color3.fromRGB(240, 248, 255),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		}, 1.5)
		text(card, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 46),
			Size = UDim2.fromOffset(190, 24),
			Text = if sku.forSale == false then `{sku.minutes} min  ({potion.source})` else `{sku.minutes} min`,
			TextColor3 = Color3.fromRGB(255, 225, 70),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		}, 2)
		local button = create("TextButton", {
			Name = "Buy_" .. sku.id,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -10, 1, -6),
			Size = UDim2.fromOffset(150, 30),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = BUY_GREEN,
			ZIndex = 5,
		}, card)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.3 })
		local label = text(button, {
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.new(1, -8, 1, -6),
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 6,
		}, 2)
		table.insert(potionRows, { sku = sku, button = button, label = label })

		button.MouseButton1Click:Connect(function()
			if (parseItems()[sku.id] or 0) > 0 then
				task.spawn(function()
					local ok, message = shopFunction:InvokeServer("UsePotion", sku.id)
					showToast(ok, message or "")
				end)
			elseif sku.forSale == false then
				-- Satılmayan iksir (Auto Click Potion): envanterde yoksa düğme Auto Click game pass'ini (kalıcı) açar
				if player:GetAttribute("HasAutoClick") == true then
					showToast(true, "You already own Auto Click forever!")
				elseif (Config.AutoClick.GamePassId or 0) > 0 then
					pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, Config.AutoClick.GamePassId)
				else
					showToast(false, `Win the {potion.name} from Daily Quests and the Daily Wheel!`)
				end
			elseif (sku.potion == "luck" or sku.potion == "rainbow") and player:GetAttribute("PaidRandomRestricted") ~= false then
				-- Roblox 'ücretli rastgele ürün' politikası (server/PaidRandomPolicy): kısıtlı hesapta (ya da henüz bilinmiyorken) şansı artıran iksir satılmaz
				showToast(false, "This potion is not available for your account.")
			elseif sku.productId > 0 then
				MarketplaceService:PromptProductPurchase(player, sku.productId)
			else
				showToast(false, `{potion.name} ({sku.minutes} min) is coming soon!`)
			end
		end)
	end
	for index, sku in Config.Shop.Potions do
		addPotionCard(index, sku)
	end

	-- Envanterde o iksirden varsa fiyat yerine 'USE xN' (mavi), yoksa Robux fiyatı (yeşil)
	local function refreshPotions()
		local items = parseItems()
		for _, row in potionRows do
			local owned = items[row.sku.id] or 0
			if owned > 0 then
				row.label.Text = `USE  x{owned}`
				row.button.BackgroundColor3 = USE_BLUE
			elseif row.sku.forSale == false then
				-- Satılmayan iksir: envanterde yoksa Auto Click pass'ini (kalıcı) göster; Robux isteği burada
				local owned = player:GetAttribute("HasAutoClick") == true
				row.label.Text = if owned then "OWNED FOREVER" elseif (Config.AutoClick.GamePassId or 0) > 0 then `{ROBUX} {Config.AutoClick.Robux} FOREVER` else "WIN IT!"
				row.button.BackgroundColor3 = if owned then Color3.fromRGB(110, 118, 135) else BUY_GREEN
			else
				row.label.Text = `{ROBUX} {row.sku.robux}`
				row.button.BackgroundColor3 = BUY_GREEN
			end
		end
	end
	player:GetAttributeChangedSignal("HasAutoClick"):Connect(refreshPotions)
	player:GetAttributeChangedSignal("PotionItems"):Connect(refreshPotions)
	refreshPotions()

	-- ------------------------------------------------------------ PACKS & MORE
	local packsHeader = addHeader(3, "PACKS & MORE")
	local packGrid = create("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, list)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(180, 192),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, packGrid)

	-- Tek kart: renkli kutu, simge, ad, açıklama ve fiyat/satın alma butonu
	-- icon: emoji (yedek), imageId: Config.Icons'taki görsel (varsa emoji yerine büyük resim görünür)
	-- badge: simgenin sağ altına konan büyük yeşil rozetin yazısı (örn. '+': yükseltme olduğu belli olsun)
	local function addCard(order, color, icon, imageId, name, detail, priceText, onBuy, badge)
		local card = create("Frame", { LayoutOrder = order, BackgroundColor3 = color }, packGrid)
		create("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
		UIStyle.soften(card, { radius = 12, strength = 0.28 })
		if imageId and imageId ~= "" then
			create("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 4),
				Size = UDim2.fromOffset(CARD_ICON, CARD_ICON),
				BackgroundTransparency = 1,
				Image = imageId,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
			}, card)
		else
			text(card, { Name = "Icon", Position = UDim2.fromScale(0.1, 0.03), Size = UDim2.fromOffset(144, 70), Text = icon }, 0)
		end
		if badge then
			local disc = create("Frame", {
				Name = "UpgradeBadge",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, CARD_ICON * 0.4, 0, CARD_ICON * 0.88),
				Size = UDim2.fromOffset(38, 38),
				BackgroundColor3 = BUY_GREEN,
				ZIndex = 5,
			}, card)
			create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disc)
			create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, disc)
			UIStyle.soften(disc, { radius = 19, strength = 0.3 })
			local mark = text(disc, { Position = UDim2.fromScale(0.05, 0), Size = UDim2.fromScale(0.9, 0.92), Text = badge, TextColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, 2)
			mark.Name = "BadgeText"
		end
		text(card, { Position = UDim2.fromScale(0.04, 0.45), Size = UDim2.fromScale(0.92, 0.14), Text = name, TextColor3 = Color3.new(1, 1, 1) }, 2)
		text(card, { Position = UDim2.fromScale(0.04, 0.6), Size = UDim2.fromScale(0.92, 0.1), Text = detail, TextColor3 = Color3.fromRGB(255, 245, 200) }, 1.5)
		local buy = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.8, 0.22),
			Text = "",
			BackgroundColor3 = BUY_GREEN,
		}, card)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, buy)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, buy)
		UIStyle.soften(buy, { radius = 10, strength = 0.28 })
		local priceLabel = text(buy, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = priceText, TextColor3 = Color3.new(1, 1, 1) }, 2)
		buy.MouseButton1Click:Connect(onBuy)
		return card, buy, priceLabel
	end

	local order = 0

	-- VIP game pass (Config.VipGamePassId): fiyatı game pass'in kendisi belirler (Creator Hub; en çok 150 Robux), kartta 'BUY' / 'SOON' yazar
	order += 1
	addCard(order, Color3.fromRGB(255, 80, 200), "👑", Config.Icons.Vip, "VIP", "2x Wins pad", if Config.VipGamePassId > 0 then `{ROBUX} {Config.VipRobux}` else "SOON", function()
		if Config.VipGamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.VipGamePassId)
		else
			showToast(false, "VIP is coming soon!")
		end
	end)

	-- AUTO CLICK game pass'i (Config.AutoClick.GamePassId, server/AutoClickPass): sahipse kart 'OWNED', değilse fiyat; satış yokken (ID 0) 'SOON'
	order += 1
	local _, autoBuy, autoLabel = addCard(order, Color3.fromRGB(70, 150, 255), "🖱️", Config.Icons.Click, "Auto Click", "Clicks for you!", "SOON", function()
		if (Config.AutoClick.GamePassId or 0) > 0 and player:GetAttribute("HasAutoClick") ~= true then
			MarketplaceService:PromptGamePassPurchase(player, Config.AutoClick.GamePassId)
		elseif (Config.AutoClick.GamePassId or 0) <= 0 then
			showToast(false, "Auto Click is coming soon!")
		end
	end)
	local function refreshAuto()
		local selling = (Config.AutoClick.GamePassId or 0) > 0
		local owned = selling and player:GetAttribute("HasAutoClick") == true
		autoLabel.Text = if owned then "OWNED" elseif selling then `{ROBUX} {Config.AutoClick.Robux}` else "SOON"
		autoBuy.BackgroundColor3 = if owned then Color3.fromRGB(110, 118, 135) else BUY_GREEN
	end
	refreshAuto()
	player:GetAttributeChangedSignal("HasAutoClick"):Connect(refreshAuto)

	for _, product in Config.Shop.Products do
		order += 1
		addCard(order, product.color, product.icon, product.imageKey and Config.Icons[product.imageKey], product.name, product.detail, `{ROBUX} {product.robux}`, function()
			if product.productId > 0 then
				MarketplaceService:PromptProductPurchase(player, product.productId)
			else
				showToast(false, `{product.name} is coming soon!`)
			end
		end, product.badge)
	end

	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	-- Döner: pencereyi açıp kapatan fonksiyon. section = 'packs' verilirse pencere AÇILIR ve 'PACKS & MORE' (Win paketleri) bölümüne kaydırılır
	-- (yumurtada Win yetmeyince yönlendirme; sahibi istedi). Ölçek: arayüz UIScale ile büyütülüyor, ekran piksel farkı birime çevrilir.
	return function(section)
		if section ~= "packs" then
			PanelManager.toggle(panel)
			return
		end
		PanelManager.show(panel)
		task.defer(function()
			task.wait() -- yerleşim (canvas boyu) hesaplansın
			local uiScale = screenGui:FindFirstChildOfClass("UIScale")
			local factor = if uiScale and uiScale.Scale > 0 then uiScale.Scale else 1
			local offset = (packsHeader.AbsolutePosition.Y - list.AbsolutePosition.Y) / factor + list.CanvasPosition.Y
			list.CanvasPosition = Vector2.new(0, math.max(0, offset - 4))
		end)
	end
end

return ShopPanel
