-- Oyun başlamadan önceki YÜKLEME EKRANI (ReplicatedFirst/Loading betiği başlatır, ReplicatedStorage.Shared'da durur; init.client'ta yedek çağrı vardır; sahibi 'oyuna uygun renkte, üzerinde loading yazsın ve bar olsun' dedi).
-- Zemin salonun lavanta mavisi, başlık ve çubuk tabelalardaki sarı, dekor olarak süzülen lego tuğlalar. Çubuk GERÇEK ilerlemeyi gösterir:
-- oyunun yüklenmesi (game.Loaded), sunucunun dünyayı kurması (Workspace 'WorldReady'), simgelerin önden yüklenmesi (ContentProvider),
-- karakterin gelmesi, istemci arayüzünün hazır olması (oyuncuda 'ClientReady'). Hepsi bitince ya da en geç MaxSeconds sonra kendiliğinden kapanır:
-- oyuncu hiçbir koşulda ekranda takılı kalmaz. Sadece görünümdür; oyun mantığına dokunmaz. Konfigürasyona (Config) bağlı DEĞİLDİR, ReplicatedFirst'te
-- ReplicatedStorage'dan önce çalışabilsin diye renkler ve süreler burada durur; simge listesi için Config sonradan (zaman aşımıyla) okunur.
local LoadingScreen = {}

-- Renkler (oyunun lobisi ve tabelalarıyla aynı aile: EnvironmentService WALL_COLOR, sarı tabela 255,205,40)
local TOP_COLOR = Color3.fromRGB(176, 186, 238)
local BOTTOM_COLOR = Color3.fromRGB(112, 122, 200)
local YELLOW = Color3.fromRGB(255, 205, 40)
local ORANGE = Color3.fromRGB(255, 150, 40)
local OUTLINE = Color3.fromRGB(40, 25, 0)
local TRACK_COLOR = Color3.fromRGB(44, 48, 104)
local TRACK_OUTLINE = Color3.fromRGB(24, 26, 70)
local BRICK_COLORS = {
	Color3.fromRGB(240, 92, 102), -- kırmızı
	Color3.fromRGB(92, 146, 242), -- mavi
	Color3.fromRGB(252, 206, 72), -- sarı
	Color3.fromRGB(102, 208, 132), -- yeşil
	Color3.fromRGB(252, 152, 72), -- turuncu
	Color3.fromRGB(172, 114, 236), -- mor
}

LoadingScreen.GameTitle = "SQUAT SIMULATOR" -- başlık (Config.GameName ile aynı; Config bu aşamada henüz gelmemiş olabilir)
LoadingScreen.ShowTitle = true
LoadingScreen.MinSeconds = 3 -- her koşulda en az bu kadar görünür (yanıp sönmesin). Süre ekranın İLK ÇİZİLDİĞİ kareden sayılır: Studio'da pencere geç açılırsa ekran kaçmasın
LoadingScreen.MaxSeconds = 30 -- en geç bu kadar sonra kapanır
LoadingScreen.DisplayOrder = 1000 -- hiçbir arayüz bunun üstüne çıkmaz (en yükseği WheelPanel 20)

-- Aşamalar ve ağırlıkları (toplam 1)
LoadingScreen.Stages = { game = 0.15, world = 0.30, assets = 0.30, character = 0.15, client = 0.10 }

-- progress[aşama] 0..1 -> toplam hedef 0..1
function LoadingScreen.target(progress)
	local total = 0
	for stage, weight in LoadingScreen.Stages do
		total += weight * math.clamp(progress[stage] or 0, 0, 1)
	end
	return total
end

-- Gösterilen çubuk değeri hedefe yumuşakça yaklaşır; asla geri gitmez ve hedefi geçmez
function LoadingScreen.ease(shown, target, dt)
	if target <= shown then
		return shown
	end
	local step = (target - shown) * math.min(1, dt * 5) + dt * 0.04 -- yakın hedefte bile ilerler (takılı görünmesin)
	return math.min(target, shown + step)
end

-- '.' sayısı zamanla döner; boşluklarla tamamlanır ki yazının genişliği (ve ortası) değişmesin
function LoadingScreen.dots(clock)
	local count = math.floor(clock * 2.5) % 4
	return "LOADING" .. string.rep(".", count) .. string.rep(" ", 3 - count)
end

