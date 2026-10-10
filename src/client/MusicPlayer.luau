-- Teyp (müzik çalar): sağ altta. Üstte kaset penceresi (şarkı adı kayan yazıyla), altta solda önceki / duraklat-devam / sonraki,
-- sağda ses kademesi (- / çubuklar / +). Müziği client/Sfx çalar; burası sadece arayüzdür.
-- Settings'te "Music" kapalıyken pencere "MUSIC OFF" yazar; butonlara basmak müziği geri açar (ve ayarı kaydeder).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sfx = require(script.Parent.Sfx)
local PlayerSettings = require(script.Parent.PlayerSettings)
local UIStyle = require(script.Parent.UIStyle)

local MusicPlayer = {}

local FONT = Enum.Font.FredokaOne
local MARQUEE_SPEED = 55 -- kayan yazının hızı (piksel/sn)
local BODY_WIDTH = 296
local BODY_HEIGHT = 100
local BODY_SCALE = 0.62 -- teyp ana ölçeğin küçüğüdür (referans oyunda teyp yok, ekranı kaplamasın; sahibi 'büyük' dedi: 0.85'ten küçültüldü)
local MARQUEE_GAP = 60 -- kayan yazının iki tekrarı arası boşluk (birim): pencere uzun süre boş kalmaz

local ICON_COLOR = Color3.fromRGB(245, 245, 250) -- önceki/sonraki simgeleri ve orta düğmenin dolgusu
local DARK = Color3.fromRGB(34, 36, 46) -- orta düğmedeki duraklat/oynat simgesi
local LIME = Color3.fromRGB(120, 255, 150)
local AMBER = Color3.fromRGB(255, 215, 90)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- Kalın siyah kenarlı yazı (oyundaki diğer butonlarla aynı)
local function text(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	local label = create("TextLabel", props, parent)
	create("UIStroke", { Thickness = strokeThickness, Color = Color3.new(0, 0, 0) }, label)
	return label
end

-- Üçgen simgesi (yazı karakterine güvenmeden, ince dikey şeritlerden): parent'ın ortasına çizilir.
-- pointRight = true ise sağa, değilse sola bakar. offsetX: şeritlerin başlangıcı (parent'ın solundan)
local STRIPS = 8
local function triangle(parent, pointRight, size, color, offsetX)
	local width = size * 0.9
	local stripWidth = width / STRIPS
	for i = 0, STRIPS - 1 do
		local progress = (i + 0.5) / STRIPS
		if not pointRight then
			progress = 1 - progress
		end
		create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, offsetX + i * stripWidth, 0.5, 0),
			Size = UDim2.fromOffset(stripWidth + 0.6, math.max(1.5, size * (1 - progress))),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
		}, parent)
	end
	return width
end

-- Ses çubuğu rengi: düşük kademe yeşil, orta sarı, yüksek turuncu
local function pipColor(index, maxLevel)
	local t = (index - 1) / math.max(1, maxLevel - 1)
	if t < 0.5 then
		return Color3.fromRGB(90, 220, 110):Lerp(Color3.fromRGB(255, 220, 60), t * 2)
	end
	return Color3.fromRGB(255, 220, 60):Lerp(Color3.fromRGB(255, 120, 50), (t - 0.5) * 2)
end

