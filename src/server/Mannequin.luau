-- Basit manken: kafa, gövde, kollar, bacaklar ve siyah şort. Skin rafındaki skin mankeni ve antrenman alanındaki antrenör
-- yer tutucusu bunu kullanır. Yüzü izleyiciye (yerel -Z) bakar, tabanı center yüksekliğindedir.
-- ANTRENÖRLER: ReplicatedStorage > GameModels içinde Blender koçu 'coach_<kıyafet>' varsa (shared/ModelLibrary) o gösterilir
-- (parçacıklar kodla eklenir); yoksa aşağıdaki kod mankeni kıyafetiyle kurulur.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))

local Mannequin = {}

local SHORTS_COLOR = Color3.fromRGB(20, 20, 25)

-- ---------------------------------------------------------------------------------------------
-- ANTRENÖR KIYAFETLERİ: her koç kendine özgü bir aksesuar ve küçük parçacık taşır (kafa merkezi y = 4.65, yarıçap ~0.65, birimler ölçeksiz).
-- Her kıyafet (part, skin) alır; part(ad, boyut, konum, renk, şekil, malzeme, dönüş) bir Part döndürür ve modele ekler.
-- ---------------------------------------------------------------------------------------------
local NEON = Enum.Material.Neon
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local SIDEWAYS = CFrame.Angles(0, 0, math.pi / 2) -- silindiri dikey eksene yatırır (halka/bant)

-- Parçaya bağlı küçük parçacık efekti (kıvılcım, ateş, kar, duman)
local function emitter(host, props)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(props.from, props.to or props.from)
	e.LightEmission = props.light or 0.6
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, props.size or 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(props.life or 0.8, (props.life or 0.8) + 0.5)
	e.Rate = props.rate or 6
	e.Speed = NumberRange.new(props.speed or 1, (props.speed or 1) + 1.5)
	e.SpreadAngle = Vector2.new(props.spread or 25, props.spread or 25)
	e.Acceleration = Vector3.new(0, props.rise or 0, 0)
	if props.texture then
		e.Texture = props.texture
	end
	e.Parent = host
	return e
end

local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Parçacık ayarları (hem kod mankeninde hem Blender koçunda aynı); hostAt: Blender koçunda parçacığın çıkacağı yer (taban merkezine göre, birimler ölçeksiz)
local FX = {
	flame = { from = Color3.fromRGB(255, 70, 20), to = Color3.fromRGB(255, 200, 60), texture = FIRE, size = 1.3, rate = 12, speed = 2, rise = 4, life = 0.7, light = 1, hostAt = Vector3.new(0, 6.0, 0) },
	ember = { from = Color3.fromRGB(255, 160, 40), to = Color3.fromRGB(255, 60, 20), texture = FIRE, size = 0.7, rate = 7, speed = 1.5, rise = 3, spread = 60, life = 1, hostAt = Vector3.new(0, 6.0, 0) },
	frost = { from = Color3.fromRGB(235, 250, 255), size = 0.45, rate = 8, speed = 0.5, rise = -2, spread = 90, life = 1.4, light = 0.4, hostAt = Vector3.new(0, 7.2, 0) },
	volt = { from = Color3.fromRGB(255, 250, 150), to = Color3.fromRGB(255, 220, 40), size = 0.35, rate = 14, speed = 4, spread = 180, life = 0.35, light = 1, hostAt = Vector3.new(0.26, 6.6, 0) },
	nova = { from = Color3.fromRGB(230, 190, 255), to = Color3.fromRGB(150, 90, 255), size = 0.5, rate = 8, speed = 1, spread = 180, life = 1.2, light = 1, hostAt = Vector3.new(0, 6.05, 0) },
	shadow = { from = Color3.fromRGB(60, 40, 90), to = Color3.fromRGB(20, 15, 30), texture = SMOKE, size = 1.4, rate = 7, speed = 0.8, rise = 1.5, spread = 40, life = 1.4, light = 0, hostAt = Vector3.new(0, 5.2, -0.5) },
}

