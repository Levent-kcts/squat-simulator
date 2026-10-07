-- Sunucu akışı (gerçek init.server): tıklama olayı -> eğitim sayacı, bacak kası, duvar hasarı, günlük görev ilerlemesi; Shop işlemleri (birleştirme, görev ödülü)
local S = require("./cstubs")
local Config = require("./Config")
Config.Tutorial.ClickGoal = 5 -- gerçek 30 tıklamayı beklemek için 12 sn busy-wait gerekirdi: sayaç mantığı hedef küçültülerek denenir
local Layout = require("./Layout")
local PlayerStats = require("./PlayerStats")
require("./serverMain")

local function remote(name)
	return rawget(S.replicated, "_children")[name]
end

local player = S.newInstance("Player")
player.Name = "FlowTester"
player.UserId = 31337
rawset(player, "Parent", S.newInstance("Players"))
for _, handler in S.playerAdded do
	pcall(handler, player)
end
local character = S.newInstance("Model")
local root = S.newInstance("Part")
root.Position = S.Vector3.new(0, 3, 40) -- lobide, duvardan uzak: squat
rawget(character, "_children")["HumanoidRootPart"] = root
player.Character = character

local click = rawget(remote("Click"), "_handlers").OnServerEvent
assert(click, "Click olayı dinleyicisi yok")
local shop = rawget(remote("Shop"), "OnServerInvoke")
assert(shop, "Shop OnServerInvoke yok")

local leaderstats = player:FindFirstChild("leaderstats")
local function stat(name)
	return leaderstats:FindFirstChild(name).Value
end

-- Eğitimin ilk adımı: hedeften fazla tıklama (sayaç hedefte durmalı)
local function clickOnce()
	-- Sunucu hareket süresi dolmadan gelen tıklamayı yok sayar: gerçek zamanda (os.clock) bekle
	local start = os.clock()
	while os.clock() - start < Config.MoveDuration.Squat + 0.05 do
	end
	click(player)
end
for _ = 1, 7 do
	clickOnce()
end
print("TutorialClicks:", player:GetAttribute("TutorialClicks"))
assert(player:GetAttribute("TutorialClicks") == Config.Tutorial.ClickGoal, "eğitim sayacı hedefte durmalı")

-- Hareketin bittiği an verilen ödül: bekleyen gecikmiş işlevleri çalıştır
local before = stat(Config.StatLegMuscle)
for _, delayed in S.delayed do
	pcall(delayed[2])
end
print("muscle gained from moves:", stat(Config.StatLegMuscle) - before)
assert(stat(Config.StatLegMuscle) > before, "hareketler bacak kası vermeli")

-- Duvarın önünde tekme: hasar duvara gitmeli (muscle x ayakkabı)
root.Position = S.Vector3.new(0, 3, Layout.wallZ(1) + Config.Wall.Thickness / 2 + 4)
table.clear(S.delayed)
clickOnce()
for _, delayed in S.delayed do
	pcall(delayed[2])
end
print("after kick: muscle", stat(Config.StatLegMuscle))

-- Shop eylemleri (sunucu doğrulaması)
local data = PlayerStats.dev(player, "FreeCats")
local owned = player:GetAttribute("OwnedPets")
local counts = {}
for id in string.gmatch(owned, "[^,]+") do
	counts[id] = (counts[id] or 0) + 1
end
local fused = false
for id, n in counts do
	if n >= 3 and not fused then
		local ok, message, newId = shop(player, "FusePet", id)
		print("Shop FusePet:", ok, message, newId)
		assert(ok == true, "birleştirme başarılı olmalı: " .. tostring(message))
		fused = true
	end
end
assert(fused, "3'lü pet bulunamadı")
local okBad = shop(player, "FusePet", "yok-boyle-pet")
assert(okBad == false, "geçersiz pet reddedilmeli")
PlayerStats.dev(player, "QuestsComplete")
local claimed, claimMessage = shop(player, "ClaimQuest", 1)
print("Shop ClaimQuest:", claimed, claimMessage)
assert(claimed == true, "bitmiş görev ödülü alınabilmeli")
local again = shop(player, "ClaimQuest", 1)
assert(again == false, "aynı görev iki kez alınamaz")
local badSlot = shop(player, "ClaimQuest", 99)
assert(badSlot == false, "olmayan görev reddedilmeli")

-- Günlük çark: günde 1 hak, sonucu sunucu seçer (dilim sırası döner), aynı gün ikinci çevirme reddedilir, DEV 'WheelReset' hakkı geri verir
assert(player:GetAttribute("WheelReady") == true, "yeni oyuncuda çark hakkı hazır olmalı")
local spun, spinMessage, spinIndex = shop(player, "SpinWheel", "")
print("Shop SpinWheel:", spun, spinMessage, spinIndex)
assert(spun == true and type(spinMessage) == "string" and spinIndex >= 1 and spinIndex <= #Config.Wheel.Prizes, "çark çevrilebilmeli ve dilim sırası dönmeli")
assert(player:GetAttribute("WheelReady") == false, "çevirdikten sonra hak kullanılmış görünmeli")
local spunAgain, againMessage = shop(player, "SpinWheel", "")
assert(spunAgain == false and string.find(againMessage, "Next free spin"), "aynı gün ikinci çevirme reddedilmeli")
-- Her dilim en az bir kez çıkmalı, ödüller sunucuda verilmeli (Win/kas/boost/pet), hata olmamalı
local seen, kinds = {}, {}
local winsBefore, muscleBefore = stat(Config.StatWins), stat(Config.StatLegMuscle)
for _ = 1, 3000 do
	PlayerStats.dev(player, "WheelReset")
	local ok, message, index = shop(player, "SpinWheel", "")
	assert(ok == true, "çark çevrilebilmeli: " .. tostring(message))
	seen[index] = true
	kinds[Config.Wheel.Prizes[index].kind] = true -- (pet dilimi envanter dolunca Win'e döner: o da denenir)
end
for index = 1, #Config.Wheel.Prizes do
	assert(seen[index], "dilim hiç çıkmadı: " .. index)
end
print("wheel prizes seen:", #Config.Wheel.Prizes, "wins/muscle delta:", stat(Config.StatWins) - winsBefore, stat(Config.StatLegMuscle) - muscleBefore)
print("DONE")
