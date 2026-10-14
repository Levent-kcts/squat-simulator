-- EĞİTİM YUMURTASI (büyüme planı sprint 1.3): 'ücretli rastgele ürün' kısıtı olan hesaplarda yumurta RASTGELE değil, önceden bilinen sabit sıralı 50'lik döngüyle açılır (25/15/6/3/1 kez),
-- döngü Catalog'da, sunucu ve istemci aynısını kullanır; sayaç kayıtlıdır; kısıtsız hesapta normal rastgele yumurta.
local S = require("./stubs")
local Config = require("./Config")
local Catalog = require("./Catalog")
local PlayerStats = require("./PlayerStats")

-- 1) Döngü yapısı: her yumurta için 50 adım, havuzdaki en sık pet 25 kez ... en nadir 1 kez, deterministik ve düzgün yayılmış
for _, egg in Config.Eggs do
	local cycle = Catalog.trainingCycle(egg)
	assert(#cycle == Catalog.TrainingLength and Catalog.TrainingLength == 50, egg.id .. ": döngü 50 adım olmalı")
	assert(cycle == Catalog.trainingCycle(egg), "döngü bir kez hesaplanıp saklanmalı")
	local counts = Catalog.trainingCounts(egg)
	local pool = table.clone(egg.pets)
	table.sort(pool, function(a, b)
		return a.weight > b.weight
	end)
	for rank, entry in pool do
		assert(counts[entry.id] == Catalog.TrainingCounts[rank], `{egg.id}: {entry.id} döngüde {Catalog.TrainingCounts[rank]} kez olmalı, {tostring(counts[entry.id])} çıktı`)
	end
	-- düzgün yayılma: en nadir petin iki katı sık olan petlerin hepsi ilk 10 adımda tek bir pete kilitlenmemeli
	local distinct = {}
	for index = 1, 10 do
		distinct[cycle[index]] = true
	end
	local kinds = 0
	for _ in distinct do
		kinds += 1
	end
	assert(kinds >= 3, egg.id .. ": ilk 10 adımda en az 3 farklı pet olmalı (döngü yayılmış): " .. kinds)
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

-- 2) Kısıtlı hesap: yumurta döngüye göre açılır
S.policy.restricted = true
local restricted = join(9971, "Restricted")
assert(restricted:GetAttribute("PaidRandomRestricted") == true, "kısıtlı hesap işaretlenmeli")
PlayerStats.dev(restricted, "AddWins", 1e9)
local egg = Config.Eggs[1]
local cycle = Catalog.trainingCycle(egg)
local seen = {}
for call = 1, 5 do
	local ok, _, results = PlayerStats.hatchEgg(restricted, egg.id, 10)
	assert(ok == true and #results == 10, "açılış başarılı olmalı")
	for index, result in results do
		local expected = cycle[(call - 1) * 10 + index]
		assert(result.id == expected, `{(call - 1) * 10 + index}. açılış döngüye uymalı: beklenen {expected}, çıkan {result.id}`)
		seen[result.id] = (seen[result.id] or 0) + 1
	end
end
for petId, count in Catalog.trainingCounts(egg) do
	assert(seen[petId] == count, `50 açılışta {petId} tam {count} kez çıkmalı: {tostring(seen[petId])}`)
end
assert(string.find(tostring(restricted:GetAttribute("TrainingEggs")), egg.id .. ":50", 1, true), "sayaç özniteliği: " .. tostring(restricted:GetAttribute("TrainingEggs")))
-- kayıt: sayaç kalıcı
assert(PlayerStats.saveNow(restricted) == true and S.datastore["Player_9971"].Training[egg.id] == 50, "eğitim sayacı kayıtlı olmalı")
-- Win yetmezse sayaç ilerlemez
local broke = join(9972, "Broke")
PlayerStats.hatchEgg(broke, egg.id, 1)
assert(not string.find(tostring(broke:GetAttribute("TrainingEggs")), egg.id .. ":", 1, true), "yumurta açılmayınca sayaç ilerlememeli")

-- 3) Kısıtsız hesap: normal rastgele yumurta, sayaç yok
S.policy.restricted = false
local free = join(9973, "Free")
assert(free:GetAttribute("PaidRandomRestricted") == false, "kısıtsız hesap")
PlayerStats.dev(free, "AddWins", 1e9)
assert(PlayerStats.hatchEgg(free, egg.id, 5) == true, "kısıtsız hesapta yumurta açılmalı")
assert(tostring(free:GetAttribute("TrainingEggs")) == "", "kısıtsız hesapta eğitim sayacı olmamalı: " .. tostring(free:GetAttribute("TrainingEggs")))
print("training egg ok")
