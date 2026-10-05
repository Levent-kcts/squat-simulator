-- Sıralama tabloları: sol duvarın arka köşesinde iki pano (en çok bacak kası, en çok rebirth). Roblox'un sıralı veri deposunu
-- (OrderedDataStore) kullanır: oyuncuların değerleri dakikada bir yazılır, ilk 10 okunup panolara basılır.
-- Kayıt güvenliği: sadece verisi başarıyla yüklenmiş oyuncular yazılır (PlayerStats.canSave). Studio'da API erişimi kapalıysa
-- panolar "unavailable" yazar, oyun etkilenmez.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)

local Leaderboards = {}

local ROWS = 10
local REFRESH_INTERVAL = 60 -- yazma ve okuma aralığı (saniye); DataStore limitlerini aşmamak için
local BOARD_WIDTH = 7 -- eskiden 10 x 15 idi, kamerada fazla büyük duruyordu
local BOARD_HEIGHT = 10.5
local BOARD_CENTER_Y = 8.5

-- Panolar: statName leaderstats'taki ad, store sıralı veri deposunun adı (değişirse tablo sıfırlanır)
local BOARDS = {
	{ title = "LEG MUSCLE", statName = Config.StatLegMuscle, store = "Leaderboard_Muscle_v1", color = Color3.fromRGB(255, 150, 40) },
	{ title = "REBIRTHS", statName = Config.StatRebirths, store = "Leaderboard_Rebirths_v1", color = Color3.fromRGB(235, 70, 170) },
}

local MEDAL_COLORS = { Color3.fromRGB(255, 215, 60), Color3.fromRGB(215, 220, 230), Color3.fromRGB(215, 140, 80) }

local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] == nil then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		nameCache[userId] = if ok then name else "Player"
	end
	return nameCache[userId]
end

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

-- Panoyu kurar, satır etiketlerini döndürür: rows[i] = { rank, name, value }
local function buildBoard(folder, frame, board, localX)
	local part = Instance.new("Part")
	part.Name = `Board_{board.statName}`
	part.Anchored = true
	part.Size = Vector3.new(BOARD_WIDTH, BOARD_HEIGHT, 0.5)
	part.Color = Color3.fromRGB(28, 30, 46)
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = frame * CFrame.new(localX, BOARD_CENTER_Y, -0.4)
	part.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 57 -- pano küçüldüğü için yazı aynı netlikte kalsın diye artırıldı (40 x 10/7)
	gui.Parent = part

	local header = Instance.new("Frame")
	header.Size = UDim2.fromScale(1, 0.12)
	header.BackgroundColor3 = board.color
	header.BorderSizePixel = 0
	header.Parent = gui
	textLabel(header, { Size = UDim2.fromScale(1, 0.85), Position = UDim2.fromScale(0, 0.08), Text = board.title, TextColor3 = Color3.new(1, 1, 1) }, 3)

	local rows = {}
	for index = 1, ROWS do
		local y = 0.14 + (index - 1) * 0.077
		local color = MEDAL_COLORS[index] or Color3.new(1, 1, 1)
		rows[index] = {
			rank = textLabel(gui, { Position = UDim2.fromScale(0.03, y), Size = UDim2.fromScale(0.15, 0.065), Text = `#{index}`, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, 2),
			name = textLabel(gui, { Position = UDim2.fromScale(0.2, y), Size = UDim2.fromScale(0.5, 0.065), Text = "-", TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, 2),
			value = textLabel(gui, { Position = UDim2.fromScale(0.68, y), Size = UDim2.fromScale(0.29, 0.065), Text = "", TextColor3 = Color3.fromRGB(255, 235, 120), TextXAlignment = Enum.TextXAlignment.Right }, 2),
		}
	end
	local footer = textLabel(gui, { Position = UDim2.fromScale(0, 0.93), Size = UDim2.fromScale(1, 0.05), Text = "Updates every minute", TextColor3 = Color3.fromRGB(170, 175, 195) }, 1)
	return rows, footer
end

function Leaderboards.init()
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = workspace

	-- Sol duvarın arka ucu (skin rafından sonra boş bırakılan köşe)
	local frame = Shelf.leftWallFrame(Config.Lobby.LeaderboardZ)

	local boards = {}
	for index, board in BOARDS do
		local localX = (index - (#BOARDS + 1) / 2) * (BOARD_WIDTH + 1)
		local rows, footer = buildBoard(folder, frame, board, localX)
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, board.store)
		table.insert(boards, { def = board, rows = rows, footer = footer, store = if ok then store else nil, lastWritten = {} })
	end

	local warned = false
	local function warnOnce(message)
		if not warned then
			warned = true
			warn(`[Leaderboards] {message}`)
		end
	end

	local function writeValues(board)
		if not board.store then
			return
		end
		for _, player in Players:GetPlayers() do
			local leaderstats = player:FindFirstChild("leaderstats")
			local stat = leaderstats and leaderstats:FindFirstChild(board.def.statName)
			if stat and PlayerStats.canSave(player) then
				local value = math.max(0, math.floor(stat.Value))
				if board.lastWritten[player.UserId] ~= value then
					local ok, err = pcall(board.store.SetAsync, board.store, tostring(player.UserId), value)
					if ok then
						board.lastWritten[player.UserId] = value
					else
						warnOnce(tostring(err))
					end
				end
			end
		end
	end

	local function readTop(board)
		if not board.store then
			return false
		end
		local ok, pages = pcall(board.store.GetSortedAsync, board.store, false, ROWS)
		if not ok then
			warnOnce(tostring(pages))
			return false
		end
		local entries = pages:GetCurrentPage()
		for index = 1, ROWS do
			local row = board.rows[index]
			local entry = entries[index]
			if entry then
				row.name.Text = nameOf(tonumber(entry.key) or 0)
				row.value.Text = Format.compact(entry.value)
			else
				row.name.Text = "-"
				row.value.Text = ""
			end
		end
		board.footer.Text = "Updates every minute"
		return true
	end

	local function refreshAll()
		for _, board in boards do
			writeValues(board)
			if not readTop(board) then
				board.footer.Text = "Unavailable (enable API access)"
			end
		end
	end

	task.spawn(function()
		task.wait(5) -- oyuncuların verisi yüklensin
		while true do
			refreshAll()
			task.wait(REFRESH_INTERVAL)
		end
	end)

	-- Oyuncu çıkarken son değerini yaz (bir sonraki yenilemede panoda görünsün)
	Players.PlayerRemoving:Connect(function(player)
		for _, board in boards do
			if board.store and PlayerStats.canSave(player) then
				local leaderstats = player:FindFirstChild("leaderstats")
				local stat = leaderstats and leaderstats:FindFirstChild(board.def.statName)
				if stat then
					task.spawn(pcall, board.store.SetAsync, board.store, tostring(player.UserId), math.max(0, math.floor(stat.Value)))
				end
			end
		end
	end)
end

return Leaderboards
