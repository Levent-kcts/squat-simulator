-- Çevrimdışı kazanç penceresi (Offline Earnings): oyuncu uzaktayken biriken bacak kası, girişte bir pencerede gösterilir.
-- CLAIM kazancı alır; DOUBLE IT! Robux ile 2 katını verir (Config.Offline.DoubleProductId; 0 iken "yakında"); X kapatır, kazanç saklanır.
-- Miktarı sunucu hesaplar ve verir (PlayerStats.claimOffline / satın alma ödülü); burası sadece gösterir.
-- Sunucu OfflinePending (kas) ve OfflineSeconds (uzakta geçen süre) özniteliklerini ayarlar; alınmadan çıkılırsa sonraki girişte yine gelir.
local MarketplaceService = game:GetService("MarketplaceService")
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
	local offline = Config.Offline

	-- Arkası hafif karartılmış tam ekran katman: tıklamalar oyuna geçmez
	local overlay = create("Frame", {
		Name = "OfflineEarnings",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Active = true,
		Visible = false,
		ZIndex = 30,
	}, screenGui)

	-- Ana kart: koyu lacivert, kalın koyu kenar (referans pencere gibi), yumuşak köşeler
	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(520, 440),
		BackgroundColor3 = Color3.fromRGB(34, 42, 86),
		ZIndex = 31,
	}, overlay)
	create("UIStroke", { Thickness = 6, Color = Color3.fromRGB(12, 16, 42) }, card)
	UIStyle.soften(card, { radius = 22, strength = 0.28, shine = false })
	local cardScale = create("UIScale", { Scale = 1 }, card)

	-- Başlık
	text(card, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(1, -110, 0, 44),
		Text = "WHILE OFFLINE YOU GAINED:",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 33,
	}, 4)

	-- Kapat (X): kazanç saklanır, sonraki girişte yine gelir
	local close = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(46, 46),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(232, 48, 62),
		ZIndex = 34,
	}, card)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, close)
	UIStyle.soften(close, { radius = 10, strength = 0.3 })
	text(close, {
		Size = UDim2.fromScale(1, 1),
		Text = "X",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 35,
	}, 3)

	-- Simgenin arkasında yumuşak parıltı (üst üste yarı saydam daireler)
	local glowHolder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 160),
		Size = UDim2.fromOffset(190, 190),
		BackgroundTransparency = 1,
		ZIndex = 32,
	}, card)
	for index, factor in { 1, 0.78, 0.58 } do
		local ring = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(factor, factor),
			BackgroundColor3 = Color3.fromRGB(255, 205, 80),
			BackgroundTransparency = 0.9 - index * 0.015,
			BorderSizePixel = 0,
			ZIndex = 32,
		}, glowHolder)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
	end

	-- Bacak kası simgesi (Config.Icons.LegMuscle yüklendiyse görsel, yoksa büyük emoji); hafifçe aşağı yukarı süzülür
	local iconHolder = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 160),
		Size = UDim2.fromOffset(170, 170),
		BackgroundTransparency = 1,
		ZIndex = 33,
	}, card)
	if Config.Icons.LegMuscle and Config.Icons.LegMuscle ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = Config.Icons.LegMuscle,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 34,
		}, iconHolder)
	else
		text(iconHolder, { Size = UDim2.fromScale(1, 1), Text = "🦵", TextColor3 = Color3.new(1, 1, 1), ZIndex = 34 }, 0)
	end
	TweenService:Create(iconHolder, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.new(0.5, 0, 0, 150),
	}):Play()

	-- Miktar: büyük, parlak sarı yazı (üstten alta sarı-turuncu geçiş), kalın siyah kenar
	local amountLabel = text(card, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 252),
		Size = UDim2.new(1, -40, 0, 64),
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 33,
	}, 6)
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 248, 150), Color3.fromRGB(255, 176, 28)),
		Rotation = 90,
	}, amountLabel)

	local awayLabel = text(card, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 318),
		Size = UDim2.new(1, -60, 0, 22),
		TextColor3 = Color3.fromRGB(190, 198, 232),
		ZIndex = 33,
	}, 2)

	-- Butonlar: yeşil CLAIM, sarı DOUBLE IT! (+ fiyat)
	local function bigButton(positionX, color)
		local button = create("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(positionX, 0, 1, -22),
			Size = UDim2.new(0.43, 0, 0, 74),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = color,
			ZIndex = 33,
		}, card)
		create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 16, strength = 0.3 })
		return button
	end

	local claim = bigButton(0.26, Color3.fromRGB(80, 220, 60))
	text(claim, {
		Position = UDim2.fromScale(0.08, 0.14),
		Size = UDim2.fromScale(0.84, 0.72),
		Text = "Claim",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 34,
	}, 4)

	local double = bigButton(0.74, Color3.fromRGB(255, 205, 40))
	text(double, {
		Position = UDim2.fromScale(0.06, 0.08),
		Size = UDim2.fromScale(0.88, 0.5),
		Text = "DOUBLE IT!",
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 34,
	}, 4)
	local priceLabel = text(double, {
		Position = UDim2.fromScale(0.12, 0.58),
		Size = UDim2.fromScale(0.76, 0.34),
		Text = if offline.DoubleProductId > 0 then `ONLY R$ {offline.DoubleRobux}` else "COMING SOON",
		TextColor3 = Color3.fromRGB(110, 255, 110),
		ZIndex = 34,
	}, 3)
	priceLabel.Name = "Price"

	local busy = false

	local function hide()
		overlay.Visible = false
	end

	local function show()
		local pending = player:GetAttribute("OfflinePending")
		local away = player:GetAttribute("OfflineSeconds")
		if type(pending) ~= "number" or pending <= 0 or overlay.Visible then
			return
		end
		if player:GetAttribute("DataLoaded") ~= true then
			return
		end
		amountLabel.Text = `{Format.compact(pending)} LEG MUSCLE`
		awayLabel.Text = if type(away) == "number" then `You were away for {duration(away)}` else "While you were away"
		overlay.Visible = true
		cardScale.Scale = 0.6
		TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	claim.MouseButton1Click:Connect(function()
		if busy then
			return
		end
		busy = true
		local ok, message = shopFunction:InvokeServer("ClaimOffline")
		busy = false
		hide()
		showToast(ok, message or "")
		if ok and okJuice then
			pcall(Juice.celebrate, Color3.fromRGB(255, 215, 80), 60)
		end
	end)

	double.MouseButton1Click:Connect(function()
		if offline.DoubleProductId > 0 then
			-- Satın alma tamamlanınca sunucu 2 katını verir ve OfflinePending silinir (aşağıdaki dinleyici pencereyi kapatır)
			MarketplaceService:PromptProductPurchase(player, offline.DoubleProductId)
		else
			showToast(false, "Double It is coming soon!")
		end
	end)

	close.MouseButton1Click:Connect(function()
		hide()
		showToast(true, "Your offline earnings are saved for later.")
	end)

	player:GetAttributeChangedSignal("OfflinePending"):Connect(function()
		local pending = player:GetAttribute("OfflinePending")
		if type(pending) == "number" and pending > 0 then
			task.delay(1.2, show) -- karakter ve arayüz otursun
		elseif overlay.Visible and not busy then
			-- Kazanç başka yoldan alındı (Double It satın alındı): pencereyi kapat ve kutla
			hide()
			if okJuice then
				pcall(Juice.celebrate, Color3.fromRGB(255, 215, 80), 70)
			end
		end
	end)
	task.delay(2.5, show) -- öznitelik istemci başlamadan önce gelmiş olabilir
end

return OfflinePanel
