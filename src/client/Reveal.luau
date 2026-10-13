-- Yumurta açılış ekranı: ekran kararır, beyaz bir parıltı çakar, açılan petler nadirliğe göre renklenen kartlar olarak SIRAYLA dönerek/zıplayarak belirir, kısa süre durur ve solar.
-- Epic ve üstü bir pet çıkarsa üstte nadirlik başlığı ('EPIC!', 'LEGENDARY!', 'MYTHIC!!!'), konfeti ve hafif sarsıntı gelir (2026-10-13 playtest: 'egg ödülleri tatmin etmiyor, açılış sönük').
-- Sadece görsel: sonucu sunucu verir (PlayerStats.hatchEgg). Yeni açılan pet "NEW!" rozeti alır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
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

-- YUMURTA KIRILMA ANİMASYONU (2026-10-13, sahibi 'her yumurta satın aldığında [multi alımlar hariç] yumurta ekranın önüne UI olarak gelsin, sallansın, sonra şu anki animasyon oynasın' dedi; ilk sürümdeki kahverengi çubuk çatlaklar
-- 'çok kötü' bulundu, bu yüzden yeniden yapıldı: çubuk çatlak YOK): TEK yumurta açılışında yumurta ekranın ortasında belirir, giderek şiddetlenen sallanmayla büyür, arkasında ışık parlar, ortasında parlak bir çatlak çizgisi belirir,
-- sonra TAM O ÇİZGİDEN ikiye ayrılır (üst yarı sola-yukarı, alt yarı sağa-aşağı savrulur; döndürülmez çünkü Roblox döndürülmüş çerçevede ClipsDescendants'ı kırpmaz) ve beyaz bir ışık patlamasıyla mevcut açılış (hafif ışık + pet kartı) başlar. Her sallanışta tok bir 'tık', kırılırken kabuk kırılma sesi çalar.
-- Çoklu (x3/x10) ve otomatik açmada oynamaz (hız kesmesin).
local EGG_POP = 0.2 -- yumurtanın belirme süresi
local EGG_SHAKE = { { -9, 0.12 }, { 9, 0.12 }, { -13, 0.11 }, { 13, 0.11 }, { -17, 0.1 }, { 17, 0.1 }, { -21, 0.09 }, { 21, 0.09 }, { -25, 0.08 }, { 25, 0.08 }, { 0, 0.1 } } -- { açı (derece), süre (sn) }
local EGG_BREAK = 0.35 -- iki yarının savrulma süresi
local EGG_WOBBLE = (function()
	local total = 0
	for _, step in EGG_SHAKE do
		total += step[2]
	end
	return total
end)()
local EGG_BREAK_AT = EGG_POP + EGG_WOBBLE -- kırılma anı (açılıştan itibaren sn)
local EGG_INTRO = EGG_BREAK_AT + EGG_BREAK -- yumurta animasyonunun toplam süresi: pet açılışı bu kadar sonra başlar
local EGG_SIZE = 250 -- yumurta görselinin kenarı (px)
Reveal.EggIntroSeconds = EGG_INTRO
Reveal.EggBreakAt = EGG_BREAK_AT

local function round(parent, x, y, width, height, color, strokeColor)
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromOffset(x, y)
	dot.Size = UDim2.fromOffset(width, height)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = dot
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 4
		stroke.Color = strokeColor
		stroke.Parent = dot
	end
	dot.Parent = parent
	return dot
end

-- Çizilmiş yumurta (Blender modeli yoksa): geniş alt daire + küçük üst daire = yumurta gibi, yumurtanın rengi ve beneği (190x240'lık alana)
local function drawEgg(parent, egg)
	local outline = UIStyle.darken(egg.color, 0.45)
	round(parent, 95, 145, 190, 190, egg.color, outline)
	round(parent, 95, 100, 138, 138, egg.color, outline)
	round(parent, 95, 138, 178, 178, egg.color) -- iki dairenin birleşim çizgisini örter
	for _, spot in { { 60, 150, 34 }, { 128, 170, 28 }, { 100, 92, 24 }, { 70, 200, 22 }, { 135, 120, 20 } } do
		round(parent, spot[1], spot[2], spot[3], spot[3], egg.accent)
	end
	round(parent, 62, 92, 30, 52, Color3.new(1, 1, 1)).BackgroundTransparency = 0.55 -- parlama
end

-- Yumurta görseli (EGG_SIZE kare): Blender modeli varsa ViewportFrame, yoksa çizilmiş yumurta. Konumu çağıran verir.
local function makeEggVisual(parent, egg)
	local viewport = UIStyle.eggModelIcon(parent, egg, { Size = UDim2.fromOffset(EGG_SIZE, EGG_SIZE) })
	if viewport then
		return viewport
	end
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(EGG_SIZE, EGG_SIZE)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local inner = Instance.new("Frame")
	inner.Size = UDim2.fromOffset(190, 240)
	inner.Position = UDim2.fromOffset((EGG_SIZE - 190) / 2, (EGG_SIZE - 240) / 2)
	inner.BackgroundTransparency = 1
	inner.Parent = frame
	drawEgg(inner, egg)
	return frame
end

-- Yumurtanın üst ya da alt YARISI: kırpılan çerçevenin içinde tam yumurta görseli (alt yarıda görsel yukarı kaydırılır). Merkez çizgisinden iki yarı birleşince bütün yumurta olur.
local function makeHalf(holder, egg, top)
	local clip = Instance.new("Frame")
	clip.Name = if top then "HatchEggTop" else "HatchEggBottom"
	clip.AnchorPoint = Vector2.new(0.5, if top then 1 else 0)
	clip.Position = UDim2.fromScale(0.5, 0.5)
	clip.Size = UDim2.fromOffset(EGG_SIZE, EGG_SIZE / 2)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.ZIndex = 5
	clip.Parent = holder
	local visual = makeEggVisual(clip, egg)
	visual.Position = UDim2.fromOffset(0, if top then 0 else -EGG_SIZE / 2)
	return clip
end

-- Orta çizgideki parlak çatlak: kısa eğik parçalardan oluşan zikzak, iç ışığı beyaz-sarı, koyu ince kenarlı (kırılma çizgisiyle AYNI yerde)
local function buildCrack(holder)
	local crack = Instance.new("Frame")
	crack.Name = "HatchCrack"
	crack.AnchorPoint = Vector2.new(0.5, 0.5)
	crack.Position = UDim2.fromScale(0.5, 0.5)
	crack.Size = UDim2.fromOffset(EGG_SIZE - 40, 40)
	crack.BackgroundTransparency = 1
	crack.Visible = false
	crack.ZIndex = 8
	crack.Parent = holder
	local segments = 7
	local step = (EGG_SIZE - 60) / segments
	for index = 1, segments do
		local piece = Instance.new("Frame")
		piece.Name = "HatchCrackPiece"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromOffset(30 + (index - 0.5) * step, 20 + (if index % 2 == 0 then 7 else -7))
		piece.Size = UDim2.fromOffset(step * 0.95, 6)
		piece.Rotation = if index % 2 == 0 then -32 else 32
		piece.BackgroundColor3 = Color3.fromRGB(255, 252, 215)
		piece.BorderSizePixel = 0
		piece.ZIndex = 9
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(120, 70, 30)
		stroke.Parent = piece
		piece.Parent = crack
	end
	return crack
end

-- Yumurtayı ekranın önüne koyar, sallar, çatlatır ve ikiye ayırır. Dönüş: bittiği zamana kadar süre (sn); sonunda yumurta kendiliğinden kalkar
local function playEggIntro(root, egg, fullScreen)
	local holder = Instance.new("Frame")
	holder.Name = "HatchEgg"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.42)
	holder.Size = UDim2.fromOffset(EGG_SIZE, EGG_SIZE)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 5
	holder.Parent = root

	-- Arkada büyüyen ışık: kırılma yaklaştıkça yumurtanın içinden ışık sızıyor gibi
	local glow = round(holder, EGG_SIZE / 2, EGG_SIZE / 2, EGG_SIZE * 1.1, EGG_SIZE * 1.1, egg.accent:Lerp(Color3.new(1, 1, 1), 0.6))
	glow.Name = "HatchGlow"
	glow.BackgroundTransparency = 0.92
	glow.ZIndex = 4
	local glowScale = Instance.new("UIScale")
	glowScale.Scale = 0.6
	glowScale.Parent = glow

	-- Bütün yumurta (kırılana kadar)
	local whole = Instance.new("Frame")
	whole.Name = "HatchEggWhole"
	whole.AnchorPoint = Vector2.new(0.5, 0.5)
	whole.Position = UDim2.fromScale(0.5, 0.5)
	whole.Size = UDim2.fromScale(1, 1)
	whole.BackgroundTransparency = 1
	whole.ZIndex = 5
	whole.Parent = holder
	local visual = makeEggVisual(whole, egg)
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	visual.Position = UDim2.fromScale(0.5, 0.5)
	local crack = buildCrack(whole)

	-- Küçükten belirir, sallanırken büyür
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = holder
	TweenService:Create(scale, TweenInfo.new(EGG_POP, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(EGG_POP, function()
		if holder.Parent then
			TweenService:Create(scale, TweenInfo.new(EGG_WOBBLE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.25 }):Play()
			TweenService:Create(glow, TweenInfo.new(EGG_WOBBLE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 0.45 }):Play()
			TweenService:Create(glowScale, TweenInfo.new(EGG_WOBBLE, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1.5 }):Play()
		end
	end)
	-- Çatlak çizgisi: sallanmanın ~%60'ında belirir
	task.delay(EGG_POP + EGG_WOBBLE * 0.6, function()
		if holder.Parent then
			crack.Visible = true
			sfx("EggKnock")
		end
	end)
	-- Sallanma: her yön değişiminde tok bir 'tık'
	task.spawn(function()
		task.wait(EGG_POP)
		for index, step in EGG_SHAKE do
			if not holder.Parent then
				return
			end
			TweenService:Create(whole, TweenInfo.new(step[2], Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = step[1] }):Play()
			if index > 1 and index % 2 == 0 then
				sfx("EggKnock")
			end
			task.wait(step[2])
		end
	end)

	-- KIRILMA: bütün yumurta kalkar, iki yarı çatlak çizgisinden ayrılıp savrulur, beyaz ışık patlar
	task.delay(EGG_BREAK_AT, function()
		if not holder.Parent then
			return
		end
		sfx("EggBreak")
		whole:Destroy()
		local top = makeHalf(holder, egg, true)
		local bottom = makeHalf(holder, egg, false)
		local flyInfo = TweenInfo.new(EGG_BREAK, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(top, flyInfo, { Position = UDim2.new(0.5, -70, 0.5, -90) }):Play()
		TweenService:Create(bottom, flyInfo, { Position = UDim2.new(0.5, 70, 0.5, 90) }):Play()
		-- Kırılma ışığı: ışık halkası büyüyüp sönerken kısa bir beyaz patlama
		TweenService:Create(glowScale, flyInfo, { Scale = 2.4 }):Play()
		TweenService:Create(glow, flyInfo, { BackgroundTransparency = 1 }):Play()
		local burst = Instance.new("Frame")
		burst.Name = "HatchBurst"
		burst.Size = UDim2.fromScale(1, 1)
		burst.BackgroundColor3 = Color3.new(1, 1, 1)
		burst.BackgroundTransparency = 0.15
		burst.BorderSizePixel = 0
		burst.ZIndex = 6
		burst.Parent = fullScreen or root -- ışık patlaması ölçeksiz tam ekran kökte
		TweenService:Create(burst, TweenInfo.new(EGG_BREAK + 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		task.delay(EGG_BREAK + 0.2, function()
			burst:Destroy()
		end)
	end)
	task.delay(EGG_INTRO, function()
		if holder.Parent then
			holder:Destroy() -- yarılar uçtu: yerini pet kartları alır
		end
	end)
	return EGG_INTRO
end

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
		Text = Format.petBonus(pet.mult),
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

-- KARARTMA TÜM EKRANI KAPLASIN (2026-10-13, sahibi 'üstü kararmıyor, onu da karart' dedi): ana arayüz çerçevesi Roblox'un üst çubuğu payının ALTINDA başlar ve sağ üst daireler ayrı bir ScreenGui'dedir;
-- bu yüzden açılış kendi tam ekran ScreenGui'sinde kurulur (IgnoreGuiInset = true, DisplayOrder diğer arayüzlerin üstünde). Kartlar/yumurta ana arayüzle aynı boyutta kalsın diye ölçek (RootScale) kopyalanır.
-- PlayerGui yoksa (testler) eski davranış: ana arayüz çerçevesi. Dönüş: ebeveyn, ölçek
local function overlayParent(screenGui)
	local player = Players.LocalPlayer
	local playerGui = player and (player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui"))
	if not playerGui then
		return screenGui, nil
	end
	local gui = playerGui:FindFirstChild("HatchRevealGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "HatchRevealGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 60 -- ana arayüz (0), sağ üst daireler (2) ve pencerelerin üstünde; yükleme ekranının (1000) altında
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = playerGui
	end
	local rootScale = screenGui:FindFirstChild("RootScale")
	local scale = if rootScale and type(rootScale.Scale) == "number" and rootScale.Scale > 0 then rootScale.Scale else 1
	return gui, scale
end

-- results: { { id, kept } ... } açılış sırasıyla; ownedBefore: açmadan önce sahip olunan pet id'leri { [id] = true }
-- egg: açılan yumurta (Config.Eggs girdisi) verilirse ve TEK pet açıldıysa önce yumurta kırılma animasyonu oynar; çoklu/otomatik açmada nil verilir (animasyon yok)
function Reveal.show(screenGui, results, ownedBefore, egg)
	if current then
		current:Destroy()
		current = nil
	end
	if type(results) ~= "table" or #results == 0 then
		return
	end

	-- Yumurta animasyonu süresi (0 = yok): açılış (ses, parıltı, kartlar, başlık) bu kadar sonra başlar
	local intro = 0
	-- Ses: açılış sesi; Epic ve üstü bir pet çıktıysa ek parıltı sesi. En iyi (kalan) peti bul: nadirlik başlığı ve konfeti ona göre
	local best, bestRank = nil, 0
	local rareSoundPending = false
	for _, entry in results do
		local pet = Catalog.PetById[entry.id]
		if entry.kept and pet then
			local rarity = Catalog.rarityOf(pet)
			local rank = RARITY_RANK[rarity.name] or 1
			if rank > bestRank then
				best, bestRank = rarity, rank
			end
			if rank >= 3 then -- Epic ve üstü
				rareSoundPending = true
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
	local parentGui, uiScale = overlayParent(screenGui)
	root.Parent = parentGui
	current = root

	-- İçerik (yumurta, kartlar, başlık): tam ekran kökün içinde ana arayüzle aynı ölçekte; karartma ve parıltı ölçeksiz tam ekran kalır
	local content = root
	if uiScale then
		content = Instance.new("Frame")
		content.Name = "HatchContent"
		content.BackgroundTransparency = 1
		content.Size = UDim2.fromScale(1 / uiScale, 1 / uiScale)
		content.Parent = root
		local contentScale = Instance.new("UIScale")
		contentScale.Scale = uiScale
		contentScale.Parent = content
	end

	if egg and #results == 1 then
		intro = playEggIntro(content, egg, root)
	end
	-- Açılış sesi (yumurta kırılma anında) ve Epic+ parıltı sesi
	task.delay(intro, sfx, "Hatch")
	if rareSoundPending then
		task.delay(intro + 0.3, sfx, "Rare")
	end

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
	local function spawnFlash()
		local flash = Instance.new("Frame")
		flash.Name = "HatchFlash"
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = if bestRank >= 3 and best then best.color:Lerp(Color3.new(1, 1, 1), 0.5) else Color3.new(1, 1, 1)
		flash.BackgroundTransparency = 0.35 -- hafif ışık (yumurta kırılma patlaması zaten oynadı)
		flash.BorderSizePixel = 0
		flash.ZIndex = 6
		flash.Parent = root
		TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	end
	if intro > 0 then
		task.delay(intro, function()
			if root.Parent then
				spawnFlash()
			end
		end)
	else
		spawnFlash()
	end

	local holder = Instance.new("Frame")
	holder.Name = "HatchCards"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.42)
	holder.Size = UDim2.fromOffset(columns * (CARD_WIDTH + CARD_GAP), rows * (CARD_HEIGHT + CARD_GAP))
	holder.BackgroundTransparency = 1
	holder.Parent = content

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
		task.delay(intro + (index - 1) * STAGGER, function()
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
		local banner = label(content, {
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
		task.delay(intro + lastCardTime * 0.6, function()
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
	local total = intro + lastCardTime + hold
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
