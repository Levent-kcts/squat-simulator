local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local PlayerStats = require(script.Parent.PlayerStats)
local Build = require(script.Parent.Build)


local WallService = {}

-- Duvarlar her oyuncuya özeldir: sunucu sadece oyuncu başına canları tutar,
-- duvar parçalarını her oyuncu kendi ekranında oluşturur (bkz. client/WallClient).
-- runs[player] = { hp = { [1..Count] }, frontier = hayatta olan ilk duvarın sırası, world = Layout.world nesnesi }
-- DÜNYALAR (World 2): her dünyanın kendi koridoru vardır (Layout.world); oyuncunun turu bulunduğu dünyanın duvarlarındadır.
local runs = {}
local wallsEvent
local notifyEvent -- oyuncuya kısa mesaj (init'te verilir)
local VIP_PROMPT_INTERVAL = 8 -- aynı oyuncuya VIP satın alma penceresi en sık bu kadar saniyede bir gösterilir
local lastVipPrompt = {} -- [userId] = zaman

local function newRun(W)
	local hp = {}
	for i = 1, W.cfg.Count do
		hp[i] = W.maxHp(i)
	end
	return { hp = hp, frontier = 1, world = W }
end

-- Oyuncunun bulunduğu dünya (kayıttan; veri yüklenmediyse World 1)
local function playerWorld(player)
	return Layout.world(PlayerStats.currentWorld(player))
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Oyuncuyu bulunduğu dünyanın doğma yerine ışınlar (World 1 = Config.SpawnPosition)
local function teleportToSpawn(player)
	if player.Character then
		player.Character:PivotTo(CFrame.new(playerWorld(player).spawn))
	end
end

local function resetRun(player)
	local run = newRun(playerWorld(player))
	runs[player] = run
	-- Sync dünya kimliğini de taşır: istemci başka dünyadaysa duvarlarını o dünyanın koridorunda yeniden kurar
	wallsEvent:FireClient(player, "Sync", run.hp, run.world.id)
end

local function advanceFrontier(run)
	while run.frontier <= run.world.cfg.Count and run.hp[run.frontier] <= 0 do
		run.frontier += 1
	end
end

-- Bu dünyanın son aşamasıyla açılan dünya (Config.Worlds.List[].unlock = { world, stage }); yoksa nil
local function worldUnlockedBy(worldId, stage)
	for index, def in Config.Worlds.List do
		local unlock = def.unlock
		if unlock and unlock.world == worldId and unlock.stage == stage then
			return def.id or index
		end
	end
	return nil
end

-- VIP kontrolü: game pass'e sahip mi (sonuç oyuncu başına bir kez sorulur ve saklanır)
local vipCache = {}

local function isVip(player)
	local passId = Config.VipGamePassId
	if not passId or passId <= 0 then
		return false
	end
	if player:GetAttribute("DevPassLock") == true then
		return false -- DEV testi (DevTools 'TogglePassLock'): pass'e sahip DEĞİLMİŞ gibi davran
	end
	if vipCache[player.UserId] == nil then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if not ok then
			return false -- sorgu başarısız: önbelleğe 'sahip değil' yazma, bir sonraki basışta yeniden sorulur
		end
		vipCache[player.UserId] = owns == true
	end
	return vipCache[player.UserId]
end

local function vipEnabled()
	return (Config.VipGamePassId or 0) > 0
end

local function addLabel(parent, text, textColor, offset)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(8, 2.5) -- stud cinsinden: uzaktayken küçülür, yan yana etiketler üst üste binmez
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = 90
	gui.Adornee = parent
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = textColor
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
end

-- Her aşamadan sonra, sonraki duvarın hemen önünde koridorun iki kenarında birer Win pedi durur.
-- İsteyen üstüne basar (Win + yeni tur + başlangıç alanına ışınlanma), isteyen ortadan geçip devam eder.
local function createWinButton(folder, W, stage, def)
	local lastWallIndex = stage * W.cfg.GroupSize
	local reward = math.floor(W.reward(stage) * (def.rewardMultiplier or 1))

	local part = Instance.new("Part")
	part.Name = if W.id == 1 then `WinPad_{def.id}_{stage}` else `WinPad_W{W.id}_{def.id}_{stage}`
	part.Anchored = true
	part.CanCollide = false -- üstünden geçilsin, takılmasın
	part.Size = Vector3.new(9, 0.6, 6)
	-- Ped odanın köşelerine yakın durur (oda genişse dışa kayar, koridor genişliğinde eski yerinde kalır)
	part.Position = Vector3.new(W.originX + def.side * W.padX(), Layout.FloorTop + 0.3, W.padZ(stage))
	part.Material = Enum.Material.Neon
	part.Color = if def.vip then Color3.fromRGB(255, 80, 220) else Color3.fromRGB(255, 220, 40)
	part.Parent = folder

	-- Etiket pedin kendi ödülünü yazar (VIP pedinde normalin 2 katı): "+1 Win", "+6 Wins"
	local text = if reward == 1 then "+1 Win" else `+{reward} Wins`
	addLabel(part, text, part.Color, Vector3.new(0, 3.5, 0))

	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local run = runs[player]
		-- Bu pedden önceki tüm duvarlar BU oyuncu için ve BU dünyada kırılmış olmalı
		if not run or run.world ~= W or run.frontier <= lastWallIndex then
			return
		end
		-- VIP pedi: game pass'i olmayana Robux satın alma penceresi açılır (game pass henüz yoksa bilgi mesajı)
		if def.vip and not isVip(player) then
			local now = os.clock()
			if now - (lastVipPrompt[player.UserId] or 0) >= VIP_PROMPT_INTERVAL then
				lastVipPrompt[player.UserId] = now
				if vipEnabled() then
					MarketplaceService:PromptGamePassPurchase(player, Config.VipGamePassId)
				else
					notifyEvent:FireClient(player, false, "VIP (2x Wins) is coming soon!")
				end
			end
			return
		end
		PlayerStats.addWin(player, reward)
		if W.id == 1 then
			if stage >= 10 then
				PlayerStats.awardBadge(player, "stage10")
			end
			if stage >= W.StageCount then
				PlayerStats.awardBadge(player, "stage20")
			end
		elseif W.id == 2 and stage >= W.StageCount then
			PlayerStats.awardBadge(player, "w2stage20")
		end
		-- Dünya kilidi: bu aşama bir sonraki dünyayı açıyorsa (World 1'in 20. aşaması -> World 2) kalıcı olarak açılır
		local nextWorld = worldUnlockedBy(W.id, stage)
		if nextWorld and PlayerStats.unlockWorld(player, nextWorld) then
			local name = Layout.world(nextWorld).name
			notifyEvent:FireClient(player, true, `{string.upper(name)} UNLOCKED! Walk through the WORLDS gate in the lobby.`)
			PlayerStats.awardBadge(player, "world2")
		end
		resetRun(player)
		teleportToSpawn(player)
	end)
end

-- Aşamalar arası boşlukta sol yan duvara asılı aşama tabelası
local function createSign(folder, W, name, side, z, text, boardColor, textColor)
	local cfg = W.cfg
	local board = Instance.new("Part")
	board.Name = name
	board.Anchored = true
	board.CanCollide = false
	board.Size = Vector3.new(0.3, 7, 12)
	board.Position = Vector3.new(W.originX + side * (cfg.Width / 2 + (cfg.ChamberExtra or 0) - 0.15), Layout.FloorTop + 9, z)
	board.Color = boardColor
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = textColor
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
end

-- Bir dünyanın herkesin ortak gördüğü sabit parçaları: zemin, yan duvarlar, Win odaları, bitiş duvarı, Win pedleri.
-- World 1'in klasörü eski adıyla 'Course' kalır; diğer dünyalar 'Course_W<id>'.
local function buildCourse(W)
	local cfg = W.cfg
	local x0 = W.originX
	local folder = Instance.new("Folder")
	folder.Name = if W.id == 1 then "Course" else `Course_W{W.id}`
	folder.Parent = Workspace

	local length = W.ZFront - W.ZEnd
	local centerZ = (W.ZFront + W.ZEnd) / 2
	local halfWidth = cfg.Width / 2
	local ceiling = cfg.CeilingHeight

	Build.block(
		folder,
		"Floor",
		Vector3.new(cfg.Width + 2, 1, length),
		Vector3.new(x0, Layout.FloorTop - 0.5, centerZ),
		Color3.fromRGB(150, 160, 215),
		Enum.Material.Plastic,
		true
	)

	-- Yan duvarlar ve tavan aşama aşama farklı renkte; Win butonundan sonra yeni renk başlar
	for stage = 1, W.StageCount do
		local zStart = W.sectionStartZ(stage)
		local zStop = W.sectionEndZ(stage)
		local sectionLength = zStart - zStop
		local sectionCenter = (zStart + zStop) / 2
		local color = W.stageColor(stage)

		-- Duvarların olduğu dar bölüm + sonundaki geniş Win odası. Parçalar birbirine TAM yüzlerinde değer (üst üste binmez, boşluk kalmaz):
		--   [dar yan duvar] [yakın omuz] [oda yan duvarı + zemin/tavan şeritleri] [uzak omuz] [sonraki aşamanın dar yan duvarı]
		-- Omuzlar duvar kalınlığındaki (Thickness) bloklardır; koridor genişliğindeki duvar ile oda duvarı arasını kapatırlar.
		local extra = cfg.ChamberExtra or 0
		local half = cfg.Thickness / 2
		local lastWallZ = W.wallZ(stage * cfg.GroupSize)
		local firstWallZ = W.wallZ((stage - 1) * cfg.GroupSize + 1)
		local hasChamber = extra > 0
		local narrowTop = if hasChamber and stage > 1 then firstWallZ - half else zStart -- önceki odanın uzak omzunun ön yüzü
		local narrowBottom = if hasChamber then lastWallZ + half else zStop -- yakın omzun arka yüzü
		local nearFace = lastWallZ - half -- odanın başladığı yüz (yakın omzun ön yüzü)
		local farFace = if stage < W.StageCount then lastWallZ - cfg.ButtonGap + half else W.ZEnd -- odanın bittiği yüz
		local roofTop = lastWallZ + half -- tavan şeridi yakın omzun üstünü de örter
		local roofBottom = if stage < W.StageCount then lastWallZ - cfg.ButtonGap - half else W.ZEnd

		for _, side in { -1, 1 } do
			Build.block(
				folder,
				`Side_{stage}`,
				Vector3.new(1, ceiling, narrowTop - narrowBottom),
				Vector3.new(x0 + side * (halfWidth + 0.5), ceiling / 2, (narrowTop + narrowBottom) / 2),
				color,
				Enum.Material.Plastic,
				true
			)
			if hasChamber then
				local capWidth = extra + 1 -- koridor yan duvarının iç yüzünden oda yan duvarının dış yüzüne
				local capX = x0 + side * (halfWidth + capWidth / 2)
				-- Odanın yan duvarı: iki ucunda omuzların içine 0.5 stud girer (içeriden görünmez, arada ışık sızmaz)
				Build.block(
					folder,
					`ChamberSide_{stage}`,
					Vector3.new(1, ceiling, nearFace - farFace + 1),
					Vector3.new(x0 + side * (halfWidth + extra + 0.5), ceiling / 2, (nearFace + farFace) / 2),
					color,
					Enum.Material.Plastic,
					true
				)
				Build.block(folder, `ChamberCapNear_{stage}`, Vector3.new(capWidth, ceiling, cfg.Thickness), Vector3.new(capX, ceiling / 2, lastWallZ), color, Enum.Material.Plastic, true)
				if stage < W.StageCount then
					Build.block(folder, `ChamberCapFar_{stage}`, Vector3.new(capWidth, ceiling, cfg.Thickness), Vector3.new(capX, ceiling / 2, lastWallZ - cfg.ButtonGap), color, Enum.Material.Plastic, true)
				end
				-- Odanın yanlara taşan zemin ve tavan şeritleri (ana zemin/tavan koridor genişliğinde biter)
				local stripX = x0 + side * (halfWidth + 1 + extra / 2)
				Build.block(folder, `ChamberFloor_{stage}`, Vector3.new(extra, 1, nearFace - farFace), Vector3.new(stripX, Layout.FloorTop - 0.5, (nearFace + farFace) / 2), Color3.fromRGB(150, 160, 215), Enum.Material.Plastic, true)
				Build.block(folder, `ChamberRoof_{stage}`, Vector3.new(extra, 1, roofTop - roofBottom), Vector3.new(stripX, ceiling + 0.5, (roofTop + roofBottom) / 2), color, Enum.Material.Plastic, true)
			end
		end
		Build.block(
			folder,
			`Roof_{stage}`,
			Vector3.new(cfg.Width + 2, 1, sectionLength),
			Vector3.new(x0, ceiling + 0.5, sectionCenter),
			color,
			Enum.Material.Plastic,
			true
		)
	end
	Build.block(
		folder,
		"EndWall",
		Vector3.new(cfg.Width + 2 + 2 * (cfg.ChamberExtra or 0), ceiling + 1, 2),
		Vector3.new(x0, (ceiling + 1) / 2, W.ZEnd - 1),
		W.stageColor(W.StageCount),
		Enum.Material.Plastic,
		true
	)

	-- Son odanın bitiş duvarındaki tabela. Bu dünyanın sonu yeni bir dünyayı açıyorsa onu duyurur ('SPACE WORLD' + kemere git),
	-- açmıyorsa yer tutucu 'COMING SOON' (wall.FinalWallText). Bitiş duvarının yüzü lego çıkıntılıdır (yazıyı delerdi),
	-- bu yüzden yazı çıkıntıların önüne konan ince, düz bir tabeladadır.
	local nextWorld = worldUnlockedBy(W.id, W.StageCount)
	local title = if nextWorld then string.upper(Layout.world(nextWorld).name) else cfg.FinalWallText
	local subtitle = if nextWorld then "Press a Win pad, then use the WORLDS gate!" else "More walls are on the way!"
	if title and title ~= "" then
		local board = Build.block(
			folder,
			"ComingSoonSign",
			Vector3.new(44, 11, 0.5),
			Vector3.new(x0, 13, W.ZEnd + 0.55), -- duvar yüzünün (ZEnd) hemen önünde, çıkıntıların (~0.2) dışında
			Color3.fromRGB(255, 205, 40),
			Enum.Material.SmoothPlastic
		)
		board.CanCollide = false
		board.CanQuery = false
		local boardGui = Instance.new("SurfaceGui")
		boardGui.Face = Enum.NormalId.Back -- koridordan gelen oyuncuya bakan (+Z) yüz
		boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		boardGui.PixelsPerStud = 30
		boardGui.Parent = board
		local function boardText(position, size, text, strokeThickness)
			local label = Instance.new("TextLabel")
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = position
			label.Size = size
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.Text = text
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Parent = boardGui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = strokeThickness
			stroke.Color = Color3.fromRGB(40, 25, 0)
			stroke.Parent = label
		end
		boardText(UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.92, 0.52), title, 6)
		boardText(UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.8, 0.2), subtitle, 3)
	end

	for stage = 1, W.StageCount do
		for _, def in Config.WinButtons do
			createWinButton(folder, W, stage, def)
		end
		local signZ = W.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap / 2 - 1
		createSign(folder, W, `StageSign_{stage}`, -1, signZ, `STAGE {stage}\nCLEARED!`, Color3.fromRGB(255, 215, 60), Color3.new(1, 1, 1))
	end
	return folder
