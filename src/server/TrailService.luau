-- İz (trail) efektleri: takılı izi karakterin arkasında çizer ve yürüme hızını ayarlar.
-- Sunucuda yapılır, bu yüzden tüm oyuncular izi görür ve yürüme hızı sunucu tarafından belirlenir.
-- OYUNA UYGUN İZLER (2026-10-14, tester E4: 'Backpack trail'leri oyunla alakasız görünüyor'): eskiden düz renkli şeritti; şimdi her iz (Config.Trails[].fx) karakterin arkasından akan
-- oyunla ilgili bir PARÇACIK efektidir: tuğla tozu, ter damlası, protein tozu, tuğla konfeti, pati izi, kupa, bacak kası, tekme kıvılcımı ve gökkuşağı şeritli efsane izi. Parçacıklar sadece
-- koşarken açılır (Humanoid.Running) ve karakterin boyuna göre ölçeklenir (level atlayınca iz yeniden kurulur). Görseller sahibin yüklediği Config.Icons simgeleridir (tuğla, pati, kupa, bacak kası),
-- yüklenmemişse hazır Roblox parçacık dokusu (kıvılcım) kullanılır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local TrailService = {}

local EFFECT_NAME = "TrailEffect" -- (varsa) ince şerit
local BACK_NAME = "TrailBack" -- parçacıkların çıktığı bağlantı noktası (sırtın arkası)
local FX_PREFIX = "TrailFx" -- parçacık yayıcıları: TrailFx1, TrailFx2 ...

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local WHITE = Color3.new(1, 1, 1)
local RAINBOW_POINTS = {
	{ 0, Color3.fromRGB(255, 60, 60) },
	{ 0.2, Color3.fromRGB(255, 200, 40) },
	{ 0.4, Color3.fromRGB(70, 220, 90) },
	{ 0.6, Color3.fromRGB(60, 200, 255) },
	{ 0.8, Color3.fromRGB(120, 80, 255) },
	{ 1, Color3.fromRGB(255, 100, 200) },
}
local BRICK_COLORS = { Color3.fromRGB(235, 70, 70), Color3.fromRGB(255, 205, 50), Color3.fromRGB(80, 200, 90), Color3.fromRGB(70, 140, 245) }

local connections = setmetatable({}, { __mode = "k" }) -- [karakter] = Humanoid.Running bağlantısı (parçacıkları koşuya göre açıp kapatır)

-- Yüklü simgenin görsel kimliği (Config.Icons anahtarı), yoksa nil
local function iconTexture(key)
	local id = key and Config.Icons[key]
	return if type(id) == "string" and id ~= "" then id else nil
end

local function numberSeq(points, scale)
	local keys = {}
	for _, point in points do
		table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2] * (scale or 1)))
	end
	return NumberSequence.new(keys)
end

local function colorSeq(points)
	local keys = {}
	for _, point in points do
		table.insert(keys, ColorSequenceKeypoint.new(point[1], point[2]))
	end
	return ColorSequence.new(keys)
end

-- Tek renkli (başından sonuna aynı) renk listesi
local function flat(color)
	return { { 0, color }, { 1, color } }
end

-- Dört renkli tuğla konfeti: her renk ayrı yayıcı (parçacık ömrü boyunca renk değiştirmesin diye); görsel LoadingBrick simgesi (yüklenmemişse kıvılcım)
local function brickEmitters(rate, light)
	local list = {}
	for _, color in BRICK_COLORS do
		table.insert(list, {
			texture = iconTexture("LoadingBrick") or SPARKLE,
			colors = flat(color),
			size = { { 0, 0.8 }, { 1, 0.55 } },
			transparency = { { 0, 0 }, { 0.7, 0 }, { 1, 1 } },
			life = { 0.9, 1.3 },
			rate = rate,
			speed = { 2, 4 },
			spread = 55,
			rise = -14,
			spin = { -200, 200 },
			rotation = { 0, 360 },
			light = light,
		})
	end
	return list
