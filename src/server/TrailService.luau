-- İz (trail) efektleri: takılı izi karakterin arkasında çizer ve yürüme hızını ayarlar.
-- Sunucuda yapılır, bu yüzden tüm oyuncular izi görür ve yürüme hızı sunucu tarafından belirlenir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local TrailService = {}

local EFFECT_NAME = "TrailEffect"

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 220, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(120, 80, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
})

-- İz, karakterin sırtından (gövdenin arka yüzünden) çıkar. İki bağlantı noktası gövdenin arkasında,
-- gövde boyunun yaklaşık yarısı kadar aralıkla durur; bu yüzden iz küçük ve sırta yapışık kalır.
local function buildTrail(character, trail)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	if not torso then
		return
	end
	local back = torso.Size.Z / 2 + 0.05 -- karakter -Z'ye bakar, sırt +Z tarafındadır
	local halfSpan = torso.Size.Y * 0.28

	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, halfSpan, back)
	top.Parent = torso

	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -halfSpan, back)
	bottom.Parent = torso

	local effect = Instance.new("Trail")
	effect.Name = EFFECT_NAME
	effect.Attachment0 = top
	effect.Attachment1 = bottom
	effect.Color = if trail.rainbow then RAINBOW else ColorSequence.new(trail.color)
	effect.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	effect.Lifetime = 0.45
	effect.LightEmission = 0.6
	effect.FaceCamera = true
	effect.MinLength = 0.1
	effect.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	effect.Parent = torso
end

local function clear(character)
	for _, descendant in character:GetDescendants() do
		if descendant.Name == EFFECT_NAME or descendant.Name == "TrailTop" or descendant.Name == "TrailBottom" then
			descendant:Destroy()
		end
	end
end

-- Takılı ize göre yürüme hızını ve iz efektini ayarlar
local function apply(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end

	local trail = Catalog.TrailById[player:GetAttribute("EquippedTrail") or ""]
	humanoid.WalkSpeed = Config.BaseWalkSpeed + (if trail then trail.speed else 0)

	clear(character)
	if trail then
		buildTrail(character, trail)
	end
end

local function watch(player)
	local function onCharacter(character)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Humanoid", 10)
		apply(player)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- İz takılınca/çıkarılınca ve kayıtlı veri yüklenince güncelle
	player:GetAttributeChangedSignal("EquippedTrail"):Connect(function()
		apply(player)
	end)

	-- Karakter büyüyünce (level) iz bağlantı noktaları yeni boyuta uysun
	local leaderstats = player:WaitForChild("leaderstats")
	local level = leaderstats:WaitForChild(Config.StatLevel)
	level:GetPropertyChangedSignal("Value"):Connect(function()
		task.delay(0.4, apply, player)
	end)
end

function TrailService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

return TrailService
