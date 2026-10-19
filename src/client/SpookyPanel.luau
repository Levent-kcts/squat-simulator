-- SEZONLUK ETKİNLİK penceresi: SPOOKY GYM (Config.Event; server/SeasonEvent). Üstte Candy sayısı + kalan süre, ortada Candy kilometre taşları (CLAIM), altta DETERMİNİSTİK etkinlik mağazası (rastgele ürün yok).
-- Durum sunucudan öznitelik olarak gelir: Candy, CandyTotal, EventClaimed ('1,2'), EventBought ('rainbow:2'), EventPerks ('title,trail'), + Workspace 'SeasonActive' / 'SeasonEnds' (UTC saniye). Sol menüdeki 🎃 düğmesiyle açılır (PanelManager).
-- Döner: pencereyi açıp kapatan fonksiyon, pencere.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local SpookyPanel = {}

local FONT = Enum.Font.FredokaOne
local ORANGE = Color3.fromRGB(255, 150, 40)
local GREEN = Color3.fromRGB(70, 200, 100)
local GRAY = Color3.fromRGB(110, 114, 135)
local PURPLE = Color3.fromRGB(70, 40, 100)
local WIDTH = 440
local CHIP_W, CHIP_H, CHIP_GAP = 76, 70, 6
local ROW_H, ROW_GAP = 60, 6

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

-- 'a,b' ya da 'a:2,b:1' metnini tabloya çevirir
local function parseSet(value)
	local set = {}
	for entry in string.gmatch(value or "", "[^,]+") do
		local key, count = string.match(entry, "^(.-):(%d+)$")
		if key then
			set[key] = tonumber(count)
		else
			set[entry] = true
		end
	end
	return set
end

-- Ödülün kısa yazısı: '4x Win', 'Muscle', 'Luck 15m' ...
local function describe(reward)
	local parts = {}
	if reward.winsStage then
		table.insert(parts, `{reward.winsStage}x Win`)
	end
	if reward.muscleClicks then
		table.insert(parts, "Muscle")
	end
	for _, potion in reward.potions or {} do
		local name = string.gsub(potion.kind, "^boost", "")
		table.insert(parts, `{name} {potion.minutes}m`)
	end
	return table.concat(parts, " + ")
end

