-- Anlık geri bildirim efektleri ("juice"): kazanç sayıları, level atlama / rebirth / Win kutlaması, duvar kırılma patlaması ve
-- kamera sarsıntısı. Hepsi sadece bu oyuncunun ekranındadır; hiçbiri oyun mantığını etkilemez (sayıları sunucu verir).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local Juice = {}

local player = Players.LocalPlayer
local screenGuiRef = nil -- ekran ortası yazılar için (init'te verilir)

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function styledLabel(parent, text, color, strokeThickness)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label, stroke
end

-- Karakterin başının üstünde yükselip kaybolan yazı ("+12", "+3 Wins")
function Juice.floatText(text, color, sizeScale)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	sizeScale = sizeScale or 1

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(5 * sizeScale, 1.6 * sizeScale) -- stud cinsinden: uzaktayken küçülür
	gui.Adornee = head
	gui.MaxDistance = 90
	gui.AlwaysOnTop = true
	local startOffset = Vector3.new((math.random() - 0.5) * 2, head.Size.Y / 2 + 2.2, 0)
	gui.StudsOffsetWorldSpace = startOffset
	gui.Parent = head

	local label, stroke = styledLabel(gui, text, color, 2)

	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = startOffset + Vector3.new(0, 3.2, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { Transparency = 1 }):Play()
	Debris:AddItem(gui, 1.1)
end

-- Ekranın ortasında büyüyüp kaybolan başlık ("LEVEL UP!")
function Juice.banner(text, color)
	if not screenGuiRef then
		return
	end
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.3)
	holder.Size = UDim2.fromOffset(0, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = screenGuiRef

	local label, stroke = styledLabel(holder, text, color, 4)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)

	-- Küçükten büyüğe zıplayarak açılır, bir süre durur, solar
	holder.Size = UDim2.fromOffset(120, 36)
	TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(420, 110) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 1.1), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 1.1), { Transparency = 1 }):Play()
	Debris:AddItem(holder, 1.8)
end

-- Verilen konumda renkli parçacık patlaması (duvar kırılması, kutlama). size: patlamanın kapladığı hacim
function Juice.burst(position, size, color, amount)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = size
	anchor.Position = position
	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.LightEmission = 0.4
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(14, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -35, 0)
	emitter.RotSpeed = NumberRange.new(-200, 200)
	emitter.Parent = anchor
	emitter:Emit(amount or 60)

	Debris:AddItem(anchor, 2)
end

-- Kamera sarsıntısı: şiddet stud, süre saniye. Humanoid.CameraOffset kullanılır, süre bitince sıfırlanır.
local shakeToken = 0
function Juice.shake(strength, duration)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	shakeToken += 1
	local token = shakeToken
	local startTime = os.clock()
	task.spawn(function()
		while shakeToken == token do
			local elapsed = os.clock() - startTime
			if elapsed >= duration then
				break
			end
			local fade = 1 - elapsed / duration
			humanoid.CameraOffset = Vector3.new(
				(math.random() - 0.5) * 2 * strength * fade,
				(math.random() - 0.5) * 2 * strength * fade,
				0
			)
			RunService.RenderStepped:Wait()
		end
		if shakeToken == token then
			humanoid.CameraOffset = Vector3.zero
		end
	end)
end

-- Duvar kırıldı: duvarın rengiyle patlama + hafif sarsıntı (sadece yakındaysak)
function Juice.wallBroken(wallPart)
	local root = rootPart()
	if not root or not wallPart then
		return
	end
	if (root.Position - wallPart.Position).Magnitude > 90 then
		return
	end
	Juice.burst(wallPart.Position, Vector3.new(wallPart.Size.X * 0.8, wallPart.Size.Y * 0.6, 2), wallPart.Color, 90)
	Juice.shake(0.35, 0.3)
end

-- Karakterin etrafında yukarı fışkıran parıltılar (level atlama, rebirth)
function Juice.celebrate(color, amount)
	local root = rootPart()
	if not root then
		return
	end
	Juice.burst(root.Position + Vector3.new(0, 1, 0), Vector3.new(4, 4, 4), color, amount or 50)
end

local GOLD = Color3.fromRGB(255, 220, 70)
local PINK = Color3.fromRGB(255, 90, 190)
local GREEN = Color3.fromRGB(120, 255, 160)

function Juice.init(screenGui)
	screenGuiRef = screenGui

	local leaderstats = player:WaitForChild("leaderstats")
	local muscle = leaderstats:WaitForChild(Config.StatLegMuscle)
	local wins = leaderstats:WaitForChild(Config.StatWins)
	local level = leaderstats:WaitForChild(Config.StatLevel)
	local rebirths = leaderstats:WaitForChild(Config.StatRebirths)

	local last = { muscle = muscle.Value, wins = wins.Value, level = level.Value, rebirths = rebirths.Value }

	-- Veri yüklenirken değerler sıçrar; kutlama sadece yükleme bittikten sonra
	local function ready()
		return player:GetAttribute("DataLoaded") == true
	end

	muscle:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = muscle.Value - last.muscle
		last.muscle = muscle.Value
		if delta > 0 and ready() then
			local inArea = (player:GetAttribute("AreaMultiplier") or 1) > 1
			Juice.floatText(`+{Format.compact(delta)}`, if inArea then GREEN else GOLD)
		end
	end)

	wins:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = wins.Value - last.wins
		last.wins = wins.Value
		if delta > 0 and ready() then
			Juice.floatText(`+{Format.compact(delta)} Wins`, Color3.fromRGB(255, 200, 60), 1.3)
			Juice.celebrate(Color3.fromRGB(255, 210, 60), 25)
		end
	end)

	-- Başlangıçta level atlamak çok sık olur: büyük yazı en fazla 4 saniyede bir çıkar, küçük patlama her seferinde
	local lastBanner = 0
	level:GetPropertyChangedSignal("Value"):Connect(function()
		local gained = level.Value > last.level
		last.level = level.Value
		if gained and ready() then
			if os.clock() - lastBanner > 4 then
				lastBanner = os.clock()
				Juice.banner("LEVEL UP!", GOLD)
			end
			Juice.celebrate(GOLD, 40)
		end
	end)

	rebirths:GetPropertyChangedSignal("Value"):Connect(function()
		local gained = rebirths.Value > last.rebirths
		last.rebirths = rebirths.Value
		if gained and ready() then
			Juice.banner("REBIRTH!", PINK)
			Juice.celebrate(PINK, 90)
			Juice.shake(0.5, 0.5)
		end
	end)
end

return Juice