end

-- Efekt tanımları: fx adı > { emitters = function(trail) -> yayıcı listesi, ribbon = ince şerit (isteğe bağlı) }.
-- Yayıcı alanları: texture, colors (ömür boyunca renk noktaları), size (karakter ölçeğiyle çarpılır), transparency, life, rate (saniyede parçacık), speed, spread (derece),
-- rise (Y ivmesi: eksi = düşer), spin/rotation (dönüş), light (parlaklık), dir ('Back' sırtın arkası varsayılan, 'Top' yukarı).
local FX = {
	-- Brick Dust: tuğla kırmızısı toz bulutları (duvar kırma)
	dust = {
		emitters = function(trail)
			return {
				{
					texture = SMOKE,
					colors = { { 0, trail.color }, { 1, Color3.fromRGB(150, 140, 135) } },
					size = { { 0, 0.5 }, { 1, 1.6 } },
					transparency = { { 0, 0.35 }, { 1, 1 } },
					life = { 0.6, 1 },
					rate = 14,
					speed = { 1, 2 },
					spread = 30,
					rise = 0.6,
					spin = { -60, 60 },
					rotation = { 0, 360 },
				},
			}
		end,
	},
	-- Sweat Drops: arkadan düşen mavi ter damlaları (antrenman)
	drops = {
		emitters = function(trail)
			return {
				{
					texture = SPARKLE,
					colors = { { 0, trail.color:Lerp(WHITE, 0.5) }, { 1, trail.color } },
					size = { { 0, 0.38 }, { 1, 0.12 } },
					transparency = { { 0, 0.05 }, { 1, 0.8 } },
					life = { 0.5, 0.8 },
					rate = 18,
					speed = { 3, 6 },
					spread = 45,
					rise = -22,
					light = 0.35,
				},
			}
		end,
	},
	-- Protein Powder: soluk sarı toz + altın pırıltı
	powder = {
		emitters = function(trail)
			return {
				{
					texture = SMOKE,
					colors = { { 0, trail.color }, { 1, WHITE } },
					size = { { 0, 0.4 }, { 1, 1.2 } },
					transparency = { { 0, 0.45 }, { 1, 1 } },
					life = { 0.5, 0.9 },
					rate = 12,
					speed = { 1, 2.5 },
					spread = 35,
					rise = 0.4,
				},
				{
					texture = SPARKLE,
					colors = { { 0, Color3.fromRGB(255, 240, 160) }, { 1, trail.color } },
					size = { { 0, 0.35 }, { 1, 0 } },
					transparency = { { 0, 0.1 }, { 1, 1 } },
					life = { 0.5, 0.9 },
					rate = 6,
					speed = { 1, 3 },
					spread = 60,
					light = 0.8,
				},
			}
		end,
	},
	-- Brick Confetti: dört renkli dönen tuğlalar
	bricks = {
		emitters = function()
			return brickEmitters(3, 0)
		end,
	},
	-- Pet Paws: arkada kalan pati izleri
	paws = {
		emitters = function(trail)
			local tint = trail.color:Lerp(WHITE, 0.55)
			return {
				{
					texture = iconTexture("Pet") or SPARKLE,
					colors = flat(tint),
					size = { { 0, 0.9 }, { 1, 0.9 } },
					transparency = { { 0, 0.1 }, { 0.7, 0.2 }, { 1, 1 } },
					life = { 1.1, 1.4 },
					rate = 2.5,
					speed = { 0, 0.3 },
					spread = 10,
					rotation = { -20, 20 },
					light = 0.1,
				},
			}
		end,
	},
	-- Win Trophies: havaya fırlayıp arkaya düşen kupalar (Win simgesi)
	trophies = {
		emitters = function()
			return {
				{
					texture = iconTexture("Wins") or SPARKLE,
					colors = flat(WHITE),
					size = { { 0, 0.85 }, { 1, 0.7 } },
					transparency = { { 0, 0 }, { 0.75, 0 }, { 1, 1 } },
					life = { 0.9, 1.2 },
					rate = 4,
					speed = { 3, 6 },
					spread = 40,
					rise = -16,
					spin = { -120, 120 },
					rotation = { 0, 360 },
					dir = "Top",
				},
			}
		end,
	},
	-- Muscle Power: yükselip büyüyen bacak kası simgeleri
	muscle = {
		emitters = function(trail)
			return {
				{
					texture = iconTexture("LegMuscle") or SPARKLE,
					colors = flat(trail.color:Lerp(WHITE, 0.35)),
					size = { { 0, 0.5 }, { 1, 1.3 } },
					transparency = { { 0, 0.1 }, { 1, 1 } },
					life = { 0.9, 1.2 },
					rate = 3.5,
					speed = { 1, 2 },
					spread = 35,
					rise = 2.5,
					light = 0.25,
				},
			}
		end,
	},
	-- Kick Sparks: tekme kıvılcımları ve küçük alev
	sparks = {
		emitters = function(trail)
			return {
				{
					texture = SPARKLE,
					colors = { { 0, Color3.fromRGB(255, 245, 170) }, { 0.4, trail.color }, { 1, Color3.fromRGB(255, 140, 40) } },
					size = { { 0, 0.55 }, { 1, 0 } },
					transparency = { { 0, 0 }, { 1, 1 } },
					life = { 0.3, 0.5 },
					rate = 34,
					speed = { 6, 10 },
					spread = 35,
					light = 1,
				},
				{
					texture = FIRE,
					colors = { { 0, Color3.fromRGB(255, 170, 60) }, { 1, trail.color } },
					size = { { 0, 0.9 }, { 1, 0 } },
					transparency = { { 0, 0.3 }, { 1, 1 } },
					life = { 0.3, 0.45 },
					rate = 9,
					speed = { 1, 2 },
					spread = 25,
					rise = 2,
					light = 1,
				},
			}
		end,
	},
	-- Rainbow Legend: gökkuşağı şerit + parlak tuğla konfeti + renkli pırıltı
	legend = {
		ribbon = true,
		emitters = function()
			local list = brickEmitters(2, 0.3)
			table.insert(list, {
				texture = SPARKLE,
				colors = RAINBOW_POINTS,
				size = { { 0, 0.5 }, { 1, 0 } },
				transparency = { { 0, 0 }, { 1, 1 } },
				life = { 0.5, 0.8 },
				rate = 16,
				speed = { 2, 5 },
				spread = 60,
				light = 1,
			})
			return list
		end,
	},
}
TrailService.FX = FX

