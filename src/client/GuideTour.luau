-- REHBER TURU (2026-10-13, sahibi 'yeni oyuncu ilk rebirth'e kadar oyun tarafından yönlendirilsin, arayüzleri tanıtsın' dedi; sonra 'çok sade kalıyor, hızlı bir tanıtım yapıp oklarla göstersin, iki görev birbirine bağlı olsun' dedi):
--   1) HIZLI OK TURU (Config.GuideIntro): ilk girişte tüm düğmeleri sırayla, büyük zıplayan ok + kısa konuşma balonuyla gezer (kendiliğinden ilerler, 'Next' hızlandırır, 'Skip' bitirir).
--   2) KARTLAR (Config.GuideTour): doğru anda tek tek küçük kart; hedef düğme büyük okla işaretlenir. Eğitim görevi (ilk ClickGoal tıklama) bitmeden ikinci bir kart açılmaz.
--   3) GÖREV BAĞI: bir NEW PLAYER görevi bitince ödül SESSİZCE verilmez (sahibi istedi): güncel hedef 'claim' olur (client/Objective), üst şerit 'Quest complete! Tap QUESTS and CLAIM...' der, ilk seferde bir kart anlatır ve Quests düğmesine ok çıkar;
--      oyuncu Quests penceresinden CLAIM eder, sonra sıradaki hedefin kartı/oku gelir (görevler sekmesi ile rehber aynı zincir).
-- Oklar ve balonlar ana arayüzün DEĞİL, ayrı bir üst katman ScreenGui'sindedir (kardeş düğmelerin altında kalmasın); hedefin ekran konumunu izler, hedef gizlenirse oku da gizlenir.
-- Her adım bir kez gösterilir (sunucuda kayıtlı 'GuideSeen'). 'Skip guide' ve Settings > Guide anahtarı tamamen kapatır (GuideOn = false).
-- Tamamen görseldir; hata verirse oyun etkilenmez (init.client safeInit).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PlayerSettings = require(script.Parent.PlayerSettings)
local Objective = require(script.Parent.Objective)

local GuideTour = {}

local FONT = Enum.Font.FredokaOne
local BODY_FONT = Enum.Font.GothamMedium
local GOLD = Color3.fromRGB(255, 214, 60)
local NAVY = Color3.fromRGB(34, 38, 60)
local GAP_SECONDS = 2.5 -- iki kart arası en az bekleme
local AUTO_DISMISS = 20 -- sn: kapatılmazsa görüldü sayılıp kaybolur
local CLAIM_SNOOZE = 20 -- sn: oyuncu Quests'e basınca 'ödülü al' oku bu kadar susar (pencerede ödülü alsın); hâlâ alınmadıysa geri gelir
local CHECK_INTERVAL = 0.5
local FOLLOW_INTERVAL = 0.1 -- ok, hedefin konumunu bu aralıkla izler
local OVERLAY_ORDER = 800 -- yükleme ekranının (1000) altında, diğer arayüzün üstünde
local ARROW_FILL = Color3.fromRGB(255, 206, 52)
local ARROW_OUTLINE = Color3.fromRGB(28, 24, 46)
local ARROW_ROTATION = { above = 0, below = 180, right = 90, left = -90 } -- ok aşağı bakacak çizilir, yöne göre döndürülür

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function label(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextScaled = props.TextScaled ~= false
	local textLabel = create("TextLabel", props, parent)
	if strokeThickness and strokeThickness > 0 then
		create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, textLabel)
	end
	return textLabel
end

-- Yumuşak, kalın dış çizgili ok (aşağı bakar; yöne göre döndürülür): gövde + elmas uç, önce koyu çizgi katmanı, üstüne altın dolgu katmanı (iç içe binen çizgiler görünmesin)
local function buildArrow(parent, size, scale)
	local arrow = create("Frame", { Name = "Arrow", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), ZIndex = 3 }, parent)
	local outline = math.max(2, math.floor(3 * scale))
	local shaftWidth, shaftHeight, headSide = size * 0.34, size * 0.6, size * 0.5
	for layer = 1, 2 do
		local grow = if layer == 1 then outline * 2 else 0
		local color = if layer == 1 then ARROW_OUTLINE else ARROW_FILL
		local shaft = create("Frame", {
			Name = if layer == 1 then "ShaftOutline" else "Shaft",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(size / 2, size * 0.04 - grow / 2),
			Size = UDim2.fromOffset(shaftWidth + grow, shaftHeight + grow),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 2 + layer,
		}, arrow)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, shaft)
		local head = create("Frame", {
			Name = if layer == 1 then "HeadOutline" else "Head",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(size / 2, size * 0.62),
			Size = UDim2.fromOffset(headSide + grow, headSide + grow),
			Rotation = 45,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 2 + layer,
		}, arrow)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, head)
	end
	return arrow
