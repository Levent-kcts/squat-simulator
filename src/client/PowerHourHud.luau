-- POWER HOUR göstergesi (Config.PowerHour, server/ServerEvents). 2026-10-16 sahibi 'üstteki hap ekranı çok kaplıyor' dedi, yeni düzen:
-- (1) Başlarken üstte (eski hapın yerinde) kısa 'POWER HOUR!' duyurusu (Config.PowerHour.AnnounceSeconds), (2) duyuru küçülerek SOL ALTA, iksirlerin olduğu sıraya iner ve
-- 'PowerHourBadge' olur: ⚡ simge, altında kalan süre, yanında 'x2' (BoostHud iksirleri bu rozetin sağına kaydırır), (3) sürerken ekranın sağından ve solundan ara ara
-- (FlybyEvery sn) küçük ⚡ simgesi geçer (Calm UI'da geçmez). Başlamadan önce geri sayım YOK, ortada büyük yazı YOK. Rozete dokununca kısa bilgi bildirimi çıkar.
-- Sadece görsel: çarpanı sunucu uygular.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local PowerHourHud = {}

local GOLD = Color3.fromRGB(255, 205, 60)
local FONT = Enum.Font.FredokaOne
-- Sol alttaki rozet: BoostHud'un iksir yuvalarıyla aynı ölçü ve kenar payı (SLOT 64 x 84, MARGIN 12)
local SLOT_WIDTH, SLOT_HEIGHT, MARGIN = 64, 84, 12
PowerHourHud.SlotWidth = SLOT_WIDTH

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds // 60) % 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function outlined(parent, props, thickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = thickness or 2.5, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Simge: Config.Icons.PowerHour yüklendiyse resim, yoksa ⚡ emojisi
local function iconInto(parent, props)
	local imageId = Config.Icons and Config.Icons.PowerHour
	if type(imageId) == "string" and imageId ~= "" then
		props.BackgroundTransparency = 1
		props.Image = imageId
		props.ScaleType = Enum.ScaleType.Fit
		return create("ImageLabel", props, parent)
	end
	props.Text = "⚡"
	props.TextColor3 = GOLD
	return outlined(parent, props, 3)
end

local function calm()
	local player = Players.LocalPlayer
	return player ~= nil and player:GetAttribute("CalmUI") == true
end

function PowerHourHud.init(screenGui, showToast)
	local settings = Config.PowerHour
	if not settings or not settings.Enabled then
		return
	end
	local announceSeconds = settings.AnnounceSeconds or 3.5
	local flybyEvery = settings.FlybyEvery or 22

	-- (1) Üstteki duyuru (eski hapın yerinde, kısa süreli)
	local banner = create("Frame", {
		Name = "PowerHourBanner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(270, 44),
		BackgroundColor3 = Color3.fromRGB(34, 30, 52),
		BackgroundTransparency = 0.1,
		Visible = false,
		ZIndex = 5,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, banner)
	local bannerStroke = create("UIStroke", { Thickness = 3, Color = GOLD }, banner)
	local bannerText = outlined(banner, {
		Position = UDim2.fromScale(0.06, 0.12),
		Size = UDim2.fromScale(0.88, 0.76),
		Text = `⚡ {settings.Name}! x{settings.Multiplier} ⚡`,
		TextColor3 = GOLD,
		ZIndex = 6,
	}, 2)
	create("UITextSizeConstraint", { MaxTextSize = 26 }, bannerText)

	-- (2) Sol alttaki rozet (iksir sırasının ilk yuvası)
	local badge = create("TextButton", {
		Name = "PowerHourBadge",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, MARGIN, 1, -MARGIN),
		Size = UDim2.fromOffset(SLOT_WIDTH, SLOT_HEIGHT),
		BackgroundTransparency = 1,
		Visible = false,
	}, screenGui)
	local badgeScale = create("UIScale", { Scale = 1 }, badge)
	iconInto(badge, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(58, 58),
	})
	-- Ayrı 'x2' rozeti sadece emoji yedeğinde: yüklenen simgenin (assets/icons/powerhour.png) üstünde zaten 'x2' yazıyor
	local imageId = Config.Icons and Config.Icons.PowerHour
	local hasImage = type(imageId) == "string" and imageId ~= ""
	local multChip = create("Frame", {
		Visible = not hasImage,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 2, 0, 12),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = GOLD,
		ZIndex = 2,
	}, badge)
	create("UICorner", { CornerRadius = UDim.new(0.5, 0) }, multChip)
	create("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, multChip)
	outlined(multChip, {
		Position = UDim2.fromScale(0.1, 0.08),
		Size = UDim2.fromScale(0.8, 0.84),
		Text = `x{settings.Multiplier}`,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
	}, 1.5)
	local timeLabel = outlined(badge, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 8, 0, 24),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
	}, 2.5)

	local function serverNow()
		local now = Workspace:GetServerTimeNow()
		return if type(now) == "number" then now else os.time()
	end

	local function remainingNow()
		local at = Workspace:GetAttribute("PowerHourAt")
		return if type(at) == "number" then at - serverNow() else 0
	end

	badge.MouseButton1Click:Connect(function()
		if showToast then
			showToast(true, `{settings.Name}: x{settings.Multiplier} Leg Muscle for everyone! {clock(remainingNow())} left`)
		end
	end)

	-- (3) Ekranın bir yanından öbürüne geçen küçük simge
	local function flyby()
		if calm() then
			return
		end
		local fromLeft = math.random() < 0.5
		local y = 0.22 + math.random() * 0.4
		local holder = create("Frame", {
			Name = "PowerHourFlyby",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(if fromLeft then 0 else 1, if fromLeft then -40 else 40, y, 0),
			Size = UDim2.fromOffset(46, 46),
			BackgroundTransparency = 1,
			Rotation = if fromLeft then -12 else 12,
		}, screenGui)
		iconInto(holder, { Size = UDim2.fromScale(1, 1) })
		local duration = 3.2 + math.random() * 1.2
		TweenService:Create(holder, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Position = UDim2.new(if fromLeft then 1 else 0, if fromLeft then 40 else -40, y - 0.06 + math.random() * 0.12, 0),
			Rotation = if fromLeft then 12 else -12,
		}):Play()
		task.delay(duration + 0.1, function()
			holder:Destroy()
		end)
	end

	local announcedFor = nil -- hangi bitiş zamanı için duyuru yapıldı
	local badgeShown = false
	local flybyClock = 0

	local function showBadge()
		if badgeShown then
			return
		end
		badgeShown = true
		badge.Visible = true
		badgeScale.Scale = 0.5
		TweenService:Create(badgeScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	local function hideAll()
		badgeShown = false
		badge.Visible = false
		banner.Visible = false
	end

	-- Duyuru: üstte durur, sonra küçülüp sol alttaki rozetin yerine iner ve rozet belirir
	local function announce()
		banner.Position = UDim2.new(0.5, 0, 0, 84)
		banner.Size = UDim2.fromOffset(270, 44)
		banner.BackgroundTransparency = 0.1
		bannerText.TextTransparency = 0
		bannerStroke.Transparency = 0
		banner.Visible = true
		flyby()
		task.delay(announceSeconds, function()
			if Workspace:GetAttribute("PowerHourActive") ~= true then
				banner.Visible = false
				return
			end
			local travel = if calm() then 0 else 0.6
			local target = UDim2.new(0, MARGIN + SLOT_WIDTH / 2, 1, -(MARGIN + SLOT_HEIGHT - 29))
			if travel > 0 then
				local info = TweenInfo.new(travel, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				TweenService:Create(banner, info, { Position = target, Size = UDim2.fromOffset(58, 30), BackgroundTransparency = 1 }):Play()
				TweenService:Create(bannerText, info, { TextTransparency = 1 }):Play()
				TweenService:Create(bannerStroke, info, { Transparency = 1 }):Play()
			end
			task.delay(travel, function()
				banner.Visible = false
				if Workspace:GetAttribute("PowerHourActive") == true then
					showBadge()
				end
			end)
		end)
	end

	local function render()
		local active = Workspace:GetAttribute("PowerHourActive") == true
		local at = Workspace:GetAttribute("PowerHourAt")
		if not active or type(at) ~= "number" then
			hideAll()
			return
		end
		timeLabel.Text = clock(at - serverNow())
		if announcedFor ~= at then
			announcedFor = at
			announce()
		end
	end

	Workspace:GetAttributeChangedSignal("PowerHourActive"):Connect(render)
	Workspace:GetAttributeChangedSignal("PowerHourAt"):Connect(render)
	render()
	task.spawn(function()
		while true do
			task.wait(0.5)
			render()
			if badgeShown then
				flybyClock += 0.5
				if flybyClock >= flybyEvery then
					flybyClock = 0
					flyby()
				end
			else
				flybyClock = 0
			end
		end
	end)
end

return PowerHourHud
