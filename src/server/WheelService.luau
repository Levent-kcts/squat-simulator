-- Günlük çark: lobide spawn'ın SOLUNDA, odaya (spawn'a) doğru dönük, lego sütunlu bir kapı çerçevesinin içinde duran dönen ödül çarkı.
-- Burada sadece GÖRÜNÜŞ ve etkileşim noktası kurulur; çevirme mantığı (günde 1 hak, ödül seçimi) PlayerStats.spinWheel'dedir, dönüş animasyonu client/WheelClient'tadır.
-- İki parça kurulur: Workspace.DailyWheel (dönen Model: dilimler, göbek, ışıklar; PrimaryPart = 'WheelPivot') ve Workspace.DailyWheelStand (sabit klasör: kaide, sütunlar, tabela,
-- ibre, ProximityPrompt, durum yazısı 'SpinLabel'). Koridorda/lobide yeni ışık paneli YOK kuralı korunur (sadece parlayan Neon lambalar).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
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

function WheelService.init()
	local wheel = Config.Wheel
	local lobby = Config.Lobby
	local floorTop = Layout.FloorTop
	local count = #wheel.Prizes
	local radius = wheel.Radius
	local rimRadius = radius + 0.6
	local axleY = 2.1 + rimRadius -- çarkın alt kenarı kaidenin 0.5 stud üstünde

	-- Yerel eksen: -Z spawn'a (okuyucuya) bakar, +Z arkaya, Y yukarı. WheelAngle kadar spawn'a doğru döner
	local frame = CFrame.new(lobby.WheelX, 0, lobby.WheelZ) * CFrame.Angles(0, -math.pi / 2 - math.rad(lobby.WheelAngle), 0)
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
	local standWidth = 2 * (rimRadius + 2.6)
	put("WheelPlinth", Vector3.new(standWidth, 1, 5.6), 0, 0.5, 0.2, STONE, nil, true)
	local plinthTop = put("WheelPlinthTop", Vector3.new(standWidth - 1.6, 0.6, 4.4), 0, 1.3, 0.2, STONE_LIGHT, nil, true)

	-- Çarkı taşıyan arka sütun (çarkın arkasında, ön yüzden görünmez) ve dingil
	for layer = 1, 5 do
		put("WheelSupport", Vector3.new(2.6, 1.9, 2.2), 0, 1.6 + (layer - 0.5) * 1.9, 1.7, BRICK_COLORS[(layer % #BRICK_COLORS) + 1], nil, true, if layer % 2 == 0 then 0.12 else -0.1)
	end

	-- Çerçeve sütunları: çarkın iki yanında, tepelerinde tabela köprüsü
	local pillarX = rimRadius + 1.4
	local pillarLayers = 9
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

	-- Durum yazısı (tabelanın üstünde): 'FREE SPIN READY!' ya da kalan süre; her oyuncuya kendi istemcisi yazar (client/WheelClient)
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

	-- İbre: çarkın üstünde sabit, aşağı bakan elmas (dönmez)
	local pointer = put("WheelPointer", Vector3.new(1.2, 1.2, 0.5), 0, axleY + radius + 0.55, -1.15, Color3.fromRGB(255, 60, 70), Enum.Material.Neon, false)
	pointer.CFrame = frame * CFrame.new(0, floorTop + axleY + radius + 0.55, -1.15) * CFrame.Angles(0, 0, math.pi / 4)
	pointer.CanCollide = false

	-- Etkileşim noktası (E): oyuncuya özel mantık istemcide; 'Panel' = 'Wheel' ile tanınır
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Spin the Wheel"
	prompt.ObjectText = "Daily Wheel"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Panel", "Wheel")
	prompt.Parent = plinthTop

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
	-- Silindirlerin ekseni yerel X'tedir; Y çevresinde 90 derece döndürülünce Z'ye (çarkın eksenine) bakar (aşağıda her silindire bu dönüş verilir)

	local pivot = addPart("WheelPivot", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), NAVY)
	pivot.Transparency = 1
	model.PrimaryPart = pivot

	local rim = addPart("WheelRim", Vector3.new(0.8, rimRadius * 2, rimRadius * 2), CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), GOLD, Enum.Material.SmoothPlastic)
	rim.Shape = Enum.PartType.Cylinder
	local face = addPart("WheelFace", Vector3.new(1, radius * 2 + 0.2, radius * 2 + 0.2), CFrame.new(0, 0, -0.1) * CFrame.Angles(0, math.pi / 2, 0), NAVY, Enum.Material.SmoothPlastic)
	face.Shape = Enum.PartType.Cylinder

	-- Dilimler: her dilim 3 basamaklı pervane kanadı (dışa doğru genişler), aralarında koyu çizgi kalır; üstüne simge ve ad yazılır
	local sliceAngle = 2 * math.pi / count
	local innerRadius, outerRadius = 2.4, radius - 0.1
	local steps = 3
	local stepLength = (outerRadius - innerRadius) / steps
	local labelRadius = innerRadius + stepLength * 1.5
	for index, prize in wheel.Prizes do
		local phi = (index - 1) * sliceAngle -- saat yönünde, yukarıdan başlar
		for step = 1, steps do
			local inner = innerRadius + (step - 1) * stepLength
			local width = 2 * inner * math.tan(sliceAngle / 2) - 0.12
			local center = inner + stepLength / 2
			local piece = addPart(
				`Slice{index}`,
				Vector3.new(width, stepLength, 0.3),
				CFrame.new(-math.sin(phi) * center, math.cos(phi) * center, -0.75) * CFrame.Angles(0, 0, phi),
				prize.color,
				Enum.Material.SmoothPlastic
			)
			piece.Name = `Slice{index}`
		end
		-- Yazı için görünmez levha: dilimle birlikte döner, yazının üstü dilimin dışa bakan yönüdür
		local label = addPart(
			`SliceLabel{index}`,
			Vector3.new(2.4, 2.3, 0.05),
			CFrame.new(-math.sin(phi) * labelRadius, math.cos(phi) * labelRadius, -0.95) * CFrame.Angles(0, 0, phi),
			prize.color,
			Enum.Material.SmoothPlastic
		)
		label.Transparency = 1
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 60
		gui.Parent = label
		textLabel(gui, { Position = UDim2.fromScale(0.1, 0.02), Size = UDim2.fromScale(0.8, 0.5), Text = prize.icon, TextColor3 = Color3.new(1, 1, 1) }, 0)
		textLabel(gui, { Position = UDim2.fromScale(0.04, 0.54), Size = UDim2.fromScale(0.92, 0.36), Text = prize.label, TextColor3 = Color3.new(1, 1, 1) }, 2)
	end

	-- Göbek ve merkez kapağı
	local hub = addPart("WheelHub", Vector3.new(0.8, 4.4, 4.4), CFrame.new(0, 0, -1.0) * CFrame.Angles(0, math.pi / 2, 0), GOLD, Enum.Material.SmoothPlastic)
	hub.Shape = Enum.PartType.Cylinder
	local cap = addPart("WheelCap", Vector3.new(0.6, 1.8, 1.8), CFrame.new(0, 0, -1.5) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 60, 70), Enum.Material.Neon)
	cap.Shape = Enum.PartType.Cylinder

	-- Kenar lambaları: istemci sırayla yakıp söndürür (koşuşan ışık)
	local lampCount = 16
	for lamp = 1, lampCount do
		local angle = (lamp - 1) * (2 * math.pi / lampCount)
		local bulb = addPart(
			"WheelLamp",
			Vector3.new(0.55, 0.55, 0.55),
			CFrame.new(-math.sin(angle) * (radius + 0.3), math.cos(angle) * (radius + 0.3), -0.55),
			Color3.fromRGB(255, 244, 200),
			Enum.Material.Neon
		)
		bulb.Shape = Enum.PartType.Ball
	end

	model.Parent = Workspace
end

return WheelService
