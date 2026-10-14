-- SUNUCU ÇAPI OLAYLAR (büyüme planı sprint 2): POWER HOUR (Config.PowerHour). Zaman UTC'ye bağlıdır: her PeriodMinutes dakikada DurationMinutes dakika sürer; tüm sunucular aynı anda başlar, durum kimseyle konuşmadan saatten hesaplanır.
-- multiplier(): şu an kas kazancı çarpanı (PlayerStats.addMuscle çağırır). init(): 'PowerHourEnds' (aktifken bitiş, sunucu saati) ve 'PowerHourNext' (aktif değilken sonraki başlangıç) Workspace özniteliklerini günceller (istemci sayacı okur).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ServerEvents = {}

-- Verilen sunucu saniyesinde (UTC) durum: aktif mi, aktifse bitişe, değilse sonraki başlangıca kalan saniye
function ServerEvents.powerHourState(now)
	local settings = Config.PowerHour
	if not settings or not settings.Enabled then
		return false, 0
	end
	local period = settings.PeriodMinutes * 60
	local duration = settings.DurationMinutes * 60
	local phase = now % period
	if phase < duration then
		return true, duration - phase
	end
	return false, period - phase
end

local function serverNow()
	local now = Workspace:GetServerTimeNow()
	return if type(now) == "number" then now else os.time()
end

-- Şu an kas kazancı çarpanı (Power Hour aktifse Config.PowerHour.Multiplier, değilse 1). Durum, init döngüsünün yazdığı 'PowerHourActive' özniteliğinden okunur (istemcinin gördüğüyle AYNI kaynak;
-- init çalışmayan ortamda, örn. testlerde, çarpan 1'dir: zamana bağlı rastgele test hatası olmaz)
function ServerEvents.multiplier()
	return if Workspace:GetAttribute("PowerHourActive") == true then Config.PowerHour.Multiplier else 1
end

-- Sezonluk etkinlik (Config.Event) şu an açık mı? (UTC saniye penceresi)
function ServerEvents.seasonActive(now)
	local event = Config.Event
	if not event or not event.Enabled then
		return false
	end
	now = now or serverNow()
	return now >= event.StartUnix and now < event.EndUnix
end

function ServerEvents.init()
	local lastActive = nil
	local lastSeason = nil
	task.spawn(function()
		while true do
			local now = serverNow()
			local active, remaining = ServerEvents.powerHourState(now)
			-- Özniteliği sadece durum değişince yaz (ağ trafiği olmasın): aktifken bitiş zamanı, değilken sonraki başlangıç
			-- Sezonluk etkinlik: durum değişince 'SeasonActive' (bool) ve 'SeasonEnds' (UTC saniye) özniteliği; istemci düğmesi ve lobi süsü bunu dinler
			local season = ServerEvents.seasonActive(now)
			if season ~= lastSeason then
				lastSeason = season
				Workspace:SetAttribute("SeasonEnds", if Config.Event then Config.Event.EndUnix else 0)
				Workspace:SetAttribute("SeasonActive", season)
			end
			if active ~= lastActive then
				lastActive = active
				Workspace:SetAttribute("PowerHourActive", active)
				Workspace:SetAttribute("PowerHourAt", now + remaining) -- aktifken bitiş, değilken sonraki başlangıç (sunucu saati)
			end
			task.wait(1)
		end
	end)
end

return ServerEvents
