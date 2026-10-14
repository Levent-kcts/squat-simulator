-- ÖLÇÜM (server/Analytics; büyüme planı sprint 1.5): Win kaynakları/giderleri Roblox Economy olayı, kilit anlar Custom Event olarak gider; oyuncu başına hız sınırı vardır; ölçüm hatası oyunu etkilemez.
local S = require("./stubs")
local Config = require("./Config")
local Analytics = require("./Analytics")
local PlayerStats = require("./PlayerStats")

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
local function last(kind)
	for index = #S.analytics, 1, -1 do
		if S.analytics[index].kind == kind then
			return S.analytics[index]
		end
	end
	return nil
end
local function find(predicate)
	for index = #S.analytics, 1, -1 do
		if predicate(S.analytics[index]) then
			return S.analytics[index]
		end
	end
	return nil
end

-- 1) Sarmalayıcı: miktar <= 0 gönderilmez, geçerli olay Economy olarak gider
local solo = S.newInstance("Player")
assert(Analytics.economy(solo, "Source", "Wins", 10, 0, "Gameplay", "x") == false, "sıfır miktar gönderilmemeli")
assert(Analytics.economy(solo, "Sink", "Wins", 10, 5, "Shop", "shoe_1") == true, "geçerli ekonomi olayı gönderilmeli")
local sent = last("economy")
assert(sent and sent.flow == "Sink" and sent.currency == "Wins" and sent.amount == 5 and sent.transaction == "Shop" and sent.sku == "shoe_1", "ekonomi olayı alanları")

-- 2) Hız sınırı: art arda çok olaydan sonra gönderim durur (patlama payı kadar)
local spam = S.newInstance("Player")
local accepted = 0
for _ = 1, 200 do
	if Analytics.event(spam, "Spam", 1) then
		accepted += 1
	end
end
assert(accepted >= Analytics.Burst and accepted < 60, "hız sınırı patlama payını geçince kesmeli: " .. accepted)

-- 3) Oyun akışları: Win kaynağı (Win pedi), gider (ayakkabı), özel olay (rebirth)
local player = join(9971, "Metrics")
local before = #S.analytics
PlayerStats.addWin(player, 5)
local win = find(function(e)
	return e.kind == "economy" and e.sku == "stage_win" and e.player == player
end)
assert(win and win.flow == "Source" and win.transaction == "Gameplay" and win.amount >= 5, "Win pedi 'Source / stage_win' olmalı")
assert(#S.analytics > before, "Win kazanmak olay üretmeli")

PlayerStats.dev(player, "AddWins", 100000)
local item = Config.Items[1]
local ok = PlayerStats.buyItem(player, item.id)
assert(ok, "ayakkabı alınmalı")
local spent = find(function(e)
	return e.kind == "economy" and e.flow == "Sink" and e.player == player and string.find(tostring(e.sku), "shoe_", 1, true)
end)
assert(spent and spent.amount == item.price and spent.transaction == "Shop", "ayakkabı 'Sink / Shop / shoe_' olmalı")

PlayerStats.dev(player, "MaxLevel")
PlayerStats.rebirth(player, true)
local reb = find(function(e)
	return e.kind == "custom" and e.name == "Rebirth" and e.player == player
end)
assert(reb and reb.value == 1, "rebirth özel olayı değeri rebirth sayısı olmalı")

-- 4) Yumurta: açılış başına değil çağrı başına tek gider olayı
PlayerStats.dev(player, "AddWins", 100000)
local egg = Config.Eggs[1]
local eggEventsBefore = 0
for _, e in S.analytics do
	if e.kind == "economy" and e.player == player and e.sku == "egg_" .. egg.id then
		eggEventsBefore += 1
	end
end
PlayerStats.hatchEgg(player, egg.id, 3)
local eggEvents = 0
local eggAmount = 0
for _, e in S.analytics do
	if e.kind == "economy" and e.player == player and e.sku == "egg_" .. egg.id then
		eggEvents += 1
		eggAmount = e.amount
	end
end
assert(eggEvents - eggEventsBefore == 1, "3'lü açılış tek gider olayı üretmeli: " .. (eggEvents - eggEventsBefore))
assert(eggAmount == egg.price * 3, "gider toplam fiyat olmalı: " .. eggAmount)

-- 5) Kod ve giriş ödülü: özel olay + Win kaynağı
local code = Config.Codes[1]
local redeemed = PlayerStats.redeemCode(player, code.code)
assert(redeemed, "kod kullanılmalı")
assert(find(function(e)
	return e.kind == "custom" and e.name == "CodeRedeemed" and e.player == player
end), "kod kullanımı özel olay üretmeli")
print("analytics ok")
