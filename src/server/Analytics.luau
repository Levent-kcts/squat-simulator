-- ÖLÇÜM (2026-10-14 büyüme planı sprint 1.5): Roblox Creator Hub > Analytics > Economy ve Custom Events için küçük sarmalayıcı. Win'in nereden geldiği / nereye gittiği (kaynak ve gider) ve kilit anlar (rebirth, kod, giriş ödülü) ölçülür,
-- böylece dengeyi ve oyuncunun nerede bıraktığını tahminle değil veriyle okuruz. SADECE ölçümdür: oyun mantığını etkilemez, hata verirse sessizce atlanır. Oyuncu başına dakikada en çok PerMinute olay (Roblox sınırlarını aşmasın, otomatik yumurta açma gibi sık işler boğmasın).
local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}
Analytics.PerMinute = 40
Analytics.Burst = 15

local buckets = setmetatable({}, { __mode = "k" }) -- [oyuncu] = { tokens, last }; oyuncu çıkınca zayıf anahtarla kendiliğinden temizlenir

local function allow(player)
	local bucket = buckets[player]
	local now = os.clock()
	if not bucket then
		bucket = { tokens = Analytics.Burst, last = now }
		buckets[player] = bucket
	end
	bucket.tokens = math.min(Analytics.Burst, bucket.tokens + (now - bucket.last) * Analytics.PerMinute / 60)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

-- Ekonomi olayı. flow: 'Source' (kazanç) ya da 'Sink' (harcama); transaction: 'Gameplay' / 'Shop' / 'IAP' / 'TimedReward' / 'Onboarding'; sku: kısa kimlik ('egg_forest'). Dönüş: gönderildi mi
function Analytics.economy(player, flow, currency, balance, amount, transaction, sku)
	if type(amount) ~= "number" or amount <= 0 or not allow(player) then
		return false
	end
	local ok = pcall(function()
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType[flow], currency, math.floor(balance), math.floor(amount), transaction, sku)
	end)
	return ok
end

-- Özel olay (Creator Hub > Analytics > Custom Events): isim, isteğe bağlı sayı ve alanlar. Dönüş: gönderildi mi
function Analytics.event(player, name, value, fields)
	if not allow(player) then
		return false
	end
	local ok = pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value, fields)
	end)
	return ok
end

return Analytics
