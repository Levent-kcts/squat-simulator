-- Günlük görevler penceresi (sağ üstteki 📜 dairesi ya da lobideki görev panosu): bugünün 3 görevi, ilerleme çubukları, ödüller ve 3'ünü bitirince bonus.
-- Görevleri, ilerlemeyi ve ödülleri SUNUCU hesaplar ve 'QuestData' özniteliğine JSON olarak yazar (PlayerStats); burası sadece gösterir ve CLAIM isteği yollar.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))
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

-- Yeni oyuncu görevleri: sunucunun 'StarterState' özniteliği 'id,ilerleme,bitti,alındı;...' (PlayerStats.publishStarter). Döner: { [id] = { progress, done, claimed } }
function QuestPanel.readStarter(player)
	local result = {}
	for entry in string.gmatch(player:GetAttribute("StarterState") or "", "[^;]+") do
		local id, progress, done, claimed = string.match(entry, "^([^,]+),(%d+),(%d),(%d)$")
		if id then
			result[id] = { progress = tonumber(progress), done = done == "1", claimed = claimed == "1" }
		end
	end
	return result
end

-- Alınmayı bekleyen yeni oyuncu görevi ödülü sayısı
function QuestPanel.starterClaimable(player)
	local count = 0
	for _, entry in QuestPanel.readStarter(player) do
		if entry.done and not entry.claimed then
			count += 1
		end
	end
	return count
end

-- Alınmayı bekleyen ödül sayısı (biten ve alınmamış günlük görevler + hazır bonus + yeni oyuncu görevleri): sağ üstteki daire rozeti bunu gösterir
function QuestPanel.claimable(player)
	local starter = QuestPanel.starterClaimable(player)
	local data = QuestPanel.read(player)
	if not data or not data.quests then
		return starter
	end
	local count = starter
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

