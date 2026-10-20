-- Pet Index (koleksiyon defteri): bütün pet türleri kart olarak listelenir; sahip olunmuş (keşfedilmiş) türler renkli ve yüzlü,
-- henüz görülmemişler sönük ve "???" yazılıdır. Keşfedilen her tür kalıcı +%1 bacak kası verir (Config.Index, sunucuda hesaplanır).
-- Sunucu DiscoveredPets (virgüllü tür listesi) ve IndexBonus (yüzde) özniteliklerini ayarlar; burası sadece gösterir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local IndexPanel = {}

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

-- Bir Index ödülünü kısa yazıya çevirir ('+150 Wins', '60 min Luck Potion')
local function describeReward(reward)
	if reward.kind == "wins" then
		return `+{Format.compact(reward.amount)} Wins`
	end
	local potion = Catalog.PotionByKind[reward.kind]
	return `{reward.minutes or Config.BoostMinutes} min {if potion then potion.name else "potion"}`
end

-- Sıradaki ödül satırı (playtest isteği: Pet Index tamamlama ödülü): ulaşılmamış ilk eşik, hepsi bitince tamamlama bonusu
local function nextRewardText(count)
	for _, reward in Config.Index.Rewards do
		if count < reward.count then
			return `Next reward at {reward.count} pets: {describeReward(reward)}`
		end
	end
	return `Index complete! +{Config.Index.CompletionPercent}% Leg Muscle forever for each world!`
end

-- Döner: pencereyi açıp kapatan fonksiyon
function IndexPanel.init(screenGui)
	local player = Players.LocalPlayer

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(640, 460),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(150, 110, 255),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Index, "📖", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) })
	text(header, {
		Position = UDim2.fromOffset(68, 8),
		Size = UDim2.fromOffset(166, 40),
		Text = "PET INDEX",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
	local counter = text(header, {
		Position = UDim2.fromOffset(236, 8),
		Size = UDim2.new(1, -300, 0, 40),
		TextColor3 = Color3.fromRGB(255, 240, 150),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, 2)
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 40, 90),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	local subtitle = text(panel, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(600, 24),
		Text = `Each new pet = +{Config.Index.PercentPerPet}% Leg Muscle forever`,
		TextColor3 = Color3.fromRGB(215, 222, 255),
	}, 2)

	local grid = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 94),
		Size = UDim2.new(1, -20, 1, -104),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(112, 138),
		CellPadding = UDim2.fromOffset(8, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingTop = UDim.new(0, 4) }, grid)

	local function render()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local found = {}
		for id in string.gmatch(player:GetAttribute("DiscoveredPets") or "", "[^,]+") do
			found[id] = true
		end
		local pets = {}
		for _, pet in Config.Pets do
			table.insert(pets, pet)
		end
		table.sort(pets, function(a, b)
			return a.mult < b.mult
		end)

		local discovered = 0
		for order, pet in pets do
			local known = found[pet.id] == true
			if known then
				discovered += 1
			end
			local card = create("Frame", {
				LayoutOrder = order,
				BackgroundColor3 = if known then Catalog.rarityOf(pet).color else Color3.fromRGB(58, 62, 82),
			}, grid)
			create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
			UIStyle.soften(card, { radius = 10, strength = 0.3 })

			text(card, {
				Position = UDim2.fromScale(0.05, 0.03),
				Size = UDim2.fromScale(0.9, 0.17),
				Text = if known then Format.petBonus(pet.mult) else "+???",
				TextColor3 = if known then Color3.new(1, 1, 1) else Color3.fromRGB(150, 156, 180),
			}, 2)
			UIStyle.safePetIcon(card, pet, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.2),
				Size = UDim2.fromOffset(62, 62),
				dim = not known,
				lite = true, -- uzun liste: telefonda 3B yerine çizilmiş yüz (UIStyle.petModelIcon)
			})
			if not known then
				-- Keşfedilmemiş: yüzün üstüne büyük soru işareti
				text(card, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.26),
					Size = UDim2.fromOffset(44, 44),
					Text = "?",
					TextColor3 = Color3.fromRGB(235, 238, 255),
					ZIndex = 5,
				}, 3)
			end
			text(card, {
				Position = UDim2.fromScale(0.04, 0.74),
				Size = UDim2.fromScale(0.92, 0.2),
				Text = if known then pet.name else "???",
				TextColor3 = if known then Color3.new(1, 1, 1) else Color3.fromRGB(150, 156, 180),
			}, 2)
		end
		counter.Text = `{discovered}/{#pets}  +{player:GetAttribute("IndexBonus") or 0}%`
		subtitle.Text = `+{Config.Index.PercentPerPet}% per pet  |  {nextRewardText(discovered)}`
	end

	for _, name in { "DiscoveredPets", "IndexBonus" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if PanelManager.isOpen(panel) then
				render()
			end
		end)
	end

	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			render()
		end
	end
end

return IndexPanel
