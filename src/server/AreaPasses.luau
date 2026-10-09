-- Robux'lu antrenman pedleri (Config.Training.Areas'ta 'robux' alanı olanlar: Coach Prism [rebirth ya da Robux] ve Coach Shadow [sadece Robux]; sahibi istedi): kalıcı game pass'lerdir.
-- Oyuncunun sahip olup olmadığı SUNUCUDA sorulur (MarketplaceService:UserOwnsGamePassAsync) ve 'HasArea_<ped id>' özniteliği olarak yayınlanır; PlayerStats.isAreaUnlocked ve 'UnlockedAreas' bunu okur.
-- Shop'ta kartı YOKTUR: oyuncu kilitli pedin üstünde durunca satın alma penceresi açılır (TrainingArea -> AreaPasses.prompt; aynı pede 20 sn içinde ikinci kez açılmaz).
-- gamePassId = 0 iken pass henüz satışa açılmamıştır: ped KİLİTLİ kalır, üstünde durunca fiyatlı 'coming soon' mesajı çıkar. DEV: 'DevAreaPasses' ikisini de açar, 'DevPassLock' hepsini kilitler.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)

local AreaPasses = {}

local PROMPT_COOLDOWN = 20 -- aynı oyuncuya aynı ped için satın alma penceresi en çok bu kadar sıklıkla açılır (saniye)

local notify = nil -- init içinde kurulur: oyuncuya kısa mesaj
local checkPlayer = nil -- init içinde kurulur; DEV anahtarları değişince yeniden sorulur (AreaPasses.recheck)
local lastPrompt = {} -- [oyuncu] = { [ped id] = os.clock() }

local function attributeName(area)
	return `HasArea_{area.id}`
end

local function paidAreas()
	local list = {}
	for _, area in Config.Training.Areas do
		if area.robux then
			table.insert(list, area)
		end
	end
	return list
end

local function publish(player, area, owns)
	if player.Parent then
		player:SetAttribute(attributeName(area), owns)
	end
end

function AreaPasses.init(notifyEvent)
	notify = notifyEvent

	-- attempt: sorgu başarısız olursa (Roblox servisi) birkaç kez yeniden denenir; sahip olan oyuncu yanlışlıkla kilitli kalmasın
	local function check(player, attempt)
		attempt = attempt or 1
		local failed = false
		for _, area in paidAreas() do
			local passId = area.gamePassId or 0
			if player:GetAttribute("DevAreaPasses") == true then
				publish(player, area, true) -- DEV testi: ikisi de açık
			elseif passId <= 0 or player:GetAttribute("DevPassLock") == true then
				publish(player, area, false) -- satışa açık değil ya da DEV kilidi: kilitli
			else
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
				publish(player, area, ok and owns == true)
				failed = failed or not ok
			end
		end
		PlayerStats.refreshAreas(player) -- açık pedler listesi ('UnlockedAreas') güncellensin
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
		for _, area in paidAreas() do
			if (area.gamePassId or 0) > 0 and gamePassId == area.gamePassId then
				if wasPurchased then
					player:SetAttribute("DevPassLock", nil) -- satın alma tamamlandı: DEV kilidi kalkar
					publish(player, area, true)
					PlayerStats.refreshAreas(player)
					notify:FireClient(player, true, `{area.trainer} unlocked! Step on the pad to train x{area.mult}.`)
				else
					-- Satın alma iptal edildi ya da Roblox 'You already own this item' dedi (oyuncu zaten sahip ama ilk sorgu başarısız olmuştu): sahipliği yeniden sor
					task.spawn(check, player)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastPrompt[player] = nil
	end)
end

-- Kilitli, Robux'lu bir pedin üstünde duran oyuncuya satın alma penceresini açar (ya da pass satışta değilse fiyatlı 'coming soon' der).
-- Dönüş: pencere açıldı mı. Aynı pede kısa sürede ikinci kez açılmaz.
function AreaPasses.prompt(player, area)
	if not area.robux or not notify then
		return false
	end
	local cooldowns = lastPrompt[player]
	if not cooldowns then
		cooldowns = {}
		lastPrompt[player] = cooldowns
	end
	if cooldowns[area.id] and os.clock() - cooldowns[area.id] < PROMPT_COOLDOWN then
		return false
	end
	cooldowns[area.id] = os.clock()

	local passId = area.gamePassId or 0
	if passId <= 0 then
		notify:FireClient(player, false, `{area.trainer} (R$ {area.robux}) is coming soon!`)
		return false
	end
	MarketplaceService:PromptGamePassPurchase(player, passId)
	return true
end

-- Sahiplik durumunu yeniden sorar (DEV paneli anahtarları değişince)
function AreaPasses.recheck(player)
	if checkPlayer then
		task.spawn(checkPlayer, player)
	end
end

return AreaPasses
