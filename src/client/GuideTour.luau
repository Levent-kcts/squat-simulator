-- REHBER TURU (2026-10-13, sahibi 'yeni oyuncu ilk rebirth'e kadar oyun tarafından yönlendirilsin, arayüzleri tanıtsın' dedi): yeni oyuncuya ilk rebirth'e kadar, doğru anda tek tek küçük kartlar gösterir
-- (Config.GuideTour: hoş geldin, duvarlar, Wins, Pets, Quests, Gifts, Auto Click, Index, Backpack, Shop/Settings, antrenman alanı, Rebirth). Kart hangi arayüz öğesini anlatıyorsa onu parlak bir çerçeveyle ve ok ile işaretler.
-- Her adım bir kez gösterilir (sunucuda kayıtlı 'GuideSeen'); 'Got it!' ya da işaretlenen düğmeye basmak ya da 20 sn beklemek görüldü sayılır. 'Skip guide' ve Settings > Guide anahtarı tamamen kapatır (GuideOn = false).
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
local GAP_SECONDS = 2.5 -- iki kart arası en az bekleme
local AUTO_DISMISS = 20 -- sn: kapatılmazsa görüldü sayılıp kaybolur
local CHECK_INTERVAL = 0.5

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

-- Adımın koşulu sağlandı mı? when: start / clicks / winsFirst / pet / skin / level:N / nearMax
local function conditionMet(player, when, wins, level)
	if when == "start" then
		return true
	elseif when == "clicks" then
		return (player:GetAttribute("TutorialClicks") or 0) >= Config.Tutorial.ClickGoal
	elseif when == "winsFirst" then
		return (player:GetAttribute("TutorialClicks") or 0) >= Config.Tutorial.ClickGoal and wins >= 1
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

-- screenGui: ana arayüz çerçevesi (kart buraya konur); showToast isteğe bağlı
function GuideTour.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local leaderstats = player:WaitForChild("leaderstats")
	local winValue = leaderstats:WaitForChild(Config.StatWins)
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)

	-- ---------- Kart (bir kez kurulur, adımlar arasında içeriği değişir) ----------
	local card = create("Frame", {
		Name = "GuideCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.27, 0),
		Size = UDim2.fromOffset(430, 170),
		BackgroundColor3 = Color3.fromRGB(34, 38, 60),
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
	label(gotIt, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Got it!", TextColor3 = Color3.new(1, 1, 1), ZIndex = 63 }, 2)

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

	-- ---------- Durum ----------
	local current = nil -- şu an gösterilen adım
	local shownThisSession = {} -- bu oturumda gösterilen (sunucu kaydı gelmeden tekrar göstermemek için)
	local lastDismiss = 0
	local highlight = nil -- hedefe eklenen çerçeve
	local targetConnection = nil
	local pulseTween = nil
	local token = 0 -- otomatik kapanma zamanlayıcısı için

	local function seenSet()
		local set = {}
		for id in string.gmatch(player:GetAttribute("GuideSeen") or "", "[^,]+") do
			set[id] = true
		end
		return set
	end

	local function clearHighlight()
		if targetConnection then
			targetConnection:Disconnect()
			targetConnection = nil
		end
		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
		end
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	end

	local function hide()
		card.Visible = false
		clearHighlight()
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
		markSeen(step)
		hide()
	end

	gotIt.MouseButton1Click:Connect(dismiss)
	skip.MouseButton1Click:Connect(function()
		local step = current
		if step then
			markSeen(step)
		end
		hide()
		PlayerSettings.set("GuideOn", false)
		if showToast then
			showToast(true, "Guide turned off. You can turn it back on in Settings.")
		end
	end)

	-- Hedef öğeyi altın çerçeve ve zıplayan okla işaretler
	local function mark(target)
		clearHighlight()
		highlight = create("Frame", {
			Name = "GuideHighlight",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 14, 1, 14),
			BackgroundTransparency = 1,
			ZIndex = 100,
		}, target)
		create("UICorner", { CornerRadius = UDim.new(0, 12) }, highlight)
		local stroke = create("UIStroke", { Thickness = 5, Color = GOLD }, highlight)
		label(highlight, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -2),
			Size = UDim2.fromOffset(34, 26),
			Text = "▼",
			TextColor3 = GOLD,
			ZIndex = 101,
		}, 2)
		pulseTween = TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 9 })
		pulseTween:Play()
		-- İşaretlenen düğmeye basmak da adımı görüldü sayar
		if target:IsA("GuiButton") then
			targetConnection = target.MouseButton1Click:Connect(function()
				task.defer(dismiss)
			end)
		end
	end

	local function show(step)
		current = step
		title.Text = step.title
		body.Text = step.text
		card.Visible = true
		local target = findTarget(player, step.target)
		if target then
			if not pcall(mark, target) then
				clearHighlight() -- işaretleme başarısızsa sadece kart gösterilir
			end
		else
			clearHighlight()
		end
		token += 1
		local mine = token
		task.delay(AUTO_DISMISS, function()
			if current == step and token == mine then
				dismiss()
			end
		end)
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
		if current or os.clock() - lastDismiss < GAP_SECONDS then
			return
		end
		local seen = seenSet()
		for _, step in Config.GuideTour do
			if not seen[step.id] and not shownThisSession[step.id] and conditionMet(player, step.when, winValue.Value, levelValue.Value) then
				show(step)
				return
			end
		end
	end

	-- Guide anahtarı kapanırsa açık kart hemen gider
	player:GetAttributeChangedSignal("GuideOn"):Connect(function()
		if player:GetAttribute("GuideOn") == false and current then
			hide()
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
	return card
end

return GuideTour
