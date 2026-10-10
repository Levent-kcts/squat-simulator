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

-- Performans modülü korumalı yüklenir (hafif grafik modunda kazanç yazıları daha seyrek çıkar)
local okPerf, Performance = pcall(require, script.Parent.Performance)
local POP_INTERVAL = 0.2 -- saniye: kas kazancı yazıları en çok bu aralıkla çıkar (aradaki kazançlar toplanır)
local POP_INTERVAL_LOW = 0.32

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

-- Config.Icons'ta görsel yüklüyse onu, yoksa emojiyi verir (ekran yazılarının simgesi)
local function popIcon(key, emoji)
	local id = Config.Icons[key]
	return if type(id) == "string" and id ~= "" then id else emoji
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

	-- icon: emoji ya da görsel kimliği ('rbxassetid://...': Config.Icons yüklüyse)
	local iconLabel
	if string.find(tostring(icon), "rbxassetid://", 1, true) == 1 then
		iconLabel = Instance.new("ImageLabel")
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = icon
		iconLabel.ScaleType = Enum.ScaleType.Fit
		iconLabel.Parent = holder
	else
		iconLabel = styledLabel(holder, icon or "🦵", Color3.new(1, 1, 1), 0)
	end
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
	TweenService:Create(iconLabel, fade, if iconLabel:IsA("ImageLabel") then { ImageTransparency = 1 } else { TextTransparency = 1 }):Play()
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
	holder.Position = UDim2.fromScale(0.5, 0.26) -- biraz yukarıda: ekranın ortasındaki karakteri ve alttaki yazıları kapatmasın
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
	holder.Size = UDim2.fromOffset(100, 30)
	TweenService:Create(holder, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(if subText then 440 else 330, if subText then 108 else 84) }):Play()
	Debris:AddItem(holder, if subText then 2.9 else 1.8)
end

-- Parçacık aileleri (Config.Wall.Themes[].fx): hız/ömür aralığı, yerçekimi (eksi = yükselir), boyut, parlaklık, isteğe bağlı doku ve içe çekilme.
-- Dokular Roblox'un kendi parçacık dokularıdır; yüklenemezse parçacık görünmez ama oyun etkilenmez.
local FX = {
	chips = { speed = { 14, 30 }, gravity = 35, size = 1.4, life = { 0.6, 1.2 }, light = 0.4 }, -- kırıntı (ahşap, taş, ana ayar)
	puff = { texture = "rbxasset://textures/particles/smoke_main.dds", speed = { 6, 16 }, gravity = 10, size = 2.6, life = { 0.9, 1.7 }, light = 0, startTransparency = 0.3 }, -- toz / kağıt
	sparks = { speed = { 26, 46 }, gravity = 30, size = 0.9, life = { 0.4, 0.9 }, light = 1 }, -- metal kıvılcımı
	gems = { speed = { 8, 22 }, gravity = -4, size = 1.7, life = { 1, 1.9 }, light = 0.9 }, -- mücevher parıltısı (yavaş yükselir)
	embers = { texture = "rbxasset://textures/particles/fire_main.dds", speed = { 10, 26 }, gravity = -12, size = 2.1, life = { 0.8, 1.5 }, light = 1 }, -- kor
	implode = { speed = { 16, 28 }, gravity = 0, size = 1.9, life = { 0.7, 1.2 }, light = 0.3, inward = true }, -- içeri çekilme (Blackhole)
}

-- Verilen konumda renkli parçacık patlaması (duvar kırılması, kutlama). size: patlamanın kapladığı hacim.
-- fxName: parçacık ailesi (FX; yoksa chips), accent: ikinci renk (yoksa rengin açığı)
function Juice.burst(position, size, color, amount, fxName, accent)
	local fx = FX[fxName or "chips"] or FX.chips
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = size
	anchor.Position = position
	anchor.Parent = Workspace

	-- Koyu temalarda (Blackhole, Obsidian) duvar rengi parçacık olarak görünmez: parıltı rengiyle başlanır
	local start = color
	if accent and (color.R * 0.3 + color.G * 0.59 + color.B * 0.11) < 0.2 then
		start = accent
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Color = ColorSequence.new(start, accent or color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.LightEmission = fx.light
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, fx.size), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, fx.startTransparency or 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(fx.life[1], fx.life[2])
	emitter.Speed = NumberRange.new(fx.speed[1], fx.speed[2])
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -fx.gravity, 0)
	emitter.RotSpeed = NumberRange.new(-200, 200)
	if fx.texture then
		emitter.Texture = fx.texture
	end
	if fx.inward then
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	end
	emitter.Parent = anchor
	emitter:Emit(amount or 60)

	Debris:AddItem(anchor, 2)
end