-- Config.Icons'taki (iç içe olabilir) rbxassetid adreslerini düz listeye toplar
function LoadingScreen.collectAssets(tbl, out)
	out = out or {}
	if type(tbl) ~= "table" then
		return out
	end
	for _, value in tbl do
		if type(value) == "string" and string.sub(value, 1, 13) == "rbxassetid://" then
			table.insert(out, value)
		elseif type(value) == "table" then
			LoadingScreen.collectAssets(value, out)
		end
	end
	return out
end

local function addText(parent, props, strokeThickness)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	label.Position = props.Position
	label.Size = props.Size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = props.Text
	label.TextColor3 = props.Color or Color3.new(1, 1, 1)
	label.ZIndex = props.ZIndex or 2
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeThickness
	stroke.Color = OUTLINE
	stroke.Parent = label
	return label
end

-- 2D LEGO TUĞLA (sahibi 3B tuğlayı beğenmedi: 'çok yukarda gözüküyor ve 3 boyutlu yapmışsın, 2d fotoğrafını çek o hareket etsin'): 2x2 (4 çıkıntılı) tuğlanın Blender'da çekilmiş
-- şeffaf PNG fotoğrafı (tools/loading/make_brick.py -> assets/loading/brick.png) ImageLabel olarak durur. Resim BEYAZA yakın griyle çekildiği için ImageColor3 ile her tuğla farklı renge boyanır
-- (gölge ve parlak vurgu korunur): Roblox'a SADECE BU TEK RESİM yüklenir, kimliği Config.Icons.LoadingBrick'e yazılır. Kimlik boşken tuğla çizilmez (düz Frame ile çizmeye DÖNME, 3B'ye de).
function LoadingScreen.brickImageId()
	local ok, config = pcall(require, script.Parent.Config)
	if ok and type(config) == "table" and type(config.Icons) == "table" then
		local id = config.Icons.LoadingBrick
		if type(id) == "string" and id ~= "" then
			return id
		end
	end
	return nil
end

-- Ekranı kurar (brickImage verilmezse Config.Icons.LoadingBrick). Dönen nesne: gui, backdrop, root, bricks, setProgress(0..1), setDots(clock), animate(clock), fadeOut(seconds)
function LoadingScreen.build(parentGui, brickImage)
	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadingScreen"
	gui.DisplayOrder = LoadingScreen.DisplayOrder
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parentGui

	-- Katmanlar (aşağıdan yukarı): zemin (Active: arkadaki oyun tıklamaları yükleme sırasında squat sayılmasın), sonra tuğlalar + yazılar + çubuk (tek CanvasGroup: birlikte solar)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(1, 1, 1)
	backdrop.BorderSizePixel = 0
	backdrop.Active = true
	backdrop.ZIndex = 1
	backdrop.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(TOP_COLOR, BOTTOM_COLOR)
	gradient.Parent = backdrop

	local root = Instance.new("CanvasGroup")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ZIndex = 2
	root.Parent = gui

	-- Dekor: ekranın kenarlarında süzülüp sallanan 2D tuğla resimleri (ortayı ve başlığı boş bırakır; üstte, ortada, altta ikişer tane).
	-- { ekran x, ekran y (0-1), genişlik (ekran genişliğinin oranı), renk sırası, başlangıç fazı, eğim (derece) }
	local bricks = {}
	local brickImage = brickImage or LoadingScreen.brickImageId()
	if brickImage then
		local layout = {
			{ 0.08, 0.13, 0.14, 1, 0.0, -12 }, { 0.92, 0.12, 0.13, 2, 1.7, 10 }, { 0.07, 0.56, 0.11, 5, 3.1, 14 },
			{ 0.93, 0.58, 0.12, 6, 4.4, -14 }, { 0.17, 0.85, 0.135, 3, 5.2, 8 }, { 0.83, 0.84, 0.15, 4, 2.4, -9 },
		}
		for index, def in layout do
			local brick = Instance.new("ImageLabel")
			brick.Name = `Brick{index}`
			brick.AnchorPoint = Vector2.new(0.5, 0.5)
			brick.Position = UDim2.fromScale(def[1], def[2])
			brick.Size = UDim2.fromScale(def[3], def[3]) -- kare resim: yükseklik aşağıdaki oran sınırından gelir (ekran oranı ne olursa olsun bozulmaz)
			brick.BackgroundTransparency = 1
			brick.Image = brickImage
			brick.ImageColor3 = BRICK_COLORS[def[4]]
			brick.Rotation = def[6]
			brick.ZIndex = 1
			brick.Parent = root
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.AspectRatio = 1
			ratio.DominantAxis = Enum.DominantAxis.Width
			ratio.Parent = brick
			bricks[index] = { frame = brick, x = def[1], y = def[2], phase = def[5], tilt = def[6] }
		end
	end

	if LoadingScreen.ShowTitle then
		addText(root, { Position = UDim2.fromScale(0.5, 0.30), Size = UDim2.fromScale(0.7, 0.16), Text = LoadingScreen.GameTitle, Color = YELLOW }, 6)
	end
	local loadingLabel = addText(root, { Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.32, 0.075), Text = LoadingScreen.dots(0) }, 4)

	-- Çubuk: koyu oluk, içinde sarıdan turuncuya dolgu, ortada yüzde
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.62)
	track.Size = UDim2.fromScale(0.46, 0.06)
	track.BackgroundColor3 = TRACK_COLOR
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.ZIndex = 2
	track.Parent = root
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0.5, 0)
	trackCorner.Parent = track
	local trackStroke = Instance.new("UIStroke")
	trackStroke.Thickness = 4
	trackStroke.Color = TRACK_OUTLINE
	trackStroke.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 3
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new(YELLOW, ORANGE)
	fillGradient.Rotation = 90
	fillGradient.Parent = fill
	local shine = Instance.new("Frame") -- üstte parlak şerit: çubuk 'cam' gibi görünür
	shine.Size = UDim2.fromScale(0.96, 0.28)
	shine.Position = UDim2.fromScale(0.02, 0.1)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.65
	shine.BorderSizePixel = 0
	shine.ZIndex = 4
	shine.Parent = fill
	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0.5, 0)
	shineCorner.Parent = shine

	local percent = addText(track, { Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.3, 0.7), Text = "0%", ZIndex = 5 }, 3)

	local screen = {}
	screen.gui = gui
	screen.backdrop = backdrop
	screen.bricks = bricks
	screen.root = root
	screen.fill = fill
	screen.percent = percent
	screen.label = loadingLabel

	function screen.setProgress(value)
		value = math.clamp(value, 0, 1)
		fill.Size = UDim2.fromScale(value, 1)
		percent.Text = string.format("%d%%", math.floor(value * 100 + 0.5))
	end
	function screen.setDots(clock)
		loadingLabel.Text = LoadingScreen.dots(clock)
	end
	-- Tuğlalar yavaşça süzülür (yukarı aşağı) ve eğimlerinin etrafında sallanır
	function screen.animate(clock)
		for _, item in bricks do
			item.frame.Position = UDim2.fromScale(item.x, item.y + math.sin(clock * 1.3 + item.phase) * 0.014)
			item.frame.Rotation = item.tilt + math.sin(clock * 0.9 + item.phase * 2) * 6
		end
	end
	function screen.fadeOut(seconds)
		local TweenService = game:GetService("TweenService")
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local main = TweenService:Create(backdrop, info, { BackgroundTransparency = 1 })
		TweenService:Create(root, info, { GroupTransparency = 1 }):Play()
		main:Play()
		return main
	end
	return screen
