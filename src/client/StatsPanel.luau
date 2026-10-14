-- Stats penceresi: oyuncunun sayıları ve kazanç çarpanının DÖKÜMÜ (pet, level, rebirth, skin, aura, güçlendirme, arkadaş, Index).
-- Sağ üstteki grafik düğmesiyle açılır. Her şey sunucunun yazdığı özniteliklerden okunur; burası sadece gösterir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Progression = require(Shared:WaitForChild("Progression"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local StatsPanel = {}

local Theme = UIStyle.Theme
local C = Theme.colors

local function mult(value)
	return `x{Format.multiplier(value)}`
end

-- Döner: pencereyi açıp kapatan fonksiyon
function StatsPanel.init(screenGui)
	local player = Players.LocalPlayer
	local leaderstats = player:WaitForChild("leaderstats")

	local function attr(name, default)
		return player:GetAttribute(name) or default
	end

	local WIDTH, PAD = 440, 16
	local ROW_H, ROW_GAP = 28, 3

	-- Kaynak satırları: { ad, emoji, değer fonksiyonu, etkin mi fonksiyonu }; etkin değilse sönük görünür
	local sources = {
		{ "Level", "⭐", function() return mult(Progression.levelMultiplier(leaderstats[Config.StatLevel].Value)) end, function() return Progression.levelMultiplier(leaderstats[Config.StatLevel].Value) > 1 end },
		{ "Rebirth", "🔁", function() return mult(Progression.rebirthMultiplier(leaderstats[Config.StatRebirths].Value)) end, function() return Progression.rebirthMultiplier(leaderstats[Config.StatRebirths].Value) > 1 end },
		{ "Aura", "✨", function()
			local aura = Catalog.AuraById[attr("EquippedAura", "")]
			return mult(if aura then aura.mult else 1)
		end, function() return Catalog.AuraById[attr("EquippedAura", "")] ~= nil end },
		{ "Pets", "🐾", function() return mult(attr("PetMultiplier", 1)) end, function() return attr("PetMultiplier", 1) > 1 end },
		{ "Skin", "🎨", function() return `+{Format.compact(attr("SkinBonus", 0))} / click` end, function() return attr("SkinBonus", 0) > 0 end },
		{ "Friends", "👥", function() return `+{attr("FriendBonus", 0)}%` end, function() return attr("FriendBonus", 0) > 0 end },
		{ "Mastery", "🎓", function() return `+{attr("MasteryPower", 0)}%` end, function() return attr("MasteryPower", 0) > 0 end },
		{ "Pet Index", "📖", function() return `+{attr("IndexBonus", 0)}%` end, function() return attr("IndexBonus", 0) > 0 end },
		{ "Potion", "🧪", function()
			local left = math.max(attr("MuscleBoostUntil", 0), attr("RainbowBoostUntil", 0)) - os.time() -- Rainbow Potion da Muscle Potion sayılır
			return if left > 0 then `x2 ({math.ceil(left / 60)}m left)` else "off"
		end, function() return math.max(attr("MuscleBoostUntil", 0), attr("RainbowBoostUntil", 0)) - os.time() > 0 end },
	}

	-- Üstteki dört küçük sayı: { başlık, değer fonksiyonu, renk }
	local minis = {
		{ "MUSCLE", function() return Format.number(leaderstats[Config.StatLegMuscle].Value) end, C.primary.base },
		{ "LEVEL", function() return `{leaderstats[Config.StatLevel].Value}/{attr("MaxLevel", "?")}` end, C.text },
		{ "REBIRTHS", function() return Format.number(leaderstats[Config.StatRebirths].Value) end, C.hot.base },
		{ "WINS", function() return Format.number(leaderstats[Config.StatWins].Value) end, C.primary.base },
	}

	local TOTAL_Y, TOTAL_H = 72, 88
	local MINI_Y, MINI_H = TOTAL_Y + TOTAL_H + 8, 48
	local SECTION_Y = MINI_Y + MINI_H + 10
	local ROWS_Y = SECTION_Y + 22
	local BOTTOM_Y = ROWS_Y + #sources * (ROW_H + ROW_GAP) + 5
	local BOTTOM_H = 58
	local height = BOTTOM_Y + BOTTOM_H + PAD

	local panel = UIStyle.panel(screenGui, {
		name = "StatsPanel",
		size = UDim2.fromOffset(WIDTH, height),
		accent = "info",
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
	})
	panel.Visible = false -- Active = true UIStyle.panel'de: pencereye tıklamak hareket başlatmasın

	UIStyle.header(panel, {
		title = "Stats",
		icon = Config.Icons.Stats,
		emoji = "📊",
		accent = "info",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	-- Büyük TOPLAM kartı
	local totalCard = UIStyle.card(panel, { name = "TotalCard", accent = "info", padding = false, size = UDim2.new(1, -PAD * 2, 0, TOTAL_H), position = UDim2.fromOffset(PAD, TOTAL_Y) })
	UIStyle.label(totalCard, { name = "TotalCaption", text = "TOTAL MULTIPLIER", role = "caption", color = C.info.base, props = { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 16) } })
	local totalValue = UIStyle.label(totalCard, { name = "TotalValue", text = "x1", role = "title", size = 36, color = C.text, props = { Position = UDim2.fromOffset(16, 28), Size = UDim2.new(1, -32, 0, 44) } })
	local totalNote = UIStyle.label(totalCard, { name = "TotalNote", text = "", role = "caption", align = "right", props = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -12), Size = UDim2.new(0.6, 0, 0, 16) } })

	-- Dört küçük sayı kartı
	local miniGap = 8
	local miniW = (WIDTH - PAD * 2 - miniGap * 3) / 4
	local miniValues = {}
	for index, mini in minis do
		local card = UIStyle.card(panel, { name = `Mini_{index}`, padding = false, size = UDim2.fromOffset(miniW, MINI_H), position = UDim2.fromOffset(PAD + (index - 1) * (miniW + miniGap), MINI_Y) })
		UIStyle.label(card, { name = "MiniCaption", text = mini[1], role = "caption", size = 10, align = "center", props = { Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 14) } })
		miniValues[index] = UIStyle.label(card, { name = "MiniValue", text = "-", role = "bold", size = 16, align = "center", color = mini[3], props = { Position = UDim2.fromOffset(4, 22), Size = UDim2.new(1, -8, 0, 20) } })
	end

	UIStyle.label(panel, { name = "SourcesCaption", text = "WHERE IT COMES FROM", role = "caption", props = { Position = UDim2.fromOffset(PAD + 4, SECTION_Y), Size = UDim2.new(1, -PAD * 2, 0, 16) } })

	-- Kaynak satırları
	local rowLabels = {}
	for index, source in sources do
		local row = UIStyle.card(panel, { name = `Source_{index}`, padding = false, size = UDim2.new(1, -PAD * 2, 0, ROW_H), position = UDim2.fromOffset(PAD, ROWS_Y + (index - 1) * (ROW_H + ROW_GAP)) })
		local iconChip = Instance.new("Frame")
		iconChip.Name = "IconChip"
		iconChip.BackgroundColor3 = C.info.base
		iconChip.BackgroundTransparency = 0.82
		iconChip.BorderSizePixel = 0
		iconChip.Position = UDim2.fromOffset(6, 3)
		iconChip.Size = UDim2.fromOffset(22, 22)
		iconChip.Parent = row
		UIStyle.round(iconChip, 6)
		UIStyle.label(iconChip, { name = "Icon", text = source[2], role = "caption", size = 13, align = "center", props = { Size = UDim2.fromScale(1, 1) } })
		local nameLabel = UIStyle.label(row, { name = "RowName", text = source[1], role = "body", size = 14, props = { Position = UDim2.fromOffset(36, 0), Size = UDim2.new(0.45, -36, 1, 0) } })
		local valueLabel = UIStyle.label(row, { name = "RowValue", text = "-", role = "bold", size = 14, align = "right", props = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.55, -10, 1, 0) } })
		rowLabels[index] = { row = row, name = nameLabel, value = valueLabel, icon = iconChip }
	end

	-- Alt iki küçük kart: tıklama başı kas, duvar hasarı
	local halfW = (WIDTH - PAD * 2 - 8) / 2
	local bottomDefs = {
		{ "Per click", "PerClick", function() return `+{Format.number(attr("PerClick", 1))}` end, C.success.base },
		{ "Wall damage", "WallDamage", function() return mult(attr("DamageMultiplier", 1)) end, C.warn.base },
	}
	local bottomValues = {}
	for index, def in bottomDefs do
		local card = UIStyle.card(panel, { name = def[2], padding = false, size = UDim2.fromOffset(halfW, BOTTOM_H), position = UDim2.fromOffset(PAD + (index - 1) * (halfW + 8), BOTTOM_Y) })
		UIStyle.label(card, { name = "BottomCaption", text = string.upper(def[1]), role = "caption", size = 11, props = { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 14) } })
		bottomValues[index] = UIStyle.label(card, { name = "BottomValue", text = "-", role = "title", size = 24, color = def[4], props = { Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -28, 0, 28) } })
	end

	local function refresh()
		for index, mini in minis do
			local ok, value = pcall(mini[2])
			miniValues[index].Text = if ok then value else "-"
		end
		for index, source in sources do
			local entry = rowLabels[index]
			local ok, value = pcall(source[3])
			entry.value.Text = if ok then value else "-"
			local okActive, active = pcall(source[4])
			local on = okActive and active
			entry.value.TextColor3 = if on then C.text else C.textMute
			entry.name.TextColor3 = if on then C.text else C.textMute
			entry.icon.BackgroundTransparency = if on then 0.82 else 0.95
		end
		for index, def in bottomDefs do
			local ok, value = pcall(def[3])
			bottomValues[index].Text = if ok then value else "-"
		end
		-- TOPLAM: antrenman pedinin çarpanı da dahil
		local area = attr("AreaMultiplier", 1)
		local total = attr("TotalMultiplier", 1) * area
		totalValue.Text = mult(total)
		totalNote.Text = if area > 1 then `incl. training area x{string.format("%g", area)}` else ""
	end

	-- Açıkken saniyede bir güncellenir (süreli güçlendirme geri sayımı için); ayrıca değerler değişince
	task.spawn(function()
		while true do
			if PanelManager.isOpen(panel) then
				refresh()
			end
			task.wait(1)
		end
	end)

	return function()
		PanelManager.toggle(panel)
		if PanelManager.isOpen(panel) then
			refresh()
		end
	end
end

return StatsPanel
