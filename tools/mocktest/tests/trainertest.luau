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
