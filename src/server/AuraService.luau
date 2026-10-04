-- Aura efektleri: takılı aura karakterin etrafında renkli parıltı (parçacık + ışık) olarak görünür.
-- Sunucuda yapılır, bu yüzden tüm oyuncular auraları görür. Aura çarpanı PlayerStats'ta uygulanır.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local AuraService = {}

local EFFECT_NAMES = { "AuraEffect", "AuraLight" }

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 220, 90)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(120, 80, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
})

local function clear(character)
	for _, descendant in character:GetDescendants() do
		if table.find(EFFECT_NAMES, descendant.Name) then
			descendant:Destroy()
		end
	end
end

local function build(character, aura)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- Karakter büyüdükçe parçacıklar da büyüsün (kök parça ölçekle birlikte büyür)
	local scale = root.Size.Y / 2

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AuraEffect"
	emitter.Color = if aura.rainbow then RAINBOW else ColorSequence.new(aura.color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 28
	emitter.Speed = NumberRange.new(1 * scale, 3 * scale)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Parent = root

	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = if aura.rainbow then Color3.fromRGB(255, 255, 255) else aura.color
	light.Range = 12 * scale
	light.Brightness = 0.8
	light.Shadows = false
	light.Parent = root
end

local function apply(player)
	local character = player.Character
	if not character then
		return
	end
	clear(character)
	local aura = Catalog.AuraById[player:GetAttribute("EquippedAura") or ""]
	if aura then
		build(character, aura)
	end
end

local function watch(player)
	local function onCharacter(character)
		character:WaitForChild("HumanoidRootPart", 10)
		apply(player)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	player:GetAttributeChangedSignal("EquippedAura"):Connect(function()
		apply(player)
	end)

	-- Karakter büyüyünce (level) parçacık boyutları yeni ölçüye uysun
	local leaderstats = player:WaitForChild("leaderstats")
	leaderstats:WaitForChild(Config.StatLevel):GetPropertyChangedSignal("Value"):Connect(function()
		task.delay(0.4, apply, player)
	end)
end

function AuraService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

return AuraService
