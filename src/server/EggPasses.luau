-- Yumurta game pass'leri (Config.EggPasses: Auto Open, Multi Open x3/x10): oyuncunun sahip olup olmadığı SUNUCUDA sorulur (MarketplaceService:UserOwnsGamePassAsync)
-- ve her pass için bir öznitelik olarak istemciye verilir ('HasEggAuto', 'HasEggMulti'). EggShop sunucuda zorlar (x3/x10 açmak ve otomatik açma pass ister).
-- GamePassId = 0 iken pass henüz satışa açılmamıştır: özellik KİLİTLİ kalır (VIP gibi; istemcide fiyat rozeti görünür, basınca 'coming soon' der). Satın alınca (PromptGamePassPurchaseFinished) anında açılır.
-- DEV: 'DevEggPasses' özniteliği (DevTools 'Egg Passes (test)') ikisini de açar; 'DevPassLock' (Passes Lock) hepsini kilitler.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local EggPasses = {}

local checkPlayer -- init içinde kurulur; DEV anahtarları değişince yeniden sorulur (EggPasses.recheck)

local function publish(player, pass, owns)
	if player.Parent then
		player:SetAttribute(pass.attribute, owns)
	end
end

-- notifyEvent: oyuncuya kısa mesaj (satın alınca)
function EggPasses.init(notifyEvent)
	-- attempt: sorgu başarısız olursa (Roblox servisi) birkaç kez yeniden denenir; sahip olan oyuncu yanlışlıkla kilitli kalmasın
	local function check(player, attempt)
		attempt = attempt or 1
		local failed = false
		for _, pass in Config.EggPasses do
			local passId = pass.GamePassId or 0
			if player:GetAttribute("DevEggPasses") == true then
				publish(player, pass, true) -- DEV testi: üçü de açık
			elseif passId <= 0 or player:GetAttribute("DevPassLock") == true then
				publish(player, pass, false) -- satışa açık değil ya da DEV kilidi: kilitli
			else
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
				publish(player, pass, ok and owns == true)
				failed = failed or not ok
			end
		end
		if failed and attempt < 4 then
			task.delay(5, check, player, attempt + 1)
		end
	end
	checkPlayer = check

	Players.PlayerAdded:Connect(function(player)
		task.spawn(check, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(check, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		for _, pass in Config.EggPasses do
			if (pass.GamePassId or 0) > 0 and gamePassId == pass.GamePassId then
				if wasPurchased then
					player:SetAttribute("DevPassLock", nil) -- satın alma tamamlandı: DEV kilidi kalkar
					publish(player, pass, true)
					notifyEvent:FireClient(player, true, `{pass.name} unlocked!`)
				else
					-- Satın alma iptal edildi ya da Roblox 'You already own this item' dedi (oyuncu zaten sahip ama ilk sorgu başarısız olmuştu): sahipliği yeniden sor
					task.spawn(check, player)
				end
			end
		end
	end)
end

-- Sahiplik durumunu yeniden sorar (DEV paneli anahtarları değişince)
function EggPasses.recheck(player)
	if checkPlayer then
		task.spawn(checkPlayer, player)
	end
end

return EggPasses
