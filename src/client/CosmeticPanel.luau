-- Genel "kozmetik" menüsü: Trails ve Auras aynı kodu kullanır. Her öğe için kart: adı, önizleme, bonus yazısı,
-- Win ve Robux fiyatı; sahip olunanlar için Equip butonu. Satın alma ve takma sunucuda yapılır.
-- Görünüm: UIStyle tasarım sistemi (panel, header, card, button, chip); 2 sütunlu kart ızgarası.
--
-- options = {
--   title, icon, image (başlık simgesi), items (Config listesi), ownedAttr, equippedAttr, buyAction, equipAction,
--   bonusText(item) -> kartta gösterilen bonus yazısı, previewKind = "trail" | "aura",
--   (eski headerTop/headerBottom/panelColor artık kullanılmaz; tasarım sisteminden gelir)
-- }
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
local Format = require(Shared:WaitForChild("Format"))

local CosmeticPanel = {}

local Theme = UIStyle.Theme
local C = Theme.colors

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 220, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(120, 80, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
})

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Kart ölçüleri (2 sütun, 460 birimlik pencerede)
local CELL_W, CELL_H = 200, 178

-- showToast(ok, mesaj): kısa bildirim gösterir. Dönüş: { toggle, show, hide, panel }.
function CosmeticPanel.init(screenGui, showToast, options)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local winValue = player:WaitForChild("leaderstats"):WaitForChild(Config.StatWins)
	local headerAccent = if options.previewKind == "aura" then "magic" else "hot"

	local panel = UIStyle.panel(screenGui, {
		name = "CosmeticPanel",
		width = 460,
		height = 450,
		accent = "magic",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})
	panel.Visible = false
	panel.Active = true -- panele tıklamak hareket başlatmasın

	-- image: menüdeki düğmeyle aynı görsel (Config.Icons), yoksa icon emojisi
	UIStyle.header(panel, {
		title = options.title,
		icon = options.image,
		emoji = options.icon,
		accent = headerAccent,
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	local list = create("ScrollingFrame", {
		Name = "CosmeticList",
		Position = UDim2.fromOffset(0, 68),
		Size = UDim2.new(1, 0, 1, -68),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.textMute,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 12),
	}, list)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(CELL_W, CELL_H),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, list)

	local function invoke(action, id)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			showToast(ok, message or "")
		end)
	end

	local function render()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local owned = {}
		for id in string.gmatch(player:GetAttribute(options.ownedAttr) or "", "[^,]+") do
			owned[id] = true
		end
		local equipped = player:GetAttribute(options.equippedAttr) or ""
		local wins = winValue.Value

		-- Sezonluk etkinlik gibi yalnızca sahibi olunca görünen ürünler (options.ownedOnlyItems) listenin sonuna eklenir
		local entries = table.clone(options.items)
		for _, extra in options.ownedOnlyItems or {} do
			if owned[extra.id] then
				table.insert(entries, extra)
			end
		end
		for index, item in entries do
			local isOwned = owned[item.id] == true
			local isEquipped = isOwned and equipped == item.id
			local card = UIStyle.card(list, {
				name = "Item_" .. tostring(item.id),
				accent = "success",
				selected = isEquipped,
				padding = false,
				props = { LayoutOrder = index, Size = UDim2.fromOffset(CELL_W, CELL_H) },
			})

			-- Önizleme çukuru: iz için sona doğru solan şerit + tema simgesi, aura için parlak yuvarlak
			local well = create("Frame", {
				Name = "Preview",
				Position = UDim2.fromOffset(8, 8),
				Size = UDim2.new(1, -16, 0, 52),
				BackgroundColor3 = C.cardDeep,
				BorderSizePixel = 0,
			}, card)
			UIStyle.round(well, Theme.radius.chip)

			if options.previewKind == "aura" then
				local orb = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(38, 38),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
				}, well)
				create("UICorner", { CornerRadius = UDim.new(1, 0) }, orb)
				create("UIGradient", { Color = if item.rainbow then RAINBOW else ColorSequence.new(item.color) }, orb)
			else
				local preview = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.new(1, -62, 0, 18),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
				}, well)
				create("UICorner", { CornerRadius = UDim.new(1, 0) }, preview)
				create("UIGradient", {
					Color = if item.rainbow then RAINBOW else ColorSequence.new(item.color),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					}),
				}, preview)
				-- İZ TEMASI SİMGESİ (2026-10-14, tester E4: 'trail'ler oyunla alakasız görünüyor'): iz neyin izini bırakıyorsa onun simgesi (tuğla, pati, kupa, bacak kası; Config.Trails[].icon),
				-- yüklü görsel yoksa emoji (Config.Trails[].emoji); tuğla simgesi iz rengine boyanır (iconTint)
				local iconId = item.icon and Config.Icons[item.icon]
				if type(iconId) == "string" and iconId ~= "" then
					create("ImageLabel", {
						Name = "TrailIcon",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -8, 0.5, 0),
						Size = UDim2.fromOffset(38, 38),
						BackgroundTransparency = 1,
						Image = iconId,
						ImageColor3 = if item.iconTint then item.color else Color3.new(1, 1, 1),
						ScaleType = Enum.ScaleType.Fit,
					}, well)
				elseif item.emoji then
					UIStyle.label(well, {
						name = "TrailIcon",
						text = item.emoji,
						role = "bold",
						size = 26,
						align = "center",
						props = {
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -8, 0.5, 0),
							Size = UDim2.fromOffset(38, 38),
						},
					})
				end
			end

			-- Durum çipi: sahip / takılı (alınabilir kartta çip yok, fiyat düğmesi var)
			if isOwned then
				UIStyle.chip(well, {
					name = "StatusChip",
					text = if isEquipped then "EQUIPPED" else "OWNED",
					accent = if isEquipped then "success" else "info",
					props = { Position = UDim2.fromOffset(6, 6) },
				})
			end

			UIStyle.label(card, {
				name = "ItemName",
				text = item.name,
				role = "bold",
				props = { Position = UDim2.fromOffset(10, 66), Size = UDim2.new(1, -20, 0, 20) },
			})
			UIStyle.label(card, {
				name = "ItemBonus",
				text = options.bonusText(item),
				role = "caption",
				color = C.success.base,
				props = { Position = UDim2.fromOffset(10, 86), Size = UDim2.new(1, -20, 0, 18) },
			})

			if isOwned then
				UIStyle.button(card, {
					name = "EquipButton",
					text = if isEquipped then "Equipped" else "Equip",
					kind = if isEquipped then "secondary" else "success",
					size = "sm",
					icon = if isEquipped then "●" else nil,
					width = CELL_W - 20,
					position = UDim2.fromOffset(10, 128),
					onClick = function()
						invoke(options.equipAction, if isEquipped then "" else item.id)
					end,
				})
			else
				local affordable = wins >= item.winPrice
				local winButton = UIStyle.button(card, {
					name = "BuyWin",
					text = `🏆 {Format.compact(item.winPrice)}`,
					kind = if affordable then "primary" else "secondary",
					size = "sm",
					width = 112,
					position = UDim2.fromOffset(10, 128),
					onClick = function()
						invoke(options.buyAction, item.id)
					end,
				})
				if not affordable and winButton then
					-- Win yetmiyorsa fiyat sönük
					pcall(function()
						winButton.Body.Label.TextColor3 = C.textMute
					end)
				end
				UIStyle.button(card, {
					name = "BuyRobux",
					text = `R$ {item.robuxPrice}`,
					kind = "ghost",
					size = "sm",
					width = CELL_W - 20 - 112 - 6,
					position = UDim2.fromOffset(10 + 112 + 6, 128),
					onClick = function()
						if item.robuxProductId > 0 then
							-- Satın alma penceresi açılır; ödülü sunucu ProcessReceipt ile verir (server/Purchases)
							MarketplaceService:PromptProductPurchase(Players.LocalPlayer, item.robuxProductId)
						else
							showToast(false, "Robux purchases are coming soon!")
						end
					end,
				})
			end
		end
	end

	local function show()
		PanelManager.show(panel)
		render()
	end
	local function hide()
		PanelManager.hide(panel)
	end
	local function toggle()
		if PanelManager.isOpen(panel) then
			hide()
		else
			show()
		end
	end

	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
		end
	end
	winValue:GetPropertyChangedSignal("Value"):Connect(onChange)
	player:GetAttributeChangedSignal(options.ownedAttr):Connect(onChange)
	player:GetAttributeChangedSignal(options.equippedAttr):Connect(onChange)

	return { toggle = toggle, show = show, hide = hide, panel = panel }
end

return CosmeticPanel
