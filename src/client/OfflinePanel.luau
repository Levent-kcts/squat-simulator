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

local Theme = UIStyle.Theme

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
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

	-- Ana kart: küçük ortalı modal (UIStyle.panel), başlık çubuğunda ghost X
	local card = UIStyle.panel(overlay, {
		name = "Card",
		accent = "success",
		width = 380,
		size = UDim2.fromOffset(380, 410),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		shadow = false,
	})
	card.ZIndex = 31

	-- Kapat (X): kazanç saklanır, sonraki girişte yine gelir
	UIStyle.header(card, {
		title = "Welcome back",
		accent = "success",
		onClose = function()
			UIStyle.fadeScaleOut(card, function()
				overlay.Visible = false
			end)
			showToast(true, "Your offline earnings are saved for later.")
		end,
	})

	-- Bacak kası simgesi (Config.Icons.LegMuscle yüklendiyse görsel, yoksa emoji); hafifçe aşağı yukarı süzülür
	local iconHolder = create("Frame", {
		Name = "IconHolder",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.fromOffset(110, 110),
		BackgroundTransparency = 1,
	}, card)
	if Config.Icons.LegMuscle and Config.Icons.LegMuscle ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = Config.Icons.LegMuscle,
			ScaleType = Enum.ScaleType.Fit,
		}, iconHolder)
	else
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "🦵",
			TextSize = 72,
			Font = Theme.fonts.bold,
			TextColor3 = Theme.colors.text,
		}, iconHolder)
	end
	if not UIStyle.isLow() then
		TweenService:Create(iconHolder, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = UDim2.new(0.5, 0, 0, 66),
		}):Play()
	end

	-- Miktar (sayma animasyonu) ve uzakta geçen süre
	local amountLabel = UIStyle.label(card, {
		name = "Amount",
		role = "title",
		size = 30,
		align = "center",
		color = Theme.colors.success.base,
		props = { Position = UDim2.new(0, 16, 0, 196), Size = UDim2.new(1, -32, 0, 38) },
	})
	local awayLabel = UIStyle.label(card, {
		name = "Away",
		role = "caption",
		align = "center",
		props = { Position = UDim2.new(0, 16, 0, 238), Size = UDim2.new(1, -32, 0, 20) },
	})

	-- Butonlar: tam genişlik CLAIM, altında ikincil DOUBLE IT!
	local claim = UIStyle.button(card, {
		name = "Claim",
		text = "Claim",
		kind = "success",
		size = "lg",
		width = UDim2.new(1, -40, 0, 0),
		position = UDim2.new(0, 20, 0, 282),
	})
	local doubleText = if offline.DoubleProductId > 0 then `Double it!  R$ {offline.DoubleRobux}` else "Double it!  Coming soon"
	local double = UIStyle.button(card, {
		name = "Double",
		text = doubleText,
		kind = "primary",
		size = "sm",
		width = UDim2.new(1, -40, 0, 0),
		position = UDim2.new(0, 20, 0, 356),
	})
	pcall(function()
		-- Fiyat yazısı eski sözleşmedeki 'Price' adını taşır
		double.Body.Label.Name = "Price"
	end)

	local busy = false

	local function hide()
		UIStyle.fadeScaleOut(card, function()
			overlay.Visible = false
		end)
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
		awayLabel.Text = if type(away) == "number" then `You were away {duration(away)}` else "While you were away"
		overlay.Visible = true
		UIStyle.fadeScaleIn(card)
		UIStyle.countTo(amountLabel, 0, pending, function(value)
			return `+{Format.compact(math.floor(value + 0.5))} Leg Muscle`
		end)
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
	-- DEV paneli her basışta OfflineNonce'u değiştirir: pencere kapatılmış olsa bile yeniden açılır
	player:GetAttributeChangedSignal("OfflineNonce"):Connect(function()
		task.delay(0.2, show)
	end)
	task.delay(2.5, show) -- öznitelik istemci başlamadan önce gelmiş olabilir
end

return OfflinePanel
