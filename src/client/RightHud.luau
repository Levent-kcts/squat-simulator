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

	-- ---------------- 2) FRIEND BONUS (sağ üst köşe) ----------------
	-- Referans oyundaki gibi küçük iki yüzlü simge ve altında yüzde: arkadaş yokken "0%", her arkadaşta +%10 ("10%", "20%" ...).
	-- Üstüne gelince / tıklayınca küçük bir açıklama çıkar (kaç arkadaş, kaç yüzde, en çok kaç).
	if not Config.Friends.Enabled then
		return
	end
	local friends = create("TextButton", {
		Name = "FriendBonus",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6), -- en sağ üst köşeye yapışık (referans oyundaki gibi)
		Size = UDim2.fromOffset(62, 82),
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}, screenGui)
	local iconBox = create("Frame", {
		Position = UDim2.fromOffset(1, 0),
		Size = UDim2.fromOffset(60, 56),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, friends)
	if Config.Icons.Friends and Config.Icons.Friends ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = Config.Icons.Friends,
			ScaleType = Enum.ScaleType.Fit,
		}, iconBox)
	else
		text(iconBox, { Size = UDim2.fromScale(1, 1), Text = "👥" }, 0)
	end
	local percentLabel = text(friends, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 46),
		Size = UDim2.fromOffset(62, 34),
		Text = "0%",
		TextColor3 = Color3.fromRGB(255, 214, 46),
	}, 3)
	local percentScale = create("UIScale", { Scale = 1 }, percentLabel)

	-- Açıklama kutusu
	local tooltip = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 92),
		Size = UDim2.fromOffset(236, 84),
		BackgroundColor3 = Color3.fromRGB(40, 44, 70),
		Visible = false,
	}, screenGui)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, tooltip)
	UIStyle.soften(tooltip, { radius = 12, strength = 0.2, shine = false })
	text(tooltip, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 24),
		Text = "FRIEND BONUS",
		TextColor3 = Color3.fromRGB(255, 214, 46),
	}, 2)
	local tooltipLine = text(tooltip, {
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 20),
		TextColor3 = Color3.new(1, 1, 1),
	}, 1.5)
	tooltipLine.Text = `+{Config.Friends.PercentPerFriend}% Leg Muscle per friend in your server`
	local tooltipCount = text(tooltip, {
		Position = UDim2.fromOffset(12, 56),
		Size = UDim2.new(1, -24, 0, 20),
		TextColor3 = Color3.fromRGB(190, 200, 235),
	}, 1.5)

	local hovering, pinned = false, false
	local function refreshTooltip()
		tooltip.Visible = hovering or pinned
	end
	friends.MouseEnter:Connect(function()
		hovering = true
		refreshTooltip()
	end)
	friends.MouseLeave:Connect(function()
		hovering = false
		refreshTooltip()
	end)
	friends.MouseButton1Click:Connect(function()
		pinned = not pinned -- dokunmatik ekranda üzerine gelme yok: tıklayınca açılır/kapanır
		refreshTooltip()
	end)

	local lastPercent = 0
	local function refreshFriends()
		local percent = player:GetAttribute("FriendBonus") or 0
		local friendCount = player:GetAttribute("FriendCount") or 0
		percentLabel.Text = `{percent}%`
		tooltipCount.Text = `{friendCount} / {Config.Friends.MaxFriends} friends here (max +{Config.Friends.MaxFriends * Config.Friends.PercentPerFriend}%)`
		if percent > lastPercent then
			-- Yeni arkadaş geldi: yüzde büyüyüp yerine oturur
			percentScale.Scale = 1.5
			TweenService:Create(percentScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
		lastPercent = percent
	end
	player:GetAttributeChangedSignal("FriendBonus"):Connect(refreshFriends)
	player:GetAttributeChangedSignal("FriendCount"):Connect(refreshFriends)
	refreshFriends()
end

return RightHud