local function buildEmitter(parent, spec, scale, index)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = FX_PREFIX .. index
	emitter.Texture = spec.texture or SPARKLE
	emitter.Color = colorSeq(spec.colors)
	emitter.Size = numberSeq(spec.size, scale)
	emitter.Transparency = numberSeq(spec.transparency)
	emitter.Lifetime = NumberRange.new(spec.life[1], spec.life[2])
	emitter.Rate = spec.rate
	emitter.Speed = NumberRange.new(spec.speed[1] * scale, spec.speed[2] * scale)
	emitter.SpreadAngle = Vector2.new(spec.spread, spec.spread)
	emitter.Acceleration = Vector3.new(0, spec.rise or 0, 0)
	emitter.LightEmission = spec.light or 0
	emitter.EmissionDirection = if spec.dir == "Top" then Enum.NormalId.Top else Enum.NormalId.Back
	if spec.spin then
		emitter.RotSpeed = NumberRange.new(spec.spin[1], spec.spin[2])
	end
	if spec.rotation then
		emitter.Rotation = NumberRange.new(spec.rotation[1], spec.rotation[2])
	end
	emitter.Enabled = false -- koşunca açılır (bindMovement)
	emitter.Parent = parent
	return emitter
end

-- İnce şerit (sadece Rainbow Legend): sırtın arkasında kısa gökkuşağı
local function buildRibbon(torso, halfSpan, back, trail)
	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, halfSpan, back)
	top.Parent = torso

	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -halfSpan, back)
	bottom.Parent = torso

	local effect = Instance.new("Trail")
	effect.Name = EFFECT_NAME
	effect.Attachment0 = top
	effect.Attachment1 = bottom
	effect.Color = if trail.rainbow then colorSeq(RAINBOW_POINTS) else ColorSequence.new(trail.color)
	effect.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	effect.Lifetime = 0.4
	effect.LightEmission = 0.7
	effect.FaceCamera = true
	effect.MinLength = 0.1
	effect.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	effect.Parent = torso
