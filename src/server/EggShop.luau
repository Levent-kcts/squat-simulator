-- Lobinin ARKA duvarındaki yumurtalar (kırılan duvarların tam karşısı): ayakkabı/skin rafıyla aynı stand (server/Shelf), iki
-- basamak: alt sırada 3, üst sırada 3 yumurta. Yumurtaya yaklaşınca bir panel açılır (pet şansları görünür); E tuşu veya Open
-- butonu Win karşılığı açar. Pedin rengi ve etiketler oyuncuya özeldir, istemcide (client/EggShop) ayarlanır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))
local EggRules = require(Shared:WaitForChild("EggRules"))

local EggShop = {}

local OPEN_RANGE = 16 -- yumurta açmak için pede en fazla bu kadar yakın olunmalı (stud, yatay)
local MIN_OPEN_INTERVAL = 0.3 -- iki açma isteği arası en az süre (saniye)

local EGG_SCALE = 0.86 -- yumurta boyutu (referans fotoğrafta yumurta boyu karakter boyundan biraz büyük)

-- Stand ölçüleri: yumurta pedin arkasında durur (referans fotoğraftaki gibi küçük ped önde), şeritler kısa.
-- 3. şerit (en arkada, duvara yaslı, en yüksek) PEDSİZ bir teras: Worlds geçidinin (server/WorldsGate) önündeki düzlük. Config.Worlds.TerraceDepth/TerraceHeight.
-- Yumurtaların 'PET EGGS' tabelası geçidin iki yanında asılıdır (ortayı kemer kaplar).
local WORLDS = Config.Worlds
local LAYOUT = {
	rowCounts = { 3, 3, 0 },
	laneDepths = { 11, 11, WORLDS.TerraceDepth },
	padSize = 5,
	padHeight = 1,
	padSpacing = 12.5,
	laneDepth = 11,
	tierHeights = { 0.4, 3.4, WORLDS.TerraceHeight },
	rampWidth = 5,
	signSize = Vector3.new(12, 4.5, 0.5),
	signXs = { -15, 15 },
	signY = 19, -- yumurta etiketleriyle (en üst yumurta ~11 stud) çakışmasın diye yüksekte
	displayLift = 3.1 * EGG_SCALE + 0.6, -- yumurta merkezi: ped tepesi + yumurta yarı boyu + biraz boşluk
	padZOffset = -2.2, -- ped şeridin ortasının önünde
	displayZ = 4.2, -- yumurta pedin arkasında
}

EggShop.Layout = LAYOUT -- (testler için)

-- Yumurta modeli: elips gövde + yüzeyine serpilmiş benekler. Yerel -Z izleyiciye bakar.
local function buildEgg(parent, egg, frame, center)
	local model = Instance.new("Model")
	model.Name = `Egg_{egg.id}`

	-- Blender yumurtası (fantastik süslü model, shared/ModelLibrary 'egg_<id>') varsa o; yoksa aşağıdaki kod yumurtası
	local mesh, offset = ModelLibrary.create("egg_" .. egg.id, Config.Models.EggScale)
	if mesh then
		mesh.Name = "Shell"
		local origin = frame * CFrame.new(center - Vector3.new(0, 3.6 * EGG_SCALE, 0)) -- modelin orijini tabanın ortasıdır
		mesh.CFrame = ModelLibrary.cframe(origin, offset)
		mesh.Parent = model
		model.Parent = parent
		return
	end

	local function sphere(name, size, offset, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size
		p.CFrame = frame * CFrame.new(center + offset)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		p.Parent = model
		return p
	end

	local radiusX, radiusY = 2.8 * EGG_SCALE, 3.6 * EGG_SCALE
	sphere("Shell", Vector3.new(radiusX * 2, radiusY * 2, radiusX * 2), Vector3.zero, egg.color)

	-- Benekler: yumurtanın izleyiciye bakan yarısında, farklı yükseklik ve açılarda
	local spots = { { 200, 40 }, { 235, 75 }, { 270, 55 }, { 305, 80 }, { 330, 45 }, { 250, 110 }, { 290, 120 } }
	for _, spot in spots do
		local theta, phi = math.rad(spot[1]), math.rad(spot[2])
		local offset = Vector3.new(
			radiusX * math.sin(phi) * math.cos(theta),
			radiusY * math.cos(phi),
			radiusX * math.sin(phi) * math.sin(theta)
		)
		local size = (0.9 + (spot[2] % 3) * 0.3) * EGG_SCALE
		sphere("Spot", Vector3.new(size, size, size * 0.6), offset * 0.97, egg.accent)
	end

	model.Parent = parent
end

-- Açma isteğinin game pass kuralı: x2-x3 Triple Open'ı, x4-x10 Mega Open'ı, otomatik açma (auto = true) Auto Open'ı ister; tek yumurta ücretsizdir. Döner: izin var mı, mesaj
function EggShop.checkPasses(player, count, auto)
	local needed = EggRules.passForCount(count)
	if needed and not EggRules.owns(player, needed) then
		return false, `{needed.name} is a paid upgrade: unlock it in the egg panel.`
	end
	if auto == true and not EggRules.owns(player, EggRules.autoPass()) then
		return false, "Auto Open is a paid upgrade: unlock it in the egg panel."
	end
	return true, nil
end

function EggShop.init(notifyEvent)
	local _, pads = Shelf.build({
		name = "EggShop",
		frame = Shelf.backWallFrame(),
		title = "PET EGGS",
		signColor = Color3.fromRGB(255, 110, 190),
		items = Config.Eggs,
		layout = LAYOUT,
		buildDisplay = buildEgg,
	})

	-- Yumurta açma isteği: istemci paneldeki E tuşunda / Open butonunda çağırır. Her şey sunucuda doğrulanır:
	-- oyuncu yumurtaya yakın olmalı, Win yetmeli, çok sık istek atılamaz.
	local openFunction = Instance.new("RemoteFunction")
	openFunction.Name = "EggOpen"
	openFunction.Parent = ReplicatedStorage

	local lastOpen = {}
	Players.PlayerRemoving:Connect(function(player)
		lastOpen[player.UserId] = nil
	end)

	-- auto: istemci otomatik açma döngüsünden mi çağırıyor (Auto Open pass'i ister). x2+ açma da ilgili pass'i ister (shared/EggRules). Tek yumurta (x1) elle açmak ücretsizdir.
	openFunction.OnServerInvoke = function(player, eggId, count, auto)
		if type(eggId) ~= "string" or type(count) ~= "number" then
			return false, "Invalid request."
		end
		count = math.clamp(math.floor(count), 1, Config.EggMultiOptions[#Config.EggMultiOptions])
		local allowed, denied = EggShop.checkPasses(player, count, auto)
		if not allowed then
			notifyEvent:FireClient(player, false, denied)
			return false, denied
		end
		local pad = pads[eggId]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not pad or not root then
			return false, "Invalid request."
		end

		local delta = root.Position - pad.Position
		if Vector3.new(delta.X, 0, delta.Z).Magnitude > OPEN_RANGE or math.abs(delta.Y) > 14 then
			return false, "Move closer to the egg."
		end

		local now = os.clock()
		if now - (lastOpen[player.UserId] or 0) < MIN_OPEN_INTERVAL then
			return false, "Slow down!"
		end
		lastOpen[player.UserId] = now

		local ok, message, results = PlayerStats.hatchEgg(player, eggId, count)
		if not ok or not results then
			notifyEvent:FireClient(player, ok, message) -- başarısızlık mesajı; başarıda istemci açılış ekranını gösterir
		end
		return ok, message, results
	end
end

return EggShop
