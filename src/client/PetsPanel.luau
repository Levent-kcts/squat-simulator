-- Pets menüsü (referans oyundaki Pets ekranına benzer): yarı saydam siyah pencere (arkada dünya görünür); solda seçili petin ayrıntı kutusu
-- (büyük resim, ad, boy ve nadirlik, çarpan, boy basamakları, Equip, Delete ve MERGE), sağda Pet Team satırı (takılı petler), Equip Best / Unequip All ve pet kartları.
-- Aynı petten Config.PetFusion.Cost tane varsa Merge düğmesi onları bir üst boya birleştirir (Small > Normal > Big > Boss); düğme 'Normal (2/3)' gibi ilerleme gösterir.
-- Takma/çıkarma/silme/birleştirme SUNUCUDA yapılır; bu panel sadece gösterir ve istek yollar. Aynı pet tek kartta yığılır ('x3' rozeti).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
-- Kutlama efekti ve ses (isteğe bağlı): yüklenemezse birleştirme yine çalışır
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local PetsPanel = {}

local FONT = Enum.Font.FredokaOne
local WIDTH, HEIGHT = 790, 470
local DETAIL_WIDTH = 240
local TEAM_SLOT = 112 -- Pet Team yuvalarının kenarı: oradaki (kullanılan) petlerin resmi alttaki kartlardan BÜYÜK olmalı (sahibi istedi)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GREEN = Color3.fromRGB(60, 200, 40)
local ORANGE = Color3.fromRGB(255, 160, 40)
local PURPLE = Color3.fromRGB(150, 80, 240)
local DIM_PURPLE = Color3.fromRGB(78, 56, 120)
local RED = Color3.fromRGB(235, 75, 85)
local GREY = Color3.fromRGB(95, 100, 120)
local BOSS_GOLD = Color3.fromRGB(255, 215, 90)
local BOSS_PINK = Color3.fromRGB(255, 90, 170)

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
	create("UIStroke", { Thickness = strokeThickness, Color = BLACK }, label)
	return label
end

-- Yumuşatılmış düğme + içinde ortalanmış yazı. Dönüş: düğme, yazı
local function makeButton(parent, props, text, color)
	props.Text = ""
	props.BackgroundColor3 = color
	local button = create("TextButton", props, parent)
	create("UIStroke", { Thickness = 3, Color = BLACK }, button)
	UIStyle.soften(button, { radius = 10, strength = 0.28 })
	local label = makeText(button, {
		Position = UDim2.fromScale(0.05, 0.1),
		Size = UDim2.fromScale(0.9, 0.8),
		Text = text,
		TextColor3 = WHITE,
	}, 2)
	return button, label
end

local function clearChildren(parent)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Virgüllü listeyi { id = adet } sözlüğüne çevirir
local function toCounts(csv)
	local counts = {}
	for id in string.gmatch(csv or "", "[^,]+") do
		counts[id] = (counts[id] or 0) + 1
	end
	return counts
end

-- Virgüllü listeyi sırayla { id, id, ... } yapar (sadece bilinen petler)
local function toList(csv)
	local list = {}
	for id in string.gmatch(csv or "", "[^,]+") do
		if Catalog.PetById[id] then
			table.insert(list, id)
		end
	end
	return list
end

-- Çöp kutusu simgesi (sahibinin verdiği gri çöp kutusu görseli gibi): Config.Icons.Trash doluysa yüklenen görsel, boşsa aynı renk ve biçimde Frame'lerden çizilir
-- (assets/icons/trash.png yüklenince ID Config.Icons.Trash'e yazılır). pixels = kare simgenin kenarı.
local function addTrashIcon(parent, pixels)
	local holder = create("Frame", {
		Name = "TrashIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(pixels, pixels),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, parent)
	local imageId = Config.Icons.Trash
	if imageId and imageId ~= "" then
		create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = imageId,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 4,
		}, holder)
		return holder
	end

	local light, mid, dark = Color3.fromRGB(211, 221, 227), Color3.fromRGB(170, 192, 200), Color3.fromRGB(124, 151, 166)
	-- Soldan sağa iki tonlu yuvarlak parça (görseldeki sol açık / sağ koyu ayrımı); gradyan renkle çarpıldığı için zemin beyazdır
	local function piece(x, y, w, h, left, right, radius, z)
		local frame = create("Frame", {
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			BackgroundColor3 = if right then WHITE else left,
			BorderSizePixel = 0,
			ZIndex = z,
		}, holder)
		create("UICorner", { CornerRadius = UDim.new(radius, 0) }, frame)
		if right then
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, left),
					ColorSequenceKeypoint.new(0.46, left),
					ColorSequenceKeypoint.new(0.461, right),
					ColorSequenceKeypoint.new(1, right),
				}),
			}, frame)
		end
		return frame
	end

	-- Kulp (halka), gövde, kapak altı şeridi, kapak ve üç dikey yuva
	local ring = create("Frame", {
		Position = UDim2.fromScale(0.32, 0.04),
		Size = UDim2.fromScale(0.36, 0.32),
		BackgroundTransparency = 1,
		ZIndex = 1,
	}, holder)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
	create("UIStroke", { Thickness = math.max(2, math.floor(pixels * 0.075)), Color = mid }, ring)
	piece(0.17, 0.42, 0.66, 0.54, light, mid, 0.14, 2)
	piece(0.13, 0.34, 0.74, 0.12, mid, dark, 0.3, 3)
	piece(0.08, 0.2, 0.84, 0.17, light, mid, 0.45, 4)
	piece(0.27, 0.54, 0.07, 0.34, mid, nil, 0.5, 5)
	piece(0.465, 0.54, 0.07, 0.34, dark, nil, 0.5, 5)
	piece(0.66, 0.54, 0.07, 0.34, dark, nil, 0.5, 5)
	return holder