local function timeLeft(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days = seconds // 86400
	local hours = (seconds % 86400) // 3600
	if days > 0 then
		return `{days}d {hours}h`
	end
	return `{hours}h {(seconds % 3600) // 60}m`
end

function SpookyPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local event = Config.Event
	if not event then
		return nil
	end
	local milestones = #event.Milestones
	local items = #event.Items
	local chipsWidth = milestones * CHIP_W + (milestones - 1) * CHIP_GAP
	local height = 56 + 40 + 24 + CHIP_H + 20 + 24 + items * (ROW_H + ROW_GAP) + 10

	local panel = create("Frame", {
		Name = "SpookyPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(WIDTH, height),
		BackgroundColor3 = Color3.fromRGB(34, 26, 52),
		Active = true,
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(WIDTH, height), MinSize = Vector2.new(320, height) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Color3.fromRGB(235, 110, 30) }, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	text(header, { Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -90, 1, -12), Text = `{event.Emoji} {event.Name}`, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left }, 3)
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(235, 40, 70),
	}, header)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, close)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.28 })
	text(close, { Size = UDim2.fromScale(1, 1), Text = "X", TextColor3 = Color3.new(1, 1, 1) }, 2)
	close.MouseButton1Click:Connect(function()
		PanelManager.hide(panel)
	end)

	-- Candy sayısı ve kalan süre (üst satır)
	local candyLabel = text(panel, { Name = "CandyLabel", Position = UDim2.fromOffset(16, 62), Size = UDim2.fromOffset(220, 32), Text = "", TextColor3 = Color3.fromRGB(255, 225, 90), TextXAlignment = Enum.TextXAlignment.Left }, 2)
	local endsLabel = text(panel, { Name = "EndsLabel", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 66), Size = UDim2.fromOffset(170, 24), Text = "", TextColor3 = Color3.fromRGB(190, 195, 215), TextXAlignment = Enum.TextXAlignment.Right }, 1)
	create("UITextSizeConstraint", { MaxTextSize = 20 }, endsLabel)

	local content = create("Frame", { Name = "Content", Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 1, -98), BackgroundTransparency = 1 }, panel)

	local function invoke(action, id)
		task.spawn(function()
			local ok, success, message = pcall(shop.InvokeServer, shop, action, id)
			if not ok then
				success, message = false, "Could not complete that. Try again."
			end
			showToast(success, message or "")
		end)
	end

	local function render()
		for _, child in content:GetChildren() do
			child:Destroy()
		end
		local candy = player:GetAttribute("Candy") or 0
		local total = player:GetAttribute("CandyTotal") or 0
		local claimed = parseSet(player:GetAttribute("EventClaimed"))
		local bought = parseSet(player:GetAttribute("EventBought"))
		local perks = parseSet(player:GetAttribute("EventPerks"))
		local active = Workspace:GetAttribute("SeasonActive") == true
		candyLabel.Text = `{event.CurrencyEmoji} {Format.compact(candy)} {event.CurrencyName}`

		-- Kilometre taşları
		text(content, { Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(300, 20), Text = `Milestones (collected: {Format.compact(total)})`, TextColor3 = Color3.fromRGB(255, 205, 100), TextXAlignment = Enum.TextXAlignment.Left }, 1)
		local startX = (WIDTH - chipsWidth) / 2
		for index, milestone in event.Milestones do
			local done = claimed[tostring(index)] == true
			local ready = not done and total >= milestone.candy
			local chip = create("Frame", {
				Name = `Milestone_{index}`,
				Position = UDim2.fromOffset(startX + (index - 1) * (CHIP_W + CHIP_GAP), 24),
				Size = UDim2.fromOffset(CHIP_W, CHIP_H),
				BackgroundColor3 = if done then Color3.fromRGB(46, 74, 60) elseif ready then Color3.fromRGB(60, 96, 62) else Color3.fromRGB(52, 48, 78),
			}, content)
			create("UICorner", { CornerRadius = UDim.new(0, 8) }, chip)
			create("UIStroke", { Thickness = 3, Color = if ready then GREEN else Color3.new(0, 0, 0) }, chip)
			UIStyle.soften(chip, { radius = 10, strength = 0.12, shine = false })
			text(chip, { Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0, 18), Text = `{event.CurrencyEmoji} {milestone.candy}`, TextColor3 = Color3.fromRGB(255, 225, 90) }, 1)
			local rewardText = text(chip, { Position = UDim2.fromOffset(3, 21), Size = UDim2.new(1, -6, 0, 26), Text = describe(milestone.reward), TextColor3 = Color3.new(1, 1, 1) }, 1)
			create("UITextSizeConstraint", { MaxTextSize = 13 }, rewardText)
			local state = create("TextButton", {
				Name = "ClaimButton",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -3),
				Size = UDim2.new(1, -10, 0, 18),
				Text = "",
				BackgroundColor3 = if ready then GREEN else GRAY,
				AutoButtonColor = ready,
			}, chip)
			create("UICorner", { CornerRadius = UDim.new(0, 9) }, state)
			text(state, { Size = UDim2.fromScale(1, 1), Text = if done then "✓" elseif ready then "CLAIM" else "🔒", TextColor3 = Color3.new(1, 1, 1) }, 1)
			if ready and active then
				state.MouseButton1Click:Connect(function()
					invoke("EventClaim", index)
				end)
			end
		end

		-- Mağaza
		local shopY = 24 + CHIP_H + 14
		text(content, { Position = UDim2.fromOffset(16, shopY), Size = UDim2.fromOffset(300, 20), Text = `{event.Emoji} Event Shop (no random items!)`, TextColor3 = Color3.fromRGB(255, 205, 100), TextXAlignment = Enum.TextXAlignment.Left }, 1)
		for index, item in event.Items do
			local row = create("Frame", {
				Name = `EventItem_{item.id}`,
				Position = UDim2.fromOffset(12, shopY + 24 + (index - 1) * (ROW_H + ROW_GAP)),
				Size = UDim2.new(1, -24, 0, ROW_H),
				BackgroundColor3 = Color3.fromRGB(52, 48, 78),
			}, content)
			create("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
			UIStyle.soften(row, { radius = 10, strength = 0.12, shine = false })
			-- Ürünün kendi resmi varsa (item.image = Config.Icons anahtarı; ör. Pumpkin Patch izi 'Trail_pumpkin') emoji yerine o görünür
			local imageId = item.image and Config.Icons[item.image]
			if type(imageId) == "string" and imageId ~= "" then
				create("ImageLabel", { Name = "ItemImage", Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(48, 52), BackgroundTransparency = 1, Image = imageId, ScaleType = Enum.ScaleType.Fit }, row)
			else
				text(row, { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(40, 44), Text = item.emoji, TextColor3 = Color3.new(1, 1, 1) }, 0)
			end
			local nameLabel = text(row, { Position = UDim2.fromOffset(54, 6), Size = UDim2.new(1, -170, 0, 26), Text = item.name, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left }, 2)
			create("UITextSizeConstraint", { MaxTextSize = 20 }, nameLabel)
			local detailLabel = text(row, { Position = UDim2.fromOffset(54, 33), Size = UDim2.new(1, -170, 0, 20), Text = item.detail, TextColor3 = Color3.fromRGB(190, 195, 215), TextXAlignment = Enum.TextXAlignment.Left }, 1)
			create("UITextSizeConstraint", { MaxTextSize = 14 }, detailLabel)

			local count = bought[item.id] or 0
			local owned = (item.perk ~= nil and perks[item.perk] == true) or (item.limit == 1 and count >= 1)
			local label, color, onClick
			if owned and item.perk == "trail" then
				local equipped = player:GetAttribute("EquippedTrail") == event.Trail.id
				label = if equipped then "EQUIPPED" else "EQUIP"
				color = if equipped then GRAY else GREEN
				onClick = function()
					invoke("EquipTrail", if equipped then "" else event.Trail.id)
				end
			elseif owned then
				label, color = "OWNED ✓", GRAY
			elseif count >= item.limit then
				label, color = "SOLD OUT", GRAY
			else
				local affordable = candy >= item.price
				label = `{event.CurrencyEmoji} {item.price}`
				color = if affordable then ORANGE else Color3.fromRGB(150, 110, 70)
				onClick = function()
					invoke("EventBuy", item.id)
				end
			end
			local button = create("TextButton", {
				Name = "BuyButton",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, -6),
				Size = UDim2.fromOffset(100, 34),
				Text = "",
				BackgroundColor3 = color,
			}, row)
			create("UICorner", { CornerRadius = UDim.new(0, 17) }, button)
			create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
			UIStyle.soften(button, { radius = 17, strength = 0.28 })
			text(button, { Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88, 0.76), Text = label, TextColor3 = Color3.new(1, 1, 1) }, 2)
			if item.limit > 1 then
				local limitLabel = text(row, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -3), Size = UDim2.fromOffset(100, 14), Text = `{count}/{item.limit}`, TextColor3 = Color3.fromRGB(190, 195, 215) }, 1)
				create("UITextSizeConstraint", { MaxTextSize = 12 }, limitLabel)
			end
			if onClick and active then
				button.MouseButton1Click:Connect(onClick)
			end
		end
	end

	local function refreshTimer()
		local ends = Workspace:GetAttribute("SeasonEnds")
		if Workspace:GetAttribute("SeasonActive") ~= true or type(ends) ~= "number" then
			endsLabel.Text = "Event ended"
			return
		end
		local now = Workspace:GetServerTimeNow()
		endsLabel.Text = `Ends in {timeLeft(ends - (if type(now) == "number" then now else os.time()))}`
	end

	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
			refreshTimer()
		end
	end
	for _, name in { "Candy", "CandyTotal", "EventClaimed", "EventBought", "EventPerks", "EquippedTrail" } do
		player:GetAttributeChangedSignal(name):Connect(onChange)
	end
	Workspace:GetAttributeChangedSignal("SeasonActive"):Connect(onChange)

	local function show()
		PanelManager.show(panel)
		render()
		refreshTimer()
		task.spawn(function()
			while PanelManager.isOpen(panel) do
				task.wait(30)
				refreshTimer()
			end
		end)
	end
	local function toggle()
		if PanelManager.isOpen(panel) then
			PanelManager.hide(panel)
		else
			show()
		end
	end
	return toggle, panel
end

return SpookyPanel
