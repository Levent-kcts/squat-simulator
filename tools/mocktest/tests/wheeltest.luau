-- Günlük çark (server/WheelService): dönen Model (dilimler, etiketler, göbek, lambalar, PrimaryPart) ve sabit stand (tabela, ibre, ProximityPrompt) pcall'sız hatasız kurulur.
local S = require("./stubs")
local fakeWorkspace = S.newInstance("Workspace")
local original = S.game.GetService
S.game.GetService = function(self, name)
	if name == "Workspace" then
		return fakeWorkspace
	end
	return original(self, name)
end
local Config = require("./Config")
local WheelService = require("./WheelService")
WheelService.init()

local children = rawget(fakeWorkspace, "_children")
assert(children.DailyWheel, "dönen çark modeli kurulmadı")
assert(children.DailyWheelStand, "çark standı kurulmadı")
local parts = rawget(children.DailyWheel, "_children")
for index = 1, #Config.Wheel.Prizes do
	assert(parts["Slice" .. index], "dilim yok: " .. index)
	assert(parts["SliceLabel" .. index], "dilim yazısı yok: " .. index)
end
for _, name in { "WheelPivot", "WheelRim", "WheelFace", "WheelHub", "WheelCap", "WheelLamp" } do
	assert(parts[name], "çark parçası yok: " .. name)
end
assert(rawget(children.DailyWheel, "PrimaryPart") == parts.WheelPivot, "PrimaryPart WheelPivot olmalı")

local stand = rawget(children.DailyWheelStand, "_children")
for _, name in { "WheelPlinth", "WheelPlinthTop", "WheelSupport", "WheelPillar", "WheelBanner", "WheelPointer" } do
	assert(stand[name], "stand parçası yok: " .. name)
end
local prompt = rawget(stand.WheelPlinthTop, "_children").ProximityPrompt
assert(prompt and prompt:GetAttribute("Panel") == "Wheel", "ProximityPrompt 'Panel' = 'Wheel' olmalı")
assert(rawget(rawget(stand.WheelBanner, "_children").SpinStatus, "_children").SpinLabel, "durum yazısı SpinLabel yok")
print("WheelService ok")
print("DONE")
