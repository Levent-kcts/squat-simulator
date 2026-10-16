-- GÜNLÜK GİRİŞ ÖDÜLÜ penceresi (2026-10-14: sahibi onayladı; Config.Login, server: PlayerStats.claimLogin): 7 günlük kart sırası, bugünün ödülü için CLAIM düğmesi, alt yazıda "seri kopmaz".
-- Durum sunucudan öznitelik olarak gelir: LoginNext (sıradaki gün 1-7), LoginReady (bugün alınabilir mi), LoginTotal. Sol menüdeki 'Daily' düğmesiyle açılır (PanelManager); hazırken düğmede kırmızı rozet çıkar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local LoginPanel = {}

local FONT = Enum.Font.FredokaOne
local GOLD = Color3.fromRGB(255, 205, 60)
local GREEN = Color3.fromRGB(70, 200, 100)
local GRAY = Color3.fromRGB(110, 114, 135)
local CARD_W, CARD_H, GAP = 70, 118, 8

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

-- Bir günün ödül yazısı ve simgesi (Config.Login.Rewards[gün]): iksir varsa iksir resmi, yoksa Win/kas simgesi
local function describe(reward)
	local lines = {}
	if reward.wins then
		table.insert(lines, `{reward.wins} Wins`)
	end
	if reward.muscleClicks then
		table.insert(lines, "Muscle")
	end
	for _, potion in reward.potions or {} do
		table.insert(lines, `{potion.minutes}m`)
	end
	return table.concat(lines, " + ")
end

local function drawIcon(parent, reward)
	local frame = create("Frame", { Position = UDim2.fromOffset(11, 26), Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1 }, parent)
	if reward.potions and #reward.potions > 0 then
		local potion = Catalog.PotionByKind[reward.potions[1].kind]
		UIStyle.potionIcon(frame, potion, { Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 1) })
		return
	end
	local key = if reward.wins then "Wins" else "LegMuscle"
	local id = Config.Icons[key]
	if type(id) == "string" and id ~= "" then
		create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = id, ScaleType = Enum.ScaleType.Fit }, frame)
	else
		text(frame, { Size = UDim2.fromScale(1, 1), Text = if reward.wins then "🏆" else "🦵", TextColor3 = Color3.new(1, 1, 1) }, 0)
	end
end

local function formatClock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

