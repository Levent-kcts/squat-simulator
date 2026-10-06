-- Pet Fusion penceresi (lobideki makineye yaklaşıp E'ye basınca açılır): aynı petten Config.PetFusion.Cost tanesi tek bir BİR ÜST BOYLU pete dönüşür,
-- yeni pet daha büyük (kürenin boyu büyür) ve daha güçlüdür. Birleştirme sunucuda yapılır; bu pencere sahip olunan petleri gösterir ve istek yollar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
-- Kutlama efekti (isteğe bağlı): yüklenemezse birleştirme yine çalışır
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local FusionPanel = {}

local FONT = Enum.Font.FredokaOne

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Virgüllü listeyi { id = adet } sözlüğüne çevirir
local function toCounts(csv)
	local counts = {}
	for id in string.gmatch(csv or "", "[^,]+") do
		counts[id] = (counts[id] or 0) + 1
	end
	return counts
end

-- showToast(ok, mesaj): kısa bildirim. Dönüş: paneli açıp kapatan fonksiyon.
function FusionPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local fusion = Config.PetFusion

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(640, 470),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(170, 90, 255),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	makeText(header, {
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -90, 1, -16),
		Text = "⚗️ PET FUSION",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
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

	makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(560, 26),
		Text = `Fuse {fusion.Cost} of the same pet into 1 BIGGER, stronger pet!`,
		TextColor3 = Color3.fromRGB(235, 220, 255),
	}, 2)

	local grid = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 96),
		Size = UDim2.new(1, -20, 1, -96 - 70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(136, 168),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, grid)

	local emptyText = makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(480, 40),
		Text = "You have no pets yet. Open eggs to get some!",
		TextColor3 = Color3.fromRGB(200, 205, 225),
		Visible = false,
	}, 2)

	-- Alt çubuk: hepsini birleştir
	local footer = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Color3.fromRGB(150, 70, 235),
	}, panel)
	UIStyle.soften(footer, { radius = 14, strength = 0.25 })
	local fuseAll = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(260, 44),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 200, 40),
	}, footer)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, fuseAll)
	UIStyle.soften(fuseAll, { radius = 10, strength = 0.28 })
	local fuseAllText = makeText(fuseAll, {
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		Text = "FUSE ALL",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	local function invoke(action, id)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			showToast(ok, message or "")
			if ok and okJuice then
				pcall(Juice.celebrate, Color3.fromRGB(190, 120, 255), 70) -- birleştirme başarılı: mor parıltı
			end
			if ok and okSfx then
				pcall(Sfx.play, "Rare") -- parlak 'pırıl' sesi (Epic ve üstü pet sesi)
			end
		end)
	end

	local function fusable(pet, count)
		return pet.tier < fusion.MaxTier and count >= fusion.Cost
	end

	local function render()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local counts = toCounts(player:GetAttribute("OwnedPets"))
		local list = {}
		for _, pet in Catalog.AllPets do
			if counts[pet.id] then
				table.insert(list, pet)
			end
		end
		-- Birleştirilebilenler önce, sonra güçlüden zayıfa
		table.sort(list, function(a, b)
			local fa, fb = fusable(a, counts[a.id]), fusable(b, counts[b.id])
			if fa ~= fb then
				return fa
			end
			return a.mult > b.mult
		end)

		local anyFusable = false
		for order, pet in list do
			local count = counts[pet.id]
			local canFuse = fusable(pet, count)
			anyFusable = anyFusable or canFuse
			local card = create("Frame", {
				LayoutOrder = order,
				BackgroundColor3 = Catalog.rarityOf(pet).color,
			}, grid)
			create("UIStroke", { Thickness = 3, Color = if canFuse then Color3.fromRGB(255, 255, 255) else Color3.new(0, 0, 0) }, card)
			UIStyle.soften(card, { radius = 10, strength = 0.3 })

			makeText(card, {
				Position = UDim2.fromScale(0.05, 0.02),
				Size = UDim2.fromScale(0.9, 0.12),
				Text = `+{math.floor(pet.mult * 100 + 0.5)}%`,
				TextColor3 = Color3.new(1, 1, 1),
			}, 2)
			-- Pet ikonu boyuyla büyür (kartta taşmasın diye sınırlı)
			local iconSize = math.floor(math.min(46 + 14 * pet.scale, 80))
			UIStyle.safePetIcon(card, pet, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.14),
				Size = UDim2.fromOffset(iconSize, iconSize),
			})
			makeText(card, {
				Position = UDim2.fromScale(0.04, 0.55),
				Size = UDim2.fromScale(0.92, 0.12),
				Text = pet.name,
				TextColor3 = Color3.new(1, 1, 1),
			}, 2)
			makeText(card, {
				Position = UDim2.fromScale(0.04, 0.67),
				Size = UDim2.fromScale(0.92, 0.1),
				Text = `You have x{count}`,
				TextColor3 = Color3.fromRGB(235, 240, 255),
			}, 1.5)

			local button = create("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -6),
				Size = UDim2.new(0.86, 0, 0, 30),
				Text = "",
				BackgroundColor3 = if canFuse then Color3.fromRGB(60, 200, 40) else Color3.fromRGB(95, 100, 120),
				Active = canFuse,
				AutoButtonColor = canFuse,
			}, card)
			create("UIStroke", { Thickness = 2.5, Color = Color3.new(0, 0, 0) }, button)
			UIStyle.soften(button, { radius = 8, strength = 0.28 })
			makeText(button, {
				Position = UDim2.fromScale(0.05, 0.1),
				Size = UDim2.fromScale(0.9, 0.8),
				Text = if pet.tier >= fusion.MaxTier
					then "MAX SIZE"
					elseif canFuse then `FUSE {fusion.Cost} > 1`
					else `Need {fusion.Cost}`,
				TextColor3 = Color3.new(1, 1, 1),
			}, 2)
			if canFuse then
				button.MouseButton1Click:Connect(function()
					invoke("FusePet", pet.id)
				end)
			end
		end

		emptyText.Visible = #list == 0
		fuseAll.BackgroundColor3 = if anyFusable then Color3.fromRGB(60, 200, 40) else Color3.fromRGB(95, 100, 120)
		fuseAllText.Text = if anyFusable then "FUSE ALL" else "Nothing to fuse yet"
		fuseAll.Active = anyFusable
	end

	fuseAll.MouseButton1Click:Connect(function()
		invoke("FuseAllPets", "")
	end)

	player:GetAttributeChangedSignal("OwnedPets"):Connect(function()
		if PanelManager.isOpen(panel) then
			render()
		end
	end)

	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			render()
		end
	end
end

return FusionPanel
