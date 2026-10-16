-- POWER HOUR göstergesi (Config.PowerHour, server/ServerEvents). 2026-10-16 sahibi 'üstteki hap ekranı çok kaplıyor' dedi, yeni düzen:
-- (1) Başlarken üstte (eski hapın yerinde) kısa 'POWER HOUR!' duyurusu (Config.PowerHour.AnnounceSeconds), (2) duyuru küçülerek SOL ALTA, iksirlerin olduğu sıraya iner ve
-- 'PowerHourBadge' olur: ⚡ simge, altında kalan süre, yanında 'x2' (BoostHud iksirleri bu rozetin sağına kaydırır), (3) sürerken ekranın sağından ve solundan ara ara
-- (FallEvery sn) yanlardan hafifçe AŞAĞI YAĞAN küçük şimşekler (Config.Icons.PowerHourFall: x2'siz lego şimşek; sahibi 'yanlarda çevrede hafif hafif aşağı doğru yağsın' dedi; Calm UI'da yağmaz). Başlamadan önce geri sayım YOK, ortada büyük yazı YOK. Rozete dokununca kısa bilgi bildirimi çıkar.
-- Sadece görsel: çarpanı sunucu uygular.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local okBubble, SpeechBubble = pcall(require, script.Parent.SpeechBubble) -- rozet açıklaması: iksirlerdeki gibi konuşma balonu
local okSfx, Sfx = pcall(require, script.Parent.Sfx) -- giriş müziği (Config.Sounds.PowerHour); yüklenemezse sessiz

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

