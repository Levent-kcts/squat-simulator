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

local function mult(value)
	return `x{string.format("%.2f", value)}`
end

-- Döner: pencereyi açıp kapatan fonksiyon
function StatsPanel.init(screenGui)
	local player = Players.LocalPlayer
	local leaderstats = player:WaitForChild("leaderstats")

	local ROW_HEIGHT, GAP = 24, 3
	-- Satırlar: { başlık, değer fonksiyonu -> yazı, renk }; null başlık = ayraç yazısı
	local rows = {
		{ "Leg Muscle", function() return Format.number(leaderstats[Config.StatLegMuscle].Value) end, Color3.fromRGB(255, 225, 90) },
		{ "Level", function() return `{leaderstats[Config.StatLevel].Value} / {player:GetAttribute("MaxLevel") or "?"}` end, Color3.new(1, 1, 1) },
		{ "Rebirths", function() return Format.number(leaderstats[Config.StatRebirths].Value) end, Color3.new(1, 1, 1) },
		{ "Wins", function() return Format.number(leaderstats[Config.StatWins].Value) end, Color3.fromRGB(255, 215, 70) },
		{ "Muscle per click", function() return `+{Format.number(player:GetAttribute("PerClick") or 1)}` end, Color3.fromRGB(110, 255, 140) },
		{ "Damage multiplier", function() return mult(player:GetAttribute("DamageMultiplier") or 1) end, Color3.fromRGB(255, 160, 120) },
		{ "-- MULTIPLIER BREAKDOWN --" },
		{ "Pets", function() return mult(player:GetAttribute("PetMultiplier") or 1) end, Color3.new(1, 1, 1) },
		{ "Level", function() return mult(Progression.levelMultiplier(leaderstats[Config.StatLevel].Value)) end, Color3.new(1, 1, 1) },
		{ "Rebirth", function() return mult(Progression.rebirthMultiplier(leaderstats[Config.StatRebirths].Value)) end, Color3.new(1, 1, 1) },
		{ "Skin", function() return mult(player:GetAttribute("SkinMultiplier") or 1) end, Color3.new(1, 1, 1) },
		{ "Aura", function()
			local aura = Catalog.AuraById[player:GetAttribute("EquippedAura") or ""]
			return mult(if aura then aura.mult else 1)
		end, Color3.new(1, 1, 1) },
		{ "2x Muscle boost", function()
			local left = (player:GetAttribute("MuscleBoostUntil") or 0) - os.time()
			return if left > 0 then `x2  ({math.ceil(left / 60)}m left)` else "off"
		end, Color3.new(1, 1, 1) },
		{ "Friends", function() return `+{player:GetAttribute("FriendBonus") or 0}%` end, Color3.fromRGB(120, 255, 140) },
		{ "Pet Index", function() return `+{player:GetAttribute("IndexBonus") or 0}%` end, Color3.fromRGB(120, 255, 140) },
		{ "TOTAL", function()
			local area = player:GetAttribute("AreaMultiplier") or 1
			local total = (player:GetAttribute("TotalMultiplier") or 1) * area
			return if area > 1 then `{mult(total)}  (training area x{string.format("%g", area)})` else mult(total)
		end, Color3.fromRGB(255, 225, 90) },
	}

	local height = 68 + #rows * (ROW_HEIGHT + GAP) + 14
	local panel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, height),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true, -- pencereye tıklamak hareket başlatmasın
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(440, height), MinSize = Vector2.new(300, height) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Color3.fromRGB(70, 160, 255),
	}, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	text(header, {
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -90, 1, -16),
		Text = "📊 STATS",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
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

	local valueLabels = {}
	for index, row in rows do
		local y = 66 + (index - 1) * (ROW_HEIGHT + GAP)
		if row[2] == nil then
			-- Ayraç başlığı
			text(panel, {
				Position = UDim2.fromOffset(12, y),
				Size = UDim2.new(1, -24, 0, ROW_HEIGHT),
				Text = row[1],
				TextColor3 = Color3.fromRGB(170, 180, 225),
			}, 2)
		else
			local box = create("Frame", {
				Position = UDim2.fromOffset(12, y),
				Size = UDim2.new(1, -24, 0, ROW_HEIGHT),
				BackgroundColor3 = Color3.fromRGB(58, 63, 82),
			}, panel)
			UIStyle.soften(box, { radius = 8, strength = 0.1, shine = false })
			text(box, {
				Position = UDim2.fromOffset(10, 3),
				Size = UDim2.new(0.5, -10, 1, -6),
				Text = row[1],
				TextColor3 = Color3.fromRGB(215, 220, 240),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, 1.5)
			valueLabels[index] = text(box, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 3),
				Size = UDim2.new(0.55, -10, 1, -6),
				TextColor3 = row[3],
				TextXAlignment = Enum.TextXAlignment.Right,
			}, 1.5)
		end
	end

	local function refresh()
		for index, row in rows do
			local label = valueLabels[index]
			if label then
				local ok, value = pcall(row[2])
				label.Text = if ok then value else "-"
			end
		end
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