end

local function percent(pet)
	return math.floor(pet.mult * 100 + 0.5)
end

-- showToast(ok, mesaj): kısa bildirim. Dönüş: paneli açıp kapatan fonksiyon.
-- openShop: Shop (Robux) penceresini açan işlev; çanta simgesinin + işareti onu çağırır (ek pet yeri satın alma)
function PetsPanel.init(screenGui, showToast, openShop)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local fusion = Config.PetFusion

	local selectedId = nil -- ayrıntı kutusunda gösterilen pet türü (id)
	local selectedCopy = 1 -- o türün hangi kartı (kopyası) seçili: kartlar YIĞILMAZ, her pet ayrı kartta (sahibi 'stacklenmesin' dedi)
	local deleteMode = false
	local marked = {} -- silme modunda işaretlenen kartlar: ["id#kopya sırası"] = true (her pet kendi kartıdır)
	local pendingDelete = nil -- Delete düğmesine bir kez basılan pet (ikinci basış siler)
	local lastTapKey, lastTapTime = nil, 0 -- ÇİFT TIK ile tak/çıkar (playtest isteği): son tıklanan kart ve zamanı (render kartları yeniden kurduğu için dışarıda tutulur)
	local hinted = false -- 'Merge edebilirsin' ipucu bu oturumda gösterildi mi
	local tweens = {} -- her çizimde yeniden kurulan, tekrarlayan animasyonlar (sonraki çizimde iptal edilir)
	local render -- aşağıda tanımlanır (kartlar ve ayrıntı kutusu düğmeleri yeniden çizim ister)

	-- Yarı saydam siyah ana pencere: arkada dünya görünür
	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundColor3 = Color3.fromRGB(6, 8, 16),
		BackgroundTransparency = 0.4,
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	UIStyle.round(panel, 18)
	create("UIStroke", { Thickness = 3, Color = WHITE, Transparency = 0.75 }, panel)

	-- Üst şerit: başlık, çarpan, envanter sayısı, More Space, X
	UIStyle.headerIcon(panel, Config.Icons.Pets, "🐾", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(44, 44) })
	makeText(panel, {
		Position = UDim2.fromOffset(62, 6),
		Size = UDim2.fromOffset(110, 40),
		Text = "Pets",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = WHITE,
	}, 3)
	local multiplierText = makeText(panel, {
		Position = UDim2.fromOffset(180, 8),
		Size = UDim2.fromOffset(WIDTH - 180 - 180, 36),
		TextColor3 = Color3.fromRGB(150, 255, 150),
	}, 2.5)

	-- Çanta sayacı (kapatma düğmesinin hemen solunda): çanta simgesi, sayı ve çantanın sağ altında beyaz + (Robux'la ek pet yeri, Shop'u açar)
	local countBox = create("Frame", {
		Position = UDim2.fromOffset(WIDTH - 164, 8),
		Size = UDim2.fromOffset(104, 36),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.4,
	}, panel)
	UIStyle.round(countBox, 10)
	create("UIStroke", { Thickness = 2, Color = WHITE, Transparency = 0.7 }, countBox)
	UIStyle.headerIcon(countBox, Config.Icons.PetSpace, "🎒", { Position = UDim2.fromOffset(3, 2), Size = UDim2.fromOffset(32, 32) }) -- Shop'taki Pet Space görseliyle aynı
	local countText = makeText(countBox, {
		Position = UDim2.fromOffset(38, 3),
		Size = UDim2.new(1, -42, 1, -6),
		TextColor3 = WHITE,
	}, 2)
	local plusButton = create("TextButton", {
		Name = "BuyPetSpace",
		Position = UDim2.fromOffset(20, 15),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "+",
		Font = FONT,
		TextSize = 26,
		TextColor3 = WHITE,
		ZIndex = 5,
	}, countBox)
	create("UIStroke", { Thickness = 2.5, Color = BLACK }, plusButton)
	local close = create("TextButton", {
		Position = UDim2.fromOffset(WIDTH - 52, 6),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = WHITE,
		BackgroundColor3 = Color3.fromRGB(235, 40, 90),
	}, panel)
	create("UIStroke", { Thickness = 3, Color = BLACK }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	-- Sol: seçili petin ayrıntı kutusu
	local detail = create("Frame", {
		Position = UDim2.fromOffset(12, 58),
		Size = UDim2.fromOffset(DETAIL_WIDTH, HEIGHT - 70),
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.45,
	}, panel)
	UIStyle.round(detail, 14)
	create("UIStroke", { Thickness = 2, Color = WHITE, Transparency = 0.75 }, detail)

	-- Sağ: Pet Team satırı, Equip Best / Unequip All, kartlar, alt satır
	local rightX = DETAIL_WIDTH + 24
	local rightWidth = WIDTH - rightX - 12
	local teamTitle = makeText(panel, {
		Position = UDim2.fromOffset(rightX, 58),
		Size = UDim2.fromOffset(300, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = WHITE,
	}, 2)
	local teamRow = create("Frame", {
		Position = UDim2.fromOffset(rightX, 86),
		Size = UDim2.fromOffset(3 * TEAM_SLOT + 2 * 10, TEAM_SLOT),
		BackgroundTransparency = 1,
	}, panel)
	-- Sağ üç düğme (Equip Best yerinde, Unequip All biraz yukarı, altında Merge All; çöp kutusunun yanındaki eski Merge All sahibinin isteğiyle KALDIRILDI, geri ekleme): hepsi Pet Team satırının yüksekliğine sığar, kart ızgarasına binmez
	local sideX = rightX + 3 * TEAM_SLOT + 30
	local sideWidth = rightWidth - (3 * TEAM_SLOT + 30)
	local SIDE_HEIGHT, SIDE_GAP = 34, 5
	local equipBest = makeButton(panel, {
		Position = UDim2.fromOffset(sideX, 86),
		Size = UDim2.fromOffset(sideWidth, SIDE_HEIGHT),
	}, "Equip Best", GREEN)
	local unequipAll = makeButton(panel, {
		Position = UDim2.fromOffset(sideX, 86 + SIDE_HEIGHT + SIDE_GAP),
		Size = UDim2.fromOffset(sideWidth, SIDE_HEIGHT),
	}, "Unequip All", ORANGE)
	local mergeAll, mergeAllText = makeButton(panel, {
		Position = UDim2.fromOffset(sideX, 86 + 2 * (SIDE_HEIGHT + SIDE_GAP)),
		Size = UDim2.fromOffset(sideWidth, SIDE_HEIGHT),
	}, "Merge All", PURPLE)

	local grid = create("ScrollingFrame", {
		Position = UDim2.fromOffset(rightX, 86 + TEAM_SLOT + 8),
		Size = UDim2.fromOffset(rightWidth, 412 - (86 + TEAM_SLOT + 8)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(92, 96),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 4) }, grid)

	local emptyText = makeText(panel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(rightX + rightWidth / 2, 290),
		Size = UDim2.fromOffset(400, 40),
		Text = "No pets yet. Hatch eggs in the lobby!",
		TextColor3 = Color3.fromRGB(200, 205, 225),
		Visible = false,
	}, 2)

	local trash = create("TextButton", {
		Position = UDim2.fromOffset(rightX, HEIGHT - 52),
		Size = UDim2.fromOffset(58, 40),
		Name = "TrashButton",
		Text = "",
		BackgroundColor3 = RED,
	}, panel)
	create("UIStroke", { Thickness = 3, Color = BLACK }, trash)
	UIStyle.soften(trash, { radius = 10, strength = 0.28 })
	addTrashIcon(trash, 30)
	local bottomHint = makeText(panel, {
		Position = UDim2.fromOffset(rightX + 70, HEIGHT - 50),
		Size = UDim2.fromOffset(rightWidth - 70, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 120, 120),
		TextWrapped = true,
		Text = "",
	}, 2)

	-- Sunucuya istek: onSuccess başarılıysa çalışır; quiet = takma/çıkarma başarılıysa mesaj gösterme (arayüz zaten güncellenir)
	local function invoke(action, id, quiet, onSuccess)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			if not ok or not quiet then
				showToast(ok, message or "")
			end
			if ok and onSuccess then
				onSuccess()
			end
		end)
	end

	local function celebrate(pet)
		local boss = Catalog.isBoss(pet)
		if okJuice then
			pcall(Juice.celebrate, if boss then BOSS_GOLD else Color3.fromRGB(190, 120, 255), if boss then 140 else 70)
		end
		if okSfx then
			pcall(Sfx.play, "Rare") -- parlak 'pırıl' sesi
		end
	end

	-- Boss parıltısı: birkaç yıldız yanıp söner
	local function addSparkles(parent, zIndex)
		local spots = { { 0.08, 0.1 }, { 0.8, 0.06 }, { 0.84, 0.66 }, { 0.04, 0.62 } }
		for index, spot in spots do
			local star = create("TextLabel", {
				Position = UDim2.fromScale(spot[1], spot[2]),
				Size = UDim2.fromScale(0.2, 0.2),
				BackgroundTransparency = 1,
				Text = "✨",
				TextScaled = true,
				ZIndex = zIndex,
			}, parent)
			local tween = TweenService:Create(star, TweenInfo.new(0.7 + index * 0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.8 })
			tween:Play()
			table.insert(tweens, tween)
		end
	end

	-- Çerçeve rengi iki renk arasında gidip gelir (Boss kartı, birleştirilebilir düğme)
	local function pulseStroke(stroke, colorA, colorB, seconds)
		stroke.Color = colorA
		local tween = TweenService:Create(stroke, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = colorB })
		tween:Play()
		table.insert(tweens, tween)
	end

	-- ---------- Ayrıntı kutusu ----------
	local function buildDetail(pet, ownedCount, equippedCount, equippedTotal)
		local rarity = Catalog.rarityOf(pet)
		local boss = Catalog.isBoss(pet)

		local backdrop = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.fromOffset(130, 130),
			BackgroundColor3 = rarity.color,
			BackgroundTransparency = 0.45,
		}, detail)
		UIStyle.round(backdrop, 18)
		local backdropStroke = create("UIStroke", { Thickness = 3, Color = pet.tierColor }, backdrop)
		if boss then
			pulseStroke(backdropStroke, BOSS_GOLD, BOSS_PINK, 0.9)
		end
		local iconSize = math.min(math.floor(70 + 24 * pet.scale), 118)
		UIStyle.safePetIcon(backdrop, pet, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
		})
		if boss then
			addSparkles(backdrop, 5)
		end

		makeText(detail, {
			Position = UDim2.fromOffset(8, 142),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 16, 28),
			Text = pet.label,
			TextColor3 = WHITE,
		}, 3)

		-- Boy ve nadirlik rozetleri
		for index, chip in { { pet.tierName, pet.tierColor }, { rarity.name, rarity.color } } do
			local box = create("Frame", {
				Position = UDim2.fromOffset(14 + (index - 1) * 112, 172),
				Size = UDim2.fromOffset(100, 20),
				BackgroundColor3 = chip[2],
			}, detail)
			UIStyle.round(box, 8)
			create("UIStroke", { Thickness = 2, Color = BLACK }, box)
			makeText(box, {
				Position = UDim2.fromScale(0.05, 0.08),
				Size = UDim2.fromScale(0.9, 0.84),
				Text = chip[1],
				TextColor3 = WHITE,
			}, 1.5)
		end

		makeText(detail, {
			Position = UDim2.fromOffset(8, 196),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 16, 24),
			-- Sadece TAKILI petler kas kazancına yüzde verir (sunucu hesabı): takılı değilse 'takılınca' diye soluk yazılır
			Text = if equippedCount > 0 then `+{percent(pet)}% Leg Muscle` else `+{percent(pet)}% Leg Muscle when equipped`,
			TextColor3 = if equippedCount > 0 then Color3.fromRGB(130, 255, 140) else Color3.fromRGB(175, 182, 205),
		}, 2)
		makeText(detail, {
			Position = UDim2.fromOffset(8, 220),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 16, 18),
			Text = `Owned: {ownedCount}   Equipped: {equippedCount}`,
			TextColor3 = Color3.fromRGB(205, 210, 230),
		}, 1.5)

		-- Boy basamakları (referanstaki seviye çubuğu gibi): ulaşılan boylar renkli, mevcut boy beyaz çerçeveli
		local gap = 6
		local pipWidth = (DETAIL_WIDTH - 28 - gap * (fusion.MaxTier - 1)) / fusion.MaxTier
		for tier = 1, fusion.MaxTier do
			local reached = tier <= pet.tier
			local pip = create("Frame", {
				Position = UDim2.fromOffset(math.floor(14 + (tier - 1) * (pipWidth + gap)), 244),
				Size = UDim2.fromOffset(math.floor(pipWidth), 24),
				BackgroundColor3 = if reached then fusion.TierColors[tier] else Color3.fromRGB(40, 44, 58),
				BackgroundTransparency = if reached then 0.1 else 0.3,
			}, detail)
			UIStyle.round(pip, 8)
			create("UIStroke", { Thickness = if tier == pet.tier then 3 else 1.5, Color = if tier == pet.tier then WHITE else BLACK }, pip)
			makeText(pip, {
				Position = UDim2.fromScale(0.04, 0.1),
				Size = UDim2.fromScale(0.92, 0.8),
				Text = fusion.TierNames[tier],
				TextColor3 = if reached then WHITE else Color3.fromRGB(150, 156, 175),
			}, 1.5)
		end

		-- Equip / Unequip (ya da takım doluysa uyarı)
		local freeCopies = ownedCount - equippedCount
		local hasRoom = equippedTotal < Config.MaxEquippedPets
		local equipText, equipColor, equipAction
		if freeCopies > 0 and hasRoom then
			equipText, equipColor, equipAction = "Equip", GREEN, "EquipPet"
		elseif equippedCount > 0 then
			equipText, equipColor, equipAction = "Unequip", ORANGE, "UnequipPet"
		else
			equipText, equipColor = "Team Full", GREY, nil
		end
		local equipButton = makeButton(detail, {
			Position = UDim2.fromOffset(14, 276),
			Size = UDim2.fromOffset(146, 38),
		}, equipText, equipColor)
		equipButton.MouseButton1Click:Connect(function()
			if equipAction then
				invoke(equipAction, pet.id, true)
			else
				showToast(false, `Your team is full ({Config.MaxEquippedPets} pets). Unequip one first.`)
			end
		end)

		-- Delete: iki basış ister (yanlışlıkla silmesin)
		local confirming = pendingDelete == pet.id
		local deleteButton = makeButton(detail, {
			Name = "DeleteButton",
			Position = UDim2.fromOffset(168, 276),
			Size = UDim2.fromOffset(58, 38),
		}, if confirming then "Sure?" else "", RED)
		if not confirming then
			addTrashIcon(deleteButton, 28)
		end
		deleteButton.MouseButton1Click:Connect(function()
			if pendingDelete == pet.id then
				pendingDelete = nil
				invoke("DeletePet", pet.id, false)
				return
			end
			pendingDelete = pet.id
			render()
			task.delay(3, function()
				if pendingDelete == pet.id then
					pendingDelete = nil
					if PanelManager.isOpen(panel) then
						render()
					end
				end
			end)
		end)

		-- Merge: 'Normal (2/3)' gibi ilerlemeyle bir üst boya
		local nextPet = Catalog.nextTier(pet)
		local cost = fusion.Cost
		local canMerge = nextPet ~= nil and ownedCount >= cost
		local progress = if nextPet then math.min(ownedCount, cost) / cost else 1
		local mergeButton = create("TextButton", {
			Position = UDim2.fromOffset(14, 322),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 28, 50),
			Text = "",
			BackgroundColor3 = if not nextPet then Color3.fromRGB(120, 92, 30) elseif canMerge then PURPLE else DIM_PURPLE,
			AutoButtonColor = canMerge,
		}, detail)
		local mergeStroke = create("UIStroke", { Thickness = 3, Color = BLACK }, mergeButton)
		UIStyle.soften(mergeButton, { radius = 10, strength = 0.28 })
		if nextPet and progress > 0 then
			local fill = create("Frame", {
				Size = UDim2.fromScale(progress, 1),
				BackgroundColor3 = if canMerge then Color3.fromRGB(200, 130, 255) else Color3.fromRGB(125, 90, 190),
				BorderSizePixel = 0,
				ZIndex = 2,
			}, mergeButton)
			UIStyle.round(fill, 10)
		end
		makeText(mergeButton, {
			Position = UDim2.fromScale(0.05, 0.12),
			Size = UDim2.fromScale(0.9, 0.76),
			Text = if nextPet then `{nextPet.tierName} ({math.min(ownedCount, cost)}/{cost})` else "MAX SIZE",
			TextColor3 = if nextPet then WHITE else BOSS_GOLD,
			ZIndex = 3,
		}, 2.5)
		if canMerge then
			pulseStroke(mergeStroke, WHITE, BOSS_GOLD, 0.6)
		end
		mergeButton.MouseButton1Click:Connect(function()
			if not nextPet then
				showToast(false, `{pet.label} is already at the maximum size!`)
			elseif not canMerge then
				showToast(false, `You need {cost} {pet.label} to merge (you have {ownedCount}).`)
			else
				invoke("FusePet", pet.id, false, function()
					-- Seçim yeni (büyük) pete GİTMEZ: 12 tilkin hepsini arka arkaya birleştirebilsin diye aynı pet seçili kalır. Sadece o petten hiç kalmadıysa sonuç peti seçilir.
					if not toCounts(player:GetAttribute("OwnedPets"))[pet.id] then
						selectedId = nextPet.id
					end
					pendingDelete = nil
					celebrate(nextPet)
					if PanelManager.isOpen(panel) then
						render()
					end
				end)
			end
		end)
	end

	-- ---------- Pet kartı (YIĞILMAZ: sahip olunan her pet ayrı kart; sahibi 'bunlar stacklenmesin, daha önce de söylemiştim' dedi, 'xN' sayacına DÖNME) ----------
	-- copy: o türün kaçıncı kopyası; equipped: bu kopya takılı mı (takılı kopyalar önce gelir: takım sayısı kadar ilk kopya)
	local function buildCard(order, pet, copy, equipped)
		local rarity = Catalog.rarityOf(pet)
		local boss = Catalog.isBoss(pet)
		local key = `{pet.id}#{copy}`
		local isSelected = pet.id == selectedId and copy == selectedCopy and not deleteMode
		local card = create("TextButton", {
			LayoutOrder = order,
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = rarity.color,
			BackgroundTransparency = 0.3,
		}, grid)
		UIStyle.soften(card, { radius = 12, strength = 0.3 })
		local stroke = create("UIStroke", {
			Thickness = if isSelected then 4 else 2,
			Color = if isSelected then WHITE else BLACK,
			Transparency = if isSelected then 0 else 0.35,
		}, card)
		if boss then
			stroke.Thickness = 3
			pulseStroke(stroke, BOSS_GOLD, BOSS_PINK, 0.9)
		end

		-- Yüzde yazısı sadece takılı petlerde var: takılı olmayan pet çarpana yüzde vermez (sahibi karışıklığı düzelttirdi)
		if equipped then
			makeText(card, {
				Position = UDim2.fromOffset(5, 4),
				Size = UDim2.fromOffset(52, 15),
				Text = `+{percent(pet)}%`,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(150, 255, 150),
			}, 1.5)
		end
		-- Kart resimleri Pet Team satırındaki (kullanılan) petlerin yarısı kadardır; boy büyüdükçe biraz büyür (47 / 50 / 55)
		local iconSize = math.floor(38 + 9 * pet.scale)
		UIStyle.safePetIcon(card, pet, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, 42),
			Size = UDim2.fromOffset(iconSize, iconSize),
			lite = true, -- uzun liste: telefonda 3B yerine çizilmiş yüz (UIStyle.petModelIcon)
		})
		if boss then
			addSparkles(card, 4)
		end

		-- Boy ve ad şeridi
		local strip = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -4),
			Size = UDim2.new(1, -8, 0, 20),
			BackgroundColor3 = pet.tierColor,
			ZIndex = 3,
		}, card)
		UIStyle.round(strip, 8)
		create("UIStroke", { Thickness = 1.5, Color = BLACK }, strip)
		makeText(strip, {
			Position = UDim2.fromScale(0.04, 0.06),
			Size = UDim2.fromScale(0.92, 0.88),
			Text = pet.label,
			TextColor3 = WHITE,
			ZIndex = 4,
		}, 1.5)

		-- Takılı kopyada yeşil "E" rozeti
		if equipped then
			local badge = create("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -3, 0, 3),
				Size = UDim2.fromOffset(24, 24),
				BackgroundColor3 = Color3.fromRGB(60, 210, 70),
				ZIndex = 5,
			}, card)
			UIStyle.round(badge, 12)
			create("UIStroke", { Thickness = 3, Color = BLACK }, badge)
			makeText(badge, {
				Position = UDim2.fromScale(0.08, 0.1),
				Size = UDim2.fromScale(0.84, 0.8),
				Text = "E",
				TextColor3 = WHITE,
				ZIndex = 6,
			}, 2)
		end

		-- Silme modunda işaretliyse kart kararır ve üstüne kırmızı çarpı çıkar
		if deleteMode and marked[key] then
			local shade = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = BLACK,
				BackgroundTransparency = 0.45,
				ZIndex = 7,
			}, card)
			UIStyle.round(shade, 12)
			for _, angle in { 45, -45 } do
				local bar = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(14, 100),
					Rotation = angle,
					BackgroundColor3 = Color3.fromRGB(235, 45, 65),
					ZIndex = 8,
				}, shade)
				create("UIStroke", { Thickness = 3, Color = BLACK }, bar)
			end
		end

		card.MouseButton1Click:Connect(function()
			if deleteMode then
				-- Aç/kapa: işaretliyse tek tıkla iptal edilir (çarpı kalkar). Sunucu silerken o türün takılı olmayan kopyasını önce tutar gibi davranmaz: tek kopya silinir (DeletePet)
				if marked[key] then
					marked[key] = nil
				else
					marked[key] = true
				end
			else
				-- ÇİFT TIK (0.4 sn içinde aynı karta): takılıysa çıkarır, değilse takar (takım doluysa uyarır); tek tık eskisi gibi sadece seçer
				local now = os.clock()
				if lastTapKey == key and now - lastTapTime < 0.4 then
					lastTapKey = nil
					if equipped then
						invoke("UnequipPet", pet.id, true)
					elseif #toList(player:GetAttribute("EquippedPets")) >= Config.MaxEquippedPets then
						showToast(false, `Your team is full ({Config.MaxEquippedPets} pets). Unequip one first.`)
					else
						invoke("EquipPet", pet.id, true)
					end
				else
					lastTapKey, lastTapTime = key, now
				end
				selectedId = pet.id
				selectedCopy = copy
				pendingDelete = nil
			end
			render()
		end)
	end

	-- ---------- Pet Team satırı ----------
	local function buildTeam(equippedList)
		for slot = 1, Config.MaxEquippedPets do
			local id = equippedList[slot]
			local pet = id and Catalog.PetById[id]
			local box = create(if pet then "TextButton" else "Frame", {
				Position = UDim2.fromOffset((slot - 1) * (TEAM_SLOT + 10), 0),
				Size = UDim2.fromOffset(TEAM_SLOT, TEAM_SLOT),
				BackgroundColor3 = if pet then Catalog.rarityOf(pet).color else BLACK,
				BackgroundTransparency = if pet then 0.35 else 0.5,
			}, teamRow)
			UIStyle.round(box, 12)
			create("UIStroke", {
				Thickness = 2.5,
				Color = if pet then pet.tierColor else WHITE,
				Transparency = if pet then 0 else 0.75,
			}, box)
			if pet then
				box.Text = ""
				local iconSize = math.min(math.floor(76 + 16 * pet.scale), TEAM_SLOT - 8)
				UIStyle.safePetIcon(box, pet, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(iconSize, iconSize),
				})
				box.MouseButton1Click:Connect(function()
					invoke("UnequipPet", id, true)
				end)
			else
				makeText(box, {
					Position = UDim2.fromScale(0.2, 0.2),
					Size = UDim2.fromScale(0.6, 0.6),
					Text = "+",
					TextColor3 = Color3.fromRGB(200, 205, 225),
					TextTransparency = 0.6,
				}, 0)
			end
		end
	end

	function render()
		for _, tween in tweens do
			tween:Cancel()
		end
		table.clear(tweens)
		clearChildren(grid)
		clearChildren(detail)
		clearChildren(teamRow)

		local owned = toCounts(player:GetAttribute("OwnedPets"))
		local equipped = toCounts(player:GetAttribute("EquippedPets"))
		local equippedList = toList(player:GetAttribute("EquippedPets"))
		local ownedTotal = 0
		for _, count in owned do
			ownedTotal += count
		end
		local equippedTotal = #equippedList

		multiplierText.Text = `x{string.format("%.2f", player:GetAttribute("PetMultiplier") or 1)} Pet Multiplier`
		countText.Text = `{ownedTotal}/{player:GetAttribute("PetCapacity") or Config.MaxOwnedPets}`
		teamTitle.Text = `Pet Team ({equippedTotal}/{Config.MaxEquippedPets} Pets)`

		-- En güçlüden başlayarak sırala (aynı güçte büyük boy önce)
		local pets = {}
		for _, pet in Catalog.AllPets do -- ilk boylar ve birleşmiş (büyümüş) boylar
			if owned[pet.id] then
				table.insert(pets, pet)
			end
		end
		table.sort(pets, function(a, b)
			if a.mult ~= b.mult then
				return a.mult > b.mult
			end
			return a.id < b.id
		end)

		if not selectedId or not owned[selectedId] then
			selectedId = if pets[1] then pets[1].id else nil
			selectedCopy = 1
		end
		if selectedId and selectedCopy > owned[selectedId] then
			selectedCopy = owned[selectedId]
		end

		-- Her kopya ayrı kart: tür sırasıyla, önce takılı kopyalar
		local anyMergeable = false
		local order = 0
		for _, pet in pets do
			if Catalog.nextTier(pet) and owned[pet.id] >= fusion.Cost then
				anyMergeable = true
			end
			local equippedCopies = equipped[pet.id] or 0
			for copy = 1, owned[pet.id] do
				order += 1
				buildCard(order, pet, copy, copy <= equippedCopies)
			end
		end
		emptyText.Visible = #pets == 0

		buildTeam(equippedList)

		local selected = selectedId and Catalog.PetById[selectedId]
		if selected then
			buildDetail(selected, owned[selected.id], equipped[selected.id] or 0, equippedTotal)
		else
			makeText(detail, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.45),
				Size = UDim2.fromOffset(200, 60),
				Text = "Hatch an egg to get your first pet!",
				TextWrapped = true,
				TextColor3 = Color3.fromRGB(200, 205, 225),
			}, 2)
		end

		-- Alt satır: çöp kutusu normalde kırmızı, silme modunda turuncu, işaretli pet varsa yeşil (basınca siler)
		local markedCount = 0
		for _ in marked do
			markedCount += 1
		end
		trash.BackgroundColor3 = if not deleteMode then RED elseif markedCount > 0 then Color3.fromRGB(60, 200, 60) else ORANGE
		bottomHint.Text = if deleteMode
			then "DELETE MODE: tap pets to mark them, then press the trash again"
			else ""
		mergeAll.BackgroundColor3 = if anyMergeable then PURPLE else GREY
		mergeAllText.Text = if anyMergeable then "Merge All" else "Nothing to merge"
	end

	equipBest.MouseButton1Click:Connect(function()
		invoke("EquipBestPets", "", true)
	end)
	unequipAll.MouseButton1Click:Connect(function()
		invoke("UnequipAllPets", "", true)
	end)
	plusButton.MouseButton1Click:Connect(function()
		if openShop then
			openShop() -- Robux (Shop) penceresi: 'Pet Space' kartı
		else
			showToast(false, "More pet space is coming soon!")
		end
	end)
	local function mergeEverything()
		local owned = toCounts(player:GetAttribute("OwnedPets"))
		local any = false
		for id, count in owned do
			local pet = Catalog.PetById[id]
			if pet and Catalog.nextTier(pet) and count >= fusion.Cost then
				any = true
			end
		end
		if not any then
			showToast(false, `You need {fusion.Cost} of the same pet to merge.`)
			return
		end
		invoke("FuseAllPets", "", false, function()
			if okJuice then
				pcall(Juice.celebrate, Color3.fromRGB(190, 120, 255), 90)
			end
			if okSfx then
				pcall(Sfx.play, "Rare")
			end
		end)
	end
	mergeAll.MouseButton1Click:Connect(mergeEverything)
	-- Çöp kutusu: 1. basış silme modunu açar, kartlara tıklayınca işaretlenir (tekrar tıklayınca iptal), 2. basış işaretlileri siler
	trash.MouseButton1Click:Connect(function()
		if not deleteMode then
			deleteMode = true
			pendingDelete = nil
			render()
			return
		end

		-- İşaretli kartlar -> silinecek pet türleri (her işaret bir kopya; sahip olunandan fazlası sayılmaz)
		local toDelete = {}
		local perType = {}
		local ownedNow = toCounts(player:GetAttribute("OwnedPets"))
		for key in marked do
			local id = string.match(key, "^(.-)#")
			if id and (perType[id] or 0) < (ownedNow[id] or 0) then
				perType[id] = (perType[id] or 0) + 1
				table.insert(toDelete, id)
			end
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
		PanelManager.hide(panel)
	end)

	-- Pencere kapanınca (X, başka pencere ya da tekrar basış) silme modu ve onay beklemesi sıfırlanır
	panel:GetAttributeChangedSignal("PanelOpen"):Connect(function()
		if not panel:GetAttribute("PanelOpen") then
			deleteMode = false
			pendingDelete = nil
			table.clear(marked)
		end
	end)

	-- Envanter değişince: pencere açıksa yeniden çiz; kapalıysa ilk kez 3 aynı pet toplandığında (oturum başına bir kez) birleştirmeyi hatırlat
	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
		end
	end
	for _, name in { "EquippedPets", "PetMultiplier", "PetCapacity" } do
		player:GetAttributeChangedSignal(name):Connect(onChange)
	end
	player:GetAttributeChangedSignal("OwnedPets"):Connect(function()
		if PanelManager.isOpen(panel) then
			render()
		elseif not hinted then
			for id, count in toCounts(player:GetAttribute("OwnedPets")) do
				local pet = Catalog.PetById[id]
				if pet and Catalog.nextTier(pet) and count >= fusion.Cost then
					hinted = true
					showToast(true, `You have {fusion.Cost} matching pets! Open Pets and Merge them into a bigger one.`)
					break
				end
			end
		end
	end)

	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			render()
		end
	end
end

return PetsPanel
