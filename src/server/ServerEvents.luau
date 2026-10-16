-- SUNUCU ÇAPI OLAYLAR (büyüme planı sprint 2): POWER HOUR (Config.PowerHour). Zaman UTC'ye bağlıdır: her gün StartHoursUTC saatlerinde DurationMinutes dakika sürer; tüm sunucular aynı anda başlar, durum kimseyle konuşmadan saatten hesaplanır.
-- DEV (DevTools 'TogglePowerHour'): devToggle() bu sunucuda hemen başlatır (tam süre) ya da o an süreni bitirir.
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
	local day = 86400
	local duration = settings.DurationMinutes * 60
	local secondOfDay = now % day
	local nextStart = day
	for _, hour in settings.StartHoursUTC or {} do
		local phase = (secondOfDay - hour * 3600) % day -- bu başlangıçtan bu yana geçen sn (dün başlayan da sayılır)
		if phase < duration then
			return true, duration - phase
		end
		nextStart = math.min(nextStart, day - phase)
	end
	return false, nextStart
end

-- DEV zorlaması: forcedUntil = bu saate kadar AKTİF; suppressUntil = bu saate kadar doğal Power Hour KAPALI (DEV ile bitirilen)
local forcedUntil = nil
local suppressUntil = nil

-- Zorlamalar dahil gerçek durum
function ServerEvents.currentState(now)
	if forcedUntil and now < forcedUntil then
		return true, forcedUntil - now
	end
	local active, remaining = ServerEvents.powerHourState(now)
	if active and suppressUntil and now < suppressUntil then
		return false, remaining -- bu doğal pencerenin sonunda yeni başlangıç yok; sonraki başlangıç yaklaşık bilgisi yeter
	end
	return active, remaining
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

local lastActive = nil

-- Power Hour özniteliklerini yazar (sadece durum değişince ya da force = true iken)
local function applyPowerHour(now, force)
	local active, remaining = ServerEvents.currentState(now)
	if active ~= lastActive or force then
		lastActive = active
		Workspace:SetAttribute("PowerHourActive", active)
		Workspace:SetAttribute("PowerHourAt", now + remaining) -- aktifken bitiş, değilken sonraki başlangıç (sunucu saati)
	end
end

-- DEV: aktif değilse bu sunucuda HEMEN tam süreli Power Hour başlatır, aktifse bitirir. Dönüş: yeni durum (true = başladı)
function ServerEvents.devToggle()
	local now = serverNow()
	local active = ServerEvents.currentState(now)
	if active then
		forcedUntil = nil
		local natural, remaining = ServerEvents.powerHourState(now)
		suppressUntil = if natural then now + remaining else nil
	else
		suppressUntil = nil
		forcedUntil = now + (Config.PowerHour.DurationMinutes or 60) * 60
	end
	applyPowerHour(now, true)
	return not active
end

function ServerEvents.init()
	local lastSeason = nil
	task.spawn(function()
		while true do
			local now = serverNow()
			-- Özniteliği sadece durum değişince yaz (ağ trafiği olmasın): aktifken bitiş zamanı, değilken sonraki başlangıç
			-- Sezonluk etkinlik: durum değişince 'SeasonActive' (bool) ve 'SeasonEnds' (UTC saniye) özniteliği; istemci düğmesi ve lobi süsü bunu dinler
			local season = ServerEvents.seasonActive(now)
			if season ~= lastSeason then
				lastSeason = season
				Workspace:SetAttribute("SeasonEnds", if Config.Event then Config.Event.EndUnix else 0)
				Workspace:SetAttribute("SeasonActive", season)
			end
			applyPowerHour(now, false)
			task.wait(1)
		end
	end)
end

return ServerEvents
