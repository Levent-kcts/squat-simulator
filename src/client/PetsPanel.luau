-- Pets menüsü (UIStyle "Soft Dark Candy" tasarım sistemiyle; vurgu rengi magic/mor): iki bölgeli pencere. Solda seçili petin ayrıntı kartı
-- (büyük resim, ad, boy ve nadirlik çipleri, çarpan, boy basamakları, Equip, Delete ve MERGE + ilerleme çubuğu), sağda Pet Team satırı
-- (takılı petler, kartlardan belirgin büyük), Equip Best / Unequip All / Merge All düğmeleri ve pet kartları.
-- Aynı petten Config.PetFusion.Cost tane varsa Merge düğmesi onları bir üst boya birleştirir (Small > Normal > Big > Boss); düğme 'Normal (2/3)' gibi ilerleme gösterir.
-- Takma/çıkarma/silme/birleştirme SUNUCUDA yapılır; bu panel sadece gösterir ve istek yollar. Kartlar YIĞILMAZ (her pet ayrı kart, 'xN' sayacı yok).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
-- Kutlama efekti ve ses (isteğe bağlı): yüklenemezse birleştirme yine çalışır
local okJuice, Juice = pcall(require, script.Parent.Juice)
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local PetsPanel = {}

local Theme = UIStyle.Theme
local C = Theme.colors
local FONTS = Theme.fonts
local WIDTH, HEIGHT = 700, 520
local DETAIL_WIDTH = 216
local TEAM_SLOT = 104 -- Pet Team yuvalarının kenarı: oradaki (kullanılan) petlerin resmi alttaki kartlardan BÜYÜK olmalı (sahibi istedi)
local TEAM_GAP = 8
local CARD_W, CARD_H = 80, 92
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
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