-- EK EFEKTLER (sahibi 'Shadow'a birazcık daha efekt ekle' dedi): ana parçacığın yanında ek parçacık kümeleri ve ışık. at: taban merkezine göre yer (birimler ölçeksiz, hostAt gibi).
-- Shadow: vücuttan yükselen parlayan mor kıvılcımlar, zeminde yayılan koyu sis ve etrafına hafif mor ışık. Hem Blender koçunda hem kod mankeninde aynı kurulur.
local EXTRA_FX = {
	shadow = {
		{ name = "ShadowSparks", at = Vector3.new(0, 2.6, 0), fx = { from = Color3.fromRGB(215, 120, 255), to = Color3.fromRGB(90, 30, 170), size = 0.42, rate = 13, speed = 1.2, rise = 4.5, spread = 55, life = 1.3, light = 1 } },
		{ name = "ShadowFog", at = Vector3.new(0, 0.5, 0), fx = { from = Color3.fromRGB(45, 25, 80), to = Color3.fromRGB(12, 8, 22), texture = SMOKE, size = 2.6, rate = 5, speed = 0.9, spread = 180, life = 2.2, light = 0 } },
		{ name = "ShadowGlow", at = Vector3.new(0, 3.2, 0), light = { color = Color3.fromRGB(170, 80, 255), brightness = 1.4, range = 11 } },
	},
}

-- outfit'in ek efektlerini kurar. makeHost(ad, konum): görünmez bir ev sahibi parça döndürür (konum taban merkezine göre, ölçeksiz); scale: koçun boyutu (büyük koçta parçacık ve ışık da büyür)
local function addExtraFx(outfit, makeHost, scale)
	for _, extra in EXTRA_FX[outfit] or {} do
		local host = makeHost(extra.name, extra.at)
		if extra.fx then
			local fx = table.clone(extra.fx)
			fx.size = (fx.size or 0.6) * scale
			fx.speed = (fx.speed or 1) * scale
			fx.rise = (fx.rise or 0) * scale
			emitter(host, fx)
		end
		if extra.light then
			local glow = Instance.new("PointLight")
			glow.Color = extra.light.color
			glow.Brightness = extra.light.brightness
			glow.Range = extra.light.range * scale
			glow.Shadows = false
			glow.Parent = host
		end
	end
end

-- Kafayı saran renkli bant
local function band(part, color)
	return part("Headband", Vector3.new(0.22, 1.4, 1.4), Vector3.new(0, 4.95, 0), color, CYLINDER, nil, SIDEWAYS)
end

local OUTFITS = {
	-- Sprout: yaprak tacı ve toprak rengi bant
	leaf = function(part)
		band(part, Color3.fromRGB(120, 78, 36))
		for index = 0, 4 do
			local angle = math.rad(index * 72)
			part("Leaf", Vector3.new(0.34, 0.34, 0.34), Vector3.new(math.cos(angle) * 0.55, 5.3, math.sin(angle) * 0.55), Color3.fromRGB(70, 215, 95), BALL)
		end
	end,
	-- Wave: mavi bant ve arkada iki kuyruk
	wave = function(part)
		band(part, Color3.fromRGB(40, 110, 255))
		for _, side in { -1, 1 } do
			part("BandTail", Vector3.new(0.2, 0.9, 0.12), Vector3.new(side * 0.25, 4.5, 0.72), Color3.fromRGB(40, 110, 255))
		end
	end,
	-- Blaze: kırmızı bant ve başta alev
	flame = function(part)
		band(part, Color3.fromRGB(235, 40, 40))
		local top = part("FlameHost", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 5.4, 0), Color3.fromRGB(255, 120, 30), BALL, NEON)
		top.Transparency = 1
		emitter(top, FX.flame)
	end,
	-- Ember: turuncu bant, bileklikler ve uçuşan közler
	ember = function(part)
		band(part, Color3.fromRGB(255, 140, 20))
		for _, side in { -1, 1 } do
			part("Wristband", Vector3.new(0.25, 0.95, 0.95), Vector3.new(side * 1.45, 2.25, 0), Color3.fromRGB(255, 140, 20), CYLINDER, nil, SIDEWAYS)
		end
		local host = part("EmberHost", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 5.2, 0), Color3.fromRGB(255, 150, 30), BALL, NEON)
		host.Transparency = 1
		emitter(host, FX.ember)
	end,
	-- Pixel: kare güneş gözlüğü ve havada süzülen pikseller
	pixel = function(part)
		part("Shades", Vector3.new(1.5, 0.3, 0.2), Vector3.new(0, 4.78, -0.62), Color3.fromRGB(20, 20, 28))
		for _, side in { -1, 1 } do
			part("Lens", Vector3.new(0.5, 0.2, 0.1), Vector3.new(side * 0.36, 4.78, -0.74), Color3.fromRGB(255, 60, 230), nil, NEON)
		end
		for _, spot in { Vector3.new(-1.1, 5.7, 0.2), Vector3.new(1.0, 6.1, -0.2), Vector3.new(0.2, 6.6, 0.3) } do
			part("PixelBit", Vector3.new(0.28, 0.28, 0.28), spot, Color3.fromRGB(255, 60, 230), nil, NEON)
		end
	end,
	-- Frost: buz tacı ve yağan kar
	frost = function(part)
		for index = 0, 4 do
			local angle = math.rad(index * 72)
			part("IceSpike", Vector3.new(0.2, 0.7, 0.2), Vector3.new(math.cos(angle) * 0.5, 5.45, math.sin(angle) * 0.5), Color3.fromRGB(190, 245, 255), nil, Enum.Material.Glass)
		end
		local host = part("SnowHost", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 6.3, 0), Color3.fromRGB(255, 255, 255), BALL)
		host.Transparency = 1
		emitter(host, FX.frost)
	end,
	-- Volt: şimşek şeklinde saç ve kıvılcım
	volt = function(part)
		part("Bolt", Vector3.new(0.3, 0.5, 0.2), Vector3.new(0.2, 5.5, 0), Color3.fromRGB(255, 235, 60), nil, NEON)
		part("Bolt", Vector3.new(0.3, 0.5, 0.2), Vector3.new(-0.1, 5.9, 0), Color3.fromRGB(255, 235, 60), nil, NEON)
		local tip = part("Bolt", Vector3.new(0.3, 0.5, 0.2), Vector3.new(0.2, 6.3, 0), Color3.fromRGB(255, 235, 60), nil, NEON)
		emitter(tip, FX.volt)
	end,
	-- Nova: başının üstünde mor halka (hale) ve yıldız parıltısı
	nova = function(part)
		local halo = part("Halo", Vector3.new(0.12, 1.9, 1.9), Vector3.new(0, 6.0, 0), Color3.fromRGB(190, 120, 255), CYLINDER, NEON, SIDEWAYS)
		emitter(halo, FX.nova)
	end,
	-- Prism: gökkuşağı renkli taç parçaları
	prism = function(part)
		for index = 0, 6 do
			local angle = math.rad(index * (360 / 7))
			part("Gem", Vector3.new(0.3, 0.5, 0.3), Vector3.new(math.cos(angle) * 0.52, 5.4, math.sin(angle) * 0.52), Color3.fromHSV(index / 7, 0.85, 1), nil, NEON)
		end
	end,
	-- Shadow: koyu kukuleta, parlayan mor gözler ve duman
	shadow = function(part)
		part("Hood", Vector3.new(1.55, 1.55, 1.55), Vector3.new(0, 4.75, 0.28), Color3.fromRGB(14, 12, 20), BALL)
		for _, side in { -1, 1 } do
			part("GlowEye", Vector3.new(0.24, 0.24, 0.24), Vector3.new(side * 0.28, 4.75, -0.7), Color3.fromRGB(190, 90, 255), BALL, NEON)
		end
		local host = part("SmokeHost", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0, 5.0, 0.3), Color3.fromRGB(20, 15, 30), BALL)
		host.Transparency = 1
		emitter(host, FX.shadow)
	end,
}

