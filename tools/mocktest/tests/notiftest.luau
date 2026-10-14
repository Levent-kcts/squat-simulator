-- BİLDİRİM İZNİ (PlayerStats.markNotifAsked, client/NotifOptIn): tek seferlik işaret, kayıtlı, öznitelik 'NotifAsked'.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")

PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Notif"
player.UserId = 9995
rawset(player, "DisplayName", "Notif")
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
assert(player:GetAttribute("NotifAsked") == false, "başta sorulmamış olmalı: " .. tostring(player:GetAttribute("NotifAsked")))
assert(PlayerStats.markNotifAsked(player) == true, "işaretleme başarılı olmalı")
assert(player:GetAttribute("NotifAsked") == true, "işaretlenince öznitelik true olmalı")
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local saved = S.datastore["Player_9995"].Flags
local found = false
for _, flag in saved do
	if flag == "notif" then
		found = true
	end
end
assert(found, "notif işareti kayıtlı olmalı")
print("notif ok")
