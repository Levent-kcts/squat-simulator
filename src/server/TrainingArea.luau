-- Lobinin SAĞ duvarındaki antrenman alanı: ayakkabı/skin rafıyla aynı stand (server/Shelf) ama büyük pedlerle, 3 basamakta 4 + 3 + 3 = 10 ped.
-- Her pedin kendi çarpanı (Config.Training.Areas) ve kilidi vardır; pedin üstünde bir antrenör yer tutucusu durur (sonra özel
-- antrenörler gelecek). Oyuncu pede girince sunucu doğrular: açıksa karakter otomatik squat yapar (istemci TrainingArea
-- özniteliğini görünce kendiliğinden tıklar, kazanç pedin çarpanıyla çarpılır); pedler sadece rebirth sayısıyla açılır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)
local Shelf = require(script.Parent.Shelf)
local Mannequin = require(script.Parent.Mannequin)

local TrainingArea = {}

-- Büyük pedler: referans oyundaki gibi geniş, düz, renkli kareler; her biri bir karakterin rahatça durabileceği büyüklükte
local LAYOUT = {
	rowCounts = Config.Training.RowCounts, -- 4 + 3 + 3 ped
	rowPadSizes = Config.Training.RowPadSizes, -- üst şeritlerde ped büyür
	laneDepths = Config.Training.RowDepths,
	rowLength = Config.Training.RowLength,
	padHeight = 0.6,
	rampWidth = 9, -- uç rampaları (merdivenler): 6'dan 9'a büyüdü; sahibi 'merdivenleri biraz büyütüp en sola (giriş duvarına) yanaştır' dedi. Config.Lobby.TrainingShelfZ ile birlikte ayarlanır: ön rampa giriş duvarına (z -63) tam değer
	signSize = Vector3.new(64, 9, 0.5),
	signY = 29, -- üst sıradaki büyük antrenörlerin (2.1 ölçek, ~11 stud) ve etiketlerin üstünde
	displayLift = 0, -- antrenör doğrudan pedin üstünde durur
	padMaterial = Enum.Material.SmoothPlastic,
	frameColor = Color3.fromRGB(25, 25, 32),
}
local CHECK_INTERVAL = 0.2 -- oyuncunun hangi pedde durduğu bu aralıkla kontrol edilir (saniye)
local EXIT_GRACE = 1.2 -- pedden kısa süre çıkmış görünmek (level atlayınca karakter büyür, kök parça bir an kayar) otomatik squat'ı kesmez: bu kadar süre beklenir

local active = {} -- [oyuncu] = alan: içinde durduğu ve AÇIK olan alan (otomatik squat)
local standing = {} -- [oyuncu] = alan: içinde durduğu alan (kilitli de olabilir)
local lastUsable = {} -- [oyuncu] = pedde son kez açık alan olarak görüldüğü an (os.clock)

-- Oyuncunun şu an antrenman yaptığı alan (yoksa nil). Tıklama işleyicisi çarpanı buradan alır.
function TrainingArea.getArea(player)
	return active[player]
end

local function setActive(player, area)
	active[player] = area
	player:SetAttribute("TrainingArea", if area then area.id else "")
	player:SetAttribute("AreaMultiplier", if area then area.mult else 1)
end

function TrainingArea.init(notifyEvent)
	local _, pads = Shelf.build({
		name = "TrainingArea",
		frame = Shelf.rightWallFrame(Config.Lobby.TrainingShelfZ),
		title = "TRAINING AREA",
		signColor = Color3.fromRGB(60, 90, 220),
		items = Config.Training.Areas,
		layout = LAYOUT,
		padColor = function(area)
			return area.color
		end,
		buildDisplay = function(parent, area, frame, center, slot)
			Mannequin.build(parent, `Trainer_{area.id}`, frame, center, Config.Training.TrainerScales[slot.row], area.color, nil, area.outfit)
		end,
	})

	local zones = {}
	for _, area in Config.Training.Areas do
		table.insert(zones, { area = area, pad = pads[area.id] })
	end

	-- Pedin üstünde mi? (pedin kendi eksenlerinde bakılır, ped dönük olsa da çalışır)
	local function areaUnder(position)
		for _, zone in zones do
			local relative = zone.pad.CFrame:PointToObjectSpace(position)
			local half = zone.pad.Size / 2
			if math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and relative.Y > -2 and relative.Y < 30 then
				return zone.area
			end
		end
		return nil
	end

	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
		standing[player] = nil
		lastUsable[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(CHECK_INTERVAL)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local area = nil
				if root and humanoid and humanoid.Health > 0 then
					area = areaUnder(root.Position)
				end

				-- Yeni bir pede girildi: kilitliyse satın alma denenir ya da neden kilitli olduğu söylenir
				if area ~= standing[player] then
					standing[player] = area
					if area and not PlayerStats.isAreaUnlocked(player, area) then
						notifyEvent:FireClient(player, false, `{area.trainer} unlocks at {area.rebirths} Rebirths.`)
					end
				end

				local usable = nil
				if area and PlayerStats.isAreaUnlocked(player, area) then
					usable = area
					lastUsable[player] = os.clock()
				elseif active[player] and os.clock() - (lastUsable[player] or 0) < EXIT_GRACE then
					usable = active[player] -- kısa süreli kayma: aktif alan korunur
				end
				if usable ~= active[player] then
					setActive(player, usable)
				end
			end
		end
	end)
end

return TrainingArea
