-- POWER HOUR (server/ServerEvents): her gün Config.PowerHour.StartHoursUTC saatlerinde DurationMinutes dakika sunucudaki herkese kas kazancı x Multiplier.
-- Zaman UTC saatinden hesaplanır (tüm sunucular aynı anda); çarpan 'PowerHourActive' Workspace özniteliğinden okunur, addMuscle'a uygulanır. DEV devToggle hemen başlatır/bitirir.
local S = require("./stubs")
local Config = require("./Config")
local ServerEvents = require("./ServerEvents")
local PlayerStats = require("./PlayerStats")

local settings = Config.PowerHour
local DAY = 86400
local duration = settings.DurationMinutes * 60
assert(duration == 3600, "Power Hour 1 saat sürmeli (sahibi istedi)")
assert(#settings.StartHoursUTC >= 1, "en az bir başlangıç saati olmalı")
local base = DAY * 20000 -- herhangi bir günün 00:00 UTC'si

-- 1) Saf zaman hesabı: her başlangıç saatinde aktif, süre dolunca değil
for _, hour in settings.StartHoursUTC do
	local start = base + hour * 3600
	local active, remaining = ServerEvents.powerHourState(start)
	assert(active == true and remaining == duration, `{hour}:00 UTC'de aktif olmalı, kalan = süre`)
	active, remaining = ServerEvents.powerHourState(start + duration - 1)
	assert(active == true and remaining == 1, "son saniyede hâlâ aktif, kalan 1")
	active = ServerEvents.powerHourState(start + duration)
	assert(active == false, "süre dolunca pasif")
	active, remaining = ServerEvents.powerHourState(start - 1)
	assert(active == false and remaining == 1, "başlangıçtan 1 sn önce pasif, kalan 1")
end
-- Sıradaki başlangıca kalan süre gün aşımında da doğru (18:00 ve 00:00 için: 20:00'de sonraki 00:00'a 4 saat)
-- Gün aşımı: son başlangıçtan 1 sn önce bitiş + bir sonraki başlangıca kalan doğru (en erken saat ertesi güne sarar)
local first = settings.StartHoursUTC[1]
for _, hour in settings.StartHoursUTC do
	first = math.min(first, hour)
end
local active, remaining = ServerEvents.powerHourState(base + DAY - 1)
assert(active == false or first == 23, "günün son saniyesinde (23:59:59) pasif olmalı")
if active == false then
	assert(remaining == 1 + first * 3600, "gece yarısından sonraki ilk başlangıca kalan doğru olmalı: " .. tostring(remaining))
end

-- 2) Kapalıyken hiç aktif olmaz
settings.Enabled = false
assert(ServerEvents.powerHourState(base + settings.StartHoursUTC[1] * 3600) == false, "Enabled=false iken aktif olmamalı")
settings.Enabled = true

-- 3) Çarpan: özniteliğe göre (testte saat bağımsız)
local workspace = S.game:GetService("Workspace")
workspace:SetAttribute("PowerHourActive", false)
assert(ServerEvents.multiplier() == 1, "pasifken çarpan 1")
workspace:SetAttribute("PowerHourActive", true)
assert(ServerEvents.multiplier() == settings.Multiplier, "aktifken çarpan Config.PowerHour.Multiplier")

-- 4) addMuscle'a uygulanır: aynı tık, Power Hour'da çarpan kadar fazla kas verir
PlayerStats.init()
local player = S.newInstance("Player")
player.Name = "PowerTester"
player.UserId = 8801
rawset(player, "DisplayName", "PowerTester")
rawset(player, "Parent", {})
S.events.PlayerAdded(player)
workspace:SetAttribute("PowerHourActive", false)
local _, normalGain = PlayerStats.addMuscle(player)
workspace:SetAttribute("PowerHourActive", true)
local _, boostedGain = PlayerStats.addMuscle(player)
assert(normalGain >= 1, "normal tık en az 1 kas vermeli: " .. tostring(normalGain))
assert(boostedGain == normalGain * settings.Multiplier, `Power Hour'da kazanç {settings.Multiplier} kat olmalı: {normalGain} -> {boostedGain}`)

-- 5) init: sunucu özniteliklerini yazar (PowerHourActive bool, PowerHourAt sayı)
workspace:SetAttribute("PowerHourActive", nil)
workspace:SetAttribute("PowerHourAt", nil)
ServerEvents.init()
assert(type(workspace:GetAttribute("PowerHourActive")) == "boolean", "init PowerHourActive özniteliğini yazmalı")
assert(type(workspace:GetAttribute("PowerHourAt")) == "number", "init PowerHourAt (bitiş ya da sonraki başlangıç) yazmalı")

-- 6) DEV: devToggle hemen başlatır (tam süre), tekrar basınca bitirir
local wasActive = workspace:GetAttribute("PowerHourActive")
local on = ServerEvents.devToggle()
assert(on == not wasActive, "devToggle durumu tersine çevirmeli")
if not on then
	on = ServerEvents.devToggle() -- doğal Power Hour saatine denk geldiyse: önce bitti, şimdi başlasın
end
assert(on == true and workspace:GetAttribute("PowerHourActive") == true, "DEV ile Power Hour başlamalı")
local left = workspace:GetAttribute("PowerHourAt") - os.time()
assert(left > duration - 5 and left <= duration + 1, "DEV Power Hour tam süre sürmeli: " .. tostring(left))
assert(ServerEvents.multiplier() == settings.Multiplier, "DEV Power Hour'da çarpan uygulanmalı")
assert(ServerEvents.devToggle() == false and workspace:GetAttribute("PowerHourActive") == false, "ikinci basış bitirmeli")
assert(ServerEvents.multiplier() == 1, "bitince çarpan 1")
print("power hour ok")
