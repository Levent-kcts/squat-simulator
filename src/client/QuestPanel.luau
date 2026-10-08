-- Günlük görevler penceresi (sağ üstteki 📜 dairesi ya da lobideki görev panosu): bugünün 3 görevi, ilerleme çubukları, ödüller ve 3'ünü bitirince bonus.
-- Görevleri, ilerlemeyi ve ödülleri SUNUCU hesaplar ve 'QuestData' özniteliğine JSON olarak yazar (PlayerStats); burası sadece gösterir ve CLAIM isteği yollar.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)
-- Ses (isteğe bağlı): ödül alınınca kısa jingle
local okSfx, Sfx = pcall(require, script.Parent.Sfx)

local QuestPanel = {}

local FONT = Enum.Font.FredokaOne

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function makeText(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- QuestData özniteliğini çözer; yoksa/bozuksa nil
function QuestPanel.read(player)
	local raw = player:GetAttribute("QuestData")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

-- Alınmayı bekleyen ödül sayısı (biten ve alınmamış görevler + hazır bonus): sağ üstteki daire rozeti bunu gösterir
function QuestPanel.claimable(player)
	local data = QuestPanel.read(player)
	if not data or not data.quests then
		return 0
	end
	local count = 0
	local allClaimed = true
	for _, quest in data.quests do
		if not quest.claimed then
			allClaimed = false
			if quest.progress >= quest.goal then
				count += 1
			end
		end
	end
	if allClaimed and not data.bonusClaimed then
		count += 1
	end
	return count
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

-- showToast(ok, mesaj): kısa bildirim. Dönüş: paneli açıp kapatan fonksiyon.
function QuestPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 470),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(255, 160, 40),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Quests, "📜", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) })
	makeText(header, {
		Position = UDim2.fromOffset(68, 8),
		Size = UDim2.fromOffset(250, 40),
		Text = "DAILY QUESTS",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
	local timerText = makeText(header, {
		Position = UDim2.fromOffset(320, 12),
		Size = UDim2.new(1, -380, 0, 32),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 250, 200),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, 2)
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "X",
		Font = FONT,
		TextSize = 26,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 40, 90),
	}, header)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	local list = create("Frame", {
		Position = UDim2.fromOffset(12, 66),
		Size = UDim2.new(1, -24, 1, -78),
		BackgroundTransparency = 1,
	}, panel)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function claimButton(parent, position, size)
		local button = create("TextButton", {
			Position = position,
			Size = size,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(95, 100, 120),
		}, parent)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.28 })
		local label = makeText(button, {
			Position = UDim2.fromScale(0.05, 0.12),
			Size = UDim2.fromScale(0.9, 0.76),
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		return button, label
	end

	local function invoke(action, id)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			showToast(ok, message or "")
			if ok and okSfx then
				pcall(Sfx.play, "Win") -- ödül alındı sesi
			end
		end)
	end

	local function styleClaim(button, label, state)
		if state == "ready" then
			button.BackgroundColor3 = Color3.fromRGB(60, 200, 40)
			label.Text = "CLAIM!"
			button.Active = true
		elseif state == "claimed" then
			button.BackgroundColor3 = Color3.fromRGB(70, 75, 95)
			label.Text = "CLAIMED"
			button.Active = false
		else
			button.BackgroundColor3 = Color3.fromRGB(95, 100, 120)
			label.Text = "In progress"
			button.Active = false
		end
	end

	-- 3 görev satırı + bonus satırı bir kez kurulur, render sadece değerleri günceller
	local rows = {}
	for slot = 1, 3 do
		local row = create("Frame", {
			LayoutOrder = slot,
			Size = UDim2.new(1, 0, 0, 86),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, list)
		UIStyle.soften(row, { radius = 12, strength = 0.12, shine = false })
		local title = makeText(row, {
			Position = UDim2.fromOffset(14, 6),
			Size = UDim2.new(0.58, -14, 0, 30),
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 2)
		local bar = create("Frame", {
			Position = UDim2.fromOffset(14, 46),
			Size = UDim2.new(0.58, -14, 0, 26),
			BackgroundColor3 = Color3.fromRGB(25, 27, 38),
		}, row)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)
		create("UIStroke", { Thickness = 2.5, Color = Color3.new(0, 0, 0) }, bar)
		local fill = create("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = Color3.fromRGB(110, 255, 140),
			BorderSizePixel = 0,
		}, bar)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
		local amount = makeText(bar, {
			Position = UDim2.fromScale(0.05, 0.1),
			Size = UDim2.fromScale(0.9, 0.8),
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 2,
		}, 1.5)
		local reward = makeText(row, {
			Position = UDim2.new(0.6, 6, 0, 6),
			Size = UDim2.new(0.4, -18, 0, 30),
			Text = "",
			TextColor3 = Color3.fromRGB(255, 225, 110),
		}, 2)
		local button, buttonLabel = claimButton(row, UDim2.new(0.6, 6, 0, 42), UDim2.new(0.4, -18, 0, 34))
		button.MouseButton1Click:Connect(function()
			invoke("ClaimQuest", slot)
		end)
		rows[slot] = { title = title, fill = fill, amount = amount, reward = reward, button = button, buttonLabel = buttonLabel }
	end

	local bonusRow = create("Frame", {
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 86),
		BackgroundColor3 = Color3.fromRGB(88, 62, 140),
	}, list)
	UIStyle.soften(bonusRow, { radius = 12, strength = 0.15, shine = false })
	makeText(bonusRow, {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(0.58, -14, 0, 30),
		Text = "⭐ BONUS: finish all 3 quests",
		TextColor3 = Color3.fromRGB(255, 240, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)
	local bonusReward = makeText(bonusRow, {
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.new(0.58, -14, 0, 30),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)
	local bonusButton, bonusButtonLabel = claimButton(bonusRow, UDim2.new(0.6, 6, 0, 26), UDim2.new(0.4, -18, 0, 36))
	bonusButton.MouseButton1Click:Connect(function()
		invoke("ClaimQuestBonus", "")
	end)

	local resetAt = 0

	local function updateTimer()
		if resetAt > 0 then
			timerText.Text = `New quests in {formatTime(resetAt - Workspace:GetServerTimeNow())}`
		else
			timerText.Text = ""
		end
	end

	local function render()
		local data = QuestPanel.read(player)
		if not data or not data.quests then
			timerText.Text = "Loading..."
			return
		end
		resetAt = data.resetAt or 0
		local allClaimed = true
		for slot, quest in data.quests do
			local row = rows[slot]
			if row then
				local progress = math.min(quest.progress, quest.goal)
				row.title.Text = quest.text
				row.fill.Size = UDim2.fromScale(math.clamp(progress / quest.goal, 0, 1), 1)
				row.amount.Text = `{progress} / {quest.goal}`
				row.reward.Text = `🎁 {quest.reward}`
				if quest.claimed then
					styleClaim(row.button, row.buttonLabel, "claimed")
				else
					allClaimed = false
					styleClaim(row.button, row.buttonLabel, if progress >= quest.goal then "ready" else "progress")
				end
			end
		end
		bonusReward.Text = data.bonusText or ""
		if data.bonusClaimed then
			styleClaim(bonusButton, bonusButtonLabel, "claimed")
		elseif allClaimed then
			styleClaim(bonusButton, bonusButtonLabel, "ready")
		else
			styleClaim(bonusButton, bonusButtonLabel, "progress")
		end
		updateTimer()
	end

	player:GetAttributeChangedSignal("QuestData"):Connect(function()
		if PanelManager.isOpen(panel) then
			render()
		end
	end)

	-- Açıkken geri sayım saniyede bir güncellenir
	task.spawn(function()
		while true do
			if PanelManager.isOpen(panel) then
				updateTimer()
			end
			task.wait(1)
		end
	end)

	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			render()
		end
	end
end

return QuestPanel