-- Sağlam duvarın etrafında dolaşan sürekli parçacık (Config.Wall.Themes[].ambient: sparkle, embers, implode). Yoksa nil döner.
-- Duvar kırılınca WallClient emitter.Enabled = false yapar, geri gelince true.
function Juice.addWallAmbient(part, theme)
	local kind = theme and theme.ambient
	if not kind then
		return nil
	end
	local accent = theme.accent or Color3.new(1, 1, 1)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = 5
	emitter.Lifetime = NumberRange.new(1.3, 2.4)
	emitter.Speed = NumberRange.new(0.5, 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 0.9
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.9), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.1), NumberSequenceKeypoint.new(1, 1) })
	emitter.Acceleration = Vector3.new(0, 1.5, 0)
	emitter.Color = ColorSequence.new(accent, Color3.new(1, 1, 1))
	if kind == "embers" then
		emitter.Texture = FX.embers.texture
		emitter.Rate = 7
		emitter.Acceleration = Vector3.new(0, 6, 0)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.Color = ColorSequence.new(accent, Color3.fromRGB(255, 80, 20))
	elseif kind == "implode" then
		emitter.Rate = 10
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		emitter.Speed = NumberRange.new(3, 6)
		emitter.Acceleration = Vector3.zero
		emitter.Color = ColorSequence.new(accent, Color3.fromRGB(30, 10, 60))
		emitter.LightEmission = 0.5
	end
	emitter.Parent = part
	return emitter
end

-- Kırılan duvardan uçan lego parçaları: duvar renginde küçük, çıkıntılı bloklar fırlar, zeminde sekip kaybolur.
-- Sadece görseldir (çarpışmaz, sadece bu oyuncunun ekranında); parçaları kare kare elle hareket ettirir, fizik motoru kullanmaz.
local CHUNK_COUNT = 16
local CHUNK_LIFETIME = 1.6
function Juice.brickChunks(wallPart, theme)
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
		part.Color = (if theme then theme.color else wallPart.Color):Lerp(Color3.new(1, 1, 1), math.random() * 0.25)
		part.Reflectance = if theme then theme.reflect or 0 else 0
		if theme and theme.fx == "implode" then
			-- Blackhole parçaları simsiyah olurdu, görünmezdi: parlak mor Neon
			part.Material = Enum.Material.Neon
			part.Color = theme.accent:Lerp(Color3.new(0, 0, 0), math.random() * 0.6)
		end
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
function Juice.wallBroken(wallPart, theme)
	local root = rootPart()
	if not root or not wallPart then
		return
	end
	if (root.Position - wallPart.Position).Magnitude > 90 then
		return
	end
	-- Ses ilk iş: parçacık ve lego parçası kurmak birkaç kare sürebilir, ses onları beklemesin
	sfx("WallBreak")
	local fx = theme and theme.fx
	Juice.burst(wallPart.Position, Vector3.new(wallPart.Size.X * 0.8, wallPart.Size.Y * 0.6, 2), if theme then theme.color else wallPart.Color, if fx == "gems" or fx == "implode" then 120 else 90, fx, theme and theme.accent)
	Juice.brickChunks(wallPart, theme)
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

	-- Kas kazancı yazıları BİRLEŞTİRİLİR: Auto Click saniyede 10 tıklama yapar ve her biri için ayrı yazı (çerçeve + 3 yazı + 5 geçiş animasyonu) çıkarmak telefonu yoruyordu.
	-- En çok POP_INTERVAL saniyede bir yazı çıkar ve o aradaki kazançların TOPLAMINI gösterir (yavaş oyunda hâlâ her kazançta anında çıkar)
	local popPending, popTimer, lastPopAt = 0, false, -10
	local function flushPop()
		popTimer = false
		if popPending <= 0 then
			return
		end
		local amount = popPending
		popPending = 0
		lastPopAt = os.clock()
		local inArea = (player:GetAttribute("AreaMultiplier") or 1) > 1
		Juice.screenPop(`+{Format.compact(amount)}`, if inArea then GREEN else Color3.new(1, 1, 1), popIcon("LegMuscle", "🦵")) -- beyaz (sahibi mavi yerine beyaz istedi); antrenman alanında yeşil
	end
	muscle:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = muscle.Value - last.muscle
		last.muscle = muscle.Value
		if delta > 0 and ready() then
			popPending += delta
			if not popTimer then
				popTimer = true
				local interval = if okPerf and Performance.low then POP_INTERVAL_LOW else POP_INTERVAL
				task.delay(math.max(0, lastPopAt + interval - os.clock()), flushPop)
			end
		end
	end)

	wins:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = wins.Value - last.wins
		last.wins = wins.Value
		if delta > 0 and ready() then
			Juice.screenPop(`+{Format.compact(delta)} Wins`, Color3.fromRGB(255, 215, 70), popIcon("Wins", "🏆"), 1.25)
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