-- İnce beyaz-saydam çerçeve (Theme)
local function thinStroke(obj, thickness, color, transparency)
	return create("UIStroke", {
		Thickness = thickness or Theme.stroke.card,
		Color = color or Theme.stroke.color,
		Transparency = transparency or Theme.stroke.transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

-- Sade yazı (sabit punto, ortalı ya da soldan); renkli zemin üzerindeki sayılarda shadow = true
local function makeText(parent, props, shadow)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONTS.bold
	props.TextSize = props.TextSize or Theme.textSize.bold
	props.TextColor3 = props.TextColor3 or C.text
	props.TextTruncate = props.TextTruncate or Enum.TextTruncate.AtEnd
	local label = create("TextLabel", props, parent)
	if shadow then
		create("UIStroke", { Thickness = 1.2, Color = BLACK, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)
	end
	return label
end

-- Düğme yazısını sığdırır (dar düğmede 'Nothing to merge' gibi uzun yazılar kesilmesin)
local function fitLabel(button, maxSize)
	pcall(function()
		local body = button:FindFirstChild("Body")
		local label = body and body:FindFirstChild("Label")
		if label then
			label.TextScaled = true
			create("UITextSizeConstraint", { MaxTextSize = maxSize or 14, MinTextSize = 8 }, label)
		end
	end)
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

local function bonus(pet)
	return Format.petBonus(pet.mult)
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
	local invokeEquipBest, invokeUnequipAll, mergeEverything -- aşağıda tanımlanır
	local onTrash -- aşağıda tanımlanır (çöp kutusu düğmesi)

	-- Ana pencere (koyu lacivert, ince çerçeve, gölge; dar ekranda %92 sınırı)
	local panel = UIStyle.panel(screenGui, {
		name = "PetsPanel",
		width = WIDTH,
		height = HEIGHT,
		accent = "magic",
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
	})
	panel.Visible = false

	-- Başlık: simge, PETS, çarpan (alt başlık), çanta sayacı, X
	local header = UIStyle.header(panel, {
		title = "Pets",
		subtitle = " ",
		icon = Config.Icons.Pets,
		emoji = "🐾",
		accent = "magic",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})
	local multiplierText = header.subtitleLabel
	if multiplierText then
		multiplierText.TextColor3 = C.success.base
	end

	-- Çanta sayacı (kapatma düğmesinin hemen solunda): çanta simgesi, sayı ve çantanın sağ altında + (Robux'la ek pet yeri, Shop'u açar)
	local countBox = create("Frame", {
		Name = "CountBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -60, 0.5, 0),
		Size = UDim2.fromOffset(104, 34),
		BackgroundColor3 = C.cardDeep,
		BorderSizePixel = 0,
	}, header.bar)
	UIStyle.round(countBox, Theme.radius.chip + 4)
	thinStroke(countBox, 1)
	UIStyle.headerIcon(countBox, Config.Icons.PetSpace, "🎒", { Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(28, 28) }) -- Shop'taki Pet Space görseliyle aynı
	local countText = makeText(countBox, {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Font = FONTS.title,
		TextSize = 15,
	})
	local plusButton = create("TextButton", {
		Name = "BuyPetSpace",
		Position = UDim2.fromOffset(20, 15),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = C.success.base,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Text = "+",
		Font = FONTS.title,
		TextSize = 16,
		TextColor3 = WHITE,
		ZIndex = 5,
	}, countBox)
	UIStyle.round(plusButton, UDim.new(1, 0))
	thinStroke(plusButton, 1.5, C.panel, 0)

	-- Sol: seçili petin ayrıntı kartı
	local detailHeight = HEIGHT - 72 - 12
	local detail = UIStyle.card(panel, {
		name = "DetailCard",
		accent = "magic",
		padding = false,
		position = UDim2.fromOffset(12, 72),
		size = UDim2.fromOffset(DETAIL_WIDTH, detailHeight),
	})

	-- Sağ: Pet Team satırı, yan düğmeler, kart ızgarası, alt satır
	local rightX = DETAIL_WIDTH + 24
	local rightWidth = WIDTH - rightX - 12
	local teamTitle = makeText(panel, {
		Position = UDim2.fromOffset(rightX, 70),
		Size = UDim2.fromOffset(rightWidth, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		TextColor3 = C.textDim,
	})
	local teamTop = 96
	local teamRow = create("Frame", {
		Name = "TeamRow",
		Position = UDim2.fromOffset(rightX, teamTop),
		Size = UDim2.fromOffset(3 * TEAM_SLOT + 2 * TEAM_GAP, TEAM_SLOT),
		BackgroundTransparency = 1,
	}, panel)
	-- Yan üç düğme (Equip Best, Unequip All, Merge All; çöp kutusunun yanındaki eski Merge All sahibinin isteğiyle KALDIRILDI, geri ekleme): Pet Team satırının yüksekliğine sığar
	local sideX = rightX + 3 * TEAM_SLOT + 2 * TEAM_GAP + 10
	local sideWidth = rightWidth - (3 * TEAM_SLOT + 2 * TEAM_GAP + 10)
	local SIDE_HEIGHT = 34
	local equipBest = UIStyle.button(panel, {
		name = "EquipBest",
		text = "Equip Best",
		kind = "success",
		size = "sm",
		width = sideWidth,
		position = UDim2.fromOffset(sideX, teamTop),
		onClick = function()
			invokeEquipBest()
		end,
	})
	local unequipAll = UIStyle.button(panel, {
		name = "UnequipAll",
		text = "Unequip All",
		kind = "secondary",
		size = "sm",
		width = sideWidth,
		position = UDim2.fromOffset(sideX, teamTop + SIDE_HEIGHT + 3),
		onClick = function()
			invokeUnequipAll()
		end,
	})
	local mergeAll = UIStyle.button(panel, {
		name = "MergeAll",
		text = "Merge All",
		kind = "secondary",
		size = "sm",
		width = sideWidth,
		position = UDim2.fromOffset(sideX, teamTop + 2 * (SIDE_HEIGHT + 3)),
		onClick = function()
			mergeEverything()
		end,
	})
	fitLabel(equipBest, 14)
	fitLabel(unequipAll, 14)
	fitLabel(mergeAll, 14)

	local gridTop = teamTop + TEAM_SLOT + 12
	local grid = create("ScrollingFrame", {
		Name = "PetGrid",
		Position = UDim2.fromOffset(rightX, gridTop),
		Size = UDim2.fromOffset(rightWidth, HEIGHT - gridTop - 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = C.textMute,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD_W, CARD_H),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, grid)

	local emptyText = makeText(panel, {
		Name = "EmptyHint",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(rightX + rightWidth / 2, gridTop + 70),
		Size = UDim2.fromOffset(rightWidth - 40, 40),
		Text = "Hatch eggs at the back wall!",
		TextColor3 = C.textDim,
		Visible = false,
	})

	local trash = UIStyle.button(panel, {
		name = "TrashButton",
		text = "",
		kind = "danger",
		size = "sm",
		width = 56,
		position = UDim2.fromOffset(rightX, HEIGHT - 52),
		onClick = function()
			onTrash()
		end,
	})
	addTrashIcon(trash, 24)
	local bottomHint = makeText(panel, {
		Name = "BottomHint",
		Position = UDim2.fromOffset(rightX + 68, HEIGHT - 52),
		Size = UDim2.fromOffset(rightWidth - 68, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.danger.base,
		TextSize = 13,
		TextWrapped = true,
		Text = "",
	})

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

	function invokeEquipBest()
		invoke("EquipBestPets", "", true)
	end
	function invokeUnequipAll()
		invoke("UnequipAllPets", "", true)
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

	-- Boss parıltısı: birkaç yıldız yanıp söner (hafif modda yok)
	local function addSparkles(parent, zIndex)
		if UIStyle.isLow() then
			return
		end
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
			local tween = UIStyle.loopTween(TweenService:Create(star, TweenInfo.new(0.7 + index * 0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.8 }), star, nil)
			tween:Play()
			table.insert(tweens, tween)
		end
	end

	-- Çerçeve rengi iki renk arasında gidip gelir (Boss kartı)
	local function pulseStroke(stroke, colorA, colorB, seconds)
		stroke.Color = colorA
		if UIStyle.isLow() then
			return
		end
		local tween = UIStyle.loopTween(TweenService:Create(stroke, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = colorB }), stroke, { Color = colorA })
		tween:Play()
		table.insert(tweens, tween)
	end

	-- ---------- Ayrıntı kartı ----------
	local function buildDetail(pet, ownedCount, equippedCount, equippedTotal)
		local rarity = Catalog.rarityOf(pet)
		local boss = Catalog.isBoss(pet)
		local inner = DETAIL_WIDTH - 24

		-- Büyük pet gösterimi: çukur zemin, nadirlik renginde çerçeve
		local backdrop = create("Frame", {
			Name = "PetBackdrop",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 12),
			Size = UDim2.fromOffset(124, 124),
			BackgroundColor3 = C.cardDeep:Lerp(rarity.color, 0.25),
			BorderSizePixel = 0,
		}, detail)
		UIStyle.round(backdrop, Theme.radius.card)
		local backdropStroke = thinStroke(backdrop, 2, rarity.color, 0)
		if boss then
			pulseStroke(backdropStroke, BOSS_GOLD, BOSS_PINK, 0.9)
		end
		local iconSize = math.min(math.floor(70 + 24 * pet.scale), 112)
		UIStyle.safePetIcon(backdrop, pet, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
		})
		if boss then
			addSparkles(backdrop, 5)
		end

		makeText(detail, {
			Name = "PetName",
			Position = UDim2.fromOffset(12, 144),
			Size = UDim2.fromOffset(inner, 22),
			Text = pet.label,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 17,
			Font = FONTS.title,
		})

		-- Boy ve nadirlik çipleri (nadirlik rengi Config'ten)
		local chipRow = create("Frame", {
			Name = "ChipRow",
			Position = UDim2.fromOffset(12, 170),
			Size = UDim2.fromOffset(inner, 24),
			BackgroundTransparency = 1,
		}, detail)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, chipRow)
		UIStyle.chip(chipRow, { name = "TierChip", text = pet.tierName, accent = pet.tierColor })
		UIStyle.chip(chipRow, { name = "RarityChip", text = rarity.name, accent = rarity.color })

		-- Sadece TAKILI petler kas kazancına yüzde verir (sunucu hesabı): takılı değilse 'takılınca' diye soluk yazılır
		makeText(detail, {
			Name = "MultiplierLine",
			Position = UDim2.fromOffset(8, 200),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 16, 20),
			Text = if equippedCount > 0 then `{bonus(pet)} Pet Multiplier` else `{bonus(pet)} Pet Multiplier when equipped`,
			TextColor3 = if equippedCount > 0 then C.success.base else C.textDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 13,
		})
		makeText(detail, {
			Name = "OwnedLine",
			Position = UDim2.fromOffset(8, 221),
			Size = UDim2.fromOffset(DETAIL_WIDTH - 16, 16),
			Text = `Owned: {ownedCount}   Equipped: {equippedCount}`,
			TextColor3 = C.textMute,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 12,
			Font = FONTS.body,
		})

		-- Boy basamakları: ulaşılan boylar renkli, mevcut boy beyaz çerçeveli
		local gap = 5
		local pipWidth = (inner - gap * (fusion.MaxTier - 1)) / fusion.MaxTier
		for tier = 1, fusion.MaxTier do
			local reached = tier <= pet.tier
			local pip = create("Frame", {
				Name = `Pip_{tier}`,
				Position = UDim2.fromOffset(math.floor(12 + (tier - 1) * (pipWidth + gap)), 246),
				Size = UDim2.fromOffset(math.floor(pipWidth), 22),
				BackgroundColor3 = if reached then fusion.TierColors[tier] else C.cardDeep,
				BorderSizePixel = 0,
			}, detail)
			UIStyle.round(pip, Theme.radius.chip)
			if tier == pet.tier then
				thinStroke(pip, 1.5, WHITE, 0.1)
			end
			makeText(pip, {
				Size = UDim2.fromScale(1, 1),
				Text = fusion.TierNames[tier],
				TextColor3 = if reached then WHITE else C.textMute,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextSize = 11,
			}, reached)
		end

		-- Equip / Unequip (ya da takım doluysa uyarı)
		local freeCopies = ownedCount - equippedCount
		local hasRoom = equippedTotal < Config.MaxEquippedPets
		local equipText, equipKind, equipAction
		if freeCopies > 0 and hasRoom then
			equipText, equipKind, equipAction = "Equip", "success", "EquipPet"
		elseif equippedCount > 0 then
			equipText, equipKind, equipAction = "Unequip", "secondary", "UnequipPet"
		else
			equipText, equipKind = "Team Full", "secondary", nil
		end
		UIStyle.button(detail, {
			name = "EquipButton",
			text = equipText,
			kind = equipKind,
			size = "sm",
			width = inner - 52,
			position = UDim2.fromOffset(12, 282),
			onClick = function()
				if equipAction then
					invoke(equipAction, pet.id, true)
				else
					showToast(false, `Your team is full ({Config.MaxEquippedPets} pets). Unequip one first.`)
				end
			end,
		})

		-- Delete: iki basış ister (yanlışlıkla silmesin)
		local confirming = pendingDelete == pet.id
		local deleteButton = UIStyle.button(detail, {
			name = "DeleteButton",
			text = if confirming then "Sure?" else "",
			kind = "danger",
			size = "sm",
			width = 46,
			position = UDim2.fromOffset(12 + inner - 46, 282),
			onClick = function()
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
			end,
		})
		if confirming then
			fitLabel(deleteButton, 11)
		else
			addTrashIcon(deleteButton, 22)
		end

		-- Merge: 'Normal (2/3)' gibi ilerlemeyle bir üst boya; altında ilerleme çubuğu
		local nextPet = Catalog.nextTier(pet)
		local cost = fusion.Cost
		local canMerge = nextPet ~= nil and ownedCount >= cost
		local progress = if nextPet then math.min(ownedCount, cost) / cost else 1
		UIStyle.button(detail, {
			name = "MergeButton",
			text = if nextPet then `{nextPet.tierName} ({math.min(ownedCount, cost)}/{cost})` else "MAX SIZE",
			kind = if canMerge then "primary" else "secondary",
			size = "lg",
			width = inner,
			position = UDim2.fromOffset(12, 330),
			onClick = function()
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
			end,
		})
		UIStyle.progressBar(detail, {
			name = "MergeProgress",
			accent = if nextPet then "magic" else "primary",
			value = progress,
			props = { Position = UDim2.fromOffset(12, 392), Size = UDim2.fromOffset(inner, 10) },
		})
		makeText(detail, {
			Name = "MergeHint",
			Position = UDim2.fromOffset(12, 408),
			Size = UDim2.fromOffset(inner, 16),
			Text = if nextPet then `Merge {cost} of the same pet into a bigger one` else "Biggest size reached",
			TextColor3 = C.textMute,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 11,
			Font = FONTS.body,
		})
	end

	-- ---------- Pet kartı (YIĞILMAZ: sahip olunan her pet ayrı kart; sahibi 'bunlar stacklenmesin, daha önce de söylemiştim' dedi, 'xN' sayacına DÖNME) ----------
	-- copy: o türün kaçıncı kopyası; equipped: bu kopya takılı mı (takılı kopyalar önce gelir: takım sayısı kadar ilk kopya)
	local function buildCard(order, pet, copy, equipped)
		local rarity = Catalog.rarityOf(pet)
		local boss = Catalog.isBoss(pet)
		local key = `{pet.id}#{copy}`
		local isSelected = pet.id == selectedId and copy == selectedCopy and not deleteMode
		local isMarked = deleteMode and marked[key]
		local card = create("TextButton", {
			Name = "PetCard",
			LayoutOrder = order,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			BackgroundColor3 = (if isSelected then C.cardHover else C.card):Lerp(rarity.color, 0.12),
		}, grid)
		UIStyle.round(card, Theme.radius.card)
		-- Kart başına TEK çerçeve: seçili = beyaz, silme işareti = kırmızı, boss = altın/pembe nabız, diğerleri ince nadirlik rengi
		local stroke = create("UIStroke", {
			Thickness = if isSelected or isMarked then 2 else 1.2,
			Color = if isMarked then C.danger.base elseif isSelected then WHITE else rarity.color,
			Transparency = if isSelected or isMarked then 0 else 0.45,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, card)
		if boss then
			stroke.Thickness = 2
			stroke.Transparency = 0
			pulseStroke(stroke, BOSS_GOLD, BOSS_PINK, 0.9)
		end

		-- Yüzde yazısı sadece takılı petlerde var: takılı olmayan pet çarpana yüzde vermez (sahibi karışıklığı düzelttirdi)
		if equipped then
			makeText(card, {
				Position = UDim2.fromOffset(6, 4),
				Size = UDim2.fromOffset(46, 14),
				Text = bonus(pet),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = C.success.base,
				TextSize = 12,
				Font = FONTS.title,
			}, true)
		end
		-- Kart resimleri Pet Team satırındaki (kullanılan) petlerden belirgin küçüktür; boy büyüdükçe biraz büyür
		local iconSize = math.floor(34 + 8 * pet.scale)
		UIStyle.safePetIcon(card, pet, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, 38),
			Size = UDim2.fromOffset(iconSize, iconSize),
			lite = true, -- uzun liste: telefonda 3B yerine çizilmiş yüz (UIStyle.petModelIcon)
		})
		if boss then
			addSparkles(card, 4)
		end

		-- Ad (boy rengiyle) ve altında 3 px nadirlik şeridi
		local nameLabel = makeText(card, {
			Name = "PetLabel",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -8, 0, 16),
			Text = pet.label,
			TextColor3 = if pet.tier > 1 then pet.tierColor else C.text,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextScaled = true,
			ZIndex = 3,
		})
		create("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 7 }, nameLabel)
		local stripe = create("Frame", {
			Name = "RarityStripe",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.new(1, -20, 0, 3),
			BackgroundColor3 = rarity.color,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, card)
		UIStyle.round(stripe, UDim.new(1, 0))

		-- Takılı kopyada yeşil "E" rozeti
		if equipped then
			local badge = create("Frame", {
				Name = "EquippedBadge",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(20, 20),
				BackgroundColor3 = C.success.base,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, card)
			UIStyle.round(badge, UDim.new(1, 0))
			makeText(badge, {
				Size = UDim2.fromScale(1, 1),
				Text = "E",
				TextColor3 = WHITE,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextSize = 12,
				Font = FONTS.title,
				ZIndex = 6,
			}, true)
		end

		-- Silme modunda işaretliyse kart kararır ve üstüne kırmızı çarpı çıkar
		if isMarked then
			local shade = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = BLACK,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				ZIndex = 7,
			}, card)
			UIStyle.round(shade, Theme.radius.card)
			for _, angle in { 45, -45 } do
				local bar = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(10, 62),
					Rotation = angle,
					BackgroundColor3 = C.danger.base,
					BorderSizePixel = 0,
					ZIndex = 8,
				}, shade)
				UIStyle.round(bar, UDim.new(1, 0))
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
			local rarity = pet and Catalog.rarityOf(pet)
			local box = create(if pet then "TextButton" else "Frame", {
				Name = if pet then "TeamSlot" else "EmptySlot",
				Position = UDim2.fromOffset((slot - 1) * (TEAM_SLOT + TEAM_GAP), 0),
				Size = UDim2.fromOffset(TEAM_SLOT, TEAM_SLOT),
				BackgroundColor3 = if pet then C.card:Lerp(rarity.color, 0.2) else C.cardDeep,
				BorderSizePixel = 0,
			}, teamRow)
			UIStyle.round(box, Theme.radius.card)
			if pet then
				thinStroke(box, 2, rarity.color, 0.15)
				box.Text = ""
				box.AutoButtonColor = false
				local iconSize = math.min(math.floor(72 + 14 * pet.scale), TEAM_SLOT - 10)
				UIStyle.safePetIcon(box, pet, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(iconSize, iconSize),
				})
				box.MouseButton1Click:Connect(function()
					invoke("UnequipPet", id, true)
				end)
			else
				thinStroke(box, 1)
				makeText(box, {
					Size = UDim2.fromScale(1, 1),
					Text = "+",
					TextColor3 = C.textMute,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 26,
					Font = FONTS.title,
				})
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

		if multiplierText then
			multiplierText.Text = `x{Format.multiplier(player:GetAttribute("PetMultiplier") or 1)} Pet Multiplier`
		end
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
				Size = UDim2.fromOffset(180, 60),
				Text = "Hatch an egg to get your first pet!",
				TextWrapped = true,
				TextColor3 = C.textDim,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.None,
			})
		end

		-- Alt satır: çöp kutusu normalde kırmızı, silme modunda turuncu, işaretli pet varsa yeşil (basınca siler)
		local markedCount = 0
		for _ in marked do
			markedCount += 1
		end
		UIStyle.setButtonKind(trash, if not deleteMode then "danger" elseif markedCount > 0 then "success" else "warn")
		bottomHint.Text = if deleteMode
			then "DELETE MODE: tap pets to mark them, then press the trash again"
			else ""
		UIStyle.setButtonKind(mergeAll, if anyMergeable then "primary" else "secondary")
		UIStyle.setButtonText(mergeAll, if anyMergeable then "Merge All" else "Nothing to merge")
	end

	plusButton.MouseButton1Click:Connect(function()
		if openShop then
			openShop() -- Robux (Shop) penceresi: 'Pet Space' kartı
		else
			showToast(false, "More pet space is coming soon!")
		end
	end)
	function mergeEverything()
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
	-- Çöp kutusu: 1. basış silme modunu açar, kartlara tıklayınca işaretlenir (tekrar tıklayınca iptal), 2. basış işaretlileri siler
	function onTrash()
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
	end

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
