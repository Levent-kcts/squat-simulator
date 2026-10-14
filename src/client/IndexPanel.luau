-- Pet Index (koleksiyon defteri): bütün pet türleri yumurta gruplarına göre kart olarak listelenir; sahip olunmuş (keşfedilmiş) türler renkli ve yüzlü,
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

local Theme = UIStyle.Theme
local COLORS = Theme.colors

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Bir Index ödülünü kısa yazıya çevirir ('+150 Wins', '60 min Luck Potion')
local function describeReward(reward)
	if reward.kind == "wins" then
		return `+{reward.amount} Wins`
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
	return `Index complete! +{Config.Index.CompletionPercent}% Leg Muscle forever!`
end

-- Sıradaki ödül eşiği (yoksa nil)
local function nextThreshold(count)
	for _, reward in Config.Index.Rewards do
		if count < reward.count then
			return reward.count
		end
	end
	return nil
end

-- Döner: pencereyi açıp kapatan fonksiyon
function IndexPanel.init(screenGui)
	local player = Players.LocalPlayer

	local panel = UIStyle.panel(screenGui, {
		name = "IndexPanel",
		width = 680,
		size = UDim2.fromOffset(680, 500),
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		accent = "magic",
	})
	panel.Visible = false

	local header = UIStyle.header(panel, {
		title = "Pet Index",
		subtitle = `Each new pet = +{Config.Index.PercentPerPet}% Leg Muscle forever`,
		icon = Config.Icons.Index,
		emoji = "📖",
		accent = "magic",
		chip = "+0% Leg Muscle",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	-- Büyük ilerleme çubuğu: 'Discovered 12/30'
	local progress = UIStyle.progressBar(panel, {
		name = "IndexProgress",
		accent = "magic",
		props = { Position = UDim2.fromOffset(16, 72), Size = UDim2.new(1, -32, 0, 24) },
	})
	local rewardLine = UIStyle.label(panel, {
		name = "NextReward",
		text = "",
		role = "caption",
		props = { Position = UDim2.fromOffset(16, 100), Size = UDim2.new(1, -32, 0, 18) },
	})

	local grid = create("ScrollingFrame", {
		Name = "IndexList",
		Position = UDim2.fromOffset(8, 124),
		Size = UDim2.new(1, -16, 1, -132),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, grid)

	-- Tek pet kartı: keşfedilmiş = renkli + ad + nadirlik şeridi; keşfedilmemiş = soluk siluet + '???'
	local function petCard(row, pet, known, order, egg)
		local rarity = Catalog.rarityOf(pet)
		local card = UIStyle.card(row, {
			name = `Pet_{pet.id}`,
			size = UDim2.new(0.2, -6.4, 1, 0),
			padding = false,
			accent = if known then "magic" else nil,
		})
		card.LayoutOrder = order
		if not known then
			card.BackgroundColor3 = COLORS.cardDeep
		end
		UIStyle.label(card, {
			text = if known then Format.petBonus(pet.mult) else "+???",
			role = "bold",
			size = 14,
			align = "center",
			color = if known then COLORS.primary.base else COLORS.textMute,
			props = { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 18) },
		})
		UIStyle.safePetIcon(card, pet, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 28),
			Size = UDim2.fromOffset(58, 58),
			dim = not known,
			lite = true, -- uzun liste: telefonda 3B yerine çizilmiş yüz (UIStyle.petModelIcon)
		})
		if not known then
			-- Keşfedilmemiş: yüzün üstüne soru işareti
			UIStyle.label(card, {
				text = "?",
				role = "title",
				align = "center",
				color = COLORS.textDim,
				props = { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(40, 28), ZIndex = 5 },
			})
		end
		UIStyle.label(card, {
			text = if known then pet.name else "???",
			role = "bold",
			size = 14,
			align = "center",
			color = if known then COLORS.text else COLORS.textMute,
			props = { Position = UDim2.new(0, 0, 0, 92), Size = UDim2.new(1, 0, 0, 18) },
		})
		if known then
			-- nadirlik şeridi
			local strip = create("Frame", {
				Name = "RarityStrip",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -8),
				Size = UDim2.new(0.8, 0, 0, 16),
				BackgroundColor3 = rarity.color,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
			}, card)
			UIStyle.round(strip, Theme.radius.chip)
			UIStyle.label(strip, {
				text = string.upper(rarity.name or ""),
				role = "caption",
				size = 10,
				align = "center",
				color = COLORS.text,
				props = { Size = UDim2.fromScale(1, 1), Font = Theme.fonts.title },
			})
		else
			UIStyle.label(card, {
				text = if egg then `Found in: {egg.name}` else "Not found yet",
				role = "caption",
				size = 10,
				align = "center",
				props = { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -8, 0, 28), TextWrapped = true, TextTruncate = Enum.TextTruncate.None },
			})
		end
	end

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
		local petById = {}
		for _, pet in Config.Pets do
			petById[pet.id] = pet
		end

		-- Yumurtaya göre gruplar (yumurtasız pet varsa 'Other' grubu)
		local groups = {}
		local placed = {}
		for _, egg in Config.Eggs do
			local list = {}
			for _, entry in egg.pets do
				local pet = petById[entry.id]
				if pet then
					table.insert(list, pet)
					placed[pet.id] = true
				end
			end
			table.insert(groups, { name = egg.name, egg = egg, pets = list })
		end
		local others = {}
		for _, pet in Config.Pets do
			if not placed[pet.id] then
				table.insert(others, pet)
			end
		end
		if #others > 0 then
			table.insert(groups, { name = "Other", pets = others })
		end

		local discovered, total = 0, 0
		for gi, group in groups do
			local holder = create("Frame", {
				Name = `Group_{gi}`,
				LayoutOrder = gi,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 166),
			}, grid)
			local groupFound = 0
			for _, pet in group.pets do
				if found[pet.id] then
					groupFound += 1
				end
			end
			UIStyle.label(holder, {
				name = "GroupTitle",
				text = `{string.upper(group.name)}   {groupFound}/{#group.pets}`,
				role = "bold",
				size = 14,
				color = COLORS.textDim,
				props = { Size = UDim2.new(1, 0, 0, 18) },
			})
			UIStyle.divider(holder, { props = { Position = UDim2.fromOffset(0, 21) } })
			local row = create("Frame", {
				Name = "Row",
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 138),
				BackgroundTransparency = 1,
			}, holder)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, row)
			for order, pet in group.pets do
				local known = found[pet.id] == true
				total += 1
				if known then
					discovered += 1
				end
				petCard(row, pet, known, order, group.egg)
			end
		end

		-- Tamamlanma bonusu kartı (altın)
		local done = total > 0 and discovered >= total
		local bonus = UIStyle.card(grid, {
			name = "CompletionCard",
			size = UDim2.new(1, 0, 0, 56),
			accent = "primary",
			selected = done,
		})
		bonus.LayoutOrder = #groups + 1
		UIStyle.label(bonus, {
			text = `Complete the Index: +{Config.Index.CompletionPercent}% Leg Muscle forever`,
			role = "bold",
			align = "center",
			color = COLORS.primary.base,
			props = { Size = UDim2.new(1, 0, 1, 0) },
		})

		local bonusPct = player:GetAttribute("IndexBonus") or 0
		progress.set(if total > 0 then discovered / total else 0, `Discovered {discovered}/{total}`)
		if header.chip then
			UIStyle.setChipText(header.chip, `+{bonusPct}% Leg Muscle`)
		end
		rewardLine.Text = nextRewardText(discovered)
		if header.subtitleLabel then
			local nextAt = nextThreshold(discovered)
			header.subtitleLabel.Text = if nextAt then `Discovered {discovered}/{total} - Next reward at {nextAt}` else `Discovered {discovered}/{total} - All rewards earned`
		end
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
