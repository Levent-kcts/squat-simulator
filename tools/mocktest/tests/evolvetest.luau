-- EVRİM ANI (Juice.evolve): yeni kas aşaması açılınca çağrılır; hata vermez; aşama atlamayan level atlayışında çalışmaz.
local S = require("../cstubs")
local Config = require("./Config")
local Progression = require("./Progression")
local Juice = require("./Juice")

local function fakeValue(initial)
	local handlers = {}
	local object = { Value = initial }
	function object:GetPropertyChangedSignal()
		return {
			Connect = function(_, callback)
				table.insert(handlers, callback)
				return S.proxy()
			end,
		}
	end
	function object:fire()
		for _, callback in handlers do
			callback()
		end
	end
	return object
end
local stats = {
	[Config.StatLegMuscle] = fakeValue(0),
	[Config.StatWins] = fakeValue(0),
	[Config.StatLevel] = fakeValue(1),
	[Config.StatRebirths] = fakeValue(0),
}
rawget(S.localPlayer, "_children")["leaderstats"] = {
	WaitForChild = function(_, name)
		return stats[name]
	end,
}
S.localPlayer:SetAttribute("DataLoaded", true)
assert(type(Juice.evolve) == "function", "Juice.evolve olmalı")
local evolved, evolveErr = pcall(Juice.evolve, 1)
assert(evolved, "evolve hata vermemeli: " .. tostring(evolveErr))

local firstStageLevel = Config.Legs.StageLevels[1]
assert(Progression.legStage(firstStageLevel) > Progression.legStage(firstStageLevel - 1), "ilk eşikte aşama artmalı")
Juice.init(S.newInstance("Frame"))
stats[Config.StatLevel].Value = firstStageLevel - 1
stats[Config.StatLevel]:fire()
stats[Config.StatLevel].Value = firstStageLevel
local ok, err = pcall(function()
	stats[Config.StatLevel]:fire()
end)
assert(ok, "aşama atlayan level hata vermemeli: " .. tostring(err))
print("evolve ok")
