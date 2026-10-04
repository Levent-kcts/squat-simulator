local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local PlayerStats = require(script.Parent.PlayerStats)
local Build = require(script.Parent.Build)

local cfg = Config.Wall

local WallService = {}

-- Duvarlar her oyuncuya özeldir: sunucu sadece oyuncu başına canları tutar,
-- duvar parçalarını her oyuncu kendi ekranında oluşturur (bkz. client/WallClient).
-- runs[player] = { hp = { [1..Count] }, frontier = hayatta olan ilk duvarın sırası }
local runs = {}
local wallsEvent
local notifyEvent -- oyuncuya kısa mesaj (init'te verilir)
local VIP_PROMPT_INTERVAL = 8 -- aynı oyuncuya VIP satın alma penceresi en sık bu kadar saniyede bir gösterilir
local lastVipPrompt = {} -- [userId] = zaman

local function newRun()
	local hp = {}
	for i = 1, cfg.Count do
		hp[i] = Layout.maxHp(i)
	end
	return { hp = hp, frontier = 1 }
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleportToSpawn(player)
	if player.Character then
		player.Character:PivotTo(CFrame.new(Config.SpawnPosition))
	end
end

local function resetRun(player)
	local run = newRun()
	runs[player] = run
	wallsEvent:FireClient(player, "Sync", run.hp)
end

local function advanceFrontier(run)
	while run.frontier <= cfg.Count and run.hp[run.frontier] <= 0 do
		run.frontier += 1
	end
end

-- VIP kontrolü: game pass'e sahip mi (sonuç oyuncu başına bir kez sorulur ve saklanır)
local vipCache = {}

local function isVip(player)
	local passId = Config.VipGamePassId
	if not passId or passId <= 0 then
		return false
	end
	if vipCache[player.UserId] == nil then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		vipCache[player.UserId] = ok and owns or false
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
local function createWinButton(folder, stage, def)
	local lastWallIndex = stage * cfg.GroupSize
	local reward = math.floor(Layout.reward(stage) * (def.rewardMultiplier or 1))

	local part = Instance.new("Part")
	part.Name = `WinPad_{def.id}_{stage}`
	part.Anchored = true
	part.CanCollide = false -- üstünden geçilsin, takılmasın
	part.Size = Vector3.new(9, 0.6, 6)
	-- Ped odanın köşelerine yakın durur (oda genişse dışa kayar, koridor genişliğinde eski yerinde kalır)
	part.Position = Vector3.new(def.side * Layout.padX(), Layout.FloorTop + 0.3, Layout.padZ(stage))
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
		-- Bu pedden önceki tüm duvarlar BU oyuncu için kırılmış olmalı
		if not run or run.frontier <= lastWallIndex then
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
		resetRun(player)
		teleportToSpawn(player)
	end)
end

-- Aşamalar arası boşlukta sol yan duvara asılı aşama tabelası
local function createSign(folder, name, side, z, text, boardColor, textColor)
	local board = Instance.new("Part")
	board.Name = name
	board.Anchored = true
	board.CanCollide = false
	board.Size = Vector3.new(0.3, 7, 12)
	board.Position = Vector3.new(side * (cfg.Width / 2 + (cfg.ChamberExtra or 0) - 0.15), Layout.FloorTop + 9, z)
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

