-- Günlük çark: lobinin sağ arka köşesinde (sahibi 'bu köşeye koy' dedi), lobinin ortasına (spawn'a) doğru dönük, lego sütunlu bir kapı çerçevesinin içinde duran dönen ödül çarkı.
-- Burada sadece GÖRÜNÜŞ ve etkileşim noktası kurulur; çarkın yüzü (8 dilim) shared/WheelFace ile SurfaceGui'ye çizilir. Çevirme mantığı (günde 1 hak, ödül seçimi) PlayerStats.spinWheel'dedir,
-- dönüş animasyonu ve E'ye basınca açılan arayüz client/WheelController ve client/WheelPanel'dedir.
-- İki parça kurulur: Workspace.DailyWheel (dönen Model: yüz, altın halka, göbek, lambalar; PrimaryPart = 'WheelPivot') ve Workspace.DailyWheelStand (sabit klasör: kaide, sütunlar, tabela,
-- ibre, ProximityPrompt, durum yazısı 'SpinLabel'). Koridorda/lobide yeni ışık paneli YOK kuralı korunur (sadece parlayan Neon lambalar).
-- YÜZ NASIL YUVARLAK GÖRÜNÜR: SurfaceGui içindeki CanvasGroup daireye kırpmadı (kare görünüyordu, sahibi 'yuvarlak üstü kare olmuş çok kötü' dedi). Bu yüzden yüz KARE çizilir ve
-- önüne, karenin köşelerini (merkezden 1.414 x yarıçap uzaklığa kadar) örten kalın bir ALTIN HALKA konur (halka = çevreye dizilmiş bloklar); görünen yüz tam yuvarlak olur.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local WheelFace = require(Shared:WaitForChild("WheelFace"))
local Build = require(script.Parent.Build)

local WheelService = {}

local GOLD = Color3.fromRGB(255, 196, 50)
local NAVY = Color3.fromRGB(28, 30, 52)
local STONE = Color3.fromRGB(150, 158, 172)
local STONE_LIGHT = Color3.fromRGB(174, 181, 195)
-- Sütun blokları: neşeli lego renkleri
local BRICK_COLORS = {
	Color3.fromRGB(255, 214, 98),
	Color3.fromRGB(120, 190, 255),
	Color3.fromRGB(255, 140, 160),
	Color3.fromRGB(150, 225, 150),
}

local function textLabel(parent, props, strokeThickness)
	props.BackgroundTransparency = 1
	props.Font = Enum.Font.FredokaOne
	props.TextScaled = true
	local label = Instance.new("TextLabel")
	for key, value in props do
		label[key] = value
	end
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label
end

-- notifyEvent (isteğe bağlı): Config.Wheel.Debug açıkken çarka basıldığında sunucunun haberi olduğunu oyuncuya gösterir (E'ye basınca bir şey olmuyorsa nerede koptuğunu görmek için)
function WheelService.init(notifyEvent)
	local wheel = Config.Wheel
	local lobby = Config.Lobby
	local floorTop = Layout.FloorTop
	local faceRadius = wheel.Radius -- görünen yuvarlak yüzün yarıçapı
	local ringOuter = faceRadius * 1.45 -- altın halkanın dış yarıçapı: kare yüzün köşeleri 1.414 x faceRadius uzaktadır, halka onları örter
	local axleY = 2.1 + ringOuter -- çarkın alt kenarı kaidenin 0.5 stud üstünde

	-- Yerel eksen: -Z (WheelFaceX, WheelFaceZ) noktasına, yani lobinin ortasına (okuyucuya) bakar, +Z arkaya, Y yukarı. Yatay dönüş: bakış yönü (-sin, -cos)
	local lookX, lookZ = lobby.WheelFaceX - lobby.WheelX, lobby.WheelFaceZ - lobby.WheelZ
	local frame = CFrame.new(lobby.WheelX, 0, lobby.WheelZ) * CFrame.Angles(0, math.atan2(-lookX, -lookZ), 0)
	local axle = frame * CFrame.new(0, floorTop + axleY, 0)

	local stand = Instance.new("Folder")
	stand.Name = "DailyWheelStand"
	stand.Parent = Workspace

	local function put(name, size, x, y, z, color, material, studs, yaw)
		local part = Build.block(stand, name, size, Vector3.zero, color, material or Enum.Material.Plastic, studs)
		part.CFrame = frame * CFrame.new(x, floorTop + y, z) * CFrame.Angles(0, yaw or 0, 0)
		return part
	end

	-- ---------- Sabit kısım: kaide, arka destek, sütunlar, tabela, ibre ----------
	local pillarX = ringOuter + 1.6
	local standWidth = 2 * (pillarX + 1.8)
	put("WheelPlinth", Vector3.new(standWidth, 1, 5.6), 0, 0.5, 0.2, STONE, nil, true)
	local plinthTop = put("WheelPlinthTop", Vector3.new(standWidth - 1.6, 0.6, 4.4), 0, 1.3, 0.2, STONE_LIGHT, nil, true)

	-- Çarkı taşıyan arka sütun (çarkın arkasında, ön yüzden görünmez)
	for layer = 1, math.ceil((axleY - 1.6) / 1.9) + 1 do
		put("WheelSupport", Vector3.new(2.6, 1.9, 2.2), 0, 1.6 + (layer - 0.5) * 1.9, 1.9, BRICK_COLORS[(layer % #BRICK_COLORS) + 1], nil, true, if layer % 2 == 0 then 0.12 else -0.1)
	end

	-- Çerçeve sütunları: çarkın iki yanında, tepelerinde tabela köprüsü
	local pillarLayers = math.ceil((axleY + ringOuter + 3.4 - 1.6) / 1.9)
	for _, side in { -1, 1 } do
		for layer = 1, pillarLayers do
			local color = BRICK_COLORS[(layer + (if side < 0 then 0 else 2)) % #BRICK_COLORS + 1]
			put("WheelPillar", Vector3.new(1.9, 1.9, 1.9), side * pillarX, 1.6 + (layer - 0.5) * 1.9, 0.3, color, nil, true, (if layer % 2 == 0 then 0.14 else -0.1) * side)
		end
	end

	local bannerY = 1.6 + pillarLayers * 1.9 - 1.5
	local banner = put("WheelBanner", Vector3.new(2 * pillarX - 0.4, 2.4, 0.8), 0, bannerY, -0.1, Color3.fromRGB(255, 150, 40), Enum.Material.SmoothPlastic, false)
	local bannerGui = Instance.new("SurfaceGui")
	bannerGui.Face = Enum.NormalId.Front
	bannerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	bannerGui.PixelsPerStud = 50
	bannerGui.Parent = banner
	textLabel(bannerGui, { Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.6), Text = "DAILY WHEEL", TextColor3 = Color3.new(1, 1, 1) }, 3)
	textLabel(bannerGui, { Position = UDim2.fromScale(0.2, 0.66), Size = UDim2.fromScale(0.6, 0.26), Text = "1 FREE SPIN EVERY DAY", TextColor3 = Color3.fromRGB(255, 245, 215) }, 2)

	-- Durum yazısı (tabelanın üstünde): 'FREE SPIN READY!' ya da kalan süre; her oyuncuya kendi istemcisi yazar (client/WheelController)
	local statusGui = Instance.new("BillboardGui")
	statusGui.Name = "SpinStatus"
	statusGui.Adornee = banner
	statusGui.Size = UDim2.fromScale(11, 2)
	statusGui.StudsOffset = Vector3.new(0, 2.6, 0)
	statusGui.LightInfluence = 0
	statusGui.AlwaysOnTop = false
	statusGui.MaxDistance = 140
	statusGui.Parent = banner
	textLabel(statusGui, { Name = "SpinLabel", Size = UDim2.fromScale(1, 1), Text = "FREE SPIN READY!", TextColor3 = Color3.fromRGB(255, 235, 110) }, 3)

	-- İbre: halkanın üstünde sabit, aşağı bakan kırmızı elmas (dönmez)
	local pointerY = axleY + ringOuter - 0.1
	local pointer = put("WheelPointer", Vector3.new(1.3, 1.3, 0.5), 0, pointerY, -1.35, Color3.fromRGB(255, 60, 70), Enum.Material.Neon, false)
	pointer.CFrame = frame * CFrame.new(0, floorTop + pointerY, -1.35) * CFrame.Angles(0, 0, math.pi / 4)
	pointer.CanCollide = false

	-- Etkileşim noktası (E): çarka yaklaşınca; istemci ('Panel' = 'Wheel') çark arayüzünü açar
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Spin the Wheel"
	prompt.ObjectText = "Daily Wheel"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Panel", "Wheel")
	prompt.Parent = plinthTop
	if wheel.Debug and notifyEvent then
		prompt.Triggered:Connect(function(player)
			notifyEvent:FireClient(player, true, "DEBUG: the server received your wheel button press")
		end)
	end

	-- ---------- Dönen kısım: Model 'DailyWheel' (PrimaryPart = WheelPivot, dönüş ekseni yerel Z) ----------
	local model = Instance.new("Model")
	model.Name = "DailyWheel"

	local function addPart(name, size, offset, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.CFrame = axle * offset
		part.Parent = model
		return part
	end
	-- Silindirlerin ekseni yerel X'tedir; Y çevresinde 90 derece döndürülünce Z'ye (çarkın eksenine) bakar. z küçüldükçe izleyiciye yaklaşılır.
	local AXIS = CFrame.Angles(0, math.pi / 2, 0)

	local pivot = addPart("WheelPivot", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), NAVY)
	pivot.Transparency = 1
	model.PrimaryPart = pivot

	-- Arka altın disk (z -0.4 .. 0.4) ve yüzün lacivert zemini (z -0.55 .. 0.35: arka yüzler aynı düzlemde olmasın, yoksa arkadan bakınca titrer / dalgalı görünür)
	local rim = addPart("WheelRim", Vector3.new(0.8, ringOuter * 2 + 0.3, ringOuter * 2 + 0.3), CFrame.new(0, 0, 0) * AXIS, GOLD, Enum.Material.SmoothPlastic)
	rim.Shape = Enum.PartType.Cylinder
	local face = addPart("WheelFace", Vector3.new(0.9, ringOuter * 2 - 0.4, ringOuter * 2 - 0.4), CFrame.new(0, 0, -0.1) * AXIS, NAVY, Enum.Material.SmoothPlastic)
	face.Shape = Enum.PartType.Cylinder

	-- Çarkın yüzü: ön yüzde şeffaf kare levha; üstündeki SurfaceGui'ye 8 renkli dilim, ayırıcılar ve yazılar çizilir (shared/WheelFace). Levha çarkla birlikte döner
	local carrier = addPart("WheelFaceCarrier", Vector3.new(faceRadius * 2, faceRadius * 2, 0.05), CFrame.new(0, 0, -0.62), NAVY, Enum.Material.SmoothPlastic)
	carrier.Transparency = 1
	local faceGui = Instance.new("SurfaceGui")
	faceGui.Face = Enum.NormalId.Front
	faceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	faceGui.PixelsPerStud = 60
	faceGui.Parent = carrier
	WheelFace.build(faceGui, wheel.Prizes, { rim = false, hub = false, upright = false, clip = false, image = Config.Icons.WheelFace })

	-- Altın halka: yüzün önünde, çevreye dizilmiş bloklar (karenin köşelerini örter, görünen yüzü daire yapar)
	local blocks = 40
	local ringCenter = (faceRadius + ringOuter) / 2
	local ringLength = ringOuter - faceRadius + 0.5
	local ringWidth = 2 * math.pi * ringOuter / blocks * 1.15
	for index = 1, blocks do
		local phi = (index - 1) * (2 * math.pi / blocks)
		addPart(
			"WheelRingBlock",
			Vector3.new(ringWidth, ringLength, 0.3),
			CFrame.new(-math.sin(phi) * ringCenter, math.cos(phi) * ringCenter, -0.78) * CFrame.Angles(0, 0, phi),
			GOLD,
			Enum.Material.SmoothPlastic
		)
	end

	-- Göbek ve merkez kapağı
	local hub = addPart("WheelHub", Vector3.new(0.8, 3, 3), CFrame.new(0, 0, -1.0) * AXIS, GOLD, Enum.Material.SmoothPlastic)
	hub.Shape = Enum.PartType.Cylinder
	local cap = addPart("WheelCap", Vector3.new(0.6, 1.3, 1.3), CFrame.new(0, 0, -1.5) * AXIS, Color3.fromRGB(255, 60, 70), Enum.Material.Neon)
	cap.Shape = Enum.PartType.Cylinder

	-- Halkanın üstündeki lambalar: istemci sırayla yakıp söndürür (koşuşan ışık)
	local lampCount = 24
	for lamp = 1, lampCount do
		local angle = (lamp - 1) * (2 * math.pi / lampCount)
		local bulb = addPart(
			"WheelLamp",
			Vector3.new(0.6, 0.6, 0.6),
			CFrame.new(-math.sin(angle) * ringCenter, math.cos(angle) * ringCenter, -1.05),
			Color3.fromRGB(255, 244, 200),
			Enum.Material.Neon
		)
		bulb.Shape = Enum.PartType.Ball
	end

	model.Parent = Workspace
end

return WheelService
