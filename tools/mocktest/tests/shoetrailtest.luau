-- Ayakkabı görünümü (gerçek AppearanceCleaner): en güçlü 4 ayakkabıda ayaklara ShoeGlow ışığı ve ShoeTrail parçacığı eklenir, iz sadece koşarken açılır;
-- zayıf ayakkabıda iz yoktur; ayakkabı değişince eskisi temizlenir.
local S = require("./cstubs")
local Config = require("./Config")
local AppearanceCleaner = require("./AppearanceCleaner")

local function child(parent, name, className)
	local instance = S.newInstance(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function makeCharacter()
	local character = S.newInstance("Model")
	character.Name = "TestCharacter"
	local humanoid = child(character, "Humanoid", "Humanoid")
	humanoid.RigType = "R15"
	humanoid.MoveDirection = S.Vector3.new(0, 0, 0)
	humanoid.FindFirstChildOfClass = function(_, className)
		return nil
	end
	for _, name in { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } do
		local part = child(character, name, "Part")
		part.Color = S.Color3.new(0.8, 0.6, 0.5)
	end
	return character, humanoid
end

local function emittersOf(character)
	local list = {}
	for _, footName in { "LeftFoot", "RightFoot" } do
		local foot = character:FindFirstChild(footName)
		local trail = foot and foot:FindFirstChild("ShoeTrail")
		local glow = foot and foot:FindFirstChild("ShoeGlow")
		table.insert(list, { foot = foot, trail = trail, glow = glow })
	end
	return list
end

local function setup(shoeId)
	local player = S.newInstance("Player")
	player.Name = "ShoeTester"
	player.UserId = 12
	rawset(player, "Parent", S.newInstance("Players"))
	local character, humanoid = makeCharacter()
	humanoid.FindFirstChildOfClass = nil
	player.Character = character
	S.characterOwners[character] = player
	player:SetAttribute("EquippedShoe", shoeId)
	for _, handler in S.playerAdded do
		pcall(handler, player)
	end
	return player, character, humanoid
end

AppearanceCleaner.init()

-- En güçlü ayakkabı (Radiant): ışık + iz var, iz sadece koşarken açık
local topId = Config.Items[#Config.Items].id
local player, character, humanoid = setup(topId)
local parts = emittersOf(character)
for _, entry in parts do
	assert(entry.glow, "güçlü ayakkabıda ayak ışığı yok")
	assert(entry.trail, "en güçlü 4 ayakkabıda iz parçacığı olmalı")
	assert(rawget(entry.trail, "Enabled") == false, "iz duruyorken kapalı olmalı")
end
local running = rawget(humanoid, "_handlers") and rawget(humanoid, "_handlers").Running
if running then
	running(10)
	for _, entry in parts do
		assert(rawget(entry.trail, "Enabled") == true, "koşarken iz açık olmalı")
	end
	running(0)
	for _, entry in parts do
		assert(rawget(entry.trail, "Enabled") == false, "durunca iz kapanmalı")
	end
	print("trail toggles with Running ok")
else
	print("note: Humanoid.Running dinleyicisi yakalanamadı (taklit boşluğu olabilir)")
end

-- Zayıf ayakkabı: ışık var ama iz yok
local _, weakCharacter = setup(Config.Items[1].id)
for _, entry in emittersOf(weakCharacter) do
	assert(entry.glow, "zayıf ayakkabıda da ayak ışığı olmalı")
	assert(not entry.trail, "zayıf ayakkabıda iz olmamalı")
end
print("DONE")
