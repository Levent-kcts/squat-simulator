-- Çevrimdışı kazanç penceresi (Offline Earnings): oyuncu uzaktayken biriken bacak kası, girişte bir pencerede gösterilir ve
-- CLAIM butonuyla alınır. Miktarı sunucu hesaplar ve verir (PlayerStats.claimOffline); burası sadece gösterir.
-- Sunucu OfflinePending (kas) ve OfflineSeconds (uzakta geçen süre) özniteliklerini ayarlar; alınmadan çıkılırsa sonraki girişte yine gelir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local UIStyle = require(script.Parent.UIStyle)

-- Kutlama efekti isteğe bağlı (Juice yüklenemezse pencere yine çalışır)
local okJuice, Juice = pcall(require, script.Parent.Juice)

local OfflinePanel = {}

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

-- 12000 -> "3h 20m", 1800 -> "30m"
local function duration(seconds)
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	if hours > 0 then
		return `{hours}h {minutes}m`
	end
	return `{math.max(1, minutes)}m`
end

function OfflinePanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shopFunction = ReplicatedStorage:WaitForChild("Shop")

	-- Arkası hafif karartılmış tam ekran katman: tıklamalar oyuna geçmez
	local overlay = create("Frame", {
		Name = "OfflineEarnings",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Active = true,
		Visible = false,
		ZIndex = 30,
	}, screenGui)

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(420, 300),
		BackgroundColor3 = Color3.fromRGB(40, 44, 66),
		ZIndex = 31,
	}, overlay)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, card)
	UIStyle.soften(card, { radius = 18, strength = 0.2, shine = false })
	local scale = create("UIScale", { Scale = 1 }, card)

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = Color3.fromRGB(120, 90, 235),
		ZIndex = 32,
	}, card)
	UIStyle.soften(header, { radius = 16, strength = 0.25 })
	text(header, {
		Position = UDim2.fromOffset(18, 8),
		Size = UDim2.new(1, -36, 1, -16),
		Text = "💤 OFFLINE EARNINGS",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 33,
	}, 3)

	local awayLabel = text(card, {
		Position = UDim2.fromOffset(20, 76),
		Size = UDim2.new(1, -40, 0, 30),
		TextColor3 = Color3.fromRGB(215, 220, 245),
		ZIndex = 32,
	}, 2)
	local amountLabel = text(card, {
		Position = UDim2.fromOffset(20, 110),
		Size = UDim2.new(1, -40, 0, 64),
		TextColor3 = Color3.fromRGB(110, 255, 140),
		ZIndex = 32,
	}, 3)
	text(card, {
		Position = UDim2.fromOffset(20, 176),
		Size = UDim2.new(1, -40, 0, 24),
		Text = "Leg Muscle",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 32,
	}, 2)

	local claim = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(240, 58),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(60, 205, 90),
		ZIndex = 32,
	}, card)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, claim)
	UIStyle.soften(claim, { radius = 14, strength = 0.28 })
	text(claim, {
		Position = UDim2.fromScale(0.08, 0.1),
		Size = UDim2.fromScale(0.84, 0.8),
		Text = "CLAIM!",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 33,
	}, 3)

	local note = text(card, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -80),
		Size = UDim2.new(1, -40, 0, 18),
		TextColor3 = Color3.fromRGB(170, 176, 205),
		ZIndex = 32,
	}, 1)
	note.Text = `Earned at {math.floor(Config.Offline.Rate * 100 + 0.5)}% of active play, up to {Config.Offline.MaxHours}h`

	local claiming = false

	local function show()
		local pending = player:GetAttribute("OfflinePending")
		local away = player:GetAttribute("OfflineSeconds")
		if type(pending) ~= "number" or pending <= 0 or overlay.Visible then
			return
		end
		if player:GetAttribute("DataLoaded") ~= true then
			return
		end
		awayLabel.Text = if type(away) == "number" then `You were away for {duration(away)}` else "While you were away"
		amountLabel.Text = `+{Format.compact(pending)}`
		overlay.Visible = true
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	claim.MouseButton1Click:Connect(function()
		if claiming then
			return
		end
		claiming = true
		local ok, message = shopFunction:InvokeServer("ClaimOffline")
		claiming = false
		overlay.Visible = false
		showToast(ok, message or "")
		if ok and okJuice then
			pcall(Juice.celebrate, Color3.fromRGB(110, 255, 140), 60)
		end
	end)

	player:GetAttributeChangedSignal("OfflinePending"):Connect(function()
		task.delay(1.2, show) -- karakter ve arayüz otursun
	end)
	task.delay(2.5, show) -- öznitelik istemci başlamadan önce gelmiş olabilir
end

return OfflinePanel
