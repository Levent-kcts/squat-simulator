-- MÜZİK DEĞİŞTİRME (client/Sfx.playMusicOverride): Power Hour müziği normal müziğin YERİNE teypten çalar (üst üste binmez), teypte adı görünür,
-- ses müzik kademesinde sabittir (kısma/sönme yok), bitince normal parça ve adı geri gelir.
local S = require("../cstubs")
local Sfx = require("./Sfx")

-- id boşsa hiçbir şey yapmaz
assert(Sfx.playMusicOverride({}, "X") == false, "boş liste ile başlamamalı")
assert(Sfx.playMusicOverride({ { id = "" } }, "X") == false, "boş id ile başlamamalı")

local before = Sfx.getTrack().name
assert(Sfx.playMusicOverride({ { id = "rbxassetid://1", stopAt = 8 }, { id = "rbxassetid://2", loopFor = 300 }, { id = "rbxassetid://1", startAt = 8 } }, "⚡ POWER HOUR x2 ⚡", 1) == true, "özel müzik başlamalı")
assert(Sfx.isOverrideActive() == true, "özel müzik etkin olmalı")
assert(Sfx.getTrack().name == "⚡ POWER HOUR x2 ⚡" and Sfx.getTrack().override == true, "teypte Power Hour adı görünmeli")

-- durdurunca: etkin değil, teypte eski ad
Sfx.stopMusicOverride()
assert(Sfx.isOverrideActive() == false, "durunca etkin olmamalı")
assert(Sfx.getTrack().name == before, "teypte eski şarkı adı dönmeli")
print("music override ok")
