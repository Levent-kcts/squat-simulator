-- İKSİRLER (Config.Potions): etkin iksirler EKRANIN SOL ALTINDA şişe simgesi + geri sayımla görünür (Luck, Muscle, Wins ve hepsini birden veren Rainbow).
-- Bitiş zamanını sunucu verir (LuckBoostUntil, MuscleBoostUntil, WinBoostUntil, RainbowBoostUntil; sunucu saati); sadece görsel. Süre bitince şişe kaybolur,
-- kalanlar sola kayar. Son 10 saniyede geri sayım kırmızı yanıp söner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UIStyle = require(script.Parent.UIStyle)

local BoostHud = {}

local SLOT_WIDTH = 64
local SLOT_HEIGHT = 84
local MARGIN = 12

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- 75 -> "1:15"
local function clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function BoostHud.init(screenGui)
	local player = Players.LocalPlayer

	local slots = {}
	for _, potion in Config.Potions.List do
		local slot = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Size = UDim2.fromOffset(SLOT_WIDTH, SLOT_HEIGHT),
			BackgroundTransparency = 1,
			Visible = false,
			Name = "Potion_" .. potion.id,
		}, screenGui)
		UIStyle.potionIcon(slot, potion, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.fromOffset(58, 58),
		})
		local label = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			Text = "",
			TextColor3 = Color3.new(1, 1, 1),
		}, slot)
		create("UIStroke", { Thickness = 2.5, Color = Color3.new(0, 0, 0) }, label)
		table.insert(slots, { potion = potion, slot = slot, label = label })
	end

	local function refresh()
		local now = Workspace:GetServerTimeNow()
		local shown = 0
		for _, entry in slots do
			local untilTime = player:GetAttribute(entry.potion.attribute)
			local remaining = if type(untilTime) == "number" then untilTime - now else 0
			entry.slot.Visible = remaining > 0
			if remaining > 0 then
				entry.slot.Position = UDim2.new(0, MARGIN + shown * (SLOT_WIDTH + 6), 1, -MARGIN)
				shown += 1
				entry.label.Text = clock(remaining)
				entry.label.TextColor3 = if remaining <= 10 and math.floor(remaining * 2) % 2 == 0 then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
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