function MusicPlayer.init(screenGui)
	local music = Config.Music
	if not music or not music.tracks or #music.tracks == 0 then
		return
	end
	local player = Players.LocalPlayer
	local maxLevel = Sfx.getMusicMaxLevel()

	-- Telefonda teyp biraz sola kayar (sağ alttaki Roblox zıplama butonunun üstüne binmesin); masaüstünde yerinde (Config.UI.Phone)
	local okPerf, Performance = pcall(require, script.Parent.Performance)
	local phoneShift = if okPerf and Performance.mobile then Config.UI.Phone.MusicShiftX else 0
	local body = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14 + phoneShift, 1, -14),
		Size = UDim2.fromOffset(BODY_WIDTH, BODY_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(52, 56, 74),
		Active = true, -- teybe tıklamak hareket başlatmasın
	}, screenGui)
	create("UIScale", { Scale = BODY_SCALE }, body)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, body)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, body)
	UIStyle.soften(body, { radius = 14, strength = 0.22 })

	-- Kaset penceresi: şarkı adı sağdan sola kayar
	local window = create("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 30),
		BackgroundColor3 = Color3.fromRGB(14, 16, 24),
		ClipsDescendants = true,
	}, body)
	create("UICorner", { CornerRadius = UDim.new(0, 7) }, window)
	create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(120, 130, 165) }, window)
	UIStyle.soften(window, { radius = 8, gradient = false, shine = false })
	local function makeMarquee()
		return create("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 20,
			TextColor3 = LIME,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Text = "",
		}, window)
	end
	local marquee = makeMarquee()
	local marquee2 = makeMarquee() -- ikinci kopya: yazı kayarken kesintisiz döngü (uzun adlarda); kısa ad sığıyorsa gizli, yazı sabit durur
	marquee2.Visible = false

	local scrolling = false
	local marqueeX = 0
	-- AbsoluteSize ekran pikselidir; yazının konumu ise ölçeksiz arayüz birimindedir (ana ölçek x teyp ölçeği), bu yüzden bölünür
	local rootScale = screenGui:FindFirstChildOfClass("UIScale")
	local function unscaled(pixels)
		return pixels / ((if rootScale then rootScale.Scale else 1) * BODY_SCALE)
	end
	local function resetMarquee()
		marqueeX = 10 -- yazı pencerenin başında görünür başlar (eskiden pencerenin sağ dışından başlar, bir süre boş görünürdü)
	end

	RunService.Heartbeat:Connect(function(dt)
		if not scrolling then
			return
		end
		local width = unscaled(marquee.AbsoluteSize.X)
		local windowWidth = unscaled(window.AbsoluteSize.X)
		if width <= windowWidth - 20 then
			-- kısa ad pencereye sığıyor: kaydırma, sabit dur
			marquee.Position = UDim2.fromOffset(10, 0)
			marquee2.Visible = false
			return
		end
		local period = width + MARQUEE_GAP
		marqueeX -= MARQUEE_SPEED * dt
		if marqueeX < -period then
			marqueeX += period
		end
		marquee.Position = UDim2.fromOffset(marqueeX, 0)
		marquee2.Visible = true
		marquee2.Position = UDim2.fromOffset(marqueeX + period, 0)
	end)

	-- Müzik kapalıysa açar (teyp butonlarına basmak "dinlemek istiyorum" demektir)
	local function wakeSounds()
		if not PlayerSettings.get("MusicOn") then
			PlayerSettings.set("MusicOn", true)
		end
	end

	local function refreshText()
		if player:GetAttribute("MusicOn") == false then
			scrolling = false
			marquee.Text = "MUSIC OFF"
			marquee.TextColor3 = Color3.fromRGB(150, 155, 175)
			marquee.Position = UDim2.fromOffset(10, 0)
			marquee2.Visible = false
			return
		end
		local track = Sfx.getTrack()
		local label
		if track.index == 0 then
			label = "🎵 Loading music...   "
		elseif track.name == "Loading..." then
			label = `🎵 Loading ({track.index}/{track.total})...   `
		else
			label = `🎵 {track.name}  ({track.index}/{track.total})      `
		end
		if marquee.Text ~= label then
			marquee.Text = label
			marquee2.Text = label
			resetMarquee()
		end
		-- Duraklatılınca yazı durur ve sarıya döner
		local paused = Sfx.isPaused()
		marquee.TextColor3 = if paused then AMBER else LIME
		marquee2.TextColor3 = marquee.TextColor3
		scrolling = not paused
	end

	-- ---- Alt sıra, sol: önceki / duraklat-devam / sonraki ----
	local ROW_TOP, ROW_HEIGHT = 46, 44

	-- Şeffaf simge butonu (üzerine gelince hafif parlar, basınca küçülür)
	local function makeIconButton(x, width, height)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(x, ROW_TOP + (ROW_HEIGHT - height) / 2),
			Size = UDim2.fromOffset(width, height),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
		}, body)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		local scale = create("UIScale", { Scale = 1 }, button)
		button.MouseEnter:Connect(function()
			button.BackgroundTransparency = 0.82
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundTransparency = 1
			scale.Scale = 1
		end)
		button.MouseButton1Down:Connect(function()
			scale.Scale = 0.88
		end)
		button.MouseButton1Up:Connect(function()
			scale.Scale = 1
		end)
		return button
	end

	-- Çift üçgen (◀◀ / ▶▶), butonun ortasında
	local function doubleTriangle(button, pointRight)
		local size = 15
		local total = size * 0.9 * 2 - 3 -- iki üçgen biraz iç içe
		local start = 34 / 2 - total / 2 -- butonlar 34 piksel genişliğinde
		triangle(button, pointRight, size, ICON_COLOR, start)
		triangle(button, pointRight, size, ICON_COLOR, start + size * 0.9 - 3)
	end

	local previousButton = makeIconButton(10, 34, 34)
	doubleTriangle(previousButton, false)
	local nextButton = makeIconButton(96, 34, 34)
	doubleTriangle(nextButton, true)

	-- Orta düğme: yuvarlak, içinde duraklat (iki çubuk) ya da oynat (üçgen) simgesi
	local playButton = create("TextButton", {
		Position = UDim2.fromOffset(48, ROW_TOP),
		Size = UDim2.fromOffset(44, ROW_HEIGHT),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = ICON_COLOR,
	}, body)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, playButton)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, playButton)
	UIStyle.soften(playButton, { radius = UDim.new(1, 0), strength = 0.15, shine = false })
	local playScale = create("UIScale", { Scale = 1 }, playButton)
	playButton.MouseButton1Down:Connect(function()
		playScale.Scale = 0.92
	end)
	playButton.MouseButton1Up:Connect(function()
		playScale.Scale = 1
	end)
	playButton.MouseLeave:Connect(function()
		playScale.Scale = 1
	end)

	local pauseIcon = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 20),
		BackgroundTransparency = 1,
	}, playButton)
	for _, x in { 0, 11 } do
		local bar = create("Frame", {
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(7, 20),
			BackgroundColor3 = DARK,
			BorderSizePixel = 0,
		}, pauseIcon)
		create("UICorner", { CornerRadius = UDim.new(0, 2) }, bar) -- köşeleri hafif yuvarlak
	end
	local playIcon = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 1, 0.5, 0), -- üçgen görsel olarak ortada dursun diye biraz sağda
		Size = UDim2.fromOffset(18, 22),
		BackgroundTransparency = 1,
		Visible = false,
	}, playButton)
	triangle(playIcon, true, 22, DARK, 0)

	local function refreshPlayIcon()
		local paused = Sfx.isPaused()
		pauseIcon.Visible = not paused
		playIcon.Visible = paused
	end

	previousButton.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.previousTrack()
	end)
	nextButton.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.nextTrack()
	end)
	playButton.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.togglePause()
	end)

	-- İki bölüm arasına ince ayraç
	create("Frame", {
		Position = UDim2.fromOffset(136, ROW_TOP + 6),
		Size = UDim2.fromOffset(2, ROW_HEIGHT - 12),
		BackgroundColor3 = Color3.fromRGB(88, 94, 120),
		BorderSizePixel = 0,
	}, body)

	-- ---- Alt sıra, sağ: ses kademesi [-] [çubuklar] [+] ----
	local function makeVolumeButton(x, color, caption)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(x, ROW_TOP + 5),
			Size = UDim2.fromOffset(28, 34),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = color,
		}, body)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		UIStyle.soften(button, { radius = 8, strength = 0.28 })
		local label = text(button, {
			Position = UDim2.fromScale(0.1, 0.1),
			Size = UDim2.fromScale(0.8, 0.8),
			Text = caption,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		create("UITextSizeConstraint", { MaxTextSize = 24 }, label)
		return button
	end

	local minus = makeVolumeButton(146, Color3.fromRGB(235, 70, 90), "-")
	local plus = makeVolumeButton(258, Color3.fromRGB(70, 200, 100), "+")
	minus.MouseButton1Click:Connect(function()
		Sfx.setMusicLevel(Sfx.getMusicLevel() - 1)
	end)
	plus.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.setMusicLevel(Sfx.getMusicLevel() + 1)
	end)

	-- Ses çubukları (merdiven gibi büyür); tıklanan çubuğun kademesine ayarlanır
	local pips = {}
	local PIP_WIDTH, PIP_GAP = 6, 2
	local pipArea = create("Frame", {
		Position = UDim2.fromOffset(178, ROW_TOP + 5),
		Size = UDim2.fromOffset(maxLevel * (PIP_WIDTH + PIP_GAP) - PIP_GAP, 34),
		BackgroundTransparency = 1,
	}, body)
	for index = 1, maxLevel do
		local height = 7 + (index - 1) * (27 / math.max(1, maxLevel - 1))
		local pip = create("TextButton", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, (index - 1) * (PIP_WIDTH + PIP_GAP), 1, 0),
			Size = UDim2.fromOffset(PIP_WIDTH, height),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(70, 76, 96),
		}, pipArea)
		create("UICorner", { CornerRadius = UDim.new(0, 2) }, pip)
		create("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0) }, pip)
		pip.MouseButton1Click:Connect(function()
			wakeSounds()
			Sfx.setMusicLevel(index)
		end)
		pips[index] = pip
	end

	local function refreshPips()
		local level = Sfx.getMusicLevel()
		for index, pip in pips do
			pip.BackgroundColor3 = if index <= level then pipColor(index, maxLevel) else Color3.fromRGB(70, 76, 96)
		end
	end

	Sfx.onTrackChanged(refreshText)
	Sfx.onMusicLevelChanged(refreshPips)
	Sfx.onPausedChanged(function()
		refreshPlayIcon()
		refreshText()
	end)
	player:GetAttributeChangedSignal("MusicOn"):Connect(refreshText)
	refreshPips()
	refreshPlayIcon()
	refreshText()
end

return MusicPlayer
