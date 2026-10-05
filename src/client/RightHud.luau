-- Ekranın sağ tarafındaki iki kutu (referans oyunun sağ tarafı boş kalmasın diye):
--  1) FREE REWARD: Gifts'teki sıradaki ödüle kalan süre (geri sayım) ya da "READY!"; tıklayınca Gifts menüsü açılır.
--  2) FRIEND BONUS: sunucudaki arkadaş sayısına göre kas bonusu yüzdesi (sunucu FriendCount / FriendBonus özniteliklerini ayarlar).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GiftState = require(script.Parent.GiftState)
local UIStyle = require(script.Parent.UIStyle)

local RightHud = {}

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

-- openGifts: Gifts menüsünü açıp kapatan fonksiyon (init.client verir)
function RightHud.init(screenGui, openGifts)
	local player = Players.LocalPlayer

	local container = create("Frame", {
		Name = "RightHud",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.4, 0),
		Size = UDim2.fromOffset(200, 190),
		BackgroundTransparency = 1,
	}, screenGui)
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, container)

	-- ---------------- 1) FREE REWARD ----------------
	local reward = create("TextButton", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(200, 88),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(255, 168, 36),
	}, container)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, reward)
	UIStyle.soften(reward, { radius = 16, strength = 0.3 })
	local rewardScale = create("UIScale", { Scale = 1 }, reward)

	if Config.Icons.Gifts and Config.Icons.Gifts ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 12),
			Size = UDim2.fromOffset(60, 60),
			Image = Config.Icons.Gifts,
			ScaleType = Enum.ScaleType.Fit,
		}, reward)
	else
		text(reward, { Position = UDim2.fromOffset(8, 12), Size = UDim2.fromOffset(60, 60), Text = "🎁" }, 0)
	end
	text(reward, {
		Position = UDim2.fromOffset(72, 8),
		Size = UDim2.fromOffset(120, 26),
		Text = "FREE REWARD",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)
	local timer = text(reward, {
		Position = UDim2.fromOffset(72, 36),
		Size = UDim2.fromOffset(120, 42),
		Text = "--:--",
		TextColor3 = Color3.fromRGB(255, 250, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
	reward.MouseButton1Click:Connect(function()
		if openGifts then
			openGifts()
		end
	end)

	-- Hazırken kutu nabız gibi atar
	local pulse = TweenService:Create(rewardScale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.07 })
	local pulsing = false

	local function refreshReward()
		local readyCount = #GiftState.ready()
		local remaining = GiftState.nextRemaining()
		if readyCount > 0 then
			timer.Text = "READY!"
			timer.TextColor3 = Color3.fromRGB(120, 255, 140)
			reward.BackgroundColor3 = Color3.fromRGB(70, 205, 90)
			if not pulsing then
				pulsing = true
				pulse:Play()
			end
		else
			if pulsing then
				pulsing = false
				pulse:Cancel()
				rewardScale.Scale = 1
			end
			reward.BackgroundColor3 = Color3.fromRGB(255, 168, 36)
			if remaining then
				timer.Text = GiftState.formatTime(remaining)
				timer.TextColor3 = Color3.fromRGB(255, 250, 200)
			else
				timer.Text = "DONE"
				timer.TextColor3 = Color3.fromRGB(215, 220, 235)
			end
		end
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			refreshReward()
		end
	end)
	refreshReward()

	-- ---------------- 2) FRIEND BONUS ----------------
	if not Config.Friends.Enabled then
		return
	end
	local friends = create("Frame", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(200, 78),
		BackgroundColor3 = Color3.fromRGB(96, 112, 255),
	}, container)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, friends)
	UIStyle.soften(friends, { radius = 16, strength = 0.3 })

	text(friends, { Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(48, 48), Text = "👥" }, 0)
	text(friends, {
		Position = UDim2.fromOffset(60, 6),
		Size = UDim2.fromOffset(132, 20),
		Text = "FRIEND BONUS",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)
	local bonus = text(friends, {
		Position = UDim2.fromOffset(60, 26),
		Size = UDim2.fromOffset(78, 30),
		Text = "+0%",
		TextColor3 = Color3.fromRGB(120, 255, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 3)
	local count = text(friends, {
		Position = UDim2.fromOffset(138, 30),
		Size = UDim2.fromOffset(54, 22),
		Text = "0/5",
		TextColor3 = Color3.fromRGB(225, 230, 255),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, 2)
	local hint = text(friends, {
		Position = UDim2.fromOffset(10, 57),
		Size = UDim2.fromOffset(182, 15),
		TextColor3 = Color3.fromRGB(215, 222, 255),
	}, 1)
	hint.Text = `+{Config.Friends.PercentPerFriend}% per friend in this server`

	local function refreshFriends()
		local percent = player:GetAttribute("FriendBonus") or 0
		local friendCount = player:GetAttribute("FriendCount") or 0
		bonus.Text = `+{percent}%`
		count.Text = `{friendCount}/{Config.Friends.MaxFriends}`
		bonus.TextColor3 = if percent > 0 then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(205, 210, 235)
	end
	player:GetAttributeChangedSignal("FriendBonus"):Connect(refreshFriends)
	player:GetAttributeChangedSignal("FriendCount"):Connect(refreshFriends)
	refreshFriends()
end

return RightHud
