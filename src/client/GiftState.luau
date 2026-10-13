-- Gifts / Playtime Rewards'ın ortak durumu: hangi ödüller alındı, sıradaki ödüle ne kadar kaldı.
-- Gifts menüsü ve sağdaki FREE REWARD kutusu aynı durumu kullanır.
-- Ödülü ve süre kontrolünü sunucu yapar (PlayerStats.claimGift); burası sadece gösterim için sayar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GiftState = {}

local player = Players.LocalPlayer

-- [ödül sırası] = true: bu oturumda alınanlar (GiftsPanel de bu tabloyu doğrudan kullanır)
GiftState.claimed = {}

-- Sunucu alınan ödüllerin sırasını 'ClaimedGifts' özniteliğiyle ('1,3,4') bildirir: Robux 'Unlock' ürünleriyle sunucunun verdiği ödüller de 'Claimed' görünsün
-- Tablo YERİNDE yenilenir (GiftsPanel aynı tabloyu tutar); tur baştan başlayınca ('' gelir) eski 'Claimed'lar silinir
local function syncClaimed()
	table.clear(GiftState.claimed)
	for index in string.gmatch(player:GetAttribute("ClaimedGifts") or "", "%d+") do
		GiftState.claimed[tonumber(index)] = true
	end
end
player:GetAttributeChangedSignal("ClaimedGifts"):Connect(syncClaimed)
syncClaimed()

-- [ödül sırası] = true: Robux 'Unlock' ile AÇILAN (süre beklemeden 'Claim' olan) ama henüz alınmayan ödüller; sunucu 'UnlockedGifts' ('2,3,4') ile bildirir
GiftState.unlocked = {}
local function syncUnlocked()
	table.clear(GiftState.unlocked)
	for index in string.gmatch(player:GetAttribute("UnlockedGifts") or "", "%d+") do
		GiftState.unlocked[tonumber(index)] = true
	end
end
player:GetAttributeChangedSignal("UnlockedGifts"):Connect(syncUnlocked)
syncUnlocked()

-- Oyuna girişten bu yana geçen süre (sunucu saatiyle; SessionStart veri yüklenince gelir)
function GiftState.elapsed()
	local start = player:GetAttribute("SessionStart")
	if type(start) ~= "number" then
		return 0
	end
	return Workspace:GetServerTimeNow() - start
end

-- Alınmaya hazır ödüllerin sıraları (süresi dolmuş ve henüz alınmamış)
function GiftState.ready()
	local list = {}
	local elapsed = GiftState.elapsed()
	for index, reward in Config.GiftRewards do
		if not GiftState.claimed[index] and (elapsed >= reward.time or GiftState.unlocked[index]) then
			table.insert(list, index)
		end
	end
	return list
end

-- Sıradaki ödüle kalan saniye (hazır olan varsa 0); hepsi alındıysa nil
function GiftState.nextRemaining()
	local elapsed = GiftState.elapsed()
	local best = nil
	for index, reward in Config.GiftRewards do
		if not GiftState.claimed[index] then
			local remaining = if GiftState.unlocked[index] then 0 else math.max(0, reward.time - elapsed)
			if best == nil or remaining < best then
				best = remaining
			end
		end
	end
	return best
end

-- 125 -> "02:05"
function GiftState.formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

return GiftState
