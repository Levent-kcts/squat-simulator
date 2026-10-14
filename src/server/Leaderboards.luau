-- Sıralama tabloları: lobinin sol arka köşesinde, DUVARA YASLI DEĞİL, odaya doğru dönük (hafif yay) iki bağımsız pano standı (en çok bacak kası, en çok rebirth).
-- Her stand referans oyundaki gibi: taş renkli çerçeveli pano, altında basamaklı kaide, üstünde renkli başlık şeridi ve havada duran simge, yanlarında lego blok sütunları.
-- Satırlar: sıra, oyuncu resmi, ad, değer, simge. Roblox'un sıralı veri deposunu (OrderedDataStore) kullanır: oyuncuların değerleri dakikada bir yazılır, ilk 10 okunup panolara basılır.
-- Kayıt güvenliği: sadece verisi başarıyla yüklenmiş oyuncular yazılır (PlayerStats.canSave). Studio'da API erişimi kapalıysa
-- panolar "unavailable" yazar, oyun etkilenmez.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Layout = require(Shared:WaitForChild("Layout"))
local PlayerStats = require(script.Parent.PlayerStats)
local Build = require(script.Parent.Build)

local Leaderboards = {}

local ROWS = 10
local REFRESH_INTERVAL = 60 -- yazma ve okuma aralığı (saniye); DataStore limitlerini aşmamak için
local BOARD_WIDTH = 7 -- eskiden 10 x 15 idi, kamerada fazla büyük duruyordu; küçük kalır
local BOARD_HEIGHT = 10.5
local FRAME_THICKNESS = 0.6 -- panonun taş çerçevesi
local BOARD_PITCH = 10.2 -- iki panonun merkezleri arası (stand ekseninde)

-- Panolar: statName leaderstats'taki ad, store sıralı veri deposunun adı (değişirse tablo sıfırlanır), icon yüklenen görsel (boşsa emoji)
local BOARDS = {
	{ title = "LEG MUSCLE", subtitle = "ALL-TIME LEADERBOARD", lifetime = true, statName = Config.StatLegMuscle, store = "Leaderboard_Muscle_v1", color = Color3.fromRGB(255, 150, 40), icon = Config.Icons.LegMuscle, emoji = "🦵" },
	{ title = "REBIRTHS", statName = Config.StatRebirths, store = "Leaderboard_Rebirths_v1", color = Color3.fromRGB(235, 70, 170), icon = Config.Icons.Rebirth, emoji = "🔄" },
}

local MEDAL_COLORS = { Color3.fromRGB(255, 215, 60), Color3.fromRGB(215, 220, 230), Color3.fromRGB(215, 140, 80) }
-- Taş/lego grisi tonları (sütunlar, çerçeve, kaide)
local STONE = { Color3.fromRGB(150, 158, 172), Color3.fromRGB(174, 181, 195), Color3.fromRGB(128, 136, 153) }
local STONE_DARK = Color3.fromRGB(96, 104, 122)

-- Bir oyuncunun panodaki değeri: LEG MUSCLE panosu (lifetime = true) bugüne kadar kazanılan TOPLAM kasa bakar (rebirth sıfırlamaz; sahibi 'şimdiye kadar üretilmiş tüm leg power' dedi),
-- diğerleri leaderstats'taki güncel değere. Veri yoksa nil. OrderedDataStore int64 tutar: üst sınır 9e18.
local function boardValue(player, board)
	local value
	if board.lifetime then
		value = PlayerStats.lifetimeMuscle(player)
	else
		local leaderstats = player:FindFirstChild("leaderstats")
		local stat = leaderstats and leaderstats:FindFirstChild(board.statName)
		value = stat and stat.Value
	end
	if value == nil then
		return nil
	end
	return math.clamp(math.floor(value), 0, 9e18)
end

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

-- Pano simgesi: yüklenen görsel varsa o, yoksa emoji. props: Position, Size, AnchorPoint ...
local function iconLabel(parent, board, props)
	if board.icon and board.icon ~= "" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Image = board.icon
		image.ScaleType = Enum.ScaleType.Fit
		for key, value in props do
			image[key] = value
		end
		image.Parent = parent
		return image
	end
	props.Text = board.emoji
	return textLabel(parent, props, 0)
end

