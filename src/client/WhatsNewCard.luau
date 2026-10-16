-- NELER YENİ KARTI (Config.WhatsNew; büyüme planı 1.6): geri dönen oyuncuya yeni özellikleri tek küçük kartla duyurur. Eğitimi bitirmiş oyuncuda, görmediği bir sürüm varsa girişten birkaç sn sonra BİR KEZ kendiliğinden açılır
-- ('Got it!' ya da X: sunucuya 'SeenWhatsNew' gider, o sürüm görülmüş sayılır). Settings > 'What's New' ile her zaman yeniden açılır. Karartma YOK, küçük, ortada; çevrimdışı kazanç penceresi açıksa o kapanana kadar bekler.
-- Döner: kartı açan fonksiyon.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local WhatsNewCard = {}

local FONT = Enum.Font.FredokaOne
local SHOW_DELAY = 4 -- girişten sonra (sn)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function text(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

function WhatsNewCard.init(screenGui)
	local player = Players.LocalPlayer
	local settings = Config.WhatsNew
	if not settings or not settings.Lines or #settings.Lines == 0 then
		return nil
	end
	local shop = ReplicatedStorage:WaitForChild("Shop")

	local LINE_HEIGHT, HEADER, FOOTER = 34, 50, 62
	local height = HEADER + #settings.Lines * LINE_HEIGHT + FOOTER + 12
	local card = create("Frame", {
		Name = "WhatsNewCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(380, height),
		BackgroundColor3 = Color3.fromRGB(34, 42, 86),
		Active = true, -- karta tıklamak hareket başlatmasın
		Visible = false,
		ZIndex = 20,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	create("UIStroke", { Thickness = 4, Color = Color3.fromRGB(12, 16, 42) }, card)
	create("UISizeConstraint", { MaxSize = Vector2.new(380, height), MinSize = Vector2.new(290, height) }, card)
	UIStyle.soften(card, { radius = 16, strength = 0.22, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundColor3 = Color3.fromRGB(255, 190, 60),
		ZIndex = 21,
	}, card)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, header)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	local title = text(header, {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -70, 1, -12),
		Text = `✨ {settings.Title}`,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	}, 3)
	create("UITextSizeConstraint", { MaxTextSize = 26 }, title)

	local function markSeen()
		if (player:GetAttribute("WhatsNewSeen") or 0) < settings.Version then
			task.spawn(function()
				pcall(shop.InvokeServer, shop, "SeenWhatsNew")
			end)
		end
	end
	local function hide()
		card.Visible = false
		markSeen()
	end

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(34, 34),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
		ZIndex = 22,
	}, header)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	text(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1), ZIndex = 23 }, 2)
	close.MouseButton1Click:Connect(hide)

	for index, line in settings.Lines do
		local row = create("Frame", {
			Name = `Line_{index}`,
			Position = UDim2.fromOffset(12, HEADER + 8 + (index - 1) * LINE_HEIGHT),
			Size = UDim2.new(1, -24, 0, LINE_HEIGHT - 4),
			BackgroundColor3 = Color3.fromRGB(52, 62, 120),
			ZIndex = 21,
		}, card)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		text(row, {
			Position = UDim2.fromOffset(6, 2),
			Size = UDim2.fromOffset(30, LINE_HEIGHT - 8),
			Text = line.icon or "•",
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 22,
		}, 1)
		local label = text(row, {
			Position = UDim2.fromOffset(40, 2),
			Size = UDim2.new(1, -46, 1, -4),
			Text = line.text,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 22,
		}, 1)
		create("UITextSizeConstraint", { MaxTextSize = 16 }, label)
	end

	local gotIt = create("TextButton", {
		Name = "GotItButton",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(170, 42),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(70, 200, 100),
		ZIndex = 22,
	}, card)
	create("UICorner", { CornerRadius = UDim.new(0, 21) }, gotIt)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, gotIt)
	UIStyle.soften(gotIt, { radius = 21, strength = 0.28 })
	text(gotIt, { Position = UDim2.fromScale(0.1, 0.12), Size = UDim2.fromScale(0.8, 0.76), Text = "GOT IT!", TextColor3 = Color3.new(1, 1, 1), ZIndex = 23 }, 2)
	gotIt.MouseButton1Click:Connect(hide)

	local function show()
		card.Visible = true
	end

	-- Kendiliğinden açılma: veri yüklü, eğitim bitmiş, görülmemiş sürüm var. Çevrimdışı kazanç penceresi açıksa o kapanana kadar (en çok 40 sn) beklenir.
	local scheduled = false
	local function consider()
		if scheduled or player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") ~= true then
			return
		end
		if (player:GetAttribute("WhatsNewSeen") or 0) >= settings.Version then
			return
		end
		scheduled = true
		task.spawn(function()
			task.wait(SHOW_DELAY)
			for _ = 1, 40 do
				local playerGui = player:FindFirstChildOfClass("PlayerGui")
				local offline = (playerGui and playerGui:FindFirstChild("OfflineEarnings", true)) or screenGui:FindFirstChild("OfflineEarnings", true)
				if not offline or not offline.Visible then
					break
				end
				task.wait(1)
			end
			if (player:GetAttribute("WhatsNewSeen") or 0) < settings.Version then
				show()
			end
		end)
	end
	player:GetAttributeChangedSignal("DataLoaded"):Connect(consider)
	player:GetAttributeChangedSignal("TutorialDone"):Connect(consider)
	player:GetAttributeChangedSignal("WhatsNewSeen"):Connect(consider)
	consider()

	return show
end

return WhatsNewCard
