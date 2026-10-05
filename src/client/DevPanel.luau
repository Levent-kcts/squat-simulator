-- Test paneli (sol üstte küçük "DEV" butonu). Sadece sunucu izin verirse (Studio veya oyun sahibi) görünür.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DevPanel = {}

-- { buton yazısı, komut, miktar }
local BUTTONS = {
	{ "Level +1", "AddLevel", 1 },
	{ "Level +10", "AddLevel", 10 },
	{ "Max Level", "MaxLevel" },
	{ "Rebirth +1", "AddRebirth" },
	{ "Rebirth +10", "AddRebirth", 10 },
	{ "Wins +100", "AddWins", 100 },
	{ "Wins +10K", "AddWins", 10000 },
	{ "Wins +1M", "AddWins", 1000000 },
	{ "Muscle +1K", "AddMuscle", 1000 },
	{ "Muscle +100K", "AddMuscle", 100000 },
	{ "Muscle +10M", "AddMuscle", 10000000 },
	{ "All Shoes", "AllShoes" },
	{ "All Skins", "AllSkins" },
	{ "Free Pet", "FreePet" },
	{ "Break Stage", "BreakStage" },
	{ "TP to Walls", "TeleportToWalls" },
	{ "Gifts +10 min", "GiftTime", 10 },
	{ "Fake Friends 3", "FakeFriends", 3 },
	{ "Fake Friends 0", "FakeFriends", 0 },
	{ "Offline 1h", "SimulateOffline", 1 },
	{ "Offline 3h", "SimulateOffline", 3 },
	{ "Offline 8h", "SimulateOffline", 8 },
	{ "Offline Popup", "ShowOffline" },
	{ "Clear Offline", "ClearOffline" },
	{ "RESET ALL", "Reset" },
}

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

function DevPanel.init(screenGui)
	local player = Players.LocalPlayer
	local remote = ReplicatedStorage:WaitForChild("DevCommand")

	local toggle = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 96),
		Size = UDim2.fromOffset(70, 30),
		Text = "DEV",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(150, 60, 200),
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 8) }, toggle)

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 132),
		Size = UDim2.fromOffset(320, 340),
		BackgroundColor3 = Color3.fromRGB(28, 28, 38),
		Active = true, -- panele tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, panel)
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -4, 0, 36),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	for index, info in BUTTONS do
		local label, command, amount = info[1], info[2], info[3]
		local button = create("TextButton", {
			LayoutOrder = index,
			Text = label,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = if command == "Reset" then Color3.fromRGB(200, 60, 60) else Color3.fromRGB(60, 90, 160),
		}, list)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		button.MouseButton1Click:Connect(function()
			remote:FireServer(command, amount)
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)

	-- Sunucu izin verdiyse göster
	local function update()
		local allowed = player:GetAttribute("IsDev") == true
		toggle.Visible = allowed
		if not allowed then
			panel.Visible = false
		end
	end
	player:GetAttributeChangedSignal("IsDev"):Connect(update)
	update()
end

return DevPanel
