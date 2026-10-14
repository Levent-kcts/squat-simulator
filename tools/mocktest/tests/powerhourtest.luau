-- POWER HOUR (server/ServerEvents; büyüme planı sprint 2): her PeriodMinutes dakikada DurationMinutes dakika sunucudaki herkese kas kazancı x Multiplier.
-- Zaman UTC saatinden hesaplanır (tüm sunucular aynı anda); çarpan 'PowerHourActive' Workspace özniteliğinden okunur, addMuscle'a uygulanır.
local S = require("./stubs")
local Config = require("./Config")
local ServerEvents = require("./ServerEvents")
local PlayerStats = require("./PlayerStats")

local settings = Config.PowerHour
local period, duration = settings.PeriodMinutes * 60, settings.DurationMinutes * 60

-- 1) Saf zaman hesabı: döngünün başında aktif, süre dolunca değil, sonraki başlangıca kalan saniye
local active, remaining = ServerEvents.powerHourState(period * 7)
assert(active == true and remaining == duration, "döngü başında Power Hour aktif olmalı, kalan = süre")
active, remaining = ServerEvents.powerHourState(period * 7 + duration - 1)
assert(active == true and remaining == 1, "son saniyede hâlâ aktif, kalan 1")
active, remaining = ServerEvents.powerHourState(period * 7 + duration)
assert(active == false and remaining == period - duration, "süre dolunca pasif, sonrakine kalan = period - duration")
active, remaining = ServerEvents.powerHourState(period * 8 - 1)
assert(active == false and remaining == 1, "bir sonraki döngüden 1 sn önce pasif, kalan 1")

-- 2) Kapalıyken hiç aktif olmaz
settings.Enabled = false
assert(ServerEvents.powerHourState(period * 7) == false, "Enabled=false iken aktif olmamalı")
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
print("power hour ok")
