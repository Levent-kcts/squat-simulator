-- DEV paneli yayında KAPALI olmalı (sahibi 'dev kısmını kapatmadık, yeni oyuncular erişemez değil mi' diye sordu): Config.DevTools.Enabled = false iken yayındaki oyunda
-- (Studio değil) KİMSE, oyunun sahibi dahil, DEV komutu çalıştıramaz ve istemci panelini görmez; true iken sadece oyunun sahibi. Karar sunucudadır (istemci sahte komut yollasa da).
local S = require("./cstubs")
local Config = require("./Config")
local runService = S.game:GetService("RunService")
rawset(runService, "IsStudio", function()
	return false -- yayındaki oyun
end)
rawset(S.game, "CreatorId", 555)
require("./serverMain")

local function remote(name)
	return rawget(S.replicated, "_children")[name]
end
local devCommand = rawget(remote("DevCommand"), "_handlers").OnServerEvent
assert(devCommand, "DevCommand dinleyicisi yok")

local function join(userId)
	local player = S.newInstance("Player")
	player.Name = "Gate" .. userId
	player.UserId = userId
	rawset(player, "Parent", S.newInstance("Players"))
	for _, handler in S.playerAdded do
		pcall(handler, player)
	end
	return player
end
local function wins(player)
	return player:FindFirstChild("leaderstats"):FindFirstChild(Config.StatWins).Value
end

-- 1) YAYIN HÂLİ: Enabled = false -> sahip dahil kimse
assert(Config.DevTools.Enabled == false, "yayın hâlinde Config.DevTools.Enabled = false olmalı")
local owner, stranger = join(555), join(777)
assert(owner:GetAttribute("IsDev") == false and stranger:GetAttribute("IsDev") == false, "yayında kimsede DEV paneli görünmemeli (IsDev false)")
for _, player in { owner, stranger } do
	local before = wins(player)
	devCommand(player, "AddWins", 1000)
	assert(wins(player) == before, "yayında DEV komutu çalışmamalı: " .. player.Name)
end

-- 2) Enabled = true (sahibin canlıda denemesi için): sadece oyunun sahibi
Config.DevTools.Enabled = true
local owner2, stranger2 = join(555), join(778)
assert(owner2:GetAttribute("IsDev") == true, "Enabled iken oyunun sahibi DEV paneli görür")
assert(stranger2:GetAttribute("IsDev") == false, "Enabled iken bile yabancı oyuncu DEV paneli görmez")
local ownerBefore = wins(owner2)
devCommand(owner2, "AddWins", 1000)
assert(wins(owner2) > ownerBefore, "sahip DEV komutu çalıştırabilir")
local strangerBefore = wins(stranger2)
devCommand(stranger2, "AddWins", 1000)
assert(wins(stranger2) == strangerBefore, "yabancı oyuncunun sahte DEV komutu reddedilmeli")
Config.DevTools.Enabled = false
print("dev gate ok")
print("DONE")
