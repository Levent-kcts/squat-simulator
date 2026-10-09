-- Lobi süsleri (server/LobbyDetail): tuğla derzleri, alt şerit, ortadaki bant, studlu sütunlar, kirişli tavan ve yol kenarları kurulur; EnvironmentService hatasız çalışır;
-- sütunlar raf/rampa bölgelerine konmaz; Detail.Enabled = false iken hiçbir süs kurulmaz
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
local Env = require("./EnvironmentService")

local ok, err = pcall(Env.init)
assert(ok, "EnvironmentService.init hata verdi: " .. tostring(err))
local lobby = rawget(rawget(fakeWorkspace, "_children").Lobby, "_children")

local function count(prefix)
	local total = 0
	for name in lobby do
		if string.sub(name, 1, #prefix) == prefix then
			total += 1
		end
	end
	return total
end
-- (Taklitte ayni adli parcalar tek anahtar altinda birlesir: adlar tekil olmali ki sayim dogru olsun)
for _, prefix in { "Base_", "Seam_", "Band_", "Pilaster_", "BeamBack", "BeamFront", "BeamLeft", "BeamRight", "BeamCross", "BeamLong", "PathCurb" } do
	assert(count(prefix) >= 1, "lobi süsü kurulmadı: " .. prefix)
end
assert(count("Pilaster_") >= 4, "sütun adları en az 4 farklı duvar için kurulmalı")

local detail = Config.Lobby.Detail
-- Sütunlar rafların durduğu yerde olmamalı: sağ duvar sütunları antrenman alanının (z -63..29) dışında, arka duvar sütunları yumurta standının (|x| <= 26.75) dışında
for _, z in detail.RightPilasters do
	assert(z > 31, "sağ duvar sütunu antrenman alanına denk geliyor: z = " .. z)
end
for _, x in detail.BackPilasters do
	assert(math.abs(x) > 30, "arka duvar sütunu yumurta standına denk geliyor: x = " .. x)
end
-- Yol kenarı yumurta standının önünde biter
local stand = Config.Lobby.BackZ - (11 + 11 + Config.Worlds.TerraceDepth)
assert(stand > 28, "stand antrenman alanının önüne taşmamalı")

-- Kapalıyken hiçbir süs kurulmaz (EnvironmentService Workspace'i modül yüklenirken aldığı için LobbyDetail doğrudan çağrılır)
local LobbyDetail = require("./LobbyDetail")
detail.Enabled = false
local emptyFolder = S.newInstance("Folder")
LobbyDetail.init({ folder = emptyFolder })
for name in rawget(emptyFolder, "_children") do
	error("Detail.Enabled = false iken süs kurulmamalı: " .. name)
end
detail.Enabled = true
print("LobbyDetail ok")
