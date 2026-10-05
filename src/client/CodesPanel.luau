-- Kod giriş penceresi: oyuncu bir kod yazar, sunucu doğrular ve ödülü verir (PlayerStats.redeemCode, Config.Codes).
-- Sol menüdeki CODES butonuyla açılır. Doğrulama tamamen sunucuda; burada sadece yazı kutusu ve sonuç mesajı var.
local Players = game:GetService("Players")
local UIStyle = require(script.Parent.UIStyle)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CodesPanel = {}

local FONT = Enum.Font.FredokaOne

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

-- Döner: pencereyi açıp kapatan fonksiyon
function CodesPanel.init(screenGui, showToast)
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(380, 210),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Color3.fromRGB(235, 120, 40),
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, header)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	text(header, {
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -90, 1, -12),
		Text = "ENTER CODE",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)

	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
	}, header)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	text(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1) }, 2)

	local box = create("TextBox", {
		Position = UDim2.fromOffset(20, 74),
		Size = UDim2.new(1, -40, 0, 50),
		BackgroundColor3 = Color3.fromRGB(235, 240, 250),
		ClearTextOnFocus = false,
		Font = FONT,
		PlaceholderText = "Type a code...",
		PlaceholderColor3 = Color3.fromRGB(130, 135, 150),
		Text = "",
		TextColor3 = Color3.fromRGB(30, 30, 40),
		TextScaled = true,
		MaxVisibleGraphemes = 24,
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, box)
	UIStyle.soften(box, { radius = 10, strength = 0.15, shine = false })
	create("UITextSizeConstraint", { MaxTextSize = 30 }, box)

	local redeem = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.fromOffset(190, 52),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 210, 80),
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, redeem)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, redeem)
	UIStyle.soften(redeem, { radius = 10, strength = 0.28 })
	text(redeem, {
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 1, -12),
		Text = "REDEEM",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2)

	local busy = false
	local function submit()
		if busy or box.Text == "" then
			return
		end
		busy = true
		local ok, success, message = pcall(function()
			return shopFunction:InvokeServer("RedeemCode", box.Text)
		end)
		busy = false
		if ok then
			showToast(success, message)
			if success then
				box.Text = ""
				panel.Visible = false
			end
		end
	end
	redeem.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)

	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	return function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			box.Text = ""
		end
	end
end

return CodesPanel
