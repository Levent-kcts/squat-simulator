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

local Theme = UIStyle.Theme
local COLORS = Theme.colors

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Görev simgeleri (sadece görünüm; bilinmeyen id için yedek yıldız)
local STARTER_ICONS = {
	squat = "🦵", pet = "🐾", skin = "🎨", wall = "🧱", shoes = "👟",
	level10 = "⬆️", gift = "🎁", train = "💪", rebirth = "🔄", wheel = "🎡",
}

-- Yazı: UIStyle.label kısayolu (sabit boyut, props ile konum/boyut)
local function text(parent, content, role, props)
	return UIStyle.label(parent, { text = content, role = role, props = props })
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
local function rewardText(rewards, ownsAutoPass)
	local parts = {}
	for _, reward in rewards do
		if reward.kind == "wins" then
			table.insert(parts, `+{reward.amount} Wins`)
		else
			-- (Auto Click game pass'i olana Auto Click Potion yerine Rainbow: Catalog.ownerPotion)
			local kind, minutes = Catalog.ownerPotion(reward.kind, reward.minutes, ownsAutoPass)
			local potion = Catalog.PotionByKind[kind]
			table.insert(parts, `{if potion then potion.name else "Potion"} {(potion and potion.fixedMinutes) or minutes or Config.BoostMinutes}m`)
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

	local panel = UIStyle.panel(screenGui, {
		name = "QuestPanel",
		width = 620,
		height = 540, -- (sekmeler için biraz yüksek)
		accent = "info",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})
	panel.Visible = false

	local header = UIStyle.header(panel, {
		title = "Quests",
		icon = Config.Icons.Quests,
		emoji = "📜",
		accent = "info",
		chip = "",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})
	local timerChip = header and header.chip
	local function setTimer(content)
		if timerChip then
			UIStyle.setChipText(timerChip, content)
			timerChip.Visible = content ~= ""
		end
	end
	setTimer("")

	-- SEKMELER (2026-10-13, sahibi 'görevlere yeni oyuncu görevleri sekmesi' istedi): NEW PLAYER (Config.StarterQuests, ilk rebirth'e kadar rehber) ve DAILY
	local setTab
	local tabApi = UIStyle.tabs(panel, {
		items = { { id = "starter", text = "NEW PLAYER" }, { id = "daily", text = "DAILY" } },
		accent = "info",
		selected = "daily",
		props = { Position = UDim2.fromOffset(16, 72), Size = UDim2.new(1, -32, 0, 44) },
		onSelect = function(id)
			setTab(id)
		end,
	})
	local tabs = {}
	for _, name in { "starter", "daily" } do
		local host = tabApi.buttons[name] or tabApi.frame
		-- alınabilir ödül varsa sekmede yeşil nokta
		local dot = create("Frame", {
			Name = "Dot",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = COLORS.success.base,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
		}, host)
		UIStyle.round(dot, UDim.new(0.5, 0))
		tabs[name] = { dot = dot }
	end

	local CONTENT_POS = UDim2.fromOffset(16, 128)
	local CONTENT_SIZE = UDim2.new(1, -32, 1, -140)
	local ROW_HEIGHT = 84
	local list = create("Frame", { Position = CONTENT_POS, Size = CONTENT_SIZE, BackgroundTransparency = 1 }, panel)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	-- YENİ OYUNCU görev listesi (kaydırılır): her satır görevin adı, nerede/nasıl yapılacağı (hint), ilerleme çubuğu, ödül ve CLAIM
	local starterList = create("ScrollingFrame", {
		Name = "StarterList",
		Position = CONTENT_POS,
		Size = CONTENT_SIZE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, panel)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, starterList)

	local function invoke(action, id)
		task.spawn(function()
			local ok, message = shopFunction:InvokeServer(action, id)
			showToast(ok, message or "")
			if ok and okSfx then
				pcall(Sfx.play, "Win") -- ödül alındı sesi
			end
		end)
	end

	-- CLAIM düğmesi: gerçek TextButton (UIStyle.button). Adı 'TextButton' kalır (ctest satırdaki 'TextButton'a tıklar).
	local function claimButton(parent, onClick)
		local button = UIStyle.button(parent, {
			name = "TextButton",
			text = "In progress",
			kind = "secondary",
			size = "sm",
			width = 132,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, 0, 0, 40),
			onClick = onClick,
		})
		if button then
			-- Hazır ödülün altın çerçevesi ('Stroke'): sadece "ready" durumunda açık
			local stroke = create("UIStroke", {
				Name = "Stroke",
				Thickness = 2,
				Color = COLORS.primary.base,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Enabled = false,
			}, button)
			return button, stroke
		end
		return nil
	end

	local function styleClaim(button, stroke, state)
		if not button then
			return
		end
		if stroke then
			stroke.Enabled = state == "ready"
		end
		if state == "ready" then
			UIStyle.setButtonKind(button, "success")
			UIStyle.setButtonEnabled(button, true)
			UIStyle.setButtonText(button, "CLAIM!")
		elseif state == "claimed" then
			UIStyle.setButtonKind(button, "secondary")
			UIStyle.setButtonEnabled(button, false)
			UIStyle.setButtonText(button, "CLAIMED")
		else
			UIStyle.setButtonKind(button, "secondary")
			UIStyle.setButtonEnabled(button, false)
			UIStyle.setButtonText(button, "In progress")
		end
	end

	-- Satır zemini: hazır (yeşilimsi) / sürüyor / alındı (sönük)
	local function styleRow(card, iconChip, titleLabel, state)
		if not card then
			return
		end
		if state == "ready" then
			card.BackgroundColor3 = COLORS.card:Lerp(COLORS.success.base, 0.2)
			card.BackgroundTransparency = 0
		elseif state == "claimed" then
			card.BackgroundColor3 = COLORS.card
			card.BackgroundTransparency = 0.55
		else
			card.BackgroundColor3 = COLORS.card
			card.BackgroundTransparency = 0
		end
		if iconChip then
			iconChip.BackgroundColor3 = if state == "ready" then COLORS.success.base elseif state == "claimed" then COLORS.cardDeep else COLORS.info.base
			iconChip.BackgroundTransparency = if state == "claimed" then 0.3 else 0.75
		end
		if titleLabel then
			titleLabel.TextColor3 = if state == "claimed" then COLORS.textMute else COLORS.text
		end
	end

	-- Sol görev simgesi çipi (emoji); alınınca tik gösterir
	local function iconChipFor(card, emoji)
		local chip = create("Frame", {
			Name = "IconChip",
			Position = UDim2.new(0, 0, 0.5, -22),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = COLORS.info.base,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		}, card)
		UIStyle.round(chip, Theme.radius.button)
		local glyph = text(chip, emoji, "bold", { Name = "Glyph", Size = UDim2.fromScale(1, 1), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center })
		return chip, glyph
	end

	-- Satır iskeleti (kart + simge + ad + çubuk + ödül + CLAIM); kart padding'siz, içerik mutlak konumlu
	local MID_WIDTH = -(44 + 12 + 144 + 8)
	local function buildRow(parent, props)
		local card = UIStyle.card(parent, { name = props.name, size = UDim2.new(1, props.inset or 0, 0, ROW_HEIGHT), padding = false, props = { LayoutOrder = props.order } })
		create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, card)
		local chip, glyph = iconChipFor(card, props.emoji)
		local title = text(card, props.title or "", "bold", { Name = "Title", Position = UDim2.fromOffset(56, if props.hint then 10 else 18), Size = UDim2.new(1, MID_WIDTH, 0, 20) })
		local hint = nil
		if props.hint then
			hint = text(card, props.hint, "caption", { Name = "Hint", Position = UDim2.fromOffset(56, 31), Size = UDim2.new(1, MID_WIDTH, 0, 16) })
		end
		local bar = UIStyle.progressBar(card, {
			accent = "success",
			name = "Progress",
			props = { Position = UDim2.fromOffset(56, if props.hint then 54 else 46), Size = UDim2.new(1, MID_WIDTH, 0, 16) },
		})
		local reward = text(card, props.reward or "", "caption", {
			Name = "Reward",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 8),
			Size = UDim2.fromOffset(144, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLORS.primary.base,
			TextWrapped = true,
			TextSize = 12,
		})
		local button, stroke = claimButton(card, props.onClick)
		return { card = card, chip = chip, glyph = glyph, title = title, hint = hint, bar = bar, reward = reward, button = button, stroke = stroke }
	end

	-- 3 görev satırı + bonus satırı bir kez kurulur, render sadece değerleri günceller
	local rows = {}
	for slot = 1, 3 do
		rows[slot] = buildRow(list, {
			name = "Daily_" .. slot,
			order = slot,
			emoji = "📜",
			onClick = function()
				invoke("ClaimQuest", slot)
			end,
		})
	end

	-- BONUS satırı: altın çerçeveli kart
	local bonusCard = UIStyle.card(list, { name = "BonusRow", size = UDim2.new(1, 0, 0, ROW_HEIGHT), padding = false, accent = "primary", selected = true, props = { LayoutOrder = 4 } })
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, bonusCard)
	local bonusChip, bonusGlyph = iconChipFor(bonusCard, "⭐")
	bonusChip.BackgroundColor3 = COLORS.primary.base
	text(bonusCard, "BONUS: finish all 3 quests", "bold", { Name = "Title", Position = UDim2.fromOffset(56, 18), Size = UDim2.new(1, MID_WIDTH, 0, 20), TextColor3 = COLORS.primary.base })
	local bonusReward = text(bonusCard, "", "caption", { Name = "Reward", Position = UDim2.fromOffset(56, 44), Size = UDim2.new(1, MID_WIDTH, 0, 20) })
	local bonusButton, bonusStroke = claimButton(bonusCard, function()
		invoke("ClaimQuestBonus", "")
	end)
	if bonusButton then
		bonusButton.Position = UDim2.new(1, 0, 0.5, -18)
	end

	-- Yeni oyuncu satırları bir kez kurulur; renderStarter sadece değerleri günceller
	local starterRows = {}
	for index, quest in Config.StarterQuests do
		local row = buildRow(starterList, {
			name = "Starter_" .. quest.id,
			order = index,
			inset = -8, -- (kaydırma çubuğuna pay)
			emoji = STARTER_ICONS[quest.id] or "⭐",
			title = quest.text,
			hint = quest.hint,
			reward = `🎁 {rewardText(quest.rewards, player:GetAttribute("HasAutoClick") == true)}`,
			onClick = function()
				invoke("ClaimStarter", quest.id)
			end,
		})
		row.quest = quest
		starterRows[quest.id] = row
	end

	local function renderStarter()
		local state = QuestPanel.readStarter(player)
		local ready = 0
		local open = 0
		local hasAuto = player:GetAttribute("HasAutoClick") == true -- Auto Click game pass'i olana Auto Click Potion yerine Rainbow görünür
		for _, row in starterRows do
			local entry = state[row.quest.id] or { progress = 0, done = false, claimed = false }
			row.reward.Text = `🎁 {rewardText(row.quest.rewards, hasAuto)}`
			local progress = math.min(entry.progress, row.quest.goal)
			row.bar.set(math.clamp(progress / row.quest.goal, 0, 1), `{progress} / {row.quest.goal}`)
			row.title.Text = if entry.done then `✔ {row.quest.text}` else row.quest.text
			if entry.claimed then
				styleClaim(row.button, row.stroke, "claimed")
				styleRow(row.card, row.chip, row.title, "claimed")
				row.glyph.Text = "✔"
			else
				open += 1
				if entry.done then
					ready += 1
				end
				styleClaim(row.button, row.stroke, if entry.done then "ready" else "progress")
				styleRow(row.card, row.chip, row.title, if entry.done then "ready" else "progress") -- ödülü alınmayı bekleyen satır yeşilimsi
				row.glyph.Text = STARTER_ICONS[row.quest.id] or "⭐"
			end
		end
		tabs.starter.dot.Visible = ready > 0
		return open
	end

	local resetAt = 0

	local function updateTimer()
		if resetAt > 0 then
			setTimer(`New quests in {formatTime(resetAt - Workspace:GetServerTimeNow())}`)
		else
			setTimer("")
		end
	end

	local function render()
		local data = QuestPanel.read(player)
		if not data or not data.quests then
			setTimer("Loading...")
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
				row.bar.set(math.clamp(progress / quest.goal, 0, 1), `{progress} / {quest.goal}`)
				row.reward.Text = `🎁 {quest.reward}`
				if quest.claimed then
					styleClaim(row.button, row.stroke, "claimed")
					styleRow(row.card, row.chip, row.title, "claimed")
					row.glyph.Text = "✔"
				else
					allClaimed = false
					local isReady = progress >= quest.goal
					styleClaim(row.button, row.stroke, if isReady then "ready" else "progress")
					styleRow(row.card, row.chip, row.title, if isReady then "ready" else "progress")
					row.glyph.Text = "📜"
				end
			end
		end
		bonusReward.Text = data.bonusText or ""
		if data.bonusClaimed then
			styleClaim(bonusButton, bonusStroke, "claimed")
			bonusGlyph.Text = "✔"
		elseif allClaimed then
			styleClaim(bonusButton, bonusStroke, "ready")
			bonusGlyph.Text = "⭐"
		else
			styleClaim(bonusButton, bonusStroke, "progress")
			bonusGlyph.Text = "⭐"
		end
		updateTimer()
	end

	local function renderAll()
		render()
		renderStarter()
	end

	-- Sekme değiştir: yalnız seçilen listenin içeriği görünür; geri sayım çipi sadece DAILY'de
	setTab = function(name)
		tabApi.select(name, true)
		list.Visible = name == "daily"
		starterList.Visible = name == "starter"
		renderAll()
		if name == "daily" then
			updateTimer()
		else
			setTimer("")
		end
	end
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
			if PanelManager.isOpen(panel) and list.Visible then
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
					starterList.CanvasPosition = Vector2.new(0, math.max(0, (firstReady - 1) * (ROW_HEIGHT + 8) - 4))
				end)
			end
		end
	end
end

return QuestPanel
