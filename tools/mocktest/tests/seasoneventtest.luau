-- SEZONLUK ETKİNLİK (Spooky Gym; server/SeasonEvent, Config.Event): Candy kazanma (duvar + aşama), deterministik mağaza (sınırlar, kalıcı unvan ve iz), kilometre taşları, etkinlik penceresi dışında kapalı, kayıt, etkinlik kimliği değişince sıfırlanma.
local S = require("./stubs")
local Config = require("./Config")
local ServerEvents = require("./ServerEvents")
local PlayerStats = require("./PlayerStats")
local SeasonEvent = require("./SeasonEvent")

local event = Config.Event

-- 1) Yapılandırma sağlam: zaman penceresi, benzersiz ürünler, artan kilometre taşları, iz Config.Trails'te değil, rastgele ürün YOK
assert(event.StartUnix < event.EndUnix, "başlangıç bitişten önce olmalı")
assert((event.EndUnix - event.StartUnix) / 86400 >= 7 and (event.EndUnix - event.StartUnix) / 86400 <= 30, "etkinlik 7-30 gün olmalı (Roblox önerisi)")
local seen = {}
for _, item in event.Items do
	assert(not seen[item.id], "ürün kimliği benzersiz olmalı: " .. item.id)
	seen[item.id] = true
	assert(item.price > 0 and item.limit >= 1 and item.name and item.detail and item.emoji, "ürün alanları eksik: " .. item.id)
	assert((item.reward ~= nil) ~= (item.perk ~= nil), "ürün ya ödül ya kalıcı avantaj olmalı: " .. item.id)
end
local previous = 0
for _, milestone in event.Milestones do
	assert(milestone.candy > previous and milestone.reward, "kilometre taşları artan eşikli olmalı")
	previous = milestone.candy
end
for _, trail in Config.Trails do
	assert(trail.id ~= event.Trail.id, "etkinlik izi kimliği Config.Trails ile çakışmamalı")
end
assert(event.Trail.eventOnly == true and Config.Trails[#Config.Trails].id ~= event.Trail.id, "etkinlik izi Config.Trails'te olmamalı")
local Catalog = require("./Catalog")
assert(Catalog.TrailById[event.Trail.id], "etkinlik izi katalogdan bulunmalı")

-- 2) Zaman penceresi
local now = os.time()
event.StartUnix, event.EndUnix = now - 100, now + 86400 * 10
assert(ServerEvents.seasonActive() == true, "pencere içinde etkinlik açık olmalı")
event.StartUnix, event.EndUnix = now + 86400, now + 86400 * 10
assert(ServerEvents.seasonActive() == false, "başlamadan kapalı olmalı")
event.StartUnix, event.EndUnix = now - 86400 * 10, now - 100
assert(ServerEvents.seasonActive() == false, "bittikten sonra kapalı olmalı")
event.Enabled = false
event.StartUnix, event.EndUnix = now - 100, now + 86400 * 10
assert(ServerEvents.seasonActive() == false, "Enabled=false iken kapalı olmalı")
event.Enabled = true

-- 3) Oyun akışı
PlayerStats.init()
SeasonEvent.init(PlayerStats)
local function join(userId, name)
	local player = S.newInstance("Player")
	player.Name = name
	player.UserId = userId
	rawset(player, "DisplayName", name)
	rawset(player, "Parent", {})
	S.events.PlayerAdded(player)
	return player
end
local player = join(9991, "Spooky")

-- etkinlik kapalıyken Candy kazanılmaz
event.StartUnix, event.EndUnix = now - 86400 * 10, now - 100
PlayerStats.questEvent(player, "walls", 5)
assert((player:GetAttribute("Candy") or 0) == 0, "etkinlik dışında Candy verilmemeli")
local okClosed, whyClosed = SeasonEvent.buy(player, "rainbow")
assert(okClosed == false and string.find(whyClosed, "ended", 1, true), "etkinlik dışında mağaza kapalı olmalı: " .. tostring(whyClosed))

event.StartUnix, event.EndUnix = now - 100, now + 86400 * 10
PlayerStats.questEvent(player, "walls", 3)
assert(player:GetAttribute("Candy") == 3 * event.CandyPerWall, "duvar başına Candy: " .. tostring(player:GetAttribute("Candy")))
PlayerStats.addWin(player, 1)
assert(player:GetAttribute("Candy") == 3 * event.CandyPerWall + event.CandyPerStage, "aşama bitirince Candy: " .. tostring(player:GetAttribute("Candy")))
assert(player:GetAttribute("CandyTotal") == player:GetAttribute("Candy"), "toplam kazanılan Candy harcanmadan eşit olmalı")

