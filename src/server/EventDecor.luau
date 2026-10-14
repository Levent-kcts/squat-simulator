-- SEZONLUK ETKİNLİK LOBİ SÜSÜ (Config.Event.Decor; Spooky Gym): etkinlik açıkken ('SeasonActive' Workspace özniteliği) yol kenarlarında yüz çizili balkabakları, havada hayaletler ve koridor ağzının önünde parlak bir etkinlik tabelası kurulur; etkinlik bitince kaldırılır.
-- SADECE görünümdür (oyun mantığı yok), kodla çizilir (Blender/Studio modeli gerekmez). Işıklar 'EventDecor' klasöründedir: client/Performance.FOLDERS bu klasörü uzaklığa göre kısar. Eşya düzenini bozmamak için balkabakları yol kenarlarının DIŞINDA,
-- raf ve antrenman alanlarına girmeyen şeritte durur (x = +-(PathHalfWidth + 3)); hayaletler tavana yakın havada (y 11-14), hiçbir şeye değmez.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local ServerEvents = require(script.Parent.ServerEvents)

local EventDecor = {}

local FOLDER = "EventDecor"
local ORANGE = Color3.fromRGB(235, 110, 20)
local STEM = Color3.fromRGB(60, 120, 50)
local GLOW = Color3.fromRGB(255, 215, 80)
local GHOST = Color3.fromRGB(226, 220, 250)

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Konum + kayma (Vector3 toplamı yerine bileşen bileşen: sunucu testinin taklidi vektör aritmetiği bilmez)
local function offset(position, dx, dy, dz)
	return Vector3.new(position.X + dx, position.Y + dy, position.Z + dz)
end

local function ball(parent, name, diameter, position, color, material)
	local p = part(parent, name, Vector3.new(diameter, diameter, diameter), position, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Yüz çizili balkabağı: dx = +1 ise yüzü +X'e, -1 ise -X'e bakar (lobinin ortasına doğru)
local function buildPumpkin(folder, index, position, dx)
	local body = ball(folder, `Pumpkin_{index}`, 3.8, position, ORANGE)
	body.Size = Vector3.new(3.8, 3.3, 3.8) -- hafif basık
	part(folder, `PumpkinStem_{index}`, Vector3.new(0.5, 0.9, 0.5), offset(position, 0, 1.9, 0), STEM)
	local front = dx * 1.75
	for _, side in { -1, 1 } do -- gözler
		part(folder, `PumpkinEye_{index}_{side}`, Vector3.new(0.3, 0.8, 0.7), offset(position, front, 0.45, side * 0.85), GLOW, Enum.Material.Neon)
	end
	for slot = -1, 1 do -- gülen ağız (uçlar yukarıda)
		local lift = if slot == 0 then -0.2 else 0.15
		part(folder, `PumpkinMouth_{index}_{slot}`, Vector3.new(0.3, 0.45, 0.7), offset(position, front - dx * 0.05, -0.75 + lift - 0.35, slot * 0.8), GLOW, Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 40)
	light.Range = 10
	light.Brightness = 0.6
	light.Parent = body
end

-- Havada duran küçük hayalet (yarı mat beyaz-lavanta, siyah gözler, etek topları)
local function buildGhost(folder, index, position)
	ball(folder, `Ghost_{index}`, 3.6, position, GHOST)
	for _, side in { -1, 1 } do
		ball(folder, `GhostEye_{index}_{side}`, 0.55, offset(position, side * 0.7, 0.35, -1.55), Color3.fromRGB(30, 30, 40))
	end
	for slot = -1, 1 do -- etek
		ball(folder, `GhostSkirt_{index}_{slot}`, 1.5, offset(position, slot * 1.15, -1.5, 0), GHOST)
	end
end

-- Koridor ağzının önünde asılı etkinlik tabelası (lobiye bakan yüz)
local function buildSign(folder, floorTop)
	local board = part(folder, "EventSign", Vector3.new(26, 4.2, 0.6), Vector3.new(0, floorTop + 21, -60), Color3.fromRGB(70, 30, 90), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "EventSignGui"
	gui.Face = Enum.NormalId.Back -- tahtanın +Z yüzü lobiye bakar
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = `{Config.Event.Emoji} {Config.Event.Name} {Config.Event.Emoji}`
	label.TextColor3 = Color3.fromRGB(255, 170, 40)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(30, 10, 40)
	stroke.Parent = label
	label.Parent = gui
end

function EventDecor.clear()
	local old = Workspace:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
end

function EventDecor.build()
	EventDecor.clear()
	local settings = Config.Event
	local decor = settings.Decor or {}
	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = Workspace

	local floorTop = Layout.FloorTop
	local curb = Config.Lobby.Detail and Config.Lobby.Detail.PathHalfWidth or 16
	local x = curb + 3
	local perSide = math.max(1, math.floor((decor.Pumpkins or 10) / 2))
	local zStart, zEnd = -50, 24 -- koridor ağzından yumurta standının önüne
	for side = 1, 2 do
		local dx = if side == 1 then 1 else -1 -- sol taraftaki (x < 0) balkabağı +X'e, sağdaki -X'e bakar
		for slot = 1, perSide do
			local z = zStart + (zEnd - zStart) * (slot - 1) / math.max(1, perSide - 1)
			buildPumpkin(folder, (side - 1) * perSide + slot, Vector3.new(-dx * x, floorTop + 1.65, z), dx)
		end
	end
	local ghosts = decor.Ghosts or 5
	local spots = { { -26, -45 }, { 26, -30 }, { -26, -12 }, { 26, 8 }, { 0, 34 }, { -26, 20 }, { 26, 22 } }
	for index = 1, math.min(ghosts, #spots) do
		local spot = spots[index]
		buildGhost(folder, index, Vector3.new(spot[1], floorTop + 11 + (index % 3), spot[2]))
	end
	buildSign(folder, floorTop)
	return folder
end

function EventDecor.init()
	local settings = Config.Event
	if not settings or not settings.Enabled then
		return
	end
	local function isActive()
		local flag = Workspace:GetAttribute("SeasonActive")
		if flag ~= nil then
			return flag == true
		end
		return ServerEvents.seasonActive()
	end
	local function sync()
		if isActive() then
			if not Workspace:FindFirstChild(FOLDER) then
				EventDecor.build()
			end
		else
			EventDecor.clear()
		end
	end
	Workspace:GetAttributeChangedSignal("SeasonActive"):Connect(sync)
	sync()
end

return EventDecor
