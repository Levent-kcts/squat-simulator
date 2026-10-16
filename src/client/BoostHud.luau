-- İKSİRLER (Config.Potions): etkin iksirler EKRANIN SOL ALTINDA şişe simgesi + geri sayımla görünür (Luck, Muscle, Wins ve hepsini birden veren Rainbow).
-- Bitiş zamanını sunucu verir (LuckBoostUntil, MuscleBoostUntil, WinBoostUntil, RainbowBoostUntil; sunucu saati); sadece görsel. Süre bitince şişe kaybolur,
-- kalanlar sola kayar. Son 10 saniyede geri sayım kırmızı yanıp söner. Şişenin ÜZERİNE GELİNCE (dokunmatikte tıklayınca) beyaz bir kutu açılır: iksirin adı, açıklaması ve kalan süre.
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
	local hovered = nil -- açıklama kutusu şu an hangi iksir için açık
	local updateTooltip -- aşağıda tanımlanır (olay işleyicileri de çağırır)

	-- Beyaz açıklama kutusu (şişenin hemen üstünde): ad, açıklama, kalan süre
	local tooltip = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(214, 92),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		ZIndex = 30,
		Name = "PotionTooltip",
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, tooltip)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, tooltip)
	local function tipText(position, size, font, color)
		return create("TextLabel", {
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			Font = font,
			TextScaled = true,
			TextWrapped = true,
			Text = "",
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 31,
		}, tooltip)
	end
	local tipTitle = tipText(UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 24), Enum.Font.FredokaOne, Color3.fromRGB(30, 30, 45))
	local tipDescription = tipText(UDim2.fromOffset(10, 32), UDim2.new(1, -20, 0, 36), Enum.Font.GothamMedium, Color3.fromRGB(70, 74, 92))
	local tipTime = tipText(UDim2.fromOffset(10, 70), UDim2.new(1, -20, 0, 18), Enum.Font.FredokaOne, Color3.fromRGB(40, 150, 70))

	for _, potion in Config.Potions.List do
		local slot = create("TextButton", {
			Text = "",
			AutoButtonColor = false,
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
		local entry = { potion = potion, slot = slot, label = label, remaining = 0 }
		table.insert(slots, entry)
		slot.MouseEnter:Connect(function()
			hovered = entry
			updateTooltip()
		end)
		slot.MouseLeave:Connect(function()
			if hovered == entry then
				hovered = nil
				updateTooltip()
			end
		end)
		-- Dokunmatik ekranda üzerine gelme yok: dokununca açılır, tekrar dokununca kapanır
		slot.MouseButton1Click:Connect(function()
			hovered = if hovered == entry then nil else entry
			updateTooltip()
		end)
	end

	updateTooltip = function()
		if hovered and hovered.slot.Visible then
			tipTitle.Text = hovered.potion.name
			tipDescription.Text = hovered.potion.description or hovered.potion.effect
			tipTime.Text = `Time left: {clock(hovered.remaining)}`
			tooltip.Position = UDim2.new(0, hovered.slot.Position.X.Offset, 1, -(MARGIN + SLOT_HEIGHT + 8))
			tooltip.Visible = true
		else
			hovered = nil
			tooltip.Visible = false
		end
	end

	local function refresh()
		local now = Workspace:GetServerTimeNow()
		-- Power Hour rozeti (client/PowerHourHud, 'PowerHourBadge') açıkken sıranın ilk yuvası onundur: iksirler bir yuva sağa kayar
		local powerBadge = screenGui:FindFirstChild("PowerHourBadge")
		local shown = if powerBadge and powerBadge.Visible then 1 else 0
		for _, entry in slots do
			local untilTime = player:GetAttribute(entry.potion.attribute)
			local remaining = if type(untilTime) == "number" then untilTime - now else 0
			entry.slot.Visible = remaining > 0
			entry.remaining = remaining
			if remaining > 0 then
				entry.slot.Position = UDim2.new(0, MARGIN + shown * (SLOT_WIDTH + 6), 1, -MARGIN)
				shown += 1
				entry.label.Text = clock(remaining)
				entry.label.TextColor3 = if remaining <= 10 and math.floor(remaining * 2) % 2 == 0 then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
			end
		end
		updateTooltip()
	end

	task.spawn(function()
		while true do
			refresh()
			task.wait(0.5)
		end
	end)
end

return BoostHud