-- parent: modelin konacağı klasör, name: model adı, frame: raf çerçevesi, center: yerel taban konumu,
-- scale: boyut (1 = ~5.3 stud boy), skin: vücut rengi, shorts: şort rengi (varsayılan siyah),
-- outfit: antrenörün kıyafeti/parçacığı (leaf, wave, flame, ember, pixel, frost, volt, nova, prism, shadow; yoksa sade manken)
function Mannequin.build(parent, name, frame, center, scale, skin, shorts, outfit)
	local model = Instance.new("Model")
	model.Name = name

	-- Blender koçu (coach_<kıyafet>): tek MeshPart, rengi dokusundan gelir; parçacıklar görünmez ev sahiplerine kodla eklenir
	local mesh, offset = nil, nil
	if outfit then
		mesh, offset = ModelLibrary.create("coach_" .. outfit, scale * Config.Models.CoachScale)
	end
	if mesh then
		mesh.Name = "Coach"
		mesh.CFrame = ModelLibrary.cframe(frame * CFrame.new(center), offset) -- modelin orijini tabanın ortasıdır
		mesh.Parent = model
		local fx = FX[outfit]
		if fx then
			local host = Instance.new("Part")
			host.Name = "FxHost"
			host.Anchored = true
			host.CanCollide = false
			host.CanQuery = false
			host.CanTouch = false
			host.Size = Vector3.new(0.3, 0.3, 0.3) * scale
			host.CFrame = frame * CFrame.new(center + fx.hostAt * scale)
			host.Transparency = 1
			host.Parent = model
			emitter(host, fx)
		end
		addExtraFx(outfit, function(hostName, at)
			local extraHost = Instance.new("Part")
			extraHost.Name = hostName
			extraHost.Anchored = true
			extraHost.CanCollide = false
			extraHost.CanQuery = false
			extraHost.CanTouch = false
			extraHost.Size = Vector3.new(0.3, 0.3, 0.3) * scale
			extraHost.CFrame = frame * CFrame.new(center + at * scale)
			extraHost.Transparency = 1
			extraHost.Parent = model
			return extraHost
		end, scale)
		model.Parent = parent
		return model
	end

	local function part(partName, size, offset, color, shape, material, rotation)
		local p = Instance.new("Part")
		p.Name = partName
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size * scale
		p.CFrame = frame * CFrame.new(center + offset * scale) * (rotation or CFrame.new())
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end

	for _, side in { -1, 1 } do
		part("Leg", Vector3.new(0.9, 2, 0.9), Vector3.new(side * 0.5, 1, 0), skin)
		part("Arm", Vector3.new(0.8, 2, 0.8), Vector3.new(side * 1.45, 3, 0), skin)
	end
	part("Shorts", Vector3.new(2, 0.9, 1.1), Vector3.new(0, 1.9, 0), shorts or SHORTS_COLOR)
	part("Torso", Vector3.new(2, 1.9, 1), Vector3.new(0, 3.05, 0), skin)
	part("Head", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.65, 0), skin, Enum.PartType.Ball)

	-- Basit yüz (iki göz)
	for _, side in { -1, 1 } do
		part("Eye", Vector3.new(0.18, 0.18, 0.18), Vector3.new(side * 0.28, 4.75, -0.62), Color3.fromRGB(30, 30, 40), Enum.PartType.Ball)
	end

	if outfit and OUTFITS[outfit] then
		OUTFITS[outfit](part, skin)
		addExtraFx(outfit, function(hostName, at)
			local extraHost = part(hostName, Vector3.new(0.3, 0.3, 0.3), at, Color3.new(0, 0, 0), BALL)
			extraHost.Transparency = 1
			return extraHost
		end, scale)
	end

	model.Parent = parent
	return model
end

return Mannequin
