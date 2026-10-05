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
local Progression = require(Shared:WaitForChild("Progression"))
local Layout = require(Shared:WaitForChild("Layout"))

local Juice = {}

-- Ses modülü korumalı yüklenir: hata verirse efektler sessiz çalışır
local okSfx, Sfx = pcall(require, script.Parent.Sfx)
local function sfx(name)
	if okSfx then
		pcall(Sfx.play, name)
	end
end

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
	-- Baş üstü etiketinin (OverheadTags) üstünden başlar, onunla üst üste binmez
	local startOffset = Vector3.new((math.random() - 0.5) * 2, head.Size.Y / 2 + 4.2, 0)
	gui.StudsOffsetWorldSpace = startOffset
	gui.Parent = head

	local label, stroke = styledLabel(gui, text, color, 2)

	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = startOffset + Vector3.new(0, 3.2, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), { Transparency = 1 }):Play()
	Debris:AddItem(gui, 1.1)
end

-- Ekranın rastgele bir yerinde beliren, yukarı süzülüp kaybolan kazanç yazısı ("🦵 +12"): her hareketten sonra karakterin üstünde değil,
-- ekranın ortasındaki geniş bölgede (kenar çubuklarından ve alt barlardan uzakta) farklı noktalarda çıkar. icon: emoji, scale: boyut çarpanı
function Juice.screenPop(text, color, icon, scale)
	if not screenGuiRef or player:GetAttribute("ShowGain") == false then
		return
	end
	scale = scale or 1
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.22 + math.random() * 0.56, 0.2 + math.random() * 0.45)
	holder.Size = UDim2.fromOffset(170 * scale, 52 * scale)
	holder.BackgroundTransparency = 1
	holder.Rotation = math.random(-10, 10)
	holder.Parent = screenGuiRef

	local iconLabel, iconStroke = styledLabel(holder, icon or "🦵", Color3.new(1, 1, 1), 0)
	iconLabel.Size = UDim2.fromScale(0.3, 1)
	iconLabel.Position = UDim2.fromScale(0, 0)

	local valueLabel, valueStroke = styledLabel(holder, text, color, 3)
	valueLabel.Size = UDim2.fromScale(0.68, 1)
	valueLabel.Position = UDim2.fromScale(0.32, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Küçükten büyüğe zıplayarak belirir, yukarı süzülür, solar
	local popScale = Instance.new("UIScale")
	popScale.Scale = 0.5
	popScale.Parent = holder
	TweenService:Create(popScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local startPosition = holder.Position
	TweenService:Create(holder, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = startPosition - UDim2.fromScale(0, 0.07) }):Play()
	local fade = TweenInfo.new(0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.45)
	TweenService:Create(iconLabel, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(valueLabel, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(valueStroke, fade, { Transparency = 1 }):Play()
	Debris:AddItem(holder, 1.05)
end

-- Ekranın ortasında büyüyüp kaybolan başlık ("LEVEL UP!"); subText verilirse altında küçük bir satır daha gösterilir
function Juice.banner(text, color, subText)
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
	label.Position = UDim2.fromScale(0.5, if subText then 0.34 else 0.5)
	if subText then
		label.Size = UDim2.fromScale(1, 0.6)
	end

	local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, if subText then 2.2 else 1.1)
	TweenService:Create(label, fadeInfo, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
	if subText then
		local sub, subStroke = styledLabel(holder, subText, Color3.new(1, 1, 1), 3)
		sub.AnchorPoint = Vector2.new(0.5, 0.5)
		sub.Position = UDim2.fromScale(0.5, 0.82)
		sub.Size = UDim2.fromScale(1, 0.3)
		TweenService:Create(sub, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(subStroke, fadeInfo, { Transparency = 1 }):Play()
	end

	-- Küçükten büyüğe zıplayarak açılır, bir süre durur, solar
	holder.Size = UDim2.fromOffset(120, 36)
	TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(if subText then 520 else 420, if subText then 130 else 110) }):Play()
	Debris:AddItem(holder, if subText then 2.9 else 1.8)
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

-- Kırılan duvardan uçan lego parçaları: duvar renginde küçük, çıkıntılı bloklar fırlar, zeminde sekip kaybolur.
-- Sadece görseldir (çarpışmaz, sadece bu oyuncunun ekranında); parçaları kare kare elle hareket ettirir, fizik motoru kullanmaz.
local CHUNK_COUNT = 16
local CHUNK_LIFETIME = 1.6
function Juice.brickChunks(wallPart)
	local folder = Instance.new("Folder")
	folder.Name = "BrickChunks"
	folder.Parent = Workspace
	local chunks = {}
	for _ = 1, CHUNK_COUNT do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Plastic
		part.Size = Vector3.new(2, 1, 1) * (0.8 + math.random() * 0.9)
		part.Color = wallPart.Color:Lerp(Color3.new(1, 1, 1), math.random() * 0.25)
		part.TopSurface = Enum.SurfaceType.Studs
		local position = wallPart.Position + Vector3.new((math.random() - 0.5) * wallPart.Size.X * 0.8, (math.random() - 0.5) * wallPart.Size.Y * 0.8, 0)
		part.CFrame = CFrame.new(position)
		part.Parent = folder
		table.insert(chunks, {
			part = part,
			position = position,
			velocity = Vector3.new((math.random() - 0.5) * 36, 12 + math.random() * 22, (math.random() - 0.3) * 40),
			angle = Vector3.zero,
			spin = Vector3.new((math.random() - 0.5) * 12, (math.random() - 0.5) * 12, (math.random() - 0.5) * 12),
		})
	end

	local floorY = Layout.FloorTop + 0.5
	local startTime = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local elapsed = os.clock() - startTime
		if elapsed >= CHUNK_LIFETIME then
			connection:Disconnect()
			folder:Destroy()
			return
		end
		local fade = math.clamp((elapsed - (CHUNK_LIFETIME - 0.4)) / 0.4, 0, 1)
		for _, chunk in chunks do
			chunk.velocity += Vector3.new(0, -70 * dt, 0)
			chunk.position += chunk.velocity * dt
			if chunk.position.Y < floorY then
				chunk.position = Vector3.new(chunk.position.X, floorY, chunk.position.Z)
				chunk.velocity = Vector3.new(chunk.velocity.X * 0.6, math.abs(chunk.velocity.Y) * 0.35, chunk.velocity.Z * 0.6)
				chunk.spin *= 0.5
			end
			chunk.angle += chunk.spin * dt
			chunk.part.CFrame = CFrame.new(chunk.position) * CFrame.Angles(chunk.angle.X, chunk.angle.Y, chunk.angle.Z)
			chunk.part.Transparency = fade
		end
	end)
end

-- Kamera sarsıntısı: şiddet stud, süre saniye. Humanoid.CameraOffset kullanılır, süre bitince sıfırlanır.
local shakeToken = 0
function Juice.shake(strength, duration)
	if player:GetAttribute("CameraShake") == false then
		return
	end
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
	Juice.brickChunks(wallPart)
	Juice.shake(0.35, 0.3)
	sfx("WallBreak")
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
			Juice.screenPop(`+{Format.compact(delta)}`, if inArea then GREEN else Color3.fromRGB(90, 220, 255), "🦵")
		end
	end)

	wins:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = wins.Value - last.wins
		last.wins = wins.Value
		if delta > 0 and ready() then
			Juice.screenPop(`+{Format.compact(delta)} Wins`, Color3.fromRGB(255, 215, 70), "🏆", 1.25)
			Juice.celebrate(Color3.fromRGB(255, 210, 60), 25)
			sfx("Win")
		end
	end)

	-- Başlangıçta level atlamak çok sık olur: büyük yazı en fazla 4 saniyede bir çıkar, küçük patlama her seferinde
	local lastBanner = 0
	level:GetPropertyChangedSignal("Value"):Connect(function()
		local previousLevel = last.level
		local gained = level.Value > previousLevel
		last.level = level.Value
		if gained and ready() then
			if os.clock() - lastBanner > 4 then
				lastBanner = os.clock()
				Juice.banner("LEVEL UP!", GOLD)
			end
			Juice.celebrate(GOLD, 40)
			-- Her level atlayışında vücut büyür: kas aşaması da değiştiyse (yeni kas çıktı/irileşti) daha güçlü ses
			sfx(if Progression.legStage(level.Value) > Progression.legStage(previousLevel) then "GrowBig" else "Grow")
		end
	end)

	rebirths:GetPropertyChangedSignal("Value"):Connect(function()
		local gained = rebirths.Value > last.rebirths
		last.rebirths = rebirths.Value
		if gained and ready() then
			Juice.banner("REBIRTH!", PINK)
			Juice.celebrate(PINK, 90)
			Juice.shake(0.5, 0.5)
			sfx("Rebirth")
		end
	end)
end

return Juice
