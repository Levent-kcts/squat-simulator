-- Antrenman alanının oyuncuya özel görünümü: pedlerin üstündeki etiketler (çarpan + kilit/durum) ve kilitli pedlerin sönük rengi.
-- Burada yapılan renk/etiket değişiklikleri sadece bu oyuncunun ekranında görünür; asıl kilit ve çarpan sunucuda (server/TrainingArea).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShelfClient = require(script.Parent.ShelfClient)

local TrainingClient = {}

local GREEN = Color3.fromRGB(60, 255, 100)
local YELLOW = Color3.fromRGB(255, 235, 40)
local PINK = Color3.fromRGB(255, 110, 150)
local LOCKED_DARKNESS = 0.6 -- kilitli ped bu oranda karartılır

-- Başlık rengi: koyu pedlerde (Black Zone) siyah kenarlıkla bile okunsun diye beyaza doğru açılır
local function titleColor(color)
	local brightest = math.max(color.R, color.G, color.B)
	return color:Lerp(Color3.new(1, 1, 1), if brightest < 0.5 then 0.75 else 0.15)
end

function TrainingClient.init()
	local player = Players.LocalPlayer
	local folder = Workspace:WaitForChild("TrainingArea")

	-- Alanın hangi basamakta olduğu (Config.Training.RowCounts sırasıyla): üst basamaklarda antrenör büyüdüğü için etiket de yükselir
	local rowOf = {}
	local counted = 0
	for row, count in Config.Training.RowCounts do
		for _ = 1, count do
			counted += 1
			rowOf[counted] = row
		end
	end

	local entries = {}
	for index, area in Config.Training.Areas do
		local pad = folder:WaitForChild(`Pad_{area.id}`)
		local trainerScale = Config.Training.TrainerScales[rowOf[index]]
		local trainerHeight = 5.3 * trainerScale
		local labelScale = trainerScale / Config.Training.TrainerScales[1] -- üst basamaklarda antrenör büyüdükçe etiket de büyür (alt basamak = 1)

		-- Antrenörün üstünde üç satır: antrenör ismi, çarpan ve durum
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(9 * labelScale, 4.4 * labelScale)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 0.3 + trainerHeight + 0.4 + 2.2 * labelScale, 0) -- ped yarım kalınlığı + antrenör boyu + boşluk + etiket yarı boyu
		gui.MaxDistance = 110
		gui.Adornee = pad
		gui.Parent = pad

		local name = ShelfClient.makeLabel(gui, 0, 0.27, Color3.new(1, 1, 1))
		name.Text = area.trainer
		local title = ShelfClient.makeLabel(gui, 0.27, 0.4, titleColor(area.color))
		title.Text = `x{ShelfClient.fmtMultiplier(area.mult)} Squat`
		local info = ShelfClient.makeLabel(gui, 0.67, 0.33, YELLOW)

		table.insert(entries, { area = area, pad = pad, info = info })
	end

	local rainbowHue = 0

	local function paintPad(entry, unlocked)
		local area = entry.area
		local color = area.color
		if area.rainbow then
			color = Color3.fromHSV(rainbowHue, 0.85, 1)
		end
		entry.pad.Color = if unlocked then color else color:Lerp(Color3.new(0, 0, 0), LOCKED_DARKNESS)
	end

	local unlockedNow = {}

	local function refresh()
		unlockedNow = {}
		for id in string.gmatch(player:GetAttribute("UnlockedAreas") or "", "[^,]+") do
			unlockedNow[id] = true
		end
		local trainingIn = player:GetAttribute("TrainingArea") or ""

		for _, entry in entries do
			local area = entry.area
			local unlocked = unlockedNow[area.id] == true
			paintPad(entry, unlocked)

			if trainingIn == area.id then
				entry.info.Text = "Training..."
				entry.info.TextColor3 = YELLOW
			elseif unlocked then
				entry.info.Text = if (area.rebirths or 0) == 0 then "FREE" else "Unlocked"
				entry.info.TextColor3 = GREEN
			else
				entry.info.Text = `Rebirth {area.rebirths}`
				entry.info.TextColor3 = PINK
			end
		end
	end

	player:GetAttributeChangedSignal("UnlockedAreas"):Connect(refresh)
	player:GetAttributeChangedSignal("TrainingArea"):Connect(refresh)
	refresh()

	-- Rainbow Zone'un rengi yavaşça döner (sadece bu oyuncunun ekranında)
	RunService.RenderStepped:Connect(function(deltaTime)
		rainbowHue = (rainbowHue + deltaTime * 0.15) % 1
		for _, entry in entries do
			if entry.area.rainbow then
				paintPad(entry, unlockedNow[entry.area.id] == true)
			end
		end
	end)
end

return TrainingClient
