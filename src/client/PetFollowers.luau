-- Takılı petleri oyuncunun arkasında süzülen küreler olarak gösterir (sadece bu oyuncuya görünür).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Catalog"))

local PetFollowers = {}

function PetFollowers.init()
	local player = Players.LocalPlayer
	local parts = {}

	local function rebuild()
		for _, part in parts do
			part:Destroy()
		end
		table.clear(parts)

		local equipped = player:GetAttribute("EquippedPets") or ""
		for id in string.gmatch(equipped, "[^,]+") do
			local pet = Catalog.PetById[id]
			if pet then
				local part = Instance.new("Part")
				part.Name = pet.name
				part.Shape = Enum.PartType.Ball
				part.Size = Vector3.new(1.8, 1.8, 1.8) * pet.scale -- birleştirilmiş petler büyüktür (Config.PetFusion.Scale)
				part.Material = Enum.Material.Neon
				part.Color = pet.color
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Parent = Workspace
				table.insert(parts, part)
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

		local count = #parts
		for i, part in parts do
			local side = (i - (count + 1) / 2) * 4.6
			local bob = math.sin(os.clock() * 3 + i) * 0.4
			local target = root.CFrame * CFrame.new(side, 0.5 + bob, 4)
			part.CFrame = part.CFrame:Lerp(target, 0.15)
		end
	end)
end

return PetFollowers
