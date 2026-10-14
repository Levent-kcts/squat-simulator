-- GÜNLÜK GİRİŞ ÖDÜLÜ penceresi (2026-10-14: sahibi onayladı; Config.Login, server: PlayerStats.claimLogin): 7 günlük kart sırası, bugünün ödülü için CLAIM düğmesi, alt başlıkta "seri kopmaz".
-- Durum sunucudan öznitelik olarak gelir: LoginNext (sıradaki gün 1-7), LoginReady (bugün alınabilir mi), LoginTotal. Sol menüdeki 'Daily' düğmesiyle açılır (PanelManager); hazırken düğmede kırmızı rozet çıkar.
-- Görünüm: UIStyle tasarım sistemi (panel/header/card/button), vurgu = warn (turuncu); 7. gün geniş ve altın vurgulu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local LoginPanel = {}

local Theme = UIStyle.Theme
local COLORS = Theme.colors
-- 4 sütunlu ızgara: 1-4 üst sıra, 5-6 alt sıra + 7. gün iki hücre genişliğinde (telefonda da sığar)
local CELL_W, CELL_H, GAP, PAD = 92, 100, 8, 16
local GRID_TOP = 76

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Bir günün ödül satırı (Config.Login.Rewards[gün]): '+50 Wins', 'Luck 15m'
local function describe(reward)
	local lines = {}
	if reward.wins then
		table.insert(lines, `+{reward.wins} Wins`)
	end
	if reward.muscleClicks then
		table.insert(lines, "+Muscle")
	end
	for _, potion in reward.potions or {} do
		local def = Catalog.PotionByKind[potion.kind]
		local name = if def and def.name then string.gsub(tostring(def.name), " Potion", "") else "Potion"
		table.insert(lines, `{name} {potion.minutes}m`)
	end
	return table.concat(lines, " + ")
end

local function drawIcon(parent, reward, size)
	local frame = create("Frame", { Name = "RewardIcon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 22), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, parent)
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
		UIStyle.label(frame, { text = if reward.wins then "🏆" else "🦵", role = "bold", size = size - 8, align = "center", props = { Size = UDim2.fromScale(1, 1) } })
	end
end

local function formatClock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

-- Kartın çerçevesini (tek UIStroke) ayarlar
local function setStroke(card, color, thickness, transparency)
	pcall(function()
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = color
			stroke.Thickness = thickness
			stroke.Transparency = transparency
		end
	end)
end

-- Döner: pencereyi açıp kapatan fonksiyon, pencere
function LoginPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local days = #Config.Login.Rewards
	local width = PAD * 2 + 4 * CELL_W + 3 * GAP
	local height = 372

	local panel = UIStyle.panel(screenGui, {
		name = "LoginPanel",
		width = width,
		size = UDim2.fromOffset(width, height),
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.48),
		accent = "warn",
	})
	panel.Visible = false

	UIStyle.header(panel, {
		title = "Daily Reward",
		subtitle = "Come back any day - no streak loss",
		icon = Config.Icons.Daily,
		emoji = "📅",
		accent = "warn",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	-- Gün kartları
	local cards = {}
	for day = 1, days do
		local reward = Config.Login.Rewards[day]
		local big = reward.big == true
		local col = (day - 1) % 4
		local row = (day - 1) // 4
		local w = if big then CELL_W * 2 + GAP else CELL_W
		local card = UIStyle.card(panel, {
			name = "LoginDay_" .. day,
			position = UDim2.fromOffset(PAD + col * (CELL_W + GAP), GRID_TOP + row * (CELL_H + GAP)),
			size = UDim2.fromOffset(w, CELL_H),
			accent = if big then "primary" else "warn",
			padding = false,
		})
		UIStyle.label(card, { name = "DayLabel", text = if big then "DAY 7 ★" else `DAY {day}`, role = "caption", align = "center", color = if big then COLORS.primary.base else COLORS.textDim, props = { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 16), Font = Theme.fonts.bold } })
		drawIcon(card, reward, if big then 40 else 34)
		local rewardLabel = UIStyle.label(card, { name = "RewardText", text = describe(reward), role = "caption", align = "center", color = COLORS.text, props = { Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 16), Font = Theme.fonts.bold } })
		local state = UIStyle.label(card, { name = "StateText", text = "", role = "caption", align = "center", props = { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 16), Font = Theme.fonts.bold } })
		cards[day] = { frame = card, state = state, reward = rewardLabel, big = big }
	end

	-- CLAIM düğmesi (hazırken nabız atar, değilken geri sayım)
	local claim = UIStyle.button(panel, {
		name = "LoginClaim",
		text = "CLAIM",
		kind = "success",
		size = "lg",
		width = 280,
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, GRID_TOP + 2 * (CELL_H + GAP) + 6),
	})
	local pulseScale = create("UIScale", { Scale = 1 }, claim)
	local pulse = nil
	pcall(function()
		pulse = UIStyle.loopTween(TweenService:Create(pulseScale, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.05 }), pulseScale, { Scale = 1 })
	end)
	local pulsing = false
	local function setPulse(on)
		on = on and not UIStyle.isLow()
		if on == pulsing or not pulse then
			return
		end
		pulsing = on
		pcall(function()
			if on then
				pulse:Play()
			else
				pulse:Cancel()
				pulseScale.Scale = 1
			end
		end)
	end

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
			local status, statusColor
			local frame = card.frame
			local bigStroke = card.big
			local restColor = if bigStroke then COLORS.primary.base else Theme.stroke.color
			local restThick = if bigStroke then 2 else Theme.stroke.card
			if day < nextDay then
				-- geçmiş: tikli, sönük
				status, statusColor = "✓ CLAIMED", COLORS.success.base
				frame.BackgroundTransparency = 0.5
				setStroke(frame, Theme.stroke.color, 1, Theme.stroke.transparency)
				card.reward.TextColor3 = COLORS.textMute
			elseif day == nextDay and ready then
				-- bugün hazır: turuncu çerçeve
				status, statusColor = "TODAY!", COLORS.warn.base
				frame.BackgroundTransparency = 0
				setStroke(frame, COLORS.warn.base, 2, 0)
				card.reward.TextColor3 = COLORS.text
			elseif day == nextDay then
				status, statusColor = "TOMORROW", COLORS.textDim
				frame.BackgroundTransparency = 0
				setStroke(frame, restColor, restThick, if bigStroke then 0.2 else Theme.stroke.transparency)
				card.reward.TextColor3 = COLORS.text
			else
				-- gelecek: kilitli, sönük
				status, statusColor = "LOCKED", COLORS.textMute
				frame.BackgroundTransparency = 0.3
				setStroke(frame, restColor, restThick, if bigStroke then 0.4 else Theme.stroke.transparency)
				card.reward.TextColor3 = COLORS.textDim
			end
			card.state.Text = status
			card.state.TextColor3 = statusColor
		end
		if ready then
			UIStyle.setButtonKind(claim, "success")
			UIStyle.setButtonEnabled(claim, true)
			UIStyle.setButtonText(claim, `CLAIM DAY {nextDay}`)
		else
			UIStyle.setButtonKind(claim, "secondary")
			UIStyle.setButtonEnabled(claim, false)
			UIStyle.setButtonText(claim, `NEXT REWARD IN {formatClock(nextSeconds())}`)
		end
		setPulse(ready and PanelManager.isOpen(panel))
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
			else
				setPulse(false)
			end
		end
	end)

	local function toggle()
		PanelManager.toggle(panel)
		render()
	end
	return toggle, panel
end

return LoginPanel
