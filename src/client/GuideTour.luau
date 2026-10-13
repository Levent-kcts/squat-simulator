-- REHBER TURU (2026-10-13, sahibi 'yeni oyuncu ilk rebirth'e kadar oyun tarafından yönlendirilsin, arayüzleri tanıtsın' dedi; sonra 'çok sade kalıyor, hızlı bir tanıtım yapıp oklarla göstersin, iki görev birbirine bağlı olsun' dedi):
--   1) HIZLI OK TURU (Config.GuideIntro): ilk girişte tüm düğmeleri sırayla, büyük zıplayan ok + kısa konuşma balonuyla gezer (kendiliğinden ilerler, 'Next' hızlandırır, 'Skip' bitirir).
--   2) KARTLAR (Config.GuideTour): doğru anda tek tek küçük kart; hedef düğme büyük okla işaretlenir. Eğitim görevi (ilk ClickGoal tıklama) bitmeden ikinci bir kart açılmaz.
--   3) GÖREV BAĞI: bir NEW PLAYER görevi bitince (StarterState) Quests düğmesine 'Quest complete! Tap to claim' oku çıkar, altında sıradaki görev yazar (görevler sekmesi ile rehber aynı zincir).
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

local GuideTour = {}

local FONT = Enum.Font.FredokaOne
local BODY_FONT = Enum.Font.GothamMedium
local GOLD = Color3.fromRGB(255, 214, 60)
local NAVY = Color3.fromRGB(34, 38, 60)
local GAP_SECONDS = 2.5 -- iki kart arası en az bekleme
local AUTO_DISMISS = 20 -- sn: kapatılmazsa görüldü sayılıp kaybolur
local CLAIM_SECONDS = 15 -- sn: görev tamamlandı okunun kalma süresi
local CHECK_INTERVAL = 0.5
local FOLLOW_INTERVAL = 0.1 -- ok, hedefin konumunu bu aralıkla izler
local OVERLAY_ORDER = 800 -- yükleme ekranının (1000) altında, diğer arayüzün üstünde
local ARROW_GLYPH = { right = "◀", left = "▶", below = "▲", above = "▼" }

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

-- Adımın koşulu sağlandı mı? when: start / clicks / winsFirst / pet / skin / level:N / nearMax
-- 'start' ve 'clicks' dışındakiler eğitim tıklamaları bitmeden çıkmaz: ilk görev (30 tıklama) sürerken ikinci bir görev kartı açılmaz
local function conditionMet(player, when, wins, level)
	if when == "start" then
		return true
	end
	local clicksDone = (player:GetAttribute("TutorialClicks") or 0) >= Config.Tutorial.ClickGoal
	if when == "clicks" then
		return clicksDone
	elseif not clicksDone then
		return false
	elseif when == "winsFirst" then
		return wins >= 1
	elseif when == "pet" then
		return (player:GetAttribute("OwnedPets") or "") ~= ""
	elseif when == "skin" then
		return (player:GetAttribute("OwnedSkins") or "") ~= ""
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

local function questText(id)
	for _, quest in Config.StarterQuests do
		if quest.id == id then
			return quest.text
		end
	end
	return id
end