-- Simge: Config.Icons[key] (varsayılan 'PowerHour') yüklendiyse resim, yoksa ⚡ emojisi
local function iconInto(parent, props, key)
	local imageId = Config.Icons and Config.Icons[key or "PowerHour"]
	if type(imageId) == "string" and imageId ~= "" then
		props.BackgroundTransparency = 1
		props.Image = imageId
		props.ScaleType = Enum.ScaleType.Fit
		return create("ImageLabel", props, parent)
	end
	if props.ImageTransparency ~= nil then
		props.TextTransparency = props.ImageTransparency -- emoji yedeği TextLabel: resim saydamlığı yazıya geçer
		props.ImageTransparency = nil
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
	local player = Players.LocalPlayer
	local settings = Config.PowerHour
	if not settings or not settings.Enabled then
		return
	end
	local announceSeconds = settings.AnnounceSeconds or 3.5
	local fallEvery = settings.FallEvery or 2.5

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

	-- Rozet açıklaması: iksir şişelerindeki gibi beyaz KONUŞMA BALONU (üstüne gelince / dokununca; sahibi 'yukarıda yeşil yazı çıkmasın, iksirlerdeki gibi balon olsun' dedi)
	local tip = create("Frame", {
		Name = "PowerHourTooltip",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, MARGIN, 1, -(MARGIN + SLOT_HEIGHT + 16)),
		Size = UDim2.fromOffset(214, 92),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		ZIndex = 30,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 10) }, tip)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, tip)
	local bubble = if okBubble then SpeechBubble.decorate(tip, { side = "bottom", at = (SLOT_WIDTH / 2) / 214 }) else nil
	local function tipText(position, size, font, color, text)
		return create("TextLabel", {
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			Font = font,
			TextScaled = true,
			TextWrapped = true,
			Text = text or "",
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 31,
		}, tip)
	end
	tipText(UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 24), FONT, Color3.fromRGB(30, 30, 45), "Power Hour")
	tipText(UDim2.fromOffset(10, 32), UDim2.new(1, -20, 0, 36), Enum.Font.GothamMedium, Color3.fromRGB(70, 74, 92), `x{settings.Multiplier} Leg Muscle for everyone in every server!`)
	local tipTime = tipText(UDim2.fromOffset(10, 70), UDim2.new(1, -20, 0, 18), FONT, Color3.fromRGB(40, 150, 70))
	local tipOpen = false
	local function setTip(open)
		tipOpen = open and badge.Visible
		if tipOpen then
			tipTime.Text = `Time left: {clock(remainingNow())}`
			if bubble then
				bubble.show()
			else
				tip.Visible = true
			end
		elseif bubble then
			bubble.hide()
		else
			tip.Visible = false
		end
	end
	badge.MouseEnter:Connect(function()
		setTip(true)
	end)
	badge.MouseLeave:Connect(function()
		setTip(false)
	end)
	badge.MouseButton1Click:Connect(function() -- dokunmatikte üstüne gelme yok: dokununca açılır, tekrar dokununca kapanır
		setTip(not tipOpen)
	end)

	-- (3) Ekranın SAĞ ve SOL kenarında yukarıdan aşağı hafifçe yağan küçük şimşek (ortayı ve karakteri kapatmaz; yarı saydam, yavaş, hafif salınır)
	local function fall()
		if calm() then
			return
		end
		local left = math.random() < 0.5
		local x = if left then 0.02 + math.random() * 0.13 else 0.85 + math.random() * 0.13
		local size = 30 + math.random(0, 14)
		local tilt = math.random(-20, 20)
		local holder = create("Frame", {
			Name = "PowerHourFall",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(x, 0, 0, -size),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			Rotation = tilt,
		}, screenGui)
		local icon = iconInto(holder, { Size = UDim2.fromScale(1, 1), ImageTransparency = 0.25 }, "PowerHourFall")
		local duration = 5 + math.random() * 2.5
		local drift = (math.random() - 0.5) * 0.04
		TweenService:Create(holder, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Position = UDim2.new(x + drift, 0, 1, size),
			Rotation = tilt + math.random(-25, 25),
		}):Play()
		if icon:IsA("ImageLabel") then
			-- alt kısımda yavaşça solar
			TweenService:Create(icon, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, duration * 0.65), { ImageTransparency = 1 }):Play()
		end
		task.delay(duration + 0.1, function()
			holder:Destroy()
		end)
	end

	local announcedFor = nil -- hangi bitiş zamanı için duyuru yapıldı
	local badgeShown = false
	local fallClock = 0

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
		if okSfx and Sfx.isOverrideActive and Sfx.isOverrideActive() then
			pcall(Sfx.stopMusicOverride) -- Power Hour bitti (ya da DEV ile durduruldu): döngü susar, normal müzik döner
		end
		badgeShown = false
		badge.Visible = false
		banner.Visible = false
		setTip(false)
	end

	-- Duyuru: üstte durur, sonra küçülüp sol alttaki rozetin yerine iner ve rozet belirir
	local function announce()
		banner.Position = UDim2.new(0.5, 0, 0, 84)
		banner.Size = UDim2.fromOffset(270, 44)
		banner.BackgroundTransparency = 0.1
		bannerText.TextTransparency = 0
		bannerStroke.Transparency = 0
		banner.Visible = true
		fall()
		-- Hareketli giriş müziği: arka plan müziği süresince kısılır (Settings'te efekt sesi kapalıysa Sfx.play çalmaz)
		if okSfx and Sfx.playMusicOverride then
			-- POWER HOUR MÜZİĞİ TEYPTEN (sahibi 'ses yükselme azalma olmasın, sağ alttaki radyoya entegre olsun, hep aynı seste çalsın' dedi): tema ve döngü normal müziğin
			-- YERİNE teypin ses kademesinde çalar, teypte '⚡ POWER HOUR' yazar. Sıra (tema TEK dosya, iki bölüm; sahibi 'bitiş müziği loop bittikten sonra çalsın' dedi):
			-- temanın giriş + patlaması (0 - ThemeSeconds) > döngü (en az LoopMusic.minutes dk, tur bitince) > temanın bitiş vuruşu (ThemeSeconds'tan sona) > normal müzik.
			local themeId = Config.Sounds and Config.Sounds.PowerHour and Config.Sounds.PowerHour.id or ""
			local loopMusic = settings.LoopMusic
			local introSeconds = settings.ThemeSeconds or 8
			local parts
			if themeId ~= "" and loopMusic and loopMusic.id ~= "" then
				parts = {
					{ id = themeId, stopAt = introSeconds },
					{ id = loopMusic.id, loopFor = (loopMusic.minutes or 5) * 60 },
					{ id = themeId, startAt = introSeconds },
				}
			elseif themeId ~= "" then
				parts = { { id = themeId } }
			end
			if parts then
				pcall(Sfx.playMusicOverride, parts, `⚡ {settings.Name} x{settings.Multiplier} ⚡`, loopMusic and loopMusic.gain or 1)
			end
		end
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
		if tipOpen then
			tipTime.Text = `Time left: {clock(at - serverNow())}`
		end
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
				fallClock += 0.5
				if fallClock >= fallEvery then
					fallClock = 0
					fall()
				end
			else
				fallClock = 0
			end
		end
	end)
end

return PowerHourHud