-- yetmeyen Candy ile alınamaz
local okPoor = SeasonEvent.buy(player, "title")
assert(okPoor == false, "yetersiz Candy ile ürün alınamaz")

-- bol Candy: iksir, sınır, unvan, iz
PlayerStats.questEvent(player, "walls", 600)
local before = player:GetAttribute("Candy")
local rainbow = event.Items[1]
local okBuy, messageBuy = SeasonEvent.buy(player, rainbow.id)
assert(okBuy == true, "Rainbow Potion alınmalı: " .. tostring(messageBuy))
assert(player:GetAttribute("Candy") == before - rainbow.price, "fiyat kadar Candy düşmeli")
assert(string.find(tostring(player:GetAttribute("EventBought")), rainbow.id .. ":1", 1, true), "alım sayacı yayınlanmalı: " .. tostring(player:GetAttribute("EventBought")))
local limitHit = false
for _ = 1, rainbow.limit + 2 do
	local ok = SeasonEvent.buy(player, rainbow.id)
	if not ok then
		limitHit = true
		break
	end
	PlayerStats.questEvent(player, "walls", rainbow.price) -- Candy bitmesin: sınır devreye girmeli
end
assert(limitHit, "ürün sınırı uygulanmalı")

PlayerStats.questEvent(player, "walls", 1000)
assert(SeasonEvent.buy(player, "title") == true, "unvan alınmalı")
assert(player:GetAttribute("EventTitle") == event.Title, "unvan yayınlanmalı: " .. tostring(player:GetAttribute("EventTitle")))
assert(SeasonEvent.buy(player, "title") == false, "unvan ikinci kez alınamaz")
assert(SeasonEvent.buy(player, "trail") == true, "iz alınmalı")
assert(string.find(tostring(player:GetAttribute("OwnedTrails")), event.Trail.id, 1, true), "iz sahipliğe girmeli: " .. tostring(player:GetAttribute("OwnedTrails")))
assert(player:GetAttribute("EquippedTrail") == event.Trail.id, "iz alınınca takılmalı")

-- 4) Kilometre taşları
local fresh = join(9992, "Milestone")
PlayerStats.questEvent(fresh, "walls", event.Milestones[1].candy - 1)
local okEarly = SeasonEvent.claim(fresh, 1)
assert(okEarly == false, "eşiğe ulaşmadan alınamaz")
PlayerStats.questEvent(fresh, "walls", 1)
local okClaim, messageClaim = SeasonEvent.claim(fresh, 1)
assert(okClaim == true, "eşiğe ulaşınca alınmalı: " .. tostring(messageClaim))
assert(SeasonEvent.claim(fresh, 1) == false, "aynı ödül ikinci kez alınamaz")
assert(string.find(tostring(fresh:GetAttribute("EventClaimed")), "1", 1, true), "alınan taş yayınlanmalı")
assert(SeasonEvent.claim(fresh, 99) == false, "olmayan ödül")

-- 5) Kayıt ve etkinlik kimliği değişimi
assert(PlayerStats.saveNow(player) == true, "kayıt başarılı olmalı")
local saved = S.datastore["Player_9991"].Event
assert(saved and saved.id == event.Id and saved.candy == player:GetAttribute("Candy") and #saved.perks == 2, "etkinlik durumu kayıtlı olmalı")
local again = join(9991, "SpookyAgain")
assert(again:GetAttribute("Candy") == saved.candy and again:GetAttribute("EventTitle") == event.Title, "tekrar girişte durum geri yüklenmeli")
event.Id = "winter2099" -- yeni etkinlik: Candy sıfırlanır, unvan ve iz kalır
PlayerStats.questEvent(again, "walls", 2)
assert(again:GetAttribute("Candy") == 2 * event.CandyPerWall, "yeni etkinlikte Candy sıfırdan başlamalı: " .. tostring(again:GetAttribute("Candy")))
assert(again:GetAttribute("EventTitle") == event.Title, "unvan etkinlik değişince KALMALI")
assert(string.find(tostring(again:GetAttribute("OwnedTrails")), event.Trail.id, 1, true), "iz etkinlik değişince KALMALI")
print("season event ok")
