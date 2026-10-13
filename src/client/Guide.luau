-- Yeni oyuncular için yol gösterici çizgi: karakterden GÜNCEL HEDEFE (client/Objective; üst şerit ve rehber kartlarıyla aynı hedef, çakışmasınlar diye) giden parlak bir şerit.
--   * Hedef 'ilk pet': ilk yumurtanın pedine (Config.Eggs[1]; pedin yanına gelince kaybolur)
--   * Hedef 'ilk skin': skin rafındaki ilk skinin (Config.Skins[1]) pedine
--   * Hedef 'duvar' (Win kazanmak ya da 3 duvar görevi): sıradaki duvarın önündeki noktaya (duvara yaklaşınca kaybolur); aşama bitince o aşamanın sarı Win pedine
--   * Diğer hedeflerde (squat sayma, ayakkabı, level...) çizgi yok.
-- Sadece Guide açıkken ve ilk rebirth'e kadar gösterilir. Tamamen görsel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Objective = require(script.Parent.Objective)

local Guide = {}

local cfg = Config.Wall
local UPDATE_INTERVAL = 0.15
local LINE_COLOR = Color3.fromRGB(255, 235, 90)

-- wallClient: WallClient modülü (getFrontier ve isNearWall için)
function Guide.init(wallClient)
	local player = Players.LocalPlayer
	local leaderstats = player:WaitForChild("leaderstats")
	local wins = leaderstats:WaitForChild(Config.StatWins)
	local levelValue = leaderstats:WaitForChild(Config.StatLevel)
	local rebirthValue = leaderstats:WaitForChild(Config.StatRebirths)
	local firstSkin = Config.Skins[1]

	-- İlk skinin rafındaki ped (sunucu pedi SkinShop klasöründe, 'ItemId' özniteliğiyle kurar); bulunana kadar nil
	local skinPad = nil
	local function findSkinPad()
		if skinPad and skinPad.Parent then
			return skinPad
		end
		local folder = Workspace:FindFirstChild("SkinShop")
		if folder then
			for _, descendant in folder:GetDescendants() do
				if descendant:IsA("BasePart") and descendant:GetAttribute("ItemId") == firstSkin.id then
					skinPad = descendant
					return skinPad
				end
			end
		end
		return nil
	end

	-- İlk yumurtanın pedi (EggShop klasöründe 'Pad_<yumurta id>'); bulunana kadar nil
	local starterEgg = Config.Eggs[1]
	local eggPad = nil
	local function findEggPad()
		if eggPad and eggPad.Parent then
			return eggPad
		end
		local folder = Workspace:FindFirstChild("EggShop")
		eggPad = folder and folder:FindFirstChild(`Pad_{starterEgg.id}`) or nil
		return eggPad
	end

	-- Hedef noktası: görünmez, sabit bir parça; çizginin ucu buna bağlanır
	local target = Instance.new("Part")
	target.Name = "GuideTarget"
	target.Anchored = true
	target.CanCollide = false
	target.CanQuery = false
	target.CanTouch = false
	target.Transparency = 1
	target.Size = Vector3.one
	target.Parent = Workspace
	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Parent = target

	local beam = Instance.new("Beam")
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(LINE_COLOR)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Transparency = NumberSequence.new(0.3)
	beam.Width0 = 0.7
	beam.Width1 = 0.7
	beam.Enabled = false
	beam.Parent = target

	local startAttachment = nil
	local function bindCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		if startAttachment then
			startAttachment:Destroy()
		end
		startAttachment = Instance.new("Attachment")
		startAttachment.Name = "GuideStart"
		startAttachment.Position = Vector3.new(0, -2.5, 0) -- ayak hizası
		startAttachment.Parent = root
		beam.Attachment0 = startAttachment
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(bindCharacter, character)
	end)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end

	-- Hedefi belirle: dönüş (konum) ya da nil (çizgi gizli). Hedef türü güncel hedeften (Objective.id) gelir
	local function pickTarget(position, objectiveId)
		if objectiveId == "pet" then
			-- İlk yumurtanın pedine (ilk pet 1. dakikada; retention)
			local pad = findEggPad()
			if pad and (pad.Position - position).Magnitude > 8 then
				return pad.Position + Vector3.new(0, 1.2, 0)
			end
			return nil
		elseif objectiveId == "skin" then
			-- Skin rafındaki ilk pede
			local pad = findSkinPad()
			if pad and (pad.Position - position).Magnitude > 7 then
				return pad.Position + Vector3.new(0, 1.2, 0)
			end
			return nil
		elseif objectiveId ~= "wall" then
			return nil
		end
		local frontier = wallClient.getFrontier()
		if frontier > cfg.Count then
			return nil
		end
		-- Duvara zaten yakınsa çizgiye gerek yok (tıklama zamanı)
		if wallClient.isNearWall(position) then
			return nil
		end
		local broken = frontier - 1
		if broken > 0 and broken % cfg.GroupSize == 0 then
			-- Aşama tamam: Win pedi henüz geçilmediyse oraya yönlendir
			local stage = broken // cfg.GroupSize
			local padZ = Layout.padZ(stage)
			if position.Z > padZ + 2 then
				return Vector3.new(Layout.padX(), Layout.FloorTop + 0.6, padZ)
			end
		end
		-- Aksi halde sıradaki duvarın önündeki nokta
		return Vector3.new(0, Layout.FloorTop + 0.6, Layout.wallZ(frontier) + cfg.Thickness / 2 + cfg.HitRange * 0.5)
	end

	local elapsed = 0
	game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < UPDATE_INTERVAL then
			return
		end
		elapsed = 0

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local training = (player:GetAttribute("TrainingArea") or "") ~= ""
		-- Settings'teki 'Guide' anahtarı (GuideOn = false) kapalıysa yol gösterici çizgi de kapalıdır; ilk rebirth'ten sonra yok
		local guiding = player:GetAttribute("DataLoaded") == true and player:GetAttribute("GuideOn") ~= false and rebirthValue.Value == 0
		if not root or not startAttachment or not guiding or training then
			beam.Enabled = false
			return
		end
		-- Üst şeritle aynı hedef (sunucuda 'TutorialDone' kapanmış olsa bile 3 duvar görevi sürerken çizgi duvara gider)
		local objective = Objective.read(player, { wins = wins.Value, level = levelValue.Value, maxLevel = player:GetAttribute("MaxLevel"), rebirths = rebirthValue.Value, wallText = "" })
		local goal = objective and pickTarget(root.Position, objective.id)
		if not goal then
			beam.Enabled = false
			return
		end
		target.Position = goal
		beam.Enabled = true
		-- Hafif nabız: çizgi kalınlığı nefes alır gibi değişir
		local width = 0.55 + 0.25 * math.sin(os.clock() * 5)
		beam.Width0 = width
		beam.Width1 = width
	end)
end

return Guide
