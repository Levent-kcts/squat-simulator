-- Pets menüsü: pet envanteri, takma/çıkarma, Equip Best, Unequip All ve silme modu (çöp kutusu).
-- Takma/çıkarma/silme sunucuda yapılır; bu panel sadece gösterir ve istek yollar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local PetsPanel = {}

local FONT = Enum.Font.FredokaOne

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

-- Virgüllü listeyi { id = adet } sözlüğüne çevirir
local function toCounts(csv)
	local counts = {}
	for id in string.gmatch(csv or "", "[^,]+") do
		counts[id] = (counts[id] or 0) + 1
	end
	return counts
end

-- Kart rengi: çarpan büyüdükçe daha nadir renk
local function cardColor(mult)
	if mult < 0.2 then
		return Color3.fromRGB(70, 200, 70)
	elseif mult < 0.6 then
		return Color3.fromRGB(40, 190, 230)
	elseif mult < 1.2 then
		return Color3.fromRGB(170, 60, 230)
	elseif mult < 3 then
		return Color3.fromRGB(250, 170, 30)
	end
	return Color3.fromRGB(240, 50, 130)
end

-- showToast(ok, mesaj): kısa bildirim. Dönüş: paneli açıp kapatan fonksiyon.
function PetsPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local deleteMode = false
	local marked = {} -- silinmek üzere işaretlenen kartlar: ["petId#kopya"] = true

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(660, 460),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.18, shine = false })

	-- Başlık: Pets | Equip Best | çarpan | X
	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(30, 190, 230),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	makeText(header, {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(110, 40),
		Text = "Pets",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, 3)

	local function headerButton(positionX, width, color, text)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(positionX, 8),
			Size = UDim2.fromOffset(width, 40),
			Text = "",
			BackgroundColor3 = color,
		}, header)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.28 })
		makeText(button, {
			Position = UDim2.fromScale(0.05, 0.1),
			Size = UDim2.fromScale(0.9, 0.8),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		return button
	end
	local equipBest = headerButton(150, 150, Color3.fromRGB(60, 200, 40), "Equip Best")
	local multiplierText = makeText(header, {
		Position = UDim2.fromOffset(320, 8),
		Size = UDim2.fromOffset(240, 40),
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 40, 130),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	local subTitle = makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 62),
		Size = UDim2.fromOffset(400, 24),
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	-- Pet kartları
	local grid = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 92),
		Size = UDim2.new(1, -20, 1, -92 - 70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(118, 134),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, grid)

	-- Alt çubuk: envanter sayısı, takılı sayısı, Unequip All, çöp kutusu
	local footer = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Color3.fromRGB(30, 190, 230),
	}, panel)
	UIStyle.soften(footer, { radius = 14, strength = 0.25 })

	local function counterBox(positionX, icon)
		local box = create("Frame", {
			Position = UDim2.fromOffset(positionX, 9),
			Size = UDim2.fromOffset(150, 44),
			BackgroundColor3 = Color3.fromRGB(235, 245, 255),
		}, footer)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, box)
		UIStyle.soften(box, { radius = 10, strength = 0.12 })
		makeText(box, { Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(32, 36), Text = icon }, 0)
		return makeText(box, {
			Position = UDim2.fromOffset(46, 5),
			Size = UDim2.new(1, -54, 1, -10),
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
	end
	local inventoryText = counterBox(12, "🎒")
	local equippedText = counterBox(176, "🐾")

	local unequipAll = create("TextButton", {
		Position = UDim2.fromOffset(350, 9),
		Size = UDim2.fromOffset(170, 44),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(255, 180, 30),
	}, footer)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, unequipAll)
	UIStyle.soften(unequipAll, { radius = 10, strength = 0.28 })
	makeText(unequipAll, {
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		Text = "Unequip All",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	local trash = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 9),
		Size = UDim2.fromOffset(60, 44),
		Text = "🗑",
		Font = FONT,
		TextSize = 28,
		BackgroundColor3 = Color3.fromRGB(235, 75, 85),
	}, footer)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, trash)
	UIStyle.soften(trash, { radius = 10, strength = 0.28 })

	local function invoke(action, id, quiet)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			-- Takma/çıkarma başarılıysa sessiz kal (arayüz zaten güncellenir), hata ve silmede mesaj göster
			if not ok or not quiet then
				showToast(ok, message or "")
			end
		end)
	end

	local function render()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		local owned = toCounts(player:GetAttribute("OwnedPets"))
		local equipped = toCounts(player:GetAttribute("EquippedPets"))
		local ownedTotal, equippedTotal = 0, 0
		for _, count in owned do
			ownedTotal += count
		end
		for _, count in equipped do
			equippedTotal += count
		end

		multiplierText.Text = `x{string.format("%.2f", player:GetAttribute("PetMultiplier") or 1)} Multiplier`
		subTitle.Text = if deleteMode
			then "DELETE MODE: mark pets with X, then press the trash button"
			else `{equippedTotal}/{Config.MaxEquippedPets} Equipped`
		subTitle.TextColor3 = if deleteMode then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
		inventoryText.Text = `{ownedTotal}/{Config.MaxOwnedPets}`
		equippedText.Text = `{equippedTotal}/{Config.MaxEquippedPets}`
		-- Çöp kutusu: normalde kırmızı, silme modunda turuncu, işaretli pet varsa yeşil (basınca siler)
		local markedCount = 0
		for _ in marked do
			markedCount += 1
		end
		trash.BackgroundColor3 = if not deleteMode
			then Color3.fromRGB(235, 75, 85)
			elseif markedCount > 0 then Color3.fromRGB(60, 200, 60)
			else Color3.fromRGB(255, 160, 40)

		-- En güçlüden başlayarak sırala
		local pets = {}
		for _, pet in Config.Pets do
			if owned[pet.id] then
				table.insert(pets, pet)
			end
		end
		table.sort(pets, function(a, b)
			return a.mult > b.mult
		end)

		-- Her kopya ayrı bir kart (yığılmaz). Bir türün ilk "takılı sayısı" kadar kopyası takılı gösterilir.
		local order = 0
		for _, pet in pets do
			for copy = 1, owned[pet.id] do
				order += 1
				local isEquipped = copy <= (equipped[pet.id] or 0)
				local card = create("TextButton", {
					LayoutOrder = order,
					Text = "",
					AutoButtonColor = true,
					BackgroundColor3 = cardColor(pet.mult),
				}, grid)
				create("UIStroke", {
					Thickness = 3,
					Color = if isEquipped then Color3.fromRGB(255, 255, 255) else Color3.new(0, 0, 0),
				}, card)
				UIStyle.soften(card, { radius = 10, strength = 0.3 })

				makeText(card, {
					Position = UDim2.fromScale(0.05, 0.03),
					Size = UDim2.fromScale(0.9, 0.18),
					Text = `+{math.floor(pet.mult * 100 + 0.5)}%`,
					TextColor3 = Color3.new(1, 1, 1),
				}, 2)
				UIStyle.safePetIcon(card, pet, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.22),
					Size = UDim2.fromOffset(62, 62),
				})
				makeText(card, {
					Position = UDim2.fromScale(0.04, 0.72),
					Size = UDim2.fromScale(0.92, 0.2),
					Text = pet.name,
					TextColor3 = Color3.new(1, 1, 1),
				}, 2)

				-- Takılı kopyada yeşil "E" rozeti
				if isEquipped then
					local badge = create("Frame", {
						Position = UDim2.fromOffset(2, 2),
						Size = UDim2.fromOffset(26, 26),
						BackgroundColor3 = Color3.fromRGB(60, 210, 70),
						ZIndex = 5,
					}, card)
					create("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
					create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, badge)
					makeText(badge, {
						Position = UDim2.fromScale(0.1, 0.1),
						Size = UDim2.fromScale(0.8, 0.8),
						Text = "E",
						TextColor3 = Color3.new(1, 1, 1),
						ZIndex = 6,
					}, 2)
				end

				-- Silme için işaretliyse kart kararır ve üstüne kırmızı çarpı çıkar
				local key = `{pet.id}#{copy}`
				if deleteMode and marked[key] then
					local shade = create("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = 0.45,
						ZIndex = 7,
					}, card)
					UIStyle.round(shade, 10)
					for _, angle in { 45, -45 } do
						local bar = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(14, 100),
							Rotation = angle,
							BackgroundColor3 = Color3.fromRGB(235, 45, 65),
							ZIndex = 8,
						}, shade)
						create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, bar)
					end
				end

				card.MouseButton1Click:Connect(function()
					if deleteMode then
						marked[key] = if marked[key] then nil else true
						render()
					elseif isEquipped then
						invoke("UnequipPet", pet.id, true)
					elseif equippedTotal < Config.MaxEquippedPets then
						invoke("EquipPet", pet.id, true)
					else
						showToast(false, `You can equip only {Config.MaxEquippedPets} pets. Unequip one first.`)
					end
				end)
			end
		end
	end

	equipBest.MouseButton1Click:Connect(function()
		invoke("EquipBestPets", "", true)
	end)
	unequipAll.MouseButton1Click:Connect(function()
		invoke("UnequipAllPets", "", true)
	end)
	-- Çöp kutusu: 1. basış silme modunu açar, kartlara tıklayıp işaretlenir, 2. basış işaretlileri siler
	trash.MouseButton1Click:Connect(function()
		if not deleteMode then
			deleteMode = true
			render()
			return
		end

		local toDelete = {}
		for key in marked do
			table.insert(toDelete, (string.match(key, "^(.-)#")))
		end
		deleteMode = false
		table.clear(marked)
		render()
		if #toDelete == 0 then
			return
		end
		task.spawn(function()
			local deleted = 0
			for _, petId in toDelete do
				local ok = shopFunction:InvokeServer("DeletePet", petId)
				if ok then
					deleted += 1
				end
			end
			showToast(true, `Deleted {deleted} pet{if deleted == 1 then "" else "s"}`)
		end)
	end)
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
		deleteMode = false
		table.clear(marked)
	end)

	local function onChange()
		if panel.Visible then
			render()
		end
	end
	for _, name in { "OwnedPets", "EquippedPets", "PetMultiplier" } do
		player:GetAttributeChangedSignal(name):Connect(onChange)
	end

	return function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			render()
		else
			deleteMode = false
			table.clear(marked)
		end
	end
end

return PetsPanel
