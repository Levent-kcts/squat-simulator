-- MÜZİK DEĞİŞTİRME (client/Sfx.playMusicOverride): Power Hour döngüsü normal müziğin YERİNE çalar (üst üste binmez), duraklatmaya uyar, bitince normal müzik sesine döner.
local S = require("../cstubs")
local Sfx = require("./Sfx")

-- id boşsa hiçbir şey yapmaz
assert(Sfx.playMusicOverride("", 10) == false, "boş id ile döngü başlamamalı")

local soundService = S.game:GetService("SoundService")
local function findOverride()
	for _, child in rawget(soundService, "_children") or {} do
		if rawget(child, "Name") == "MusicOverride" then
			return child
		end
	end
	return nil
end

assert(Sfx.playMusicOverride("rbxassetid://123", 300, 1) == true, "döngü başlamalı")
local sound = findOverride()
assert(sound, "MusicOverride sesi kurulmalı")
assert(rawget(sound, "Looped") == true, "döngüde çalmalı")
assert(rawget(sound, "SoundId") == "rbxassetid://123", "doğru parça")

-- ikinci çağrı eskisini hemen kaldırır (aynı anda iki döngü olmaz)
Sfx.playMusicOverride("rbxassetid://456", 300, 1)
local count = 0
for _, child in rawget(soundService, "_children") or {} do
	if rawget(child, "Name") == "MusicOverride" then
		count += 1
	end
end
assert(count == 1, "aynı anda tek döngü olmalı: " .. count)

-- anında durdurma: döngü kalkar
Sfx.stopMusicOverride(true)
assert(findOverride() == nil, "durdurunca döngü kalkmalı")
print("music override ok")
