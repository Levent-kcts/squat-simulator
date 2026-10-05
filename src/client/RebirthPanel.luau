-- Rebirth onay ekranı: önce/sonra çarpanı, önce/sonra en yüksek level, uyarı, level çubuğu ve iki buton:
-- "Rebirth" (level sınırına gelince çalışır) ve "SKIP?" (Robux ile level şartını atlama, şimdilik yer tutucu).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local Progression = require(Shared:WaitForChild("Progression"))

local RebirthPanel = {}

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

-- showToast(ok, mesaj): kısa bildirim gösterir. Dönüş: paneli açan fonksiyon.
function RebirthPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")
	local leaderstats = player:WaitForChild("leaderstats")
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(600, 420),
		BackgroundColor3 = Color3.fromRGB(30, 26, 40),
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	-- Başlık
	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = Color3.fromRGB(235, 40, 190),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	makeText(header, { Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(42, 42), Text = "🔄" }, 0)
	makeText(header, {
		Position = UDim2.fromOffset(64, 8),
		Size = UDim2.new(0.5, 0, 1, -16),
		Text = "Rebirth",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.new(1, 1, 1),
	}, 3)
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(42, 42),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(215, 30, 60),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })

	-- Önce / Sonra tablosu
	makeText(panel, {
		Position = UDim2.new(0.04, 0, 0, 68),
		Size = UDim2.new(0.4, 0, 0, 24),
		Text = "Before",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)
	makeText(panel, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.96, 0, 0, 68),
		Size = UDim2.new(0.4, 0, 0, 24),
		Text = "After",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	local function infoBox(row, side, color)
		local box = create("Frame", {
			AnchorPoint = Vector2.new(if side == "right" then 1 else 0, 0),
			Position = UDim2.new(if side == "right" then 0.96 else 0.04, 0, 0, 98 + (row - 1) * 62),
			Size = UDim2.new(0.4, 0, 0, 52),
			BackgroundColor3 = color,
		}, panel)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, box)
		UIStyle.soften(box, { radius = 10, strength = 0.28 })
		return makeText(box, {
			Position = UDim2.fromScale(0.05, 0.12),
			Size = UDim2.fromScale(0.9, 0.76),
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
	end
	local pink = Color3.fromRGB(235, 40, 110)
	local cyan = Color3.fromRGB(40, 170, 230)
	local beforeMultiplier = infoBox(1, "left", pink)
	local afterMultiplier = infoBox(1, "right", pink)
	local beforeMax = infoBox(2, "left", cyan)
	local afterMax = infoBox(2, "right", cyan)
	makeText(panel, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(40, 40), Text = "→", TextColor3 = Color3.new(1, 1, 1) }, 2)
	makeText(panel, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 166), Size = UDim2.fromOffset(40, 40), Text = "→", TextColor3 = Color3.new(1, 1, 1) }, 2)

	-- Uyarı
	makeText(panel, {
		Position = UDim2.new(0.03, 0, 0, 228),
		Size = UDim2.new(0.94, 0, 0, 28),
		Text = "[WARNING] Rebirth resets your leg muscle, wins & levels!",
		TextColor3 = Color3.fromRGB(255, 70, 70),
	}, 2)

	-- Level çubuğu
	local bar = create("Frame", {
		Position = UDim2.new(0.03, 0, 0, 266),
		Size = UDim2.new(0.94, 0, 0, 48),
		BackgroundColor3 = Color3.fromRGB(90, 60, 10),
	}, panel)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, bar)
	UIStyle.soften(bar, { radius = 12, strength = 0.35, shine = false })
	local barFill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 190, 20),
		BorderSizePixel = 0,
	}, bar)
	UIStyle.soften(barFill, { radius = 12, strength = 0.3 })
	local barText = makeText(bar, {
		Position = UDim2.fromScale(0.05, 0.08),
		Size = UDim2.fromScale(0.9, 0.84),
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	-- Butonlar
	local function bigButton(side, color, text)
		local button = create("TextButton", {
			AnchorPoint = Vector2.new(if side == "right" then 1 else 0, 0),
			Position = UDim2.new(if side == "right" then 0.97 else 0.03, 0, 0, 328),
			Size = UDim2.new(0.46, 0, 0, 74),
			Text = "",
			BackgroundColor3 = color,
		}, panel)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 14, strength = 0.28 })
		local label = makeText(button, {
			Position = UDim2.fromScale(0.05, 0.1),
			Size = UDim2.fromScale(0.9, 0.8),
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
		}, 3)
		return button, label
	end
	local rebirthButton, rebirthLabel = bigButton("left", Color3.fromRGB(60, 200, 40), "Rebirth")
	local skipButton, skipLabel = bigButton("right", Color3.fromRGB(170, 40, 230), `SKIP? R$ {Config.Rebirth.SkipRobuxPrice}`)

	local function currentState()
		local rebirths = rebirthValue.Value
		return rebirths, levelValue.Value, Progression.maxLevel(rebirths)
	end

	local function render()
		local rebirths, level, maxLevel = currentState()
		beforeMultiplier.Text = `{string.format("%.2f", Progression.rebirthMultiplier(rebirths))}x Multiplier`
		afterMultiplier.Text = `{string.format("%.2f", Progression.rebirthMultiplier(rebirths + 1))}x Multiplier`
		beforeMax.Text = `Max Level {maxLevel}`
		afterMax.Text = `Max Level {Progression.maxLevel(rebirths + 1)}`
		barText.Text = `Level: {level}/{maxLevel}`
		barFill.Size = UDim2.fromScale(math.clamp(level / maxLevel, 0, 1), 1)

		local ready = level >= maxLevel
		rebirthButton.BackgroundColor3 = if ready then Color3.fromRGB(60, 200, 40) else Color3.fromRGB(105, 110, 105)
		rebirthLabel.Text = if ready then "Rebirth" else `Reach level {maxLevel}`
	end

	rebirthButton.MouseButton1Click:Connect(function()
		local _, level, maxLevel = currentState()
		if level < maxLevel then
			showToast(false, `Reach level {maxLevel} to rebirth!`)
			return
		end
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer("Rebirth")
			showToast(ok, message or "")
			if ok then
				panel.Visible = false
			end
			render()
		end)
	end)

	skipButton.MouseButton1Click:Connect(function()
		-- Gerçek satış için Developer Product oluşturulup Config.Rebirth.SkipProductId'ye yazılmalı
		if Config.Rebirth.SkipProductId > 0 then
			-- Satın alma penceresi açılır; rebirth'i sunucu ProcessReceipt ile yapar (server/Purchases)
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, Config.Rebirth.SkipProductId)
		else
			showToast(false, "Skipping with Robux is coming soon!")
		end
	end)

	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	local function onChange()
		if panel.Visible then
			render()
		end
	end
	levelValue:GetPropertyChangedSignal("Value"):Connect(onChange)
	rebirthValue:GetPropertyChangedSignal("Value"):Connect(onChange)

	-- Paneli açar (kapalıysa), açıksa kapatır
	return function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			render()
		end
	end
end

return RebirthPanel