end

-- Oyuncuyu bulunduğu dünyaya yerleştirir: tur o dünyanın duvarlarıyla baştan kurulur, istemciye Sync gider; teleport true ise doğma yerine ışınlanır
local function placeInWorld(player, teleport)
	resetRun(player)
	if teleport then
		teleportToSpawn(player)
	end
end

function WallService.init(notify)
	notifyEvent = notify
	wallsEvent = Instance.new("RemoteEvent")
	wallsEvent.Name = "WallsEvent"
	wallsEvent.Parent = ReplicatedStorage

	-- İstemci duvarlarını kurunca mevcut canları ister
	wallsEvent.OnServerEvent:Connect(function(player, action)
		local run = runs[player]
		if action == "Request" and run then
			wallsEvent:FireClient(player, "Sync", run.hp, run.world.id)
		end
	end)

	local function onPlayerAdded(player)
		runs[player] = newRun(Layout.world(1))
		-- Karakter her doğduğunda (giriş, ölüm) oyuncu kendi dünyasının doğma yerine gelir (SpawnLocation World 1'dedir)
		player.CharacterAdded:Connect(function(character)
			if PlayerStats.currentWorld(player) ~= 1 then
				task.defer(function()
					if character.Parent then
						character:PivotTo(CFrame.new(playerWorld(player).spawn))
					end
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	-- Kayıt yüklenince oyuncu kayıtlı dünyasına alınır (World 2'de çıkan World 2'de doğar)
	PlayerStats.onLoaded(function(player)
		local run = runs[player]
		if run and PlayerStats.currentWorld(player) ~= run.world.id then
			placeInWorld(player, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
		vipCache[player.UserId] = nil
		lastVipPrompt[player.UserId] = nil
	end)

	-- VIP game pass satın alındı: önbellek güncellenir, pede hemen basılabilir
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased and gamePassId == Config.VipGamePassId then
			player:SetAttribute("DevPassLock", nil) -- satın alma tamamlandı: DEV kilidi kalkar
			vipCache[player.UserId] = true
			notifyEvent:FireClient(player, true, "VIP unlocked! Step on the pink pad for 2x Wins.")
		end
	end)

	for id = 1, Layout.worldCount do
		buildCourse(Layout.world(id))
	end
end

-- DÜNYA GEÇİŞİ (WorldsGate portalı, DEV): dünya açıksa oyuncu o dünyaya geçer, turu o dünyanın duvarlarıyla başlar ve doğma yerine ışınlanır.
-- Karar sunucudadır: açık olmayan dünyaya geçilemez. Dönüş: ok, mesaj
function WallService.setWorld(player, id)
	if not runs[player] then
		return false, "Please wait, loading..."
	end
	if not PlayerStats.worldUnlocked(player, id) then
		return false, "This world is locked."
	end
	if PlayerStats.currentWorld(player) ~= id and not PlayerStats.setWorld(player, id) then
		return false, "Please wait, loading..."
	end
	placeInWorld(player, true)
	return true, `Welcome to {Layout.world(id).name}!`
end

-- TEST: oyuncunun şu anki aşamasındaki tüm duvarları kır
function WallService.devBreakStage(player)
	local run = runs[player]
	if not run then
		return
	end
	local cfg = run.world.cfg
	advanceFrontier(run)
	if run.frontier > cfg.Count then
		return
	end
	local groupEnd = math.min(math.ceil(run.frontier / cfg.GroupSize) * cfg.GroupSize, cfg.Count)
	local changes = {}
	for i = run.frontier, groupEnd do
		run.hp[i] = 0
		table.insert(changes, { i, 0 })
	end
	wallsEvent:FireClient(player, "Update", changes)
	advanceFrontier(run)
end

-- Oyuncuyu ilk sağlam duvarının önüne ışınla (sol taraftaki "Walls" butonu ve DEV paneli kullanır)
function WallService.teleportToWalls(player)
	local run = runs[player]
	if not run or not player.Character then
		return
	end
	local W = run.world
	advanceFrontier(run)
	local index = math.min(run.frontier, W.cfg.Count)
	player.Character:PivotTo(CFrame.new(W.originX, 5, W.wallZ(index) + W.cfg.Thickness / 2 + 5))
end

WallService.devTeleportToWalls = WallService.teleportToWalls

-- Rebirth sonrası: oyuncunun duvarlarını baştan kur ve başlangıç alanına ışınla (oyuncu BULUNDUĞU dünyada kalır)
function WallService.resetPlayer(player)
	if runs[player] then
		placeInWorld(player, true)
	end
end

-- Oyuncu kendi ilk sağlam duvarının vuruş menzilinde mi? (tekme mi squat mı seçmek için)
-- extra: menzile eklenen mesafe (Config.Wall.NoSquatRange ile 'squat yok' bölgesi); verilmezse tekme/hasar menzili
function WallService.isNearWall(player, extra)
	local run = runs[player]
	local root = getRoot(player)
	if not run or not root then
		return false
	end
	advanceFrontier(run)
	return run.frontier <= run.world.cfg.Count and run.world.withinReach(run.frontier, root.Position, extra)
end

-- Oyuncunun kendi ilk sağlam duvarına yakınsa, hasarı sırayla duvarlara uygular.
-- Hasar o duvarın aşamasının (5'li grup) son duvarını geçmez.
function WallService.hit(player, damage)
	local run = runs[player]
	local root = getRoot(player)
	if not run or not root then
		return false
	end
	local W = run.world
	local cfg = W.cfg

	advanceFrontier(run)
	if run.frontier > cfg.Count then
		return false
	end

	if not W.withinReach(run.frontier, root.Position) then
		return false
	end

	local groupEnd = math.min(math.ceil(run.frontier / cfg.GroupSize) * cfg.GroupSize, cfg.Count)
	local remaining = damage
	local changes = {}
	local broken = 0 -- bu vuruşta kırılan duvar sayısı (günlük görevler için)
	for i = run.frontier, groupEnd do
		if remaining <= 0 then
			break
		end
		local hp = run.hp[i]
		if hp > 0 then
			if remaining >= hp then
				remaining -= hp
				run.hp[i] = 0
				broken += 1
			else
				run.hp[i] = hp - remaining
				remaining = 0
			end
			table.insert(changes, { i, run.hp[i] })
		end
	end

	wallsEvent:FireClient(player, "Update", changes)
	advanceFrontier(run)

	-- Son duvar da kırıldıysa ve oyuncu Win'e basmazsa tur kendiliğinden başa sarar
	if run.frontier > cfg.Count then
		task.delay(cfg.RespawnDelay, function()
			if runs[player] == run and run.frontier > cfg.Count then
				local currentRoot = getRoot(player)
				resetRun(player)
				if currentRoot and W.inCorridor(currentRoot.Position) then
					teleportToSpawn(player)
				end
			end
		end)
	end

	return true, broken
end

return WallService