-- Döner: pencereyi açıp kapatan fonksiyon, pencere
function LoginPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local days = #Config.Login.Rewards
	local width = 24 + days * CARD_W + (days - 1) * GAP

	local panel = create("Frame", {
		Name = "LoginPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(width, 292),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		Active = true,
		Visible = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, panel)
	create("UISizeConstraint", { MaxSize = Vector2.new(width, 292), MinSize = Vector2.new(300, 292) }, panel)
	UIStyle.soften(panel, { radius = 16, strength = 0.2, shine = false })

	local header = create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Color3.fromRGB(255, 170, 50) }, panel)
	UIStyle.soften(header, { radius = 14, strength = 0.25 })
	UIStyle.headerIcon(header, Config.Icons.Daily, "📅", { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(48, 48) }) -- sağ üstteki Daily dairesiyle aynı simge
	text(header, { Position = UDim2.fromOffset(66, 6), Size = UDim2.new(1, -140, 1, -12), Text = "DAILY REWARDS", TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left }, 3)
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

	-- Gün kartları
	local cards = {}
	for day = 1, days do
		local reward = Config.Login.Rewards[day]
		local card = create("Frame", {
			Name = "LoginDay_" .. day,
			Position = UDim2.fromOffset(12 + (day - 1) * (CARD_W + GAP), 68),
			Size = UDim2.fromOffset(CARD_W, CARD_H),
			BackgroundColor3 = Color3.fromRGB(58, 63, 82),
		}, panel)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
		local stroke = create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, card)
		UIStyle.soften(card, { radius = 10, strength = 0.12, shine = false })
		text(card, { Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 20), Text = if reward.big then "DAY 7 ★" else `DAY {day}`, TextColor3 = if reward.big then GOLD else Color3.new(1, 1, 1) }, 2)
		drawIcon(card, reward)
		text(card, { Position = UDim2.fromOffset(2, 78), Size = UDim2.new(1, -4, 0, 18), Text = describe(reward), TextColor3 = Color3.fromRGB(190, 195, 215) }, 1)
		local state = text(card, { Position = UDim2.fromOffset(2, 97), Size = UDim2.new(1, -4, 0, 16), Text = "", TextColor3 = Color3.new(1, 1, 1) }, 1)
		cards[day] = { frame = card, stroke = stroke, state = state }
	end

	-- CLAIM düğmesi ve alt yazı
	local claim = create("TextButton", {
		Name = "LoginClaim",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 196),
		Size = UDim2.fromOffset(250, 44),
		Text = "",
		BackgroundColor3 = GREEN,
	}, panel)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, claim)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, claim)
	UIStyle.soften(claim, { radius = 12, strength = 0.28 })
	local claimText = text(claim, { Position = UDim2.fromScale(0.05, 0.12), Size = UDim2.fromScale(0.9, 0.76), Text = "CLAIM", TextColor3 = Color3.new(1, 1, 1) }, 2)
	local note = text(panel, {
		Position = UDim2.fromOffset(12, 250),
		Size = UDim2.new(1, -24, 0, 30),
		Text = "Your streak never resets: miss a day and the next reward is still waiting!",
		TextColor3 = Color3.fromRGB(190, 195, 215),
	}, 1)
	create("UITextSizeConstraint", { MaxTextSize = 15 }, note)

	local function nextSeconds()
		local now = Workspace:GetServerTimeNow()
		if type(now) ~= "number" then
			now = os.time()
		end
		return 86400 - (now % 86400)
	end

	local function render()
		local nextDay = player:GetAttribute("LoginNext") or 1
		local ready = player:GetAttribute("LoginReady") == true
		for day, card in cards do
			local status, color, strokeColor
			if day < nextDay then
				status, color, strokeColor = "✓ CLAIMED", Color3.fromRGB(48, 96, 66), GREEN
			elseif day == nextDay then
				if ready then
					status, color, strokeColor = "TODAY!", Color3.fromRGB(96, 80, 36), GOLD
				else
					status, color, strokeColor = "TOMORROW", Color3.fromRGB(58, 63, 82), GRAY
				end
			else
				status, color, strokeColor = "", Color3.fromRGB(58, 63, 82), Color3.new(0, 0, 0)
			end
			card.frame.BackgroundColor3 = color
			card.stroke.Color = strokeColor
			card.state.Text = status
			card.state.TextColor3 = if status == "TODAY!" then GOLD elseif day < nextDay then GREEN else Color3.fromRGB(190, 195, 215)
		end
		if ready then
			claim.BackgroundColor3 = GREEN
			claimText.Text = `CLAIM DAY {nextDay}`
		else
			claim.BackgroundColor3 = GRAY
			claimText.Text = `NEXT REWARD IN {formatClock(nextSeconds())}`
		end
	end

	local busy = false
	claim.MouseButton1Click:Connect(function()
		if busy or player:GetAttribute("LoginReady") ~= true then
			return
		end
		busy = true
		task.spawn(function()
			local callOk, success, message = pcall(shop.InvokeServer, shop, "ClaimLogin")
			busy = false
			if showToast then
				showToast(callOk and success == true, if callOk then message or "" else "Could not claim the reward. Try again.")
			end
			render()
		end)
	end)
	player:GetAttributeChangedSignal("LoginNext"):Connect(render)
	player:GetAttributeChangedSignal("LoginReady"):Connect(render)
	render()

	-- Pencere açıkken geri sayımı saniyede bir yenile
	task.spawn(function()
		while true do
			task.wait(1)
			if PanelManager.isOpen(panel) then
				render()
			end
		end
	end)

	local function toggle()
		render()
		PanelManager.toggle(panel)
	end
	return toggle, panel
end

return LoginPanel
