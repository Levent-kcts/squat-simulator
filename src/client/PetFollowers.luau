-- Takılı petleri oyuncunun arkasında süzülen küreler olarak gösterir (sadece bu oyuncuya görünür).
-- Boy arttıkça küre büyür (Small < Normal < Big); BOSS (en büyük boy) Big ile aynı boydadır ama üstünde parlayan bir efekt vardır:
-- altın/pembe parıltı parçacıkları, nabız gibi atan saydam kabuk ve ince bir dış çizgi.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))

local PetFollowers = {}

local BOSS_GOLD = Color3.fromRGB(255, 215, 90)
local BOSS_PINK = Color3.fromRGB(255, 90, 170)

-- Boss efekti: parçacıklar + saydam kabuk (kabuk kürenin konumunu her karede izler). Dönüş: kabuk (ya da nil)
local function addBossEffect(part, pet)
	local shell = Instance.new("Part")
	shell.Name = "BossShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = part.Size * 1.3
	shell.Material = Enum.Material.Neon
	shell.Color = pet.color:Lerp(BOSS_GOLD, 0.6)
	shell.Transparency = 0.75
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.Parent = Workspace

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(BOSS_GOLD, BOSS_PINK)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Lifetime = NumberRange.new(0.8, 1.5)
	sparkles.Rate = 16
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = part

	-- İnce dış çizgi (Highlight desteklenmeyen yerde sessizce atlanır)
	pcall(function()
		local outline = Instance.new("Highlight")
		outline.Adornee = part
		outline.FillTransparency = 1
		outline.OutlineColor = BOSS_GOLD
		outline.OutlineTransparency = 0.2
		outline.Parent = part
	end)
	return shell
end

function PetFollowers.init()
	local player = Players.LocalPlayer
	local parts = {} -- { part = küre, shell = Boss kabuğu (varsa), baseSize = küre boyu }

	local function rebuild()
		for _, entry in parts do
			entry.part:Destroy()
			if entry.shell then
				entry.shell:Destroy()
			end
		end
		table.clear(parts)

		local equipped = player:GetAttribute("EquippedPets") or ""
		for id in string.gmatch(equipped, "[^,]+") do
			local pet = Catalog.PetById[id]
			if pet then
				local part = Instance.new("Part")
				part.Name = pet.label
				part.Shape = Enum.PartType.Ball
				part.Size = Vector3.new(1.8, 1.8, 1.8) * pet.scale -- birleştirilmiş petler büyüktür (Config.PetFusion.Scale)
				part.Material = Enum.Material.Neon
				part.Color = pet.color
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Parent = Workspace
				local entry = { part = part, baseSize = part.Size }
				if Catalog.isBoss(pet) then
					local ok, shell = pcall(addBossEffect, part, pet)
					if ok then
						entry.shell = shell
					else
						warn(`[PetFollowers] Boss efekti kurulamadı: {shell}`)
					end
				end
				table.insert(parts, entry)
			end
		end
	end

	player:GetAttributeChangedSignal("EquippedPets"):Connect(rebuild)
	rebuild()

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local now = os.clock()
		local count = #parts
		for i, entry in parts do
			local side = (i - (count + 1) / 2) * 4.6
			local bob = math.sin(now * 3 + i) * 0.4
			local target = root.CFrame * CFrame.new(side, 0.5 + bob, 4)
			local part = entry.part
			part.CFrame = part.CFrame:Lerp(target, 0.15)
			local shell = entry.shell
			if shell then
				-- Kabuk nabız gibi atar: boyu ve saydamlığı yavaşça değişir
				local pulse = (math.sin(now * 4 + i) + 1) / 2
				shell.Size = entry.baseSize * (1.25 + 0.15 * pulse)
				shell.Transparency = 0.7 + 0.15 * pulse
				shell.CFrame = part.CFrame
			end
		end
	end)
end

return PetFollowers