-- screenGui: ana arayüz çerçevesi (kart buraya konur); showToast isteğe bağlı
function GuideTour.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local leaderstats = player:WaitForChild("leaderstats")
	local winValue = leaderstats:WaitForChild(Config.StatWins)
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)
	local timing = { gap = GAP_SECONDS, intro = Config.GuideIntroSeconds or 2.6 }

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
	create("UIStroke", { Thickness = 4, Color = GOLD }, card)
	UIStyle.soften(card, { radius = 16, strength = 0.2, shine = false })
	create("UISizeConstraint", { MaxSize = Vector2.new(430, 170), MinSize = Vector2.new(260, 170) }, card)

	label(card, { -- 'GUIDE' etiketi
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(70, 18),
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

	-- ---------- Hızlı tur çubuğu: 'Quick tour 3/10  [Skip] [Next >]' ----------
	local introBar = create("Frame", {
		Name = "IntroBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.27, 0),
		Size = UDim2.fromOffset(360, 48),
		BackgroundColor3 = NAVY,
		Active = true,
		Visible = false,
		ZIndex = 60,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = GOLD }, introBar)
	UIStyle.soften(introBar, { radius = 14, strength = 0.2, shine = false })
	create("UISizeConstraint", { MaxSize = Vector2.new(360, 48), MinSize = Vector2.new(300, 48) }, introBar)
	local introCounter = label(introBar, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.fromOffset(160, 36),
		Text = "",
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 61,
	}, 2)
	local introSkip = create("TextButton", {
		Name = "IntroSkip",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -112, 0.5, 0),
		Size = UDim2.fromOffset(62, 28),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(86, 90, 112),
		ZIndex = 62,
	}, introBar)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, introSkip)
	UIStyle.soften(introSkip, { radius = 8, strength = 0.2, shine = false })
	label(introSkip, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Skip", TextColor3 = Color3.fromRGB(225, 228, 245), ZIndex = 63 }, 1.5)
	local introNext = create("TextButton", {
		Name = "IntroNext",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(96, 34),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		ZIndex = 62,
	}, introBar)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, introNext)
	UIStyle.soften(introNext, { radius = 10, strength = 0.28 })
	label(introNext, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Next ▶", TextColor3 = Color3.new(1, 1, 1), ZIndex = 63 }, 2)

	-- ---------- Durum ----------
	local current = nil -- şu an gösterilen adım (kart, hızlı tur ya da görev oku)
	local shownThisSession = {} -- bu oturumda gösterilen (sunucu kaydı gelmeden tekrar göstermemek için)
	local announced = {} -- bu oturumda 'görev tamamlandı' oku gösterilen görevler
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
		local gap = math.floor(4 * s)
		local arrowSize = callout.arrowSize
		local span = gap + arrowSize
		local bob = math.floor(9 * s)
		local arrow, bubble = callout.arrow, callout.bubble
		arrow.Text = ARROW_GLYPH[dir]
		local from, to
		if dir == "right" then
			arrow.AnchorPoint = Vector2.new(0, 0.5)
			bubble.AnchorPoint = Vector2.new(0, 0.5)
			from, to = UDim2.new(1, gap, 0.5, 0), UDim2.new(1, gap - bob, 0.5, 0)
			bubble.Position = UDim2.new(1, span + 2, 0.5, 0)
		elseif dir == "left" then
			arrow.AnchorPoint = Vector2.new(1, 0.5)
			bubble.AnchorPoint = Vector2.new(1, 0.5)
			from, to = UDim2.new(0, -gap, 0.5, 0), UDim2.new(0, -gap + bob, 0.5, 0)
			bubble.Position = UDim2.new(0, -span - 2, 0.5, 0)
		elseif dir == "below" then
			arrow.AnchorPoint = Vector2.new(0.5, 0)
			bubble.AnchorPoint = Vector2.new(align, 0)
			from, to = UDim2.new(0.5, 0, 1, gap), UDim2.new(0.5, 0, 1, gap - bob)
			bubble.Position = UDim2.new(align, 0, 1, span)
		else
			arrow.AnchorPoint = Vector2.new(0.5, 1)
			bubble.AnchorPoint = Vector2.new(align, 1)
			from, to = UDim2.new(0.5, 0, 0, -gap), UDim2.new(0.5, 0, 0, -gap + bob)
			bubble.Position = UDim2.new(align, 0, 0, -span)
		end
		arrow.Position = from
		local ok, tween = pcall(function()
			return TweenService:Create(arrow, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = to })
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
			arrowSize = math.floor(54 * s),
			alive = true,
			tweens = {},
			bounceTweens = {},
		}
		local container = create("Frame", { Name = "GuideCallout", BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), Visible = false }, overlay)
		callout.container = container

		local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, container)
		create("UICorner", { CornerRadius = UDim.new(0, math.floor(14 * s)) }, ring)
		local stroke = create("UIStroke", { Thickness = 4, Color = GOLD }, ring)
		local okPulse, pulse = pcall(function()
			return TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 9 })
		end)
		if okPulse and pulse then
			table.insert(callout.tweens, pulse)
			pcall(function()
				pulse:Play()
			end)
		end

		callout.arrow = label(container, {
			Name = "Arrow",
			Size = UDim2.fromOffset(callout.arrowSize, callout.arrowSize),
			Text = "▼",
			TextColor3 = GOLD,
			ZIndex = 3,
		}, 3)

		local bubbleHeight = math.floor((if subText then 70 else 50) * s)
		local bubble = create("Frame", {
			Name = "Bubble",
			Size = UDim2.fromOffset(math.floor(260 * s), bubbleHeight),
			BackgroundColor3 = NAVY,
			ZIndex = 2,
		}, container)
		create("UIStroke", { Thickness = 3, Color = GOLD }, bubble)
		UIStyle.soften(bubble, { radius = 12, strength = 0.2, shine = false })
		label(bubble, {
			Name = "Text",
			Position = UDim2.fromScale(0.04, 0.06),
			Size = UDim2.fromScale(0.92, if subText then 0.56 else 0.88),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = true,
			ZIndex = 4,
		}, 1.5)
		if subText then
			label(bubble, {
				Name = "SubText",
				Position = UDim2.fromScale(0.04, 0.64),
				Size = UDim2.fromScale(0.92, 0.3),
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
		card.Visible = true
		local target = findTarget(player, step.target)
		if target and not pcall(setCallout, target, step.pointer or "Tap here!", nil, dismiss) then
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

	-- Bir NEW PLAYER görevi bitince Quests düğmesine 'tamamlandı, al' oku; altında sıradaki görev (rehber ile görevler aynı zincir)
	local function showClaim(quest)
		local target = findTarget(player, "QuestsButton")
		if not target then
			return false
		end
		announced[quest.id] = true
		local nextText = nil
		for _, entry in readStarter(player) do
			if not entry.done and entry.id ~= quest.id then
				nextText = questText(entry.id)
				break
			end
		end
		local step = { id = "claim:" .. quest.id, claim = true, questId = quest.id }
		current = step
		token += 1
		local mine = token
		-- Quests'e basınca o an bekleyen tüm tamamlanmış görevler 'duyurulmuş' sayılır (arka arkaya ok çıkıp bunaltmasın)
		local function opened()
			for _, entry in readStarter(player) do
				if entry.done and not entry.claimed then
					announced[entry.id] = true
				end
			end
			dismiss()
		end
		local ok = pcall(setCallout, target, "Quest complete! Tap to claim", nextText and ("Next: " .. nextText) or nil, opened)
		if not ok then
			current = nil
			return false
		end
		task.delay(CLAIM_SECONDS, function()
			if current == step and token == mine then
				hide()
			end
		end)
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
		for _, step in Config.GuideTour do
			if not seen[step.id] and not shownThisSession[step.id] and conditionMet(player, step.when, winValue.Value, levelValue.Value) then
				if sinceDismiss >= math.min(step.gap or timing.gap, timing.gap) then
					show(step)
				end
				return
			end
		end
		-- Hızlı tur görüldükten sonra: biten ama alınmamış görev varsa Quests düğmesine ok
		if (seen.intro or shownThisSession.intro) and sinceDismiss >= timing.gap then
			for _, entry in readStarter(player) do
				if entry.done and not entry.claimed and not announced[entry.id] then
					local quest = nil
					for _, candidate in Config.StarterQuests do
						if candidate.id == entry.id then
							quest = candidate
						end
					end
					if quest and showClaim(quest) then
						return
					end
					announced[entry.id] = true
				end
			end
		end
	end

	-- Guide anahtarı kapanırsa açık kart/ok hemen gider
	player:GetAttributeChangedSignal("GuideOn"):Connect(function()
		if player:GetAttribute("GuideOn") == false and current then
			hide()
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
