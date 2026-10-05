-- Arkadaş bonusu: sunucuda her arkadaşın için bacak kası kazancına +%X eklenir (Config.Friends). Oyuncuya arkadaşını çağırtmak için.
-- Arkadaşlık Roblox'tan sorulur (Player:IsFriendsWith, ağ çağrısı: yavaş olabilir, sonuç önbelleğe alınır) ve hatalar yok sayılır.
-- Bonusu PlayerStats uygular (refresh: toplam çarpana girer); bu modül sadece sunucudaki arkadaş sayısını bulup PlayerStats.setFriendCount'a bildirir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)

local FriendBonus = {}

local cache = {} -- ["küçükId_büyükId"] = true/false (iki yönde aynı)
local lastCounts = {} -- [player] = son bildirilen arkadaş sayısı (artışta mesaj göstermek için)

local function pairKey(a, b)
	if a > b then
		a, b = b, a
	end
	return `{a}_{b}`
end

-- İki oyuncu arkadaş mı? Roblox cevap vermezse (hata) arkadaş değil sayılır ve önbelleğe yazılmaz
local function areFriends(playerA, playerB)
	local key = pairKey(playerA.UserId, playerB.UserId)
	if cache[key] ~= nil then
		return cache[key]
	end
	local ok, result = pcall(playerA.IsFriendsWith, playerA, playerB.UserId)
	if not ok then
		return false
	end
	cache[key] = result == true
	return cache[key]
end

function FriendBonus.init(notifyEvent)
	if not Config.Friends.Enabled then
		return
	end

	local function recount(player)
		if player.Parent ~= Players then
			return
		end
		local count = 0
		for _, other in Players:GetPlayers() do
			if other ~= player and areFriends(player, other) then
				count += 1
			end
		end
		if player.Parent ~= Players then
			return
		end
		local previous = lastCounts[player] or 0
		lastCounts[player] = count
		PlayerStats.setFriendCount(player, count)
		if count > previous then
			local bonus = math.min(count, Config.Friends.MaxFriends) * Config.Friends.PercentPerFriend
			notifyEvent:FireClient(player, true, `Friend joined! Friend Bonus: +{bonus}% Leg Muscle`)
		end
	end

	local function recountAll()
		for _, player in Players:GetPlayers() do
			task.spawn(recount, player)
		end
	end

	Players.PlayerAdded:Connect(recountAll)
	Players.PlayerRemoving:Connect(function(leaving)
		lastCounts[leaving] = nil
		task.defer(recountAll) -- ayrılan oyuncu listeden çıktıktan sonra say
	end)
	recountAll()
end

return FriendBonus
