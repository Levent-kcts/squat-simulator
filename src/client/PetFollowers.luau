-- Takılı petleri oyuncunun arkasında süzülen modeller olarak gösterir (sadece bu oyuncuya görünür). Blender modeli (kutu pet, shared/ModelLibrary 'pet_<id>') varsa o, yoksa renkli küre.
-- Boy arttıkça küre büyür (Small < Normal < Big); BOSS (en büyük boy) Big ile aynı boydadır ama üstünde parlayan bir efekt vardır:
-- altın/pembe parıltı parçacıkları ve ince bir dış çizgi. Nabız gibi atan SAYDAM KABUK (hale) sahibi 'çok kötü duruyor, kapat' dediği için KAPALI (Config.PetFusion.BossShell = false).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Config = require(Shared:WaitForChild("Config"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))

local PetFollowers = {}

local BOSS_GOLD = Color3.fromRGB(255, 215, 90)
local BOSS_PINK = Color3.fromRGB(255, 90, 170)

-- Boss efekti: parçacıklar + ince dış çizgi (+ isteğe bağlı saydam kabuk: kabuk kürenin konumunu her karede izler). Dönüş: kabuk (ya da nil)
local function addBossEffect(part, pet)
	local shell = nil
	if Config.PetFusion.BossShell then
		shell = Instance.new("Part")
		shell.Name = "BossShell"
		shell.Shape = Enum.PartType.Ball
		local diameter = math.max(part.Size.X, part.Size.Y, part.Size.Z) * 1.1
		shell.Size = Vector3.new(diameter, diameter, diameter) -- top şekli her zaman eşit boyutludur
		shell.Material = Enum.Material.Neon
		shell.Color = pet.color:Lerp(BOSS_GOLD, 0.6)
		shell.Transparency = 0.75
		shell.Anchored = true
		shell.CanCollide = false
		shell.CanTouch = false
		shell.CanQuery = false
		shell.Parent = Workspace
	end

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
				-- Blender kutu modeli varsa o (boyu pet.scale ile büyür), yoksa eski küre
				local part, offset = ModelLibrary.create("pet_" .. pet.baseId, Config.Models.PetScale * pet.scale)
				if part then
					part.Name = pet.label
				else
					part = Instance.new("Part")
					part.Name = pet.label
					part.Shape = Enum.PartType.Ball
					part.Size = Vector3.new(1.8, 1.8, 1.8) * pet.scale -- birleştirilmiş petler büyüktür (Config.PetFusion.Scale)
					part.Material = Enum.Material.Neon
					part.Color = pet.color
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					offset = nil
				end
				part.Parent = Workspace
				local diameter = math.max(part.Size.X, part.Size.Y, part.Size.Z) * (if offset then 0.85 else 1)
				local entry = { part = part, baseSize = Vector3.new(diameter, diameter, diameter), offset = offset }
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
			local target
			if entry.offset then
				-- Model: orijini tabanın ortasıdır; zeminin biraz üstünde süzülür, kutu merkezine göre yerleşir
				target = ModelLibrary.cframe(root.CFrame * CFrame.new(side, Config.Models.PetHover + bob, 4), entry.offset)
			else
				target = root.CFrame * CFrame.new(side, 0.5 + bob, 4)
			end
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