end

-- Adı verilen arayüz öğesini bulur (PlayerGui altında, iç içe olabilir); yoksa nil
local function findTarget(player, name)
	if not name then
		return nil
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end
	local found = playerGui:FindFirstChild(name, true)
	if found and found:IsA("GuiObject") then
		return found
	end
	return nil
end

-- Hedef ekranda görünüyor mu (kendisi ve atalarından biri gizli değil, ScreenGui kapalı değil)
local function isShown(target)
	local ok, shown = pcall(function()
		local object = target
		while object do
			if object:IsA("ScreenGui") then
				return object.Enabled ~= false
			end
			if object:IsA("GuiObject") and object.Visible == false then
				return false
			end
			object = object.Parent
		end
		return true
	end)
	return not ok or shown
end

-- Adımın koşulu sağlandı mı? when: start / quest:<görev id> (o görev GÜNCEL HEDEF: üst şerit, çizgi ve kart hep aynı hedefi söyler) / level:N / nearMax
-- 'start' dışındakiler eğitim tıklamaları (30) bitmeden çıkmaz. cardPending: güncel hedefin kartı henüz gösterilmediyse bilgi (tip) kartları ve diğerleri bekler (iki görev çakışmasın).
local function conditionMet(player, step, level, objective, cardPending)
	local when = step.when
	if when == "start" then
		return true
	end
	if (player:GetAttribute("TutorialClicks") or 0) < Config.Tutorial.ClickGoal then
		return false
	end
	local questId = string.match(when, "^quest:(.+)$")
	if questId then
		return objective ~= nil and objective.id == questId
	elseif cardPending then
		return false
	elseif when == "nearMax" then
		local maxLevel = player:GetAttribute("MaxLevel") or 0
		return maxLevel > 0 and level >= maxLevel - 2
	end
	local wanted = string.match(when, "^level:(%d+)$")
	return wanted ~= nil and level >= tonumber(wanted)
end

-- 'StarterState' = 'id,ilerleme,bitti,alındı;...' (sunucu PlayerStats.publishStarter)
local function readStarter(player)
	local list = {}
	for entry in string.gmatch(player:GetAttribute("StarterState") or "", "[^;]+") do
		local id, progress, done, claimed = string.match(entry, "^([^,]+),(%d+),(%d),(%d)$")
		if id then
			table.insert(list, { id = id, progress = tonumber(progress), done = done == "1", claimed = claimed == "1" })
		end
	end
	return list
end

