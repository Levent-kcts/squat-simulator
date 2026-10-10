-- Level atlayınca: ekrana 'LEVEL UP!' yazısı ÇIKMAZ, bunun yerine alttaki level çubuğu nabız atar (Juice.setLevelPulse); rebirth başlığı eskisi gibi çıkar
local S = require("../cstubs")
local Config = require("./Config")
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

local pulses = 0
Juice.setLevelPulse(function()
	pulses += 1
end)
local root = S.newInstance("Frame")
Juice.init(root)
local childrenBefore = 0
for _ in rawget(root, "_children") do
	childrenBefore += 1
end

stats[Config.StatLevel].Value = 2
stats[Config.StatLevel]:fire()
assert(pulses == 1, "level atlayınca çubuk nabzı bir kez çağrılmalı: " .. pulses)
stats[Config.StatLevel].Value = 3
stats[Config.StatLevel]:fire()
assert(pulses == 2, "her level atlayışında nabız (arka arkaya da): " .. pulses)
local childrenAfter = 0
for _ in rawget(root, "_children") do
	childrenAfter += 1
end
assert(childrenAfter == childrenBefore, "level atlayınca ekrana yazı/başlık eklenmemeli (LEVEL UP! yok): " .. childrenBefore .. " -> " .. childrenAfter)

-- Level düşerse (rebirth sıfırlaması) nabız yok
stats[Config.StatLevel].Value = 1
stats[Config.StatLevel]:fire()
assert(pulses == 2, "level düşünce nabız olmamalı")

-- Rebirth başlığı hâlâ çıkar
stats[Config.StatRebirths].Value = 1
stats[Config.StatRebirths]:fire()
local childrenRebirth = 0
for _ in rawget(root, "_children") do
	childrenRebirth += 1
end
assert(childrenRebirth > childrenAfter, "rebirth başlığı çıkmalı")
print("level up pulse ok")
print("DONE")
