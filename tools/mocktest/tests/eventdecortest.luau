-- SEZONLUK ETKİNLİK LOBİ SÜSÜ (server/EventDecor): etkinlik açıkken balkabakları (yüz + ışık), hayaletler ve tabela kurulur, kapanınca kaldırılır; sadece görünüm.
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
local EventDecor = require("./EventDecor")

local function count(folder, prefix)
	local total = 0
	for name in rawget(folder, "_children") do
		if string.sub(name, 1, #prefix) == prefix then
			total += 1
		end
	end
	return total
end

local folder = EventDecor.build()
local children = rawget(folder, "_children")
local decor = Config.Event.Decor
assert(count(folder, "Pumpkin_") == decor.Pumpkins, "balkabağı sayısı Config.Event.Decor.Pumpkins olmalı: " .. count(folder, "Pumpkin_"))
assert(count(folder, "PumpkinStem_") == decor.Pumpkins, "her balkabağının sapı olmalı")
assert(count(folder, "PumpkinEye_") == decor.Pumpkins * 2, "her balkabağının iki gözü olmalı")
assert(count(folder, "PumpkinMouth_") == decor.Pumpkins * 3, "her balkabağının ağzı olmalı")
assert(count(folder, "Ghost_") == decor.Ghosts, "hayalet sayısı Config.Event.Decor.Ghosts olmalı: " .. count(folder, "Ghost_"))
assert(children.EventSign, "etkinlik tabelası olmalı")

-- Balkabakları yol kenarlarının DIŞINDA ve her iki yanda (raf/antrenman alanına girmez)
local left, right = 0, 0
for name, instance in children do
	if string.match(name, "^Pumpkin_%d+$") then
		local x = instance.Position.X
		assert(math.abs(x) > Config.Lobby.Detail.PathHalfWidth, "balkabağı yolun dışında olmalı: x = " .. tostring(x))
		assert(math.abs(x) < 30, "balkabağı raf/antrenman alanına girmemeli: x = " .. tostring(x))
		if x < 0 then
			left += 1
		else
			right += 1
		end
	end
end
assert(left == right and left > 0, "iki yanda eşit sayıda balkabağı olmalı: " .. left .. "/" .. right)

-- Yeniden kurmak eskiyi siler (çift klasör olmaz); clear kaldırır
EventDecor.build()
local folders = 0
for name in rawget(fakeWorkspace, "_children") do
	if name == "EventDecor" then
		folders += 1
	end
end
assert(folders == 1, "tek EventDecor klasörü olmalı: " .. folders)
EventDecor.clear()
assert(not rawget(fakeWorkspace, "_children").EventDecor, "clear() süsü kaldırmalı")
print("event decor ok")