-- Lego blok sütunu: üst üste dizilen, hafif dönük ve her kat farklı tonda taş bloklar (koridor girişindeki kulelerle aynı fikir)
local function pillar(folder, frame, x, layers, width, seed)
	local layerHeight = 1.9
	for layer = 1, layers do
		local color = STONE[(seed + layer) % #STONE + 1]
		local yaw = (if layer % 2 == 0 then 0.2 else -0.14) * (if seed % 2 == 0 then 1 else -1)
		local part = Build.block(folder, "LeaderboardPillar", Vector3.new(width, layerHeight, width), Vector3.zero, color, Enum.Material.Plastic, true)
		part.CFrame = frame * CFrame.new(x, Layout.FloorTop + (layer - 0.5) * layerHeight, 0.4) * CFrame.Angles(0, yaw, 0)
	end
end

-- Pano standını kurar, satır etiketlerini döndürür: rows[i] = { rank, avatar, name, value }
-- Yerel eksen (frame): -Z odaya (okuyucuya) bakar, +Z arkaya, Y yukarı; localX stand ekseninde panonun yeri
local function buildBoard(folder, frame, board, localX)
	local function put(name, size, x, y, z, color, material, studs)
		local part = Build.block(folder, name, size, Vector3.zero, color, material or Enum.Material.Plastic, studs)
		part.CFrame = frame * CFrame.new(localX + x, Layout.FloorTop + y, z)
		return part
	end

	-- Basamaklı kaide (zemine oturur, pano havada durmaz)
	put("BoardPlinth", Vector3.new(BOARD_WIDTH + 2.4, 1, 3.8), 0, 0.5, 0.5, STONE[1], nil, true)
	put("BoardPlinthTop", Vector3.new(BOARD_WIDTH + 1.4, 0.6, 2.8), 0, 1.3, 0.4, STONE[2], nil, true)
	local boardBottom = 1.6 + FRAME_THICKNESS
	local boardCenterY = boardBottom + BOARD_HEIGHT / 2

	-- Taş çerçeve (panonun önüne taşar) ve arkadaki destek bloğu
	put("BoardFrameBottom", Vector3.new(BOARD_WIDTH + FRAME_THICKNESS * 2, FRAME_THICKNESS, 1), 0, 1.6 + FRAME_THICKNESS / 2, -0.1, STONE[3], nil, true)
	put("BoardFrameTop", Vector3.new(BOARD_WIDTH + FRAME_THICKNESS * 2, FRAME_THICKNESS, 1), 0, boardBottom + BOARD_HEIGHT + FRAME_THICKNESS / 2, -0.1, STONE[3], nil, true)
	for _, side in { -1, 1 } do
		put("BoardFrameSide", Vector3.new(FRAME_THICKNESS, BOARD_HEIGHT, 1), side * (BOARD_WIDTH / 2 + FRAME_THICKNESS / 2), boardCenterY, -0.1, STONE[3], nil, true)
	end
	put("BoardBrace", Vector3.new(BOARD_WIDTH - 0.6, BOARD_HEIGHT + 0.4, 1.4), 0, boardCenterY, 1, STONE_DARK, nil, false)

	-- Pano yüzü
	local part = put(`Board_{board.statName}`, Vector3.new(BOARD_WIDTH, BOARD_HEIGHT, 0.4), 0, boardCenterY, 0.1, Color3.fromRGB(24, 26, 42), Enum.Material.SmoothPlastic, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 57 -- pano küçük olduğu için yazı aynı netlikte kalsın diye yüksek
	gui.Parent = part

	local rows = {}
	local rowHeight = 0.092
	for index = 1, ROWS do
		local y = 0.025 + (index - 1) * rowHeight
		local color = MEDAL_COLORS[index] or Color3.new(1, 1, 1)
		if index % 2 == 0 then
			local stripe = Instance.new("Frame")
			stripe.Position = UDim2.fromScale(0.02, y)
			stripe.Size = UDim2.fromScale(0.96, rowHeight)
			stripe.BackgroundColor3 = Color3.new(1, 1, 1)
			stripe.BackgroundTransparency = 0.93
			stripe.BorderSizePixel = 0
			stripe.Parent = gui
		end
		local avatar = Instance.new("ImageLabel")
		avatar.AnchorPoint = Vector2.new(0, 0.5)
		avatar.Position = UDim2.new(0.18, 0, y + rowHeight / 2, 0)
		avatar.Size = UDim2.fromOffset(38, 38)
		avatar.BackgroundColor3 = Color3.fromRGB(60, 64, 88)
		avatar.Image = ""
		avatar.Visible = false
		avatar.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = avatar
		rows[index] = {
			rank = textLabel(gui, { Position = UDim2.fromScale(0.03, y + 0.006), Size = UDim2.fromScale(0.15, rowHeight - 0.012), Text = `#{index}`, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, 2),
			avatar = avatar,
			name = textLabel(gui, { Position = UDim2.fromScale(0.31, y + 0.006), Size = UDim2.fromScale(0.3, rowHeight - 0.012), Text = "-", TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left }, 2),
			value = textLabel(gui, { Position = UDim2.fromScale(0.58, y + 0.006), Size = UDim2.fromScale(0.3, rowHeight - 0.012), Text = "", TextColor3 = Color3.fromRGB(255, 235, 120), TextXAlignment = Enum.TextXAlignment.Right }, 2),
		}
		iconLabel(gui, board, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.94, 0, y + rowHeight / 2, 0), Size = UDim2.fromOffset(28, 28) })
	end
	local footer = textLabel(gui, { Position = UDim2.fromScale(0, 0.952), Size = UDim2.fromScale(1, 0.04), Text = "Updates every minute", TextColor3 = Color3.fromRGB(170, 175, 195) }, 1)

	-- Başlık şeridi: panonun çerçevesinin üstünde, renkli; üstünde havada duran simge
	local frameTop = boardBottom + BOARD_HEIGHT + FRAME_THICKNESS
	put("BoardTrim", Vector3.new(BOARD_WIDTH + FRAME_THICKNESS * 2 + 0.4, 0.3, 1.2), 0, frameTop + 0.15, 0, STONE_DARK, nil, false)
	local banner = put("BoardBanner", Vector3.new(BOARD_WIDTH + FRAME_THICKNESS * 2 + 0.4, 2.6, 0.7), 0, frameTop + 0.3 + 1.3, 0, board.color, Enum.Material.SmoothPlastic, false)
	local bannerGui = Instance.new("SurfaceGui")
	bannerGui.Face = Enum.NormalId.Front
	bannerGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	bannerGui.PixelsPerStud = 60
	bannerGui.Parent = banner
	textLabel(bannerGui, { Position = UDim2.fromScale(0.04, 0.06), Size = UDim2.fromScale(0.92, 0.58), Text = board.title, TextColor3 = Color3.new(1, 1, 1) }, 3)
	textLabel(bannerGui, { Position = UDim2.fromScale(0.15, 0.66), Size = UDim2.fromScale(0.7, 0.26), Text = board.subtitle or "LEADERBOARD", TextColor3 = Color3.fromRGB(255, 245, 215) }, 2)

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = banner
	billboard.Size = UDim2.fromScale(4.6, 4.6) -- ölçek = stud
	billboard.StudsOffset = Vector3.new(0, 3.9, 0)
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 160
	billboard.Parent = banner
	iconLabel(billboard, board, { Size = UDim2.fromScale(1, 1) })

	return rows, footer
end

function Leaderboards.init()
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = workspace

	-- Sol arka köşe (skin rafından sonra boş bırakılan yer): stand duvardan açık durur ve lobinin ortasına doğru döner
	local lobby = Config.Lobby
	local frame = CFrame.new(lobby.LeaderboardX, 0, lobby.LeaderboardZ) * CFrame.Angles(0, -math.pi / 2 + math.rad(lobby.LeaderboardAngle), 0)

	local boards = {}
	for index, board in BOARDS do
		local localX = (index - (#BOARDS + 1) / 2) * BOARD_PITCH
		local rows, footer = buildBoard(folder, frame, board, localX)
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, board.store)
		table.insert(boards, { def = board, rows = rows, footer = footer, store = if ok then store else nil, lastWritten = {} })
	end
	-- Sütunlar: iki yanda ve panoların arasında
	local half = (#BOARDS - 1) / 2 * BOARD_PITCH
	pillar(folder, frame, -(half + BOARD_WIDTH / 2 + 1.9), 6, 2, 0)
	pillar(folder, frame, half + BOARD_WIDTH / 2 + 1.9, 6, 2, 1)
	for index = 1, #BOARDS - 1 do
		pillar(folder, frame, (index - (#BOARDS) / 2) * BOARD_PITCH, 5, 1.6, index + 1)
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
			local value = boardValue(player, board.def)
			if value and PlayerStats.canSave(player) then
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
				local userId = tonumber(entry.key) or 0
				row.name.Text = nameOf(userId)
				row.value.Text = Format.compact(entry.value)
				row.avatar.Image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=60&h=60`
				row.avatar.Visible = true
			else
				row.name.Text = "-"
				row.value.Text = ""
				row.avatar.Image = ""
				row.avatar.Visible = false
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
				local value = boardValue(player, board.def)
				if value then
					task.spawn(pcall, board.store.SetAsync, board.store, tostring(player.UserId), value)
				end
			end
		end
	end)
end

return Leaderboards
