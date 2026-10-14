-- NELER YENİ KARTI (Config.WhatsNew; sunucu): eğitimi bitirmiş eski oyuncuda görülen sürüm 0 (kartı görür), yeni oyuncuda güncel sürüm (görmez); 'SeenWhatsNew' sürümü kaydeder ve kayıtlıdır.
local S = require("./stubs")
local Config = require("./Config")
local PlayerStats = require("./PlayerStats")

assert(type(Config.WhatsNew.Version) == "number" and Config.WhatsNew.Version >= 1, "Config.WhatsNew.Version sayı olmalı")
assert(#Config.WhatsNew.Lines >= 1 and #Config.WhatsNew.Lines <= 5, "kart en çok 5 satır olmalı (ekran sade kalsın)")
for _, line in Config.WhatsNew.Lines do
	assert(type(line.text) == "string" and #line.text <= 60, "satır kısa olmalı: " .. tostring(line.text))
end

PlayerStats.init()
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end

-- 1) Yeni oyuncu (eğitim bitmemiş): kart görülmüş sayılır
local fresh = join(9981, "FreshWhatsNew")
assert(fresh:GetAttribute("WhatsNewSeen") == Config.WhatsNew.Version, "yeni oyuncuya kart gösterilmemeli: " .. tostring(fresh:GetAttribute("WhatsNewSeen")))

-- 2) Eski oyuncu (kayıt var, eğitim bitmiş, WhatsNew alanı yok): 0 = kartı görür
S.datastore["Player_9982"] = { Muscle = 5000, TutorialDone = true, Wins = 10, Level = 3, Rebirths = 0 }
local veteran = join(9982, "VeteranWhatsNew")
assert(veteran:GetAttribute("WhatsNewSeen") == 0, "eski oyuncu kartı görmeli (görülen sürüm 0): " .. tostring(veteran:GetAttribute("WhatsNewSeen")))
assert(PlayerStats.seenWhatsNew(veteran) == true, "seenWhatsNew başarılı olmalı")
assert(veteran:GetAttribute("WhatsNewSeen") == Config.WhatsNew.Version, "görülen sürüm güncellenmeli")

-- 3) Kayıtlı ve tekrar girişte yüklenir
assert(PlayerStats.saveNow(veteran) == true, "kayıt başarılı olmalı")
assert(S.datastore["Player_9982"].WhatsNew == Config.WhatsNew.Version, "WhatsNew kayıt alanına yazılmalı")
local again = join(9982, "VeteranAgain")
assert(again:GetAttribute("WhatsNewSeen") == Config.WhatsNew.Version, "tekrar girişte görülen sürüm korunmalı")

-- 4) Daha yeni bir sürüm çıkınca eski kayıt yine kartı görür
Config.WhatsNew.Version += 1
local later = join(9982, "VeteranLater")
assert(later:GetAttribute("WhatsNewSeen") < Config.WhatsNew.Version, "yeni sürümde kart tekrar görünmeli")
Config.WhatsNew.Version -= 1
print("whats new ok")