-- Ödül listesini kısa yazıya çevirir ('+10 Wins', 'Rainbow Potion 15 min')
local function rewardText(rewards)
	local parts = {}
	for _, reward in rewards do
		if reward.kind == "wins" then
			table.insert(parts, `+{reward.amount} Wins`)
		else
			local potion = Catalog.PotionByKind[reward.kind]
			table.insert(parts, `{if potion then potion.name else "Potion"} {reward.minutes or Config.BoostMinutes}m`)
		end
	end
	return table.concat(parts, " + ")
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
		Size = UDim2.fromOffset(620, 540), -- (sekmeler için biraz yüksek)
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
		Text = "QUESTS",
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

	-- SEKMELER (2026-10-13, sahibi 'görevlere yeni oyuncu görevleri sekmesi' istedi): NEW PLAYER (Config.StarterQuests, ilk rebirth'e kadar rehber) ve DAILY
	local tabs = {}
	local currentTab = nil
	local function makeTab(name, title, x, color)
		local button = create("TextButton", {
			Name = "Tab_" .. name,
			Position = UDim2.fromOffset(x, 62),
			Size = UDim2.fromOffset(190, 36),
			Text = "",
			BackgroundColor3 = color,
		}, panel)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 10, strength = 0.28 })
		local label = makeText(button, { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = title, TextColor3 = Color3.new(1, 1, 1) }, 2)
		local dot = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromRGB(120, 255, 140),
			Visible = false,
			ZIndex = 5,
		}, button)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
		create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, dot)
		tabs[name] = { button = button, label = label, color = color, dot = dot }
		return button
	end
	local starterTab = makeTab("starter", "NEW PLAYER", 12, Color3.fromRGB(70, 190, 255))
	local dailyTab = makeTab("daily", "DAILY", 210, Color3.fromRGB(255, 160, 40))

	local list = create("Frame", {
		Position = UDim2.fromOffset(12, 108),
		Size = UDim2.new(1, -24, 1, -120),
		BackgroundTransparency = 1,
	}, panel)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	-- YENİ OYUNCU görev listesi (kaydırılır): her satır görevin adı, nerede/nasıl yapılacağı (hint), ilerleme çubuğu, ödül ve CLAIM
	local starterList = create("ScrollingFrame", {
		Name = "StarterList",
		Position = UDim2.fromOffset(12, 108),
		Size = UDim2.new(1, -24, 1, -120),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, panel)
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, starterList)

	local function claimButton(parent, position, size)
		local button = create("TextButton", {
			Position = position,
			Size = size,
			Text = "",
			BackgroundColor3 = Color3.fromRGB(95, 100, 120),
		}, parent)
		create("UIStroke", { Name = "Stroke", Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
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
		-- Alınmaya hazır ödülün düğmesi altın çerçeveli (oyuncu Quests'e yönlendirilince CLAIM'i hemen bulsun)
		local stroke = button:FindFirstChild("Stroke")
		if stroke then
			stroke.Color = if state == "ready" then Color3.fromRGB(255, 214, 60) else Color3.new(0, 0, 0)
			stroke.Thickness = if state == "ready" then 4 else 3
		end
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

	-- Yeni oyuncu satırları bir kez kurulur; renderStarter sadece değerleri günceller
	local starterRows = {}
	for index, quest in Config.StarterQuests do
		local row = create("Frame", {
			Name = "Starter_" .. quest.id,
			LayoutOrder = index,
			Size = UDim2.new(1, -10, 0, 74),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, starterList)
		UIStyle.soften(row, { radius = 12, strength = 0.12, shine = false })
		local title = makeText(row, {
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(0.6, -12, 0, 24),
			Text = quest.text,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 2)
		makeText(row, {
			Position = UDim2.fromOffset(12, 28),
			Size = UDim2.new(0.6, -12, 0, 16),
			Text = quest.hint,
			TextColor3 = Color3.fromRGB(190, 196, 220),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 1)
		local bar = create("Frame", {
			Position = UDim2.fromOffset(12, 50),
			Size = UDim2.new(0.6, -12, 0, 16),
			BackgroundColor3 = Color3.fromRGB(25, 27, 38),
		}, row)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)
		create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, bar)
		local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(110, 255, 140), BorderSizePixel = 0 }, bar)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
		local amount = makeText(bar, { Position = UDim2.fromScale(0.05, 0.05), Size = UDim2.fromScale(0.9, 0.9), Text = "", TextColor3 = Color3.new(1, 1, 1), ZIndex = 2 }, 1.2)
		makeText(row, {
			Position = UDim2.new(0.6, 6, 0, 6),
			Size = UDim2.new(0.4, -16, 0, 24),
			Text = `🎁 {rewardText(quest.rewards)}`,
			TextColor3 = Color3.fromRGB(255, 225, 110),
		}, 2)
		local button, buttonLabel = claimButton(row, UDim2.new(0.6, 6, 0, 36), UDim2.new(0.4, -16, 0, 30))
		button.MouseButton1Click:Connect(function()
			invoke("ClaimStarter", quest.id)
		end)
		starterRows[quest.id] = { frame = row, title = title, fill = fill, amount = amount, button = button, buttonLabel = buttonLabel, quest = quest }
	end

	local function renderStarter()
		local state = QuestPanel.readStarter(player)
		local ready = 0
		local open = 0
		for _, row in starterRows do
			local entry = state[row.quest.id] or { progress = 0, done = false, claimed = false }
			local progress = math.min(entry.progress, row.quest.goal)
			row.fill.Size = UDim2.fromScale(math.clamp(progress / row.quest.goal, 0, 1), 1)
			row.amount.Text = `{progress} / {row.quest.goal}`
			row.title.Text = if entry.done then `✔ {row.quest.text}` else row.quest.text
			if entry.claimed then
				styleClaim(row.button, row.buttonLabel, "claimed")
				row.frame.BackgroundColor3 = Color3.fromRGB(58, 63, 82)
			else
				open += 1
				if entry.done then
					ready += 1
				end
				styleClaim(row.button, row.buttonLabel, if entry.done then "ready" else "progress")
				row.frame.BackgroundColor3 = if entry.done then Color3.fromRGB(48, 96, 66) else Color3.fromRGB(58, 63, 82) -- ödülü alınmayı bekleyen satır yeşilimsi
			end
		end
		tabs.starter.dot.Visible = ready > 0
		return open
	end

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
		-- DAILY sekmesindeki nokta: alınmayı bekleyen günlük ödül varsa yanar
		local dailyReady = 0
		for _, quest in data.quests do
			if not quest.claimed and quest.progress >= quest.goal then
				dailyReady += 1
			end
		end
		tabs.daily.dot.Visible = dailyReady > 0
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

	local function renderAll()
		render()
		renderStarter()
	end

	-- Sekme değiştir: yalnız seçilen listenin içeriği görünür; geri sayım yazısı sadece DAILY'de
	local function setTab(name)
		currentTab = name
		list.Visible = name == "daily"
		starterList.Visible = name == "starter"
		timerText.Visible = name == "daily"
		for tabName, tab in tabs do
			local active = tabName == name
			tab.button.BackgroundColor3 = if active then tab.color else Color3.fromRGB(80, 84, 104)
			tab.label.TextTransparency = if active then 0 else 0.35
		end
		renderAll()
	end
	starterTab.MouseButton1Click:Connect(function()
		setTab("starter")
	end)
	dailyTab.MouseButton1Click:Connect(function()
		setTab("daily")
	end)
	setTab("daily")

	for _, name in { "QuestData", "StarterState" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if PanelManager.isOpen(panel) then
				renderAll()
			end
		end)
	end

	-- Açıkken geri sayım saniyede bir güncellenir
	task.spawn(function()
		while true do
			if PanelManager.isOpen(panel) then
				updateTimer()
			end
			task.wait(1)
		end
	end)

	local openedOnce = false
	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			-- Alınmayı bekleyen yeni oyuncu ödülü varsa HER açılışta NEW PLAYER sekmesi açılır ve o satıra kaydırılır (ödül sessizce verilmez: oyuncu buradan CLAIM eder; rehber/üst şerit buraya yönlendirir).
			-- Yoksa ilk açılışta alınmamış yeni oyuncu görevi varsa NEW PLAYER (yeni oyuncu doğrudan görür), yoksa DAILY.
			local state = QuestPanel.readStarter(player)
			local anyOpen = false
			local firstReady = nil
			for index, quest in Config.StarterQuests do
				local entry = state[quest.id]
				if not entry or not entry.claimed then
					anyOpen = true
				end
				if entry and entry.done and not entry.claimed and not firstReady then
					firstReady = index
				end
			end
			if firstReady or not openedOnce then
				openedOnce = true
				setTab(if anyOpen then "starter" else "daily")
			else
				renderAll()
			end
			if firstReady then
				-- (Tuval boyutu liste görünür olduktan sonra hesaplanır: bir an sonra kaydır)
				task.delay(0.05, function()
					starterList.CanvasPosition = Vector2.new(0, math.max(0, (firstReady - 1) * 80 - 4))
				end)
			end
		end
	end
end

return QuestPanel
