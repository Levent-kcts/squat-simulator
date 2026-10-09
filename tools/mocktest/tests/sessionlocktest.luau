-- Yayın öncesi veri güvenliği: oturum kilidi (iki sunucu aynı oyuncunun kaydını ezmesin), kayıt yeniden denemeleri ve satın almada 'önce kaydet' (PlayerStats.saveNow)
local S = require("./stubs")
local Config = require("./Config")

local ME = "mock-server-guid" -- stubs'taki HttpService:GenerateGUID değeri (bu sunucunun kimliği)
local PlayerStats = require("./PlayerStats")
PlayerStats.init()

local function newPlayer(userId)
	local player = S.newInstance("Player")
	player.Name = "Locker" .. userId
	player.UserId = userId
	rawset(player, "Parent", {})
	return player
end
local function key(userId)
	return "Player_" .. userId
end

-- 1) Yeni oyuncu: giriş kaydı bu sunucuya kilitler; çıkış kaydı kilidi BIRAKIR (sonraki sunucu beklemeden girer)
local first = newPlayer(8101)
S.events.PlayerAdded(first)
assert(PlayerStats.canSave(first), "yeni oyuncu kaydedilebilmeli")
local record = S.datastore[key(8101)]
assert(record and record.Lock and record.Lock.id == ME, "giriş kaydı bu sunucuya kilitlemeli")
PlayerStats.dev(first, "AddWins", 123)
assert(PlayerStats.saveNow(first) == true, "saveNow başarılı olmalı")
assert(S.datastore[key(8101)].Wins == 123 and S.datastore[key(8101)].Lock.id == ME, "kayıt veriyi yazar ve kilidi yeniler")
S.events.PlayerRemoving(first)
assert(S.datastore[key(8101)].Lock == nil and S.datastore[key(8101)].Wins == 123, "çıkış kaydı kilidi bırakmalı")

-- 2) Başka sunucunun TAZE kilidi: yüklemede beklenir; kilit bırakılınca ilerleme KORUNARAK devam edilir
S.datastore[key(8102)] = { Muscle = 5000, Wins = 77, Lock = { id = "other-server", t = os.time() } }
local waits = 0
local realWait = S.task.wait
S.task.wait = function()
	waits += 1
	if waits == 2 then
		S.datastore[key(8102)].Lock = nil -- diğer sunucu çıkış kaydıyla kilidi bıraktı
	end
end
local second = newPlayer(8102)
S.events.PlayerAdded(second)
S.task.wait = realWait
assert(waits == 2, "kilit bırakılana kadar beklenmeli: " .. waits)
assert(PlayerStats.canSave(second), "kilit bırakılınca kaydedilebilmeli")
assert(second:FindFirstChild("leaderstats"):FindFirstChild(Config.StatWins).Value == 77, "bekledikten sonra eski ilerleme yüklenmeli")
assert(S.datastore[key(8102)].Lock.id == ME and S.datastore[key(8102)].Muscle == 5000, "kilit bu sunucuya geçti, veri korundu")

-- 3) Kilit çökmüş sunucudan kalmışsa (LOCK_STALE'den eski) beklemeden devralınır
S.datastore[key(8103)] = { Wins = 9, Lock = { id = "dead-server", t = os.time() - 600 } }
local third = newPlayer(8103)
S.events.PlayerAdded(third)
assert(PlayerStats.canSave(third) and S.datastore[key(8103)].Lock.id == ME, "eski kilit devralınmalı")

-- 4) Kilit KAYBEDİLİRSE (başka sunucu devraldı): bu sunucu artık o oyuncu için kaydetmez ve yeni sunucunun verisini ezmez
S.datastore[key(8103)] = { Wins = 5000, Lock = { id = "new-server", t = os.time() } }
PlayerStats.dev(third, "AddWins", 1)
assert(PlayerStats.saveNow(third) == false, "kilit başka sunucuda: kayıt reddedilmeli")
assert(not PlayerStats.canSave(third), "kilit kaybedilince kaydetme kapanmalı")
assert(S.datastore[key(8103)].Wins == 5000 and S.datastore[key(8103)].Lock.id == "new-server", "yeni sunucunun verisi ezilmemeli")

-- 5) Geçici DataStore hatası: 'now' kaydı 3 kez dener (2 hata sonrası başarılı), hata sürerse false döner (satın alma o zaman 'verildi' denmez, makbuz sonra tekrar gelir)
local fourth = newPlayer(8104)
S.events.PlayerAdded(fourth)
PlayerStats.dev(fourth, "AddWins", 40)
S.task.wait = function() end -- yeniden deneme beklemeleri testte anlık
S.datastoreFailures = 2
assert(PlayerStats.saveNow(fourth) == true and S.datastoreFailures == 0, "iki geçici hatadan sonra üçüncü denemede kaydedilmeli")
assert(S.datastore[key(8104)].Wins == 40, "yeniden denenen kayıt veriyi yazmalı")
S.datastoreFailures = 5
assert(PlayerStats.saveNow(fourth) == false, "hata sürerse saveNow false dönmeli")
assert(PlayerStats.canSave(fourth), "geçici hata kaydetmeyi kalıcı kapatmamalı (sadece kilit kaybı kapatır)")
S.datastoreFailures = 0
S.events.PlayerRemoving(fourth)
assert(S.datastore[key(8104)].Lock == nil, "hata geçince çıkış kaydı kilidi bırakmalı")
S.task.wait = realWait

-- 6) Satın alma kaydı: processPurchase sonrası saveNow makbuzu kalıcı yazar (Purchases bunu çağırmadan 'verildi' demez)
local buyer = newPlayer(8105)
S.events.PlayerAdded(buyer)
assert(PlayerStats.processPurchase(buyer, "receipt-1", { kind = "wins", amount = 500 }) == true)
assert(PlayerStats.saveNow(buyer) == true)
local saved = S.datastore[key(8105)]
assert(saved.Wins == 500, "satın alınan Win kayda geçmeli: " .. tostring(saved.Wins))
local hasReceipt = false
for _, id in saved.Receipts do
	if id == "receipt-1" then
		hasReceipt = true
	end
end
assert(hasReceipt, "makbuz kayıtta olmalı (yeniden gelirse ikinci kez ödül verilmez)")

print("session lock ok")
print("DONE")
