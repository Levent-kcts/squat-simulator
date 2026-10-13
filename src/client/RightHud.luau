-- Ekranın sağ tarafındaki iki kutu (referans oyunun sağ tarafı boş kalmasın diye):
--  1) FREE REWARD: Gifts'teki sıradaki ödüle kalan süre (geri sayım) ya da "READY!"; tıklayınca Gifts menüsü açılır.
--  2) FRIEND BONUS: sunucudaki arkadaş sayısına göre kas bonusu yüzdesi (sunucu FriendCount / FriendBonus özniteliklerini ayarlar).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
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

-- openGifts / openIndex / openStats: pencereleri açıp kapatan fonksiyonlar; showToast(ok, mesaj): kısa bildirim (hepsini init.client verir)
function RightHud.init(screenGui, openGifts, showToast, openIndex, openStats, openQuests)
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
	-- Kutu sabit boyutlu bir TUTUCUNUN içindedir ve ORTADAN büyür (playtest: 'free reward paneli sağ kenara sabit, içerik büyüyünce tek yöne genişliyor, yazılar yamuluyor'):
	-- eskiden nabız atan UIScale sol-üst köşeden büyüyüp sağ kenara taşıyordu.
	local rewardHolder = create("Frame", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(150, 64), -- küçük tutulur (sahibi istedi): eskiden 200x88 idi ve lobiyi (raflar, tabelalar) kapatıyordu
		BackgroundTransparency = 1,
	}, container)
	local reward = create("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(255, 168, 36),
	}, rewardHolder)
	create("UIStroke", { Thickness = 4, Color = Color3.new(0, 0, 0) }, reward)
	UIStyle.soften(reward, { radius = 16, strength = 0.3 })
	local rewardScale = create("UIScale", { Scale = 1 }, reward)

	if Config.Icons.Gifts and Config.Icons.Gifts ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(6, 9),
			Size = UDim2.fromOffset(44, 44),
			Image = Config.Icons.Gifts,
			ScaleType = Enum.ScaleType.Fit,
		}, reward)
	else
		text(reward, { Position = UDim2.fromOffset(6, 9), Size = UDim2.fromOffset(44, 44), Text = "🎁" }, 0)
	end
	text(reward, {
		Position = UDim2.fromOffset(54, 6),
		Size = UDim2.fromOffset(90, 18),
		Text = "FREE REWARD",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, 2)
	local timer = text(reward, {
		Position = UDim2.fromOffset(54, 25),
		Size = UDim2.fromOffset(90, 32),
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
	local pulse = TweenService:Create(rewardScale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.05 })
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

	-- Roblox'un üst çubuğu (~58 px) normal ScreenGui'lerde boş bırakılır; köşede, o çubukla aynı hizada durması için AYRI bir ScreenGui kullanılır
	-- (IgnoreGuiInset = true). Eskiden ana ScreenGui'deydi ve üst çubuğun altından başladığı için köşeden çok aşağıda duruyordu.
	local cornerGui = create("ScreenGui", {
		Name = "CornerGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 2,
	}, player:WaitForChild("PlayerGui"))
	-- Kısa ekranlarda (telefon) sağ üst daireler de küçülür (sol HUD ana ölçekle zaten küçülüyor, daireler ayrı ScreenGui'de olduğu için dışarıda kalıyordu): 520 px ve üstü yükseklikte 1, 390'da ~0.75
	local cornerRoot = create("Frame", { Name = "CornerRoot", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, cornerGui)
	local cornerScale = create("UIScale", { Scale = 1 }, cornerRoot)
	local function updateCornerScale()
		local camera = workspace.CurrentCamera
		local height = if camera then camera.ViewportSize.Y else 1000
		local scale = if type(height) == "number" then math.clamp(height / 520, 0.7, 1) else 1
		cornerScale.Scale = scale
		cornerRoot.Size = UDim2.fromScale(1 / scale, 1 / scale)
	end
	updateCornerScale()
	do
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCornerScale)
		end
	end

	-- Sağ üst daireler (referanstaki gibi siyah daireler, sağdan sola: Arkadaş bonusu, Stats, Index). Her biri 60 px genişliğinde sütun.
	local function circleButton(name, slot, imageId, emoji)
		local column = create("TextButton", {
			Name = name,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10 - slot * 64, 0, 3),
			Size = UDim2.fromOffset(60, 82),
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
		}, cornerRoot)
		local disc = create("Frame", {
			Position = UDim2.fromOffset(4, 0),
			Size = UDim2.fromOffset(52, 52),
			BackgroundColor3 = Color3.fromRGB(16, 17, 24),
			BackgroundTransparency = 0.04,
		}, column)
		create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disc)
		create("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(70, 74, 98) }, disc)
		if imageId and imageId ~= "" then
			create("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(38, 36),
				Image = imageId,
				ScaleType = Enum.ScaleType.Fit,
			}, disc)
		else
			text(disc, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(32, 32), Text = emoji }, 0)
		end
		-- Üstüne gelince hafif aydınlanır
		column.MouseEnter:Connect(function()
			disc.BackgroundColor3 = Color3.fromRGB(40, 43, 62)
		end)
		column.MouseLeave:Connect(function()
			disc.BackgroundColor3 = Color3.fromRGB(16, 17, 24)
		end)
		return column
	end

	-- Stats: sayılar ve kazanç çarpanı dökümü (StatsPanel)
	local stats = circleButton("StatsButton", 1, Config.Icons.Stats, "📊")
	stats.MouseButton1Click:Connect(function()
		if openStats then
			openStats()
		end
	end)

	-- Pet Index: koleksiyon defteri; altında "keşfedilen/toplam" sayısı (IndexPanel)
	local index = circleButton("IndexButton", 2, Config.Icons.Index, "📖")
	local indexCount = text(index, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 41),
		Size = UDim2.fromOffset(62, 32),
		Text = "0/0",
		TextColor3 = Color3.fromRGB(255, 214, 46),
		ZIndex = 3,
	}, 3)
	-- Yeni pet türü keşfedilince (playtest isteği: 'yeni pet keşfedilince bildirim, Index butonunda rozet'): kısa bildirim + Index dairesi Index'i açana kadar nabız atar
	local indexDisc = index:FindFirstChildOfClass("Frame")
	local indexPulseScale = create("UIScale", { Scale = 1 }, indexDisc)
	local indexPulse = TweenService:Create(indexPulseScale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 })
	local indexPulsing = false
	local lastDiscovered = nil
	local function refreshIndex()
		local count = 0
		for _ in string.gmatch(player:GetAttribute("DiscoveredPets") or "", "[^,]+") do
			count += 1
		end
		indexCount.Text = `{count}/{#Config.Pets}`
		if lastDiscovered ~= nil and count > lastDiscovered then
			if showToast then
				showToast(true, "New pet discovered! Check your Pet Index (top right).")
			end
			if not indexPulsing then
				indexPulsing = true
				indexPulse:Play()
			end
		end
		lastDiscovered = count
	end
	player:GetAttributeChangedSignal("DiscoveredPets"):Connect(refreshIndex)
	refreshIndex()
	index.MouseButton1Click:Connect(function()
		if indexPulsing then
			indexPulsing = false
			indexPulse:Cancel()
			indexPulseScale.Scale = 1
		end
		if openIndex then
			openIndex()
		end
	end)

	-- Günlük görevler: en soldaki daire; altında alınmayı bekleyen ödül sayısı. Playtest: 'bildirim sayısının rengi arayüzle uyumsuz': diğer dairelerin altındaki sayılarla (Index, Arkadaş bonusu)
	-- AYNI sarı, boy ve kenar; dikkat çekmek için ödül varken daire nabız atar.
	local quests = circleButton("QuestsButton", 3, Config.Icons.Quests, "📜")
	local questBadgeText = text(quests, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 41),
		Size = UDim2.fromOffset(62, 32),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 214, 46),
		ZIndex = 3,
	}, 3)
	local questDisc = quests:FindFirstChildOfClass("Frame")
	local questPulseScale = create("UIScale", { Scale = 1 }, questDisc)
	local questPulse = TweenService:Create(questPulseScale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 })
	local questPulsing = false
	quests.MouseButton1Click:Connect(function()
		if openQuests then
			openQuests()
		end
	end)
	local okQuestPanel, QuestPanel = pcall(require, script.Parent.QuestPanel) -- hata verirse sadece rozet çalışmaz
	local lastClaimable = nil
	local function refreshQuestBadge()
		if not okQuestPanel then
			return
		end
		local count = QuestPanel.claimable(player)
		-- Yeni bir görev bitince (alınabilir sayısı artınca) kısa hatırlatma
		if lastClaimable ~= nil and count > lastClaimable and showToast then
			showToast(true, "Quest complete! Tap the 📜 Quests button (top right) to claim your reward.")
		end
		lastClaimable = count
		questBadgeText.Text = if count > 0 then tostring(count) else ""
		if count > 0 and not questPulsing then
			questPulsing = true
			questPulse:Play()
		elseif count == 0 and questPulsing then
			questPulsing = false
			questPulse:Cancel()
			questPulseScale.Scale = 1
		end
	end
	player:GetAttributeChangedSignal("QuestData"):Connect(refreshQuestBadge)
	refreshQuestBadge()

	-- ---------------- 2) FRIEND BONUS (sağ üst köşe) ----------------
	-- Referans oyundaki gibi küçük iki yüzlü simge ve altında yüzde: arkadaş yokken "0%", her arkadaşta +%10 ("10%", "20%" ...).
	-- Üstüne gelince küçük bir açıklama çıkar (kaç arkadaş, kaç yüzde, en çok kaç). TIKLAYINCA Roblox'un kendi "Invite Friends" penceresi açılır
	-- (SocialService:PromptGameInvite): arkadaş listesi, arama ve link kopyalama Roblox'tan gelir; davet kabul edilince arkadaş oyuna girer ve bonus başlar.
	if not Config.Friends.Enabled then
		return
	end
	local friends = create("TextButton", {
		Name = "FriendBonus",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 3), -- en sağ üst köşe, Roblox üst çubuğuyla aynı hizada
		Size = UDim2.fromOffset(60, 82),
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
	}, cornerRoot)

	-- Siyah yuvarlak zemin (referanstaki sağ üst yuvarlak butonlar gibi: koyu daire, ince açık kenar); simge içinde ortalı
	local iconBox = create("Frame", {
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(16, 17, 24),
		BackgroundTransparency = 0.04,
	}, friends)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, iconBox)
	create("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(70, 74, 98) }, iconBox)
	if Config.Icons.Friends and Config.Icons.Friends ~= "" then
		create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(38, 36),
			Image = Config.Icons.Friends,
			ScaleType = Enum.ScaleType.Fit,
		}, iconBox)
	else
		text(iconBox, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Text = "👥" }, 0)
	end
	local percentLabel = text(friends, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 41),
		Size = UDim2.fromOffset(62, 36),
		Text = "0%",
		TextColor3 = Color3.fromRGB(255, 214, 46),
		ZIndex = 3,
	}, 3)
	local percentScale = create("UIScale", { Scale = 1 }, percentLabel)

	-- Açıklama kutusu
	local tooltip = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 84),
		Size = UDim2.fromOffset(236, 106),
		BackgroundColor3 = Color3.fromRGB(40, 44, 70),
		Visible = false,
	}, cornerRoot)
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
	text(tooltip, {
		Position = UDim2.fromOffset(12, 80),
		Size = UDim2.new(1, -24, 0, 20),
		Text = "Click to invite friends!",
		TextColor3 = Color3.fromRGB(120, 255, 140),
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
	-- Tıklayınca Roblox'un arkadaş davet penceresi. Davet gönderilemiyorsa (yayınlanmamış oyun, yaş kısıtı, ağ hatası) açıklama kutusu 4 sn açık kalır.
	local inviting = false
	friends.MouseButton1Click:Connect(function()
		if inviting then
			return
		end
		inviting = true
		task.spawn(function()
			local okCheck, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
			local opened = false
			if okCheck and canInvite then
				opened = pcall(SocialService.PromptGameInvite, SocialService, player)
			end
			if not opened then
				if showToast then
					showToast(false, "Friend invites are not available right now.")
				end
				pinned = true
				refreshTooltip()
				task.delay(4, function()
					pinned = false
					refreshTooltip()
				end)
			end
			inviting = false
		end)
	end)

	local lastPercent = 0
	local function refreshFriends()
		local percent = player:GetAttribute("FriendBonus") or 0
		local friendCount = player:GetAttribute("FriendCount") or 0
		-- Arkadaş yokken dev '0%' olumsuz mesaj veriyordu (sahibi: küçült): küçük bir 'INVITE' çağrısı gösterilir; bonus başlayınca büyük yüzde döner
		if percent <= 0 then
			percentLabel.Text = "INVITE"
			percentLabel.TextColor3 = Color3.fromRGB(150, 205, 255)
			percentLabel.Size = UDim2.fromOffset(60, 18)
			percentLabel.Position = UDim2.new(0.5, 0, 0, 48)
		else
			percentLabel.Text = `{percent}%`
			percentLabel.TextColor3 = Color3.fromRGB(255, 214, 46)
			percentLabel.Size = UDim2.fromOffset(62, 36)
			percentLabel.Position = UDim2.new(0.5, 0, 0, 41)
		end
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
