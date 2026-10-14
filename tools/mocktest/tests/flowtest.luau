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
local muscleAtStart = stat(Config.StatLegMuscle)
for _ = 1, 7 do
	clickOnce()
end
print("TutorialClicks:", player:GetAttribute("TutorialClicks"))
assert(player:GetAttribute("TutorialClicks") == Config.Tutorial.ClickGoal, "eğitim sayacı hedefte durmalı")

-- HER TIKLAMA bacak kasını ANINDA verir: hareketin bitmesini beklemeden (gecikmiş işlevler çalışmadan) kas artmış olmalı
assert(stat(Config.StatLegMuscle) > muscleAtStart, "her tıklama hemen bacak kası vermeli")
-- Gecikmiş işlevler sadece duvar hasarını yapar: kasa ek kas eklememeli
local before = stat(Config.StatLegMuscle)
for _, delayed in S.delayed do
	pcall(delayed[2])
end
assert(stat(Config.StatLegMuscle) == before, "hareket sonu kas eklememeli (kas tıklamada verildi)")

-- Hızlı seri (hiç beklemeden 3 tıklama): üçü de kas verir ama sadece İLK tıklama bir hareket (duvar hasarı zamanlayıcısı) başlatır
table.clear(S.delayed)
local function waitIdle()
	local start = os.clock()
	while os.clock() - start < Config.MoveDuration.Squat + 0.05 do
	end
end
waitIdle() -- önceki hareketin bitmesi (hız kovası da dolar)
table.clear(S.delayed)
local perClick = player:GetAttribute("PerClick")
local fastBefore = stat(Config.StatLegMuscle)
click(player)
click(player)
click(player)
local squatTimers = 0
for _, delayed in S.delayed do
	if math.abs(delayed[1] - Config.MoveDuration.Squat * (Config.MoveContact.Squat or 1)) < 1e-6 then
		squatTimers += 1
	end
end
assert(squatTimers == 1, "art arda tıklamada tek hareket başlamalı: " .. squatTimers)
assert(stat(Config.StatLegMuscle) - fastBefore >= 3 * perClick, "üç hızlı tıklama üç kez kas vermeli")

-- Hız sınırı: aşırı hızlı tıklama (otomatik tıklayıcı) Burst'ten fazla kas vermez
waitIdle()
local limitBefore = stat(Config.StatLegMuscle)
for _ = 1, 50 do
	click(player)
end
local counted = (stat(Config.StatLegMuscle) - limitBefore) / player:GetAttribute("PerClick")
assert(counted <= Config.ClickLimit.Burst + 2, "hız sınırı: 50 ani tıklama " .. counted .. " kez sayıldı")
assert(counted >= 1, "hız sınırı en az bir tıklamayı saymalı")
print("click limit ok, counted", counted)

-- Duvarın önünde TEKME: tıklama kas VERMEZ, hareket boştayken tek tekme başlar; kas ve duvar hasarı ayak değince (gecikmiş işlev) tek seferde gelir, hareket sürerken gelen tıklamalar yok sayılır
root.Position = S.Vector3.new(0, 3, Layout.wallZ(1) + Config.Wall.Thickness / 2 + 4)
do
	local start = os.clock()
	while os.clock() - start < Config.MoveDuration.Squat + 0.05 do
	end
end
table.clear(S.delayed)
local kickPerClick = player:GetAttribute("PerClick")
local kickBefore = stat(Config.StatLegMuscle)
click(player)
click(player)
click(player)
assert(stat(Config.StatLegMuscle) == kickBefore, "tekmede tıklama hemen kas vermemeli")
local kickTimers = 0
for _, delayed in S.delayed do
	if math.abs(delayed[1] - Config.MoveDuration.Kick * Config.MoveContact.Kick) < 1e-6 then
		kickTimers += 1
	end
end
assert(kickTimers == 1, "art arda tıklamada tek tekme başlamalı: " .. kickTimers)
for _, delayed in S.delayed do
	pcall(delayed[2])
end
local kickGain = stat(Config.StatLegMuscle) - kickBefore
assert(kickGain >= kickPerClick and kickGain < kickPerClick * 1.5, "tekme ayak değince TEK tıklamalık kas vermeli: " .. kickGain .. " (tıklama başı " .. kickPerClick .. ")")
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
-- Mağaza hız sınırı: saniyede binlerce çağrı kısılır ('too fast'), normal kullanım etkilenmez (taze kovalı ayrı bir oyuncuyla denenir)
local hammer = S.newInstance("Player")
local rejected, accepted = 0, 0
for _ = 1, Config.ShopLimit.Burst * 3 do
	local _, message = shop(hammer, "ClaimOffline")
	if message == "You are going too fast, slow down." then
		rejected += 1
	else
		accepted += 1
	end
end
assert(rejected >= Config.ShopLimit.Burst and accepted >= Config.ShopLimit.Burst * 0.9, `hız sınırı fazla çağrıyı reddetmeli: {rejected} reddedildi, {accepted} kabul`)
Config.ShopLimit.PerSecond, Config.ShopLimit.Burst = 1e9, 1e9 -- (aşağıdaki 3000'lik çark döngüsü için sınırı fiilen kaldır)
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
-- Roblox 'ücretli rastgele ürün' politikası: kısıtlı hesapta rastgele yumurta yerine sabit sıralı Eğitim Yumurtası açılır (trainingeggtest), kısıtsızda politika engeli çıkmaz; sorgu yapılamazsa güvenli taraf = kısıtlı
local eggOpen = rawget(remote("EggOpen"), "OnServerInvoke")
assert(eggOpen, "EggOpen OnServerInvoke yok")
local firstEgg = Config.Eggs[1].id
assert(player:GetAttribute("PaidRandomRestricted") == false, "girişte politika sorulmalı (kısıtsız taklit): " .. tostring(player:GetAttribute("PaidRandomRestricted")))
player:SetAttribute("PaidRandomRestricted", nil)
S.policy.restricted = true
local okRestricted, whyRestricted = eggOpen(player, firstEgg, 1, false)
assert(not string.find(tostring(whyRestricted), "not available", 1, true), "kısıtlı hesapta artık sıralı Eğitim Yumurtası açılır, politika engeli çıkmamalı: " .. tostring(whyRestricted))
assert(player:GetAttribute("PaidRandomRestricted") == true, "kısıtlı sonuç özniteliğe yazılmalı")
local winsBeforeEgg = stat(Config.StatWins)
eggOpen(player, firstEgg, 1, false)
assert(stat(Config.StatWins) == winsBeforeEgg, "kısıtlı hesapta Win harcanmamalı")
S.policy.restricted = false
player:SetAttribute("PaidRandomRestricted", nil)
local _, whyOpen = eggOpen(player, firstEgg, 1, false)
assert(player:GetAttribute("PaidRandomRestricted") == false, "kısıtsız sonuç özniteliğe yazılmalı")
assert(not string.find(tostring(whyOpen), "not available for your account", 1, true), "kısıtsız hesapta politika engeli çıkmamalı: " .. tostring(whyOpen))
print("DONE")
