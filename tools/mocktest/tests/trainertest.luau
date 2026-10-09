-- Antrenör kıyafetleri: 10 zonun hepsi için Mannequin.build hatasız çalışmalı (özellik adları Studio'da görülür)
local S = require("./cstubs")
local Config = require("./Config")
local Mannequin = require("./Mannequin")
local folder = S.newInstance("Folder")
local count = 0
for index, area in Config.Training.Areas do
	local model = Mannequin.build(folder, "Trainer_" .. area.id, S.CFrame.new(), S.Vector3.new(0, 0, 0), Config.Training.TrainerScales[1] or 1, area.color, nil, area.outfit)
	assert(model, "model yok: " .. area.id)
	assert(area.outfit, "outfit tanımsız: " .. area.id)
	assert(not model:FindFirstChild("Coach"), "model yokken kod mankeni kurulmalı: " .. area.id)
	count += 1
end
print("trainers built:", count)

-- Blender koçları: GameModels'te coach_<kıyafet> varsa tek MeshPart (ModelInfo boyutunda) kurulur, parçacıklar görünmez ev sahibine kodla eklenir
local ModelInfo = require("./ModelInfo")
local gameModels = S.newInstance("Folder")
gameModels.Name = "GameModels"
gameModels.Parent = S.replicated
for _, area in Config.Training.Areas do
	assert(ModelInfo["coach_" .. area.outfit], "ModelInfo'da coach_" .. area.outfit .. " yok (tools/blender/coaches.py)")
	local mesh = S.newInstance("MeshPart")
	mesh.Name = "coach_" .. area.outfit
	mesh.Parent = gameModels
end
local withFx, withoutFx = 0, 0
for _, area in Config.Training.Areas do
	local scale = Config.Training.TrainerScales[2] or 1
	local model = Mannequin.build(folder, "Coach_" .. area.id, S.CFrame.new(), S.Vector3.new(0, 0, 0), scale, area.color, nil, area.outfit)
	local coach = model:FindFirstChild("Coach")
	assert(coach, "Blender koçu kurulmadı: " .. area.id)
	local info = ModelInfo["coach_" .. area.outfit]
	assert(math.abs(coach.Size.Y - info.size.Y * scale * Config.Models.CoachScale) < 1e-6, "koç ModelInfo boyutunda olmalı: " .. area.id)
	local host = model:FindFirstChild("FxHost")
	if host then
		assert(host:FindFirstChildOfClass("ParticleEmitter"), "FxHost'ta parçacık yok: " .. area.id)
		withFx += 1
	else
		withoutFx += 1
	end
end
assert(withFx == 6 and withoutFx == 4, "parçacıklı koç sayısı beklenmedik: " .. withFx .. "/" .. withoutFx)
-- kıyafetsiz manken (skin rafı) model aramaz
local plain = Mannequin.build(folder, "Skin", S.CFrame.new(), S.Vector3.new(0, 0, 0), 1, Config.Skins[1].color, nil, nil)
assert(plain and not plain:FindFirstChild("Coach"), "kıyafetsiz manken Blender koçu olmamalı")
print("coach models ok:", withFx, withoutFx)
print("DONE")

-- Coach Shadow'a EK EFEKT (sahibi 'en pahalı olmasına yaraşır bir efekt ver, ÇOK ABARTMA' dedi): zeminde mor büyü halkası (28 ince neon parça), halka içinde yükselen mor tozlar, ince sis ve mor ışık;
-- diğer koçlarda bu ekler YOK. Hem Blender koçunda (aşağıdaki GameModels kurulumuyla) hem kod mankeninde aynı kurulur
local function countFx(model)
	local emitters, lights, ringSegments = 0, 0, 0
	local function walk(instance)
		for _, child in instance:GetChildren() do
			local className = rawget(child, "ClassName")
			if className == "ParticleEmitter" then
				emitters += 1
			elseif className == "PointLight" then
				lights += 1
			elseif string.match(rawget(child, "Name") or "", "^ShadowRing%d+$") then
				ringSegments += 1
				assert(rawget(child, "Transparency") < 1 and rawget(child, "Transparency") > 0, "halka parçası görünür olmalı")
			end
			walk(child)
		end
	end
	walk(model)
	return emitters, lights, ringSegments
end
for _, area in Config.Training.Areas do
	local built = Mannequin.build(folder, "ExtraCheck_" .. area.id, S.CFrame.new(), S.Vector3.new(0, 0, 0), 2.1, area.color, nil, area.outfit)
	local emitters, lights, ringSegments = countFx(built)
	if area.outfit == "shadow" then
		assert(emitters >= 3 and lights == 1, `Shadow'da ana + toz + sis parçacığı ve 1 ışık olmalı: {emitters} parçacık, {lights} ışık`)
		assert(ringSegments == 28, "Shadow'un zemin halkası 28 parçadan oluşmalı: " .. ringSegments)
		assert(built:FindFirstChild("ShadowMotes") and built:FindFirstChild("ShadowFog") and built:FindFirstChild("ShadowGlow"), "Shadow ek ev sahipleri")
	else
		assert(lights == 0 and ringSegments == 0 and not built:FindFirstChild("ShadowMotes"), "diğer koçlarda Shadow ekleri olmamalı: " .. area.id)
	end
end
print("shadow extra fx ok")
