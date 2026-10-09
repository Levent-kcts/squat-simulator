-- Auto Click game pass'i: oyuncunun sahip olup olmadığı SUNUCUDA sorulur (MarketplaceService:UserOwnsGamePassAsync) ve 'HasAutoClick' özniteliği olarak istemciye verilir.
-- Config.AutoClick.GamePassId = 0 iken satış yoktur: herkes için true. Satın alınca (PromptGamePassPurchaseFinished) anında true olur.
-- Not: Auto Click istemcide tıkladığı için bu sadece KOLAYLIK kilididir; sunucu hız sınırı (Config.ClickLimit) herkese aynıdır, yani pass olmayan biri elle (ya da hileyle) en çok
-- aynı hızda tıklayabilir; pass'in değeri sürekli tıklama zahmetinden kurtarmasıdır.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local AutoClickPass = {}

local checkPlayer -- init içinde kurulur; DEV 'Passes Lock' değişince yeniden sorulur (AutoClickPass.recheck)

local function publish(player, owns)
	if player.Parent then
		player:SetAttribute("HasAutoClick", owns)
	end
end

-- notifyEvent: oyuncuya kısa mesaj (satın alınca)
function AutoClickPass.init(notifyEvent)
	local passId = Config.AutoClick.GamePassId or 0

	local function check(player)
		if passId <= 0 then
			publish(player, true) -- satış yok: Auto Click serbest
			return
		end
		-- DEV testi (DevTools 'TogglePassLock', sadece sunucudan ayarlanır): pass'e sahip DEĞİLMİŞ gibi davran, kilit ve satın alma akışı denenebilsin
		if player:GetAttribute("DevPassLock") == true then
			publish(player, false)
			return
		end
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		publish(player, ok and owns == true)
	end
	checkPlayer = check

	Players.PlayerAdded:Connect(function(player)
		task.spawn(check, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end

	if passId > 0 then
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
			if wasPurchased and gamePassId == passId then
				player:SetAttribute("DevPassLock", nil) -- satın alma tamamlandı: DEV kilidi kalkar
				publish(player, true)
				notifyEvent:FireClient(player, true, "Auto Click unlocked! It is ON now.")
			end
		end)
	end
end

-- Sahiplik durumunu yeniden sorar (DEV paneli 'Passes Lock' açıp kapatınca)
function AutoClickPass.recheck(player)
	if checkPlayer then
		task.spawn(checkPlayer, player)
	end
end

return AutoClickPass
