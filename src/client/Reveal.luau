-- Yumurta açılış ekranı: ekran kararır, beyaz bir parıltı çakar, açılan petler nadirliğe göre renklenen kartlar olarak SIRAYLA dönerek/zıplayarak belirir, kısa süre durur ve solar.
-- Epic ve üstü bir pet çıkarsa üstte nadirlik başlığı ('EPIC!', 'LEGENDARY!', 'MYTHIC!!!'), konfeti ve hafif sarsıntı gelir (2026-10-13 playtest: 'egg ödülleri tatmin etmiyor, açılış sönük').
-- Sadece görsel: sonucu sunucu verir (PlayerStats.hatchEgg). Yeni açılan pet "NEW!" rozeti alır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)

local Reveal = {}

local okSfx, Sfx = pcall(require, script.Parent.Sfx)
local function sfx(name)
	if okSfx then
		pcall(Sfx.play, name)
	end
end

local CARD_WIDTH = 104
local CARD_HEIGHT = 132
local CARD_GAP = 10
local PER_ROW = 5
local STAGGER = 0.08 -- kartlar arası gecikme
local HOLD = 1.8 -- tüm kartlar göründükten sonra ekranda kalma süresi

local okJuice, Juice = pcall(require, script.Parent.Juice)
local RARITY_RANK = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
local RARITY_TITLE = { Epic = "EPIC!", Legendary = "LEGENDARY!", Mythic = "MYTHIC!!!" }

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
	UIStyle.soften(card, { radius = 12, strength = 0.3 })

	-- Üst: çarpan
	label(card, {
		Position = UDim2.fromScale(0.05, 0.03),
		Size = UDim2.fromScale(0.9, 0.17),
		Text = `+{math.floor(pet.mult * 100 + 0.5)}%`,
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	-- Pet simgesi: sevimli yüz (silinen petin rengi solgun)
	UIStyle.safePetIcon(card, pet, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromOffset(56, 56),
		dim = not kept,
	})

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

	-- Ses: açılış sesi; Epic ve üstü bir pet çıktıysa ek parıltı sesi. En iyi (kalan) peti bul: nadirlik başlığı ve konfeti ona göre
	sfx("Hatch")
	local best, bestRank = nil, 0
	for _, entry in results do
		local pet = Catalog.PetById[entry.id]
		if entry.kept and pet then
			local rarity = Catalog.rarityOf(pet)
			local rank = RARITY_RANK[rarity.name] or 1
			if rank > bestRank then
				best, bestRank = rarity, rank
			end
			if pet.mult >= 1.2 then
				task.delay(0.3, sfx, "Rare")
			end
		end
	end

	local count = #results
	local columns = math.min(count, PER_ROW)
	local rows = math.ceil(count / PER_ROW)

	-- Kök: tüm açılış parçalarını (karartma, parıltı, başlık, kartlar) tek yerde tutar; kaldırılınca hepsi gider
	local root = Instance.new("Frame")
	root.Name = "HatchReveal"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = screenGui
	current = root

	-- Odak: arka plan hafif kararır
	local dim = Instance.new("Frame")
	dim.Name = "HatchDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Parent = root
	TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 0.55 }):Play()

	-- Açılış parıltısı: ilk kartla birlikte beyaz bir çakma (nadir peti varsa nadirlik renginde)
	local flash = Instance.new("Frame")
	flash.Name = "HatchFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = if bestRank >= 3 and best then best.color:Lerp(Color3.new(1, 1, 1), 0.5) else Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0.35
	flash.BorderSizePixel = 0
	flash.Parent = root
	TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()

	local holder = Instance.new("Frame")
	holder.Name = "HatchCards"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.42)
	holder.Size = UDim2.fromOffset(columns * (CARD_WIDTH + CARD_GAP), rows * (CARD_HEIGHT + CARD_GAP))
	holder.BackgroundTransparency = 1
	holder.Parent = root

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

		-- Kart dönerek ve zıplayarak açılır (küçükten büyüğe, hafif eğikten düze)
		local scale = Instance.new("UIScale")
		scale.Scale = 0
		scale.Parent = card
		card.Rotation = if index % 2 == 0 then 14 else -14
		table.insert(cards, scale)
		task.delay((index - 1) * STAGGER, function()
			if root.Parent then
				TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
			end
		end)
	end

	-- Nadirlik başlığı (Epic ve üstü): kartların üstünde büyük renkli yazı + konfeti + hafif sarsıntı
	local lastCardTime = (count - 1) * STAGGER + 0.35
	local hold = HOLD
	local title = best and RARITY_TITLE[best.name]
	if title then
		hold = HOLD + 0.8
		local banner = label(root, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0.42, -(rows * (CARD_HEIGHT + CARD_GAP)) / 2 - 4), -- kartların hemen üstünde
			Size = UDim2.fromOffset(460, 62),
			Text = title,
			TextColor3 = best.color:Lerp(Color3.new(1, 1, 1), 0.25),
			ZIndex = 5,
		}, 4)
		local bannerScale = Instance.new("UIScale")
		bannerScale.Scale = 0
		bannerScale.Parent = banner
		task.delay(lastCardTime * 0.6, function()
			if root.Parent then
				TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				if okJuice then
					pcall(Juice.celebrate, best.color, 70)
					if bestRank >= 4 then
						pcall(Juice.shake, 0.25, 0.4)
					end
				end
			end
		end)
	end

	-- Bir süre durup küçülerek kaybolur
	local total = lastCardTime + hold
	task.delay(total, function()
		if current ~= root or not root.Parent then
			return
		end
		for _, scale in cards do
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		end
		TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function()
			if root.Parent then
				root:Destroy()
			end
			if current == root then
				current = nil
			end
		end)
	end)
end

return Reveal