function WallService.init(notify)
	notifyEvent = notify
	wallsEvent = Instance.new("RemoteEvent")
	wallsEvent.Name = "WallsEvent"
	wallsEvent.Parent = ReplicatedStorage

	-- İstemci duvarlarını kurunca mevcut canları ister
	wallsEvent.OnServerEvent:Connect(function(player, action)
		local run = runs[player]
		if action == "Request" and run then
			wallsEvent:FireClient(player, "Sync", run.hp)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		runs[player] = newRun()
	end)
	for _, player in Players:GetPlayers() do
		runs[player] = newRun()
	end
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
		vipCache[player.UserId] = nil
		lastVipPrompt[player.UserId] = nil
	end)

	-- VIP game pass satın alındı: önbellek güncellenir, pede hemen basılabilir
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased and gamePassId == Config.VipGamePassId then
			vipCache[player.UserId] = true
			notifyEvent:FireClient(player, true, "VIP unlocked! Step on the pink pad for 2x Wins.")
		end
	end)

	-- Herkesin ortak gördüğü sabit parçalar: zemin, yan duvarlar, bitiş duvarı, Win butonları
	local folder = Instance.new("Folder")
	folder.Name = "Course"
	folder.Parent = Workspace

	local length = Layout.ZFront - Layout.ZEnd
	local centerZ = (Layout.ZFront + Layout.ZEnd) / 2
	local halfWidth = cfg.Width / 2
	local ceiling = cfg.CeilingHeight

	Build.block(
		folder,
		"Floor",
		Vector3.new(cfg.Width + 2, 1, length),
		Vector3.new(0, Layout.FloorTop - 0.5, centerZ),
		Color3.fromRGB(150, 160, 215),
		Enum.Material.Plastic,
		true
	)

	-- Yan duvarlar ve tavan aşama aşama farklı renkte; Win butonundan sonra yeni renk başlar
	for stage = 1, Layout.StageCount do
		local zStart = Layout.sectionStartZ(stage)
		local zStop = Layout.sectionEndZ(stage)
		local sectionLength = zStart - zStop
		local sectionCenter = (zStart + zStop) / 2
		local color = Layout.stageColor(stage)

		-- Duvarların olduğu dar bölüm + sonundaki geniş Win odası. Parçalar birbirine TAM yüzlerinde değer (üst üste binmez, boşluk kalmaz):
		--   [dar yan duvar] [yakın omuz] [oda yan duvarı + zemin/tavan şeritleri] [uzak omuz] [sonraki aşamanın dar yan duvarı]
		-- Omuzlar duvar kalınlığındaki (Thickness) bloklardır; koridor genişliğindeki duvar ile oda duvarı arasını kapatırlar.
		local extra = cfg.ChamberExtra or 0
		local half = cfg.Thickness / 2
		local lastWallZ = Layout.wallZ(stage * cfg.GroupSize)
		local firstWallZ = Layout.wallZ((stage - 1) * cfg.GroupSize + 1)
		local hasChamber = extra > 0
		local narrowTop = if hasChamber and stage > 1 then firstWallZ - half else zStart -- önceki odanın uzak omzunun ön yüzü
		local narrowBottom = if hasChamber then lastWallZ + half else zStop -- yakın omzun arka yüzü
		local nearFace = lastWallZ - half -- odanın başladığı yüz (yakın omzun ön yüzü)
		local farFace = if stage < Layout.StageCount then lastWallZ - cfg.ButtonGap + half else Layout.ZEnd -- odanın bittiği yüz
		local roofTop = lastWallZ + half -- tavan şeridi yakın omzun üstünü de örter
		local roofBottom = if stage < Layout.StageCount then lastWallZ - cfg.ButtonGap - half else Layout.ZEnd

		for _, side in { -1, 1 } do
			Build.block(
				folder,
				`Side_{stage}`,
				Vector3.new(1, ceiling, narrowTop - narrowBottom),
				Vector3.new(side * (halfWidth + 0.5), ceiling / 2, (narrowTop + narrowBottom) / 2),
				color,
				Enum.Material.Plastic,
				true
			)
			if hasChamber then
				local capWidth = extra + 1 -- koridor yan duvarının iç yüzünden oda yan duvarının dış yüzüne
				local capX = side * (halfWidth + capWidth / 2)
				-- Odanın yan duvarı: iki ucunda omuzların içine 0.5 stud girer (içeriden görünmez, arada ışık sızmaz)
				Build.block(
					folder,
					`ChamberSide_{stage}`,
					Vector3.new(1, ceiling, nearFace - farFace + 1),
					Vector3.new(side * (halfWidth + extra + 0.5), ceiling / 2, (nearFace + farFace) / 2),
					color,
					Enum.Material.Plastic,
					true
				)
				Build.block(folder, `ChamberCapNear_{stage}`, Vector3.new(capWidth, ceiling, cfg.Thickness), Vector3.new(capX, ceiling / 2, lastWallZ), color, Enum.Material.Plastic, true)
				if stage < Layout.StageCount then
					Build.block(folder, `ChamberCapFar_{stage}`, Vector3.new(capWidth, ceiling, cfg.Thickness), Vector3.new(capX, ceiling / 2, lastWallZ - cfg.ButtonGap), color, Enum.Material.Plastic, true)
				end
				-- Odanın yanlara taşan zemin ve tavan şeritleri (ana zemin/tavan koridor genişliğinde, x = +-17'de biter)
				local stripX = side * (halfWidth + 1 + extra / 2)
				Build.block(folder, `ChamberFloor_{stage}`, Vector3.new(extra, 1, nearFace - farFace), Vector3.new(stripX, Layout.FloorTop - 0.5, (nearFace + farFace) / 2), Color3.fromRGB(150, 160, 215), Enum.Material.Plastic, true)
				Build.block(folder, `ChamberRoof_{stage}`, Vector3.new(extra, 1, roofTop - roofBottom), Vector3.new(stripX, ceiling + 0.5, (roofTop + roofBottom) / 2), color, Enum.Material.Plastic, true)
			end
		end
		if hasChamber then
			Build.ceilingLight(folder, `ChamberLight_{stage}`, Vector3.new(14, 0.5, 14), Vector3.new(0, ceiling - 0.25, (nearFace + farFace) / 2), 40)
		end
		Build.block(
			folder,
			`Roof_{stage}`,
			Vector3.new(cfg.Width + 2, 1, sectionLength),
			Vector3.new(0, ceiling + 0.5, sectionCenter),
			color,
			Enum.Material.Plastic,
			true
		)
		Build.ceilingLight(
			folder,
			`Light_{stage}`,
			Vector3.new(14, 0.5, 14),
			Vector3.new(0, ceiling - 0.25, sectionCenter),
			40
		)
	end
	Build.block(
		folder,
		"EndWall",
		Vector3.new(cfg.Width + 2 + 2 * (cfg.ChamberExtra or 0), ceiling + 1, 2),
		Vector3.new(0, (ceiling + 1) / 2, Layout.ZEnd - 1),
		Layout.stageColor(Layout.StageCount),
		Enum.Material.Plastic,
		true
	)

	for stage = 1, Layout.StageCount do
		for _, def in Config.WinButtons do
			createWinButton(folder, stage, def)
		end
		local signZ = Layout.wallZ(stage * cfg.GroupSize) - cfg.ButtonGap / 2 - 1
		createSign(folder, `StageSign_{stage}`, -1, signZ, `STAGE {stage}\nCLEARED!`, Color3.fromRGB(255, 215, 60), Color3.new(1, 1, 1))
	end
end

-- TEST: oyuncunun şu anki aşamasındaki tüm duvarları kır
function WallService.devBreakStage(player)
	local run = runs[player]
	if not run then
		return
	end
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
	advanceFrontier(run)
	local index = math.min(run.frontier, cfg.Count)
	player.Character:PivotTo(CFrame.new(0, 5, Layout.wallZ(index) + cfg.Thickness / 2 + 5))
end

WallService.devTeleportToWalls = WallService.teleportToWalls

-- Rebirth sonrası: oyuncunun duvarlarını baştan kur ve başlangıç alanına ışınla
function WallService.resetPlayer(player)
	if runs[player] then
		resetRun(player)
		teleportToSpawn(player)
	end
end

-- Oyuncu kendi ilk sağlam duvarının vuruş menzilinde mi? (tekme mi squat mı seçmek için)
function WallService.isNearWall(player)
	local run = runs[player]
	local root = getRoot(player)
	if not run or not root then
		return false
	end
	advanceFrontier(run)
	return run.frontier <= cfg.Count and Layout.withinReach(run.frontier, root.Position)
end

-- Oyuncunun kendi ilk sağlam duvarına yakınsa, hasarı sırayla duvarlara uygular.
-- Hasar o duvarın aşamasının (5'li grup) son duvarını geçmez.
function WallService.hit(player, damage)
	local run = runs[player]
	local root = getRoot(player)
	if not run or not root then
		return false
	end

	advanceFrontier(run)
	if run.frontier > cfg.Count then
		return false
	end

	if not Layout.withinReach(run.frontier, root.Position) then
		return false
	end

	local groupEnd = math.min(math.ceil(run.frontier / cfg.GroupSize) * cfg.GroupSize, cfg.Count)
	local remaining = damage
	local changes = {}
	for i = run.frontier, groupEnd do
		if remaining <= 0 then
			break
		end
		local hp = run.hp[i]
		if hp > 0 then
			if remaining >= hp then
				remaining -= hp
				run.hp[i] = 0
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
				if currentRoot and currentRoot.Position.Z < Layout.ZFront then
					teleportToSpawn(player)
				end
			end
		end)
	end

	return true
end

return WallService
