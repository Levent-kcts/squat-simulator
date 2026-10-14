-- ÇAPRAZ SUNUCU DUYURU AKIŞI (server/GlobalFeed; büyüme planı sprint 1.1): nadir pet (Legendary/Mythic) ve rebirth eşikleri bu sunucudaki oyunculara ve diğer sunuculara (MessagingService) küçük duyuru olarak gider.
-- Güvenlik: metin sunucu şablonu + oyuncu adı, <> ve denetim karakterleri atılır, 90 karakter sınırı, oyuncu başına 20 sn / sunucu başına dakikada 8 sınırı, kendi sunucudan dönen mesaj yok sayılır.
local S = require("./stubs")
local Config = require("./Config")
local PlayerStats = require("./PlayerStats")
local GlobalFeed = require("./GlobalFeed")

PlayerStats.init()
GlobalFeed.init()
local remote = GlobalFeed.remote
assert(remote and rawget(remote, "Name") == "Feed", "Feed RemoteEvent'i kurulmalı")
local delivered = {}
rawset(remote, "FireAllClients", function(_, kind, text, tier)
	table.insert(delivered, { kind = kind, text = text, tier = tier })
end)
assert(S.subscribers[GlobalFeed.TOPIC], "diğer sunuculardan gelen duyurulara abone olmalı")

local function newPlayer(userId, displayName)
	local player = S.newInstance("Player")
	player.Name = displayName
	player.UserId = userId
	rawset(player, "DisplayName", displayName)
	rawset(player, "Parent", {})
	return player
end

-- 1) Duyuru: yerel oyunculara ve diğer sunuculara gider, metin 'Ad + şablon'
local ali = newPlayer(9901, "Ali")
assert(GlobalFeed.announce(ali, "pet", "hatched a MYTHIC Titan!", "Mythic") == true, "ilk duyuru yayınlanmalı")
assert(#delivered == 1 and delivered[1].kind == "pet" and delivered[1].text == "Ali hatched a MYTHIC Titan!" and delivered[1].tier == "Mythic", "yerel duyuru metni: " .. tostring(delivered[1] and delivered[1].text))
assert(#S.published == 1 and S.published[1].topic == GlobalFeed.TOPIC and S.published[1].data.s == GlobalFeed.SERVER_ID and S.published[1].data.t == "Ali hatched a MYTHIC Titan!", "diğer sunuculara yayınlanmalı")
-- aynı oyuncudan 20 sn içinde ikinci duyuru yok
assert(GlobalFeed.announce(ali, "pet", "hatched a LEGENDARY Dragon!", "Legendary") == false, "oyuncu başına sınır (20 sn) uygulanmalı")
-- izin verilmeyen tür reddedilir
assert(GlobalFeed.announce(newPlayer(9902, "Bo"), "chat", "hello", "") == false, "bilinmeyen duyuru türü reddedilmeli")

-- 2) Başka sunucudan gelen: iletilir; kendi sunucundan dönen yok sayılır; bozuk biçim ve temizlik
local before = #delivered
assert(GlobalFeed.receive({ Data = { s = "other-server", k = "rebirth", t = "Zeynep reached Rebirth 10!", r = "Legendary" } }) == true, "başka sunucudan gelen duyuru iletilmeli")
assert(#delivered == before + 1 and delivered[#delivered].text == "Zeynep reached Rebirth 10!" and delivered[#delivered].tier == "Legendary", "iletilen metin aynı kalmalı")
assert(GlobalFeed.receive({ Data = { s = GlobalFeed.SERVER_ID, k = "pet", t = "x", r = "" } }) == false, "kendi sunucumuzdan dönen duyuru yok sayılmalı")
assert(GlobalFeed.receive({ Data = { s = "other", k = "hack", t = "x", r = "" } }) == false and #delivered == before + 1, "bilinmeyen tür iletilmemeli")
assert(GlobalFeed.receive({ Data = "not a table" }) == false and GlobalFeed.receive(nil) == false, "bozuk mesaj yok sayılmalı")
local count = #delivered
GlobalFeed.receive({ Data = { s = "other", k = "pet", t = "<b>Eve</b>" .. string.rep("a", 200), r = "" } })
assert(#delivered == count + 1, "temizlenen duyuru iletilmeli")
local text = delivered[#delivered].text
assert(not string.find(text, "<", 1, true) and not string.find(text, ">", 1, true) and #text <= 90, "metinde <> olmamalı ve en çok 90 karakter: " .. #text)

-- 3) Sunucu başına dakikada 8 duyuru sınırı (yerel + dış birlikte)
local sent = 0
for index = 1, 20 do
	if GlobalFeed.announce(newPlayer(9910 + index, "P" .. index), "rebirth", "reached Rebirth 5!", "Epic") then
		sent += 1
	end
end
assert(sent < 8, "dakikada en çok 8 duyuru: yeni yayınlanan " .. sent)

print("feed ok")
