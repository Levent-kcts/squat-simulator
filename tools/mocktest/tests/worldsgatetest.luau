-- Worlds geçidi (server/WorldsGate) ve yumurta standının 3. katı (terası): geçit parçaları ve yazıları kurulur, standda 3. şerit ve iki tabela vardır, yumurtalar terasın derinliği kadar öne kayar
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
local Shelf = require("./Shelf")
local WorldsGate = require("./WorldsGate")
local EggShop = require("./EggShop")

-- Yumurta standı gerçek yerleşimle kurulur (yumurta modelleri yerine boş çizim: ModelLibrary ReplicatedStorage ağacını ister)
Shelf.build({
	name = "EggShop",
	frame = Shelf.backWallFrame(),
	title = "PET EGGS",
	signColor = Config.Eggs[1].color,
	items = Config.Eggs,
	layout = EggShop.Layout,
	buildDisplay = function() end,
})
WorldsGate.init()

local children = rawget(fakeWorkspace, "_children")

-- Yumurta standı: 3 şerit (3. şerit pedsiz teras), iki tabela, 6 yumurta pedi
local egg = rawget(children.EggShop, "_children")
for _, name in { "Lane_1", "Lane_2", "Lane_3", "Sign", "Sign_2" } do
	assert(egg[name], "yumurta standında parça yok: " .. name)
end
local pads = 0
for name in egg do
	if string.sub(name, 1, 4) == "Pad_" then
		pads += 1
	end
end
assert(pads == #Config.Eggs, "ped sayısı yumurta sayısı olmalı: " .. pads)
-- Raf köşelerinde çıkıntılar birbirine girmez: ön çıkıntı iki yan çıkıntının arasında biter (köşede aynı yükseklikte iki studlu üst yüz çakışıp titreşiyordu)
for _, row in { 1, 2, 3 } do
	assert(egg["Rim_" .. row].Size.X == egg["Lane_" .. row].Size.X - 2 * egg["SideRim_" .. row .. "_1"].Size.X, "ön çıkıntı yan çıkıntıların arasında bitmeli: şerit " .. row)
end
local terrace = egg.Lane_3
assert(terrace.Size.Z == Config.Worlds.TerraceDepth, "teras derinliği Config.Worlds.TerraceDepth olmalı")
assert(math.abs(terrace.Size.Y - Config.Worlds.TerraceHeight) < 1e-6, "teras yüksekliği Config.Worlds.TerraceHeight olmalı")
-- Yumurtalar öne kaydı ama duvarla stand arasındaki toplam derinlik arka duvarla çarpışmasın (teras en arkada, duvara yaslı)
local frontEdge = Config.Lobby.BackZ - (11 + 11 + Config.Worlds.TerraceDepth)
assert(frontEdge > 28, "stand antrenman alanının (z <= 31) önüne taşmamalı: z = " .. frontEdge)
-- (Taklitte Position yerel kalır: CFrame ile dünyaya çevrilmez) 1. kat yumurta pedi, 3. katın derinliği + 2. katın derinliği kadar duvardan uzakta
local padLocalZ = -(Config.Worlds.TerraceDepth + 11 + 11 / 2) + EggShop.Layout.padZOffset
assert(math.abs(egg.Pad_starter.Position.Z - padLocalZ) < 1e-6, "1. kat yumurta pedi terasın derinliği kadar öne kaymalı: " .. egg.Pad_starter.Position.Z .. " beklenen " .. padLocalZ)

-- Geçit: parlayan yüz, taş sütunlar, kemer taşları, anahtar taşı ve iki yazı
local gate = rawget(children.WorldsGate, "_children")
for _, name in { "GateGlow", "GateGlowArc_1", "GateGlowArc_16", "GateColumn_-1_1", "GateColumn_1_1", "GateArch_1", "GateArch_15", "GateKeystone", "GateTitle", "GateSoon" } do
	assert(gate[name], "geçit parçası yok: " .. name)
end
local function labelTexts(plate)
	local out = {}
	local gui = rawget(plate, "_children").SurfaceGui
	assert(gui, "yazı levhasında SurfaceGui yok")
	for _, label in rawget(gui, "_children") do
		out[rawget(label, "Text")] = true
	end
	return out
end
assert(labelTexts(gate.GateTitle)[Config.Worlds.Title], "başlık yazısı Config.Worlds.Title olmalı")
assert(labelTexts(gate.GateSoon)[Config.Worlds.SoonText], "yüzdeki yazı Config.Worlds.SoonText olmalı")
-- (Taklitte Position CFrame ile dünyaya çevrilmez: terasın üstünde durma ve kemerin şekli tools/worlds_gate_preview.py ile çizilerek denetlenir)

-- Enabled = false: geçit kurulmaz (teras kalır)
Config.Worlds.Enabled = false
local fakeWorkspace2 = S.newInstance("Workspace")
S.game.GetService = function(self, name)
	if name == "Workspace" then
		return fakeWorkspace2
	end
	return original(self, name)
end
WorldsGate.init()
assert(not rawget(fakeWorkspace2, "_children").WorldsGate, "Enabled = false iken geçit kurulmamalı")
Config.Worlds.Enabled = true
print("WorldsGate ok")
