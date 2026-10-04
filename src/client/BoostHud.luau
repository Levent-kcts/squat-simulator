-- Aktif süreli güçlendirmelerin (2x Muscle, 2x Wins) geri sayımı: sol üstte, Win sayacının altında küçük çipler. Süre bitince kaybolur.
-- Bitiş zamanını sunucu verir (MuscleBoostUntil / WinBoostUntil, sunucu saati); sadece görsel.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BoostHud = {}

local BOOSTS = {
	{ attribute = "MuscleBoostUntil", icon = "⚡", label = "2x Muscle", color = Color3.fromRGB(255, 160, 50) },
	{ attribute = "WinBoostUntil", icon = "🏆", label = "2x Wins", color = Color3.fromRGB(255, 215, 70) },
}
local FIRST_X = 182 -- Rebirth ve Win sayaçlarının hemen sağı (sol buton ızgarasıyla çakışmasın)
local FIRST_Y = 64

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
	props.Font = Enum.Font.FredokaOne
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- 75 -> "1:15"
local function clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function BoostHud.init(screenGui)
	local player = Players.LocalPlayer

	local chips = {}
	for index, boost in BOOSTS do
		local chip = create("Frame", {
			Position = UDim2.fromOffset(FIRST_X, FIRST_Y + (index - 1) * 46),
			Size = UDim2.fromOffset(160, 38),
			BackgroundColor3 = Color3.fromRGB(25, 25, 32),
			BackgroundTransparency = 0.2,
			Visible = false,
		}, screenGui)
		create("UICorner", { CornerRadius = UDim.new(0, 19) }, chip)
		create("UIStroke", { Thickness = 2, Color = boost.color }, chip)
		text(chip, { Position = UDim2.fromOffset(8, 2), Size = UDim2.fromOffset(30, 34), Text = boost.icon }, 0)
		local label = text(chip, {
			Position = UDim2.fromOffset(42, 3),
			Size = UDim2.new(1, -50, 1, -6),
			Text = boost.label,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, 2)
		table.insert(chips, { boost = boost, chip = chip, label = label })
	end

	local function refresh()
		local now = Workspace:GetServerTimeNow()
		for _, entry in chips do
			local untilTime = player:GetAttribute(entry.boost.attribute)
			local remaining = if type(untilTime) == "number" then untilTime - now else 0
			entry.chip.Visible = remaining > 0
			if remaining > 0 then
				entry.label.Text = `{entry.boost.label} {clock(remaining)}`
			end
		end
	end

	task.spawn(function()
		while true do
			refresh()
			task.wait(0.5)
		end
	end)
end

return BoostHud
