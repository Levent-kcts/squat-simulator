-- Dokunmatik ekranda 'tıklama' ile 'kaydırma'yı ayırır (sahibi telefondan 'ekranı sağa sola çeviremiyorum, her dokunuşta leg power veriyor, kaydırmamı algılamıyor' dedi):
-- parmak ekrana değdiği anda tıklama SAYILMAZ; parmak kalkınca, dokunuş KISA sürdüyse ve parmak neredeyse HAREKET ETMEDİYSE (tap) tıklama sayılır.
-- Parmak sürüklendiyse (kamera döndürme, joystick) tıklama sayılmaz. Saf mantıktır (Roblox'a bağlı değil): client/init.client UserInputService olaylarını buna bağlar. Fare tıklaması bu süzgeçten GEÇMEZ.
local TapFilter = {}
TapFilter.__index = TapFilter

local STALE_SECONDS = 5 -- parmak kalktı olayı hiç gelmezse (nadir) kayıt bu kadar süre sonra silinir

-- maxSeconds: bir dokunuşun tıklama sayılması için en uzun süre; maxMove: parmağın en çok kaç piksel kayabileceği (bundan fazlası kaydırmadır)
function TapFilter.new(maxSeconds, maxMove)
	return setmetatable({ maxSeconds = maxSeconds or 0.6, maxMove = maxMove or 14, touches = {} }, TapFilter)
end

-- key: dokunuşu tanıyan değer (Roblox'ta aynı parmağın InputObject'i); x, y: ekran pikseli; now: os.clock()
function TapFilter:began(key, x, y, now)
	for other, touch in self.touches do
		if now - touch.at > STALE_SECONDS then
			self.touches[other] = nil
		end
	end
	self.touches[key] = { x = x, y = y, at = now, moved = false }
end

function TapFilter:moved(key, x, y)
	local touch = self.touches[key]
	if not touch or touch.moved then
		return
	end
	local dx, dy = x - touch.x, y - touch.y
	if dx * dx + dy * dy > self.maxMove * self.maxMove then
		touch.moved = true
	end
end

-- Parmak kalktı: bu dokunuş bir tıklama (tap) mıydı?
function TapFilter:ended(key, now)
	local touch = self.touches[key]
	self.touches[key] = nil
	return touch ~= nil and not touch.moved and now - touch.at <= self.maxSeconds
end

-- Dokunuş iptal edildi (örneğin başka bir sistem devraldı): tıklama sayılmaz
function TapFilter:cancel(key)
	self.touches[key] = nil
end

return TapFilter
