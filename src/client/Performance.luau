-- Performans yöneticisi (sahibi 'oyunu gereksiz büyütecek ve yoracak şeyleri kaldır, mobil telefonlarda tam performans çalışsın' dedi): SADECE görünümü hafifletir, oyun mantığına dokunmaz.
--   * Performance.low: hafif grafik modu. Telefon/tablette (dokunmatik, klavyesiz) baştan açıktır; masaüstünde kare hızı uzun süre düşük kalırsa kendiliğinden açılır (bir kez açılınca kapanmaz).
--     Açıkken: yerel gölgeler kapanır (Lighting.GlobalShadows; kapalı salonda zaten ortam ışığı baskındır), diğer modüller (WallClient, ShelfClient, Juice, UIStyle) daha hafif çalışır.
--   * Uzaklık kısma: lobideki ışıklar, parçacıklar ve SurfaceGui'ler (ayakkabı/skin/yumurta/antrenör süsleri, tabelalar) kameradan uzaktaysa kapatılır, yaklaşınca açılır (yarım saniyede bir bakılır).
-- Yeni dekoratif ışık/parçacık/SurfaceGui eklersen Workspace > FOLDERS klasörlerinden birine koy: kendiliğinden kısılır. Kısma sadece Enabled'ı değiştirir (sahibi başka kodla Enabled'ı oynatılan nesneleri bu klasörlere koyma).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Performance = {}

-- Telefon/tablet: dokunmatik var ve (klavye/fare yok YA DA ekran kısa: Studio cihaz emülatörü klavye/fareyi 'var' gösterebilir; dokunmatik ekranlı dizüstü yüksek ekranlıdır)
local function screenHeight()
	local camera = Workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 1000
	return if type(height) == "number" then height else 1000
end
Performance.mobile = UserInputService.TouchEnabled and ((not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled) or screenHeight() < 520)
Performance.low = Performance.mobile

-- Kısılacak klasörler (server/EnvironmentService, Shelf, TrainingArea, EggShop, Hub, WheelService, WorldsGate...); duvarlar (MyWalls) KENDİ penceresini WallClient yönetir
local FOLDERS = { "Lobby", "ShoeShop", "SkinShop", "TrainingArea", "EggShop", "Hub", "DailyWheel", "DailyWheelStand", "WorldsGate", "Course", "Leaderboards" }

-- Kameraya göre görünürlük menzilleri (stud); [1] = normal, [2] = hafif mod
local RANGES = {
	light = { 75, 45 },
	fx = { 130, 75 },
	gui = { 220, 130 }, -- büyük başlık tabelaları salonun öbür ucundan da görünsün (statik doku, ucuz): sadece koridor/Win odalarındaki uzak tabelalar kısılır
}
local HYSTERESIS = 1.15 -- açıkken menzil bu kadar büyür: sınırda gidip gelince titremesin
local CHECK_INTERVAL = 0.45

local listeners = {}
local tracked = {} -- { instance, kind, original (başlangıçta açık muydu), on }

function Performance.onChange(callback)
	table.insert(listeners, callback)
end

local function applyLow()
	-- Yerel gölgeleri kapat: sadece bu oyuncunun ekranı (sunucu ışık ayarı değişmez)
	pcall(function()
		Lighting.GlobalShadows = false
	end)
end

-- Hafif moda geç (geri dönüş yok: kare hızı düştüyse tekrar yükseltmek titreme yaratır)
function Performance.setLow()
	if Performance.low and Performance.applied then
		return
	end
	Performance.low = true
	Performance.applied = true
	applyLow()
	for _, callback in listeners do
		pcall(callback)
	end
end

local function kindOf(instance)
	if instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
		return "light"
	elseif instance:IsA("ParticleEmitter") then
		return "fx"
	elseif instance:IsA("SurfaceGui") then
		return "gui"
	end
	return nil
end

local function anchorPart(instance)
	local anchor = instance.Parent -- lobideki ışık, parçacık ve SurfaceGui'ler her zaman doğrudan kendi parçalarının çocuğudur
	if anchor and anchor:IsA("BasePart") then
		return anchor
	end
	return nil
end

local function track(instance)
	local kind = kindOf(instance)
	if not kind or instance:GetAttribute("NoCull") then
		return
	end
	-- Tavan panellerinin hale katmanları (server/Build.ceilingHalo): saydam, üst üste binen büyük yüzeyler; hafif modda (telefon) tamamen kapatılır (ışık panelleri yine görünür)
	local parent = instance.Parent
	local halo = kind == "gui" and parent ~= nil and parent.Name == "LobbyLightHalo"
	table.insert(tracked, { instance = instance, kind = kind, original = instance.Enabled, on = instance.Enabled, halo = halo })
end

local function scan(folder)
	for _, descendant in folder:GetDescendants() do
		track(descendant)
	end
	folder.DescendantAdded:Connect(function(descendant)
		task.defer(track, descendant)
	end)
end

-- Kameraya yakın olanlar açık, uzak olanlar kapalı. Kapalı gelen (original = false) nesnelere dokunulmaz.
local function cull()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	local index = if Performance.low then 2 else 1
	local keep = {}
	for _, entry in tracked do
		local instance = entry.instance
		if instance.Parent then
			table.insert(keep, entry)
			if entry.halo and Performance.low then
				if entry.on then
					entry.on = false
					instance.Enabled = false
				end
			elseif entry.original then
				local part = anchorPart(instance)
				if part then
					local range = RANGES[entry.kind][index]
					local distance = (part.Position - origin).Magnitude
					local want = distance <= (if entry.on then range * HYSTERESIS else range)
					if want ~= entry.on then
						entry.on = want
						instance.Enabled = want
					end
				end
			end
		end
	end
	tracked = keep
end

local function watchFrameRate()
	-- Yükleme bitince 6 saniyelik pencerelerle ortalama kare hızı ölçülür; iki pencere üst üste çok düşükse hafif moda geçilir
	local player = Players.LocalPlayer
	local windowTime, frames, lowWindows = 0, 0, 0
	RunService.RenderStepped:Connect(function(dt)
		if Performance.low or player:GetAttribute("DataLoaded") ~= true then
			return
		end
		windowTime += dt
		frames += 1
		if windowTime >= 6 then
			local fps = frames / windowTime
			windowTime, frames = 0, 0
			if fps < 28 then
				lowWindows += 1
				if lowWindows >= 2 then
					print(`[Performance] Frame rate stayed low ({math.floor(fps)} fps): switching to light graphics.`)
					Performance.setLow()
				end
			else
				lowWindows = 0
			end
		end
	end)
end

function Performance.init()
	if Performance.low then
		Performance.setLow()
	end

	local function register(name)
		local folder = Workspace:FindFirstChild(name)
		if folder then
			scan(folder)
		end
	end
	for _, name in FOLDERS do
		register(name)
	end
	-- Klasörler geç gelirse (ağ gecikmesi) bir kez daha bak
	task.delay(6, function()
		local known = {}
		for _, entry in tracked do
			known[entry.instance] = true
		end
		for _, name in FOLDERS do
			local folder = Workspace:FindFirstChild(name)
			if folder then
				for _, descendant in folder:GetDescendants() do
					if not known[descendant] then
						track(descendant)
					end
				end
			end
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed = 0
		cull()
	end)
	watchFrameRate()
end

return Performance