-- screenGui: ana arayüz çerçevesi (kart buraya konur); showToast isteğe bağlı
function GuideTour.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local leaderstats = player:WaitForChild("leaderstats")
	local winValue = leaderstats:WaitForChild(Config.StatWins)
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)
	local timing = { gap = GAP_SECONDS, intro = Config.GuideIntroSeconds or 2.6, snoozeUntil = 0 }

	-- ---------- Kart (bir kez kurulur, adımlar arasında içeriği değişir) ----------
	local card = create("Frame", {
		Name = "GuideCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.27, 0),
		Size = UDim2.fromOffset(430, 170),
		BackgroundColor3 = NAVY,
		Active = true, -- karta tıklamak hareket başlatmasın
		Visible = false,
		ZIndex = 60,
	}, screenGui)
	create("UIStroke", { Thickness = 3, Color = GOLD }, card)
	UIStyle.soften(card, { radius = 16, strength = 0.2, shine = false })
	create("UISizeConstraint", { MaxSize = Vector2.new(430, 170), MinSize = Vector2.new(260, 170) }, card)

	local tagLabel = label(card, { -- 'GUIDE' / 'NEW QUEST' / 'TIP' etiketi
		Name = "Tag",
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(110, 18),
		Text = "GUIDE",
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, 1.5)
	local title = label(card, {
		Position = UDim2.fromOffset(14, 26),
		Size = UDim2.new(1, -28, 0, 32),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, 2.5)
	local body = label(card, {
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 0, 56),
		Text = "",
		Font = BODY_FONT,
		TextColor3 = Color3.fromRGB(232, 236, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		ZIndex = 61,
	}, 0)

	local gotIt = create("TextButton", {
		Name = "GotIt",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -10),
		Size = UDim2.fromOffset(120, 36),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		ZIndex = 62,
	}, card)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, gotIt)
	UIStyle.soften(gotIt, { radius = 10, strength = 0.28 })
	local gotItLabel = label(gotIt, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Got it!", TextColor3 = Color3.new(1, 1, 1), ZIndex = 63 }, 2)

	local skip = create("TextButton", {
		Name = "SkipGuide",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -14),
		Size = UDim2.fromOffset(110, 26),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(86, 90, 112),
		ZIndex = 62,
	}, card)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, skip)
	UIStyle.soften(skip, { radius = 8, strength = 0.2, shine = false })
	label(skip, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Skip guide", TextColor3 = Color3.fromRGB(225, 228, 245), ZIndex = 63 }, 1.5)

	-- ---------- Hızlı tur çubuğu: 'Quick tour 3/10  [Skip] [Next >]' + altında ilerleme çizgisi ----------
	local introBar = create("Frame", {
		Name = "IntroBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.27, 0),
		Size = UDim2.fromOffset(360, 56),
		BackgroundColor3 = NAVY,
		Active = true,
		Visible = false,
		ZIndex = 60,
	}, screenGui)
	create("UIStroke", { Thickness = 3, Color = GOLD }, introBar)
	UIStyle.soften(introBar, { radius = 18, strength = 0.22, shine = false })
	create("UISizeConstraint", { MaxSize = Vector2.new(360, 56), MinSize = Vector2.new(300, 56) }, introBar)
	local introCounter = label(introBar, {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.fromOffset(170, 30),
		Text = "",
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, 2)
	local introSkip = create("TextButton", {
		Name = "IntroSkip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -112, 0, 9),
		Size = UDim2.fromOffset(62, 28),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(86, 90, 112),
		ZIndex = 62,
	}, introBar)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, introSkip)
	UIStyle.soften(introSkip, { radius = 10, strength = 0.2, shine = false })
	label(introSkip, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Skip", TextColor3 = Color3.fromRGB(225, 228, 245), ZIndex = 63 }, 1.5)
	local introNext = create("TextButton", {
		Name = "IntroNext",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(96, 32),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		ZIndex = 62,
	}, introBar)
	create("UIStroke", { Thickness = 2.5, Color = Color3.new(0, 0, 0) }, introNext)
	UIStyle.soften(introNext, { radius = 12, strength = 0.28 })
	label(introNext, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Next ▶", TextColor3 = Color3.new(1, 1, 1), ZIndex = 63 }, 2)
	local introTrack = create("Frame", { Name = "IntroTrack", Position = UDim2.new(0, 14, 1, -13), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = Color3.fromRGB(18, 20, 36), BorderSizePixel = 0, ZIndex = 61 }, introBar)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, introTrack)
	local introFill = create("Frame", { Name = "IntroFill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 62 }, introTrack)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, introFill)

	-- ---------- Durum ----------
	local current = nil -- şu an gösterilen adım (kart, hızlı tur ya da görev oku)
	local shownThisSession = {} -- bu oturumda gösterilen (sunucu kaydı gelmeden tekrar göstermemek için)
	local lastDismiss = 0
	local token = 0 -- otomatik kapanma zamanlayıcıları için
	local activeCallout = nil -- hedefi işaretleyen ok + balon
	local intro = nil -- { step, stops = {{target, text}}, index, stopToken }
	local overlays = {} -- [ignoreInset] = ScreenGui

	local function seenSet()
		local set = {}
		for id in string.gmatch(player:GetAttribute("GuideSeen") or "", "[^,]+") do
			set[id] = true
		end
		return set
	end

	-- ---------- Ok + balon (callout) ----------
	-- Hedefin bulunduğu ScreenGui ile AYNI IgnoreGuiInset'e sahip bir üst katman: AbsolutePosition iki katmanda da aynı koordinat sisteminde olur
	local function getOverlay(ignoreInset)
		local existing = overlays[ignoreInset]
		if existing and existing.Parent then
			return existing
		end
		local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui")
		local gui = create("ScreenGui", {
			Name = if ignoreInset then "GuideOverlayCorner" else "GuideOverlay",
			ResetOnSpawn = false,
			IgnoreGuiInset = ignoreInset,
			DisplayOrder = OVERLAY_ORDER,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, playerGui or screenGui)
		overlays[ignoreInset] = gui
		return gui
	end

	local function viewportSize(overlay)
		local ok, width, height = pcall(function()
			local size = overlay.AbsoluteSize
			return size.X, size.Y
		end)
		if ok and type(width) == "number" and type(height) == "number" and width > 0 and height > 0 then
			return width, height
		end
		local okCamera, cw, ch = pcall(function()
			local size = workspace.CurrentCamera.ViewportSize
			return size.X, size.Y
		end)
		if okCamera and type(cw) == "number" and type(ch) == "number" and cw > 0 and ch > 0 then
			return cw, ch
		end
		return 1280, 720
	end

	local function pickDirection(cx, cy)
		if cx < 0.2 then
			return "right" -- sol kenardaki düğme: ok sağında, sola bakar
		elseif cy < 0.45 then
			return "below" -- üstteki düğme: ok altında, yukarı bakar
		elseif cx > 0.85 then
			return "left"
		end
		return "above" -- alttaki düğme: ok üstünde, aşağı bakar
	end

	local function clearCallout()
		local callout = activeCallout
		activeCallout = nil
		if not callout then
			return
		end
		callout.alive = false
		if callout.clickConnection then
			pcall(function()
				callout.clickConnection:Disconnect()
			end)
		end
		for _, tween in callout.tweens do
			pcall(function()
				tween:Cancel()
			end)
		end
		callout.container:Destroy()
	end

	-- Okun yönünü/konumunu uygular ve hedefe doğru zıplama animasyonunu yeniden başlatır
	local function applyDirection(callout, dir, align)
		callout.dir = dir
		callout.align = align
		for _, tween in callout.bounceTweens do
			pcall(function()
				tween:Cancel()
			end)
		end
		callout.bounceTweens = {}
		local s = callout.scale
		local gap = math.floor(6 * s)
		local half = callout.arrowSize / 2
		local span = gap + callout.arrowSize + 4
		local bob = math.floor(8 * s)
		local arrow, bubble = callout.arrow, callout.bubble
		arrow.Rotation = ARROW_ROTATION[dir]
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		local from, to
		if dir == "right" then
			bubble.AnchorPoint = Vector2.new(0, 0.5)
			from, to = UDim2.new(1, gap + half, 0.5, 0), UDim2.new(1, gap + half - bob, 0.5, 0)
			bubble.Position = UDim2.new(1, span, 0.5, 0)
		elseif dir == "left" then
			bubble.AnchorPoint = Vector2.new(1, 0.5)
			from, to = UDim2.new(0, -(gap + half), 0.5, 0), UDim2.new(0, -(gap + half) + bob, 0.5, 0)
			bubble.Position = UDim2.new(0, -span, 0.5, 0)
		elseif dir == "below" then
			bubble.AnchorPoint = Vector2.new(align, 0)
			from, to = UDim2.new(0.5, 0, 1, gap + half), UDim2.new(0.5, 0, 1, gap + half - bob)
			bubble.Position = UDim2.new(align, 0, 1, span)
		else
			bubble.AnchorPoint = Vector2.new(align, 1)
			from, to = UDim2.new(0.5, 0, 0, -(gap + half)), UDim2.new(0.5, 0, 0, -(gap + half) + bob)
			bubble.Position = UDim2.new(align, 0, 0, -span)
		end
		arrow.Position = from
		local ok, tween = pcall(function()
			return TweenService:Create(arrow, TweenInfo.new(0.42, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = to })
		end)
		if ok and tween then
			table.insert(callout.bounceTweens, tween)
			pcall(function()
				tween:Play()
			end)
		end
	end

	-- Hedefin konumunu izler; gizlenmişse oku da gizler
	local function place(callout)
		pcall(function()
			local target = callout.target
			local container = callout.container
			if target.Parent == nil or not isShown(target) then
				container.Visible = false
				return
			end
			local position, size = target.AbsolutePosition, target.AbsoluteSize
			if size.X <= 0 or size.Y <= 0 then
				container.Visible = false
				return
			end
			local viewWidth, viewHeight = viewportSize(callout.overlay)
			local pad = callout.pad
			-- KONUM ÖLÇÜMLE DÜZELTİLİR: AbsolutePosition'ın hangi başlangıç noktasına göre olduğu (üst çubuk payı, IgnoreGuiInset) ScreenGui'ye göre değişiyor;
			-- ilk denemede sağ üst dairelerin halkası ~58 px yukarı kaçıp ekran dışına taşmıştı. Bu yüzden kapsayıcının GERÇEK AbsolutePosition'ı okunur ve hedefinkine eşitlenene kadar kaydırılır
			-- (iki tarafta da aynı özellik okunduğu için hangi modelde olursa olsun doğru çıkar). Düzelme gerçekleşene kadar (ilk ölçüm) gizli kalır, yanlış yerde göz kırpmaz.
			local wantX, wantY = position.X - pad, position.Y - pad
			local setX, setY = wantX, wantY
			if callout.calibrating then
				local actual = container.AbsolutePosition
				if type(actual.X) == "number" and type(actual.Y) == "number" then
					setX = callout.lastX + (wantX - actual.X)
					setY = callout.lastY + (wantY - actual.Y)
				end
			end
			callout.lastX, callout.lastY = setX, setY
			container.Position = UDim2.fromOffset(setX, setY)
			container.Size = UDim2.fromOffset(size.X + pad * 2, size.Y + pad * 2)
			if callout.calibrating then
				container.Visible = true
			end
			callout.calibrating = true
			-- Halka: 'Disc' varsa yalnız daireyi (tam yuvarlak), yoksa tüm hedefi sarar (uzun dikey hedef hap, diğerleri yumuşak yuvarlak köşeli)
			local holder = callout.holder
			if callout.ringIsDisc then
				local discPosition, discSize = callout.ringTarget.AbsolutePosition, callout.ringTarget.AbsoluteSize
				local ringPad = math.max(2, math.floor(pad * 0.6))
				holder.Position = UDim2.fromOffset(discPosition.X - position.X + pad - ringPad, discPosition.Y - position.Y + pad - ringPad)
				holder.Size = UDim2.fromOffset(discSize.X + ringPad * 2, discSize.Y + ringPad * 2)
			else
				holder.Position = UDim2.fromOffset(0, 0)
				holder.Size = UDim2.fromScale(1, 1)
			end
			local radius = if callout.ringIsDisc or size.Y / size.X > 1.25 then 0.5 else 0.28
			for _, corner in callout.corners do
				corner.CornerRadius = UDim.new(radius, 0)
			end
			local cx = (position.X + size.X / 2) / viewWidth
			local cy = (position.Y + size.Y / 2) / viewHeight
			local dir = pickDirection(cx, cy)
			local align = if cx > 0.7 then 1 elseif cx < 0.3 then 0 else 0.5
			if dir ~= callout.dir or align ~= callout.align then
				applyDirection(callout, dir, align)
			end
		end)
	end

	-- Hedefi büyük bir okla ve konuşma balonuyla işaretler. onClick: hedef bir düğmeyse ona basılınca çağrılır.
	local function setCallout(target, text, subText, onClick)
		clearCallout()
		local ignoreInset = false
		pcall(function()
			local gui = target:FindFirstAncestorOfClass("ScreenGui")
			ignoreInset = gui ~= nil and gui.IgnoreGuiInset == true
		end)
		local overlay = getOverlay(ignoreInset)
		local _, viewHeight = viewportSize(overlay)
		local s = math.clamp(viewHeight / 620, 0.75, 1.3)
		local callout = {
			target = target,
			overlay = overlay,
			scale = s,
			pad = math.floor(5 * s),
			arrowSize = math.floor(48 * s),
			alive = true,
			tweens = {},
			bounceTweens = {},
		}
		local container = create("Frame", { Name = "GuideCallout", BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), Visible = false }, overlay)
		callout.container = container

		-- Halka: hafif altın dolgulu yumuşak çerçeve + dışa yayılıp sönen dalga (kaba kalın çerçeve değil).
		-- Halka SADECE vurgulanan şekli sarar: hedefin 'Disc' adlı çocuğu varsa (sağ üst daireler: daire + altındaki sayı tek düğme) halka yalnız daireyi sarar (sahibi 'halka çok büyük, sadece çemberin etrafı sarı yansın' dedi);
		-- ok ve balon yine tüm düğmenin dışında kalır (sayıyı kapatmasın).
		callout.corners = {}
		callout.ringTarget = target
		callout.ringIsDisc = false
		pcall(function()
			local disc = target:FindFirstChild("Disc")
			if disc and disc:IsA("GuiObject") then
				callout.ringTarget = disc
				callout.ringIsDisc = true
			end
		end)
		local holder = create("Frame", { Name = "RingHolder", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, container)
		callout.holder = holder
		local ring = create("Frame", { Name = "Ring", BackgroundColor3 = GOLD, BackgroundTransparency = 0.88, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, holder)
		table.insert(callout.corners, create("UICorner", { CornerRadius = UDim.new(0.28, 0) }, ring))
		create("UIStroke", { Thickness = 3, Color = GOLD }, ring)
		local ripple = create("Frame", {
			Name = "Ripple",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, holder)
		table.insert(callout.corners, create("UICorner", { CornerRadius = UDim.new(0.28, 0) }, ripple))
		local rippleStroke = create("UIStroke", { Thickness = 3, Color = GOLD, Transparency = 0 }, ripple)
		local okRipple, grow, fade = pcall(function()
			local info = TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, false)
			return TweenService:Create(ripple, info, { Size = UDim2.new(1, math.floor(14 * s), 1, math.floor(14 * s)) }), TweenService:Create(rippleStroke, info, { Transparency = 1 })
		end)
		if okRipple and grow and fade then
			table.insert(callout.tweens, grow)
			table.insert(callout.tweens, fade)
			pcall(function()
				grow:Play()
				fade:Play()
			end)
		end

		callout.arrow = buildArrow(container, callout.arrowSize, s)

		local bubbleHeight = math.floor((if subText then 66 else 48) * s)
		local bubble = create("Frame", {
			Name = "Bubble",
			Size = UDim2.fromOffset(math.floor(270 * s), bubbleHeight),
			BackgroundColor3 = NAVY,
			ZIndex = 2,
		}, container)
		create("UIStroke", { Thickness = 2.5, Color = GOLD }, bubble)
		UIStyle.soften(bubble, { radius = 14, strength = 0.25, shine = false })
		label(bubble, {
			Name = "Text",
			Position = UDim2.fromScale(0.05, 0.08),
			Size = UDim2.fromScale(0.9, if subText then 0.52 else 0.84),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = true,
			ZIndex = 4,
		}, 1.5)
		if subText then
			label(bubble, {
				Name = "SubText",
				Position = UDim2.fromScale(0.05, 0.62),
				Size = UDim2.fromScale(0.9, 0.3),
				Text = subText,
				Font = BODY_FONT,
				TextColor3 = Color3.fromRGB(205, 212, 245),
				TextWrapped = true,
				ZIndex = 4,
			}, 0)
		end
		callout.bubble = bubble

		-- Hedef bir düğmeyse ona basmak da adımı geçer
		if onClick then
			pcall(function()
				callout.clickConnection = target.MouseButton1Click:Connect(function()
					task.defer(onClick)
				end)
			end)
		end
		activeCallout = callout
		applyDirection(callout, "above", 0.5)
		place(callout)
		task.spawn(function()
			task.wait(0.05) -- ilk ölçüm için bir iki kare bekle (konum düzeltmesi), sonra düzenli izle
			while callout.alive do
				place(callout)
				task.wait(FOLLOW_INTERVAL)
			end
		end)
		return callout
	end

	-- ---------- Kapatma ----------
	local function hide()
		card.Visible = false
		introBar.Visible = false
		intro = nil
		clearCallout()
		current = nil
		lastDismiss = os.clock()
	end

	local function markSeen(step)
		shownThisSession[step.id] = true
		task.spawn(pcall, shop.InvokeServer, shop, "GuideSeen", step.id)
	end

	local function dismiss()
		local step = current
		if not step then
			return
		end
		if not step.claim then
			markSeen(step)
		end
		hide()
	end

	gotIt.MouseButton1Click:Connect(dismiss)
	skip.MouseButton1Click:Connect(function()
		local step = current
		if step and not step.claim then
			markSeen(step)
		end
		hide()
		PlayerSettings.set("GuideOn", false)
		if showToast then
			showToast(true, "Guide turned off. You can turn it back on in Settings.")
		end
	end)

	-- ---------- Hızlı ok turu ----------
	local showStop

	local function finishIntro(skipped)
		local step = intro and intro.step
		if not step then
			return
		end
		markSeen(step)
		hide()
		if showToast and not skipped then
			showToast(true, "Now tap anywhere to squat! Open Quests (📜 top right) for NEW PLAYER rewards.")
		end
	end

	local function advanceIntro()
		if not intro then
			return
		end
		intro.index += 1
		if intro.index > #intro.stops then
			finishIntro(false)
		else
			showStop(intro.index)
		end
	end

	showStop = function(index)
		local state = intro
		if not state then
			return
		end
		local stop = state.stops[index]
		state.index = index
		state.stopToken += 1
		local mine = state.stopToken
		introCounter.Text = `Quick tour  {index}/{#state.stops}`
		introFill.Size = UDim2.fromScale(index / #state.stops, 1)
		local target = findTarget(player, stop.target)
		local ok = target ~= nil and pcall(setCallout, target, stop.text, nil, advanceIntro)
		if not ok then
			clearCallout() -- bu durağın oku kurulamadı: sonrakine geç
			task.defer(advanceIntro)
			return
		end
		task.delay(timing.intro, function()
			if intro == state and state.stopToken == mine then
				advanceIntro()
			end
		end)
	end

	local function startIntro(step)
		local stops = {}
		for _, stop in Config.GuideIntro or {} do
			local target = findTarget(player, stop.target)
			if target and isShown(target) then
				table.insert(stops, stop)
			end
		end
		if #stops < 3 then
			markSeen(step) -- arayüz henüz kurulmamış ya da çok az öğe var: turu atla
			current = nil
			lastDismiss = os.clock()
			return
		end
		intro = { step = step, stops = stops, index = 1, stopToken = 0 }
		card.Visible = false
		introBar.Visible = true
		showStop(1)
	end

	introNext.MouseButton1Click:Connect(advanceIntro)
	introSkip.MouseButton1Click:Connect(function()
		finishIntro(true)
	end)

	-- ---------- Kart adımları ve görev oku ----------
	local function show(step)
		current = step
		token += 1
		local mine = token
		if step.intro then
			startIntro(step)
			return
		end
		title.Text = step.title
		body.Text = step.text
		gotItLabel.Text = step.button or "Got it!"
		tagLabel.Text = step.tag or "GUIDE"
		card.Visible = true
		local target = findTarget(player, step.target)
		local onTargetClick = dismiss
		if step.target == "QuestsButton" then
			onTargetClick = function() -- oyuncu Quests'e bastı: pencerede ödülünü alsın, 'ödülü al' oku kısa süre susar
				timing.snoozeUntil = os.clock() + CLAIM_SNOOZE
				dismiss()
			end
		end
		if target and not pcall(setCallout, target, step.pointer or "Tap here!", nil, onTargetClick) then
			clearCallout() -- ok kurulamazsa sadece kart gösterilir
		elseif not target then
			clearCallout()
		end
		task.delay(AUTO_DISMISS, function()
			if current == step and token == mine then
				dismiss()
			end
		end)
	end

	-- Biten görevin ödülü alınmayı bekliyorsa (güncel hedef 'claim') Quests düğmesine kalıcı ok: altında ödül yazar.
	-- Oyuncu Quests'e basınca ok CLAIM_SNOOZE sn susar (pencerede ödülü alsın); ödül alınınca ya da hedef değişince kalkar.
	local function showClaim(quest)
		local target = findTarget(player, "QuestsButton")
		if not target then
			return false
		end
		local step = { id = "claim:" .. quest.id, claim = true, questId = quest.id }
		current = step
		token += 1
		local function opened()
			timing.snoozeUntil = os.clock() + CLAIM_SNOOZE
			dismiss()
		end
		local ok = pcall(setCallout, target, "Quest complete! Tap to claim", "Reward: " .. Objective.rewardText(quest.rewards), opened)
		if not ok then
			current = nil
			return false
		end
		return true
	end

	-- Rehber açık mı ve yeni oyuncu mu: ilk rebirth'e kadar, veri yüklendikten sonra
	local function active()
		return player:GetAttribute("DataLoaded") == true
			and player:GetAttribute("GuideOn") ~= false
			and rebirthValue.Value == 0
			and player:GetAttribute("GuideSeen") ~= nil
	end

	local function tick()
		if not active() then
			if current then
				hide()
			end
			return
		end
		if current then
			return
		end
		local seen = seenSet()
		local sinceDismiss = os.clock() - lastDismiss
		-- Güncel hedef (üst şeritle aynı) ve bu hedefin kartı bekliyor mu
		local objective = Objective.read(player, {
			wins = winValue.Value,
			level = levelValue.Value,
			maxLevel = player:GetAttribute("MaxLevel"),
			rebirths = rebirthValue.Value,
			wallText = "",
		})
		local cardPending = false
		if objective then
			for _, step in Config.GuideTour do
				if step.when == "quest:" .. objective.id and not seen[step.id] and not shownThisSession[step.id] then
					cardPending = true
				end
			end
		end
		for _, step in Config.GuideTour do
			if not seen[step.id] and not shownThisSession[step.id] and conditionMet(player, step, levelValue.Value, objective, cardPending) then
				if sinceDismiss >= math.min(step.gap or timing.gap, timing.gap) then
					show(step)
				end
				return
			end
		end
		-- Hızlı tur görüldükten sonra: ödülü alınmayı bekleyen görev varsa (güncel hedef 'claim') Quests düğmesine ok
		if objective and objective.id == "claim" and (seen.intro or shownThisSession.intro) and sinceDismiss >= timing.gap and os.clock() >= timing.snoozeUntil then
			showClaim(objective.quest)
		end
	end

	-- Guide anahtarı kapanırsa açık kart/ok hemen gider
	player:GetAttributeChangedSignal("GuideOn"):Connect(function()
		if player:GetAttribute("GuideOn") == false and current then
			hide()
		end
	end)
	-- Sunucu rehber kaydını sıfırladıysa (DEV 'RESTART TUTORIAL'): bu oturumda gösterilmiş sayılanlar da unutulur, açık kart/ok/tur kapanır ve rehber baştan başlar
	player:GetAttributeChangedSignal("GuideSeen"):Connect(function()
		if (player:GetAttribute("GuideSeen") or "") == "" and next(shownThisSession) ~= nil then
			table.clear(shownThisSession)
			timing.snoozeUntil = 0
			if current then
				hide()
			end
		end
	end)
	-- Gösterilen görev oku: görev alınınca (ya da başka yoldan) kaybolur
	player:GetAttributeChangedSignal("StarterState"):Connect(function()
		local step = current
		if step and step.claim then
			for _, entry in readStarter(player) do
				if entry.id == step.questId and entry.claimed then
					hide()
					return
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			tick()
			task.wait(CHECK_INTERVAL)
		end
	end)

	-- Testler ve hata ayıklama için
	GuideTour._tick = tick
	GuideTour._card = card
	GuideTour._introBar = introBar
	GuideTour._timing = timing
	GuideTour._place = function()
		if activeCallout then
			place(activeCallout)
		end
	end
	GuideTour._state = function()
		return { current = current, callout = activeCallout, intro = intro, overlays = overlays }
	end
	return card
end

return GuideTour
