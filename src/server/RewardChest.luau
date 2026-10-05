-- Lobideki "FREE REWARD" sandığı (Gifts / Playtime Rewards ödüllerine bağlı). Burada sadece duran 3B sandık kurulur;
-- süre sayacı, kapağın açılması, parıltı ve ödülü alma oyuncuya özeldir ve istemcide yapılır (client/RewardChest).
-- Ödülün kendisini yine sunucu verir (PlayerStats.claimGift: süre ve tekrar kontrolü sunucuda).
-- Sandık blokludur (lego görünümü); kapak parçaları "LidPart" özniteliğiyle işaretlenir, menteşe "Hinge" parçasıdır.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Layout = require(Shared:WaitForChild("Layout"))
local Build = require(script.Parent.Build)

local RewardChest = {}

local WOOD = Color3.fromRGB(205, 122, 62)
local WOOD_LIGHT = Color3.fromRGB(228, 146, 78)
local GOLD = Color3.fromRGB(255, 208, 70)
local BASE = Color3.fromRGB(255, 226, 130)

function RewardChest.init()
	local folder = Instance.new("Folder")
	folder.Name = "RewardChest"
	folder.Parent = Workspace

	local cx, cz = Config.Lobby.RewardChest.X, Config.Lobby.RewardChest.Y
	local floorTop = Layout.FloorTop
	local baseTop = floorTop + 0.8
	local bodyTop = baseTop + 3

	local function part(name, size, position, color, material, lid)
		local p = Build.block(folder, name, size, position, color, material or Enum.Material.SmoothPlastic, false)
		p.CanCollide = not lid
		if lid then
			p:SetAttribute("LidPart", true)
		end
		return p
	end

	-- Taban: geniş sarı plaka (lego çıkıntılı) ve üstünde ince parlak çerçeve (hazır olunca istemci yakar)
	local base = Build.block(folder, "Base", Vector3.new(11, 0.8, 11), Vector3.new(cx, floorTop + 0.4, cz), BASE, Enum.Material.Plastic, true)
	base.CanCollide = true
	local ring = part("Ring", Vector3.new(9.4, 0.15, 9.4), Vector3.new(cx, baseTop + 0.07, cz), GOLD, Enum.Material.SmoothPlastic)
	ring.CanCollide = false

	-- Gövde ve altın şeritler
	part("Body", Vector3.new(6.6, 3, 4.6), Vector3.new(cx, baseTop + 1.5, cz), WOOD, Enum.Material.Plastic)
	part("BodyTrim", Vector3.new(6.9, 0.5, 4.9), Vector3.new(cx, baseTop + 0.25, cz), GOLD)
	for _, side in { -1, 1 } do
		part("BodyStrap", Vector3.new(0.8, 3.05, 4.85), Vector3.new(cx + side * 2.3, baseTop + 1.5, cz), GOLD)
	end
	part("Lock", Vector3.new(1.4, 1.9, 0.5), Vector3.new(cx, bodyTop - 0.5, cz - 2.4), GOLD)

	-- Kapak (istemci menteşeden döndürür): kapak + altın şeritler
	part("Lid", Vector3.new(6.9, 1.7, 4.9), Vector3.new(cx, bodyTop + 0.85, cz), WOOD_LIGHT, Enum.Material.Plastic, true)
	for _, side in { -1, 1 } do
		part("LidStrap", Vector3.new(0.9, 1.8, 5.05), Vector3.new(cx + side * 2.3, bodyTop + 0.85, cz), GOLD, nil, true)
	end

	-- Menteşe: kapağın arka üst kenarı (sandık lobinin ortasına, yani -Z tarafına bakar; kapak ön kenardan yukarı kalkar)
	local hinge = Build.block(folder, "Hinge", Vector3.new(0.2, 0.2, 0.2), Vector3.new(cx, bodyTop, cz + 2.45), GOLD, Enum.Material.SmoothPlastic, false)
	hinge.Transparency = 1
	hinge.CanCollide = false
	hinge.CanQuery = false

	-- Işık ve parıltı: istemci hazır olduğunda açar (burada kapalı)
	local glow = Build.block(folder, "Glow", Vector3.new(0.4, 0.4, 0.4), Vector3.new(cx, bodyTop + 1.4, cz), GOLD, Enum.Material.SmoothPlastic, false)
	glow.Transparency = 1
	glow.CanCollide = false
	glow.CanQuery = false

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 100)
	light.Range = 22
	light.Brightness = 2
	light.Enabled = false
	light.Parent = glow

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Rate = 26
	sparkles.Lifetime = NumberRange.new(1, 1.8)
	sparkles.Speed = NumberRange.new(3, 7)
	sparkles.SpreadAngle = Vector2.new(35, 35)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Acceleration = Vector3.new(0, 2, 0)
	sparkles.LightEmission = 0.7
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 190, 60))
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Enabled = false
	sparkles.Parent = glow
end

return RewardChest
