-- Roblox 'ücretli rastgele ürün' politikası (create.roblox.com/docs/production/monetization/paid-random-items): Robux ya da Robux'la alınan para birimiyle (bizde Win paketleri) alınan
-- RASTGELE sonuçlu şeyler (yumurta açma, Luck iksiri) için bazı oyuncularda (bölgeye/yaşa göre) PolicyService 'ArePaidRandomItemsRestricted' = true gelir; bu oyuncular ücretli rastgele
-- ürün üreticilerini KULLANAMAZ. Biz Roblox'un listesindeki 'satın almayı hata mesajıyla engelle' yolunu uyguluyoruz: kısıtlı oyuncuda yumurta açılmaz, Luck/Rainbow iksiri satın alınamaz.
-- Kısıtlı olmayanlara yüzdeler yumurta panelinde (toplam 100) ve Luck iksiri etkinken güncel gösterilir. Ücretsiz yollar (çark, Playtime ödülleri, görev) rastgele de olsa serbesttir.
-- Sonuç oyuncunun 'PaidRandomRestricted' özniteliğindedir (istemci Shop'ta okur); sorgu başarısız olursa GÜVENLİ taraf: kısıtlı sayılır.
local PolicyService = game:GetService("PolicyService")

local PaidRandomPolicy = {}

local ATTRIBUTE = "PaidRandomRestricted"
local TRIES = 4

-- Oyuncunun politikasını sorar ve özniteliğe yazar (giriş sırasında arka planda çağrılır; aynı anda iki kez çağrılması zararsızdır)
function PaidRandomPolicy.check(player)
	for attempt = 1, TRIES do
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and type(info) == "table" then
			player:SetAttribute(ATTRIBUTE, info.ArePaidRandomItemsRestricted == true)
			return
		end
		if attempt < TRIES then
			task.wait(2)
		end
	end
	warn(`[PaidRandomPolicy] Could not read the policy for {player.Name}: treating as restricted.`)
	player:SetAttribute(ATTRIBUTE, true)
end

-- Kısıtlı mı? Henüz sorulmadıysa şimdi sorar (bekler). Bilinmiyorsa kısıtlı sayılır.
function PaidRandomPolicy.isRestricted(player)
	local value = player:GetAttribute(ATTRIBUTE)
	if value == nil then
		PaidRandomPolicy.check(player)
		value = player:GetAttribute(ATTRIBUTE)
	end
	return value ~= false
end

PaidRandomPolicy.Message = "Egg hatching is not available for your account."

return PaidRandomPolicy