end

-- Parçacıklar sadece koşarken çıkar (Humanoid.Running hızı > 1); duruyorsa kapalı
local function bindMovement(character, emitters)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local function setMoving(speed)
		for _, emitter in emitters do
			emitter.Enabled = speed > 1
		end
	end
	setMoving(if humanoid.MoveDirection.Magnitude > 0.1 then Config.BaseWalkSpeed else 0)
	connections[character] = humanoid.Running:Connect(setMoving)
end

-- İz, karakterin sırtından (gövdenin arka yüzünden) çıkar. Dönüş: kurulan yayıcıların listesi
function TrailService.build(character, trail)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	if not torso then
		return {}
	end
	local back = torso.Size.Z / 2 + 0.05 -- karakter -Z'ye bakar, sırt +Z tarafındadır
	local halfSpan = torso.Size.Y * 0.28
	local scale = math.clamp(torso.Size.Y / 1.6, 0.7, 3) -- karakter büyüdükçe parçacıklar da büyür

	local fx = FX[trail.fx]
	if not fx then
		-- Bilinmeyen efekt adı: düz renkli şerit (eski görünüm), oyun bozulmasın
		buildRibbon(torso, halfSpan, back, trail)
		return {}
	end

	local anchor = Instance.new("Attachment")
	anchor.Name = BACK_NAME
	anchor.Position = Vector3.new(0, 0, back)
	anchor.Parent = torso

	local emitters = {}
	for index, spec in fx.emitters(trail) do
		table.insert(emitters, buildEmitter(anchor, spec, scale, index))
	end
	if fx.ribbon then
		buildRibbon(torso, halfSpan, back, trail)
	end
	bindMovement(character, emitters)
	return emitters
end

local function clear(character)
	local connection = connections[character]
	if connection then
		connection:Disconnect()
		connections[character] = nil
	end
	for _, descendant in character:GetDescendants() do
		local name = descendant.Name
		if name == EFFECT_NAME or name == "TrailTop" or name == "TrailBottom" or name == BACK_NAME then
			descendant:Destroy() -- (TrailBack'in altındaki yayıcılar onunla gider)
		end
	end
end

-- Takılı ize göre yürüme hızını ve iz efektini ayarlar
local function apply(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end

	local trail = Catalog.TrailById[player:GetAttribute("EquippedTrail") or ""]
	humanoid.WalkSpeed = Config.BaseWalkSpeed + (if trail then trail.speed else 0)

	clear(character)
	if trail then
		TrailService.build(character, trail)
	end
end

local function watch(player)
	local function onCharacter(character)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Humanoid", 10)
		apply(player)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- İz takılınca/çıkarılınca ve kayıtlı veri yüklenince güncelle
	player:GetAttributeChangedSignal("EquippedTrail"):Connect(function()
		apply(player)
	end)

	-- Karakter büyüyünce (level) iz bağlantı noktaları ve parçacık boyu yeni ölçüye uysun
	local leaderstats = player:WaitForChild("leaderstats")
	local level = leaderstats:WaitForChild(Config.StatLevel)
	level:GetPropertyChangedSignal("Value"):Connect(function()
		task.delay(0.4, apply, player)
	end)
end

function TrailService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

return TrailService
