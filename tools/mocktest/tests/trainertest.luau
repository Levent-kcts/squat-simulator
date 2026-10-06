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
	count += 1
end
print("trainers built:", count)
print("DONE")
