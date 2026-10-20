-- FAVORİ İSTEMİ (PlayerStats.markFavorite, client/HappyMoments; 2026-10-20 pazarlama planı Faz B): ödülsüz; favorilerse 'FavDone' kalıcı, reddederse tekrar sorulabilir.
local S = require("./stubs")
local PlayerStats = require("./PlayerStats")
local Config = require("./Config")

PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "Fav"
player.UserId = 9996
rawset(player, "DisplayName", "Fav")
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
assert(player:GetAttribute("FavDone") == false, "başta favorilenmemiş olmalı: " .. tostring(player:GetAttribute("FavDone")))
local winsBefore = player:FindFirstChild("leaderstats"):FindFirstChild(Config.StatWins).Value
assert(PlayerStats.markFavorite(player, false) == true, "reddedilen istem de kaydedilebilmeli")
assert(player:GetAttribute("FavDone") == false, "reddedince FavDone false kalmalı (sonraki oturumda tekrar sorulabilir)")
assert(PlayerStats.markFavorite(player, true) == true, "favori işaretlenmeli")
assert(player:GetAttribute("FavDone") == true, "favorileyince FavDone true olmalı")
assert(player:FindFirstChild("leaderstats"):FindFirstChild(Config.StatWins).Value == winsBefore, "favori istemi ÖDÜL VERMEMELİ")
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local found = false
for _, flag in S.datastore["Player_9996"].Flags do
	if flag == "fav" then
		found = true
	end
end
assert(found, "fav işareti kayıtlı olmalı")
-- Kilometre taşı kodları Config'te ve ödülsüz değil (küçük ödül)
local codes = {}
for _, entry in Config.Codes do
	codes[entry.code] = entry
end
assert(codes["100VISITS"] and codes["1KVISITS"], "kilometre taşı kodları tanımlı olmalı")
print("favorite + milestone codes ok")
