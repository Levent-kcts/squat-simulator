-- Teyp (müzik çalar): sağ altta. Ses kademesini açıp kısar (- / +, ya da çubuklara tıkla), sonraki şarkıya geçer (NEXT),
-- şarkı adı pencerede kayan yazıyla görünür. Müziği client/Sfx çalar; burası sadece arayüzdür.
-- "Sounds" anahtarı kapalıyken pencere "SOUNDS OFF" yazar; + / NEXT / çubuklar sesi geri açar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sfx = require(script.Parent.Sfx)

local MusicPlayer = {}

local FONT = Enum.Font.FredokaOne
local MARQUEE_SPEED = 55 -- kayan yazının hızı (piksel/sn)
local BODY_WIDTH = 252
local BODY_HEIGHT = 98

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

	local body = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.fromOffset(BODY_WIDTH, BODY_HEIGHT),
		BackgroundColor3 = Color3.fromRGB(52, 56, 74),
		Active = true, -- teybe tıklamak hareket başlatmasın
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, body)
	create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, body)

	-- Kaset penceresi: şarkı adı sağdan sola kayar
	local window = create("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 32),
		BackgroundColor3 = Color3.fromRGB(14, 16, 24),
		ClipsDescendants = true,
	}, body)
	create("UICorner", { CornerRadius = UDim.new(0, 7) }, window)
	create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(120, 130, 165) }, window)
	local marquee = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(120, 255, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Text = "",
	}, window)

	local scrolling = false
	local marqueeX = 0
	local function resetMarquee()
		marqueeX = window.AbsoluteSize.X
	end

	RunService.Heartbeat:Connect(function(dt)
		if not scrolling then
			return
		end
		marqueeX -= MARQUEE_SPEED * dt
		if marqueeX < -marquee.AbsoluteSize.X then
			marqueeX = window.AbsoluteSize.X
		end
		marquee.Position = UDim2.fromOffset(marqueeX, 0)
	end)

	local function refreshText()
		if player:GetAttribute("SoundsOn") == false then
			scrolling = false
			marquee.Text = "SOUNDS OFF"
			marquee.TextColor3 = Color3.fromRGB(150, 155, 175)
			marquee.Position = UDim2.fromOffset(10, 0)
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
			resetMarquee()
		end
		marquee.TextColor3 = Color3.fromRGB(120, 255, 150)
		scrolling = true
	end

	-- Alt sıra: [-] [ses çubukları] [+] [NEXT]
	local function makeButton(x, width, color, caption)
		local button = create("TextButton", {
			Position = UDim2.fromOffset(x, 50),
			Size = UDim2.fromOffset(width, 38),
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = color,
		}, body)
		create("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
		create("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }, button)
		local label = text(button, {
			Position = UDim2.fromScale(0.1, 0.1),
			Size = UDim2.fromScale(0.8, 0.8),
			Text = caption,
			TextColor3 = Color3.new(1, 1, 1),
		}, 2)
		create("UITextSizeConstraint", { MaxTextSize = 24 }, label)
		return button
	end

	-- Sesi açmak/skip için: ses kapalıysa önce açılır
	local function wakeSounds()
		if player:GetAttribute("SoundsOn") == false then
			player:SetAttribute("SoundsOn", true)
		end
	end

	local minus = makeButton(10, 36, Color3.fromRGB(235, 70, 90), "-")
	local plus = makeButton(148, 36, Color3.fromRGB(70, 200, 100), "+")
	local nextButton = makeButton(190, 52, Color3.fromRGB(70, 140, 255), "NEXT")

	minus.MouseButton1Click:Connect(function()
		Sfx.setMusicLevel(Sfx.getMusicLevel() - 1)
	end)
	plus.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.setMusicLevel(Sfx.getMusicLevel() + 1)
	end)
	nextButton.MouseButton1Click:Connect(function()
		wakeSounds()
		Sfx.nextTrack()
	end)

	-- Ses çubukları (merdiven gibi büyür); tıklanan çubuğun kademesine ayarlanır
	local pips = {}
	local PIP_WIDTH, PIP_GAP = 7, 2
	local pipArea = create("Frame", {
		Position = UDim2.fromOffset(52, 50),
		Size = UDim2.fromOffset(maxLevel * (PIP_WIDTH + PIP_GAP) - PIP_GAP, 38),
		BackgroundTransparency = 1,
	}, body)
	for index = 1, maxLevel do
		local height = 8 + (index - 1) * (30 / math.max(1, maxLevel - 1))
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
	player:GetAttributeChangedSignal("SoundsOn"):Connect(refreshText)
	refreshPips()
	refreshText()
end

return MusicPlayer
