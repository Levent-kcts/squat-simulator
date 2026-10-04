-- Yumurta açılış ekranı: açılan petler nadirliğe göre renklenen kartlar olarak sırayla zıplayarak belirir, kısa süre durur ve solar.
-- Sadece görsel: sonucu sunucu verir (PlayerStats.hatchEgg). Yeni açılan pet "NEW!" rozeti alır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))

local Reveal = {}

local CARD_WIDTH = 104
local CARD_HEIGHT = 132
local CARD_GAP = 10
local PER_ROW = 5
local STAGGER = 0.08 -- kartlar arası gecikme
local HOLD = 1.8 -- tüm kartlar göründükten sonra ekranda kalma süresi

local current = nil -- açık olan açılış ekranı (yenisi gelince eskisi kaldırılır)

local function label(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.FredokaOne
	props.TextScaled = true
	local textLabel = Instance.new("TextLabel")
	for key, value in props do
		textLabel[key] = value
	end
	textLabel.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = textLabel
	return textLabel
end

local function buildCard(parent, entry, isNew, order)
	local pet = Catalog.PetById[entry.id]
	local rarity = Catalog.rarityOf(pet)
	local kept = entry.kept

	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.BackgroundColor3 = if kept then rarity.color else Color3.fromRGB(80, 82, 92)
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = if rarity.name == "Common" or not kept then 3 else 5
	stroke.Color = if kept and rarity.name ~= "Common" then rarity.color:Lerp(Color3.new(1, 1, 1), 0.55) else Color3.new(0, 0, 0)
	stroke.Parent = card

	-- Üst: çarpan
	label(card, {
		Position = UDim2.fromScale(0.05, 0.03),
		Size = UDim2.fromScale(0.9, 0.17),
		Text = `+{math.floor(pet.mult * 100 + 0.5)}%`,
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	-- Pet simgesi: pet renginde yuvarlak
	local icon = Instance.new("Frame")
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.fromScale(0.5, 0.22)
	icon.Size = UDim2.fromOffset(52, 52)
	icon.BackgroundColor3 = if kept then pet.color else pet.color:Lerp(Color3.fromRGB(80, 82, 92), 0.7)
	icon.Parent = card
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Thickness = 3
	iconStroke.Color = Color3.new(0, 0, 0)
	iconStroke.Parent = icon

	label(card, {
		Position = UDim2.fromScale(0.04, 0.63),
		Size = UDim2.fromScale(0.92, 0.17),
		Text = pet.name,
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)
	label(card, {
		Position = UDim2.fromScale(0.04, 0.81),
		Size = UDim2.fromScale(0.92, 0.15),
		Text = if kept then rarity.name else "Deleted",
		TextColor3 = if kept then rarity.color:Lerp(Color3.new(1, 1, 1), 0.6) else Color3.fromRGB(255, 120, 120),
	}, 2)

	-- Yeni pet rozeti (sağ üst köşede, hafif eğik)
	if isNew and kept then
		local badge = label(card, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.86, 0.1),
			Size = UDim2.fromOffset(52, 22),
			Rotation = 14,
			Text = "NEW!",
			TextColor3 = Color3.fromRGB(255, 240, 80),
			ZIndex = 3,
		}, 2)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = Color3.fromRGB(235, 40, 70)
		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 6)
		badgeCorner.Parent = badge
	end

	return card
end

-- results: { { id, kept } ... } açılış sırasıyla; ownedBefore: açmadan önce sahip olunan pet id'leri { [id] = true }
function Reveal.show(screenGui, results, ownedBefore)
	if current then
		current:Destroy()
		current = nil
	end
	if type(results) ~= "table" or #results == 0 then
		return
	end

	local count = #results
	local columns = math.min(count, PER_ROW)
	local rows = math.ceil(count / PER_ROW)

	local holder = Instance.new("Frame")
	holder.Name = "HatchReveal"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.38)
	holder.Size = UDim2.fromOffset(columns * (CARD_WIDTH + CARD_GAP), rows * (CARD_HEIGHT + CARD_GAP))
	holder.BackgroundTransparency = 1
	holder.Parent = screenGui
	current = holder

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	grid.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	grid.FillDirectionMaxCells = PER_ROW
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = holder

	local seen = {}
	local cards = {}
	for index, entry in results do
		local isNew = not (ownedBefore and ownedBefore[entry.id]) and not seen[entry.id]
		seen[entry.id] = true
		local card = buildCard(holder, entry, isNew, index)

		-- Kart küçükten büyüğe zıplayarak açılır
		local scale = Instance.new("UIScale")
		scale.Scale = 0
		scale.Parent = card
		table.insert(cards, scale)
		task.delay((index - 1) * STAGGER, function()
			if holder.Parent then
				TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end)
	end

	-- Bir süre durup küçülerek kaybolur
	local total = (count - 1) * STAGGER + 0.3 + HOLD
	task.delay(total, function()
		if current ~= holder or not holder.Parent then
			return
		end
		for _, scale in cards do
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		end
		task.delay(0.3, function()
			if holder.Parent then
				holder:Destroy()
			end
			if current == holder then
				current = nil
			end
		end)
	end)
end

return Reveal
