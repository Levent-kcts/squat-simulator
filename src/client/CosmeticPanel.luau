-- Genel "kozmetik" menüsü: Trails ve Auras aynı kodu kullanır. Her öğe için kart: adı, önizleme, bonus yazısı,
-- Win ve Robux fiyatı; sahip olunanlar için Equip butonu. Satın alma ve takma sunucuda yapılır.
--
-- options = {
--   title, icon, headerTop, headerBottom (başlık renkleri), panelColor,
--   items (Config listesi), ownedAttr, equippedAttr, buyAction, equipAction,
--   bonusText(item) -> kartta gösterilen bonus yazısı, previewKind = "trail" | "aura",
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

local FONT = Enum.Font.FredokaOne

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

-- Kalın siyah kenarlı yazı
local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- showToast(ok, mesaj): kısa bildirim gösterir. Dönüş: { toggle, show, hide, panel }.
function CosmeticPanel.init(screenGui, showToast, options)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local winValue = player:WaitForChild("leaderstats"):WaitForChild(Config.StatWins)

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 450),
		BackgroundColor3 = options.panelColor,
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = options.headerTop,
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, options.image, options.icon, { Position = UDim2.fromOffset(12, 5), Size = UDim2.fromOffset(46, 46) }) -- image: menüdeki düğmeyle aynı görsel (Config.Icons), yoksa icon emojisi
	makeText(header, {
		Position = UDim2.fromOffset(60, 8),
		Size = UDim2.new(0.5, 0, 1, -16),
		Text = options.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, 3)

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(215, 40, 75),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 64),
		Size = UDim2.new(1, -16, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

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
			local card = create("Frame", {
				LayoutOrder = index,
				Size = UDim2.new(1, -10, 0, 120),
				BackgroundColor3 = item.color:Lerp(Color3.new(0, 0, 0), 0.55),
			}, list)
			create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
			UIStyle.soften(card, { radius = 12, strength = 0.3 })

			-- İZ KART SİMGESİ (2026-10-18, sahibi 'iz simgelerini üret, oyunda gerekli yerlerde olsun' dedi): izin kendi resmi varsa (Config.Icons.Trail_<id>)
			-- kartın solunda BÜYÜK durur ve eski renk şeridinin yerini alır (simgenin içinde izin akışı zaten çizili); resim yoksa eski şerit + küçük simge/emoji
			local trailImage = options.previewKind ~= "aura" and item.icon and Config.Icons[item.icon]
			if type(trailImage) ~= "string" or trailImage == "" or item.iconTint then
				trailImage = nil
			end
			local textX = if trailImage then 112 else 14

			makeText(card, {
				Position = UDim2.fromOffset(textX, 6),
				Size = UDim2.new(0.55, 0, 0, 36),
				Text = item.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.new(1, 1, 1),
			}, 3)

			-- Önizleme: iz için sona doğru solan şerit, aura için parlak yuvarlak
			if options.previewKind == "aura" then
				local orb = create("Frame", {
					Position = UDim2.fromOffset(18, 48),
					Size = UDim2.fromOffset(38, 38),
					BackgroundColor3 = Color3.new(1, 1, 1),
				}, card)
				create("UICorner", { CornerRadius = UDim.new(1, 0) }, orb)
				create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, orb)
				create("UIGradient", { Color = if item.rainbow then RAINBOW else ColorSequence.new(item.color) }, orb)
			elseif trailImage then
				create("ImageLabel", {
					Name = "TrailIcon",
					Position = UDim2.fromOffset(8, 12),
					Size = UDim2.fromOffset(96, 96),
					BackgroundTransparency = 1,
					Image = trailImage,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 2,
				}, card)
			else
				local preview = create("Frame", {
					Position = UDim2.fromOffset(16, 52),
					Size = UDim2.fromOffset(150, 26),
					BackgroundColor3 = Color3.new(1, 1, 1),
				}, card)
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
						Position = UDim2.fromOffset(176, 45),
						Size = UDim2.fromOffset(40, 40),
						BackgroundTransparency = 1,
						Image = iconId,
						ImageColor3 = if item.iconTint then item.color else Color3.new(1, 1, 1),
						ScaleType = Enum.ScaleType.Fit,
					}, card)
				elseif item.emoji then
					makeText(card, {
						Name = "TrailIcon",
						Position = UDim2.fromOffset(176, 45),
						Size = UDim2.fromOffset(40, 40),
						Text = item.emoji,
						TextColor3 = Color3.new(1, 1, 1),
					}, 1)
				end
			end

			makeText(card, {
				Position = UDim2.fromOffset(if trailImage then textX elseif options.previewKind == "aura" then 66 else 16, 86),
				Size = UDim2.new(0.5, 0, 0, 26),
				Text = options.bonusText(item),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(150, 255, 170),
			}, 2)

			local function button(yOffset, height, color, text, onClick)
				local b = create("TextButton", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -12, 0, yOffset),
					Size = UDim2.new(0.38, 0, 0, height),
					Text = "",
					BackgroundColor3 = color,
				}, card)
				create("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
				create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, b)
				UIStyle.soften(b, { radius = 10, strength = 0.28 })
				makeText(b, {
					Position = UDim2.fromScale(0.05, 0.1),
					Size = UDim2.fromScale(0.9, 0.8),
					Text = text,
					TextColor3 = Color3.new(1, 1, 1),
				}, 2)
				b.MouseButton1Click:Connect(onClick)
				return b
			end

			if owned[item.id] then
				local isEquipped = equipped == item.id
				button(
					24,
					72,
					if isEquipped then Color3.fromRGB(110, 110, 120) else Color3.fromRGB(60, 200, 90),
					if isEquipped then "Equipped" else "Equip",
					function()
						invoke(options.equipAction, if isEquipped then "" else item.id)
					end
				)
			else
				local affordable = wins >= item.winPrice
				button(
					10,
					48,
					if affordable then Color3.fromRGB(255, 170, 30) else Color3.fromRGB(150, 110, 70),
					`🏆 {Format.compact(item.winPrice)}`,
					function()
						invoke(options.buyAction, item.id)
					end
				)
				button(62, 48, Color3.fromRGB(50, 150, 255), `R$ {item.robuxPrice}`, function()
					if item.robuxProductId > 0 then
						-- Satın alma penceresi açılır; ödülü sunucu ProcessReceipt ile verir (server/Purchases)
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, item.robuxProductId)
					else
						showToast(false, "Robux purchases are coming soon!")
					end
				end)
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
	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

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
