-- Shop penceresi: Robux ile alınan ürünler. İki sekme (UIStyle tasarım sistemi, vurgu rengi primary/sarı):
--  * POTIONS (Config.Shop.Potions): iksir kartları (üstte şişe, ad, etki, süre çipi, altta tam genişlik düğme). Envanterde o iksirden varsa (çark / Gifts / görev bonusundan çıkanlar)
--    butonda fiyat yerine 'USE xN' yazar ve basınca iksir içilir (sunucu 'UsePotion'); hiç yoksa Robux fiyatı yazar ve basınca Roblox satın alma penceresi açılır (alınan iksir hemen içilir).
--  * PACKS & MORE: VIP game pass ve Config.Shop.Products (Power paketleri, Pet Space, Win paketleri).
-- productId 0 olan ürünlerde fiyat yine görünür (düğme sönük) ama basınca 'coming soon' bildirimi çıkar (Robux aşamasında ID'ler girilir). Ödülü sunucu ProcessReceipt ile verir (server/Purchases).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
require(Shared:WaitForChild("Catalog")) -- iksir ürünlerine (Config.Shop.Potions) .def / .kind alanlarını ekler
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local TweenService = game:GetService("TweenService")

local ShopPanel = {}

local Theme = UIStyle.Theme
local C = Theme.colors
local ROBUX = utf8.char(0xE002) -- Roblox'un Robux simgesi (yazı tipinde özel karakter)
local CARD_H = 206 -- kart yüksekliği (arayüz birimi)
local ICON_WRAP = 76 -- kart üstündeki simge zemini
local CORE_SIZE = 28 -- yeni iksir rozetindeki kırmızı yuvarlağın kenarı (piksel): Gifts rozetiyle AYNI ölçü (sahibi 'giftsin orantısı güzel' dedi); nabızda +4 büyür
-- 'En iyi değer' köşe şeridi alan ürünler (Config.Shop.Products id'si -> yazı)
local RIBBONS = { winsBig = "BEST VALUE" }

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Döner: pencereyi açıp kapatan fonksiyon. shopButton (isteğe bağlı): soldaki Shop düğmesi; yeni iksir gelince köşesinde kırmızı yuvarlak (sayı) belirir
function ShopPanel.init(screenGui, showToast, shopButton)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	-- Pencere: genişlik ekranın %92'si ile 640 arasında, yükseklik ekranın %90'ı ile 500 arasında
	local panel = UIStyle.panel(screenGui, {
		name = "ShopPanel",
		width = 640,
		size = UDim2.new(0, 0, 0.9, 0),
		accent = "primary",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.48),
	})
	panel.Visible = false
	panel.Active = true -- pencereye tıklamak hareket başlatmasın
	pcall(function()
		panel:FindFirstChild("WidthLimit").MaxSize = Vector2.new(640, 500)
	end)

	-- Başlıktaki Win bakiyesi çipi (kupa + miktar)
	local winValue = nil
	pcall(function()
		local stats = player:FindFirstChild("leaderstats")
		winValue = stats and stats:FindFirstChild(Config.StatWins)
	end)
	local header = UIStyle.header(panel, {
		title = "Shop",
		icon = Config.Icons.Shop,
		emoji = "🛒",
		accent = "primary",
		chip = "🏆 " .. (if winValue then Format.number(winValue.Value) else "0"),
		onClose = function()
			PanelManager.hide(panel)
		end,
	})
	pcall(function()
		if header.chip and winValue then
			winValue:GetPropertyChangedSignal("Value"):Connect(function()
				UIStyle.setChipText(header.chip, "🏆 " .. Format.number(winValue.Value))
			end)
		end
	end)

	-- Sekmeler: POTIONS / PACKS & MORE (her biri ayrı kaydırma alanı; sekme değişince başa döner)
	local lists = {}
	local function makeList(id)
		local list = create("ScrollingFrame", {
			Name = "List_" .. id,
			Position = UDim2.fromOffset(0, 124),
			Size = UDim2.new(1, 0, 1, -124),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = C.textMute,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = id == "potions",
		}, panel)
		create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}, list)
		local grid = create("UIGridLayout", {
			CellSize = UDim2.new(1 / 3, -7, 0, CARD_H),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)
		lists[id] = { list = list, grid = grid }
		return list
	end
	local potionList = makeList("potions")
	local packList = makeList("packs")

	local tabs = UIStyle.tabs(panel, {
		items = { { id = "potions", text = "POTIONS" }, { id = "packs", text = "PACKS & MORE" } },
		accent = "primary",
		selected = "potions",
		props = { Position = UDim2.fromOffset(16, 68), Size = UDim2.new(1, -32, 0, 44) },
		onSelect = function(id)
			for listId, entry in lists do
				entry.list.Visible = listId == id
				if listId == id then
					entry.list.CanvasPosition = Vector2.new(0, 0)
				end
			end
		end,
	})

	-- Dar ekranda (telefon) 2 sütun, genişte 3 sütun
	local function updateColumns()
		local width = 640
		pcall(function()
			local uiScale = screenGui:FindFirstChildOfClass("UIScale")
			local factor = if uiScale and uiScale.Scale > 0 then uiScale.Scale else 1
			local measured = panel.AbsoluteSize.X / factor
			if type(measured) == "number" and measured > 0 then
				width = measured
			end
		end)
		for _, entry in lists do
			entry.grid.CellSize = if width < 520 then UDim2.new(0.5, -5, 0, CARD_H) else UDim2.new(1 / 3, -7, 0, CARD_H)
		end
	end
	updateColumns()
	pcall(function()
		panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateColumns)
	end)

	-- Kart iskeleti: ortada simge zemini, ad, etki satırı; altta tam genişlik eylem düğmesi. Döner: kart, simge zemini
	local function buildCard(parent, order, accentColor, name, detail, minutesText, ribbon)
		local card = UIStyle.card(parent, { name = "ShopCard", padding = false, props = { LayoutOrder = order } })
		local wrap = create("Frame", {
			Name = "IconWrap",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 12),
			Size = UDim2.fromOffset(ICON_WRAP, ICON_WRAP),
			BackgroundColor3 = accentColor,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
		}, card)
		UIStyle.round(wrap, UDim.new(1, 0))
		UIStyle.label(card, { name = "CardName", text = name, role = "bold", align = "center", props = { Position = UDim2.fromOffset(8, 92), Size = UDim2.new(1, -16, 0, 20) } })
		UIStyle.label(card, { name = "CardDetail", text = detail, role = "caption", align = "center", wrap = true, props = { Position = UDim2.fromOffset(8, 112), Size = UDim2.new(1, -16, 0, 38), TextYAlignment = Enum.TextYAlignment.Top } })
		if minutesText then
			UIStyle.chip(card, { name = "MinutesChip", text = minutesText, accent = "info", props = { Position = UDim2.fromOffset(8, 8) } })
		end
		if ribbon then
			UIStyle.chip(card, { name = "Ribbon", text = ribbon, accent = "primary", props = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8) } })
		end
		return card, wrap
	end

	local function addButton(card, id, text, kind, onClick)
		return UIStyle.button(card, {
			name = id,
			text = text,
			kind = kind,
			size = "md",
			width = UDim2.new(1, -20, 0, 0),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -10),
			onClick = onClick,
		})
	end

	-- ------------------------------------------------------------ POTIONS
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
		local detail = if sku.forSale == false then `{potion.effect} ({potion.source})` else potion.effect
		local card, wrap = buildCard(potionList, order, potion.color, potion.name, detail, `{sku.minutes} min`)
		local icon = UIStyle.potionIcon(wrap, potion, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60) })
		icon.ZIndex = 3
		local button = addButton(card, "Buy_" .. sku.id, "", "primary", function()
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
		table.insert(potionRows, { sku = sku, button = button, card = card })
	end
	for index, sku in Config.Shop.Potions do
		addPotionCard(index, sku)
	end

	-- Envanterde o iksirden varsa fiyat yerine 'USE xN' (yeşil), yoksa Robux fiyatı (sarı)
	local function refreshPotions()
		local items = parseItems()
		for _, row in potionRows do
			local owned = items[row.sku.id] or 0
			-- Auto Click game pass'i olana Auto Click Potion anlamsızdır (yerine Rainbow verilir): kart (ve düğmesi) gizlenir
			local visible = not (row.sku.forSale == false and player:GetAttribute("HasAutoClick") == true)
			row.card.Visible = visible
			row.button.Visible = visible
			if owned > 0 then
				UIStyle.setButtonText(row.button, `USE  x{owned}`)
				UIStyle.setButtonKind(row.button, "success")
			elseif row.sku.forSale == false then
				-- Satılmayan iksir: envanterde yoksa Auto Click pass'ini (kalıcı) göster; Robux isteği burada
				local hasPass = player:GetAttribute("HasAutoClick") == true
				UIStyle.setButtonText(row.button, if hasPass then "OWNED FOREVER" elseif (Config.AutoClick.GamePassId or 0) > 0 then `{ROBUX} {Config.AutoClick.Robux} FOREVER` else "WIN IT!")
				UIStyle.setButtonKind(row.button, if hasPass or (Config.AutoClick.GamePassId or 0) <= 0 then "secondary" else "primary")
			else
				UIStyle.setButtonText(row.button, `{ROBUX} {row.sku.robux}`)
				UIStyle.setButtonKind(row.button, "primary")
			end
		end
	end
	player:GetAttributeChangedSignal("HasAutoClick"):Connect(refreshPotions)
	player:GetAttributeChangedSignal("PotionItems"):Connect(refreshPotions)
	refreshPotions()

	-- YENİ İKSİR ROZETİ (2026-10-13, sahibi 'alınan potionlar markete gittiğinde marketin köşesinde kırmızı bir yuvarlak olsun, yeni potion geldiğini göstermek için' dedi):
	-- çark / Gifts / görev bonusu / Index ödülünden envantere iksir girince Shop düğmesinin sağ üst köşesinde kırmızı yuvarlak (yeni iksir sayısı) çıkar,
	-- Shop açılınca kalkar (iksirler orada 'USE xN' yazar). İçmek (USE) sayıyı düşürür ama rozet çıkarmaz; girişte zaten envanterde olanlar 'yeni' sayılmaz (DataLoaded'dan sonra ölçülür).
	if shopButton then
		-- İki katman: PotionBadge = sabit boyutlu, görünmez tutucu (köşede durur, hiç hareket etmez); Core = içindeki kırmızı yuvarlak. Nabızda SADECE Core'un Size'ı büyür/küçülür ve
		-- AnchorPoint ortada olduğu için her yöne eşit büyür (sahibi 'her yerinden büyüsün, tek yerinden değil' dedi: yuvarlağın kendisi değil sabit tutucu köşeye bağlıdır).
		local badge = create("Frame", {
			Name = "PotionBadge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(CORE_SIZE + 8, CORE_SIZE + 8),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 9,
		}, shopButton)
		local core = create("Frame", {
			Name = "Core",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CORE_SIZE, CORE_SIZE),
			BackgroundColor3 = Color3.fromRGB(232, 38, 52),
			ZIndex = 9,
		}, badge)
		create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, core) -- Gifts rozetiyle aynı siyah çerçeve
		UIStyle.soften(core, { radius = UDim.new(0.5, 0), strength = 0.3, shine = false }) -- yarıçap kenarın yarısı (ORAN): büyüyünce de tam daire kalır
		-- Sayı Gifts rozetindeki gibi: yuvarlağın %80'i kadar kutu, en çok 16 punto, ortada (kenara değmez)
		local badgeText = create("TextLabel", {
			BackgroundTransparency = 1,
			Font = Theme.fonts.title,
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			Text = "1",
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 10,
		}, core)
		create("UITextSizeConstraint", { MaxTextSize = 16 }, badgeText)
		local badgePulse = TweenService:Create(core, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromOffset(CORE_SIZE + 4, CORE_SIZE + 4) })
		local pulsing = false

		local function totalItems()
			local total = 0
			for _, count in parseItems() do
				total += count
			end
			return total
		end
		local baselineSet = false
		local seen = 0 -- şimdiye kadar görülen (Shop'ta ya da girişte envanterde bulunan) iksir sayısı
		local function updateBadge()
			if not baselineSet then
				if player:GetAttribute("DataLoaded") ~= true then
					return -- kayıt yüklenmeden envanter boş görünür: oturum başında gelen iksirler 'yeni' sayılmasın
				end
				baselineSet = true
				seen = totalItems()
			end
			local total = totalItems()
			if PanelManager.isOpen(panel) or total < seen then
				seen = total -- Shop açık (görüyor) ya da iksir içildi
			end
			local fresh = total - seen
			badge.Visible = fresh > 0
			if fresh > 0 then
				badgeText.Text = if fresh > 9 then "9+" else tostring(fresh)
				if not pulsing then
					pulsing = true
					badgePulse:Play()
				end
			elseif pulsing then
				pulsing = false
				badgePulse:Cancel()
				core.Size = UDim2.fromOffset(CORE_SIZE, CORE_SIZE)
			end
		end
		player:GetAttributeChangedSignal("PotionItems"):Connect(updateBadge)
		player:GetAttributeChangedSignal("DataLoaded"):Connect(updateBadge)
		panel:GetAttributeChangedSignal("PanelOpen"):Connect(updateBadge)
		updateBadge()
	end

	-- ------------------------------------------------------------ PACKS & MORE
	-- Tek kart: simge, ad, açıklama ve fiyat/satın alma düğmesi
	-- icon: emoji (yedek), imageId: Config.Icons'taki görsel (varsa emoji yerine büyük resim görünür)
	-- badge: simgenin sağ altına konan yeşil rozetin yazısı (örn. '+': yükseltme olduğu belli olsun)
	local function addCard(order, color, icon, imageId, name, detail, priceText, onBuy, badge, ribbon)
		local card, wrap = buildCard(packList, order, color, name, detail, nil, ribbon)
		if imageId and imageId ~= "" then
			create("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(60, 60),
				BackgroundTransparency = 1,
				Image = imageId,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
			}, wrap)
		else
			UIStyle.label(wrap, { name = "Icon", text = icon, role = "title", size = 36, align = "center", props = { Size = UDim2.fromScale(1, 1) } })
		end
		if badge then
			local disc = create("Frame", {
				Name = "UpgradeBadge",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -4, 1, -4),
				Size = UDim2.fromOffset(30, 30),
				BackgroundColor3 = C.success.base,
				ZIndex = 5,
			}, wrap)
			UIStyle.round(disc, UDim.new(0.5, 0))
			create("UIStroke", { Thickness = 2, Color = C.success.dark, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, disc)
			UIStyle.label(disc, { name = "BadgeText", text = badge, role = "title", size = 20, color = C.success.text, align = "center", props = { Size = UDim2.fromScale(1, 1), ZIndex = 6 } })
		end
		local buy = addButton(card, "Buy", priceText, "primary", onBuy)
		return card, buy
	end

	local order = 0

	-- VIP game pass (Config.VipGamePassId): fiyatı game pass'in kendisi belirler (Creator Hub), kartta fiyat / 'SOON' yazar
	order += 1
	local _, vipBuy = addCard(order, C.hot.base, "👑", Config.Icons.Vip, "VIP", "2x Wins pad", if Config.VipGamePassId > 0 then `{ROBUX} {Config.VipRobux}` else "SOON", function()
		if Config.VipGamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.VipGamePassId)
		else
			showToast(false, "VIP is coming soon!")
		end
	end)
	if Config.VipGamePassId <= 0 then
		UIStyle.setButtonEnabled(vipBuy, false)
	end

	-- AUTO CLICK game pass'i (Config.AutoClick.GamePassId, server/AutoClickPass): sahipse kart 'OWNED', değilse fiyat; satış yokken (ID 0) 'SOON'
	order += 1
	local _, autoBuy = addCard(order, C.info.base, "🖱️", Config.Icons.Click, "Auto Click", "Clicks for you!", "SOON", function()
		if (Config.AutoClick.GamePassId or 0) > 0 and player:GetAttribute("HasAutoClick") ~= true then
			MarketplaceService:PromptGamePassPurchase(player, Config.AutoClick.GamePassId)
		elseif (Config.AutoClick.GamePassId or 0) <= 0 then
			showToast(false, "Auto Click is coming soon!")
		end
	end)
	local function refreshAuto()
		local selling = (Config.AutoClick.GamePassId or 0) > 0
		local owned = selling and player:GetAttribute("HasAutoClick") == true
		UIStyle.setButtonText(autoBuy, if owned then "OWNED" elseif selling then `{ROBUX} {Config.AutoClick.Robux}` else "SOON")
		UIStyle.setButtonKind(autoBuy, if owned or not selling then "secondary" else "primary")
	end
	refreshAuto()
	player:GetAttributeChangedSignal("HasAutoClick"):Connect(refreshAuto)

	for _, product in Config.Shop.Products do
		order += 1
		local card, buy = addCard(order, product.color, product.icon, product.imageKey and Config.Icons[product.imageKey], product.name, product.detail, `{ROBUX} {product.robux}`, function()
			if product.productId > 0 then
				MarketplaceService:PromptProductPurchase(player, product.productId)
			else
				showToast(false, `{product.name} is coming soon!`)
			end
		end, product.badge, RIBBONS[product.id])
		if product.productId <= 0 then
			UIStyle.setButtonEnabled(buy, false) -- henüz satışta değil: fiyat görünür (sönük), basınca 'coming soon'
		end
		if product.once then
			-- Tek seferlik ürün (Başlangıç Paketi): alındıktan sonra kart kalkar (sunucu 'StarterPackOwned' özniteliğini koyar)
			local function refreshOnce()
				card.Visible = player:GetAttribute("StarterPackOwned") ~= true
			end
			player:GetAttributeChangedSignal("StarterPackOwned"):Connect(refreshOnce)
			refreshOnce()
		end
	end

	-- Döner: pencereyi açıp kapatan fonksiyon. section = 'packs' verilirse pencere AÇILIR ve 'PACKS & MORE' (Win paketleri) sekmesi seçilir
	-- (yumurtada Win yetmeyince yönlendirme; sahibi istedi).
	return function(section)
		if section ~= "packs" then
			PanelManager.toggle(panel)
			return
		end
		tabs.select("packs")
		PanelManager.show(panel)
	end
end

return ShopPanel
