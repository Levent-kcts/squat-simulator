-- Yeni oyuncular için yol gösterici çizgi: karakterden hedefe giden parlak bir şerit.
--   * İlk duvarlar sağlamken: sıradaki duvarın önündeki noktaya (duvara yaklaşınca kaybolur)
--   * Aşama bitince: o aşamanın sarı Win pedine (pedi geçince ya da sonraki duvara yaklaşınca kaybolur)
-- Sadece ilk aşamalarda (Config.Guide.MaxStage) ve hiç rebirth yapmamış oyuncuya gösterilir. Tamamen görsel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))

local Guide = {}

local cfg = Config.Wall
local UPDATE_INTERVAL = 0.15
local LINE_COLOR = Color3.fromRGB(255, 235, 90)

-- wallClient: WallClient modülü (getFrontier ve isNearWall için)
function Guide.init(wallClient)
	local player = Players.LocalPlayer
	local rebirths = player:WaitForChild("leaderstats"):WaitForChild(Config.StatRebirths)
	local maxStage = (Config.Guide and Config.Guide.MaxStage) or 3

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

	-- Hedefi belirle: dönüş (konum) ya da nil (çizgi gizli)
	local function pickTarget(position)
		local frontier = wallClient.getFrontier()
		if frontier > cfg.Count then
			return nil
		end
		if Layout.stageOf(frontier) > maxStage then
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
		if not root or not startAttachment or rebirths.Value > 0 or training then
			beam.Enabled = false
			return
		end

		local goal = pickTarget(root.Position)
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