end

-- Yükleme ekranını gösterir ve oyun hazır olunca kapatır. Hata verirse (ya da GUI kurulamazsa) oyunu engellemez.
function LoadingScreen.run()
	local ReplicatedFirst = game:GetService("ReplicatedFirst")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local ContentProvider = game:GetService("ContentProvider")

	local player = Players.LocalPlayer
	while not player do -- ReplicatedFirst çok erken çalışırsa oyuncu henüz gelmemiş olabilir
		task.wait()
		player = Players.LocalPlayer
	end
	-- Tek örnek: ReplicatedFirst betiği ve init.client yedeği ikisi de çağırır, ilk gelen kazanır (kontrol ile işaretleme arasında bekleme yok)
	if player:GetAttribute("LoadingActive") then
		return
	end
	player:SetAttribute("LoadingActive", true)

	pcall(function()
		ReplicatedFirst:RemoveDefaultLoadingScreen() -- Roblox'un kendi yükleme ekranı yerine bizimki
	end)

	local playerGui = player:WaitForChild("PlayerGui")
	local okBuild, screen = pcall(LoadingScreen.build, playerGui)
	if not okBuild then
		warn(`[Loading] Could not build the loading screen: {screen}`)
		return
	end

	print("[Loading] screen shown")
	local startedAt = os.clock()
	local progress: { [string]: number } = { game = 0, world = 0, assets = 0, character = 0, client = 0 }
	local maxSeconds = LoadingScreen.MaxSeconds

	-- Bir aşama bitene (ya da zaman aşımına) kadar koşulu yoklar; zaman aşımında aşama bitmiş sayılır
	local function waitFor(stage: string, condition: () -> boolean, partial: (() -> number)?)
		task.spawn(function()
			while not condition() do
				if partial then
					local current: number = partial()
					progress[stage] = math.max(progress[stage], current)
				end
				if os.clock() - startedAt > maxSeconds then
					break
				end
				task.wait(0.1)
			end
			progress[stage] = 1
		end)
	end

	waitFor("game", function()
		return game:IsLoaded()
	end)
	-- Sunucu dünyayı kurunca Workspace'e 'WorldReady' işareti koyar; kurulum sürerken kaç ana klasörün geldiği kısmi ilerleme sayılır
	local worldFolders = { "Lobby", "ShoeShop", "SkinShop", "EggShop", "TrainingArea" }
	waitFor("world", function()
		return Workspace:GetAttribute("WorldReady") == true
	end, function()
		local found = 0
		for _, name in worldFolders do
			if Workspace:FindFirstChild(name) then
				found += 1
			end
		end
		return 0.9 * found / #worldFolders
	end)
	waitFor("character", function()
		local character = player.Character
		if not (character and character:FindFirstChild("HumanoidRootPart")) then
			return false
		end
		local ok, appearance = pcall(function()
			return player:HasAppearanceLoaded()
		end)
		return not ok or appearance -- kıyafetler gelmeden kapanırsa karakter gözümüzün önünde 'çıplak' görünür
	end)
	waitFor("client", function()
		return player:GetAttribute("ClientReady") == true
	end)

	-- Simgeleri önden yükle (Config.Icons; arayüz açıldığında boş kutu yerine hazır görünsün)
	task.spawn(function()
		local list = {}
		local shared = ReplicatedStorage:WaitForChild("Shared", 10)
		local configModule = shared and shared:WaitForChild("Config", 10)
		if configModule then
			local okConfig, config = pcall(require, configModule)
			if okConfig and type(config) == "table" then
				LoadingScreen.collectAssets(config.Icons, list)
			end
		end
		if #list > 0 then
			local done = 0
			pcall(function()
				ContentProvider:PreloadAsync(list, function()
					done += 1
					progress.assets = math.min(0.99, done / #list)
				end)
			end)
		end
		progress.assets = 1
	end)

	-- Ana döngü: çubuğu hedefe doğru ilerlet, bitince solarak kapat
	local shown = 0
	local finished = false
	local connection
	local renderStart -- ilk çizilen karenin zamanı
	connection = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		renderStart = renderStart or os.clock()
		local clock = os.clock() - renderStart -- ekranın görünür kaldığı süre
		local allDone = true
		for stage in LoadingScreen.Stages do
			if progress[stage] < 1 then
				allDone = false
			end
		end
		local timedOut = os.clock() - startedAt > maxSeconds + 2
		local target = if timedOut then 1 else LoadingScreen.target(progress)
		if clock < LoadingScreen.MinSeconds then
			target = math.min(target, 0.97 * clock / LoadingScreen.MinSeconds) -- kısa sürede dolup hemen kapanmasın
		end
		shown = LoadingScreen.ease(shown, target, dt)
		screen.setProgress(shown)
		screen.setDots(clock)
		screen.animate(clock)

		if (allDone or timedOut) and clock >= LoadingScreen.MinSeconds and shown >= 0.995 then
			finished = true
			connection:Disconnect()
			print(`[Loading] done after {string.format("%.1f", clock)} s{if timedOut then " (timed out)" else ""}`)
			screen.setProgress(1)
			task.delay(0.25, function()
				local tween = screen.fadeOut(0.5)
				tween.Completed:Wait()
				screen.gui:Destroy()
			end)
		end
	end)
end

return LoadingScreen
